root <- "."
assessment_id <- "afma_sessf_eastern_school_whiting_2024"
candidate_id <- "AFMA:SESSF_Eastern_School_Whiting"
report_path <- file.path(root,
  "source_cache/afma_school_whiting/frdc_2019-030_final_report.pdf")
report_url <- "https://www.frdc.com.au/sites/default/files/products/2019-030-DLD.pdf"
report_hash <- "39FD3D537ACEB850769F85C7F602CC95C7DE8F7B739B4EF14C7ADFB932CDF25F"
write_mode <- "--write" %in% commandArgs(trailingOnly = TRUE)

if (!file.exists(report_path) ||
    toupper(unname(tools::sha256sum(report_path))) != report_hash) {
  stop("The cached FRDC report differs from the reviewed source.", call. = FALSE)
}

read_csv <- function(path) utils::read.csv(path, stringsAsFactors = FALSE,
  colClasses = "character", check.names = FALSE, na.strings = c("", "NA"))

read_fields <- function(path) names(utils::read.csv(path, nrows = 0L,
  check.names = FALSE))

source(file.path(root, "scripts/database/candidate_register_io.R"), local = TRUE)

blank_row <- function(fields, values) {
  row <- as.list(rep("", length(fields)))
  names(row) <- fields
  for (name in intersect(names(values), fields)) {
    value <- values[[name]]
    row[[name]] <- if (length(value) == 0L || is.na(value[1L])) "" else
      as.character(value[1L])
  }
  as.data.frame(row, stringsAsFactors = FALSE, check.names = FALSE)
}

append_csv <- function(path, rows) {
  if (!nrow(rows)) return(invisible(NULL))
  fields <- read_fields(path)
  missing <- setdiff(fields, names(rows))
  if (length(missing)) stop("Missing columns: ", paste(missing, collapse = ", "),
    call. = FALSE)
  utils::write.table(rows[fields], path, sep = ",", row.names = FALSE,
    col.names = FALSE, quote = TRUE, qmethod = "double", na = "",
    append = TRUE, eol = "\n")
}

read_assessment_rows <- function(path, id) {
  connection <- file(path, open = "rt")
  on.exit(close(connection))
  header <- readLines(connection, n = 1L, warn = FALSE)
  prefix <- paste0('"', id, '"')
  rows <- character()
  repeat {
    chunk <- readLines(connection, n = 50000L, warn = FALSE)
    if (!length(chunk)) break
    rows <- c(rows, chunk[startsWith(chunk, prefix)])
  }
  if (!length(rows)) {
    return(utils::read.csv(text = header, stringsAsFactors = FALSE,
      colClasses = "character", check.names = FALSE))
  }
  utils::read.csv(text = paste(c(header, rows), collapse = "\n"),
    stringsAsFactors = FALSE, colClasses = "character", na.strings = c("", "NA"),
    check.names = FALSE)
}

normalize_rows <- function(rows) {
  rows[] <- lapply(rows, function(value) {
    value <- as.character(value)
    value[is.na(value)] <- ""
    value
  })
  rows
}

row_keys <- function(rows, fields) {
  do.call(paste, c(lapply(rows[fields], function(value) {
    ifelse(is.na(value), "", as.character(value))
  }), sep = "\r"))
}

rows_to_add <- function(existing, proposed, key_fields) {
  existing <- normalize_rows(existing)
  proposed <- normalize_rows(proposed)
  existing_keys <- row_keys(existing, key_fields)
  proposed_keys <- row_keys(proposed, key_fields)
  if (anyDuplicated(proposed_keys)) stop("The proposed rows contain duplicate keys.",
    call. = FALSE)
  for (i in which(proposed_keys %in% existing_keys)) {
    j <- match(proposed_keys[i], existing_keys)
    if (!identical(unlist(existing[j, names(proposed), drop = FALSE],
      use.names = FALSE), unlist(proposed[i, , drop = FALSE], use.names = FALSE))) {
      stop("An existing record key has a different source value.", call. = FALSE)
    }
  }
  proposed[!proposed_keys %in% existing_keys, , drop = FALSE]
}

database <- file.path(root, "database")
assumptions_path <- file.path(database, "assumptions.csv")
outputs_path <- file.path(database, "outputs.csv")
candidates_path <- file.path(root, "discovery/candidates.csv")
assumptions_fields <- read_fields(assumptions_path)
outputs_fields <- read_fields(outputs_path)
assumptions <- function(setting, value, notes = "") {
  blank_row(assumptions_fields, list(
    assessment_id = assessment_id, component = "biology", region = "Southeastern Australia",
    setting = setting, value = value,
    source_reference = "Hall et al. 2026, FRDC Final Report 2019-030, Table 18, p. 130; reproduced from Burch et al. 2024b",
    notes = notes
  ))
}

