root <- "."
assessment_id <- "nafo_cod_3m_2026"
stock_id <- "nafo_cod_3m"
cache_dir <- file.path(root, "source_cache", "nafo_cod_3m_2026")
report_path <- file.path(cache_dir, "nafo_scr26_023_cod3m_2026.pdf")

if (!requireNamespace("pdftools", quietly = TRUE)) {
  stop("Install pdftools to extract the cached official assessment tables.", call. = FALSE)
}
if (!file.exists(report_path)) {
  stop("Download the assessment PDF listed in provenance/nafo_cod_3m_2026/manifest.csv.", call. = FALSE)
}

pages <- pdftools::pdf_data(report_path)
clean_page <- function(page) as.data.frame(pages[[page]], stringsAsFactors = FALSE)

year_row <- function(page, year) {
  x <- clean_page(page)
  found <- which(x$text == as.character(year))
  if (!length(found)) stop("Could not find year ", year, " on report page ", page, call. = FALSE)
  selected <- found[which.min(x$x[found])]
  x[x$y == x$y[selected], , drop = FALSE]
}

numeric_cells <- function(row, year = NULL) {
  valid <- grepl("^[0-9]+(\\.[0-9]+)?$", row$text)
  if (!is.null(year)) valid <- valid & row$text != as.character(year)
  row <- row[valid, , drop = FALSE]
  row[order(row$x), , drop = FALSE]
}

year_values <- function(page, year, expected, allow_empty = FALSE) {
  cells <- numeric_cells(year_row(page, year), year)
  values <- suppressWarnings(as.numeric(cells$text))
  if (!length(values) && allow_empty) return(rep(NA_real_, expected))
  if (length(values) != expected) {
    stop("Expected ", expected, " values for ", year, " on page ", page,
      "; found ", length(values), call. = FALSE)
  }
  values
}

input_rows <- list()
output_rows <- list()

add_input <- function(type, measure, basis, value, unit, year = NA_integer_,
  age = NA_real_, fleet = "", survey = "", region = "", season = "",
  source_reference, transformation = "", notes = "") {
  has_year <- !is.na(year)
  input_rows[[length(input_rows) + 1L]] <<- data.frame(
    assessment_id = assessment_id,
    type = type,
    measure = measure,
    basis = basis,
    fleet = fleet,
    survey = survey,
    sex = "",
    region = region,
    season = season,
    year = if (has_year) as.integer(year) else NA_integer_,
    year_basis = if (has_year) "calendar_year" else "",
    age = age,
    value = value,
    unit = unit,
    sampling_time = NA_real_,
    source_type = "official_table",
    source_reference = source_reference,
    transformation = transformation,
    notes = notes,
    observation_id = NA_character_,
    length_bin = NA_character_,
    length_bin_lower = NA_real_,
    length_bin_upper = NA_real_,
    sample_size = NA_real_,
    age_error = NA_character_,
    partition = NA_character_,
    stringsAsFactors = FALSE
  )
}

add_output <- function(type, measure, value, unit, year = NA_integer_,
  age = NA_real_, age_group = "", se = NA_real_, lwr = NA_real_,
  upr = NA_real_, source_reference, notes = "") {
  output_rows[[length(output_rows) + 1L]] <<- data.frame(
    assessment_id = assessment_id,
    type = type,
    measure = measure,
    fleet = "",
    survey = "",
    sex = "",
    region = "",
    season = "",
    year = if (!is.na(year)) as.integer(year) else NA_integer_,
    age = age,
    age_group = age_group,
    value = value,
    se = se,
    lwr = lwr,
    upr = upr,
    unit = unit,
    source_type = "official_table",
    source_reference = source_reference,
    notes = notes,
    stringsAsFactors = FALSE
  )
}

years <- 1988:2025
catch_age_years <- c(1988:2001, 2006:2025)
commercial <- "Commercial catch"
eu_survey <- "EU Flemish Cap bottom-trawl survey"
division <- "NAFO Division 3M"

