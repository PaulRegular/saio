source("scripts/database/pacific_tables.R")
source("scripts/database/atka_report_matrices.R")
id <- "afsc_atka_mackerel_bsai_2024"
report <- "https://files.npfmc.org/SAFE/2024/BSAIatka.pdf"
cache <- "source_cache/afsc_atka_mackerel_bsai"
pages <- pdftools::pdf_text(file.path(cache, "assessment_2024.pdf"))
table_rows <- function(page, columns, first = 1977, last = 2024) {
  lines <- trimws(strsplit(pages[page], "\n")[[1]])
  lines <- lines[grepl("^[12][0-9]{3}[ab]? ", lines)]
  cells <- strsplit(gsub(",", "", lines), "[[:space:]]+")
  cells <- lapply(cells, function(v) {
    v <- gsub("[ab%]$", "", v)
    v <- v[grepl("^[0-9.]+$|^-$", v)]
    stopifnot(length(v) <= columns)
    length(v) <- columns
    suppressWarnings(as.numeric(v))
  })
  z <- as.data.frame(t(vapply(cells, identity, numeric(columns))))
  z[z[[1]] >= first & z[[1]] <= last, ]
}
as_age_matrix <- function(z, ages) {
  m <- as.matrix(z[-1])
  dimnames(m) <- list(z[[1]], ages)
  m
}
survey_n <- table_rows(49, 13, 1991, 2022)
sample_counts <- survey_n[[2]]
survey_n <- as_age_matrix(survey_n[-2], 1:11)
survey_weights <- as_age_matrix(table_rows(50, 12, 1991), 1:11)
catch_weights <- as_age_matrix(table_rows(51, 12), 1:11)
catch_rows <- trimws(strsplit(pages[47], "\n")[[1]])
catch_rows <- catch_rows[grepl("^[12][0-9]{3} ", catch_rows)]
catch_n <- as_age_matrix(read.table(text = paste(catch_rows, collapse = "\n"),
                                    na.strings = "---"), 2:11)
catch_complete <- catch_n[complete.cases(catch_n), , drop = FALSE]
survey_panels <- table_rows(48, 6, 1991)
# Page 48 repeats years for biomass, CV and hauls. Read the biomass panel only.
survey_b <- survey_panels[seq_len(nrow(survey_weights)), ]
survey_cv <- survey_panels[nrow(survey_weights) + seq_len(nrow(survey_weights)), ]
biomass <- table_rows(56, 7)
recruitment <- table_rows(58, 5)
full_F <- table_rows(59, 5)
stopifnot(identical(dim(atka_N), c(48L, 11L)),
          identical(dim(atka_sel), c(48L, 11L)),
          identical(as.numeric(atka_N[, 1]), recruitment[[2]]),
          tail(biomass[[2]], 1) == 584610,
          tail(biomass[[5]], 1) == 128919,
          max(abs(rowSums(atka_sel > 1))) == 0)

