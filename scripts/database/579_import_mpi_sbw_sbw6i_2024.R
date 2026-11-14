root <- "."
args <- commandArgs(trailingOnly = TRUE)
write_mode <- "--write" %in% args
stock_id <- "mpi_sbw_sbw6i"
assessment_id <- "mpi_sbw_sbw6i_2024"
candidate_id <- "MPI:SBW6I"
source_dir <- "source_cache/mpi_sbw_sbw6i_2023"
source_files <- file.path(source_dir, c(
  "FAR-2024-37-SBW-6I-assessment.pdf",
  "FAR-2023-63-SBW-input-data-review.pdf",
  "FAR-2023-37-SBW-6I-acoustic-survey.pdf",
  "FAP-2025-SBW-plenary.pdf",
  "FAR-2025-44-SBW-6I-6B-catch-at-age.pdf",
  "FAR-2026-38-SBW-6I-6B-catch-at-age.pdf"
))
source_hashes <- c(
  "F746EE559E8D6403B7CB7DDB2292B4A977EF778E1C900ABE54338C1FEF588396",
  "4AA109FC8ECA83B9DC60294704A0E2E531278538D62ABC68789342D203CC3D77",
  "897A8F624AB001990DAB831D546343031C90A79913394EA9B397CE88CBC6B8E5",
  "41959A0C34B235C97BFD5DC70EF2AD2E4489761C8D1929F4AD1402C96E461CAA",
  "D3765074B8789F197274FCB077573D9A9C0301DB39B3F81C78D913180D5462DC",
  "294AA93630CAAFB2CFE71D445A06AD7832C1B9C8A8BAAFF74FA22A7484688C53"
)

if (!all(file.exists(source_files))) {
  stop("Cache the six reviewed SBW 6I sources before importing.", call. = FALSE)
}
actual_hashes <- toupper(unname(tools::sha256sum(source_files)))
if (!identical(actual_hashes, source_hashes)) {
  stop("A cached SBW 6I source differs from the reviewed file.", call. = FALSE)
}

