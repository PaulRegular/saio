source("scripts/database/pacific_tables.R")
id <- "afsc_pollock_ai_2024"
report <- "https://files.npfmc.org/SAFE/2024/AIpollock.pdf"
pages <- pdftools::pdf_text("source_cache/afsc_pollock_ai/assessment_2024.pdf")
rows <- function(page) {
  l <- trimws(strsplit(pages[page], "\n")[[1]])
  l <- l[grepl("^(19|20)[0-9]{2}\\** ", l)]
  l <- l[!grepl("[A-Za-z]", l)]
  lapply(strsplit(gsub("[,*%]", "", l), "[[:space:]]+"), as.numeric)
}
age_matrix <- function(x, ages = 1:15) {
  z <- do.call(rbind, lapply(x, function(v) v[seq_len(length(ages) + 1)]))
  m <- z[, -1, drop = FALSE]
  dimnames(m) <- list(z[, 1], ages)
  m
}
fish_p <- age_matrix(rows(41))
survey_p <- age_matrix(rows(36)[1:12])
survey_w <- age_matrix(rows(37))
fish_w <- age_matrix(rows(42))
n <- age_matrix(rows(47))
survey <- do.call(rbind, rows(35))
survey <- survey[survey[, 1] >= 1991, ]
catch <- do.call(rbind, lapply(rows(32), function(v) c(year = v[1], value = tail(v, 1))))
catch <- catch[catch[, 1] >= 1978, ]
catch[catch[, 1] == 2024, 2] <- 5106
bio <- do.call(rbind, lapply(rows(46), function(v) {
  if (length(v) == 9) v[c(1,3,4,5,7,8,9)] else v
}))
bio <- bio[bio[, 1] <= 2024, ]
recruitment <- do.call(rbind, lapply(rows(50), function(v) c(v[1], tail(v, 2))))
mean_f <- do.call(rbind, rows(49))
fish_sizes <- c(100,33,100,100,101,101,104,102,101,101,104,104,102,101,100,100,100,100)
maturity <- c(0,.001,.021,.269,.565,.813,.899,.959,.984,.990,1,1,1,1,1)
stopifnot(nrow(fish_p) == 18, nrow(survey_p) == 12, nrow(n) == 47,
  nrow(bio) == 47, nrow(recruitment) == 47,
  identical(rownames(n), as.character(1978:2024)),
  max(abs(n[, 1] * 1000 - recruitment[, 2])) <= .5 + 1e-10,
  bio[bio[, 1] == 2024, 2] == 258150,
  bio[bio[, 1] == 2024, 5] == 84723)

