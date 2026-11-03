root <- "."
cache <- file.path(root, "source_cache/afsc_pollock_ebs_2024")
data_file <- file.path(cache, "pm_24.dat")
inputs_file <- file.path(root, "database/inputs.csv")
assessment_id <- "afsc_pollock_ebs_2024"
revision <- "44e0cb0ac8698e1d3954273e8aaf760d7c76cba5"
source_url <- paste0(
  "https://github.com/noaa-afsc/EBS_pollock/blob/",
  revision, "/runs/data/pm_24.dat; "
)

data_lines <- trimws(readLines(data_file, warn = FALSE))
read_block <- function(name) {
  i <- which(data_lines == paste0("#", name))
  stopifnot(length(i) == 1L)
  j <- which(seq_along(data_lines) > i & startsWith(data_lines, "#"))[1]
  if (is.na(j)) j <- length(data_lines) + 1L
  block_lines <- sub("/.*$", "", data_lines[(i + 1L):(j - 1L)])
  values <- suppressWarnings(as.numeric(unlist(strsplit(
    block_lines, "[[:space:]]+"
  ))))
  values[is.finite(values)]
}

years <- list(
  bts = read_block("yrs_bts_data"),
  ats = read_block("yrs_ats_data"),
  avo = read_block("yrs_avo"),
  cpue = read_block("yrs_cpue")
)
weights <- list(
  bts = matrix(read_block("wt_bts"), nrow = length(years$bts), byrow = TRUE),
  ats = matrix(read_block("wt_ats"), nrow = length(years$ats), byrow = TRUE),
  avo = matrix(read_block("wt_avo"), nrow = length(years$avo), byrow = TRUE)
)
sds <- list(
  bts = read_block("ob_bts_std"),
  ats = read_block("ob_ats_std"),
  avo = read_block("ob_avo_std"),
  cpue = read_block("obs_cpue_std")
)
stopifnot(
  ncol(weights$bts) == 15L, ncol(weights$ats) == 15L,
  ncol(weights$avo) == 15L,
  lengths(sds) == lengths(years),
  all(lengths(sds) == lengths(years))
)

inputs <- read.csv(inputs_file, stringsAsFactors = FALSE, check.names = FALSE)
inputs <- inputs[!(inputs$assessment_id == assessment_id &
  ((inputs$type == "weight" &
    inputs$measure == "weight_at_age" &
    !is.na(inputs$survey) & nzchar(inputs$survey)) |
    inputs$measure == "index_sd" |
    inputs$measure == "proportion_at_length" |
    inputs$measure == "environmental_covariate")), ]
empty_row <- as.list(setNames(rep("", ncol(inputs)), names(inputs)))
rows <- list()
add_row <- function(...) {
  row <- empty_row
  values <- list(...)
  for (name in names(values)) row[[name]] <- as.character(values[[name]])
  rows[[length(rows) + 1L]] <<- as.data.frame(row, stringsAsFactors = FALSE)
}
number <- function(x) format(x, digits = 17, trim = TRUE, scientific = FALSE)

survey_names <- c(
  bts = "NMFS bottom-trawl VAST",
  ats = "NMFS acoustic-trawl",
  avo = "Acoustic vessels of opportunity"
)
survey_times <- c(bts = 0.5, ats = 0.5, avo = NA_real_)
for (series in names(weights)) {
  for (i in seq_along(years[[series]])) {
    for (age in seq_len(ncol(weights[[series]]))) {
      add_row(
        assessment_id = assessment_id, type = "weight", measure = "weight_at_age",
        basis = "kg_per_fish", survey = survey_names[[series]],
        year = years[[series]][i], year_basis = "calendar_year", age = age,
        value = number(weights[[series]][i, age]), unit = "kg",
        sampling_time = if (is.na(survey_times[[series]])) "" else survey_times[[series]],
        source_type = "native_model",
        source_reference = paste0(source_url, "wt_", series),
        notes = "Survey-specific weight-at-age matrix used in the official model; age 15 is 15+."
      )
    }
  }
}

