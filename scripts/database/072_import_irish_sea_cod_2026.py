"""Import the tabulated inputs and available outputs for ICES cod.27.7a."""
import csv
import io
import json
import pathlib
import re
import sys

import pdfplumber

root = pathlib.Path(sys.argv[1]) / "analysis/comp_assessments"
cache = root / "source_cache/ck_ices_wgcse_morhua_is7a/assessment_2026"
assessment = "ices_cod_irish_sea_2026"
stock_id = "ck_ices_wgcse_morhua_is7a"
report = "https://ndownloader.figshare.com/files/66387206"
report_doi = "https://doi.org/10.17895/ices.pub.32625759"
annex = "https://doi.org/10.17895/ices.pub.24495970.v2"
sag = "https://sag.ices.dk/SAG_API/api/StockDownload?assessmentKey=23721"

with pdfplumber.open(cache / "WGCSE_2026_Cod_7a.pdf") as pdf:
    pages = [page.extract_text() or "" for page in pdf.pages]
with pdfplumber.open(cache / "ICES_Stock_Annex_cod_27_7a_2025.pdf") as pdf:
    annex_text = "\n".join(page.extract_text() or "" for page in pdf.pages)


def is_year(token):
    return re.fullmatch(r"(?:19|20)\d{2}[*^,]*", token) is not None


def year_value(token):
    return int(token[:4])


def numeric(token):
    token = token.rstrip("*,^")
    if token.upper() in ("NA", "N/A"):
        return None
    return float(token)


def matrix(page_numbers, columns):
    rows = []
    for page_number in page_numbers:
        for line in pages[page_number - 1].splitlines():
            cells = line.split()
            if len(cells) == columns + 2 and cells[1] in ("*", "**", "^"):
                cells.pop(1)
            if len(cells) != columns + 1 or not is_year(cells[0]):
                continue
            values = [numeric(value) for value in cells[1:]]
            rows.append((year_value(cells[0]), cells[0], values))
    assert rows
    assert len({year for year, _, _ in rows}) == len(rows)
    return rows


def add_input(kind, measure, basis, value, unit, *, year="", age="", fleet="",
              survey="", season="", timing="", reference="", notes=""):
    if value is None:
        return
    inputs.append(dict(
        assessment_id=assessment, type=kind, measure=measure, basis=basis,
        fleet=fleet, survey=survey, sex="", region="", season=season,
        year=year, year_basis="calendar_year" if year != "" else "", age=age,
        value=value, unit=unit, sampling_time=timing, source_type="official_table",
        source_reference=reference, transformation="", notes=notes,
    ))


def add_output(measure, year, value, unit, *, age="", age_group="", low=None,
               high=None, notes=""):
    outputs.append(dict(
        assessment_id=assessment,
        type={"SSB": "biomass", "recruitment": "recruitment", "Fbar": "mortality"}[measure],
        measure=measure, year=year, age=age, age_group=age_group, value=value,
        se="", lwr="" if low is None else low, upr="" if high is None else high,
        unit=unit, source_type="official_table", source_reference=f"{report}; Table 6.14, printed pp. 200-201",
        notes=notes,
    ))


inputs, outputs, assumptions = [], [], []
excluded_catch_years = {2003, 2004, 2005, 2020}

def summary_rows():
    rows = []
    for page_number in (36, 37):
        for line in pages[page_number - 1].splitlines():
            cells = line.split()
            if not cells or not is_year(cells[0]):
                continue
            year = year_value(cells[0])
            values = [numeric(value) for value in cells[1:]]
            if year <= 2025 and len(values) == 11:
                rows.append((year, values))
            elif year == 2026 and len(values) == 4:
                rows.append((year, values))
    assert len(rows) == 59
    return rows


# Catch and biological inputs
for year, label, values in matrix([23, 24], 7):
    note = "Age 6 is the 6+ group. Values are reported in thousands of fish."
    if year in excluded_catch_years:
        note += " Marked as excluded from the assessment because of limited sampling."
    for age, value in enumerate(values):
        add_input("catch", "numbers_at_age", "numbers", value, "thousand_fish",
                  year=year, age=age, fleet="commercial", reference=f"{report}; Table 6.9, printed pp. 187-188", notes=note)

