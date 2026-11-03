source("scripts/database/pacific_tables.R")
root <- "."
cache <- file.path(root, "source_cache/afsc_pop_bsai/native")
id <- "afsc_pop_bsai_2024"
revision <- jsonlite::fromJSON(file.path(dirname(cache), "repository_revision.json"))$sha
repository <- "https://github.com/afsc-assessments/BSAI-POP"
native <- paste0(repository, "/tree/", revision, "/2024%20assessment")
report <- "https://files.npfmc.org/SAFE/2024/BSAIpop.pdf"
x <- dget(file.path(cache, "m_24_2_reweighted.rdat"))
dat <- readLines(file.path(cache, "pop24.dat"))
ctl <- readLines(file.path(cache, "pop24.ctl"))
std <- read.table(file.path(cache, "m_24_2_reweighted.std"), header = TRUE)
composition_multipliers <- scan(file.path(cache, "compweights.ctl"), quiet = TRUE)
after <- function(pattern, n, lines = dat) {
  at <- grep(pattern, lines)
  if (length(at) != 1L) cli::cli_abort("Source label is not unique: {pattern}.")
  scan(text = paste(lines[seq.int(at + 1L, length(lines))], collapse = "\n"),
       nmax = n, comment.char = "#", quiet = TRUE)
}
years <- 1960:2024
ages <- 3:46
comp_ages <- 3:40
weight <- after("^# population weight", 44)
catch_weight <- after("^# fishery weight", 44)
stopifnot(identical(dim(x$natage), c(65L, 38L)),
          max(abs(rowSums(x$natage) - x$t.series$totnum)) < 0.02,
          abs(tail(x$t.series$spbiom, 1) - 359280) <= 5,
          tail(x$t.series$totbiom, 1) == 864800,
          tail(x$t.series$M, 1) == 0.0505762)

input <- function(type, measure, basis, value, unit, year = NA_integer_,
                  age = NA_integer_, fleet = "", survey = "", ...,
                  source_reference = paste0(native, "; pop24.dat")) {
  pacific_database_row("inputs", assessment_id = id, type = type,
    measure = measure, basis = basis, value = value, unit = unit,
    year = year, age = age, fleet = fleet, survey = survey, sex = "combined",
    region = "BSAI", year_basis = ifelse(is.na(year), "", "calendar_year"),
    source_type = "native_model", source_reference = source_reference, ...)
}
inputs <- list(
  input("catch", "total_biomass", "biomass", x$t.series$catchbio, "t",
        years, fleet = "Combined fishery"),
  input("weight", "weight_at_age", "kg_per_fish", weight, "g/fish", age = ages,
        notes = "Time-invariant supplied population weight. Native values in grams; stored without conversion."),
  input("catch_weight", "weight_at_age", "kg_per_fish", catch_weight, "g/fish",
        age = ages, fleet = "Combined fishery",
        notes = "Separate supplied catch-weight vector; equal to population weights in this run.")
)
composition <- function(matrix, type, measure, fleet = "", survey = "",
                        label, size, raw_count, bins) {
  raw <- matrix(after(label, length(matrix)), nrow = nrow(matrix), byrow = TRUE,
                dimnames = dimnames(matrix))
  stopifnot(max(abs(raw / rowSums(raw) - matrix)) < 1e-6)
  z <- pacific_matrix_long(raw)
  if (measure == "proportion_at_length") z$age <- NA_integer_
  is_length <- measure == "proportion_at_length"
  proportions <- input(type, if (is_length) "frequency_at_length" else measure,
    if (is_length) "native_frequency" else "proportion_numbers", z$value,
    if (is_length) "source frequency" else "proportion", z$year, z$age,
    fleet = fleet, survey = survey,
    length_bin = if (measure == "proportion_at_length") rep(bins, each = nrow(raw)) else NA_real_,
    observation_id = paste(type, if (nzchar(fleet)) fleet else survey, measure, z$year, sep = ":"),
    sample_size = rep(size, times = ncol(raw)),
    notes = "Original number compositions, not abundance indices. Length frequencies retain their native row totals (some rows are counts); source code normalizes each row. Age 40 and length 39 are terminal observation groups. sample_size is the supplied square-root count times the native composition multiplier, not an estimated effective sample size.")
  counts <- input("biology", "composition_sample_count", "numbers", raw_count,
    "fish", as.integer(rownames(raw)), fleet = fleet, survey = survey,
    observation_id = paste(type, if (nzchar(fleet)) fleet else survey, measure,
                           rownames(raw), sep = ":"),
    notes = "Raw measured or aged fish count; separate from the transformed, reweighted likelihood sample_size on composition cells.")
  rbind(proportions, counts)
}
inputs[[length(inputs) + 1L]] <- composition(x$oac.f.unbiased, "catch",
  "proportion_at_age", fleet = "Combined fishery",
  label = "^#[[:space:]]+unbiased fishery age compositions",
  size = after("^## sqrt of read otoliths \\(#stg1_fish", 22, ctl) * composition_multipliers[1],
  raw_count = after("^## number of otoliths read \\(#nsamples_fish", 22, ctl), bins = comp_ages)
