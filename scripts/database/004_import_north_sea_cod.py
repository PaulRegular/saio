"""Import the official 2025 Northern Shelf cod assessment from cached ICES sources."""
import argparse
import csv
import io
import pathlib
import re
import subprocess
import xml.etree.ElementTree as ET

import pdfplumber

parser = argparse.ArgumentParser()
parser.add_argument("repository", type=pathlib.Path)
parser.add_argument("--rscript", required=True)
args = parser.parse_args()
root = args.repository / "analysis/comp_assessments"
cache = root / "source_cache/ices_cod_north_sea_2025"
assessment = "ices_cod_north_sea_2025"
report = "https://ndownloader.figshare.com/files/59358443"
revision = "390ff07e3d1de2e14b3a50b1ac27260566d73b62"
repository = "https://github.com/ices-advice/2025_cod.27.46a7d20"
workflow = f"{repository}/blob/{revision}/2025_cod.27.46a7d20_assessment/data.R"
regions = ["Northwestern", "Southern", "Viking"]
with pdfplumber.open(cache / "WGNSSK_2025_cod_autumn.pdf") as pdf:
    text = "\n".join(page.extract_text() or "" for page in pdf.pages)


def section(table):
    start = text.index(f"Table {table}. Cod")
    end = re.search(r"\nTable 4\.\d+[a-z]?\. Cod", text[start + 1:])
    return text[start:start + 1 + end.start()] if end else text[start:]


def matrix(table, columns, by_region=False):
    result = []
    region = ""
    for line in section(table).splitlines():
        if by_region and line.strip() in regions:
            region = line.strip()
        cells = line.split()
        if len(cells) != columns + 1 or not re.fullmatch(r"(?:19|20)\d{2}\*?", cells[0]):
            continue
        if by_region and not region:
            continue
        values = [None if x == "#N/A" else float(x) for x in cells[1:]]
        result.append((region, int(cells[0].rstrip("*")), values))
    assert result, table
    assert len({(r, y) for r, y, _ in result}) == len(result), table
    return result


inputs = []
outputs = []
assumptions = []


def input_row(table, kind, measure, basis, year, age, value, unit,
              region="", survey="", season="", timing="", note=""):
    if value is None:
        return
    inputs.append(dict(assessment_id=assessment, type=kind, measure=measure,
                       basis=basis, fleet="commercial" if kind in ("catch", "catch_weight") else "",
                       survey=survey, sex="", region=region, season=season, year=year,
                       year_basis="calendar_year", age=age, value=value, unit=unit,
                       sampling_time=timing, source_type="official_table",
                       source_reference=f"{report}; Table {table}", transformation="", notes=note))


for table, kind, measure, basis, unit, by_region in [
    ("4.2c", "catch", "numbers_at_age", "numbers", "thousand_fish", False),
    ("4.4a", "catch_weight", "landings_weight_at_age", "kg_per_fish", "kg_per_fish", False),
    ("4.4b", "catch_weight", "discard_weight_at_age", "kg_per_fish", "kg_per_fish", False),
    ("4.4c", "catch_weight", "weight_at_age", "kg_per_fish", "kg_per_fish", False),
    ("4.5a", "weight", "weight_at_age", "kg_per_fish", "kg_per_fish", True),
    ("4.5b", "maturity", "maturity_at_age", "proportion", "proportion", True),
    ("4.5c", "M", "natural_mortality_at_age", "per_year", "per_year", False),
]:
    for region, year, values in matrix(table, 7, by_region):
        for age, value in enumerate(values, 1):
            note = "Age 7 is the plus group. Report-rounded source input."
            if table in ("4.5a", "4.5b", "4.5c"):
                note += " Biological observation informing a GMRF, not its fitted estimate."
            if table == "4.5c":
                note += " Same observation matrix supplied to all three substocks; missing 2023-2025 values are not filled."
            input_row(table, kind, measure, basis, year, age, value, unit, region=region, note=note)

