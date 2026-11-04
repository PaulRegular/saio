root <- "."
database <- file.path(root, "database")
cache <- file.path(root, "source_cache", "discovery_dfo_greenland_halibut_2_3klmno_2025")
manifest_path <- file.path(root, "provenance", "discovery_dfo_greenland_halibut_2_3klmno_2025", "sources.csv")
dry_run <- identical(Sys.getenv("SAIO_IMPORT_DRY_RUN"), "1")

manifest <- utils::read.csv(
  manifest_path, stringsAsFactors = FALSE, na.strings = c("", "NA"),
  check.names = FALSE
)

sha256_file <- function(path) {
  result <- system2(
    "certutil.exe",
    c("-hashfile", shQuote(normalizePath(path, winslash = "\\")), "SHA256"),
    stdout = TRUE
  )
  hashes <- tolower(trimws(grep(
    "^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$", result, value = TRUE
  )))
  if (length(hashes) != 1L) stop("Could not verify a cached NAFO PDF checksum.", call. = FALSE)
  hashes
}

for (file in c("nafo_scr_23_007_input_data_2023.pdf", "nafo_scr_23_008rev_sca_assessment_2023.pdf")) {
  row <- match(file, manifest$file)
  path <- file.path(cache, file)
  if (is.na(row) || !file.exists(path) ||
    !identical(tolower(manifest$sha256[row]), sha256_file(path))) {
    stop("A cached Greenland halibut SCAA source is missing from the provenance manifest or differs from its checksum: ", file,
      call. = FALSE)
  }
}

data_path <- file.path(cache, "nafo_scr_23_007_input_data_2023.pdf")
scaa_path <- file.path(cache, "nafo_scr_23_008rev_sca_assessment_2023.pdf")
data_text <- pdftools::pdf_text(data_path)
data_pages <- pdftools::pdf_data(data_path)

parse_number <- function(x) {
  value <- gsub(",", "", paste0(x, collapse = ""), fixed = TRUE)
  value <- gsub("[^0-9.\\-]", "", value)
  if (!nzchar(value) || identical(value, "-")) return(NA_real_)
  suppressWarnings(as.numeric(value))
}

extract_numeric_table <- function(pages, page_numbers, years, n_values, label) {
  lines <- unlist(lapply(pages[page_numbers], strsplit, "\\n"), use.names = FALSE)
  rows <- list()
  for (line in lines) {
    tokens <- strsplit(trimws(line), "[[:space:]]+")[[1]]
    if (!length(tokens) || !tokens[[1]] %in% as.character(years) ||
      length(tokens) != n_values + 1L ||
      any(!grepl("^[0-9][0-9,.]*$", tokens[-1]))) next
    values <- vapply(tokens[-1], parse_number, numeric(1))
    row <- as.data.frame(as.list(values), stringsAsFactors = FALSE)
    names(row) <- paste0("v", seq_len(n_values))
    row$year <- as.integer(tokens[[1]])
    rows[[length(rows) + 1L]] <- row[, c("year", paste0("v", seq_len(n_values))), drop = FALSE]
  }
  if (!length(rows)) stop("No rows were recovered from the ", label, " table.", call. = FALSE)
  out <- do.call(rbind, rows)
  out <- out[order(out$year), , drop = FALSE]
  if (!setequal(out$year, years) || anyDuplicated(out$year)) {
    stop("The ", label, " table has incomplete years or duplicate rows.", call. = FALSE)
  }
  out
}

landings <- extract_numeric_table(data_text, 6:7, 1960:2021, 1L, "landings")
catch_age_1_10 <- extract_numeric_table(data_text, 8:9, 1975:2021, 10L, "catch-at-age")
catch_weight_1_10 <- extract_numeric_table(data_text, 10:11, 1975:2021, 10L, "catch weights-at-age")

