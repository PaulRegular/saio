root <- "."
db <- file.path(root, "database")
assessment_id <- "dfo_northern_mackerel_2025"
stock_id <- "ck_dfo_qc_scombrus_4t"
cache <- file.path(root, "source_cache", "dfo_northern_mackerel_2025")
repo <- file.path(cache, "model_repository")
data_dir <- file.path(repo, "data", "2025")
csv_dir <- file.path(repo, "csv", "2025")
model_revision <- "435d10bcb6ee64e0d94c77f6854e0d37f53e4b8b"
ccam_revision <- "1bcb06473343c13ebeebecdb54acd905220aeb61"
model_base <- paste0("https://github.com/iml-assess/mackerel_assessment/blob/",
  model_revision)
repository_url <- paste0("https://github.com/iml-assess/mackerel_assessment/tree/",
  model_revision)
ccam_base <- paste0("https://github.com/iml-mackerel/CCAM/blob/", ccam_revision)

abort <- function(...) stop(paste0(...), call. = FALSE)
assessment_url <- "https://publications.gc.ca/site/eng/9.964308/publication.html"
framework_url <- "https://www.dfo-mpo.gc.ca/csas-sccs/Publications/ResDocs-DocRech/2025/2025_054-eng.pdf"
tep_units_url <- "https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41219132.pdf"

required <- c(
  file.path(csv_dir, c("Intrants_2025.csv", "Intrants_at_age_2025.csv",
    "N_sd.csv", "f.csv", "ssb.csv", "rec.csv", "tsb.csv", "out.csv",
    "catch.limits.csv")),
  file.path(data_dir, c("cn.dat", "ct.dat", "ctUSA.dat", "ctUnaccounted.dat",
    "mo.dat", "sw.dat", "sw0.dat", "cw.dat", "nm.dat", "pf.dat", "pm.dat",
    "propFemale.dat", "fec.dat", "tep.dat"))
)
if (any(!file.exists(required))) abort("Required pinned 2025 assessment files are missing.")

model_years <- 1969:2025
source_years <- 1968:2025
ages <- 1:10

read_source_csv <- function(name) read.csv(file.path(csv_dir, name),
  stringsAsFactors = FALSE, check.names = FALSE, na.strings = c("", "NA"))

read_ices <- function(name, columns) {
  path <- file.path(data_dir, name)
  lines <- readLines(path, warn = FALSE, encoding = "UTF-8")
  if (length(lines) < 6L) abort("Malformed ICES file: ", path)
  x <- read.table(text = paste(lines[-seq_len(5L)], collapse = "\n"),
    header = FALSE, fill = FALSE, na.strings = c("NA", "-"),
    comment.char = "", stringsAsFactors = FALSE, check.names = FALSE)
  if (nrow(x) != length(source_years) || ncol(x) != columns) {
    abort("Unexpected dimensions in ", path, ": ", nrow(x), " x ", ncol(x))
  }
  as.matrix(x)
}

inputs_old <- read.csv(file.path(db, "inputs.csv"), stringsAsFactors = FALSE,
  check.names = FALSE, na.strings = c("", "NA"))
input_columns <- names(inputs_old)
empty_inputs <- function(n) {
  numeric_columns <- c("year", "age", "value", "sampling_time",
    "length_bin_lower", "length_bin_upper", "sample_size")
  x <- as.data.frame(lapply(input_columns, function(column) {
    if (column %in% numeric_columns) rep(NA_real_, n) else rep("", n)
  }), stringsAsFactors = FALSE, optional = TRUE)
  names(x) <- input_columns
  x$assessment_id <- assessment_id
  x$year_basis <- "calendar_year"
  x
}
input_rows <- function(n, type, measure, basis, unit, source_reference,
                       source_type = "native_model", notes = "",
                       transformation = "", fleet = "", survey = "",
                       season = "", sampling_time = NA_real_) {
  x <- empty_inputs(n)
  x$type <- type
  x$measure <- measure
  x$basis <- basis
  x$unit <- unit
  x$source_reference <- source_reference
  x$source_type <- source_type
  x$notes <- notes
  x$transformation <- transformation
  x$fleet <- fleet
  x$survey <- survey
  x$season <- season
  x$sampling_time <- sampling_time
  x
}
age_rows <- function(year, age, value, type, measure, basis, unit,
                     source_reference, notes = "", source_type = "native_model",
                     transformation = "") {
  if (length(year) != length(age) || length(year) != length(value) ||
      any(!is.finite(year)) || any(!is.finite(age)) || any(!is.finite(value))) {
    abort("Invalid values in age surface ", measure, ".")
  }
  x <- input_rows(length(value), type, measure, basis, unit, source_reference,
    source_type, notes, transformation)
  x$year <- year
  x$age <- age
  x$value <- value
  x
}
matrix_rows <- function(name, type, measure, basis, unit, notes = "") {
  z <- read_ices(name, length(ages))[-1L, , drop = FALSE]
  age_rows(
    year = rep(model_years, each = length(ages)),
    age = rep(ages, times = length(model_years)),
    value = as.vector(t(z)),
    type = type, measure = measure, basis = basis, unit = unit,
    source_reference = paste0("model_repository/data/2025/", name),
    notes = paste("Annual source-model surface; age 10 is the 10+ group.", notes)
  )
}