index_series <- list(
  cpue = list(
    name = "Historical fishery CPUE", unit = "native biomass-proportional index",
    note = "Native-scale SD used in the CPUE residual likelihood."
  ),
  avo = list(
    name = "Acoustic vessels of opportunity", unit = "native biomass-proportional index",
    note = "Native-scale SD used in the AVO residual likelihood."
  ),
  bts = list(
    name = survey_names[["bts"]], unit = "thousand t",
    note = "Supplied native-scale SD vector; the official DoCovBTS=1 likelihood instead uses the full supplied covariance matrix."
  ),
  ats = list(
    name = survey_names[["ats"]], unit = "thousand t",
    note = "Supplied native-scale SD converted by the source model to log-scale variance for its biomass-index likelihood."
  )
)
for (series in names(sds)) {
  stopifnot(length(sds[[series]]) == length(years[[series]]))
  for (i in seq_along(years[[series]])) {
    add_row(
      assessment_id = assessment_id, type = "index", measure = "index_sd",
      basis = "index_scale", survey = index_series[[series]]$name,
      year = years[[series]][i], year_basis = "calendar_year",
      value = number(sds[[series]][i]), unit = index_series[[series]]$unit,
      sampling_time = if (series %in% c("bts", "ats")) 0.5 else "",
      source_type = "native_model",
      source_reference = paste0(source_url, switch(series,
        cpue = "obs_cpue_std",
        avo = "ob_avo_std",
        bts = "ob_bts_std",
        ats = "ob_ats_std"
      )),
      notes = index_series[[series]]$note
    )
  }
}

bottom_temperature <- read_block("bottom_temp")
stopifnot(length(bottom_temperature) == length(years$bts))
for (i in seq_along(years$bts)) {
  add_row(
    assessment_id = assessment_id, type = "covariate",
    measure = "environmental_covariate", basis = "native_covariate",
    survey = survey_names[["bts"]], year = years$bts[i],
    year_basis = "calendar_year", value = number(bottom_temperature[i]),
    unit = "native temperature units",
    source_type = "native_model", source_reference = paste0(source_url, "bottom_temp"),
    notes = "Bottom-trawl-year temperature covariate supplied to the model; native input does not state a unit. The fitted temperature slope is fixed at zero in this control."
  )
}

length_comp <- read_block("olc_fsh")
stopifnot(length(length_comp) == 50L)
length_comp <- length_comp / sum(length_comp)
for (i in seq_along(length_comp)) {
  add_row(
    assessment_id = assessment_id, type = "catch", measure = "proportion_at_length",
    basis = "proportion_numbers", fleet = "Combined fishery",
    value = number(length_comp[i]), unit = "proportion", sample_size = 50,
    observation_id = "ebs_fishery_length_composition",
    length_bin = 19 + i, source_type = "native_model",
    source_reference = paste0(source_url, "olc_fsh"),
    transformation = "Normalized by the vector sum, as in source_pm.tpl.",
    notes = "Single fishery length-composition vector; model applies a fixed likelihood weight of 50. The source code defines bin values 20 through 69 in unit increments; the input file does not state the length unit."
  )
}

new_inputs <- do.call(rbind, rows)
inputs <- rbind(inputs, new_inputs)
write.csv(inputs, inputs_file, row.names = FALSE, na = "")

assessments_file <- file.path(root, "database/assessments.csv")
assessments <- read.csv(assessments_file, stringsAsFactors = FALSE, check.names = FALSE)
assessment_row <- assessments$assessment_id == assessment_id
old_note <- "M, covariance/sample-size/SD export, detailed statistical assumptions, F-at-age and uncertainty remain incomplete."
assessments$notes[assessment_row] <- gsub(
  old_note,
  "F-at-age, output uncertainty, and some statistical assumptions remain incomplete; inputs status remains partial pending the item-by-item native-input review.",
  assessments$notes[assessment_row],
  fixed = TRUE
)
write.csv(assessments, assessments_file, row.names = FALSE, na = "")
message("Imported ", nrow(new_inputs), " EBS survey-weight, index-SD, temperature, and length-composition rows.")
