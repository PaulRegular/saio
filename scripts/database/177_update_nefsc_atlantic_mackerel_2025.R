root <- "."
db_dir <- file.path(root, "database")
assessment_id <- "nefsc_atlantic_mackerel_2025"
report_url <- "https://www.mafmc.org/s/e_Northwest_Atlantic_Mackerel_Update_2025.pdf"
report_reference <- paste0(
  "2025 Atlantic Mackerel Management Track Assessment Report, draft working paper for peer review, ",
  "Mid-Atlantic Fishery Management Council October 2025 meeting materials (",
  report_url, ")"
)

read_db <- function(name) {
  read.csv(file.path(db_dir, paste0(name, ".csv")), stringsAsFactors = FALSE,
    check.names = FALSE)
}

inputs <- read_db("inputs")
outputs <- read_db("outputs")
assumptions <- read_db("assumptions")
assessments <- read_db("assessments")
if (!assessment_id %in% assessments$assessment_id) {
  stop("The 2025 Atlantic mackerel assessment must already be registered.", call. = FALSE)
}
if (any(inputs$assessment_id == assessment_id & inputs$measure == "total_biomass") ||
  any(outputs$assessment_id == assessment_id & outputs$measure %in% c(
    "predicted_catch", "Fmsy", "Bmsy", "msy", "median_recruitment"
  )) ||
  any(assumptions$assessment_id == assessment_id & assumptions$setting %in% c(
    "assessment_method", "natural_mortality", "projection_recruitment",
    "projection_biology", "projection_catch", "projection_fishing_rate"
  ))) {
  stop("The 2025 Atlantic mackerel source additions are already present.", call. = FALSE)
}

years <- 2015:2024
catch <- c(14176, 18319, 20971, 22195, 16445, 18188, 12538, 3557, 5699, 3610)
input_notes <- paste(
  "Stock-wide total catch as reported in the assessment status table.",
  "This aggregate summary is not age-specific catch-at-age and does not identify",
  "the modeled fleet inputs; it must not be used as a substitute for the missing",
  "ASAP catch-at-age or age-composition data. The assessment remains input-partial."
)
inputs_add <- data.frame(
  assessment_id = assessment_id, type = "catch", measure = "total_biomass",
  basis = "biomass", fleet = "", survey = "", sex = "", region = "", season = "",
  year = years, year_basis = "calendar_year", age = NA_real_, value = catch,
  unit = "metric tons", sampling_time = NA_real_, source_type = "official_table",
  source_reference = paste(report_reference, "Table 1, p. 1"), transformation = "",
  notes = input_notes, observation_id = "", length_bin = NA_real_,
  length_bin_lower = NA_real_, length_bin_upper = NA_real_, sample_size = NA_real_,
  age_error = NA_real_, partition = NA_real_, stringsAsFactors = FALSE
)

new_output <- function(type, measure, year = NA_real_, value, unit,
                       age = NA_real_, age_group = "", lwr = NA_real_,
                       upr = NA_real_, notes) {
  n <- length(value)
  if (length(year) == 1L && is.na(year)) year <- rep(NA_real_, n)
  if (length(age) == 1L) age <- rep(age, n)
  if (length(age_group) == 1L) age_group <- rep(age_group, n)
  if (length(lwr) == 1L) lwr <- rep(lwr, n)
  if (length(upr) == 1L) upr <- rep(upr, n)
  data.frame(
    assessment_id = assessment_id, type = type, measure = measure, fleet = "",
    survey = "", sex = "", region = "", season = "", year = year,
    age = age, age_group = age_group, value = value, se = NA_real_,
    lwr = lwr, upr = upr, unit = unit, source_type = "official_table",
    source_reference = paste(report_reference, "Tables 2-3, pp. 1-2"),
    notes = notes, stringsAsFactors = FALSE
  )
}

