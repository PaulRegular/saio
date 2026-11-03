source("scripts/database/pacific_tables.R")
source("scripts/database/pacific_sources.R")
source("scripts/database/bc_petrale_posterior.R")

id <- "dfo_petrale_bc_2024"
stock_id <- "dfo_petrale_bc"
report <- "https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/4127961x.pdf"
revision <- "7f1c59b8cc3895a3477204ac16da6cf15e2466c6"
repository <- paste0("https://github.com/pbs-assess/gftrends/tree/", revision)
posterior_url <- paste0("https://raw.githubusercontent.com/pbs-assess/gftrends/", revision,
  "/data-raw/petrale-sole-bc-mcmc-2024.rds")
cache_pacific_source(stock_id, report, "science_advisory_report_2025_002.pdf")
posterior_file <- cache_pacific_source(stock_id, posterior_url, "ssb_posterior_2024.rds", revision)
cache_pacific_source(stock_id, paste0("https://raw.githubusercontent.com/pbs-assess/gftrends/",
  revision, "/data-raw/process-raw-data.R"), "gftrends_process_raw_data.R", revision)

catalogue_revision <- "7e4daca3cbfc14ce7fa0b28ed824eebe7113249b"
for (file in c("Master.csv", "PLOS_2026_analysis/metadata_no_age_corection.csv")) {
  path <- cache_pacific_source(stock_id, paste0(
    "https://raw.githubusercontent.com/JulieCharbonneau/Age-structured-marine-fish-database/",
    catalogue_revision, "/", file), paste0("catalogue/", basename(file)), catalogue_revision)
  stopifnot(!any(grepl("petrale|Eopsetta|jordani", readLines(path, warn = FALSE), ignore.case = TRUE)))
}

draws <- readRDS(posterior_file)
ssb <- summarize_bc_petrale_posterior(draws)
stopifnot(nrow(draws) == 174000L, length(unique(draws$iter)) == 2000L,
  identical(sort(unique(draws$species)), "petrale sole"),
  identical(sort(unique(draws$region)), "BC"),
  all(abs(draws$lrp - .4 * draws$bmsy) < 1e-8),
  all(abs(draws$usr - .8 * draws$bmsy) < 1e-8))

output <- function(measure, value, year, lwr, upr, reference, source_type, notes,
                   type = "biomass", unit = "t", sex = "female") {
  pacific_database_row("outputs", assessment_id = id, type = type, measure = measure,
    value = value, year = year, lwr = lwr, upr = upr, sex = sex, region = "BC coast",
    unit = unit, source_type = source_type, source_reference = reference, notes = notes)
}
outputs <- do.call(rbind, list(
  output("SSB", ssb$value, ssb$year, ssb$lwr, ssb$upr, posterior_url, "derived_source_output",
    paste("Female spawning biomass in tonnes. Median and equal-tail 95% credible limits (R quantile type 7)",
      "of 2000 complete posterior trajectories from the authors' combined-M output, downsampled by gftrends.",
      "Not the exact full-ensemble published quantiles; no SE inferred. 2024 is the beginning-year boundary",
      "after fitted catches through 2023, not an observed catch year. Original medium/low/high mixture",
      "sample membership is absent from this file; no additional weighting or scaling applied.")),
  output("published_terminal_SSB", 17330, 2024, 10830, 27977, paste(report, "Table 1, p. 6"),
    "official_table", "Official full-ensemble B2024: posterior median and equal-tail 95% credible limits. Retained separately from the public 2000-draw summaries; no rescaling to force agreement."),
  output("Bmsy", 5704, 2024, 2793, 8323, paste(report, "Table 1, p. 6"), "official_table",
    "Official full-ensemble reference point: posterior median and 95% credible limits. Year identifies the assessment boundary, not a time-varying BMSY series."),
  output("Fmsy", .092, 2024, .067, .171, paste(report, "Table 1, p. 6"), "official_table",
    "Official full-ensemble reference point: posterior median and 95% credible limits. Not F-at-age or an age-averaged Fbar; year identifies the assessment boundary.",
    type = "mortality", unit = "per year", sex = "")
))

# Reported component scalars are distinct from recovered year-age M surfaces.
inputs <- pacific_database_row("inputs", assessment_id = id, type = "M",
  measure = c("fixed_mortality_medium", "fixed_mortality_low", "fixed_mortality_high"),
  basis = "per_year", value = c(.154, .124, .184), unit = "per year", region = "BC coast",
  source_type = "official_document", source_reference = paste(report, "Assessment, pp. 3-4"),
  notes = c(
    "Reported baseM component scalar; 50% weight in official ensemble. Original sex/age parameter arrays not recovered; not an input age grid or a pooled ensemble mean M.",
    "Reported low-M component scalar; 25% weight in official ensemble. Original sex/age parameter arrays not recovered; not an input age grid.",
    "Reported high-M component scalar; 25% weight in official ensemble. Original sex/age parameter arrays not recovered; not an input age grid."
  ))