for year, label, values in matrix([25, 26], 7):
    note = "Age 6 is the 6+ group. The report describes these landings weights as used for the whole stock and catch."
    if "*" in label:
        note += " Asterisked 2020, 2023-2025 values have low or incomplete sampling; retain as reported and do not treat as complete observed weights."
    if "^" in label:
        note += " Ages 4+ use the preceding-three-year average because too few fish were aged."
    for age, value in enumerate(values):
        add_input("weight", "weight_at_age", "kg_per_fish", value, "kg_per_fish",
                  year=year, age=age, reference=f"{report}; Table 6.10, printed pp. 189-190", notes=note)

for year, label, values in matrix([27, 28], 7):
    note = "Discard numbers-at-age in thousands, raised from sampled trips to total effort. Age 6 is the 6+ group."
    if "*" in label or "^" in label:
        note += " The report marks sampling as very low or incomplete."
    for age, value in enumerate(values):
        add_input("catch", "discard_numbers_at_age", "numbers", value, "thousand_fish",
                  year=year, age=age, fleet="discards", reference=f"{report}; Table 6.11(a), printed pp. 191-192", notes=note)

# Annual maturity is updated through 2024; pre-1996 values are retained from the current stock annex.
maturity_rows = matrix([31], 3)
maturity_by_year = {year: values for year, _, values in maturity_rows}
assert set(maturity_by_year) == set(range(1996, 2026))
pre_1996 = re.search(r"Proportion mature\s+1968[–-]1996\s+0\s+([0-9.]+)\s+1", annex_text)
assert pre_1996, "Could not verify the pre-1996 maturity value from the current stock annex."
pre_1996_age2 = float(pre_1996.group(1))
for year in range(1968, 2026):
    age2 = pre_1996_age2 if year < 1996 else maturity_by_year[year][1]
    note = "Ages 0 and 1 map to the source <2 class; ages 3-6 map to 3+."
    if year < 1996:
        note += " Age-2 value is the constant pre-1996 value in the 2025 stock annex."
        reference = f"{annex}; section B.2.1"
    else:
        note += " The annual ogive is reported in the 2026 assessment table."
        reference = f"{report}; Table 6.12, printed p. 195"
    for age in range(7):
        value = 0.0 if age < 2 else age2 if age == 2 else 1.0
        add_input("maturity", "maturity_at_age", "proportion", value, "proportion",
                  year=year, age=age, reference=reference, notes=note)

m_rows = re.search(r"Age\s+0\s+1\s+2\s+3\+\s+M\s+([0-9.]+)\s+([0-9.]+)\s+([0-9.]+)\s+([0-9.]+)", annex_text)
assert m_rows, "Could not verify fixed M-at-age values in the stock annex."
m_values = [float(value) for value in m_rows.groups()]
for age in range(7):
    value = m_values[min(age, 3)]
    add_input("M", "natural_mortality_at_age", "per_year", value, "per_year",
              age=age, reference=f"{annex}; section B.2.2", notes="Fixed age-specific natural mortality, constant through years; ages 3-6 map to the source 3+ group.")

# Survey indices and reported precision
for year, label, values in matrix([32], 5):
    cv, *age_values = values
    for age, value in zip(range(1, 5), age_values):
        add_input("index", "numbers_at_age", "index_scale", value,
                  "native survey index (unit unresolved)", year=year, age=age,
                  survey="NIGFS-WIBTS-Q1 (G7144)", season="Q1",
                  reference=f"{report}; Table 6.13, printed p. 196",
                  notes="Age-specific survey index as reported; scale multiplier is not stated.")
    for age in range(1, 5):
        add_input("index", "relative_standard_error", "relative_scale", cv, "coefficient of variation",
                  year=year, age=age, survey="NIGFS-WIBTS-Q1 (G7144)", season="Q1",
                  reference=f"{report}; Table 6.13, printed p. 196",
                  notes="The table prints one annual CV beside the age-specific index vector; this value is repeated across ages for a rectangular source record, not evidence of age-specific CV estimates.")