# Catch, catch-at-age, and catch weight (SCR 26/023, Tables 1A–3).
for (year in years) {
  catch_row <- numeric_cells(year_row(11, year), year)
  if (!length(catch_row)) stop("Missing total catch for ", year, call. = FALSE)
  add_input(
    type = "catch", measure = "total_biomass", basis = "biomass",
    year = year, value = as.numeric(catch_row$text[[1]]), unit = "tonnes",
    fleet = commercial, region = division,
    source_reference = "NAFO SCR 2026/023, Table 1A, p. 11",
    notes = "Uses the first Table 1A column, Estimated total catch (STACFIS estimate), rather than the separately reported nominal total."
  )

  catch_weight <- year_values(14, year, 8L)
  for (age in 1:8) {
    add_input(
      type = "catch_weight", measure = "catch_weight_at_age", basis = "kg_per_fish",
      year = year, age = age, value = catch_weight[[age]], unit = "kg/fish",
      fleet = commercial, region = division,
      source_reference = "NAFO SCR 2026/023, Table 3, p. 14",
      notes = "Age 8 denotes the 8+ group. The 2025 values use the EU survey length-weight relationship, as stated in the report."
    )
  }
}

for (year in catch_age_years) {
  page <- if (year <= 1995) 12L else 13L
  values <- year_values(page, year, 8L)
  values[[1]] <- 0
  zero_ages <- which(values[2:8] == 0) + 1L
  if (length(zero_ages)) values[zero_ages] <- NA_real_
  for (age in 1:8) {
    add_input(
      type = "catch", measure = "numbers_at_age", basis = "numbers",
      year = year, age = age, value = values[[age]], unit = "thousand fish",
      fleet = commercial, region = division,
      source_reference = paste0("NAFO SCR 2026/023, Table 2, pp. 12–13"),
      transformation = if (age == 1) {
        "Set age-1 catch-at-age to zero, as specified for the fitted assessment."
      } else {
        "Published zero values at ages 2+ are represented as missing because the assessment treats them as NA."
      },
      notes = "Age 8 denotes the 8+ group. No catch-at-age observations are reported for 2002–2005."
    )
  }
}

# Survey age indices: preserve the source ages and the model's 1–8+ grouping.
survey_page <- clean_page(15)
age_header <- survey_page[survey_page$y == 95 & survey_page$text %in% as.character(1:19), , drop = FALSE]
age_header <- age_header[match(as.character(1:19), age_header$text), , drop = FALSE]
if (nrow(age_header) != 19L || anyNA(age_header$text)) {
  stop("Could not identify the 1–19 survey age columns on page 15.", call. = FALSE)
}
header <- survey_page[survey_page$y == 95 & survey_page$text %in% c("Total", "Abundance", "Biomass"), , drop = FALSE]
abundance_header <- header[header$text == "Abundance", , drop = FALSE]
biomass_header <- header[header$text == "Biomass", , drop = FALSE]
if (nrow(abundance_header) != 1L || nrow(biomass_header) != 1L) {
  stop("Could not identify survey total columns on page 15.", call. = FALSE)
}
survey_right_edges <- c(age_header$x + age_header$width,
  abundance_header$x[[1]] + abundance_header$width[[1]],
  biomass_header$x[[1]] + biomass_header$width[[1]])

survey_table <- matrix(NA_real_, nrow = length(years), ncol = 21L,
  dimnames = list(as.character(years), NULL))
for (i in seq_along(years)) {
  year <- years[[i]]
  cells <- numeric_cells(year_row(15, year), year)
  right_edge <- cells$x + cells$width
  survey_table[i, ] <- vapply(survey_right_edges, function(target) {
    if (!length(right_edge)) return(NA_real_)
    selected <- which.min(abs(right_edge - target))
    if (abs(right_edge[[selected]] - target) > 4) return(NA_real_)
    as.numeric(cells$text[[selected]])
  }, numeric(1))
}