extract_survey_biomass <- function(pages) {
  page <- pages[[12L]]
  years <- page[
    page$x < 120 & page$text %in% as.character(1995:2021) &
      page$y >= 80 & page$y <= 720, , drop = FALSE
  ]
  centers <- c(149, 206, 258, 414, 461, 513)
  surveys <- c(
    "Canada Autumn 2J3K", "Canada Autumn 3LNO", "Canada Spring 3LNO",
    "EU-Spain 3NO", "EU 3M 0-1400m", "EU 3M 0-700m"
  )
  rows <- list()
  for (j in seq_len(nrow(years))) {
    y <- years$y[[j]]
    words <- page[
      abs(page$y - y) < 0.5 & page$x >= 130 & page$x <= 550 &
        grepl("^[0-9][0-9,.]*$", page$text), , drop = FALSE
    ]
    assigned <- vapply(words$x, function(x) {
      distance <- abs(centers - x)
      at <- which.min(distance)
      if (distance[[at]] <= 20) at else NA_integer_
    }, integer(1))
    values <- rep(NA_real_, length(centers))
    for (i in seq_along(centers)) {
      tokens <- words$text[assigned == i & !is.na(assigned)]
      if (length(tokens)) values[[i]] <- parse_number(tokens)
    }
    rows[[length(rows) + 1L]] <- data.frame(
      survey = surveys, year = as.integer(years$text[[j]]),
      value = values, stringsAsFactors = FALSE
    )
  }
  out <- do.call(rbind, rows)
  out[!is.na(out$value), , drop = FALSE]
}

extract_survey_age <- function(pages) {
  section_y <- list(
    `13` = data.frame(y = c(135, 535), survey = c("Canada Autumn 2J3K", "Canada Autumn 3LNO")),
    `14` = data.frame(y = c(277, 608), survey = c("Canada Spring 3LNO", "EU 3M 0-700m")),
    `15` = data.frame(y = c(132, 419), survey = c("EU 3M 0-1400m", "EU-Spain 3NO")),
    `16` = data.frame(y = c(171, 419), survey = c("EU-Spain 3LNO", "EU-Spain 3L"))
  )
  age_x <- c(158, 194, 230, 266, 302, 338, 374, 410, 446, 482, 518)
  modeled_surveys <- c(
    "Canada Autumn 2J3K", "Canada Autumn 3LNO", "Canada Spring 3LNO",
    "EU 3M 0-700m", "EU 3M 0-1400m", "EU-Spain 3NO"
  )
  rows <- list()
  current_survey <- NULL

  for (page_number in 13:16) {
    page <- pages[[page_number]]
    headings <- section_y[[as.character(page_number)]]
    year_rows <- page[
      page$x < 145 & page$text %in% as.character(1990:2021) &
        page$y >= 80 & page$y <= 720, , drop = FALSE
    ]
    events <- sort(unique(c(headings$y, year_rows$y)))
    for (y in events) {
      matches <- headings[headings$y == y, , drop = FALSE]
      if (nrow(matches)) current_survey <- matches$survey[[1]]
      years_here <- year_rows[year_rows$y == y, , drop = FALSE]
      if (!nrow(years_here) || !current_survey %in% modeled_surveys) next

      words <- page[
        abs(page$y - y) <= 6 & page$x >= 145 & page$x <= 560 &
          grepl("^[0-9][0-9,.]*$", page$text), , drop = FALSE
      ]
      cells <- rep(NA_real_, length(age_x))
      assigned <- vapply(words$x, function(x) {
        distance <- abs(age_x - x)
        at <- which.min(distance)
        if (distance[[at]] <= 20) at else NA_integer_
      }, integer(1))
      for (age_index in seq_along(age_x)) {
        tokens <- words$text[assigned == age_index & !is.na(assigned)]
        if (length(tokens)) cells[[age_index]] <- parse_number(tokens)
      }
      if (current_survey %in% c("EU 3M 0-700m", "EU 3M 0-1400m") && is.na(cells[[1L]])) {
        cells[[1L]] <- 0
      }
      rows[[length(rows) + 1L]] <- data.frame(
        survey = current_survey, year = as.integer(years_here$text[[1]]),
        age = 0:10, value = cells, stringsAsFactors = FALSE
      )
    }
  }

  out <- do.call(rbind, rows)
  out <- out[out$survey %in% modeled_surveys, , drop = FALSE]
  key <- paste(out$survey, out$year, out$age, sep = "|")
  if (anyDuplicated(key) || any(!out$survey %in% modeled_surveys)) {
    stop("The SCAA base-case survey age table has duplicate or unexpected rows.", call. = FALSE)
  }
  out[order(out$survey, out$year, out$age), , drop = FALSE]
}