inputs[[length(inputs) + 1L]] <- composition(x$olc.fish, "catch",
  "proportion_at_length", fleet = "Combined fishery",
  label = "^#[[:space:]]+fishery length compositions",
  size = after("^## sqrt of fished lengthed", 32, ctl) * composition_multipliers[2],
  raw_count = after("^## number of fishery lengths \\(#nsamples_fish", 32, ctl), bins = 15:39)

for (survey in c("AI_survey", "EBS_survey")) {
  z <- x[[paste0(survey, "_obs_bio_abun")]]
  yy <- as.integer(rownames(z))
  # Both totals are supplied. Control flags fit biomass, not abundance.
  inputs[[length(inputs) + 1L]] <- input("index", "total_biomass", "biomass",
    z$obssrv_bio, "t", yy, survey = survey,
    notes = "Active biomass index; native prediction averages survival across the year, not an instantaneous sampling date.")
  inputs[[length(inputs) + 1L]] <- input("index", "total_numbers", "numbers",
    z$obssrv_abun, "million fish", yy, survey = survey,
    notes = "Supplied abundance series is mapped out by fit_srv_abun=0; retained for provenance, not a second independent observation.")
  survey_number <- match(survey, c("AI_survey", "EBS_survey"))
  sd <- after("^#[[:space:]]*Survey  standard deviations \\(mt\\)", 20)
  ss <- if (survey_number == 1L) sd[1:14] else sd[15:20]
  inputs[[length(inputs) + 1L]] <- input("index", "index_sd", "index_scale",
    ss, "t", yy, survey = survey,
    notes = "Supplied SD of the biomass survey index on its natural scale.")
  m <- x[[paste0("oac.", survey)]]
  inputs[[length(inputs) + 1L]] <- composition(m, "index", "proportion_at_age",
    survey = survey, label = paste0("^# survey age comps \\(",
      if (survey_number == 1L) "AI" else "EBS", " survey\\)"),
    size = after("^## sqrt of read otoliths \\(#stg1_srv", 19, ctl)[
      if (survey_number == 1L) 1:13 else 14:19] * composition_multipliers[2 + survey_number],
    raw_count = after("^## number of otoliths read \\(#nsamples_srv", 19, ctl)[
      if (survey_number == 1L) 1:13 else 14:19], bins = comp_ages)
  m <- x[[paste0("olc.", survey)]]
  if (!is.null(m) && nrow(m)) inputs[[length(inputs) + 1L]] <- composition(m, "index",
    "proportion_at_length", survey = survey,
    label = paste0("^#[[:space:]]+survey[[:space:]]+length[[:space:]]+compositions \\(",
                   if (survey_number == 1L) "AI" else "EBS", "\\)"),
    size = after("^## sqrt of fish lengthed", 1, ctl) * composition_multipliers[4 + survey_number],
    raw_count = after("^## number of fishery lengths \\(#nsamples_srv", 1, ctl), bins = 15:39)
}
mat_ages <- after("^# ages \\(first row TenBrink", 44)
for (measure in c("maturity_sample_size", "mature_sample_count")) {
  counts <- after(if (measure == "maturity_sample_size") "^# fish sampled for maturity" else
                    "^# number of mature fish", 44)
  inputs[[length(inputs) + 1L]] <- input("biology", measure, "numbers", counts,
    "fish", age = mat_ages,
    observation_id = rep(c("TenBrink", "Shaw"), c(21, 23)),
    notes = "Female maturity sampling data fitted by the source binomial maturity likelihood.")
}
inputs <- do.call(rbind, inputs)
inputs$sex[inputs$measure %in% c("maturity_sample_size", "mature_sample_count")] <- "female"