for (i in seq_along(years)) {
  year <- years[[i]]
  raw_values <- survey_table[i, 1:19]
  grouped_values <- c(raw_values[1:7],
    if (anyNA(raw_values[8:19])) NA_real_ else sum(raw_values[8:19]))
  grouped_values[grouped_values == 0] <- NA_real_

  for (age in 1:19) {
    add_input(
      type = "index", measure = "numbers_at_age", basis = "numbers",
      year = year, age = age, value = raw_values[[age]], unit = "thousand fish",
      survey = eu_survey, region = division, season = "summer",
      source_reference = "NAFO SCR 2026/023, Table 4, p. 15",
      notes = "Published survey abundance index at source ages 1–19. Zeros are retained here as published; the assessment treats zero age indices as missing. The model uses the separate 1–8+ grouped series."
    )
  }

  for (age in 1:8) {
    add_input(
      type = "index", measure = "index_by_age_group", basis = "numbers",
      year = year, age = age, value = grouped_values[[age]], unit = "thousand fish",
      survey = eu_survey, region = division, season = "summer",
      source_reference = "NAFO SCR 2026/023, Table 4, p. 15",
      transformation = if (age == 8) {
        "Sum source ages 8–19 to the model's 8+ group; retain NA when a source age is blank."
      } else {
        "Map the source age to the same model age; represent zero index values as missing because the assessment treats them as NA."
      },
      notes = "The model uses ages 1–8+. Age 8 denotes the 8+ group. Sampling time is represented by the July interval in Annex I, not a single scalar."
    )
  }
}

# Stock weights, maturity ogives, and the reported a50 summary (Tables 5–6).
for (year in years) {
  weights <- year_values(16, year, 8L)
  maturity <- year_values(17, year, 9L)
  for (age in 1:8) {
    add_input(
      type = "weight", measure = "weight_at_age", basis = "kg_per_fish",
      year = year, age = age, value = weights[[age]], unit = "kg/fish",
      region = division,
      source_reference = "NAFO SCR 2026/023, Table 5, p. 16",
      notes = "Age 8 denotes the 8+ group; weight-at-age in the stock."
    )
    add_input(
      type = "maturity", measure = "maturity_at_age", basis = "proportion",
      year = year, age = age, value = maturity[[age]], unit = "proportion",
      region = division,
      source_reference = "NAFO SCR 2026/023, Table 6, p. 17",
      notes = "Age 8 denotes the 8+ group. The ogives are medians from annual logistic regressions where available; the report documents carried-forward and mixed-year ogives."
    )
  }
  add_output(
    type = "biology", measure = "age_at_maturity_50_percent",
    year = year, value = maturity[[9]], unit = "years",
    source_reference = "NAFO SCR 2026/023, Table 6, p. 17",
    notes = "Reported median a50. Figure 9B shows uncertainty graphically, but numeric limits are not tabulated."
  )
}

# Natural mortality prior medians and posterior medians (Table 10).
m_page <- clean_page(21)
named_numeric_row <- function(label) {
  matches <- which(m_page$text == label)
  if (!length(matches)) stop("Could not find Table 10 row: ", label, call. = FALSE)
  selected <- matches[which.max(m_page$y[matches])]
  row <- m_page[m_page$y == m_page$y[[selected]], , drop = FALSE]
  values <- suppressWarnings(as.numeric(numeric_cells(row)$text))
  if (length(values) != 8L) stop("Expected 8 mortality values in row ", label, call. = FALSE)
  values
}
m_prior <- named_numeric_row("Prior")
m_posterior <- named_numeric_row("Posterior")
for (age in 1:8) {
  add_input(
    type = "M", measure = "natural_mortality_at_age", basis = "per_year",
    age = age, value = m_prior[[age]], unit = "year^-1",
    source_reference = "NAFO SCR 2026/023, Table 10, p. 21",
    notes = "Age-specific lognormal prior median; M is estimated by age and constant across years. Age 8 denotes the 8+ group."
  )
  add_output(
    type = "mortality", measure = "natural_mortality_at_age",
    age = age, value = m_posterior[[age]], unit = "year^-1",
    source_reference = "NAFO SCR 2026/023, Table 10, p. 21",
    notes = "Posterior median. The report does not tabulate age-specific uncertainty. Age 8 denotes the 8+ group."
  )
}