catch = {year: values for _, year, values in matrix("4.2c", 7)}
landings = {year: values for _, year, values in matrix("4.2a", 7)}
assert set(catch) == set(range(1983, 2025)) == set(landings)
for year in catch:
    for age, (ln, cn) in enumerate(zip(landings[year], catch[year]), 1):
        input_row("4.2a", "catch", "landings_numbers_at_age", "numbers", year, age, ln, "thousand_fish",
                  note="Component used to recover the landings fraction; not a separate fitted catch fleet.")
        assert cn > 0 and 0 <= ln <= cn
        input_row("4.2a and 4.2c", "catch", "landings_fraction_at_age", "proportion_numbers",
                  year, age, ln / cn, "proportion")
        inputs[-1].update(source_type="reconstructed_source_input",
                          transformation="landings numbers-at-age / total catch numbers-at-age for the same year and age",
                          notes="Report-rounded reconstruction of the actual land.frac input identified in official data.R.")

for table, by_region, timing, season in [("4.6a", True, 0.125, "Q1"), ("4.6b", False, 0.75, "Q3+Q4")]:
    for region, year, values in matrix(table, 14, by_region):
        survey = "Survey_Q1_" + {"Northwestern": "NW", "Southern": "SO", "Viking": "VI"}[region] if by_region else "Survey_Q34"
        for age in range(1, 8):
            input_row(table, "index", "numbers_at_age", "numbers", year, age, values[age - 1],
                      "survey_index", region=region, survey=survey, season=season, timing=timing,
                      note="Delta-GAM index; timing verified in pinned official data/output.R. Age 7 is the plus group.")
            input_row(table, "index", "log_index_sd", "log_scale", year, age, values[age + 6],
                      "log_index", region=region, survey=survey, season=season, timing=timing,
                      note="Supplied log-index SD; data.R uses 1/SD^2 and fixVarToWeight=0 gives relative observation weights.")
for _, year, values in matrix("4.6c", 6):
    for j, region in enumerate(regions):
        survey = "Survey_Rec_" + ["NW", "SO", "VI"][j]
        note = "Age 0 observed in Q3+Q4 of year-1, shifted to age 1 at model-year time 0. Southern/Viking mixing follows Table 4.7c."
        input_row("4.6c", "index", "numbers_at_age", "numbers", year, 1, values[j], "survey_index",
                  region=region, survey=survey, season="forward_shifted_Q3+Q4", timing=0, note=note)
        input_row("4.6c", "index", "log_index_sd", "log_scale", year, 1, values[j + 3], "log_index",
                  region=region, survey=survey, season="forward_shifted_Q3+Q4", timing=0, note=note)

auxiliary = text.split("The Q1 substock proportions over time are as", 1)[1].split("4.2.1.4 Recreational catches", 1)[0]
auxiliary_years = {3: set(), 4: set()}
for line in auxiliary.splitlines():
    cells = line.split()
    if len(cells) not in (4, 5) or not re.fullmatch(r"(?:19|20)\d{2}", cells[0]):
        continue
    year = int(cells[0])
    if not 1995 <= year <= 2024:
        continue
    values = [float(x) for x in cells[1:]]
    assert abs(sum(values) - 1) <= 0.021
    auxiliary_years[len(values)].add(year)
    for j, value in enumerate(values):
        input_row("4.2.1.3", "catch", "landings_proportion", "proportion_biomass", year, "", value, "proportion",
                  region=regions[j] if len(values) == 3 else "",
                  season="Q1" if len(values) == 3 else f"Q{j+1}",
                  note="Reported rounded landings-weight composition; not renormalized. Native unrounded values are unavailable. The reference component is retained; official data.R uses additive log-ratios for fitting.")
        inputs[-1]["source_reference"] = f"{report}; section 4.2.1.3"
assert auxiliary_years[3] == auxiliary_years[4] == set(range(1995, 2025))

# Output surfaces use the official model-derived objects, checked against report rounding.
native = cache / "native_output_surfaces.csv"
r_code = r'''
a <- commandArgs(TRUE)
e <- new.env(); load(a[1], e)
stocks <- e[["cod.27.46a7d20"]]
rows <- list()
for(i in seq_along(stocks)) for(s in c("stock.n", "harvest", "m")) {
  x <- attr(stocks[[i]], s)
  attr(x, "class") <- NULL
  d <- expand.grid(age=dimnames(x)[[1]], year=dimnames(x)[[2]], stringsAsFactors=FALSE)
  d$value <- c(x)
  d$region <- c("Northwestern", "Southern", "Viking")[i]
  d$slot <- s
  if(s == "harvest") d <- d[as.integer(d$year) <= 2024, ]
  rows[[length(rows)+1]] <- d
}
write.csv(do.call(rbind, rows), a[2], row.names=FALSE)
'''
native_script = cache / "export_native_surfaces.R"
native_script.write_text(r_code, encoding="utf-8")
subprocess.run([args.rscript, str(native_script),
                str(root / "source_cache/ices_selectivity_2026/FLStocks.RData"), str(native)], check=True)