# Source inputs
age_data <- read_source_csv("Intrants_at_age_2025.csv")
if (nrow(age_data) != length(model_years) * length(ages) ||
    !setequal(as.numeric(age_data$year), model_years) ||
    !setequal(as.numeric(age_data$age), ages) ||
    anyDuplicated(paste(age_data$year, age_data$age))) {
  abort("Unexpected year-age grid in Intrants_at_age_2025.csv.")
}
notes_plus <- "Annual source-model surface for ages 1-10+; age 10 is the plus group. The 1968 input row is excluded from the fitted years."
inputs <- list(
  age_rows(as.numeric(age_data$year), as.numeric(age_data$age),
    as.numeric(age_data$caa_1000), "catch", "numbers_at_age", "numbers",
    "thousand fish", "model_repository/data/2025/cn.dat; csv/2025/Intrants_at_age_2025.csv",
    "Catch-at-age input for the source composition likelihood; not a tinyAM fit-ready likelihood equivalent. Age 10 is 10+."),
  age_rows(as.numeric(age_data$year), as.numeric(age_data$age),
    as.numeric(age_data$prop_mature), "maturity", "maturity_at_age", "proportion",
    "proportion mature", "model_repository/data/2025/mo.dat; csv/2025/Intrants_at_age_2025.csv",
    notes_plus),
  age_rows(as.numeric(age_data$year), as.numeric(age_data$age),
    as.numeric(age_data$stock_weight_kg), "weight", "weight_at_age", "kg_per_fish",
    "kg/fish", "model_repository/data/2025/sw.dat; csv/2025/Intrants_at_age_2025.csv",
    notes_plus),
  age_rows(as.numeric(age_data$year), as.numeric(age_data$age),
    as.numeric(age_data$catch_weight_kg), "catch_weight", "weight_at_age", "kg_per_fish",
    "kg/fish", "model_repository/data/2025/cw.dat; csv/2025/Intrants_at_age_2025.csv",
    notes_plus),
  age_rows(as.numeric(age_data$year), as.numeric(age_data$age),
    as.numeric(age_data$fecundity), "biology", "fecundity_at_age", "egg_count",
    "eggs per female", "model_repository/data/2025/fec.dat; csv/2025/Intrants_at_age_2025.csv",
    "Annual fecundity-at-age used in the source TEP prediction; age 10 is 10+."),
  matrix_rows("sw0.dat", "weight", "start_weight_at_age", "kg_per_fish", "kg/fish",
    "January 1 stock weight, distinct from the annual stock-weight surface."),
  matrix_rows("nm.dat", "M", "natural_mortality_at_age", "per_year", "1/year",
    "Fixed natural mortality supplied to the source model; it is not an estimated M output."),
  matrix_rows("propFemale.dat", "biology", "proportion_female_at_age", "proportion",
    "proportion female", "Female fraction used in the source model's TEP calculation."),
  matrix_rows("pf.dat", "biology", "fraction_F_before_spawning", "proportion",
    "proportion", "Fraction of annual F applied before spawning."),
  matrix_rows("pm.dat", "biology", "fraction_M_before_spawning", "proportion",
    "proportion", "Fraction of annual M applied before spawning.")
)
for (x in inputs) {
  if (nrow(x) == length(model_years) * length(ages) &&
      !setequal(unique(x$year), as.numeric(model_years))) {
    abort("An age input does not cover 1969-2025.")
  }
}