assumption_rows <- do.call(rbind, list(
  assumptions("assessment_length_weight_intercept_a", "1.32e-5",
    "Non-estimated allometric length-weight coefficient used in the 2024 assessment. The source labels the associated equation units as g and cm and cites Bax and Knuckey (2004)."),
  assumptions("assessment_length_weight_exponent_b", "2.93",
    "Non-estimated allometric length-weight exponent used in the 2024 assessment; see the source note for the units and citation attached to coefficient a."),
  assumptions("female_length_at_50_percent_maturity", "16 cm FL",
    "Non-estimated value used in the 2024 assessment. This is distinct from the current-project biological estimate of 157.5 mm reported in Table 29."),
  assumptions("female_maturity_slope", "-2",
    "Non-estimated maturity-curve slope used in the 2024 assessment. The source reports the value and its stated unit as cm; retained as published.")
))

output <- function(type, measure, value, unit, year, scenario, notes,
    source_reference) {
  blank_row(outputs_fields, list(
    assessment_id = assessment_id, type = type, measure = measure,
    region = "Southeastern Australia", year = year, value = value, unit = unit,
    source_type = "official_table", source_reference = source_reference,
    scenario = scenario, notes = notes
  ))
}

table43 <- data.frame(
  scenario = c(
    "Final combined base case", "Natural mortality M=0.5", "Natural mortality M=0.7",
    "Steepness h=0.65", "Steepness h=0.85", "Length at 50% maturity 14 cm",
    "Length at 50% maturity 18 cm", "Recruitment variability sigma_R=0.6",
    "Recruitment variability sigma_R=0.8", "Length-composition weight x0.5",
    "Length-composition weight x2", "Age-at-length weight x0.5",
    "Age-at-length weight x2", "CPUE weight x0.5", "CPUE weight x2",
    "Exclude Commonwealth Danish seine CPUE", "Exclude Commonwealth trawl CPUE",
    "Exclude Commonwealth trawl and NSW southern trawl CPUE",
    "Alternative NSW prawn trawl catch series"
  ),
  nll = c(521, 524, 520, 521, 520, 521, 521, 516, 526, 365, 820, 409, 738,
    581, 393, 562, 532, 535, 521),
  delta_nll = c(0, 3, -1, 0, -1, 0, 0, -5, 5, -156, 299, -112, 217, 60,
    -128, 41, 11, 14, 0),
  ssb0 = c(13208, 13358, 14792, 14080, 12646, 16492, 9646, 12458, 14164,
    13250, 13166, 13552, 12982, 12950, 13336, 13130, 12948, 12852, 13674),
  ssb2025 = c(7110, 5631, 9598, 7016, 7187, 10130, 4191, 6798, 7508, 7117,
    7189, 7424, 6939, 6981, 7212, 8687, 6575, 6356, 7412),
  ratio = c(.54, .42, .65, .50, .57, .61, .43, .55, .53, .54, .55, .55, .53,
    .54, .54, .66, .51, .49, .54),
  stringsAsFactors = FALSE
)

table43_reference <- "Hall et al. 2026, FRDC Final Report 2019-030, Table 43, p. 207 (reproduced from Burch et al. 2024b)"
table43_scenario <- paste("Table 43:", table43$scenario)
table43_notes <- ifelse(seq_len(nrow(table43)) == 1L,
  "The base-case line reports the same 2024 final combined fit as the contemporaneous SERAG minutes. Table 43 gives SSB0 as 13,208 t; the minutes report 13,207 t. Preserve both source presentations; the 1 t difference is consistent with rounding, not a separate fit.",
  paste("Reported sensitivity result for", table43$scenario,
    "under the 2024 assessment. Total spawning biomass includes male and female biomass. No numeric uncertainty interval is tabulated."))

table43_rows <- do.call(rbind, lapply(seq_len(nrow(table43)), function(i) {
  scenario <- table43_scenario[i]
  notes <- table43_notes[i]
  rbind(
    output("diagnostic", "negative_log_likelihood", table43$nll[i],
      "negative log-likelihood units", NA, scenario, notes, table43_reference),
    output("diagnostic", "change_in_negative_log_likelihood", table43$delta_nll[i],
      "negative log-likelihood units relative to base case", NA, scenario, notes,
      table43_reference),
    output("biomass", "unfished_spawning_biomass", table43$ssb0[i], "tonnes", NA,
      scenario, notes, table43_reference),
    output("biomass", "SSB", table43$ssb2025[i], "tonnes", 2025L, scenario, notes,
      table43_reference),
    output("biomass", "SSB_ratio_to_B0", table43$ratio[i],
      "proportion of unfished SSB (B0)", 2025L, scenario, notes, table43_reference)
  )
}))