# Annual population and fishing mortality summaries (Tables 7–9).
for (year in years) {
  t7 <- year_values(18, year, 12L)
  summary_specs <- list(
    c("biomass", "total_biomass", "tonnes", 1L),
    c("biomass", "SSB", "tonnes", 4L),
    c("recruitment", "recruitment", "thousand fish", 7L),
    c("mortality", "Fbar", "year^-1", 10L)
  )
  for (spec in summary_specs) {
    j <- as.integer(spec[[4]])
    add_output(
      type = spec[[1]], measure = spec[[2]], year = year,
      value = t7[[j]], unit = spec[[3]], age_group = if (spec[[2]] == "Fbar") "3-5" else "",
      lwr = t7[[j + 1L]], upr = t7[[j + 2L]],
      source_reference = "NAFO SCR 2026/023, Table 7, p. 18",
      notes = if (spec[[2]] == "recruitment") {
        "Posterior median age-1 recruitment; the table caption says tons, but the quantity equals Table 9 age-1 abundance and is in thousand fish. Bounds are the 10th and 90th posterior percentiles (central 80% interval)."
      } else if (spec[[2]] == "Fbar") {
        "Posterior median Fbar for ages 3–5. Bounds are the 10th and 90th posterior percentiles (central 80% interval), not a 95% interval."
      } else {
        "Posterior median. Bounds are the 10th and 90th posterior percentiles (central 80% interval), not a 95% interval."
      }
    )
  }

  f_at_age <- year_values(19, year, 8L)
  n_at_age <- year_values(20, year, 10L)
  for (age in 1:8) {
    add_output(
      type = "mortality", measure = "fishing_mortality_at_age",
      year = year, age = age, value = f_at_age[[age]], unit = "year^-1",
      source_reference = "NAFO SCR 2026/023, Table 8, p. 19",
      notes = "Posterior median; age 8 denotes the 8+ group. Age 1 F is fixed at zero. No age-specific interval is tabulated."
    )
    add_output(
      type = "population", measure = "numbers_at_age",
      year = year, age = age, value = n_at_age[[age]], unit = "thousand fish",
      source_reference = "NAFO SCR 2026/023, Table 9, p. 20",
      notes = "Posterior median; age 8 denotes the 8+ group. No age-specific interval is tabulated."
    )
  }
  add_output(
    type = "population", measure = "total_numbers", year = year,
    value = n_at_age[[9]], unit = "thousand fish",
    source_reference = "NAFO SCR 2026/023, Table 9, p. 20",
    notes = "Reported posterior median total across fitted ages 1–8+. No interval is tabulated."
  )
  add_output(
    type = "population", measure = "mature_numbers", year = year,
    value = n_at_age[[10]], unit = "thousand fish",
    source_reference = "NAFO SCR 2026/023, Table 9, p. 20",
    notes = "Reported posterior median number of mature fish. No interval is tabulated."
  )
}

inputs_new <- do.call(rbind, input_rows)
outputs_new <- do.call(rbind, output_rows)

input_value <- function(type, measure, year = NA_integer_, age = NA_real_) {
  selected <- inputs_new$type == type & inputs_new$measure == measure
  if (!is.na(year)) selected <- selected & inputs_new$year == year
  if (!is.na(age)) selected <- selected & inputs_new$age == age
  values <- inputs_new$value[selected]
  if (length(values) != 1L) stop("Expected one extracted input: ", measure, call. = FALSE)
  as.numeric(values[[1]])
}
output_value <- function(type, measure, year = NA_integer_, age = NA_real_) {
  selected <- outputs_new$type == type & outputs_new$measure == measure
  if (!is.na(year)) selected <- selected & outputs_new$year == year
  if (!is.na(age)) selected <- selected & outputs_new$age == age
  values <- outputs_new$value[selected]
  if (length(values) != 1L) stop("Expected one extracted output: ", measure, call. = FALSE)
  as.numeric(values[[1]])
}
stopifnot(
  input_value("catch", "total_biomass", 1988L) == 28899,
  input_value("catch", "total_biomass", 2025L) == 12485,
  input_value("catch", "numbers_at_age", 1988L, 2) == 3500,
  input_value("catch", "numbers_at_age", 2025L, 8) == 864,
  !any(inputs_new$type == "catch" & inputs_new$measure == "numbers_at_age" &
    inputs_new$year %in% 2002:2005),
  input_value("index", "numbers_at_age", 2025L, 1) == 1786,
  input_value("index", "index_by_age_group", 2025L, 8) == 1965,
  is.na(input_value("index", "index_by_age_group", 2005L, 7)),
  is.na(input_value("index", "index_by_age_group", 2018L, 8)),
  input_value("M", "natural_mortality_at_age", age = 1) == 1.26,
  output_value("biomass", "total_biomass", 2025L) == 70872,
  output_value("biomass", "SSB", 2025L) == 39216,
  output_value("recruitment", "recruitment", 2025L) == 31134,
  output_value("mortality", "Fbar", 2025L) == 0.115,
  output_value("population", "total_numbers", 2025L) == 82174,
  output_value("mortality", "fishing_mortality_at_age", 2025L, 8) == 0.331,
  output_value("population", "mature_numbers", 2025L) == 18618,
  output_value("mortality", "natural_mortality_at_age", age = 8) == 0.34,
  output_value("biology", "age_at_maturity_50_percent", 2025L) == 4.96
)