# Total-catch observations and reconstructed likelihood bounds
ct <- read_ices("ct.dat", 2L)[-1L, 1L]
ct_usa <- read_ices("ctUSA.dat", 2L)[-1L, 1L]
ct_unaccounted <- read_ices("ctUnaccounted.dat", 2L)[-1L, 1L]
if (anyNA(c(ct, ct_usa, ct_unaccounted))) abort("Missing total-catch bound components.")
catch_lower <- ct * 1.10 + ct_usa * 0.20
catch_upper <- ct + ct_unaccounted + ct_usa * 0.80
if (any(catch_lower > catch_upper)) abort("Reconstructed catch lower bound exceeds upper bound.")
catch_component <- function(value, measure, fleet, source_reference,
                            notes, source_type = "native_model", transformation = "") {
  x <- input_rows(length(model_years), "catch", measure, "biomass", "t",
    source_reference, source_type, notes, transformation, fleet = fleet)
  x$year <- model_years
  x$value <- as.numeric(value)
  x
}
inputs <- c(inputs, list(
  catch_component(ct, "total_biomass", "Base total catch", "model_repository/data/2025/ct.dat",
    "Base annual catch used to construct the total-catch bounds; not a separate fitted fleet."),
  catch_component(ct_usa, "total_biomass", "U.S. catch component", "model_repository/data/2025/ctUSA.dat",
    "U.S. catch series used only as a component of the combined total-catch bounds."),
  catch_component(ct_unaccounted, "total_biomass", "Unaccounted catch component", "model_repository/data/2025/ctUnaccounted.dat",
    "Unaccounted-catch allowance used only as a component of the combined upper bound."),
  catch_component(catch_lower, "catch_lower_bound", "Total catch likelihood",
    "model_repository/Rscripts/2025/surplus/read_data.R; data/2025/ct.dat; ctUSA.dat",
    "Reconstructed source lower bound: ct * 1.10 + ctUSA * 0.20 tonnes.",
    "reconstructed_source_input"),
  catch_component(catch_upper, "catch_upper_bound", "Total catch likelihood",
    "model_repository/Rscripts/2025/surplus/read_data.R; data/2025/ct.dat; ctUSA.dat; ctUnaccounted.dat",
    "Reconstructed source upper bound: ct + ctUnaccounted + ctUSA * 0.80 tonnes.",
    "reconstructed_source_input")
))

tep <- read_source_csv("Intrants_2025.csv")
tep <- tep[is.finite(tep$TEP_e12), , drop = FALSE]
if (!nrow(tep) || any(!tep$year %in% model_years) || any(tep$TEP_e12 <= 0)) {
  abort("Unexpected total egg production observations.")
}
tep_rows <- input_rows(nrow(tep), "index", "total_egg_production", "egg_count",
  "trillion eggs", "model_repository/data/2025/tep.dat; csv/2025/Intrants_2025.csv",
  notes = "Aggregate total egg production index, not an age-specific abundance index. Years without a survey or usable observation are omitted.",
  transformation = "Retain native trillion-egg values; do not convert to fish numbers. The model script separately multiplies observations by 1e9 for its internal likelihood scale.",
  survey = "Total egg production (TEP)", season = "spring spawning", sampling_time = 0.47)
tep_rows$year <- as.numeric(tep$year)
tep_rows$value <- as.numeric(tep$TEP_e12)
inputs <- c(inputs, list(tep_rows))
inputs <- do.call(rbind, inputs)
inputs <- inputs[order(inputs$year, inputs$type, inputs$measure, inputs$age), , drop = FALSE]