catch <- read.table(text = "
source_period catch_t
1971 7260
1972 18010
1973 33856
1974 29458
1975 1660
1976 11929
1977 18453
1978 6403
1978-79 25305
1979-80 12828
1980-81 5989
1981-82 7915
1982-83 12803
1983-84 10777
1984-85 7490
1985-86 15252
1986-87 12804
1987-88 17422
1988-89 26611
1989-90 16542
1990-91 21314
1991-92 14208
1992-93 9316
1993-94 11668
1994-95 9492
1995-96 14959
1996-97 15685
1997-98 24273
1998-00 30386
2000-01 18049
2001-02 29999
2002-03 33445
2003-04 23718
2004-05 19799
2005-06 26190
2006-07 19763
2007-08 20996
2008-09 20483
2009-10 19040
2010-11 20224
2011-12 30982
2012-13 21321
2013-14 28606
2014-15 23397
2015-16 22100
2016-17 19875
2017-18 18334
2018-19 15147
2019-20 26517
2020-21 11982
2021-22 19514
2022-23 22985
", header = TRUE, stringsAsFactors = FALSE)
catch$year <- as.integer(substr(catch$source_period, 1L, 4L))
if (nrow(catch) != 52L || catch$catch_t[catch$source_period == "2022-23"] != 22985L ||
    catch$catch_t[catch$source_period == "1971"] != 7260L) {
  stop("Expected all 52 Table 2 SBW 6I catch periods.", call. = FALSE)
}

acoustic <- read.table(text = "
year immature_biomass immature_cv mature_biomass mature_cv
1993 35208 0.25 16060 0.24
1994 5523 0.38 72168 0.34
1995 15507 0.29 53608 0.30
1998 6759 0.20 91639 0.14
2000 1864 0.24 71749 0.17
2002 247 0.76 66034 0.68
2004 5617 0.16 42236 0.35
2006 3423 0.24 43843 0.32
2009 24479 0.26 99521 0.27
2011 14454 0.17 53299 0.22
2013 8004 0.55 65801 0.25
2016 4456 0.19 97117 0.16
2019 4060 0.18 91145 0.27
2022 5356 0.22 91968 0.20
", header = TRUE)
if (nrow(acoustic) != 14L || !identical(acoustic$year,
    c(1993L, 1994L, 1995L, 1998L, 2000L, 2002L, 2004L, 2006L,
      2009L, 2011L, 2013L, 2016L, 2019L, 2022L))) {
  stop("Expected the 14 acoustic-survey years in Table 3.", call. = FALSE)
}

stock_header <- names(read.csv("database/stocks.csv", nrows = 0L,
  stringsAsFactors = FALSE, check.names = FALSE))
assessment_header <- names(read.csv("database/assessments.csv", nrows = 0L,
  stringsAsFactors = FALSE, check.names = FALSE))
assumption_header <- names(read.csv("database/assumptions.csv", nrows = 0L,
  stringsAsFactors = FALSE, check.names = FALSE))
input_header <- names(read.csv("database/inputs.csv", nrows = 0L,
  stringsAsFactors = FALSE, check.names = FALSE))
output_header <- names(read.csv("database/outputs.csv", nrows = 0L,
  stringsAsFactors = FALSE, check.names = FALSE))

make_record <- function(header, n) {
  out <- as.data.frame(matrix("", nrow = n, ncol = length(header)),
    stringsAsFactors = FALSE)
  names(out) <- header
  out
}
make_inputs <- function(data, measure, basis, unit, source_reference) {
  out <- make_record(input_header, nrow(data))
  for (name in intersect(names(data), names(out))) {
    value <- as.character(data[[name]])
    value[is.na(value)] <- ""
    out[[name]] <- value
  }
  out$assessment_id <- assessment_id
  out$type <- data$type
  out$measure <- measure
  out$basis <- basis
  out$unit <- unit
  out$source_type <- "official_table"
  out$source_reference <- source_reference
  out
}
make_assumption <- function(component, setting, value, source_reference, notes = "") {
  out <- make_record(assumption_header, 1L)
  out$assessment_id <- assessment_id
  out$component <- component
  out$setting <- setting
  out$value <- value
  out$source_reference <- source_reference
  out$notes <- notes
  out
}

catch_data <- data.frame(
  type = "catch",
  measure = "total_biomass",
  fleet = "Commercial fishery",
  region = "Campbell Island Rise",
  year = catch$year,
  year_basis = "model_year",
  value = catch$catch_t,
  observation_id = paste0("FAR-2024-37-Table2-", catch$source_period),
  transformation = paste(
    "Year is the first four-digit year of the source fishing-period label;",
    "the full label is retained in observation_id and notes. The catch value",
    "is copied unchanged from the assessment table."
  ),
  notes = paste0("Estimated catch for source fishing period ", catch$source_period,
    "; no landings/discards split is reported.",
    ifelse(catch$year <= 1977L,
      " The source estimate applies a 0.70 Campbell Island stock share to total catch.", "")),
  stringsAsFactors = FALSE
)
catch_inputs <- make_inputs(catch_data, "total_biomass", "biomass", "tonnes",
  "FAR 2024/37, Table 2, p. 5.")

index_data <- do.call(rbind, lapply(c("immature", "mature"), function(category) {
  data.frame(
    type = "index",
    survey = paste("R.V. Tangaroa wide-area acoustic", category, "biomass"),
    region = "Campbell Island Rise",
    year = acoustic$year,
    year_basis = "calendar_year",
    value = acoustic[[paste(category, "biomass", sep = "_")]],
    notes = paste(
      "Source acoustic biomass category:", category,
      "fish; aggregate biomass index, not an age-specific abundance series.",
      "The assessment treated it as relative mid-season biomass. Exact fractional-year timing is not reported."
    ),
    stringsAsFactors = FALSE
  )
}))
index_inputs <- make_inputs(index_data, "total_biomass", "biomass", "tonnes",
  "FAR 2024/37, Table 3, p. 6.")

cv_data <- do.call(rbind, lapply(c("immature", "mature"), function(category) {
  data.frame(
    type = "index",
    survey = paste("R.V. Tangaroa wide-area acoustic", category, "biomass"),
    region = "Campbell Island Rise",
    year = acoustic$year,
    year_basis = "calendar_year",
    value = acoustic[[paste(category, "cv", sep = "_")]],
    notes = paste(
      "Source sampling CV for the corresponding", category,
      "biomass index. The assessment added separate estimated process error;",
      "that adjustment is not folded into this source CV."
    ),
    stringsAsFactors = FALSE
  )
}))
cv_inputs <- make_inputs(cv_data, "biomass_index_cv", "relative_scale", "ratio",
  "FAR 2024/37, Table 3, p. 6.")
new_inputs <- rbind(catch_inputs, index_inputs, cv_inputs)
if (nrow(new_inputs) != 108L || nrow(catch_inputs) != 52L ||
    nrow(index_inputs) != 28L || nrow(cv_inputs) != 28L) {
  stop("Unexpected SBW 6I input row counts.", call. = FALSE)
}

stock_row <- make_record(stock_header, 1L)
stock_row[1L, ] <- list(
  stock_id, "", "Fisheries New Zealand", "SBW 6I", "Micromesistius australis",
  "Southern blue whiting", "Campbell Island Rise", "New Zealand sub-Antarctic",
  "Southwest Pacific",
  paste("SBW 6I is the Campbell Island Rise stock, assessed separately from",
    "SBW 6A, SBW 6B, SBW 6R and SBW 1.")
)
assessment_row <- make_record(assessment_header, 1L)
assessment_row[1L, ] <- list(
  assessment_id, stock_id, "2024", "2022", "2022", "full_assessment",
  "Casal2", "Casal2 version not reported", "TRUE", "TRUE", "",
  "https://fs.fish.govt.nz/Doc/25762/FAR-2024-37-Southern-blue-whiting-stock-assessment-Campbell-Island-Rise-to-2022-23.pdf.ashx",
  "https://fs.fish.govt.nz/Doc/26114/southern-blue-whiting-sbw-fisheries-assessment-plenary-may-2025-volume-3.pdf.ashx",
  "https://fs.fish.govt.nz/Doc/25586/FAR-2023-63-Southern-Blue-Whiting-Fisheries-Characterisation-Up-To-2022-4422.pdf.ashx",
  "", "", "partial", "partial", "partial",
  paste("FAR 2024/37 documents the latest detailed full assessment located for",
    "the current SBW 6I unit, using data through the 2022-23 fishing year.",
    "The 2025 Plenary lists the 2024 assessment as most recent and 2026 as next.",
    "Later catch-age reports are not substituted into this run. Numerical",
    "commercial composition vectors, complete annual biology, and annual",
    "age-specific population outputs remain unavailable in the reviewed sources.")
)

assumptions <- list(
  make_assumption("model", "assessment_model",
    "Two-sex, single-stock, single-area Bayesian statistical catch-at-age model implemented in Casal2",
    "FAR 2024/37, Section 2.1, p. 3.", "Exact Casal2 version is not reported."),
  make_assumption("model", "model_partitions",
    "Two sexes and immature/mature partitions; ages 2-15 with age-15 plus group",
    "FAR 2024/37, Section 2.1, p. 3."),
  make_assumption("model", "model_years",
    "1960-2022; projections 2023-2028",
    "FAR 2024/37, Section 2.1, p. 3."),
  make_assumption("population", "initial_age_distribution",
    "Equilibrium age distribution in 1960 for the Base run",
    "FAR 2024/37, Table 6, p. 9."),
  make_assumption("recruitment", "year_class_strength_years",
    "Year-class strengths estimated for 1960-2021; mean constrained to one",
    "FAR 2024/37, Table 6, p. 9 and Section 2.3, p. 7."),
  make_assumption("recruitment", "year_class_strength_prior",
    "Lognormal; mean 1.0, CV 1.3",
    "FAR 2024/37, Table 4, p. 7."),
  make_assumption("recruitment", "stock_recruitment_relationship",
    "Beverton-Holt; steepness 0.9",
    "FAR 2024/37, Section 2.1, p. 3."),
  make_assumption("recruitment", "male_fraction_at_recruitment",
    "0.5 at age two",
    "FAR 2024/37, Section 2.1, p. 3."),
  make_assumption("mortality", "natural_mortality",
    "0.20 per year, fixed in the Base run",
    "FAR 2024/37, Table 6, p. 9.",
    "M=0.15, M=0.25 and estimated M are sensitivity runs, not Base-run settings."),
  make_assumption("timing", "annual_model_time_steps",
    "November-August: 90% of M; September-October: remaining 10% of M, age advancement, recruitment and fishing mortality",
    "FAR 2024/37, Table 1, p. 3."),
  make_assumption("growth", "length_at_age",
    "Empirical sex-specific length-at-age matrix; no von Bertalanffy curve",
    "FAR 2024/37, Section 2.1, p. 4.",
    "The full annual matrix is not tabulated in the reviewed public sources."),
  make_assumption("weight", "length_weight_relationship",
    "Male weight=0.00515*length^3.092; female weight=0.00407*length^3.152; length in cm, weight in kg",
    "FAR 2024/37, Section 2.1, p. 4."),
  make_assumption("maturity", "maturation_ogive",
    "Sex-specific logistic maturation with parameters A50 and Ato95",
    "FAR 2024/37, Section 2.1, p. 3.",
    "Numerical age-specific maturity values for the Base run are not tabulated."),
  make_assumption("fishery", "mature_fish_selectivity",
    "Mature fish on the spawning ground are assumed equally selected; Umax=0.99",
    "FAR 2024/37, Section 2.1, p. 3."),
  make_assumption("index", "acoustic_index_observations",
    "Immature and mature acoustic biomass indices are treated as relative mid-season biomass; juvenile index excluded",
    "FAR 2024/37, Section 2.2, pp. 5-6."),
  make_assumption("index", "acoustic_index_likelihood",
    "Lognormal; source sampling CV combined with separately estimated process error",
    "FAR 2024/37, Section 2.2, p. 6 and Section 2.3, p. 8."),
  make_assumption("index", "mature_acoustic_q_prior",
    "Lognormal mean 0.54, CV 0.44",
    "FAR 2024/37, Table 4, p. 7 and Table 5, p. 8."),
  make_assumption("index", "immature_acoustic_q_prior",
    "Uniform bounds 0.01-1.5",
    "FAR 2024/37, Table 4, p. 7."),
  make_assumption("composition", "commercial_age_composition_likelihood",
    "Sex-specific proportions-at-age, ages 1-15+, multinomial likelihood",
    "FAR 2024/37, Section 2.2, p. 6.",
    "Sampling CVs are estimated by bootstrap; effective sample size includes estimated process error using Francis method TA1.8."),
  make_assumption("timing", "acoustic_survey_time",
    "Relative mid-season biomass after half the seasonal catch is removed; exact fractional-year timing not reported",
    "FAR 2024/37, Section 2.2, p. 6."),
  make_assumption("catch", "early_catch_apportionment",
    "1971-1977 Campbell Island catch estimates use a 0.70 stock share",
    "FAR 2024/37, Section 2.2, p. 4 and Table 2, p. 5.")
)
new_assumptions <- do.call(rbind, assumptions)

output_rows <- list()
add_output <- function(type, measure, value, unit, source_reference,
  lwr = "", upr = "", year = "", survey = "", scenario = "Base_MCMC", notes = "") {
  out <- make_record(output_header, 1L)
  out$assessment_id <- assessment_id
  out$type <- type
  out$measure <- measure
  out$value <- as.character(value)
  out$lwr <- as.character(lwr)
  out$upr <- as.character(upr)
  out$unit <- unit
  out$year <- as.character(year)
  out$survey <- survey
  out$scenario <- scenario
  out$source_type <- "official_table"
  out$source_reference <- source_reference
  out$notes <- notes
  output_rows[[length(output_rows) + 1L]] <<- out
}
add_output("biomass", "unfished_spawning_biomass", 308, "thousand tonnes",
  "FAR 2024/37, Table 8, p. 13.", scenario = "Base_MPD",
  notes = "MPD estimate of B0; no interval reported in Table 8.")
add_output("biomass", "SSB_ratio_to_B0", 63, "percent of B0",
  "FAR 2024/37, Table 8, p. 13.", year = 2022, scenario = "Base_MPD",
  notes = "MPD estimate of 2022 spawning biomass as a percentage of B0; value kept on the source percent scale.")
add_output("biomass", "unfished_spawning_biomass", 323, "thousand tonnes",
  "FAR 2024/37, Table 9, p. 17.", 292, 369,
  notes = "MCMC median of B0 and reported 95% credible interval.")
add_output("biomass", "SSB_ratio_to_B0", 63, "percent of B0",
  "FAR 2024/37, Table 9, p. 17.", 47, 82, year = 2022,
  notes = "MCMC median 2022 spawning biomass as a percentage of B0 and reported 95% credible interval; value kept on the source percent scale.")
add_output("catchability", "q", 0.23, "ratio",
  "FAR 2024/37, Table 10, p. 17.", 0.20, 0.28,
  survey = "R.V. Tangaroa wide-area acoustic immature biomass",
  notes = "Base-run MCMC median and 95% credible interval.")
add_output("catchability", "q", 0.41, "ratio",
  "FAR 2024/37, Table 10, p. 17.", 0.33, 0.49,
  survey = "R.V. Tangaroa wide-area acoustic mature biomass",
  notes = "Base-run MCMC median and 95% credible interval.")
new_outputs <- do.call(rbind, output_rows)
if (nrow(new_outputs) != 6L || nrow(new_assumptions) != 21L) {
  stop("Unexpected SBW 6I output or assumption row counts.", call. = FALSE)
}

read_assessment_ids <- function(path) {
  header <- names(read.csv(path, nrows = 0L, stringsAsFactors = FALSE,
    check.names = FALSE))
  classes <- rep("NULL", length(header))
  names(classes) <- header
  classes[["assessment_id"]] <- "character"
  read.csv(path, colClasses = classes, stringsAsFactors = FALSE,
    na.strings = c("", "NA"), check.names = FALSE)$assessment_id
}
stocks <- read.csv("database/stocks.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
assessments <- read.csv("database/assessments.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
if (stock_id %in% stocks$stock_id || assessment_id %in% assessments$assessment_id) {
  stop("The SBW 6I canonical record already exists; inspect before reimporting.", call. = FALSE)
}
for (table in c("assumptions", "inputs", "outputs")) {
  path <- file.path("database", paste0(table, ".csv"))
  if (assessment_id %in% read_assessment_ids(path)) {
    stop(assessment_id, " already appears in ", path, ".", call. = FALSE)
  }
}

candidates <- read.csv("discovery/candidates.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
candidate_index <- which(candidates$candidate_id == candidate_id)
if (length(candidate_index) != 1L ||
    !candidates$import_status[candidate_index] %in% "not_started" ||
    !candidates$eligibility[candidate_index] %in% "unresolved") {
  stop("Expected one unresolved, not-started SBW 6I candidate before importing.", call. = FALSE)
}

records <- list(
  stocks = stock_row,
  assessments = assessment_row,
  assumptions = new_assumptions,
  inputs = new_inputs,
  outputs = new_outputs
)
for (table in names(records)) {
  path <- file.path("database", paste0(table, ".csv"))
  header <- names(read.csv(path, nrows = 0L, stringsAsFactors = FALSE,
    check.names = FALSE))
  if (!identical(names(records[[table]]), header)) {
    stop("Column mismatch for ", path, ".", call. = FALSE)
  }
}

cat("SBW 6I source import prepared: 1 stock, 1 assessment, ",
  nrow(new_assumptions), " assumptions, ", nrow(new_inputs),
  " inputs, and ", nrow(new_outputs), " outputs.\n", sep = "")
cat("Inputs preserve 52 catch periods, 14 immature/mature acoustic indices and sampling CVs.\n")
cat("The import remains partial: numeric commercial age compositions, full annual biology and annual numerical population surfaces remain unavailable in the reviewed sources.\n")

if (!write_mode) {
  cat("Dry run only. Re-run with --write to append the source records.\n")
} else {
  append_rows <- function(path, rows) {
    header <- names(read.csv(path, nrows = 0L, stringsAsFactors = FALSE,
      check.names = FALSE))
    if (!identical(names(rows), header)) stop("Column mismatch for ", path, ".")
    write.table(rows, file = path, sep = ",", row.names = FALSE,
      col.names = FALSE, append = TRUE, na = "", quote = TRUE, qmethod = "double")
  }
  append_rows("database/stocks.csv", stock_row)
  append_rows("database/assessments.csv", assessment_row)
  append_rows("database/assumptions.csv", new_assumptions)
  append_rows("database/inputs.csv", new_inputs)
  append_rows("database/outputs.csv", new_outputs)

  candidates$matched_stock_id[candidate_index] <- stock_id
  candidates$match_status[candidate_index] <- "matched"
  candidates$import_status[candidate_index] <- "partial"
  candidates$decision_reason[candidate_index] <- paste(
    "The current SBW 6I unit now has a partial source import from FAR 2024/37.",
    "Numerical catch biomass, acoustic indices and sampling CVs, Base-run summary",
    "outputs, and reported model assumptions are retained. Age-composition values",
    "and complete annual biology remain unresolved, so translation eligibility stays unresolved."
  )
  candidates$notes[candidate_index] <- paste(
    "See source_reviews/mpi_sbw_sbw6i_2024.md. The catch table's source period",
    "labels are retained in observation_id; later catch-age reports are not mixed",
    "into the 2022-23 assessment."
  )
  source("scripts/database/candidate_register_io.R")
  replace_candidate_register_row("discovery/candidates.csv", candidate_index,
    candidates[candidate_index, , drop = FALSE], candidate_id)
}
