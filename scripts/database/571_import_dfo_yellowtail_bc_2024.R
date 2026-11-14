# Run from the SAIO root. Omit --write to validate and assemble the source rows.
source("scripts/database/pacific_tables.R")
source("scripts/database/pacific_ss.R")
source("scripts/database/candidate_register_io.R")

id <- "dfo_yellowtail_bc_2024"
stock_id <- "dfo_yellowtail_bc"
report_url <- "https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41294804.pdf"
native_url <- paste0("https://github.com/pbs-software/pbs-synth/tree/",
  "16f1d4368ad7d3e854219ca1c2d9d6353252c861/models/input/2024/YTR/BC/Base/B1.R02v2/02.01")
cache <- file.path("source_cache", id)
manifest <- read.csv(file.path("provenance", id, "sources.csv"),
  stringsAsFactors = FALSE, na.strings = "")
paths <- setNames(file.path(cache, manifest$file), manifest$file)
downloaded <- manifest$origin == "public"
stopifnot(!anyDuplicated(manifest$file), all(file.exists(paths)),
  all(unname(tools::md5sum(paths[downloaded])) == manifest$md5[downloaded]))

dat <- r4ss::SS_readdat(paths[["native/data.02.01.ss"]], verbose = FALSE)
ctl <- r4ss::SS_readctl(paths[["native/control.02.01.ss"]], datlist = dat, verbose = FALSE)
ages <- 0:45
years <- 1935:2024
fleet <- "TRAWL_FISHERY_BC"
surveys <- dat$fleetnames[-1L]
sexes <- c("female", "male")
stopifnot(dat$styr == min(years), dat$endyr == max(years),
  dat$Nages == max(ages), dat$Nsexes == 2L, dat$N_areas == 1L, dat$nseas == 1L,
  dat$Nfleets == 7L, dat$spawn_month == 1L, dat$fleetnames[1L] == fleet,
  identical(as.integer(dat$agebin_vector), ages[-1L]),
  all(dat$agecomp$Gender == 3L), all(dat$agecomp$Lbin_lo == -1),
  all(dat$agecomp$Lbin_hi == -1),
  identical(as.integer(table(dat$agecomp$FltSvy)), c(38L, 11L, 7L, 6L)),
  all(dat$CPUE$index %in% 2:7), all(dat$CPUEinfo$Units == 1L),
  ctl$F_Method == 3L, ctl$maturity_option == 3L, ctl$fecundity_option == 1L,
  all(ctl$MG_parms$PHASE[grepl("L_at_|VonBert_|CV_|Wtlen_", rownames(ctl$MG_parms))] < 0))

input <- function(type, measure, basis, value, unit, year = NA_integer_, ...) {
  pacific_database_row("inputs", assessment_id = id, type = type, measure = measure,
    basis = basis, value = value, unit = unit, year = year, region = "BC coast",
    year_basis = ifelse(is.na(year), "", "calendar_year"), ...)
}

catch <- dat$catch[dat$catch$year %in% years, ]
index <- dat$CPUE
stopifnot(identical(as.integer(catch$year), years), all(catch$fleet == 1L),
  all(catch$catch > 0), all(catch$catch_se == .01),
  catch$catch[catch$year == 2024] == catch$catch[catch$year == 2023],
  nrow(index) == 57L, all(index$obs > 0 & index$se_log > 0),
  !anyDuplicated(index[c("index", "year", "seas")]))
inputs <- list(
  input("catch", "total_biomass", "biomass", catch$catch, "t", catch$year,
    fleet = fleet, sex = "combined", source_type = "native_model",
    source_reference = paste(native_url, "data.02.01.ss, catch block"),
    notes = "Native pooled landings and releases. The 2024 input repeats 2023 provisionally. Initial equilibrium catch is a model setting."),
  input("catch", "log_catch_sd", "log_scale", catch$catch_se, "log SD", catch$year,
    fleet = fleet, sex = "combined", source_type = "native_model",
    source_reference = paste(native_url, "data.02.01.ss, catch block"),
    notes = "Native catch error input on the log scale."),
  input("index", "total_biomass", "biomass", index$obs, "t", index$year,
    survey = dat$fleetnames[index$index], sex = "combined",
    sampling_time = (index$seas - 1) / 12, source_type = "native_model",
    source_reference = paste(native_url, "data.02.01.ss, survey abundance block"),
    notes = paste("Design-based total biomass. Source observation month", index$seas)),
  input("index", "log_index_sd", "log_scale", index$se_log, "log SD", index$year,
    survey = dat$fleetnames[index$index], sex = "combined",
    sampling_time = (index$seas - 1) / 12, source_type = "native_model",
    source_reference = paste(native_url, "data.02.01.ss, survey abundance block"),
    notes = "Supplied aggregate-index log SD. The control uses zero additional survey CV."),
  pacific_ss_compositions(dat, "age", id, paste(native_url, "data.02.01.ss, age compositions"),
    "BC coast")
)
error_keys <- seq_len(dat$N_ageerror_definitions)
for (key in error_keys) {
  inputs[[length(inputs) + 1L]] <- input("biology", "ageing_error_sd", "age_error_sd",
    as.numeric(dat$ageerror[2L * key, ]), "years", age = ages, age_error = key,
    source_type = "native_model",
    source_reference = paste(native_url, "data.02.01.ss, ageing-error definition", key),
    notes = "SD by true-age index. The associated means and any sentinel remain in the pinned input.")
}