input <- function(type, measure, basis, value, unit, year = NA_integer_,
                  age = NA_integer_, table, survey = "", fleet = "", ...) {
  pacific_database_row("inputs", assessment_id = id, type = type,
    measure = measure, basis = basis, value = value, unit = unit,
    year = year, age = age, sex = "combined", region = "BSAI",
    survey = survey, fleet = fleet, source_type = "official_table",
    source_reference = paste(report, table, sep = "; "),
    year_basis = ifelse(is.na(year), "", "calendar_year"), ...)
}
matrix_input <- function(m, type, measure, basis, unit, table, ...) {
  z <- pacific_matrix_long(m)
  input(type, measure, basis, z$value, unit, z$year, z$age, table = table, ...)
}
composition <- function(m, type, table, ...) {
  matrix_input(m / rowSums(m), type, "proportion_at_age", "proportion_numbers",
    "proportion", table,
    transformation = "Normalize published expanded numbers-at-age within year to recover the composition consumed by the multinomial likelihood; printed rounding retained.",
    ...)
}
inputs <- list(
  composition(catch_complete, "catch", "Table 17.8", fleet = "Combined trawl fishery",
    notes = "Recovered only for rows without missing dashes. The model fits biomass and composition separately. Age 1 is not reported. Earlier incomplete rows are not filled with zero."),
  composition(survey_n, "index", "Table 17.10", survey = "AI_bottom_trawl",
    notes = "Design-expanded numbers, not raw otolith counts. Normalized for the source composition likelihood; plus age 11."),
  input("index", "total_biomass", "biomass", survey_b[[6]], "t", survey_b[[1]],
    table = "Table 17.9, total biomass panel", survey = "AI_bottom_trawl",
    sampling_time = 6.5 / 12,
    notes = "Framework month 7.5 becomes (month-1)/12 in AMAK. One fitted combined survey, not separate subarea indices."),
  input("index", "relative_standard_error", "relative_scale", survey_cv[[6]] / 100,
    "CV", survey_cv[[1]], table = "Table 17.9, total CV panel", survey = "AI_bottom_trawl",
    notes = "Published rounded design-based CV; model uses unrounded supplied CV. Not a composition sample size or a fitted residual SD."),
  input("weight", "weight_at_age", "kg_per_fish",
    c(.058,.158,.464,.621,.729,.706,.781,.821,.877,.888,.809), "kg/fish",
    age = 1:11, table = "Table 17.11, Population WAA"),
  matrix_input(survey_weights, "weight", "weight_at_age", "kg_per_fish", "kg/fish",
    "Table 17.11, survey WAA", survey = "AI_bottom_trawl"),
  matrix_input(catch_weights, "catch_weight", "weight_at_age", "kg_per_fish", "kg/fish",
    "Table 17.12", fleet = "Combined trawl fishery"),
  input("maturity", "maturity_at_age", "proportion",
    c(.005,.037,.224,.688,.944,.992,.999,1,1,1,1), "proportion", age = 1:11,
    table = "Table 17.13 and unchanged Model 16.0b framework am2022.dat",
    notes = "Female maturity; framework retains unrounded values of the unchanged ogive. Source SSB uses female fraction 0.5 and August 1 spawning."),
  input("M", "natural_mortality_at_age", "per_year", rep(.3, 11), "per year",
    age = 1:11, table = "Natural mortality section, p.14"),
  input("biology", "composition_sample_count", "numbers", sample_counts, "fish",
    year = as.integer(rownames(survey_n)), table = "Table 17.10, n",
    survey = "AI_bottom_trawl",
    notes = "Raw otolith counts, not the supplied multinomial sample sizes. Supplied survey sizes are haul-scaled and Francis-weighted, not recovered numerically.")
)
# Keep the annual catch likelihood input, including the source terminal assumption.
catch_totals <- rbind(table_rows(38, 5), table_rows(39, 5))
catch_totals <- catch_totals[catch_totals[[1]] < 2024, ]
inputs[[length(inputs) + 1L]] <- input("catch", "total_biomass", "biomass",
  c(catch_totals[[2]], 72987), "t", c(catch_totals[[1]], 2024),
  table = "Table 17.1 and terminal-catch footnote", fleet = "Combined trawl fishery",
  notes = "2024 model assumes full-year catch equal to TAC 72,987 t; 64,439 t is only the in-year observation and is not substituted.")
inputs <- do.call(rbind, inputs)
inputs$source_type[inputs$measure == "proportion_at_age"] <- "reconstructed_source_input"