assumption <- function(component, setting, value, source_reference, notes = "") {
  data.frame(assessment_id = assessment_id, component = component,
    fleet = "", survey = "", sex = "", region = "", season = "",
    setting = setting, value = value, source_reference = source_reference,
    notes = notes, stringsAsFactors = FALSE)
}
assumptions <- do.call(rbind, list(
  assumption("population", "model_years", "1969-2025",
    "model_repository/Rscripts/2025/surplus/read_data.R",
    "The source files span 1968-2025; the fit drops the 1968 row from annual inputs."),
  assumption("population", "modeled_ages", "1-10+",
    "model_repository/data/2025/cn.dat; DFO Research Document 2025/054, Figure 2",
    "Age 10 is the 10+ group."),
  assumption("recruitment", "recruitment_age", "1",
    "CCAM_repository/R/tables.R; model_repository/csv/2025/rec.csv",
    "Recruitment is age-1 abundance in the same calendar year."),
  assumption("population", "stock_recruitment_model", "Beverton-Holt",
    "model_repository/Rscripts/2025/surplus/read_data.R",
    "The run script sets stockRecruitmentModelCode = 2."),
  assumption("catch", "total_catch_likelihood", "Censored annual total catch",
    "model_repository/Rscripts/2025/surplus/read_data.R; CCAM_repository/inst/include/obs.hpp",
    "Uses lower and upper bounds reconstructed from Canadian catch, U.S. catch, and an unaccounted-catch allowance."),
  assumption("catch", "catch_at_age_likelihood", "Continuation-ratio logit age composition",
    "CCAM_repository/inst/include/predobs.hpp; model_repository/data/2025/cn.dat",
    "The source model uses catch-at-age as a composition likelihood. tinyAM's direct lognormal catch observation is an approximation."),
  assumption("mortality", "natural_mortality", "Fixed 0.28 per year at ages 1-10+",
    "model_repository/data/2025/nm.dat",
    "The source M surface is constant and supplied, not estimated."),
  assumption("biology", "fraction_f_before_spawning", "0.47 for all modeled years and ages",
    "model_repository/data/2025/pf.dat"),
  assumption("biology", "fraction_m_before_spawning", "0.47 for all modeled years and ages",
    "model_repository/data/2025/pm.dat"),
  assumption("index", "index_definition", "Aggregate total egg production (TEP)",
    "model_repository/data/2025/tep.dat; CCAM_repository/inst/include/predobs.hpp",
    "The predicted index sums abundance, maturity, female fraction and fecundity across ages after mortality to sampling time. The TEP routine adds F only where keySel < 0; this run assigns nonnegative keys 0-4. tinyAM's age-specific index equation cannot represent it."),
  assumption("index", "tep_native_unit", "Trillion eggs",
    paste("DFO Research Document 2022/068 Table S9", tep_units_url,
      "DFO Research Document 2025/054 section 3.3", framework_url,
      "model_repository/csv/2025/Intrants_2025.csv"),
    "The source values match the documented trillion-egg scale. The 2025 run script multiplies raw values by 1e9 for its internal likelihood scale; this is kept separate from the canonical unit."),
  assumption("index", "tep_sampling_time", "0.47",
    "model_repository/Rscripts/2025/surplus/read_data.R",
    "Fraction of year set for the source TEP observation model."),
  assumption("catchability", "selectivity_key_by_age", "0,1,2,3,4,4,4,4,4,4",
    "model_repository/Rscripts/2025/surplus/read_data.R",
    "The source script shares selectivity key 4 across ages 5-10+."),
  assumption("mortality", "Fbar_age_range", "5-10+",
    "model_repository/Rscripts/2025/surplus/read_data.R; csv/2025/out.csv",
    "The source script sets fbarRange = c(5, 10).")
))

outputs_old <- read.csv(file.path(db, "outputs.csv"), stringsAsFactors = FALSE,
  check.names = FALSE, na.strings = c("", "NA"))
output_columns <- names(outputs_old)
empty_outputs <- function(n) {
  numeric_columns <- c("year", "age", "value", "se", "lwr", "upr")
  x <- as.data.frame(lapply(output_columns, function(column) {
    if (column %in% numeric_columns) rep(NA_real_, n) else rep("", n)
  }), stringsAsFactors = FALSE, optional = TRUE)
  names(x) <- output_columns
  x$assessment_id <- assessment_id
  x
}
output_rows <- function(n, type, measure, unit, source_reference,
                        age_group = "", notes = "", source_type = "native_model") {
  x <- empty_outputs(n)
  x$type <- type
  x$measure <- measure
  x$unit <- unit
  x$source_reference <- source_reference
  x$source_type <- source_type
  x$age_group <- age_group
  x$notes <- notes
  x
}
uncertainty_note <- paste(
  "Intervals are the back-transformed estimate +/- 2 asymptotic standard deviations on the log scale, as in CCAM::tableit.ccam.",
  "They are approximate and are not presented as exact 95% confidence intervals."
)

N <- read_source_csv("N_sd.csv")
N$year <- as.numeric(N$year)
N$age <- as.numeric(N$age)
if (nrow(N) != length(model_years) * length(ages) ||
    !setequal(N$year, model_years) || !setequal(N$age, ages) ||
    any(!is.finite(N$Estimate)) || any(!is.finite(N$Low)) || any(!is.finite(N$High))) {
  abort("Unexpected or incomplete fitted N-at-age output.")
}
Nout <- output_rows(nrow(N), "population", "numbers_at_age", "thousand fish",
  "model_repository/csv/2025/N_sd.csv; Rdata/2025/fit.Rdata; CCAM::tableit.ccam",
  notes = paste("Age 10 is 10+.", uncertainty_note))