assume <- function(component, setting, value, survey = "", reference = report, notes = "") {
  pacific_database_row("assumptions", assessment_id = id, component = component,
    setting = setting, value = value, survey = survey, region = "BC coast",
    source_reference = reference, notes = notes)
}
assumptions <- list(
  assume("assessment", "official_model", "2024 two-sex coastwide Stock Synthesis ensemble used for advice; Science Advisory Report 2025/002 published February 2025."),
  assume("assessment", "record_scope", "Summary and public posterior-output record; not a recovered detailed production run. Native inputs and final detailed research document not recovered; is_current=FALSE under the detailed-record selection rule."),
  assume("population", "modeled_years", "1938-2023"),
  assume("population", "age_range", "unknown", notes = "Source population age grid and terminal plus group were not recovered; hard-coded script column positions are not evidence of model ages."),
  assume("population", "plus_group", "unknown"),
  assume("population", "sex_structure", "Female and male; one coastwide population in 3CD and 5ABCDE, excluding Strait of Georgia 4B."),
  assume("population", "initial_conditions", "Unfished equilibrium in 1938, the first year of recorded catches; exact initial-state parameterization unresolved."),
  assume("N", "process", "unknown", notes = "Exact cohort recursion, plus-group convention and initial-age treatment require the production configuration."),
  assume("recruitment", "recruitment_age", "unknown"),
  assume("recruitment", "stock_recruit", "Steepness estimated with an informative beta prior, mean .85 and CV 10%, developed for rock sole. Exact recruitment equation, deviations and bias adjustment require native configuration."),
  assume("M", "process", "Fixed M within each component. Medium/baseM .154, low .124 and high .184 per year; posterior mixture weights .50/.25/.25. Do not average M scalars into a single official model."),
  assume("M", "parameter_activation", "Initial attempts to estimate M were unsuccessful; the advice ensemble fixes M. It is not source-estimated M."),
  assume("F", "selectivity", "Asymptotic, time-invariant fishery selectivity forced from a double-normal parameterization; male parameters offset from female. Exact active phases, normalization and fishing-intensity treatment unresolved."),
  assume("catch", "fleets", "Multi-species groundfish trawl removals including low discards, 1938-2023. Numerical removals, native fleet codes and retained/discard representation not recovered."),
  assume("catch", "age_compositions", "Commercial ages available 2004-2013, expanded to stock-wide proportions caught at age using the Redstripe Rockfish method (Starr and Haigh 2021). Multinomial likelihood with bootstrapped input sample sizes. Numerical arrays, native composition basis, sex normalization and weights not recovered."),
  assume("biology", "growth", "Von Bertalanffy length-at-age and log-weight versus log-length relationship. Numerical coefficients, sex sharing, growth variability and weight-at-age not recovered."),
  assume("biology", "maturity", "Logistic maturity-at-age; numerical parameters or age vector not recovered."),
  assume("biology", "spawning_time", "unknown", notes = "January/beginning-year female spawning biomass is reported; the exact modeled spawning month and mortality fractions require production files."),
  assume("source", "estimate_convention", "Official advice uses medians and 95% credible intervals of a 50/25/25 M mixture. Public gftrends object is a 2000-draw subset with SSB and BMSY only; published terminal quantiles retained separately.", reference = paste(report, ";", repository)),
  assume("source", "missing_material", "Native catch totals and fishery ages; all three survey totals and ages; sample sizes, timing and q/SD settings; weight/maturity; model ages and plus group; final production configuration; N/F-at-age and recruitment outputs."),
  assume("source", "posterior_mixture_evidence", "Author correspondence in hdiAnalysis documents intended 14000 medium-M and 7000 each low/high samples, with 5 samples missing BMSY; packaged relative-biomass object has 27995 draws for 1938-2023. This corroborates mixture intent, not component membership of the gftrends subset.",
    reference = "https://github.com/andrew-edwards/hdiAnalysis/blob/0d0e0c0910fddaf1636b4471299acd4e409d6ef3/report/results-petrale-sole.Rmd")
)
for (survey in c("QCS_SYNOPTIC", "HS_SYNOPTIC", "WCVI_SYNOPTIC")) {
  assumptions <- c(assumptions, list(
    assume("index", "observation_model", "Separate geostatistical biomass index, 2003-2023; numerical input and supplied precision not recovered.", survey),
    assume("index", "age_compositions", "Survey age compositions, 2004-2018/2019 depending on survey; multinomial likelihood with bootstrap sample sizes. Native composition basis, sex normalization, exact years, age cells and input counts not recovered.", survey),
    assume("index", "sampling_time", "unknown", survey, notes = "Model timing not recovered; no .5 default or inferred calendar precision supplied."),
    assume("q", "selectivity", "Asymptotic, time-invariant age selectivity, distinct for each survey, with male offsets; exact q parameterization and sharing unresolved.", survey)
  ))
}

stock <- pacific_database_row("stocks", stock_id = stock_id, authority = "DFO",
  authority_stock_id = "Coastwide petrale sole", scientific_name = "Eopsetta jordani",
  common_name = "British Columbia petrale sole", area = "3CD; 5ABCDE (excluding 4B)",
  region = "British Columbia", ocean = "Northeast Pacific",
  notes = "Canadian-managed catalogue exception: no match in the pinned Charbonneau Master or PLOS metadata. One coastwide stock, not separate M-scenario cases.")
assessment <- pacific_database_row("assessments", assessment_id = id, stock_id = stock_id,
  assessment_year = 2024, terminal_year = 2023, estimate_terminal_year = 2024,
  assessment_type = "full", model_family = "Stock Synthesis", model_version = "unknown",
  is_current = FALSE, is_applied = TRUE, framework_year = 2024, assessment_url = report,
  repository_url = "https://github.com/pbs-assess/petrale",
  assumptions_status = "partial", inputs_status = "partial", outputs_status = "partial",
  notes = paste("Official 2024 advice ensemble, SAR published 2025. Summary/public-posterior record only:",
    "not marked current detailed because original observations, biology and final configuration are missing.",
    "Repository contains appendix environmental scripts, not the native fitted model. Public SSB draws",
    "through 2024 retained with subset quantiles and separate published terminal values; no fitted states used as inputs."))
append_pacific_case(stock, assessment, do.call(rbind, assumptions), inputs, outputs)
