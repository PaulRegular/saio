source("scripts/database/pacific_tables.R")
source("scripts/database/pacific_sources.R")
source("scripts/database/pacific_ss.R")

id <- "dfo_canary_bc_2022"
stock_id <- "dfo_canary_bc"
revision <- "16f1d4368ad7d3e854219ca1c2d9d6353252c861"
base <- paste0("https://raw.githubusercontent.com/pbs-software/pbs-synth/", revision,
               "/models/input/2022/CAR/CST/Base/R24/24.01/")
native <- sub("raw.githubusercontent.com", "github.com", base, fixed = TRUE)
native <- sub(paste0("/", revision, "/"), paste0("/tree/", revision, "/"), native, fixed = TRUE)
report <- "https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41218875.pdf"
cache <- file.path("source_cache", stock_id)
cache_pacific_source(stock_id, report, "research_2023_070.pdf")
cache_pacific_source(stock_id, "https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41097312.pdf",
                     "advice_2023_002.pdf")
for (file in c("data.24.01.ss", "control.24.01.ss", "starter.ss", "forecast.ss")) {
  cache_pacific_source(stock_id, paste0(base, file), paste0("native/", file), revision)
}
posterior_revision <- "7f1c59b8cc3895a3477204ac16da6cf15e2466c6"
posterior_url <- paste0("https://raw.githubusercontent.com/pbs-assess/gftrends/",
                        posterior_revision, "/data-raw/canary-bc-mcmc.rds")
posterior_file <- cache_pacific_source(stock_id, posterior_url,
  "posterior/canary-bc-mcmc.rds", posterior_revision)
cache_pacific_source(stock_id, paste0("https://raw.githubusercontent.com/pbs-assess/gftrends/",
  posterior_revision, "/data-raw/process-raw-data.R"), "posterior/process-raw-data.R", posterior_revision)

dat <- r4ss::SS_readdat(file.path(cache, "native/data.24.01.ss"), verbose = FALSE)
ctl <- r4ss::SS_readctl(file.path(cache, "native/control.24.01.ss"), datlist = dat, verbose = FALSE)
wt <- r4ss::SS_readwtatage(file.path(cache, "fixed_biology_evaluation/wtatage.ss_new"))
stopifnot(dat$styr == 1935, dat$endyr == 2022, dat$Nsexes == 2, dat$Nages == 60,
  dat$Nfleets == 8, dat$spawn_month == 1, all(ctl$size_selex_types$Pattern == 0),
  ctl$maturity_option == 3, ctl$fecundity_option == 1, ctl$F_Method == 1,
  all(ctl$MG_parms$PHASE[grepl("L_at_|VonBert_|CV_|Wtlen_", rownames(ctl$MG_parms))] < 0))

input <- function(type, measure, basis, value, unit, year = NA_integer_, age = NA_integer_,
                  fleet = "", survey = "", sex = "combined", ...) {
  pacific_database_row("inputs", assessment_id = id, type = type, measure = measure,
    basis = basis, value = value, unit = unit, year = year, age = age,
    fleet = fleet, survey = survey, sex = sex, region = "BC coast",
    year_basis = ifelse(is.na(year), "", "calendar_year"),
    source_type = "native_model", source_reference = native, ...)
}
catch <- dat$catch[dat$catch$year >= dat$styr, ]
index <- dat$CPUE
inputs <- list(
  input("catch", "total_biomass", "biomass", catch$catch, "t", catch$year,
    fleet = dat$fleetnames[catch$fleet],
    notes = "Original retained plus reconstructed releases by fleet. Catch log SD fixed 0.01. Incomplete 2022 catch was set to 780 t after industry consultation, allocated by fleet using 2017-2021 shares; not final observed 2022 catch. Equilibrium (-999) zero catches are configured initial conditions, not annual observations."),
  input("index", ifelse(index$index == 1, "relative_biomass_index", "total_biomass"),
    ifelse(index$index == 1, "index_scale", "biomass"), index$obs,
    ifelse(index$index == 1, "relative index", "t"), index$year,
    survey = ifelse(index$index == 1, "TRAWL_CPUE", dat$fleetnames[index$index]),
    sampling_time = (index$seas - 1) / 12,
    notes = "Native biomass index; SS3 units=1, lognormal error. Commercial CPUE is standardized relative biomass, not tonnes. Native observation month 6 is 5/12 of the year. No age allocation has been applied."),
  input("index", "log_index_sd", "log_scale", index$se_log, "log SD", index$year,
    survey = ifelse(index$index == 1, "TRAWL_CPUE", dat$fleetnames[index$index]),
    sampling_time = (index$seas - 1) / 12,
    notes = "Supplied reweighted log-index SD in final 24.01 data. Commercial CPUE includes added process CV 0.178; survey additional process CV is zero. Not a natural-scale SE.")
)
inputs[[length(inputs) + 1L]] <- pacific_ss_compositions(dat, "age", id, native, "BC coast")