assumptions_new <- data.frame(
  assessment_id = assessment_id,
  component = c(
    "population", "population", "population", "recruitment", "abundance",
    "fishing_mortality", "fishing_mortality", "fishing_mortality",
    "fishing_mortality", "fishing_mortality", "catch", "catch", "index",
    "index", "index", "catch", "index", "biology", "mortality",
    "mortality", "mortality", "mortality"
  ),
  fleet = "", survey = "", sex = "", region = "", season = "",
  setting = c(
    "model_structure", "modeled_years", "modeled_ages", "recruitment_prior_median",
    "first_year_abundance_prior", "F_definition", "F_year_effect",
    "F_year_effect_prior", "selectivity_process", "selectivity_constraints",
    "total_catch_cv", "catch_at_age_cv", "survey_index_cv",
    "survey_timing_alpha", "survey_timing_beta", "age_1_catch_and_F",
    "zero_index_handling", "maturity_data_handling", "M_structure",
    "M_prior_medians", "M_prior_cv", "q_age_groups_and_age_1_effect"
  ),
  value = c(
    "Bayesian sequential catch-at-age model; cohorts are projected forward; model fitted in JAGS called from R via rjags.",
    "1988-2025", "Ages 1-8+", "medrec = 45,000 thousand fish; cvrec = 10.",
    "First-year abundance N[1,a], ages 2-8+, has a lognormal prior with median profile medF[a] = c(0.0001, 0.1, 0.5, 0.7, 0.7, 0.7, 0.7, 0.7) and cvyear1 = 10, as written in Annex I.",
    "F[y,a] = f[y] * rC[y,a].", "log(f) follows an AR(1) process across years.",
    "rhof has Uniform(0,1) prior; medf = 0.2; cvf = 4.",
    "For each age except the reference and plus group, log(rC) follows an age-specific random walk over years.",
    "Age 1 rC is fixed at zero; age 5 is the reference with rC = 1; age 8+ rC equals age 7. Initial medrC for ages 2-8 is c(0.001, 0.3, 0.6, 0.9, 1, 1, 1); cvrC = 4; cvrCcond = 0.2.",
    "cvCW = 0.077; the report states a 95% probability of no more than 15% deviation.",
    "Catch numbers-at-age observation CV is 0.2 on the original scale.",
    "Survey abundance-at-age observation CV is 0.3 on the original scale.",
    "alpha.EU = 0.50; the model timing interval begins at 0.50.",
    "beta.EU = 0.58; alpha/beta correspond to the survey timing in July. No single annual sampling_time is assigned.",
    "Catch-at-age 1 is set to zero in every modeled year and F at age 1 is fixed at zero.",
    "Zero survey indices and zero catch-at-age values for ages 2+ are treated as missing values.",
    "Maturity ogives from 1990-1998, 2001-2006 and 2008-2022; 1988-1989 use 1990; 1999-2000 mix 1998/2001; 1991 mixes 1990/1992; 2007 mixes 2006/2008; 2023-2025 use the 2020-2022 mean.",
    "M is age-dependent and constant across years; it is estimated with an age-specific lognormal prior.",
    "Table 10 prior medians by age are stored in inputs.csv; ages 1-8+.",
    "cvM = 0.15.",
    "Survey q is estimated by age groups 1, 2, 3, and 4+; age-1 q is stock-size dependent. medlogphi = 0, taulogphi = 1/5, medgama = 1, and taugama = 1/0.25."
  ),
  source_reference = c(
    rep("NAFO SCR 2026/023, pp. 5-6 and Annex I, pp. 54-55", 10),
    "NAFO SCR 2026/023, Annex I, p. 55",
    "NAFO SCR 2026/023, p. 6 and Annex I, p. 55",
    "NAFO SCR 2026/023, p. 6 and Annex I, p. 55",
    "NAFO SCR 2026/023, p. 6 and Annex I, p. 55",
    "NAFO SCR 2026/023, Annex I, p. 55",
    "NAFO SCR 2026/023, Annex I, p. 55",
    "NAFO SCR 2026/023, pp. 5-6",
    "NAFO SCR 2026/023, pp. 5-6 and Annex I, p. 55",
    "NAFO SCR 2026/023, p. 6 and Annex I, p. 55",
    "NAFO SCR 2026/023, pp. 6 and 21",
    "NAFO SCR 2026/023, p. 6 and Annex I, p. 55",
    "NAFO SCR 2026/023, p. 22 and Annex I, p. 55"
  ),
  notes = c(
    rep("", 10),
    "CV is reported for the total-catch observation model.",
    "CV is reported on catch numbers-at-age in original scale, not log scale.",
    "CV is reported on the age-specific survey abundance index in original scale, not log scale.",
    "The source gives an interval used by the model; leave input sampling_time blank rather than replace it with a midpoint.",
    "The 2025 Flemish Cap survey occurred 8 July to 4 August; this does not establish one annual fraction for all years.",
    "Table 2 reports small nonzero age-1 values, but the assessment specifies setting the model input to zero.",
    "The source table retains published zeros separately from the model-effective grouped input rows.",
    "The source documents carry-forward and mixture rules for missing survey maturity years.",
    "The prior median values are source inputs, not fixed mortality estimates.",
    "Posterior medians are recorded separately in outputs.csv.",
    "Table 10 provides age-specific prior medians; the prior CV is recorded here.",
    "Model-grouped survey indices are recorded in inputs.csv."
  ),
  stringsAsFactors = FALSE
)