survey_biomass <- extract_survey_biomass(data_pages)
survey_age <- extract_survey_age(data_pages)
base_surveys <- c(
  "Canada Autumn 2J3K", "Canada Autumn 3LNO", "Canada Spring 3LNO",
  "EU 3M 0-700m", "EU 3M 0-1400m", "EU-Spain 3NO"
)
survey_biomass <- survey_biomass[survey_biomass$survey %in% base_surveys, , drop = FALSE]
survey_age <- survey_age[survey_age$survey %in% base_surveys, , drop = FALSE]
survey_age$source_notes <- ifelse(
  survey_age$survey %in% c("EU 3M 0-700m", "EU 3M 0-1400m") & survey_age$age == 0L,
  "The supporting data table leaves age 0 blank; the SCAA Table B5 prints 0.000, preserved here as zero.",
  ifelse(is.na(survey_age$value), "A blank source cell is preserved as missing.", "")
)

if (nrow(landings) != 62L || nrow(catch_age_1_10) != 47L ||
  nrow(catch_weight_1_10) != 47L || anyDuplicated(paste(survey_age$survey, survey_age$year, survey_age$age)) ||
  !setequal(unique(survey_biomass$survey), base_surveys) ||
  !setequal(unique(survey_age$survey), base_surveys) ||
  catch_age_1_10$v2[catch_age_1_10$year == 2021L] != 7 ||
  catch_age_1_10$v10[catch_age_1_10$year == 2021L] != 983 ||
  catch_weight_1_10$v10[catch_weight_1_10$year == 2021L] != 2.64 ||
  !all(survey_biomass$value[survey_biomass$survey == "Canada Autumn 2J3K" & survey_biomass$year == 2021L] == 21.15) ||
  !all(survey_biomass$value[survey_biomass$survey == "EU 3M 0-1400m" & survey_biomass$year == 2021L] == 16.31) ||
  !all(survey_biomass$value[survey_biomass$survey == "EU-Spain 3NO" & survey_biomass$year == 2021L] == 8.09) ||
  !all(survey_age$value[survey_age$survey == "Canada Autumn 2J3K" & survey_age$year == 2021L & survey_age$age >= 8L] == c(0.88, 0.35, 0.22))) {
  stop("The SCAA input tables failed year, age, or 2021 source checks.", call. = FALSE)
}

stocks_path <- file.path(database, "stocks.csv")
assessments_path <- file.path(database, "assessments.csv")
assumptions_path <- file.path(database, "assumptions.csv")
inputs_path <- file.path(database, "inputs.csv")
outputs_path <- file.path(database, "outputs.csv")
register_path <- file.path(root, "discovery", "candidates.csv")

stocks_existing <- utils::read.csv(stocks_path, stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)
assessments_existing <- utils::read.csv(assessments_path, stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)
assumptions_existing <- utils::read.csv(assumptions_path, nrows = 0L, stringsAsFactors = FALSE, check.names = FALSE)
inputs_existing <- utils::read.csv(inputs_path, nrows = 0L, stringsAsFactors = FALSE, check.names = FALSE)
outputs_existing <- utils::read.csv(outputs_path, nrows = 0L, stringsAsFactors = FALSE, check.names = FALSE)
register <- utils::read.csv(register_path, stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE, encoding = "UTF-8")

stock_id <- "dfo_greenland_halibut_2_3klmno"
scaa_id <- paste0(stock_id, "_2023_scaa")
candidate_id <- "DFO:Newfoundland and Labrador:Greenland Halibut (Turbot) - NAFO 2 + 3KLMNO"
candidate_row <- which(register$candidate_id == candidate_id)
if (!stock_id %in% stocks_existing$stock_id || length(candidate_row) != 1L ||
  !identical(register$candidate_unit_id[candidate_row], stock_id) ||
  !identical(register$match_status[candidate_row], "matched") ||
  !identical(register$import_status[candidate_row], "partial")) {
  stop("The Greenland halibut stock identity or candidate status has changed.", call. = FALSE)
}
if (scaa_id %in% assessments_existing$assessment_id) {
  stop("The Greenland halibut SCAA event already exists; refusing duplicate rows.", call. = FALSE)
}