for (sex in 1:2) {
  for (fleet in c(0, -1, -2, 1:8)) {
    w <- wt[wt$Sex == sex & wt$Fleet == fleet, as.character(0:60)]
    stopifnot(nrow(w) > 0, max(apply(w, 2, function(v) diff(range(v)))) < 1e-10)
    values <- as.numeric(w[1, ])
    type <- if (fleet == -2) "biology" else if (fleet %in% 1:2) "catch_weight" else "weight"
    measure <- if (fleet == -2) "maturity_fecundity_at_age" else "weight_at_age"
    row <- input(type, measure, "kg_per_fish", values, "kg/fish", age = 0:60,
      fleet = if (fleet %in% 1:2) dat$fleetnames[fleet] else "",
      survey = if (fleet >= 3) dat$fleetnames[fleet] else "",
      sex = c("female", "male")[sex],
      season = if (fleet == 0) "begin_year" else if (fleet == -2) "spawning" else "mid_year",
      transformation = "Evaluate original fixed growth, length CV and weight-length functions with SS3 v3.30.18, -maxfn 0 -nohess -nox; retain fixed biology only.",
      notes = paste("Reconstructed fixed source biology, including source length variation; not a fitted biological estimate.",
        if (fleet == -2) "Effective maturity times weight: executable applies first-mature-age cutoff 10 from input 10.6; zero below 10. Fecundity option 1 has coefficients 1,0. Male reproductive output is zero." else
          "Source weights are constant across years. Fleet weights equal the mid-season population weights; survey conversion uses these with a documented timing approximation."))
    row$source_type <- "reconstructed_source_input"
    inputs[[length(inputs) + 1L]] <- row
  }
}
inputs[[length(inputs) + 1L]] <- input("maturity", "maturity_at_age", "proportion",
  as.numeric(ctl$Age_Maturity), "proportion", age = 0:60, sex = "female",
  notes = "Original supplied maturity-option-3 vector, not the effective reproductive-output schedule. Values at ages 4-9 are nonzero, but the matching executable's first-mature-age cutoff removes these contributions; effective maturity-fecundity weights are stored separately.")

output <- function(type, measure, value, unit, year = NA_integer_, age = NA_integer_,
                   sex = "female", reference = report, source_type = "official_table", ...) {
  pacific_database_row("outputs", assessment_id = id, type = type, measure = measure,
    value = value, unit = unit, year = year, age = age, sex = sex, region = "BC coast",
    source_reference = reference, source_type = source_type, ...)
}
draws <- readRDS(posterior_file)
stopifnot(nrow(draws) == 44500L, length(unique(draws$iter)) == 500L,
  identical(sort(unique(draws$year)), 1935:2023), !anyDuplicated(draws[c("iter", "year")]),
  all(is.finite(draws$b) & draws$b > 0), all(table(draws$iter) == 89L),
  all(draws$species == "canary"), all(draws$region == "BC"))
ssb <- t(vapply(split(draws$b, draws$year), stats::quantile, numeric(3),
                probs = c(.025, .5, .975), type = 7))
outputs <- list(output("biomass", "SSB", ssb[, 2], "t", as.integer(rownames(ssb)),
  lwr = ssb[, 1], upr = ssb[, 3], reference = posterior_url, source_type = "derived_source_output",
  notes = "Female beginning-year spawning biomass: median and equal-tail 95% credible limits of the public 500-draw subset, R quantile type 7. Source processing randomly downsampled 2000 official Run24 posterior draws (seed 123). Not exact full-posterior quantiles; no rescaling or SE inferred. 2023 is the beginning-year state after provisional 2022 catches."),
  output("biomass", "published_terminal_SSB", 10761, "t", 2023, lwr = 7275, upr = 17637,
    notes = "Research Document Table 2: official full-posterior median B2023 and 90% credible limits (5%-95%). Kept separate from the public subset summaries."),
  output("biomass", "Bmsy", 3580, "t", 2023, lwr = 2149, upr = 5964,
    notes = "Research Document Table 2: official posterior median and 90% credible limits (5%-95%). Assessment reference value, not a time-varying BMSY series."))