# The executable evaluates the fixed growth and weight-length parameters and the
# supplied maturity schedule. Keep these schedules distinct from observed weights.
wt <- r4ss::SS_readwtatage(paths[["native_reference/wtatage.ss_new"]])
weight_ref <- "Reproduced SS3 3.30.22.1 B1.R02v2/02.01, wtatage.ss_new"
for (s in seq_along(sexes)) {
  for (f in c(0L, -1L, -2L, seq_len(dat$Nfleets))) {
    if (f == -2L && s == 2L) next
    w <- wt[wt$Sex == s & wt$Fleet == f & wt$Yr %in% years, as.character(ages)]
    stopifnot(nrow(w) == length(years), all(apply(w, 2, function(z) diff(range(z))) == 0))
    type <- if (f == -2L) "biology" else if (f == 1L) "catch_weight" else "weight"
    measure <- if (f == -2L) "maturity_fecundity_at_age" else "weight_at_age"
    inputs[[length(inputs) + 1L]] <- input(type, measure, "kg_per_fish", as.numeric(w[1L, ]),
      "kg/fish", age = ages, sex = sexes[s], fleet = if (f == 1L) fleet else "",
      survey = if (f > 1L) dat$fleetnames[f] else "",
      season = if (f == 0L) "begin_year" else if (f == -2L) "spawning" else "mid_year",
      source_type = "reconstructed_source_input", source_reference = weight_ref,
      transformation = "Evaluate fixed source growth, length variation, weight and maturity in the matching executable.",
      notes = if (f == -2L) {
        "Female effective reproductive weight. Fecundity alpha=1 and beta=0. The executable zeros ages 0-8."
      } else {
        "Constant generated source weight schedule. No empirical weight-at-age file was supplied."
      })
  }
}
maturity <- as.numeric(ctl$Age_Maturity)
stopifnot(length(maturity) == length(ages), all(maturity >= 0 & maturity <= 1))
inputs[[length(inputs) + 1L]] <- input("maturity", "maturity_at_age", "proportion",
  maturity, "proportion", age = ages, sex = "female", season = "spawning", sampling_time = 0,
  source_type = "native_model", source_reference = paste(native_url, "control.02.01.ss, Age_Maturity"),
  notes = "Original maturity vector. The separately stored reproductive weight uses the executable's age-9 cutoff.")
inputs <- do.call(rbind, inputs)

# Import the reproduced point estimate and keep public posterior SSB distinct.
report <- paths[["native_reference/Report.sso"]]
header <- readLines(report, n = 24L, warn = FALSE)
gradient <- as.numeric(sub(".*: ([^ ]+) .*", "\\1", grep("^Convergence_Level:", header, value = TRUE)))
objective <- as.numeric(sub(".*: ", "", grep("^total_LogL:", header, value = TRUE)))
stopifnot(startsWith(header[1L], "#V3.30.22.1;"),
  "Data_File: data.02.01.ss" %in% header, "Control_File: control.02.01.ss" %in% header,
  length(gradient) == 1L, is.finite(gradient), gradient < 1e-4,
  length(objective) == 1L, abs(objective - 384.673) < .01)
n <- pacific_ss_section(report, "NUMBERS_AT_AGE report:")
n <- n[n$Yr %in% years & n$`Beg/Mid` == "B" & n$Era == "TIME", ]
f <- pacific_ss_section(report, "F_AT_AGE report:")
f <- f[f$Yr %in% years & f$Era == "TIME", ]
time <- pacific_ss_section(report, "TIME_SERIES report:")
ssb_2025 <- time$SpawnBio[time$Yr == 2025L & time$Era == "FORE"]
time <- time[time$Yr %in% years & time$Era == "TIME", ]
check_states <- function(x) {
  stopifnot(nrow(x) == 2L * length(years), setequal(x$Yr, years),
    setequal(x$Sex, 1:2), all(x$Area == 1L & x$Seas == 1L),
    all(x$Morph == x$Sex), !anyDuplicated(x[c("Yr", "Sex")]))
}
check_states(n)
check_states(f)
stopifnot(all(f$Fleet == 1L), identical(as.integer(time$Yr), years),
  all(time$Area == 1L & time$Seas == 1L),
  length(ssb_2025) == 1L, abs(ssb_2025 - 19093) < 1)