output <- function(type, measure, value, unit, year = NA_integer_, age = NA_integer_,
                   se = NA_real_, notes = "", ...) {
  pacific_database_row("outputs", assessment_id = id, type = type, measure = measure,
    value = value, unit = unit, year = year, age = age, se = se, sex = "combined",
    region = "BSAI", source_type = "native_model",
    source_reference = paste0(native, "; m_24_2_reweighted.rdat / .std"), notes = notes, ...)
}
output_matrix <- function(matrix, type, measure, unit, notes) {
  z <- pacific_matrix_long(matrix)
  output(type, measure, z$value, unit, z$year, z$age,
    age_group = ifelse(z$age == 40, "40+", ""), notes = notes)
}
outputs <- list(
  output_matrix(x$natage, "population", "numbers_at_age", "million fish",
    "Beginning-year combined-sex numbers. Reported 40+ sums modeled ages 40-46+. No state uncertainty supplied."),
  pacific_database_row("outputs", assessment_id = id, type = "population",
    measure = "total_abundance", year = as.integer(rownames(x$natage)),
    value = rowSums(x$natage),
    unit = "million fish", source_type = "derived_source_output",
    source_reference = paste0(native, "; m_24_2_reweighted.rdat$natage"),
    notes = paste(
      "Derived by summing reported population numbers at ages 3-39 and 40+ for each year.",
      "Standard errors and intervals are unavailable because joint uncertainty for N-at-age is not supplied."
    )),
  output_matrix(x$selfish * x$t.series$fmort, "mortality", "fishing_mortality_at_age",
    "per year", "F = reported annual F multiplier times reported selectivity. Tail selectivity is constant after age 40; no uncertainty reconstructed."),
  output("mortality", "natural_mortality_at_age", rep(x$t.series$M, length(ages)),
    "per year", rep(years, times = length(ages)), rep(ages, each = length(years)),
    notes = "Estimated age-constant and time-constant M. Source lognormal prior mean 0.05, CV 0.05. Not a fixed input."),
  output("biomass", "SSB", x$t.series$spbiom, "t", years,
    se = std$std.dev[std$name == "sp_biom"][seq_along(years)],
    notes = "MLE female SSB at April 1, using half the combined-sex N and estimated maturity. Natural-scale marginal ADMB SE; no intervals invented."),
  output("biomass", "total_biomass", x$t.series$totbiom, "t", years,
    notes = "Beginning-year ages 3-46+ biomass; MLE."),
  output("recruitment", "recruitment", x$t.series$a3recs, "million fish", years,
    age = 3, notes = "Age-3 beginning-year abundance; final three years use the source's mean-recruitment rule.")
)
for (parameter in c("mat_beta1", "mat_beta2")) {
  z <- std[std$name == parameter, ]
  outputs[[length(outputs) + 1L]] <- output("biology", parameter, z$value,
    "logit maturity coefficient", se = z$std.dev,
    notes = "Maturity = plogis(mat_beta1 + mat_beta2 * age); source adjusts its oldest modeled age towards age 100 maturity. Coefficient-scale SE.")
}
outputs <- do.call(rbind, outputs)