expected = {}
for table, slot, count in [("4.8", "harvest", 8), ("4.9", "stock.n", 8), ("4.13", "m", 7)]:
    for region, year, values in matrix(table, count, True):
        for age, value in enumerate(values[:7], 1):
            expected[(slot, region, year, age)] = value
with native.open(newline="") as f:
    surfaces = list(csv.DictReader(f))
assert len(surfaces) == len(expected) == 2688
for row in surfaces:
    slot, region, year, age, value = row["slot"], row["region"], int(row["year"]), int(row["age"]), float(row["value"])
    assert abs(value - expected[(slot, region, year, age)]) <= (0.501 if slot == "stock.n" else 0.000501)
    kind, measure, unit = {"stock.n": ("population", "numbers_at_age", "thousand_fish"),
                           "harvest": ("mortality", "fishing_mortality_at_age", "per_year"),
                           "m": ("mortality", "natural_mortality_at_age", "per_year")}[slot]
    outputs.append(dict(assessment_id=assessment, type=kind, measure=measure, region=region,
                        year=year, age=age, value=value, unit=unit, source_type="native_model",
                        source_reference=f"https://ndownloader.figshare.com/files/67087409; Selectivity Indicators/FLStocks.RData; cod.27.46a7d20; {region}; {slot}",
                        notes="Official official-model output; all N/F/M values cross-checked against Tables 4.8, 4.9 and 4.13 within report rounding. Age 7 is the plus group."))

for region, key in zip(regions, [19661, 19662, 19663]):
    tree = ET.parse(cache / f"SAG_2025_{region.lower()}_{key}.xml").getroot()
    for year_row in tree.findall("Fish_Data"):
        year = int(year_row.findtext("Year"))
        if year > 2025:
            continue
        for field, kind, measure, unit in [("StockSize", "biomass", "SSB", "tonnes"),
                                          ("Recruitment", "recruitment", "recruitment", "thousand_fish"),
                                          ("TBiomass", "biomass", "total_biomass", "tonnes"),
                                          ("FishingPressure", "mortality", "Fbar", "per_year"),
                                          ("Catches", "catch", "predicted_catch", "tonnes")]:
            value = year_row.findtext(field)
            if not value:
                continue
            outputs.append(dict(assessment_id=assessment, type=kind, measure=measure, region=region,
                                year=year, age=1 if field == "Recruitment" else "",
                                age_group="2-4" if field == "FishingPressure" else "",
                                value=float(value), lwr=year_row.findtext("Low_" + field) or "",
                                upr=year_row.findtext("High_" + field) or "", unit=unit,
                                source_type="official_machine_readable",
                                source_reference=f"https://sag.ices.dk/SAG_API/StockXmlDownload/{key}; Fish_Data/{field}",
                                notes="Reported model estimate; pointwise 95% limits where provided. Catch is fitted substock catch, not observed removals."))


def assumption(component, setting, value, reference, **dimensions):
    assumptions.append(dict(assessment_id=assessment, component=component, setting=setting,
                            value=value, source_reference=reference, **dimensions))


for setting, value in [("years", "1983-2025; catch data end 2024"), ("ages", "1-7+"),
                       ("recruitment_age", "1"), ("plus_group", "7"),
                       ("substocks", "Northwestern; Southern; Viking; no transfer between reproductively isolated substocks")]:
    assumption("population", setting, value, f"{report}; sections 4.1.1 and 4.3.4; Tables 4.7-4.9")
for component, setting, value in [
    ("recruitment", "process", "Random walk; stockRecruitmentModelCode=0"),
    ("F", "process", "Random walk with AR1 correlation across age increments; scaled selectivity connects substocks with flexible Fbar"),
    ("N", "expected_state", "Median formulation; logNMeanAssumption=0 0"),
    ("catch", "observation_likelihood", "Lognormal with AR1 correlation among ages; combined commercial catch only"),
    ("catch", "excluded_removals", "Recreational catches are not included"),
    ("biology", "stock_weight", "GMRF with cohort, within-year and additional plus-group correlation; stockWeightModel=2"),
    ("biology", "maturity", "GMRF on logit proportion mature with additional plus-group correlation; matureModel=2"),
    ("M", "process", "GMRF; mortalityModel=1; same supplied observations but separate fitted random effects by substock"),
    ("biology", "spawning_fractions", "prop.f=NULL and prop.m=NULL resolve to zero in setup.sam.data"),
    ("catch", "quarterly_landings_likelihood", "Additive logistic normal; Q4 reference; log(Q1:Q3/Q4)"),
    ("catch", "substock_landings_likelihood", "Additive logistic normal for Q1; Viking reference; log(Northwestern or Southern / Viking)"),
]:
    assumption(component, setting, value, f"{report}; sections 4.2-4.3 and Table 4.7; {workflow}")