for year, label, values in matrix([33], 2):
    cv, value = values
    if value is None:
        continue
    add_input("index", "numbers_at_age", "index_scale", value,
              "native survey index (unit unresolved)", year=year, age=0,
              survey="NIGFS-WIBTS-Q4 (G7655)", season="Q4",
              reference=f"{report}; Table 6.13, printed p. 197",
              notes="Age-0 recruitment survey index; scale multiplier is not stated.")
    if cv is not None:
        add_input("index", "relative_standard_error", "relative_scale", cv, "coefficient of variation",
                  year=year, age=0, survey="NIGFS-WIBTS-Q4 (G7655)", season="Q4",
                  reference=f"{report}; Table 6.13, printed p. 197",
                  notes="One annual CV is printed beside the age-0 index value.")

for year, label, values in matrix([34], 5):
    for age, value in zip(range(2, 7), values):
        add_input("index", "numbers_at_age", "index_scale", value,
                  "native survey index (unit unresolved)", year=year, age=age,
                  survey="UK FSP (B7897)", season="Q1",
                  reference=f"{report}; Table 6.13, printed p. 198",
                  notes="Age-specific spring survey index; scale multiplier is not stated. Age 6 is the 6+ group.")

for year, label, values in matrix([35], 2):
    cpue, sd = values
    add_input("index", "relative_biomass_index", "index_scale", cpue,
              "CPUE (reported unit not stated)", year=year,
              survey="NIGFS-WIBTS-Q1 CPUE (G7144)", season="Q1",
              reference=f"{report}; Table 6.13, printed p. 199",
              notes="Aggregate relative CPUE index, retained on the reported scale.")
    add_input("index", "index_sd", "index_scale", sd,
              "CPUE (reported unit not stated)", year=year,
              survey="NIGFS-WIBTS-Q1 CPUE (G7144)", season="Q1",
              reference=f"{report}; Table 6.13, printed p. 199",
              notes="Reported standard deviation on the native CPUE scale.")

# Annual landings and discards totals are assessment inputs, not fitted catch predictions.
for year, values in summary_rows():
    if year > 2025:
        continue
    landings, discards = values[6:8]
    add_input("catch", "total_biomass", "biomass", landings, "tonnes", year=year,
              fleet="landings", reference=f"{report}; Table 6.14, printed pp. 200-201",
              notes="ICES landings estimate used as an assessment input.")
    add_input("catch", "total_biomass", "biomass", discards, "tonnes", year=year,
              fleet="discards", reference=f"{report}; Table 6.14, printed pp. 200-201",
              notes="ICES discard estimate used as an assessment input; values before 2007 are reconstructed by the source.")

# Available annual assessment summaries and 95% confidence limits.
for year, values in summary_rows():
    if year > 2025:
        rec = values[0]
        ssb_low, ssb, ssb_high = values[1:4]
        add_output("recruitment", year, rec, "thousand_fish", age=0,
                   notes="2026 forecast recruitment is the 2016-2023 geometric mean, not a fitted estimate.")
        add_output("SSB", year, ssb, "tonnes", low=ssb_low, high=ssb_high,
                   notes="2026 forecast; 95% confidence limits as reported.")
        continue
    rec_low, rec, rec_high, ssb_low, ssb, ssb_high, _, _, f_low, f, f_high = values
    add_output("recruitment", year, rec, "thousand_fish", age=0,
               low=rec_low, high=rec_high,
               notes="Recruitment at age 0; pointwise 95% confidence limits as reported; point-estimate convention not specified.")
    add_output("SSB", year, ssb, "tonnes", low=ssb_low, high=ssb_high,
               notes="Pointwise 95% confidence limits as reported; spawning timing is not stated in the table.")
    add_output("Fbar", year, f, "per_year", age_group="2-4", low=f_low, high=f_high,
               notes="Fbar over ages 2-4; pointwise 95% confidence limits as reported; point-estimate convention not specified.")


def assumption(component, setting, value, reference, notes="", survey="", fleet=""):
    assumptions.append(dict(
        assessment_id=assessment, component=component, setting=setting, value=value,
        source_reference=reference, notes=notes, survey=survey, fleet=fleet,
        sex="", region="", season="",
    ))