output <- function(type, measure, value, unit, year, age = NA_integer_, table, ...) {
  pacific_database_row("outputs", assessment_id = id, type = type, measure = measure,
    value = value, unit = unit, year = year, age = age, sex = "combined",
    region = "BSAI", source_type = "official_table",
    source_reference = paste(report, table, sep = "; "), ...)
}
z <- pacific_matrix_long(atka_N)
f <- pacific_matrix_long(atka_sel * full_F[[2]])
outputs <- rbind(
  output("population", "numbers_at_age", z$value, "million fish", z$year, z$age,
    table = "Table 17.16", notes = "Begin-year MLE, rounded to one million fish; age 11 is 11+. Visually transcribed embedded table."),
  output("mortality", "fishing_mortality_at_age", f$value, "per year", f$year, f$age,
    table = "Tables 17.15 and 17.20",
    source_type = "derived_source_output",
    notes = "Annual fully-selected F times normalized selectivity, both at report precision. 2024 selectivity equals 2023. No covariance or intervals reconstructed."),
  output("biomass", "total_biomass", biomass[[2]], "t", biomass[[1]],
    table = "Table 17.17", lwr = biomass[[3]], upr = biomass[[4]],
    notes = "Ages 1+ MLE biomass, approximate 95% confidence bounds."),
  output("biomass", "SSB", biomass[[5]], "t", biomass[[1]],
    table = "Table 17.17", lwr = biomass[[6]], upr = biomass[[7]],
    notes = "Female MLE spawning biomass at August 1, approximate 95% confidence bounds."),
  output("recruitment", "recruitment", recruitment[[2]], "million fish", recruitment[[1]], 1,
    table = "Table 17.19, Current estimate", se = recruitment[[3]],
    notes = "Age-1 MLE recruitment; marginal natural-scale SE, not CV. No intervals invented.")
)
assume <- function(component, setting, value, notes = "") {
  pacific_database_row("assumptions", assessment_id = id, component = component,
    setting = setting, value = value, source_reference = report, notes = notes)
}
assumptions <- do.call(rbind, list(
  assume("assessment", "official_model", "Model 16.0b; 2024 operational update; retained under 2025 rollover"),
  assume("population", "dimensions", "1977-2024; ages 1-11+; one combined-sex BSAI population"),
  assume("N", "process", "Deterministic cohort survival; initial equilibrium; female fraction 0.5"),
  assume("recruitment", "process", "Beverton-Holt, fixed steepness 0.8; estimated lognormal recruitment SD (reported 0.48)"),
  assume("F", "process", "Annual intensity and time-varying nonparametric selectivity, normalized mean 1; smoothness/dome/temporal penalties; ages 10+ share selectivity; Francis-tuned temporal variance"),
  assume("M", "process", "Fixed 0.3 at every age and year"),
  assume("q", "process", "One estimated survey scalar with prior mean 1, log variance 0.2^2; nonparametric time-invariant selectivity; mean combined q/selectivity normalized over ages 4-10"),
  assume("catch", "observation_model", "Lognormal total biomass, CV 5%; separate multinomial age compositions, haul-scaled input sample sizes 2-236, mean 100"),
  assume("index", "observation_model", "Lognormal biomass with supplied CV; separate multinomial ages, haul-scaled/Francis-weighted sample sizes 25-32; no lengths fitted"),
  assume("biology", "survey_timing", "(7.5-1)/12", "Unchanged AMAK framework; month_ind=7.5 and code ind_month_frac=(mo_ind-1)/12."),
  assume("biology", "SSB_definition", "0.5 * sum(N * population_weight * maturity * exp(-(7/12)*Z)); August 1 female biomass"),
  assume("biology", "ageing_error", "Fixed ageing-error matrix; unchanged since prior assessment"),
  assume("observation", "unrecovered_weights", "Exact 2024 supplied composition counts and unrounded index CVs unavailable in the report tables", "Raw otolith count and fitted effective N are not substituted for input likelihood weights.")
))
stock <- pacific_database_row("stocks", stock_id = "afsc_atka_mackerel_bsai",
  charbonneau_id = "AFSC_BSAI_Pleurogrammus_monopterygius", authority = "NOAA-AFSC",
  authority_stock_id = "BSAI Atka mackerel", scientific_name = "Pleurogrammus monopterygius",
  common_name = "Bering Sea/Aleutian Islands Atka mackerel", area = "Bering Sea and Aleutian Islands",
  region = "Alaska", ocean = "Northeast Pacific", notes = "One stock; Aleutian subareas are not counted as separate assessments.")
assessment <- pacific_database_row("assessments", assessment_id = id,
  stock_id = "afsc_atka_mackerel_bsai", assessment_year = 2024, terminal_year = 2024,
  estimate_terminal_year = 2024, assessment_type = "full", model_family = "AMAK",
  model_version = "Model 16.0b", is_current = TRUE, is_applied = TRUE,
  assessment_url = report, framework_url = "https://apps-afsc.fisheries.noaa.gov/Plan_Team/2022/BSAIatka.pdf",
  data_url = report, model_url = "https://github.com/afsc-assessments/AMAK",
  repository_url = "https://github.com/JaneSullivan-NOAA/atkawham",
  assumptions_status = "partial", inputs_status = "partial", outputs_status = "partial",
  notes = "Latest detailed production model; 2025 rollover adds no fitted run. Report-precision compositions recovered from expanded numbers; missing early catch cells not invented. Exact supplied weights, unrounded states and covariance unavailable. See source review.")
append_pacific_case(stock, assessment, assumptions, inputs, outputs)