Nout$year <- N$year
Nout$age <- N$age
Nout$value <- N$Estimate
Nout$lwr <- N$Low
Nout$upr <- N$High

read_age_surface <- function(name) {
  x <- read_source_csv(name)
  names(x)[1L] <- "year"
  x$year <- as.numeric(x$year)
  age_columns <- as.character(ages)
  if (nrow(x) != length(model_years) || !setequal(x$year, model_years) ||
      !all(age_columns %in% names(x))) abort("Unexpected age surface in ", name)
  list(year = rep(x$year, each = length(ages)),
       age = rep(ages, times = length(model_years)),
       value = as.vector(t(as.matrix(x[, age_columns, drop = FALSE]))))
}
F <- read_age_surface("f.csv")
Fout <- output_rows(length(F$value), "mortality", "fishing_mortality_at_age",
  "per year", "model_repository/csv/2025/f.csv; Rdata/2025/fit.Rdata; CCAM::faytable",
  notes = "Age 10 is 10+; point estimates are rounded to 0.01 per year. No uncertainty is available in this export.")
Fout$year <- F$year
Fout$age <- F$age
Fout$value <- F$value

read_annual <- function(name) {
  x <- read_source_csv(name)
  if (!"year" %in% names(x)) names(x)[1L] <- "year"
  x$year <- as.numeric(x$year)
  if (nrow(x) != length(model_years) || !setequal(x$year, model_years)) {
    abort("Unexpected annual output in ", name)
  }
  x
}
ssb <- read_annual("ssb.csv")
SSBout <- output_rows(nrow(ssb), "biomass", "SSB", "t",
  "model_repository/csv/2025/ssb.csv; Rdata/2025/fit.Rdata; CCAM::ssbtable",
  notes = uncertainty_note)
SSBout$year <- ssb$year
SSBout$value <- ssb$Estimate
SSBout$lwr <- ssb$Low
SSBout$upr <- ssb$High

rec <- read_annual("rec.csv")
Rout <- output_rows(nrow(rec), "recruitment", "recruitment", "thousand fish",
  "model_repository/csv/2025/rec.csv; Rdata/2025/fit.Rdata; CCAM::rectable",
  notes = paste("Age-1 recruitment in the same calendar year.", uncertainty_note))
Rout$year <- rec$year
Rout$age <- 1
Rout$value <- rec$Estimate
Rout$lwr <- rec$Low
Rout$upr <- rec$High

tsb <- read_annual("tsb.csv")
TSBout <- output_rows(nrow(tsb), "biomass", "total_biomass", "t",
  "model_repository/csv/2025/tsb.csv; Rdata/2025/fit.Rdata; CCAM::tsbtable",
  notes = uncertainty_note)
TSBout$year <- tsb$year
TSBout$value <- tsb$Estimate
TSBout$lwr <- tsb$Low
TSBout$upr <- tsb$High

summary <- read_annual("out.csv")
if (!"f" %in% names(summary)) abort("Fbar is absent from out.csv.")
Fbarout <- output_rows(nrow(summary), "mortality", "Fbar", "per year",
  "model_repository/csv/2025/out.csv; Rdata/2025/fit.Rdata; CCAM::fbartable",
  age_group = "5-10+", notes = "Source Fbar uses ages 5-10, with age 10 as the plus group; point estimates are rounded to 0.01 per year.")
Fbarout$year <- summary$year
Fbarout$value <- summary$f

catch <- read_annual("catch.limits.csv")
Catchout <- output_rows(nrow(catch), "catch", "predicted_catch", "t",
  "model_repository/csv/2025/catch.limits.csv; Rdata/2025/fit.Rdata; CCAM::catchtable",
  notes = uncertainty_note)
Catchout$year <- catch$year
Catchout$value <- catch$Estimate
Catchout$lwr <- catch$Low
Catchout$upr <- catch$High

total_N <- aggregate(Estimate ~ year, N, sum)
names(total_N)[[2L]] <- "value"
TotalNout <- output_rows(nrow(total_N), "population", "total_numbers", "thousand fish",
  "Derived from model_repository/csv/2025/N_sd.csv; age 1-10+ population sum",
  notes = "Sum of fitted N-at-age point estimates across the complete age range 1-10+ for each year. No uncertainty is derived because the joint covariance is unavailable.",
  source_type = "derived_source_output")