for setting, value in [
    ("years", "1968-2025 fitted data; 2026 forecast"),
    ("ages", "0-6+"),
    ("recruitment_age", "0"),
    ("plus_group", "6+"),
    ("model_family", "Stock Synthesis 3 (SS3)"),
    ("fbar_ages", "2-4"),
    ("recreational_removals", "excluded from the assessment"),
]:
    assumption("population", setting, value, f"{report}; sections 6.2 and 6.3; Table 6.14")
assumption("catch", "age_observations", "Total catch numbers-at-age include landings and discards; years 2003-2005 and 2020 are excluded because sampling was limited.", f"{report}; Table 6.9, printed pp. 187-188")
assumption("catch", "landings_and_discards", "ICES estimates are used as assessment inputs; discard totals before 2007 are reconstructed.", f"{report}; Table 6.14, printed pp. 200-201")
assumption("M", "natural_mortality", "Fixed M at age: 1.7, 0.714, 0.68, 0.65 for ages 0, 1, 2, 3+; constant through years.", f"{annex}; section B.2.2")
assumption("biology", "weight_at_age", "Mean weight-at-age in landings is used for the whole stock and catch.", f"{report}; Table 6.10, printed pp. 189-190")
assumption("biology", "maturity", "Annual maturity ogive updated through 2024 and held constant from 2025; pre-1996 age-2 maturity is 0.27, age <2 is immature, and ages 3+ are mature.", f"{report}; Table 6.12; {annex}; section B.2.1")
assumption("F", "summary", "Fbar ages 2-4.", f"{annex}; Table C-2; {report}; Table 6.14")
assumption("F", "selectivity", "Catch selectivity follows age-based empirical random walks with estimated ages 2-3 and older ages following age 3; current annual control-file details were not recovered.", f"{annex}; Table C-2", notes="Model-configuration summary from the stock annex; exact 2026 SS3 control settings unavailable.")
assumption("recruitment", "stock_recruitment", "Beverton-Holt with recruitment blocks 1968-2001 and 2002-current+1 in the stock annex.", f"{annex}; Table C-2", notes="The current report does not provide the full 2026 SS3 control file; treat as the documented configuration, not a recovered native file.")
for survey, ages, period, season in [
    ("NIGFS-WIBTS-Q1 (G7144)", "1-4", "1995-2025", "Q1"),
    ("NIGFS-WIBTS-Q4 (G7655)", "0", "1995-2025 except 2024", "Q4"),
    ("UK FSP (B7897)", "2-6+", "2005-2025 except 2014 in Table 6.13", "Q1"),
]:
    assumption("index", "coverage", f"Ages {ages}; years {period}.", f"{report}; section 6.1 and Table 6.13", survey=survey)
    assumption("index", "sampling_time", f"{season}; exact within-year timing not stated in recovered source files.", f"{report}; section 6.1", survey=survey)
assumption("index", "Q1_CV", "One annual CV is reported beside the age 1-4 index vector and is repeated across its ages in the canonical long table; the current SS3 likelihood allocation is not independently verified.", f"{report}; Table 6.13", survey="NIGFS-WIBTS-Q1 (G7144)")
assumption("index", "FSP_effective_sample_size", "0.2 in the stock annex configuration; current 2026 setting not independently verified.", f"{annex}; Table C-2", survey="UK FSP (B7897)")
assumption("index", "FSP_year_coverage", "The assessment text summarizes 2004-2025; Table 6.13 contains observations beginning in 2005. The canonical database follows the numerical table.", f"{report}; section 6.1 and Table 6.13", survey="UK FSP (B7897)")
assumption("index", "aggregate_Q1_CPUE", "Aggregate CPUE and its native-scale SD are reported; tinyAM's age-specific index likelihood does not directly represent this aggregate series.", f"{report}; Table 6.13", survey="NIGFS-WIBTS-Q1 CPUE (G7144)")
assumption("assessment", "source_file_availability", "Detailed report tables and the current stock annex are available, but native 2026 SS3 data/control files were not recovered; exact likelihood weights and fitted model configurations remain unresolved.", report_doi)
assumption("assessment", "output_coverage", "Annual SSB, age-0 recruitment and Fbar 2-4 with 95% confidence limits are tabulated; age-specific N/F and estimated M outputs are not available in the recovered sources.", f"{report}; Table 6.14")