for survey in sorted({x["survey"] for x in inputs if x["survey"]}):
    timing = next(x["sampling_time"] for x in inputs if x["survey"] == survey)
    assumption("index", "sampling_time", str(timing), workflow, survey=survey)
    assumption("index", "observation_variance", "Relative weights 1 / supplied log-index SD squared; fixVarToWeight=0; variance also estimated",
               f"{workflow}; Table 4.7a", survey=survey)
    assumption("index", "observation_likelihood", "Lognormal; AR1 among ages for Q1/Q34", f"{report}; section 4.3.4", survey=survey)
assumption("index", "fleet_to_stock_weights", "Survey_Rec_SO: 0*Northwestern + 0.75*Southern + 0*Viking; Survey_Rec_VI: 0*Northwestern + 0.25*Southern + 1*Viking",
           f"{report}; Table 4.7c; {workflow}")

configuration = section("4.7a")
def key_rows(key):
    body = configuration.split("$" + key + "\n", 1)[1].split("\n$", 1)[0]
    return [line.strip() for line in body.splitlines()
            if re.fullmatch(r"(?:-?\d+|NA)(?:\s+(?:-?\d+|NA))*", line.strip())]

fleet_names = ["Catch", "Survey_Q34", "Survey_Q1_NW", "Survey_Q1_SO", "Survey_Q1_VI",
               "Survey_Rec_NW", "Survey_Rec_SO", "Survey_Rec_VI", "AUX_SeasonProp", "AUX_SubNew"]
for key, component in [("keyLogFpar", "q"), ("keyVarObs", "observation_error"), ("keyCorObs", "observation_error")]:
    rows = key_rows(key)
    assert len(rows) == 10
    for fleet_name, value in zip(fleet_names, rows):
        dimensions = dict(fleet="commercial") if fleet_name == "Catch" else dict(survey=fleet_name) if fleet_name.startswith("Survey") else dict(fleet=fleet_name)
        assumption(component, key, value, f"{report}; Table 4.7a-b",
                   notes="Keys are ordered by ages 1-7 (adjacent age pairs for keyCorObs). Identical nonnegative integers share a parameter; negative keys omit it. Auxiliary rows use composition components rather than ages. These keys are shared across substocks per Table 4.7b.", **dimensions)
assumption("F", "state_sharing", key_rows("keyLogFsta")[0], f"{report}; Table 4.7a",
           notes="Ages 1-7 have distinct latent F states (keys 0-6).")
assumption("F", "process_variance_sharing", key_rows("keyVarF")[0], f"{report}; Table 4.7a-b",
           notes="Ages 1-2 share a log-F process variance; ages 3-7 share a second variance; keys shared across substocks.")
assumption("N", "process_variance_sharing", key_rows("keyVarLogN")[0], f"{report}; Table 4.7a-b",
           notes="Recruitment variance is separate; older-age survival variances share a parameter; keys shared across substocks.")
assumption("N", "process_correlation", "Independent abundance-process innovations across ages and substocks; default formula=~-1 and suggestCorStructure(nAgeClose=0) constrain all correlations to zero.",
           f"{repository}/blob/{revision}/2025_cod.27.46a7d20_assessment/utilities.R; runFit; https://github.com/calbertsen/multi_SAM/blob/0465d228884e0e1fe394276ef320e2d8f20ac16c/multiStockassessment/R/suggest_covstructure.R",
           notes="The runFit call does not override covariance defaults. Same-age cross-stock correlation is also constrained because the implementation uses age distance >= nAgeClose.")