for (sex in c("female", "male")) {
  m <- if (sex == "female") c(.09329, .08094, .1063) else c(.06543, .05471, .07748)
  outputs[[length(outputs) + 1L]] <- output("mortality", "natural_mortality_at_age",
    m[1], "per year", year = rep(1935:2022, 61), age = rep(0:60, each = 88),
    sex = sex, lwr = m[2], upr = m[3],
    notes = "Table 1: estimated sex-specific constant M, posterior median and 90% credible limits (5%-95%). The same parameter applies to every age and year in 1935-2022; these are not independent annual estimates. No fixed-M input or natural-scale SE inferred.")
}

assume <- function(component, setting, value, fleet = "", survey = "", sex = "", notes = "") {
  pacific_database_row("assumptions", assessment_id = id, component = component,
    setting = setting, value = value, fleet = fleet, survey = survey, sex = sex,
    region = "BC coast", source_reference = paste(native, ";", report), notes = notes)
}
assumptions <- list(
  assume("assessment", "official_model", "Run24 / 24.01, SS3 v3.30.18; official September 2022 peer-reviewed assessment, SAR 2023/002 and Research Document 2023/070. One base run, not its 14 MCMC sensitivity runs."),
  assume("population", "dimensions", "1935-2022, ages 0-60+, female and male, one coastwide area 3CD5ABCDE excluding 4B; one annual season with two growth sub-seasons."),
  assume("population", "initial_conditions", "Unfished equilibrium in 1935; configured equilibrium catches zero; early recruitment deviations start 1920. Initial older cohorts are not independently free N0 parameters."),
  assume("recruitment", "recruitment_age", "0"),
  assume("recruitment", "stock_recruit", "Beverton-Holt (SS3 function 3). Estimated log R0 (prior normal 7, SD7, phase1); h (beta prior mean .67, SD .17, phase5); fixed sigmaR .9; autocorrelation disabled."),
  assume("recruitment", "deviations", "Main log-recruitment deviations 1950-2012, phase2, constrained to sum zero; early deviations from 1920 and recent deviations with reduced bias adjustment. Bias adjustment maximum .65; ramps 1942-1978 and 2009-2015."),
  assume("N", "process", "Deterministic cohort survival and 60+ accumulator; no independent survival-process errors. January 1 spawning; separate female/male states, recruitment sex fraction .5."),
  assume("F", "process", "SS3 F_Method=1: Pope approximation using known catch biomass and independent annual fleet intensities, not a temporal F random walk or tinyAM's Baranov catch equation."),
  assume("F", "selectivity", "Time-invariant age double-normal curves forced asymptotic (pattern20, descending width200 fixed); trawl peak and ascending width estimated with normal priors. Male peak offset estimated, other male shape offsets fixed; apical male selectivity1."),
  assume("F", "other_fishery", "Non-trawl fleet has fixed selectivity at prior means (peak14, log ascending width2.5, male offset-.4), not fitted trawl selectivity. No age samples; do not claim an observed non-trawl age composition.", fleet = "OTHER_FISHERY"),
  assume("M", "process", "Constant M estimated separately for females and males; normal natural-scale prior mean .06, SD .018, bounds .02-.2, phase4. No M process variation and no supplied fixed M."),
  assume("catch", "observation_model", "Two biomass fleets, TRAWL_FISHERY and OTHER_FISHERY; catch log SD .01. Joint-sex trawl ages (36 sampled years, 1977-2017), ages1-60+; supplied row sample sizes and age-error keys retained. No sampled ages2018-2022."),
  assume("catch", "provisional_terminal_catch", "2022 total catch assumed 780 t after industry consultation, split 766.6636648 t trawl and 13.33633516 t other using 2017-2021 catch shares. Retain the official provisional input, not final observed landings."),
  assume("catch", "composition_error", "SS3 Dirichlet-multinomial, separate estimated parameter for each sampled fishery/survey. Native joint-sex cells sum to one; female/male samples are not independently normalized. addtocomp=.0001; minimum sample size .001; no Francis composition reweighting."),
  assume("biology", "growth", "Fixed sex-specific von Bertalanffy L1 at age1, L2 at age60, K, length CV and weight-length coefficients (negative phases). No empirical WAA input. Matching v3.30.18 evaluated with zero optimization for fixed weights only."),
  assume("biology", "maturity", "Original female maturity-option3 vector retained. First_Mature_Age=10.6 is read as age10 by executable, removing spawning contributions below10 despite positive supplied maturity at4-9. Effective maturity-fecundity weights retained separately."),
  assume("biology", "spawning_time", "January 1 (month1, fraction0); female mature biomass in tonnes. Fecundity option1, alpha1, beta0. Population beginning-year weights distinct from midyear catch weights."),
  assume("index", "cpue", "Standardized bottom-trawl relative biomass CPUE, 1996-2021, month6 (5/12); lognormal, added process CV .178. Aggregate-only series without a matching independent age composition.", survey = "TRAWL_CPUE"),
  assume("source", "estimate_convention", "Official advice uses 2000 posterior draws, medians and 90% equal-tail intervals. gftrends publicly retains 500 randomly sampled joint SSB/BMSY trajectories; derived 95% limits are labelled separately. Annual N/F/recruitment numerical outputs not recovered."),
  assume("source", "missing_material", "Joint posterior N/F/recruitment and exact full SSB posterior absent publicly. Native ageing-error definition vectors remain in pinned files but are not transcribed into numerical canonical rows; inputs_status remains partial.")
)
for (survey in dat$fleetnames[3:8]) {
  f <- match(survey, dat$fleetnames)
  years <- dat$CPUE$year[dat$CPUE$index == f]
  ages <- dat$agecomp$Yr[dat$agecomp$FltSvy == f]
  assumptions <- c(assumptions, list(
    assume("index", "observation_model", paste("Biomass in tonnes, lognormal index; years", paste(years, collapse = ","),
      "; month6, sampling fraction5/12. Supplied final log SDs retained; no extra process CV."), survey = survey),
    assume("index", "age_compositions", if (length(ages)) paste("Joint-sex number proportions at ages1-60+, supplied N and age-error keys; sampled years", paste(ages, collapse = ",")) else "No age composition supplied; aggregate biomass index only.", survey = survey),
    assume("q", "selectivity", if (length(ages)) "Profiled constant scalar q, estimated female asymptotic double-normal age selectivity and male peak offset; informative selectivity priors." else "Profiled constant scalar q; age selectivity fixed at prior means, not estimated without ages.", survey = survey)
  ))
}
stock <- pacific_database_row("stocks", stock_id = stock_id, authority = "DFO",
  authority_stock_id = "Coastwide Canary Rockfish", scientific_name = "Sebastes pinniger",
  common_name = "British Columbia Canary Rockfish", area = "3CD; 5ABCDE (excluding 4B)",
  region = "British Columbia", ocean = "Northeast Pacific",
  notes = "Canadian-managed catalogue exception: no matching stock in pinned Charbonneau Master/PLOS metadata. One coastwide assessment; sexes and sensitivity runs are not extra cases.")
assessment <- pacific_database_row("assessments", assessment_id = id, stock_id = stock_id,
  assessment_year = 2022, terminal_year = 2022, estimate_terminal_year = 2023,
  assessment_type = "full", model_family = "Stock Synthesis", model_version = "Run24/24.01, SS3.30.18",
  is_current = TRUE, is_applied = TRUE, framework_year = 2022,
  assessment_url = report, framework_url = report, data_url = native, model_url = native,
  repository_url = "https://github.com/pbs-software/pbs-synth",
  inputs_status = "partial", outputs_status = "partial", assumptions_status = "partial",
  notes = "Official detailed 2022 assessment published 2023. Native fleet/sex observations, fixed biology, source configuration and 500-draw annual female SSB subset recovered; source-estimated constant M has native 90% intervals. Posterior N/F/recruitment and full ageing-error transcription missing. Newest detailed assessment located; no output used as an observation.")
append_pacific_case(stock, assessment, do.call(rbind, assumptions), do.call(rbind, inputs), do.call(rbind, outputs))