input <- function(type, measure, basis, value, unit, year = NA_integer_, age = NA_integer_,
                  table, survey = "", fleet = "", ...) {
  pacific_database_row("inputs", assessment_id = id, type = type,
    measure = measure, basis = basis, value = value, unit = unit, year = year, age = age,
    sex = "combined", region = "Aleutian NRA", survey = survey, fleet = fleet,
    year_basis = ifelse(is.na(year), "", "calendar_year"), source_type = "official_table",
    source_reference = paste(report, table, sep = "; "), ...)
}
matrix_input <- function(m, type, measure, basis, unit, table, ...) {
  z <- pacific_matrix_long(m)
  input(type, measure, basis, z$value, unit, z$year, z$age, table = table, ...)
}
inputs <- rbind(
  input("catch", "total_biomass", "biomass", catch[,2], "t", catch[,1],
    table = "Table 1A.1 Best Estimates; Table 1A.22 terminal assumption", fleet = "Combined fishery",
    notes = "Best-estimate catch series, not simply the official blend column. 2024 fitted model assumes 5,106 t, not the incomplete September catch of 4,482 t."),
  matrix_input(fish_p, "catch", "proportion_at_age", "proportion_numbers", "proportion",
    "Table 1A.11", fleet = "Combined fishery", sample_size = rep(fish_sizes, 15),
    notes = "Observed number proportions; source has separate catch-biomass and multinomial likelihoods. Ages 15+; report rounding retained. AICASS age observations in 2006-2008 enter the fishery composition stream."),
  input("index", "total_biomass", "biomass", survey[,6], "t", survey[,1],
    table = "Table 1A.4, NRA biomass", survey = "AI_bottom_trawl",
    notes = "Fitted NRA (170W-170E) survey; pre-1991 surveys excluded. Summer timing; exact 2024 configured fraction not recovered."),
  input("index", "relative_standard_error", "relative_scale", survey[,7], "CV", survey[,1],
    table = "Table 1A.4, CV", survey = "AI_bottom_trawl",
    notes = "Published rounded survey CV; retained separately from composition weighting."),
  matrix_input(survey_p, "index", "proportion_at_age", "proportion_numbers", "proportion",
    "Table 1A.5, top panel", survey = "AI_bottom_trawl",
    sample_size = rep(c(1, rep(100,11)), 15),
    notes = "Design-based number proportions, not raw age-sample counts. Source multinomial N=1 in 1991, N=100 thereafter; current source deliberately omits pre-1991 ages."),
  matrix_input(survey_w, "weight", "weight_at_age", "kg_per_fish", "kg/fish",
    "Table 1A.6", survey = "AI_bottom_trawl",
    notes = "Original annual survey weights. Not claimed to be the separate native constant population-weight vector, which was not recovered for the 2024 run."),
  matrix_input(fish_w, "catch_weight", "weight_at_age", "kg_per_fish", "kg/fish",
    "Table 1A.12", fleet = "Combined fishery"),
  input("maturity", "maturity_at_age", "proportion", maturity, "proportion", age = 1:15,
    table = "Maturity section and Table 1A.14, GOA row",
    transformation = "GOA percentages divided by 100 to express female maturity as a probability; source combined-sex SSB applies a separate female fraction of 0.5.",
    notes = "Female proportions from the adopted GOA schedule, not the BSAI row printed alongside it. Combined-sex SSB applies female fraction 0.5; March spawning in unchanged framework.")
)
output <- function(type, measure, value, unit, year, age = NA_integer_, table, ...) {
  pacific_database_row("outputs", assessment_id = id, type = type, measure = measure,
    value = value, unit = unit, year = year, age = age, sex = "combined",
    region = "Aleutian NRA", source_type = "official_table",
    source_reference = paste(report, table, sep = "; "), ...)
}
nn <- pacific_matrix_long(n)
fsel <- c(.020,.039,.081,.176,.331,.511,.740,rep(1,8))
terminal_f <- mean_f[mean_f[,1] == 2024,2] * fsel / mean(fsel)
outputs <- rbind(
  output("population", "numbers_at_age", nn$value, "billion fish", nn$year, nn$age,
    table = "Table 1A.21", notes = "Begin-year MLE N, rounded to 0.001 billion fish; ages 15+. No state uncertainty supplied."),
  output("biomass", "total_biomass", bio[,2], "t", bio[,1], table = "Table 1A.19, 2024 model",
    lwr = bio[,3], upr = bio[,4], notes = "Native age-1+ MLE biomass; approximate 95% confidence limits, not 2022 model values."),
  output("biomass", "SSB", bio[,5], "t", bio[,1], table = "Table 1A.19, 2024 model",
    lwr = bio[,6], upr = bio[,7], notes = "Native female spawning biomass; approximate 95% confidence limits. Separate native population-weight vector is not recovered."),
  output("recruitment", "recruitment", recruitment[,2], "million fish", recruitment[,1], 1,
    table = "Table 1A.24, 2024 Model 15.1", se = recruitment[,3],
    notes = "Age-1 MLE and natural-scale standard deviation; report precision differs from the rounded N table."),
  output("mortality", "natural_mortality_at_age", rep(.206,47*15), "per year",
    rep(1978:2024,15), rep(1:15,each=47), table = "Table 1A.18, Model 15.1 mean M",
    notes = "Estimated constant M, reported to three decimals. Prior mean 0.2 and CV 0.2; not a fixed biological input. The 0.21 row in Table 1A.15 is a coarser rounding."),
  output("mortality", "Fbar", mean_f[,2], "per year", mean_f[,1], table = "Table 1A.23, footnote a",
    age_group = "1-15+", notes = "Arithmetic average over all model age groups, despite the table heading mentioning full selection. Not population-weighted Fbar."),
  output("mortality", "fishing_mortality_at_age", terminal_f, "per year", 2024, 1:15,
    table = "Tables 1A.20 and 1A.23", source_type = "derived_source_output",
    notes = "2024 arithmetic mean F times terminal fishery selectivity divided by its arithmetic mean. Only terminal selectivity is recovered; no historical F-at-age is invented. Report rounding; no uncertainty reconstructed.")
)
assume <- function(component, setting, value, notes = "") pacific_database_row("assumptions",
  assessment_id = id, component = component, setting = setting, value = value,
  source_reference = report, notes = notes)