assumption("q", "time_and_density_dependence", "Fixed age-specific q; no density-dependent power parameters (keyQpow=-1)", f"{report}; Table 4.7a-b")
implementation = "https://github.com/calbertsen/multi_SAM/blob/0465d228884e0e1fe394276ef320e2d8f20ac16c/multiStockassessment/src/multiStockassessment.cpp"
assumption("population", "initial_state", "Separate initial recruitment-level parameter per substock. Initial log abundance at age 1 is normal around that level with SD 0.01; each older initial age is normal around the preceding age minus first-year M+F, also with SD 0.01.",
           f"{report}; Table 4.7b; initN=2; shared_initN=FALSE; initF=FALSE; {implementation}; initial parameter contribution",
           notes="Verified in the cited shared_obs implementation, version 0.4.0, revision dated 2025-04-22. No additional plus-group accumulation term appears in this initial-state recursion.")
assumption("F", "substock_selectivity_scaling", "Northwestern reference log-F process; Southern and Viking log F add a cubic polynomial age effect and scalar AR1 temporal level. shared_oneFScalePars=TRUE shares SD and rho of the two scalar level processes.",
           f"{report}; Table 4.7b; shared_selectivity=4; shared_proportionalHazard=poly(Age,3); {implementation}; shared_F_type=4",
           notes="The C++ likelihood uses stationary scalar AR1 scaling, despite an older source comment calling it RW. The overall reference F process retains its random-walk increments.")

stock = dict(stock_id="ices_cod_north_sea", charbonneau_id="ICES-WGNSSK_NS 4-7d,20_Gadus_morhua",
             authority="ICES", authority_stock_id="cod.27.46a7d20", scientific_name="Gadus morhua",
             common_name="Northern Shelf cod (formerly North Sea cod)",
             area="Subarea 4, divisions 6.a and 7.d, Subdivision 20", region="Northern Shelf", ocean="Northeast Atlantic",
             notes="The 2023 benchmark combined North Sea and West of Scotland cod in one assessment with Northwestern, Southern and Viking substocks; historical Charbonneau stock boundary differs.")
assessment_row = dict(assessment_id=assessment, stock_id=stock["stock_id"], assessment_year=2025,
                      terminal_year=2025, estimate_terminal_year=2025, assessment_type="assessment_update",
                      model_family="multistock SAM", model_version="stockassessment 0.12.4; multiStockassessment 0.4.0",
                      is_current="TRUE", is_applied="TRUE", framework_year=2023, assessment_url=report,
                      framework_url="https://doi.org/10.17895/ices.pub.22591423",
                      data_url=workflow, model_url="https://ndownloader.figshare.com/files/67087409",
                      repository_url=repository, assumptions_status="partial", inputs_status="partial", outputs_status="partial",
                      notes="Official autumn 2025 three-substock assessment. Terminal fitted input year is 2025 because Q1 indices extend to 2025; catch and reported F end in 2024. Report-rounded input tables and verified official N/F/M output objects. All material input streams are represented, including auxiliary substock/quarterly landings proportions, but exact unrounded values and native input files are absent from the public repository. Configuration keys, timing, abundance-process covariance and multistock initialization/selectivity semantics were checked against the report and cited version 0.4.0 implementation. Exact installed code revision and numerical catchability/prediction uncertainty remain unavailable; biology process mean/variance details are not fully extracted. Missing biological observations are not replaced with estimates. All seven fitted index streams are represented with their supplied log-scale SDs and documented model timing.")

for filename, new, key in [("stocks.csv", [stock], "stock_id"), ("assessments.csv", [assessment_row], "assessment_id"),
                           ("inputs.csv", inputs, "assessment_id"), ("outputs.csv", outputs, "assessment_id"),
                           ("assumptions.csv", assumptions, "assessment_id")]:
    path = root / "database" / filename
    content = path.read_bytes().decode("utf-8-sig")
    reader = csv.DictReader(io.StringIO(content))
    fields = reader.fieldnames
    old = list(reader)
    lines = content.splitlines(keepends=True)
    assert len(lines) == len(old) + 1, "Preserving source formatting requires one physical line per CSV record"
    preserved = [lines[0]] + [line for line, row in zip(lines[1:], old) if row[key] != new[0][key]]
    with path.open("w", newline="", encoding="utf-8") as f:
        f.writelines(preserved)
        writer = csv.DictWriter(f, fields)
        writer.writerows({field: row.get(field, "") for field in fields} for row in new)
print(f"Imported {len(inputs)} inputs, {len(outputs)} outputs and {len(assumptions)} assumptions; statuses remain partial.")