recr <- rowsum(n[["0"]], n$Yr)
abundance <- rowsum(rowSums(n[as.character(ages)]), n$Yr)
fecundity <- wt[wt$Yr == 1935L & wt$Sex == 1L & wt$Fleet == -2L, as.character(ages)]
female <- n[n$Sex == 1L, ]
female <- female[match(years, female$Yr), ]
stopifnot(max(abs(recr[, 1L] / time$Recruit_0 - 1)) < 1e-5,
  max(abs(drop(as.matrix(female[as.character(ages)]) %*% as.numeric(fecundity)) /
    time$SpawnBio - 1)) < 1e-5)

output <- function(type, measure, value, unit, year = NA_integer_, ...) {
  pacific_database_row("outputs", assessment_id = id, type = type, measure = measure,
    value = value, unit = unit, year = year, region = "BC coast", ...)
}
report_ref <- "Reproduced SS3 3.30.22.1 B1.R02v2/02.01, Report.sso"
state_rows <- function(x, type, measure, unit, season, section, fleet = "") {
  output(type, measure, as.vector(t(as.matrix(x[as.character(ages)]))), unit,
    rep(x$Yr, each = length(ages)), age = rep(ages, times = nrow(x)),
    sex = rep(sexes[x$Sex], each = length(ages)), fleet = fleet, season = season,
    source_type = "derived_source_output", source_reference = paste(report_ref, section),
    notes = "Point estimates from rerunning the pinned inputs. Age 45 is the accumulator age.")
}
outputs <- list(
  state_rows(n, "population", "numbers_at_age", "thousand fish", "begin_year", "NUMBERS_AT_AGE"),
  state_rows(f, "mortality", "fishing_mortality_at_age", "per year", "annual", "F_AT_AGE", fleet),
  output("population", "total_numbers", abundance[, 1L], "thousand fish", years,
    sex = "combined", season = "begin_year", source_type = "derived_source_output",
    source_reference = paste(report_ref, "NUMBERS_AT_AGE"),
    notes = "Sum of both sexes over all 46 ages from the reproduced beginning-year point estimates."),
  output("recruitment", "recruitment", time$Recruit_0, "thousand fish", years, age = 0L,
    sex = "combined", season = "begin_year", source_type = "derived_source_output",
    source_reference = paste(report_ref, "TIME_SERIES, Recruit_0"),
    notes = "Reproduced both-sex age-0 recruitment. Cross-checked against NUMBERS_AT_AGE."),
  output("biomass", "SSB", time$SpawnBio, "t", years,
    sex = "female", season = "begin_year", source_type = "derived_source_output",
    source_reference = paste(report_ref, "TIME_SERIES, SpawnBio"),
    notes = "Reproduced female spawning biomass point estimate.")
)
parameter_lines <- readLines(report, warn = FALSE)
for (s in seq_along(sexes)) {
  label <- paste0("NatM_uniform_", c("Fem", "Mal")[s], "_GP_1")
  line <- grep(paste0("^ *[0-9]+ +", label, " "), parameter_lines, value = TRUE)
  stopifnot(length(line) == 1L)
  m <- as.numeric(strsplit(trimws(line), "[[:space:]]+")[[1L]][3L])
  stopifnot(is.finite(m), m > .02, m < .2)
  outputs[[length(outputs) + 1L]] <- output("mortality", "natural_mortality_at_age",
    m, "per year", rep(years, each = length(ages)),
    age = rep(ages, length(years)), sex = sexes[s], season = "annual",
    source_type = "derived_source_output", source_reference = paste(report_ref, "PARAMETERS,", label),
    notes = "Reproduced point estimate of one constant rate, repeated over the ages and years to which it applies.")
}

posterior_file <- "posterior/yellowtail-bc-mcmc-2025.rds"
draws <- readRDS(paths[[posterior_file]])
stopifnot(length(unique(draws$iter)) == 1944L,
  identical(sort(as.integer(unique(draws$year))), 1935:2025),
  !anyDuplicated(draws[c("iter", "year")]), all(table(draws$iter) == 91L),
  all(is.finite(draws$b) & draws$b > 0))