empty_rows <- function(template, n) {
  out <- as.data.frame(matrix("", nrow = n, ncol = ncol(template)), stringsAsFactors = FALSE)
  names(out) <- names(template)
  out
}
repeat_n <- function(x, n) {
  if (length(x) == 1L) rep(x, n) else if (length(x) == n) x else stop("A row field has an unexpected length.", call. = FALSE)
}
input_block <- function(type, measure, basis, value, unit, source_reference,
                        year = NA_integer_, age = NA_integer_, survey = "", fleet = "",
                        region = "", season = "", notes = "", source_type = "official_table",
                        transformation = "") {
  n <- length(value)
  out <- empty_rows(inputs_existing, n)
  out$assessment_id <- scaa_id
  out$type <- type
  out$measure <- measure
  out$basis <- basis
  for (field in c("survey", "fleet", "region", "season", "notes", "source_type", "transformation")) {
    out[[field]] <- repeat_n(get(field), n)
  }
  year <- repeat_n(year, n)
  out$year <- ifelse(is.na(year), "", as.character(year))
  out$year_basis <- ifelse(is.na(year), "", "calendar_year")
  age <- repeat_n(age, n)
  out$age <- ifelse(is.na(age), "", as.character(age))
  out$value <- ifelse(is.na(value), "", as.character(value))
  out$unit <- unit
  out$source_reference <- source_reference
  out
}
assumption_block <- function(component, setting, value, source_reference, notes = "") {
  n <- length(value)
  out <- empty_rows(assumptions_existing, n)
  out$assessment_id <- scaa_id
  out$component <- component
  out$setting <- setting
  out$value <- as.character(value)
  out$source_reference <- source_reference
  out$notes <- repeat_n(notes, n)
  out
}
output_block <- function(measure, value, year, unit, source_reference,
                         age_group = "", notes = "") {
  n <- length(value)
  out <- empty_rows(outputs_existing, n)
  out$assessment_id <- scaa_id
  out$type <- "biomass"
  out$measure <- measure
  out$year <- as.character(repeat_n(year, n))
  out$age_group <- repeat_n(age_group, n)
  out$value <- as.character(value)
  out$unit <- unit
  out$source_type <- "official_table"
  out$source_reference <- source_reference
  out$notes <- repeat_n(notes, n)
  out
}

assessments <- empty_rows(assessments_existing, 1L)
assessments$assessment_id <- scaa_id
assessments$stock_id <- stock_id
assessments$assessment_year <- "2023"
assessments$terminal_year <- "2021"
assessments$estimate_terminal_year <- "2021"
assessments$assessment_type <- "management strategy evaluation update"
assessments$model_family <- "Statistical catch-at-age model"
assessments$model_version <- "2023 SCAA base-case operating model"
assessments$is_current <- "FALSE"
assessments$is_applied <- "FALSE"
assessments$framework_year <- "2017"
assessments$assessment_url <- "https://www.nafo.int/Portals/0/PDFs/sc/2023/scr23-008REV.pdf"
assessments$framework_url <- "https://www.nafo.int/Portals/0/PDFs/sc/2017/scr17-002.pdf"
assessments$assumptions_status <- "partial"
assessments$inputs_status <- "partial"
assessments$outputs_status <- "partial"
assessments$notes <- paste(
  "The 2023 SCAA base-case operating model is an MSE assessment run fitted through 2021, not the age-structured model used for the 2026 annual TAC advice.",
  "The report tabulates selected biomass estimates for 1975, 2016, and 2021; full annual N-at-age, F-at-age, recruitment, and SSB trajectories are shown in figures rather than numeric tables."
)