assume <- function(component, setting, value, reference = "pop24.dat / pop24.ctl / pop24.tpl", notes = "") {
  pacific_database_row("assumptions", assessment_id = id, component = component,
    setting = setting, value = value, source_reference = paste(native, reference, sep = "; "), notes = notes)
}
assumptions <- list(
  assume("assessment", "official_model", "2024 Model 24; m_24_2_reweighted", notes = "Native historical biomass, SSB and recruitment agree with SAFE Table 12.25 within printed rounding; December 2025 rollover does not add a new fitted model."),
  assume("population", "dimensions", "1960-2024; ages 3-46+; combined-sex; BSAI; one annual season"),
  assume("population", "reported_age_groups", "3-39 and 40+", notes = "Observation and exported N bins differ from the model plus age 46."),
  assume("N", "process", "Deterministic survival given F and M; initial equilibrium with historical F fixed at zero"),
  assume("recruitment", "process", "Lognormal deviations about separate mean recruitment before/after 1990; sigmaR=0.75; final 3 years fixed to bias-corrected mean; no fitted BH relation (option 1)"),
  assume("F", "process", "Annual F scalars and bicubic spline selectivity; penalties: dome=30, age smoothness=10, temporal variation=300, temporal smoothness=300"),
  assume("M", "process", "One estimated constant; lognormal prior mean 0.05, CV 0.05; one bin; no time-varying deviation penalty"),
  assume("index", "observation_model", "Biomass lognormal likelihoods; number totals inactive. Prediction uses (1-exp(-Z))/Z averaged over the year; no exact sampling_time"),
  assume("q", "process", "Two constant q parameters, both estimated; logistic age selectivity; AI q prior mean 1, CV 0.15; EBS q prior inactive"),
  assume("catch", "observation_model", "Total biomass likelihood weight 500 plus separate multinomial age and length compositions"),
  assume("biology", "maturity", "Estimated logistic age curve; female binomial samples; maturity-input switch 0; April 1 spawning"),
  assume("biology", "SSB_definition", "0.5 * sum(N * wt_pop * maturity * exp(-0.25 * Z)); female biomass in tonnes"),
  assume("biology", "weight_units", "Supplied grams; population N in millions; N * weight yields tonnes")
)
for (spec in list(c("age_error", "^#[[:space:]]+matrix for unbiased", 44, 44),
                  c("length_at_age_key", "^#[[:space:]]+matrix for length comps", 25, 44))) {
  m <- matrix(after(spec[2], as.integer(spec[3]) * as.integer(spec[4])),
              nrow = as.integer(spec[3]), byrow = TRUE)
  for (i in seq_len(nrow(m))) assumptions[[length(assumptions) + 1L]] <-
    assume("biology", paste0(spec[1], "_row_", i), paste(m[i, ], collapse = " "),
      notes = if (spec[1] == "age_error") "Rows observed age, columns true age; model ages 3-46+." else "Rows length bins 15-39+, columns model ages 3-46+.")
}
assumptions[[length(assumptions) + 1L]] <- assume("observation", "composition_multipliers",
  paste(composition_multipliers, collapse = " "),
  notes = "Order: fish age, fish length, AI age, EBS age, AI length, EBS length. Multiply supplied square-root counts; raw counts remain in inputs.")
assumptions <- do.call(rbind, assumptions)

stock <- pacific_database_row("stocks", stock_id = "afsc_pop_bsai",
  charbonneau_id = "AFSC_alutus_BSAI", authority = "NOAA-AFSC",
  authority_stock_id = "BSAI Pacific ocean perch", scientific_name = "Sebastes alutus",
  common_name = "Bering Sea/Aleutian Islands Pacific ocean perch", area = "Bering Sea and Aleutian Islands",
  region = "Alaska", ocean = "Northeast Pacific",
  notes = "Broader Charbonneau-Keith Master.csv catalogue; one stock, not separate survey areas.")
assessment <- pacific_database_row("assessments", assessment_id = id,
  stock_id = "afsc_pop_bsai", assessment_year = 2024, terminal_year = 2024,
  estimate_terminal_year = 2024, assessment_type = "full", model_family = "ADMB statistical catch-at-age",
  model_version = "Model 24 (m_24_2_reweighted)", is_current = TRUE, is_applied = TRUE,
  assessment_url = report, framework_url = report, data_url = native, model_url = native,
  repository_url = repository, assumptions_status = "partial", inputs_status = "partial",
  outputs_status = "partial", notes = paste(
    "Official 2024 model retained under 2025 catch-only rollover. Native catch, both surveys, age/length compositions, raw sample counts, weights, maturity samples and observation keys retained.",
    "Native N is exported only as 3-39/40+ rather than full 3-46+; state uncertainty and some control semantics remain unexported. See source_reviews/afsc_pop_bsai.md."
  ))
append_pacific_case(stock, assessment, assumptions, inputs, outputs)
cat("Imported", id, ":", nrow(inputs), "inputs;", nrow(outputs), "outputs.\n")