stock_new <- data.frame(
  stock_id = stock_id,
  charbonneau_id = "",
  authority = "NAFO",
  authority_stock_id = "cod.3M",
  scientific_name = "Gadus morhua",
  common_name = "Cod in Division 3M",
  area = "NAFO Division 3M (Flemish Cap)",
  region = "Flemish Cap",
  ocean = "Northwest Atlantic",
  notes = "Distinct NAFO assessment unit for Atlantic cod in Division 3M; no existing canonical stock record was found.",
  stringsAsFactors = FALSE
)

assessment_new <- data.frame(
  assessment_id = assessment_id,
  stock_id = stock_id,
  assessment_year = 2026L,
  terminal_year = 2025L,
  estimate_terminal_year = 2025L,
  assessment_type = "full_assessment",
  model_family = "Bayesian SCAA",
  model_version = "JAGS called from R via rjags; package/model code version not reported",
  is_current = TRUE,
  is_applied = TRUE,
  framework_year = 2018L,
  assessment_url = "https://www.nafo.int/Portals/0/PDFs/sc/2026/scr26-023.pdf",
  framework_url = "https://www.nafo.int/Portals/0/PDFs/sc/2018/scr18-030.pdf",
  data_url = "https://www.nafo.int/Portals/0/PDFs/sc/2026/scr26-003.pdf",
  model_url = "",
  repository_url = "",
  assumptions_status = "partial",
  inputs_status = "partial",
  outputs_status = "partial",
  notes = "Official 2026 production assessment used for advice for 2027; fitted years 1988-2025. Input and output tables are transcribed from SCR 26/023; 2018 survey age 15 is blank, so an exact 8+ index cannot be reconstructed. Age-specific posterior uncertainty is not numerically tabulated. No public production-run JAGS code or fitted object was located.",
  stringsAsFactors = FALSE
)