assumptions <- do.call(rbind, list(
  assume("assessment", "official_model", "2024 Model 15.1, retained by December 2024 SSC; next operational assessment scheduled for 2026"),
  assume("population", "dimensions", "1978-2024; ages 1-15+; combined-sex Aleutian NRA, 170W-170E"),
  assume("N", "process", "Deterministic cohort survival, equilibrium initial abundance"),
  assume("recruitment", "process", "Beverton-Holt; steepness fixed 0.7; recruitment variability fixed at source setting 0.6", "Report calls this a variance; the historical control labels SigmaR. Exact current implementation scale remains unresolved without the production control file."),
  assume("F", "process", "Annual scalar times nonparametric age selectivity; ages 8-15 share selectivity; mean-one normalization; smoothness penalties and periods 1978-1989, 1990-1998, 1999-2007, 2008-2024"),
  assume("M", "process", "One estimated age-constant M, prior mean 0.2 CV 0.2; alternative Model 15.2 is not the official run"),
  assume("q", "process", "Fixed scalar q=1 under normalization over ages 5-12; estimated time-invariant nonparametric age selectivity, shared at ages 8+"),
  assume("catch", "observation_model", "Lognormal biomass (historical input CV 0.05) plus multinomial age compositions with supplied sample sizes in assessment p.12; no lengths fitted"),
  assume("index", "observation_model", "Lognormal summer survey biomass plus multinomial age compositions; sample size 1 in 1991, 100 thereafter; pre-1991 ages excluded"),
  assume("index", "sampling_time", "unknown", "Summer survey, May-August. Current configured fraction not recovered; public historical data and example source versions do not establish the 2024 value."),
  assume("biology", "population_weights", "unknown", "The current report gives annual fishery/survey weights, but not the separate constant population-weight vector. Do not substitute the 2022 vector as an original 2024 input."),
  assume("biology", "maturity", "Adopted GOA female maturity; combined-sex spawning biomass uses female fraction 0.5, March spawning"),
  assume("biology", "ageing_error", "Fixed 15x15 ageing-error matrix, Table 1A.16"),
  assume("outputs", "F_definition", "Table 1A.23 F is arithmetic average over ages (footnote a), not fully-selected F or population-weighted Fbar")
))
age_error <- trimws(strsplit(pages[44], "\n")[[1]])
age_error <- age_error[grepl("^([1-9]|1[0-5])\\+? ", age_error)]
age_error <- gsub("+", "", age_error, fixed = TRUE)
age_error <- lapply(strsplit(age_error, "[[:space:]]+"), as.numeric)
age_error <- age_error[lengths(age_error) == 16]
stopifnot(length(age_error) == 15)
for (v in age_error) assumptions <- rbind(assumptions,
  assume("biology", paste0("age_error_row_", v[1]), paste(v[-1], collapse = " "),
    "Fixed probabilities at printed Table 1A.16 precision; observed and true age groups 1-15+."))
stock <- pacific_database_row("stocks", stock_id = "afsc_pollock_ai",
  charbonneau_id = "AFSC_AI_Gadus_chalcogrammus", authority = "NOAA-AFSC",
  authority_stock_id = "Aleutian Islands pollock", scientific_name = "Gadus chalcogrammus",
  common_name = "Aleutian Islands walleye pollock", area = "Aleutian Islands NRA (170W-170E)",
  region = "Alaska", ocean = "Northeast Pacific", notes = "One stock; Bering Sea pollock and Bogoslof pollock are separate assessments.")
assessment <- pacific_database_row("assessments", assessment_id = id, stock_id = "afsc_pollock_ai",
  assessment_year = 2024, terminal_year = 2024, estimate_terminal_year = 2024,
  assessment_type = "full", model_family = "AMAK", model_version = "Model 15.1",
  is_current = TRUE, is_applied = TRUE, assessment_url = report, framework_url = report,
  data_url = report, model_url = "https://github.com/afsc-assessments/AI_pollock",
  repository_url = "https://github.com/afsc-assessments/AI_pollock",
  inputs_status = "partial", assumptions_status = "partial", outputs_status = "partial",
  notes = "Official 2024 Model 15.1, verified against final SSC. Report-precision observations and outputs; native public repository only exposes older fitted runs, not substituted here. Current constant population weights, exact survey fraction and historical F-at-age remain unresolved.")
append_pacific_case(stock, assessment, assumptions, inputs, outputs)
