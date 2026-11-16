assessment_ids <- c(
  "ices_sol_27_8ab_2026", "ices_wit_27_3a47d_2026",
  "noaa_yellowtail_snapper_11081_2025", "noaa_atlantic_menhaden_2025"
)

read_assessment_rows_for_ids <- function(path, ids) {
  connection <- file(path, open = "rb")
  on.exit(close(connection))
  header <- readLines(connection, n = 1L, warn = FALSE)
  pattern <- paste0('^"(', paste(ids, collapse = "|"), ')"[,]')
  selected <- character()
  repeat {
    chunk <- readLines(connection, n = 50000L, warn = FALSE)
    if (!length(chunk)) break
    selected <- c(selected, chunk[grepl(pattern, chunk, perl = TRUE)])
  }
  if (!length(selected)) return(read.csv(text = header, check.names = FALSE))
  read.csv(text = paste(c(header, selected), collapse = "\n"),
    stringsAsFactors = FALSE, check.names = FALSE, na.strings = c("", "NA"))
}

inputs <- read_assessment_rows_for_ids("database/inputs.csv", assessment_ids)
outputs <- read_assessment_rows_for_ids("database/outputs.csv", assessment_ids)
assumptions <- read_assessment_rows_for_ids("database/assumptions.csv", assessment_ids)
stocks <- read.csv("database/stocks.csv", stringsAsFactors = FALSE, check.names = FALSE)
assessments <- read.csv("database/assessments.csv", stringsAsFactors = FALSE, check.names = FALSE)
candidates <- read.csv("database/candidates.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)

num <- function(x) suppressWarnings(as.numeric(x))
input_by_id <- function(id) inputs[inputs$assessment_id == id, , drop = FALSE]
output_by_id <- function(id) outputs[outputs$assessment_id == id, , drop = FALSE]
assumption_by_id <- function(id) assumptions[assumptions$assessment_id == id, , drop = FALSE]

sole <- input_by_id("ices_sol_27_8ab_2026")
sole_out <- output_by_id("ices_sol_27_8ab_2026")
witch <- input_by_id("ices_wit_27_3a47d_2026")
witch_out <- output_by_id("ices_wit_27_3a47d_2026")
yellowtail <- input_by_id("noaa_yellowtail_snapper_11081_2025")
yellowtail_out <- output_by_id("noaa_yellowtail_snapper_11081_2025")
yellowtail_assumptions <- assumption_by_id("noaa_yellowtail_snapper_11081_2025")
menhaden <- input_by_id("noaa_atlantic_menhaden_2025")
menhaden_out <- output_by_id("noaa_atlantic_menhaden_2025")
menhaden_assumptions <- assumption_by_id("noaa_atlantic_menhaden_2025")

stopifnot(
  nrow(sole) == 1019L, nrow(sole_out) == 714L,
  num(sole$value[sole$type == "catch" & sole$year == 1984 & sole$age == 2]) == 6522,
  num(sole_out$value[sole_out$measure == "SSB" & sole_out$year == 2025]) == 9917,
  nrow(witch) == 813L, nrow(witch_out) == 1824L,
  num(witch$value[witch$type == "catch" & witch$year == 2009 & witch$age == 1]) == 1880573,
  num(witch_out$value[witch_out$measure == "SSB" & witch_out$year == 2025]) == 4650,
  nrow(yellowtail) == 251L, nrow(yellowtail_out) == 256L,
  nrow(yellowtail_assumptions) == 18L,
  sum(yellowtail$measure == "relative_abundance_index" | yellowtail$measure == "relative_biomass_index") == 94L,
  sum(grepl("_index_cv$", yellowtail$measure)) == 94L,
  num(yellowtail$value[yellowtail$measure == "natural_mortality_at_age" & yellowtail$age == 0]) == .558,
  num(yellowtail$value[yellowtail$measure == "maturity_at_age" & yellowtail$age == 2]) == .69,
  num(yellowtail$value[yellowtail$measure == "relative_abundance_index" & yellowtail$survey == "Commercial CPUE" & yellowtail$year == 2023]) == 1.826,
  num(yellowtail_out$value[yellowtail_out$measure == "SSB" & yellowtail_out$year == 2023]) == 2684,
  num(yellowtail_out$value[yellowtail_out$measure == "total_abundance" & yellowtail_out$year == 2023]) == 49880,
  num(yellowtail_out$value[yellowtail_out$measure == "fishing_mortality_at_age" & yellowtail_out$year == 2023]) == .2,
  all(is.na(yellowtail_out$se) & is.na(yellowtail_out$lwr) & is.na(yellowtail_out$upr)),
  nrow(menhaden) == 2434L, nrow(menhaden_out) == 2L,
  nrow(menhaden_assumptions) == 41L,
  sum(menhaden$measure == "landings_biomass") == 362L,
  sum(menhaden$measure == "proportion_at_age") == 1505L,
  sum(menhaden$measure == "composition_sample_count") == 216L,
  sum(menhaden$measure == "relative_abundance_index") == 172L,
  sum(menhaden$measure == "abundance_index_cv") == 172L,
  sum(menhaden$measure == "natural_mortality_at_age") == 7L,
  num(menhaden$value[menhaden$measure == "landings_biomass" & menhaden$fleet == "Reduction" & menhaden$region == "North" & menhaden$year == 2023]) == 26,
  num(menhaden$value[menhaden$measure == "proportion_at_age" & menhaden$fleet == "Reduction" & menhaden$region == "North" & menhaden$year == 1955 & menhaden$age == 1]) == .015,
  num(menhaden$value[menhaden$measure == "composition_sample_count" & menhaden$year == 2020 & grepl("A2", menhaden$observation_id)]) == 0,
  any(grepl("censored from the base run", menhaden$notes[menhaden$year == 2020 & menhaden$measure == "proportion_at_age"])),
  num(menhaden$value[menhaden$measure == "relative_abundance_index" & menhaden$survey == "Conn YOY" & menhaden$year == 2023]) == .43,
  num(menhaden$value[menhaden$measure == "natural_mortality_at_age" & menhaden$age == 6]) == .57,
  nrow(menhaden_assumptions[menhaden_assumptions$setting == "Conn_component_process_sd", ]) == 24L,
  !anyDuplicated(do.call(paste, c(lapply(menhaden_assumptions[c("assessment_id", "component", "fleet", "survey", "sex", "region", "season", "setting")], function(x) { x[is.na(x)] <- ""; as.character(x) }), sep = "\r"))),
  any(grepl("first Table A7 entry", menhaden_assumptions$survey)),
  any(grepl("second Table A7 entry", menhaden_assumptions$survey)),
  num(menhaden_out$value[menhaden_out$measure == "fishing_mortality_summary" & menhaden_out$year == 2023]) == .26,
  num(menhaden_out$value[menhaden_out$measure == "total_egg_production" & menhaden_out$year == 2023]) == 1240272,
  !any(menhaden_out$measure %in% c("SSB", "numbers_at_age", "fishing_mortality_at_age")),
  all(vapply(assessment_ids, function(id) sum(assessments$assessment_id == id) == 1L, logical(1L))),
  all(vapply(assessment_ids, function(id) {
    row <- assessments[assessments$assessment_id == id, , drop = FALSE]
    all(row[c("inputs_status", "outputs_status", "assumptions_status")] == "partial")
  }, logical(1L))),
  all(c("ICES:sol.27.8ab", "ICES:wit.27.3a47d", "NOAA:11081", "NOAA:11089") %in% candidates$candidate_id),
  all(candidates$import_status[match(c("ICES:sol.27.8ab", "ICES:wit.27.3a47d", "NOAA:11081", "NOAA:11089"), candidates$candidate_id)] == "partial"),
  all(candidates$eligibility[match(c("ICES:sol.27.8ab", "ICES:wit.27.3a47d", "NOAA:11081", "NOAA:11089"), candidates$candidate_id)] == "unresolved"),
  grepl("catch numbers-at-age", paste(readLines("source_reviews/noaa_atlantic_menhaden.md"), collapse = " ")),
  grepl("Eligibility for an age-disaggregated comparison remains unresolved", paste(readLines("source_reviews/noaa_yellowtail_snapper_11081.md"), collapse = " "))
)

cat("Four partial imports: values, coverage, units, candidate status, and documented gaps passed.\n")




