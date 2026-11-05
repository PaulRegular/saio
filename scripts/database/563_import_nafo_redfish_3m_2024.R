root <- "."
assessment_id <- "nafo_redfish_3m_2024"
stock_id <- "nafo_redfish_3m"
candidate_id <- "NAFO:redfish.3M"

read_csv <- function(path) read.csv(path, stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
append_csv <- function(x, path) write.table(x, path, sep = ",", quote = TRUE,
  row.names = FALSE, col.names = FALSE, append = TRUE, na = "",
  qmethod = "double")
source(file.path(root, "scripts", "database", "candidate_register_io.R"))

add_input <- function(year, value) data.frame(
  assessment_id = assessment_id, type = "catch", measure = "total_biomass",
  basis = "biomass", fleet = "NAFO Division 3M fisheries", survey = "",
  sex = "", region = "NAFO Division 3M", season = "", year = year,
  year_basis = "calendar_year", age = NA_real_, value = value,
  unit = "1000 tonnes", sampling_time = NA_real_, source_type = "official_table",
  source_reference = "NAFO SCS Doc. 24/16, Section V.4.e, p. 161",
  transformation = "None; the table reports STACFIS estimated beaked redfish catch in thousands of tonnes.",
  notes = "Estimated beaked redfish catch based on observed species proportions; not the age-specific catch-at-age series used by XSA.",
  observation_id = NA_character_, length_bin = NA_character_,
  length_bin_lower = NA_real_, length_bin_upper = NA_real_, sample_size = NA_real_,
  age_error = NA_character_, partition = NA_character_, stringsAsFactors = FALSE
)

assumptions <- list()
add_assumption <- function(component, setting, value, source_reference, notes = "") {
  assumptions[[length(assumptions) + 1L]] <<- data.frame(
    assessment_id = assessment_id, component = component, fleet = "", survey = "",
    sex = "", region = "NAFO Division 3M", season = "", setting = setting,
    value = as.character(value), source_reference = source_reference,
    notes = notes, stringsAsFactors = FALSE
  )
}

add_assumption("assessment", "assessment_method", "XSA age-based assessment",
  "NAFO SCS Doc. 24/16, Section V.4.e–f, pp. 161–162",
  "The separate SCR 2024/032 assessment document is listed in the NAFO catalogue but its download link is unavailable; the Scientific Council report provides the accessible run summary.")
add_assumption("population", "assessment_years", "1989–2023",
  "NAFO SCS Doc. 24/16, Section V.4.e–h, pp. 161–164",
  "The assessment uses age-based XSA; annual numeric fitted inputs and population trajectories are not tabulated in the accessible report.")
add_assumption("population", "assessment_ages", "4–19+",
  "NAFO SCS Doc. 24/16, Section V.4.e, p. 161",
  "The model's oldest group is 19+; projection calculations extended ages internally beyond the XSA range.")
add_assumption("population", "species_definition", "Combined Sebastes mentella and Sebastes fasciatus",
  "NAFO SCR Doc. 24/024, pp. 1–2; NAFO SCS Doc. 24/16, Section V.4.e, p. 161",
  "Golden redfish (Sebastes norvegicus) is not part of the modeled stock.")
add_assumption("index", "survey", "EU Flemish Cap summer bottom-trawl survey, Div. 3M, ages 4–19+",
  "NAFO SCR Doc. 24/024; NAFO SCR Doc. 24/005; NAFO SCS Doc. 24/16, Section V.4.e, p. 161",
  "The precise age-specific index matrix used by XSA was not recoverable from the accessible documents.")
add_assumption("catch", "catch_at_age", "Commercial catch-at-age is used by XSA; numerical age-year matrix not recovered",
  "NAFO SCS Doc. 24/16, Section V.4.e, p. 161; NAFO SCR Doc. 24/024",
  "The report's beaked redfish total catch series is imported separately and is not a substitute for the missing age-specific matrix.")
add_assumption("mortality", "natural_mortality_history", "M=0.1 before 2006; M=0.4 tuned to ages 4–6 during 2006–2010 and applied to all ages in 2009–2010; M=0.125 in 2011–2012; M=0.14 in 2013–2014; M=0.10 from 2015 onward",
  "NAFO SCS Doc. 24/16, Section V.4.e, p. 161; NAFO SCR Doc. 24/024",
  "Historical M settings are recorded as documented; the complete year-by-age M matrix was not recovered.")
add_assumption("index", "catchability", "Catchability is independent of stock size; age-independent for ages 16 and older",
  "NAFO SCS Doc. 24/16, Section V.4.e, p. 161",
  "Numerical age-year catchability estimates were not available in the accessible report.")
add_assumption("population", "time_weighting", "No tapered time weights",
  "NAFO SCS Doc. 24/16, Section V.4.e, p. 161",
  "")
add_assumption("population", "terminal_survivor_shrinkage", "Terminal survivors are not shrunk to mean F; oldest-age survivors are not shrunk",
  "NAFO SCS Doc. 24/16, Section V.4.e, p. 161",
  "")
add_assumption("population", "minimum_standard_error", "0.5",
  "NAFO SCS Doc. 24/16, Section V.4.e, p. 161",
  "Minimum standard error for population estimates at the last true age of each cohort.")
add_assumption("projection", "mortality", "M=0.10 with allowed variability from 0.08 to 0.12",
  "NAFO SCS Doc. 24/16, Section V.4.h, p. 163",
  "This is the projection assumption, not a full record of historical assessment M.")
add_assumption("projection", "recruitment", "2024 age-4 recruitment uses the geometric mean of 2021–2023; recruitment is resampled for 2025–2026",
  "NAFO SCS Doc. 24/16, Section V.4.h, p. 163",
  "")
add_assumption("projection", "fishing_mortality_scenarios", "F=0; F0.1=0.0675; F=M=0.1; Fstatusquo=0.0585; 1.25 TAC; TAC; 0.75 TAC",
  "NAFO SCS Doc. 24/16, Section V.4.h, Table 7.1, pp. 163-164",
  "Projection output rows carry the source scenario in the scenario field.")
add_assumption("projection", "scenario_outputs_recorded", "All seven scenarios", "NAFO SCS Doc. 24/16, Table 7.1, p. 164", "The common 2025 SSB is recorded once; scenario-specific SSB for 2026-2027, yield, and TAC are keyed by scenario. SSB intervals are central 80%.")
add_assumption("reference_points", "F0.1", "0.0675 (candidate; not confirmed)",
  "NAFO SCS Doc. 24/16, Section V.4.g, p. 163",
  "No accepted limit reference point is available; Fmax is considered highly uncertain and was not accepted.")

projection_scenarios <- list(
  "F=0" = list(ssb = c(50199, 51014, 51356), lwr = c(44661, 45564, 46045), upr = c(59311, 59659, 59688), yield = c(0, 0), tac = c(0, 0)),
  "F0.1=0.0675" = list(ssb = c(50199, 44603, 39608), lwr = c(44661, 39919, 35681), upr = c(59311, 51955, 45815), yield = c(21378, 18652), tac = c(22445, 19584)),
  "F=M=0.1" = list(ssb = c(50199, 41849, 35170), lwr = c(44661, 37548, 31672), upr = c(59311, 48711, 40488), yield = c(30659, 25087), tac = c(32189, 26339)),
  "Fstatusquo=0.0585" = list(ssb = c(50199, 45409, 40983), lwr = c(44661, 40641, 36895), upr = c(59311, 52891, 47412), yield = c(18689, 16599), tac = c(19622, 17428)),
  "1.25 TAC" = list(ssb = c(50199, 44769, 39884), lwr = c(44661, 40062, 35925), upr = c(59311, 52137, 46117), yield = c(20839, 18247), tac = c(21879, 19158)),
  "TAC" = list(ssb = c(50199, 45993, 42045), lwr = c(44661, 41174, 37850), upr = c(59311, 53600, 48636), yield = c(16671, 15007), tac = c(17503, 15756)),
  "0.75 TAC" = list(ssb = c(50199, 47251, 44292), lwr = c(44661, 42261, 39825), upr = c(59311, 55078, 51233), yield = c(12503, 11555), tac = c(13127, 12131))
)
outputs <- list()
add_output <- function(type, measure, year, value, unit, se = NA_real_, lwr = NA_real_, upr = NA_real_, notes, source_reference, scenario = "") {
  outputs[[length(outputs) + 1L]] <<- data.frame(
    assessment_id = assessment_id, type = type, measure = measure, fleet = "",
    survey = "", sex = "", region = "NAFO Division 3M", season = "",
    year = as.integer(year), age = NA_real_, age_group = "", value = value,
    se = se, lwr = lwr, upr = upr, unit = unit, source_type = "official_table",
    source_reference = source_reference, notes = notes, scenario = scenario, stringsAsFactors = FALSE
  )
}

projection_ref <- "NAFO SCS Doc. 24/16, Table 7.1, p. 164"
add_output("biomass", "SSB", 2024, 52117, "tonnes",
  notes = "Deterministic SSB at the beginning of 2024, common to all projection scenarios.", source_reference = projection_ref)
add_output("catch", "yield", 2024, 13195, "tonnes",
  notes = "Deterministic 2024 baseline yield for beaked redfish, common to all projection scenarios.", source_reference = projection_ref)
add_output("catch", "catch_advice", 2024, 17503, "tonnes",
  notes = "2024 baseline TAC for all three redfish species combined; this is not beaked-redfish catch.", source_reference = projection_ref)
add_output("biomass", "SSB", 2025, 50199, "tonnes", lwr = 44661, upr = 59311,
  notes = "50th percentile common to all seven scenarios; interval is central 80% (10th-90th percentiles).",
  source_reference = projection_ref)
for (scenario in names(projection_scenarios)) {
  z <- projection_scenarios[[scenario]]
  for (i in 2:3) {
    year <- 2024L + i
    add_output("biomass", "SSB", year, z$ssb[[i]], "tonnes",
      lwr = z$lwr[[i]], upr = z$upr[[i]],
      notes = paste0("50th percentile under scenario ", scenario, "; interval is central 80% (10th-90th percentiles)."),
      source_reference = projection_ref, scenario = scenario)
  }
  for (i in seq_along(2025:2026)) {
    year <- 2024L + i
    add_output("catch", "yield", year, z$yield[[i]], "tonnes",
      notes = paste0("Projected beaked-redfish yield (50th percentile) under scenario ", scenario, "."),
      source_reference = projection_ref, scenario = scenario)
    add_output("catch", "catch_advice", year, z$tac[[i]], "tonnes",
      notes = paste0("TAC for all three redfish species combined under scenario ", scenario, "; not beaked-redfish yield."),
      source_reference = projection_ref, scenario = scenario)
  }
}

assumptions_new <- do.call(rbind, assumptions)
inputs_new <- do.call(rbind, lapply(2015:2023, function(year) {
  values <- c(5.2, 6.2, 6.9, 10.3, 10.2, 8.7, 8.3, 9.4, 9.4)
  add_input(year, values[[year - 2014L]])
}))
outputs_new <- do.call(rbind, outputs)

stock_new <- data.frame(
  stock_id = stock_id, charbonneau_id = "", authority = "NAFO",
  authority_stock_id = "redfish.3M",
  scientific_name = "Sebastes mentella; Sebastes fasciatus",
  common_name = "Beaked redfish", area = "NAFO Division 3M (Flemish Cap)",
  region = "Flemish Cap", ocean = "Northwest Atlantic",
  notes = "The assessed stock combines beaked redfish Sebastes mentella and S. fasciatus; golden redfish S. norvegicus is not included.",
  stringsAsFactors = FALSE
)
assessment_new <- data.frame(
  assessment_id = assessment_id, stock_id = stock_id, assessment_year = 2024L,
  terminal_year = 2023L, estimate_terminal_year = 2027L,
  assessment_type = "full_assessment", model_family = "XSA",
  model_version = "2024 production XSA; software/version not reported in accessible sources",
  is_current = TRUE, is_applied = TRUE, framework_year = NA_integer_,
  assessment_url = "https://www.nafo.int/Portals/0/PDFs/sc/2024/scs24-16rev.pdf",
  framework_url = "https://www.nafo.int/Portals/0/PDFs/sc/2024/scr24-024.pdf",
  data_url = "https://www.nafo.int/Portals/0/PDFs/sc/2024/scr24-024.pdf",
  model_url = "", repository_url = "", assumptions_status = "partial",
  inputs_status = "partial", outputs_status = "partial",
  notes = "The accessible 2024 Council report summarizes the accepted full XSA and projection tables; the separately listed SCR 2024/032 assessment PDF has no download link and its direct PDF URL returns 404. Numerical age-specific catch, survey, biological and fitted-state matrices were not recovered. The imported catch totals and projections do not reproduce the full XSA input or output series.",
  stringsAsFactors = FALSE
)

stocks_path <- file.path(root, "database", "stocks.csv")
assessments_path <- file.path(root, "database", "assessments.csv")
assumptions_path <- file.path(root, "database", "assumptions.csv")
inputs_path <- file.path(root, "database", "inputs.csv")
outputs_path <- file.path(root, "database", "outputs.csv")
candidate_path <- file.path(root, "discovery", "candidates.csv")
stocks <- read_csv(stocks_path)
assessments <- read_csv(assessments_path)
candidates <- read_csv(candidate_path)
if (!identical(Sys.getenv("SAIO_NAFO_IMPORT_DRY_RUN"), "1") && (stock_id %in% stocks$stock_id || assessment_id %in% assessments$assessment_id)) stop("Stock or assessment already exists; inspect before importing.", call. = FALSE)
candidate_row <- which(candidates$candidate_id == candidate_id)
if (length(candidate_row) != 1L || candidates$candidate_unit_id[candidate_row] != stock_id) stop("Expected one candidate matching the NAFO 3M beaked-redfish unit.", call. = FALSE)
if (nrow(assumptions_new) != 16L || nrow(inputs_new) != 9L || nrow(outputs_new) != 46L) stop("Unexpected redfish extraction row counts.", call. = FALSE)
if (any(!is.finite(inputs_new$value)) || any(!is.finite(outputs_new$value)) || any(outputs_new$lwr > outputs_new$upr, na.rm = TRUE)) stop("Non-finite or invalid redfish values.", call. = FALSE)

if (identical(Sys.getenv("SAIO_NAFO_IMPORT_DRY_RUN"), "1")) {
  message("Dry run only: ", nrow(inputs_new), " inputs; ", nrow(assumptions_new), " assumptions; ", nrow(outputs_new), " outputs.")
  quit(save = "no", status = 0L)
}

has_assessment <- function(path, id) {
  con <- file(path, open = "r"); on.exit(close(con), add = TRUE)
  prefix <- paste0("\"", id, "\",\"")
  repeat { lines <- readLines(con, n = 100000L, warn = FALSE); if (!length(lines)) return(FALSE); if (any(startsWith(lines, prefix))) return(TRUE) }
}
for (path in c(assumptions_path, inputs_path, outputs_path)) if (has_assessment(path, assessment_id)) stop("Assessment rows already exist; inspect before importing.", call. = FALSE)
append_csv(stock_new, stocks_path)
append_csv(assessment_new, assessments_path)
append_csv(assumptions_new, assumptions_path)
append_csv(inputs_new, inputs_path)
append_csv(outputs_new, outputs_path)
candidates$matched_stock_id[candidate_row] <- stock_id
candidates$match_status[candidate_row] <- "matched"
candidates$inventory_assessment_year[candidate_row] <- 2024L
candidates$import_status[candidate_row] <- "partial"
candidates$notes[candidate_row] <- "The latest accessible full age-based assessment is the 2024 XSA. The 2026 full assessment was deferred and no later production XSA tables were found. The 2024 assessment PDF SCR 24/032 is listed by NAFO but unavailable for download; current records contain only the accessible beaked catch totals, documented assumptions and projection results."
replace_candidate_register_row(candidate_path, candidate_row, candidates[candidate_row, , drop = FALSE], candidate_id)
message("Imported ", assessment_id, ": ", nrow(inputs_new), " inputs; ", nrow(assumptions_new), " assumptions; ", nrow(outputs_new), " outputs.")