source_reviews <- file.path(root, "source_reviews")
manifest_path <- file.path(root, "provenance", "nafo_cod_3m_2026", "manifest.csv")
candidate_path <- file.path(root, "discovery", "candidates.csv")
source(file.path(root, "scripts", "database", "candidate_register_io.R"))

read_csv <- function(path) read.csv(path, stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
append_csv <- function(x, path) write.table(x, path, sep = ",", quote = TRUE,
  row.names = FALSE, col.names = FALSE, append = TRUE, na = "",
  qmethod = "double")

stocks_path <- file.path(root, "database", "stocks.csv")
assessments_path <- file.path(root, "database", "assessments.csv")
assumptions_path <- file.path(root, "database", "assumptions.csv")
inputs_path <- file.path(root, "database", "inputs.csv")
outputs_path <- file.path(root, "database", "outputs.csv")
stocks <- read_csv(stocks_path)
assessments <- read_csv(assessments_path)
assumptions <- read_csv(assumptions_path)
candidates <- read_csv(candidate_path)

if (stock_id %in% stocks$stock_id || assessment_id %in% assessments$assessment_id) {
  stop("Stock or assessment already exists; inspect the canonical records before importing.", call. = FALSE)
}
candidate_row <- which(candidates$candidate_id == "NAFO:cod.3M")
if (length(candidate_row) != 1L || candidates$candidate_unit_id[candidate_row] != stock_id) {
  stop("Expected exactly one matching NAFO 3M cod candidate row.", call. = FALSE)
}
if (nrow(assumptions_new) != 22L || nrow(inputs_new) != 2256L || nrow(outputs_new) != 882L) {
  stop("Unexpected extraction row counts; no canonical files were changed.", call. = FALSE)
}
if (any(!is.finite(inputs_new$value) & !is.na(inputs_new$value))) {
  stop("Non-finite source inputs found.", call. = FALSE)
}
if (any(!is.finite(outputs_new$value))) stop("Non-finite source outputs found.", call. = FALSE)

if (identical(Sys.getenv("SAIO_NAFO_IMPORT_DRY_RUN"), "1")) {
  message("Dry run only: ", nrow(inputs_new), " inputs; ",
    nrow(assumptions_new), " assumptions; ", nrow(outputs_new), " outputs.")
  message("Missing grouped survey values: ", sum(is.na(inputs_new$value[
    inputs_new$measure == "index_by_age_group"])))
  quit(save = "no", status = 0L)
}

has_assessment <- function(path, id) {
  connection <- file(path, open = "r")
  on.exit(close(connection), add = TRUE)
  prefix <- paste0("\"", id, "\",\"")
  repeat {
    lines <- readLines(connection, n = 100000L, warn = FALSE)
    if (!length(lines)) return(FALSE)
    if (any(startsWith(lines, prefix))) return(TRUE)
  }
}
if (has_assessment(inputs_path, assessment_id) || has_assessment(outputs_path, assessment_id)) {
  stop("Assessment rows already exist in inputs.csv or outputs.csv; inspect before importing.", call. = FALSE)
}

append_csv(stock_new, stocks_path)
append_csv(assessment_new, assessments_path)
append_csv(assumptions_new, assumptions_path)
append_csv(inputs_new, inputs_path)
append_csv(outputs_new, outputs_path)

candidates$matched_stock_id[candidate_row] <- stock_id
candidates$match_status[candidate_row] <- "matched"
candidates$import_status[candidate_row] <- "partial"
replace_candidate_register_row(candidate_path, candidate_row,
  candidates[candidate_row, , drop = FALSE], "NAFO:cod.3M")

message("Imported ", assessment_id, ": ", nrow(inputs_new), " inputs, ",
  nrow(assumptions_new), " assumptions, and ", nrow(outputs_new), " outputs.")