data_source <- "NAFO SCR Doc. 23/007, Tables 1-5, pp. 6-16; cross-checked against NAFO SCR Doc. 23/008REV, Tables B2-B5, pp. 21-25"
catch_numbers <- data.frame(
  year = catch_age_1_10$year,
  v0 = rep(0, nrow(catch_age_1_10)),
  catch_age_1_10[, -1, drop = FALSE],
  check.names = FALSE
)
catch_weights <- data.frame(
  year = catch_weight_1_10$year,
  v0 = rep(0, nrow(catch_weight_1_10)),
  catch_weight_1_10[, -1, drop = FALSE],
  check.names = FALSE
)
catch_values <- as.vector(t(as.matrix(catch_numbers[, -1, drop = FALSE])))
weight_values <- as.vector(t(as.matrix(catch_weights[, -1, drop = FALSE])))
catch_years <- rep(catch_numbers$year, each = 11L)
catch_ages <- rep(0:10, times = nrow(catch_numbers))

input_rows <- list(
  input_block(
    "catch", "landings_biomass", "biomass", landings$v1,
    "kilotonnes", "NAFO SCR Doc. 23/007, Table 1, pp. 6-7; SCAA use confirmed in report text",
    year = landings$year, fleet = "NAFO commercial fishery",
    notes = "Annual landings series used by the SCAA from 1960 onward; source reports kilotonnes."
  ),
  input_block(
    "catch", "numbers_at_age", "numbers", catch_values,
    "thousand fish", paste(data_source, "Commercial catch-at-age"),
    year = catch_years, age = rep(catch_ages, times = 1L), fleet = "NAFO commercial fishery",
    notes = ifelse(catch_ages == 0L,
      "The SCAA Table B2 reports zero catch at age 0 throughout 1975-2021.",
      "Catch numbers-at-age; age 10 represents the source 10+ group."),
    transformation = "Source tables report ages 1-10+; the SCAA Table B2 age-0 column is added as the reported all-zero series."
  ),
  input_block(
    "catch_weight", "catch_weight_at_age", "kg_per_fish", weight_values,
    "kg per fish", paste(data_source, "Commercial catch weights-at-age"),
    year = catch_years, age = rep(catch_ages, times = 1L), fleet = "NAFO commercial fishery",
    notes = ifelse(catch_ages == 0L,
      "The SCAA Table B3 reports zero catch weight at age 0 throughout 1975-2021.",
      "Catch weight; ages 1-2 are zero, and age 10 represents the source 10+ group. The SCAA methodology uses catch weights as the available age-specific fish mass."),
    transformation = "Source tables report ages 1-10+; the SCAA Table B3 age-0 column is added as the reported all-zero series."
  ),
  input_block(
    "index", "relative_biomass_index", "index_scale", survey_biomass$value,
    "kg per tow", "NAFO SCR Doc. 23/007, Table 4, p. 12; NAFO SCR Doc. 23/008REV, Table B5, pp. 24-25",
    year = survey_biomass$year, survey = survey_biomass$survey,
    region = ifelse(grepl("2J3K", survey_biomass$survey), "NAFO Divisions 2J3K",
      ifelse(grepl("3LNO", survey_biomass$survey), "NAFO Divisions 3LNO",
        ifelse(grepl("3NO", survey_biomass$survey), "NAFO Divisions 3NO", "NAFO Division 3M"))),
    season = ifelse(grepl("Autumn", survey_biomass$survey), "Autumn",
      ifelse(grepl("Spring", survey_biomass$survey), "Spring", "")),
    notes = "SCAA base-case survey biomass index reported as mean weight per tow. The 23/007 table supplies values to two decimals; no scaling factor is applied."
  ),
  input_block(
    "index", "numbers_at_age", "index_scale", survey_age$value,
    "mean number per tow", "NAFO SCR Doc. 23/007, Table 5, pp. 13-16; NAFO SCR Doc. 23/008REV, Table B5, pp. 24-25",
    year = survey_age$year, age = survey_age$age, survey = survey_age$survey,
    region = ifelse(grepl("2J3K", survey_age$survey), "NAFO Divisions 2J3K",
      ifelse(grepl("3LNO", survey_age$survey), "NAFO Divisions 3LNO",
        ifelse(grepl("3M", survey_age$survey), "NAFO Division 3M", "NAFO Divisions 3NO"))),
    season = ifelse(grepl("Autumn", survey_age$survey), "Autumn",
      ifelse(grepl("Spring", survey_age$survey), "Spring", "")),
    notes = paste("SCAA 2023 base-case survey numbers-at-age; age 10 is the source 10+ group.", survey_age$source_notes)
  ),
  input_block(
    "maturity", "maturity_at_age", "proportion", c(rep(0, 9L), rep(1, 5L)),
    "proportion", "NAFO SCR Doc. 23/008REV, Table B4, p. 23",
    age = 1:14, notes = "Fixed SCAA maturity schedule: ages 1-9 are immature; ages 10-14+ are mature. Age 14 represents the 14+ group."
  )
)
inputs <- do.call(rbind, input_rows)