ssb <- t(vapply(split(draws$b, draws$year), stats::quantile, numeric(3),
  probs = c(.05, .5, .95), type = 7))
stopifnot(ssb["2025", 1L] < ssb_2025, ssb_2025 < ssb["2025", 3L],
  abs(ssb["2025", 2L] / 22300 - 1) < .002)
outputs[[length(outputs) + 1L]] <- output("biomass", "spawning_biomass_posterior", ssb[, 2L], "t",
  as.integer(rownames(ssb)), sex = "female", season = "begin_year",
  lwr = ssb[, 1L], upr = ssb[, 3L], source_type = "derived_source_output",
  source_reference = manifest$url[match(posterior_file, manifest$file)],
  notes = paste("Female spawning biomass posterior median and 90% equal-tail interval,",
    "computed from the public 1,944 complete trajectories. The public file omits",
    "56 draws with non-finite MSY-based quantities from the 2,000 official draws."))
outputs[[length(outputs) + 1L]] <- output("biomass", "published_terminal_SSB", 22300, "t",
  2025L, sex = "female", season = "begin_year", lwr = 13163, upr = 40388,
  source_type = "official_table", source_reference = paste(report_url, "Table 2"),
  notes = "Official beginning-2025 SSB median and 90% interval from all 2,000 posterior draws.")
outputs <- do.call(rbind, outputs)

assume <- function(component, setting, value, ...) {
  pacific_database_row("assumptions", assessment_id = id, component = component,
    setting = setting, value = value, region = "BC coast",
    source_reference = paste(native_url, report_url), ...)
}
assumptions <- list(
  assume("assessment", "official_model", "Coastwide B1.R02v2/02.01, SS3 3.30.22.1. Full 2024 assessment; advice in CSAS 2025/026."),
  assume("population", "dimensions", "1935-2024, ages 0-45+, two sexes and one area 3CD5ABCDE excluding 4B. One annual season and two growth subseasons."),
  assume("population", "initial_conditions", "Unfished equilibrium catches set to zero. Initial older ages include early recruitment deviations from 1920."),
  assume("recruitment", "process", "Beverton-Holt with estimated log R0 and steepness and fixed log-recruitment SD 0.9. Main deviations 1935-2015 with early and late deviations and a bias-adjustment ramp. Female recruitment fraction 0.5."),
  assume("N", "process", "Age advancement from natural and fishing mortality, with a plus group at age 45. No independent older-age process deviations."),
  assume("F", "process", "F_Method=3, continuous F with hybrid catch solution. The official annual F reporting setting is biomass exploitation; instantaneous F is separately available at age.", fleet = fleet),
  assume("F", "selectivity", "Sex-specific age double-normal with fixed descending width yielding a flat older-age plateau. The base run uses a single combined trawl-dominated fishery.", fleet = fleet),
  assume("M", "process", "Estimate constant rates by sex, with normal prior mean 0.08, SD 0.024, and parameter bounds 0.02-0.20 per year."),
  assume("catch", "observation_model", "Pooled catch biomass in tonnes with supplied log SD 0.01. Active joint-sex age samples in 38 years spanning 1979-2018.", fleet = fleet),
  assume("catch", "provisional_terminal_catch", "The 2024 assessment input repeats the 2023 catch because 2024 catches were incomplete.", fleet = fleet),
  assume("biology", "spawning_time", "January 1, fraction zero. Female effective reproductive weight starts at age 9 in the executable."),
  assume("biology", "weights", "Fixed sex-specific von Bertalanffy growth, length variation and weight-length parameters. No empirical weight-at-age input. Generated beginning-season and fleet weights are retained separately."),
  assume("index", "observation_model", "Six fishery-independent survey biomass series and no commercial CPUE. Supplied log SDs and month-based sampling times retained."),
  assume("q", "process", "One floated scalar catchability per survey with fixed-in-time age selectivity. Age curve parameters are fitted where specified and fixed for index-only series."),
  assume("source", "output_conventions", "SSB, N, recruitment, F and M come from the reproduced base point estimate. SSB posterior summaries from the public 1,944-draw subset and the official terminal table are stored separately.")
)
adjust <- ctl$Variance_adjustment_list
for (i in which(adjust$Factor == 5L)) {
  j <- adjust$Fleet[i]
  series <- dat$fleetnames[j]
  assumptions[[length(assumptions) + 1L]] <- assume(if (j == 1L) "catch" else "index",
    "age_composition_multiplier", sprintf("%.15g", adjust$Value[i]),
    fleet = if (j == 1L) series else "", survey = if (j == 1L) "" else series,
    notes = "Source control factor 5 multiplies the reported row sample size in the multinomial likelihood.")
}