TotalNout$year <- total_N$year
TotalNout$value <- total_N$value

outputs <- do.call(rbind, list(Nout, Fout, SSBout, Rout, TSBout, Fbarout, Catchout, TotalNout))
outputs <- outputs[order(outputs$year, outputs$type, outputs$measure, outputs$age), , drop = FALSE]

new_assessment <- data.frame(
  assessment_id = assessment_id, stock_id = stock_id,
  assessment_year = 2025, terminal_year = 2025, estimate_terminal_year = 2025,
  assessment_type = "full_assessment", model_family = "CCAM",
  model_version = paste0("2025 run; mackerel_assessment ", model_revision,
    "; fit CCAM RemoteSha 1d1cc18416b2; available CCAM source snapshot ",
    ccam_revision),
  is_current = TRUE, is_applied = TRUE, framework_year = NA_real_,
  assessment_url = assessment_url, framework_url = framework_url,
  data_url = paste0(model_base, "/data/2025"),
  model_url = paste0(model_base, "/Rdata/2025/fit.Rdata"),
  repository_url = repository_url,
  assumptions_status = "partial", inputs_status = "complete", outputs_status = "partial",
  notes = paste(
    "The official 2025 assessment is represented by the pinned DFO mackerel_assessment repository run, with annual inputs and fitted exports through 2025.",
    "DFO Research Document 2025/054 documents the preceding 2024 assessment and is used only for method and age-group context.",
    "The 2026/040 Science Advisory Report PDF download currently resolves to archived HTML; its official catalogue record is retained, and the pinned native run supplies numerical inputs and outputs.",
    "The aggregate TEP likelihood is not represented by tinyAM's age-specific index equation and is excluded from translation. M is fixed input, not an estimated M output."
  ), stringsAsFactors = FALSE
)

stock <- read.csv(file.path(db, "stocks.csv"), stringsAsFactors = FALSE,
  check.names = FALSE, na.strings = c("", "NA"))
stock_row <- which(stock$stock_id == stock_id)
if (length(stock_row) != 1L) abort("Expected one existing metadata row for ", stock_id)
stock$authority_stock_id[stock_row] <- "Northern contingent Atlantic mackerel"
stock$common_name[stock_row] <- "Northern contingent Atlantic mackerel"
stock$area[stock_row] <- "Northwest Atlantic northern contingent; main spawning area NAFO Division 4T"
stock$region[stock_row] <- "Northwest Atlantic"
stock$notes[stock_row] <- paste(
  "Matched existing Charbonneau-Keith DFO-QC_scombrus_4T metadata to the northern contingent assessed by DFO.",
  "The catalogue's 4T label is retained as an identifier; the assessment stock spans the Northwest Atlantic northern contingent, with its main spawning area in 4T."
)

write_rows <- function(name, rows, id, replace_in_place = FALSE) {
  path <- file.path(db, name)
  lines <- readLines(path, warn = FALSE, encoding = "UTF-8")
  pattern <- paste0('^"?', id, '"?,')
  matches <- which(grepl(pattern, lines[-1L])) + 1L
  tmp <- tempfile(fileext = ".csv")
  on.exit(unlink(tmp), add = TRUE)
  write.csv(rows, tmp, row.names = FALSE, na = "", fileEncoding = "UTF-8")
  new_lines <- readLines(tmp, warn = FALSE, encoding = "UTF-8")
  if (replace_in_place) {
    if (length(matches) != 1L || nrow(rows) != 1L) abort("Expected one replaceable row for ", id)
    lines[matches] <- new_lines[[2L]]
    writeLines(lines, path, useBytes = TRUE)
  } else {
    body <- lines[-1L]
    body <- body[!grepl(pattern, body)]
    writeLines(c(lines[1L], body, new_lines[-1L]), path, useBytes = TRUE)
  }
}
write_rows("stocks.csv", stock[stock$stock_id == stock_id, , drop = FALSE],
  stock_id, replace_in_place = TRUE)
write_rows("assessments.csv", new_assessment, assessment_id)
write_rows("assumptions.csv", assumptions, assessment_id)
write_rows("inputs.csv", inputs, assessment_id)
write_rows("outputs.csv", outputs, assessment_id)

cat("Imported ", nrow(inputs), " inputs and ", nrow(outputs),
  " outputs for ", assessment_id, ".\n", sep = "")