assumptions <- rbind(
  assumption_block("model", "SCAA role", "2023 base-case operating model for MSE; not the model used for annual TAC advice", "NAFO SCR Doc. 23/008REV, pp. 1-2; NAFO SCR Doc. 23/007, p. 1"),
  assumption_block("recruitment", "steepness h", "0.80 (fixed)", "NAFO SCR Doc. 23/008REV, Table 1, p. 4", "The report marks bold values as fixed on input."),
  assumption_block("mortality", "natural mortality M", "0.12 per year (fixed)", "NAFO SCR Doc. 23/008REV, Table 1, p. 4", "The report marks bold values as fixed on input."),
  assumption_block("survey", "base-case survey series", paste(base_surveys, collapse = "; "), "NAFO SCR Doc. 23/008REV, Table 1 and Appendix B, pp. 4, 24-25", "EU-Spain 3L and EU-Spain 3LNO appear only in sensitivity runs and are not imported to this base-case event."),
  assumption_block("survey", "survey index observation model", "Lognormal survey biomass-index likelihood; survey-specific residual variability is estimated, with a minimum SD of 0.15 described in the methodology.", "NAFO SCR Doc. 23/008REV, Appendix A, section A.2.1"),
  assumption_block("survey", "survey timing", "The biomass-index calculation adjusts for survey timing within the year; numerical survey-month/timing values were not recoverable from the reviewed tables.", "NAFO SCR Doc. 23/008REV, Appendix A, section A.2.1; NAFO SCR Doc. 17/002, Appendix B", "No timing values are imputed."),
  assumption_block("biology", "catch weights used for fish mass", "Catch weights-at-age are the only age-specific mass data reported and are used as the model fish mass.", "NAFO SCR Doc. 23/008REV, Appendix A, section A.2.1", "The database retains the source series as catch weights; it does not relabel them as separate stock or spawning weights.")
)

summary_source <- "NAFO SCR Doc. 23/008REV, Table 1, p. 4"
ssb_values <- c(545, 85, 91)
ssb_cvs <- c(0.18, 0.19, 0.19)
b59_values <- c(153, 86, 62)
b59_cvs <- c(0.24, 0.09, 0.13)
summary_years <- c(1975L, 2016L, 2021L)
outputs <- rbind(
  output_block("SSB", ssb_values, summary_years, "kilotonnes", summary_source,
    notes = paste0("SCAA Bsp estimate; Hessian-based CV reported as ", ssb_cvs,
      ". CV retained in notes; source does not report a standard error or interval in this table.")),
  output_block("exploitable_biomass", b59_values, summary_years, "kilotonnes", summary_source,
    age_group = "5-9", notes = paste0("SCAA B5-9 estimate (biomass of ages 5-9); Hessian-based CV reported as ", b59_cvs,
      ". CV retained in notes; source does not report a standard error or interval in this table."))
)

if (anyDuplicated(paste(inputs$assessment_id, inputs$type, inputs$measure,
  inputs$survey, inputs$fleet, inputs$year, inputs$age)) ||
  nrow(inputs) < 1500L || nrow(outputs) != 6L ||
  any(nzchar(outputs$se)) || any(nzchar(outputs$lwr)) || any(nzchar(outputs$upr))) {
  stop("SCAA rows failed uniqueness, coverage, or uncertainty checks.", call. = FALSE)
}