table44_reference <- "Hall et al. 2026, FRDC Final Report 2019-030, Table 44, p. 208 (reproduced from Burch et al. 2024b)"
table44_rows <- do.call(rbind, list(
  output("catch", "retained_catch", 2489, "tonnes", 2025L,
    "Table 44: 2024 final model, average recruitment", "Retained catch associated with the 2025 projected RBC.", table44_reference),
  output("catch", "retained_catch", 2374, "tonnes", 2026L,
    "Table 44: 2024 final model, average recruitment", "Retained catch associated with the 2026 projected RBC.", table44_reference),
  output("catch", "estimated_discards", 597, "tonnes", 2025L,
    "Table 44: 2024 final model, average recruitment", "Estimated discards associated with the 2025 projected RBC.", table44_reference),
  output("catch", "estimated_discards", 587, "tonnes", 2026L,
    "Table 44: 2024 final model, average recruitment", "Estimated discards associated with the 2026 projected RBC.", table44_reference),
  output("biomass", "SSB_ratio_to_B0", .538, "proportion of unfished SSB (B0)", 2025L,
    "Table 44: 2024 final model, average recruitment", "More precise source-reported stock status; Table 44 reports .538, while the summary rounds to 54% and Table 43 to .54.", table44_reference),
  output("biomass", "SSB_ratio_to_B0", .509, "proportion of unfished SSB (B0)", 2026L,
    "Table 44: 2024 final model, average recruitment", "Projected stock status under the average-recruitment scenario.", table44_reference),
  output("catch", "recommended_biological_catch", 3023, "tonnes", NA,
    "Table 44: 2025-2026 two-year average", "Table 44 reports a two-year average RBC of 3,023 t; the AFMA summary reports 3,024 t. Retained separately as source-reported rounding.", table44_reference),
  output("catch", "retained_catch", 2432, "tonnes", NA,
    "Table 44: 2025-2026 two-year average", "Two-year average retained catch.", table44_reference),
  output("catch", "estimated_discards", 592, "tonnes", NA,
    "Table 44: 2025-2026 two-year average", "Two-year average estimated discards.", table44_reference),
  output("management", "long_term_yield", 2830, "tonnes", NA,
    "Table 44: long-term average recruitment", "Long-term yield under the 20:35:48 harvest control rule.", table44_reference)
))

assumption_key_fields <- c("assessment_id", "component", "fleet", "survey", "sex",
  "region", "season", "setting")
output_key_fields <- c("assessment_id", "type", "measure", "fleet", "survey",
  "sex", "region", "season", "year", "age", "age_group", "scenario")

existing_assumptions <- read_csv(assumptions_path)
existing_outputs <- read_assessment_rows(outputs_path, assessment_id)
assumptions_to_add <- rows_to_add(existing_assumptions, assumption_rows,
  assumption_key_fields)
outputs_to_add <- rows_to_add(existing_outputs,
  rbind(table43_rows, table44_rows), output_key_fields)

candidates <- read_csv(candidates_path)
candidate_row <- which(candidates$candidate_id == candidate_id)
if (length(candidate_row) != 1L ||
    !assessment_id %in% read_csv(file.path(database, "assessments.csv"))$assessment_id ||
    !any(read_csv(file.path(database, "stocks.csv"))$stock_id == "afma_sessf_eastern_school_whiting")) {
  stop("The existing School Whiting record does not match the reviewed source.",
    call. = FALSE)
}

candidate <- candidates[candidate_row, , drop = FALSE]
candidate$detailed_source_url <- report_url
candidate$catch_age_evidence <- paste(
  "The 2026 FRDC final report confirms that the 2024 six-fleet SS3 assessment used catches, CPUE, length compositions, conditional age-at-length, discards, and ageing error, but it does not publish the numerical likelihood arrays.",
  "The separate 2020 assessment is not used to fill the 2024 gap."
)
candidate$output_evidence <- paste(
  "FRDC Table 43 reproduces base-case SSB0 = 13,208 t and SSB2025 = 7,110 t, plus sensitivity NLL, SSB0, SSB2025, and SSB2025/SSB0; Table 44 reports annual and average catch advice, retained catch, discards, stock status, and long-term yield.",
  "Table 43 reports base-case SSB0 = 13,208 t; the SERAG minutes report 13,207 t, a one-tonne reporting difference."
)
candidate$decision_reason <- paste(
  "Current-run assumptions and selected model outputs are now supported by the AFMA summary, SERAG minutes, and the 2026 FRDC final report reproducing Burch et al. (2024b).",
  "Age-input eligibility remains unresolved because no numerical likelihood arrays are published in the reviewed sources."
)
candidate$notes <- paste(
  "FRDC 2019-030 final report provides supporting biological parameters and selected 2024 assessment outputs; it does not provide raw annual likelihood inputs.",
  "See source_reviews/afma_school_whiting_sessf.md."
)

cat("AFMA eastern school whiting: ", nrow(assumptions_to_add),
  " assumptions and ", nrow(outputs_to_add), " source outputs ready.\n", sep = "")
if (!write_mode) {
  cat("Dry run only. Re-run with --write to update the assumptions, outputs, and candidate register.\n")
} else {
  append_csv(assumptions_path, assumptions_to_add)
  append_csv(outputs_path, outputs_to_add)
  replace_candidate_register_row(candidates_path, candidate_row, candidate, candidate_id)
  cat("Wrote the detailed AFMA School Whiting source data.\n")
}