stock <- pacific_database_row("stocks", stock_id = stock_id, authority = "DFO",
  authority_stock_id = "Coastwide Yellowtail Rockfish", scientific_name = "Sebastes flavidus",
  common_name = "British Columbia Yellowtail Rockfish", area = "3CD; 5ABCDE (excluding 4B)",
  region = "British Columbia", ocean = "Northeast Pacific",
  notes = "Canadian coastwide unit from DFO 2025/026, distinct from the US northern Yellowtail assessment unit.")
assessment <- pacific_database_row("assessments", assessment_id = id, stock_id = stock_id,
  assessment_year = 2024L, terminal_year = 2024L, estimate_terminal_year = 2025L,
  assessment_type = "full", model_family = "Stock Synthesis", model_version = "B1.R02v2/02.01, SS3 3.30.22.1",
  is_current = TRUE, is_applied = TRUE, framework_year = 2024L,
  assessment_url = report_url, framework_url = report_url, data_url = native_url, model_url = native_url,
  repository_url = "https://github.com/pbs-software/pbs-synth",
  inputs_status = "partial", outputs_status = "partial", assumptions_status = "partial",
  notes = paste("Official 2024 base inputs, fixed-source weight evaluations and historical MPD states.",
    "Public posterior SSB subset retained. Full joint posterior N, recruitment and F have not been recovered.",
    "Catch and survey compositions remain separate from aggregate biomass observations."))

assumptions <- do.call(rbind, assumptions)
yellowtail_case <- list(stocks = stock, assessments = assessment, assumptions = assumptions,
  inputs = inputs, outputs = outputs)
if ("--write" %in% commandArgs(trailingOnly = TRUE)) {
  candidate_path <- "discovery/candidates.csv"
  candidate_id <- "DFO:Pacific:Yellowtail Rockfish - British Columbia coastwide"
  candidates <- read.csv(candidate_path, stringsAsFactors = FALSE, na.strings = c("", "NA"))
  row <- which(candidates$candidate_id == candidate_id)
  inventory_path <- "discovery/inventory_units.csv"
  inventory <- read.csv(inventory_path, stringsAsFactors = FALSE, na.strings = c("", "NA"))
  unit_key <- paste0("candidate:", candidates$candidate_unit_id[row])
  unit_row <- which(inventory$unit_key == unit_key)
  stopifnot(length(row) == 1L, candidates$import_status[row] == "not_started")
  stopifnot(length(unit_row) == 1L, inventory$import_status[unit_row] == "not_started")
  do.call(append_pacific_case, yellowtail_case)
  candidates$matched_stock_id[row] <- stock_id
  candidates$eligibility[row] <- "eligible"
  candidates$import_status[row] <- "partial"
  candidates$catch_age_evidence[row] <- "Native pooled biomass and 38 annual joint-sex age samples; separate native input streams retained."
  candidates$survey_age_evidence[row] <- "Six biomass indices; three surveys have paired age samples: NMFS Triennial, Queen Charlotte Sound and west coast Vancouver Island."
  candidates$weights_evidence[row] <- "Fixed source biological parameters evaluated in native SS3 and retained as reconstructed schedules."
  candidates$maturity_evidence[row] <- "Female age ogive supplied. Effective reproductive weight begins at age 9."
  candidates$mortality_evidence[row] <- "Sex-specific estimated constants with native prior settings and reproduced point estimates."
  candidates$timing_evidence[row] <- "January spawning. Native index month retained and sampling fraction calculated as (month - 1)/12."
  candidates$output_evidence[row] <- "Public annual posterior female SSB; reproduced historical N, recruitment and instantaneous F at age from pinned 02.01 native inputs."
  candidates$decision_reason[row] <- "Public native base inputs, fixed source biology, posterior SSB and reproduced historical states support a partial source import."
  candidates$review_date[row] <- format(Sys.Date())
  replace_candidate_register_row(candidate_path, row, candidates[row, , drop = FALSE], candidate_id)
  inventory$matched_stock_id[unit_row] <- stock_id
  inventory$eligibility[unit_row] <- "eligible"
  inventory$import_status[unit_row] <- "partial"
  replace_csv_register_row(inventory_path, unit_row, inventory[unit_row, , drop = FALSE],
    "unit_key", unit_key)
}
cat("Verified Yellowtail source rows:", nrow(inputs), "inputs,", nrow(outputs),
  "outputs and", nrow(assumptions), "assumptions.\n")