# Cross-check table summaries against the official machine-readable SAG export.
sag_rows = json.loads((cache / "ICES_SAG_23721_2026.json").read_text(encoding="utf-8"))
by_year = {int(row["Year"]): row for row in sag_rows if row.get("Year", "").isdigit()}
for row in outputs:
    year = int(row["year"])
    if year not in by_year or year > 2025:
        continue
    key = {"SSB": "StockSize", "recruitment": "Recruitment", "Fbar": "FishingPressure"}[row["measure"]]
    machine = float(by_year[year][key])
    tolerance = 0.0051 if row["measure"] == "Fbar" else 0.501
    assert abs(float(row["value"]) - machine) <= tolerance, (row["measure"], year, row["value"], machine)

assert len([r for r in inputs if r["type"] == "catch" and r["measure"] == "numbers_at_age"]) == 58 * 7
assert len([r for r in inputs if r["type"] == "weight"]) == 57 * 7 + 6
assert len([r for r in inputs if r["measure"] == "maturity_at_age"]) == 58 * 7
assert len([r for r in outputs if r["measure"] == "SSB"]) == 59
assert len([r for r in outputs if r["measure"] == "recruitment"]) == 59
assert len([r for r in outputs if r["measure"] == "Fbar"]) == 58

stock = dict(
    stock_id=stock_id, charbonneau_id="ICES-WGCSE_morhua_IS7a", authority="ICES",
    authority_stock_id="cod.27.7a", scientific_name="Gadus morhua",
    common_name="Irish Sea cod", area="Division 7.a", region="Irish Sea",
    ocean="Northeast Atlantic", notes="Current ICES assessment unit cod.27.7a; Charbonneau-Keith catalogue stock metadata."
)
assessment_row = dict(
    assessment_id=assessment, stock_id=stock_id, assessment_year=2026,
    terminal_year=2025, estimate_terminal_year=2026, assessment_type="annual_assessment",
    model_family="Stock Synthesis", model_version="SS3; exact version unavailable",
    is_current="TRUE", is_applied="TRUE", framework_year=2022,
    assessment_url=report_doi, framework_url=annex, data_url=sag,
    model_url="", repository_url="", assumptions_status="partial",
    inputs_status="partial", outputs_status="partial",
    notes="Applied 2026 ICES assessment, data through 2025 with forecast outputs for 2026. Numerical input tables and summary outputs were transcribed from the WGCSE chapter and checked against ICES SAG. Native SS3 input/control files were not recovered; the report does not provide age-specific N/F outputs or estimated M. Survey index scales and some likelihood weighting details remain unresolved."
)


def replace_assessment(filename, new_rows, key="assessment_id"):
    path = root / "database" / filename
    content = path.read_bytes().decode("utf-8-sig")
    reader = csv.DictReader(io.StringIO(content))
    fields = reader.fieldnames
    old = list(reader)
    lines = content.splitlines(keepends=True)
    assert len(lines) == len(old) + 1, f"Unexpected multiline CSV row in {filename}"
    remove_value = stock_id if key == "stock_id" else assessment
    preserved = [lines[0]] + [line for line, row in zip(lines[1:], old) if row[key] != remove_value]
    with path.open("w", newline="", encoding="utf-8") as stream:
        stream.writelines(preserved)
        writer = csv.DictWriter(stream, fields)
        writer.writerows({field: row.get(field, "") for field in fields} for row in new_rows)


replace_assessment("stocks.csv", [stock], "stock_id")
replace_assessment("assessments.csv", [assessment_row])
replace_assessment("assumptions.csv", assumptions)
replace_assessment("inputs.csv", inputs)
replace_assessment("outputs.csv", outputs)
print(f"Imported {len(inputs)} inputs, {len(outputs)} outputs and {len(assumptions)} assumptions for {assessment}.")