candidate_update <- register[candidate_row, , drop = FALSE]
candidate_update$review_date <- "2026-11-04"
candidate_update$catch_age_evidence <- paste(
  "The 2023 SCAA base case has landings in kt from 1960-2021 and commercial catch numbers-at-age in thousands of fish, ages 0-10+, 1975-2021.",
  "The age-1 to 10+ series is in NAFO SCR 23/007 Table 2; the SCAA report Table B2 also reports age 0 as zero throughout."
)
candidate_update$survey_age_evidence <- paste(
  "The 2023 SCAA base case uses six survey series with mean numbers per tow at ages 0-10+ and mean-weight-per-tow biomass indices.",
  "The SCAA retains 2J3K ages 8+ in 2018, 2019 and 2021; these cells are excluded only from the companion SSM fit."
)
candidate_update$weights_evidence <- "The SCAA report provides catch weights-at-age in kg for ages 0-10+, 1975-2021; these are the only age-specific fish-mass inputs reported and are used by the SCAA methodology."
candidate_update$maturity_evidence <- "The SCAA report Table B4 provides a fixed ogive: ages 1-9 are immature and ages 10-14+ are mature. This maturity input is specific to the SCAA event and is not added to the SSM record."
candidate_update$mortality_evidence <- "The 2023 SCAA base case fixes M at 0.12 per year and steepness h at 0.80; the companion SSM also fixes M at 0.12."
candidate_update$timing_evidence <- "The SCAA biomass-index calculation adjusts for within-year survey timing, but the numerical survey timing values were not recovered; none are imputed."
candidate_update$output_evidence <- paste(
  "The SCAA report Table 1 gives SSB and exploitable biomass ages 5-9 for 1975, 2016 and 2021, with Hessian CVs.",
  "Full annual N-at-age, F-at-age, recruitment and SSB trajectories are shown in figures rather than numeric tables; the reported CVs are preserved in notes rather than converted to SEs."
)
candidate_update$detailed_source_url <- paste(
  "https://www.nafo.int/Portals/0/PDFs/sc/2026/scs26-12.pdf",
  "https://www.nafo.int/Portals/0/PDFs/sc/2023/scr23-014.pdf",
  "https://www.nafo.int/Portals/0/PDFs/sc/2023/scr23-008REV.pdf",
  "https://www.nafo.int/Portals/0/PDFs/sc/2023/scr23-007.pdf",
  "https://www.nafo.int/Portals/0/PDFs/sc/2017/scr17-002.pdf",
  "https://www.nafo.int/Portals/0/PDFs/com/2024/comdoc24-01REV.pdf",
  sep = "; "
)
candidate_update$decision_reason <- paste(
  "The current 2026 annual MP, 2023 SSM update and 2023 SCAA MSE operating model are represented as separate partial assessment events.",
  "The SCAA and SSM use separate model-specific input records; the SCAA report adds maturity and the EU 3M 0-700m series.",
  "Full annual numeric N/F/SSB/recruitment outputs and numerical survey timing remain unavailable in the reviewed SCAA source."
)
candidate_update$notes <- paste(
  "The latest 2026 annual advice applies the management procedure and sets the 2027 TAC; the 2023 SCAA and SSM fits were prepared for the MSE update and are not the annual advice models.",
  "Source PDFs, URLs, retrieval dates, and checksums are in source_cache/discovery_dfo_greenland_halibut_2_3klmno_2025/. See source_reviews/dfo_greenland_halibut_2_3klmno.md."
)

if (dry_run) {
  cat("Dry run validated ", nrow(assumptions), " SCAA assumptions, ", nrow(inputs),
    " SCAA inputs, and ", nrow(outputs), " SCAA outputs for ", scaa_id,
    ". Database and candidate register were not changed.\n", sep = "")
} else {
  append_rows <- function(rows, path) {
    utils::write.table(rows, path, sep = ",", quote = TRUE,
      row.names = FALSE, col.names = FALSE, append = TRUE, na = "")
  }
  append_rows(assessments, assessments_path)
  append_rows(assumptions, assumptions_path)
  append_rows(inputs, inputs_path)
  append_rows(outputs, outputs_path)
  register[candidate_row, ] <- candidate_update
  utils::write.csv(register, register_path, row.names = FALSE, na = "", fileEncoding = "UTF-8")
  cat("Imported ", scaa_id, ": ", nrow(assumptions), " assumptions, ",
    nrow(inputs), " inputs, and ", nrow(outputs), " selected SCAA summary outputs.\n", sep = "")
}