projection_years <- 2025:2028
projection_notes <- paste(
  "Short-term projection from Table 3 under the reported harvest scenario.",
  "Values are projected quantities, not historical observations. The report",
  "prints lower and upper SSB ranges but does not state their interval level",
  "in the table."
)
outputs_add <- rbind(
  new_output(
    "catch", "predicted_catch", projection_years,
    c(3625, 50376, 50029, 48760), "metric tons",
    notes = paste(
      projection_notes,
      "The 2025 total is an assumed catch (Canada TAC 500 mt plus U.S. ACL 3,125 mt);",
      "2026-2028 catches are projected under FMSY proxy."
    )
  ),
  new_output(
    "biomass", "SSB", projection_years,
    c(240626, 286004, 278154, 268913), "metric tons",
    lwr = c(120779, 149527, 150198, 149049),
    upr = c(464698, 542599, 516437, 490049), notes = projection_notes
  ),
  new_output(
    "mortality", "Fbar", projection_years, c(0.019, 0.2, 0.2, 0.2),
    "per year", age_group = "6+",
    notes = paste(projection_notes, "F is for the fully selected ages 6+.")
  ),
  new_output(
    "mortality", "Fmsy", value = 0.2, unit = "per year",
    notes = paste(
      "F40% overfishing-threshold proxy from Table 2; the assessment report",
      "labels this FMSY proxy, not an unqualified FMSY estimate."
    )
  ),
  new_output(
    "biomass", "Bmsy", value = 169139, unit = "metric tons",
    lwr = 91371, upr = 352116,
    notes = paste(
      "SSBMSY biomass target proxy from Table 2. Parenthetical bounds are",
      "reported in the source; their interval level is not specified in Table 2."
    )
  ),
  new_output(
    "catch", "msy", value = 31216, unit = "metric tons",
    lwr = 16978, upr = 62902,
    notes = paste(
      "MSY proxy from Table 2. Parenthetical bounds are reported in the source;",
      "their interval level is not specified in Table 2."
    )
  ),
  new_output(
    "recruitment", "median_recruitment", value = 176521,
    unit = "thousand fish", age = 1,
    notes = "Reported median age-1 recruitment reference point from Table 2; this is not an annual recruitment estimate."
  )
)

assumptions_add <- data.frame(
  assessment_id = assessment_id,
  component = c("assessment", "M", "projection", "projection", "projection", "projection"),
  fleet = "", survey = "", sex = "", region = "", season = "",
  setting = c(
    "assessment_method", "natural_mortality", "projection_recruitment",
    "projection_biology", "projection_catch", "projection_fishing_rate"
  ),
  value = c(
    "Level 1 update of the 2023 management-track assessment using ASAP; a planned Level 3 WHAM assessment was delayed by data availability.",
    "Assumed constant over age and time; the report says the likelihood profile supports the assumed value but does not state the 2025 run's numerical value.",
    "Two recruitment stanzas: sample from 2009 onward when projected SSB is below one-half of SSBMSY proxy, otherwise sample from 1975 onward.",
    "Projection selectivity, maturity ogive, and mean weights-at-age use the most recent five-year averages.",
    "2025 stock-wide catch assumed to be 3,625 mt: Canadian TAC 500 mt plus U.S. ACL 3,125 mt.",
    "Projection harvest scenario uses the FMSY proxy from 2026 through 2028."
  ),
  source_reference = c(
    paste(report_reference, "p. 1"), paste(report_reference, "p. 2"),
    paste(report_reference, "p. 2"), paste(report_reference, "p. 2"),
    paste(report_reference, "Table 3, p. 2"), paste(report_reference, "Table 3, p. 2")
  ),
  notes = c(
    "The report is explicitly labeled a draft working paper for peer review; MAFMC posted it with the October 2025 SSC meeting materials.",
    "The 2023 model's M value is not copied here as the exact 2025 run configuration was not recovered.",
    "The report describes this stochastic projection rule; it is not the historical assessment recruitment likelihood.",
    "Projection biology is averaged and may differ from historical year-specific inputs.",
    "This is a projection scenario, not an observed catch-at-age input.",
    "The reported F proxy is also recorded as a reference-point output."
  ), stringsAsFactors = FALSE
)

if (nrow(inputs_add) != 10L || nrow(outputs_add) != 16L ||
  any(!is.finite(inputs_add$value)) || any(!is.finite(outputs_add$value)) ||
  any(inputs_add$value < 0) || any(outputs_add$year[outputs_add$measure %in% c(
    "SSB", "Fbar", "predicted_catch"
  )] != rep(projection_years, 3L))) {
  stop("The 2025 Atlantic mackerel additions failed source-value or dimension checks.", call. = FALSE)
}

append_rows <- function(name, rows) {
  path <- file.path(db_dir, paste0(name, ".csv"))
  existing <- read.csv(path, stringsAsFactors = FALSE, check.names = FALSE)
  if (!setequal(names(rows), names(existing))) stop("Column mismatch for ", name, ".csv.", call. = FALSE)
  utils::write.table(rows[names(existing)], path, sep = ",", quote = TRUE,
    row.names = FALSE, col.names = FALSE, append = TRUE, na = "")
}

append_rows("inputs", inputs_add)
append_rows("outputs", outputs_add)
append_rows("assumptions", assumptions_add)
cat("Added 10 aggregate 2015-2024 catch records, 16 2025 assessment/projection outputs, and six projection/model assumptions.\n")
