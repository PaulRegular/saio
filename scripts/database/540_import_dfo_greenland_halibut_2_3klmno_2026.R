root <- "."
database <- file.path(root, "database")
cache <- file.path(root, "source_cache", "discovery_dfo_greenland_halibut_2_3klmno_2025")
dry_run <- identical(Sys.getenv("TINYAM_IMPORT_DRY_RUN"), "1")

manifest <- utils::read.csv(
  file.path(cache, "sources.csv"), stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE
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

for (file in manifest$file) {
  path <- file.path(cache, file)
  row <- match(file, manifest$file)
  size_mismatch <- "bytes" %in% names(manifest) && !is.na(manifest$bytes[row]) &&
    file.info(path)$size != as.numeric(manifest$bytes[row])
  if (!file.exists(path) || size_mismatch ||
    !identical(tolower(manifest$sha256[row]), sha256_file(path))) {
    stop("A cached NAFO PDF is missing or differs from its source manifest: ", file, call. = FALSE)
  }
}

ssm_path <- file.path(cache, "nafo_scr_23_014_ssm_mse_update_2023.pdf")
mp_path <- file.path(cache, "nafo_sc_report_26_12_2026.pdf")
ssm_pages <- pdftools::pdf_data(ssm_path)
ssm_text <- pdftools::pdf_text(ssm_path)
mp_pages <- pdftools::pdf_data(mp_path)
mp_text <- pdftools::pdf_text(mp_path)

parse_number <- function(x) {
  value <- gsub(",", "", paste0(x, collapse = ""))
  value <- gsub("[^0-9.\\-]", "", value)
  if (!nzchar(value) || identical(value, "-")) return(NA_real_)
  suppressWarnings(as.numeric(value))
}

extract_table_rows <- function(pages, page_numbers, years, n_values,
                               year_x_max = 130, x_max = 730,
                               y_min = 80, y_max = 720) {
  rows <- list()
  for (page_number in page_numbers) {
    page <- pages[[page_number]]
    year_words <- page[
      page$x <= year_x_max & page$text %in% as.character(years) &
        page$y >= y_min & page$y <= y_max, , drop = FALSE
    ]
    for (j in seq_len(nrow(year_words))) {
      y <- year_words$y[[j]]
      row <- page[abs(page$y - y) < 0.5 & page$x > year_x_max &
        page$x < x_max, , drop = FALSE]
      row <- row[order(row$x), , drop = FALSE]
      values <- row$text[grepl("^[0-9][0-9,.]*$", row$text)]
      if (length(values) != n_values) {
        stop("Unexpected source-table row at PDF page ", page_number,
          ", year ", year_words$text[[j]], ".", call. = FALSE)
      }
      row_values <- vapply(values, parse_number, numeric(1))
      row <- as.data.frame(as.list(row_values), stringsAsFactors = FALSE)
      names(row) <- paste0("v", seq_len(n_values))
      row$year <- as.integer(year_words$text[[j]])
      rows[[length(rows) + 1L]] <- row[, c("year", paste0("v", seq_len(n_values))), drop = FALSE]
    }
  }
  if (!length(rows)) stop("No rows were recovered from a source table.", call. = FALSE)
  do.call(rbind, rows)
}

extract_age_grid <- function(pages, page_numbers, years, n_ages,
                             year_x_max = 130, x_max = 730) {
  rows <- extract_table_rows(
    pages, page_numbers, years, n_values = n_ages,
    year_x_max = year_x_max, x_max = x_max
  )
  if (!setequal(unique(rows$year), years) || anyDuplicated(rows$year)) {
    stop("An age table has incomplete years or duplicate year rows.", call. = FALSE)
  }
  rows[order(rows$year), , drop = FALSE]
}

extract_age_survey <- function(pages) {
  section_y <- list(
    `18` = data.frame(y = c(130, 586), survey = c("Canada Autumn 2J3K", "Canada Autumn 3LNO")),
    `19` = data.frame(y = 396, survey = "Canada Spring 3LNO"),
    `20` = data.frame(y = c(160, 328, 658), survey = c("EU 3M 0-700m", "EU 3M 0-1400m", "EU-Spain 3NO")),
    `21` = data.frame(y = 463, survey = "EU-Spain 3LNO"),
    `22` = data.frame(y = 143, survey = "EU-Spain 3L")
  )
  age_x <- c(158, 190, 225, 261, 297, 338, 374, 410, 446, 482, 518)
  modeled_surveys <- c(
    "Canada Autumn 2J3K", "Canada Autumn 3LNO", "Canada Spring 3LNO",
    "EU 3M 0-1400m", "EU-Spain 3NO"
  )
  rows <- list()
  current_survey <- NULL

  for (page_number in 18:22) {
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

      numeric_words <- page[
        abs(page$y - y) <= 6 & page$x >= 145 & page$x <= 560 &
          grepl("^[0-9][0-9,.]*$", page$text), , drop = FALSE
      ]
      cells <- rep(NA_real_, length(age_x))
      assigned <- vapply(numeric_words$x, function(x) {
        distance <- abs(age_x - x)
        at <- which.min(distance)
        if (distance[[at]] <= 20) at else NA_integer_
      }, integer(1))
      for (age_index in seq_along(age_x)) {
        tokens <- numeric_words$text[assigned == age_index & !is.na(assigned)]
        if (length(tokens)) cells[[age_index]] <- parse_number(tokens)
      }
      rows[[length(rows) + 1L]] <- data.frame(
        survey = current_survey,
        year = as.integer(years_here$text[[1]]),
        age = 0:10,
        value = cells,
        stringsAsFactors = FALSE
      )
    }
  }

  out <- do.call(rbind, rows)
  key <- paste(out$survey, out$year, out$age, sep = "|")
  if (anyDuplicated(key) || any(!out$survey %in% modeled_surveys)) {
    stop("The base-case survey age table has duplicate or unexpected rows.", call. = FALSE)
  }
  out[order(out$survey, out$year, out$age), , drop = FALSE]
}

extract_mp_indices <- function(pages, page_text) {
  has_table_rows <- vapply(seq_along(pages), function(i) {
    page <- pages[[i]]
    has_year <- function(year) any(page$x < 125 & page$text == as.character(year) &
      page$y >= 350 & page$y <= 600)
    has_year(2011L) && has_year(2025L) && grepl("Table i.3", page_text[[i]], fixed = TRUE)
  }, logical(1))
  page_number <- which(has_table_rows)[1]
  if (is.na(page_number)) stop("Could not locate the 2026 MP input table.", call. = FALSE)
  page <- pages[[page_number]]
  years <- page[
    page$x < 125 & page$text %in% as.character(2011:2025) &
      page$y >= 350 & page$y <= 600, , drop = FALSE
  ]
  starts <- c(161, 242, 322, 406, 485)
  survey <- c(
    "Canada Autumn 2J3K", "Canada Autumn 3LNO", "EU-Spain 3L",
    "EU-Spain 3NO", "EU 3M 0-1400m"
  )
  region <- c("NAFO Divisions 2J3K", "NAFO Divisions 3LNO", "NAFO Division 3L", "NAFO Divisions 3NO", "NAFO Division 3M")
  out <- list()
  for (j in seq_len(nrow(years))) {
    y <- years$y[[j]]
    words <- page[abs(page$y - y) < 0.5 & page$x >= 145 & page$x <= 530, , drop = FALSE]
    assigned <- vapply(words$x, function(x) {
      distance <- abs(starts - x)
      at <- which.min(distance)
      if (distance[[at]] <= 24) at else NA_integer_
    }, integer(1))
    values <- rep(NA_real_, length(starts))
    for (i in seq_along(starts)) {
      tokens <- words$text[assigned == i & !is.na(assigned) & grepl("^[0-9][0-9,.]*$", words$text)]
      if (length(tokens)) values[[i]] <- parse_number(tokens)
    }
    out[[length(out) + 1L]] <- data.frame(
      survey = survey, region = region, year = as.integer(years$text[[j]]),
      value = values, stringsAsFactors = FALSE
    )
  }
  result <- do.call(rbind, out)
  result[!is.na(result$value), , drop = FALSE]
}

landings <- extract_table_rows(ssm_pages, 11:12, 1975:2021, 1L,
  year_x_max = 300, x_max = 700)
catch <- extract_age_grid(ssm_pages, 13:14, 1975:2021, 10L)
catch_weight <- extract_age_grid(ssm_pages, 15:16, 1975:2021, 10L)
survey_age <- extract_age_survey(ssm_pages)
excluded_survey_age <- survey_age$survey == "Canada Autumn 2J3K" &
  survey_age$year %in% c(2018L, 2019L, 2021L) & survey_age$age >= 8L
survey_age$reported_value <- survey_age$value
survey_age$excluded_from_fit <- excluded_survey_age
survey_age$value[excluded_survey_age] <- NA_real_
survey_age$source_notes <- ifelse(
  excluded_survey_age,
  paste0(
    "The source table reports ", survey_age$reported_value,
    ", but this age-8+ index was excluded from the fitted SSM because deep strata were not covered."
  ),
  ifelse(is.na(survey_age$value), "A blank source cell is preserved as missing.", "")
)
expected_excluded_values <- c(1.03, 0.45, 0.20, 0.41, 0.15, 0.13, 0.88, 0.35, 0.22)
if (sum(survey_age$excluded_from_fit) != 9L ||
  !identical(survey_age$reported_value[survey_age$excluded_from_fit], expected_excluded_values) ||
  any(!is.na(survey_age$value[survey_age$excluded_from_fit]))) {
  stop("Canada Autumn 2J3K age-8+ exclusions failed source checks.", call. = FALSE)
}
mp_index <- extract_mp_indices(mp_pages, mp_text)
recruitment <- extract_table_rows(ssm_pages, 24:25, 1975:2021, 3L, year_x_max = 190)
exploitable_biomass <- extract_table_rows(ssm_pages, 26:27, 1975:2021, 3L, year_x_max = 190)
fbar <- extract_table_rows(ssm_pages, 28:29, 1975:2021, 3L, year_x_max = 190)

if (nrow(landings) != 47L || nrow(catch) != 47L || nrow(catch_weight) != 47L ||
  nrow(recruitment) != 47L || nrow(exploitable_biomass) != 47L || nrow(fbar) != 47L ||
  !all(catch[["v5"]][catch$year == 1975L] == 334) ||
  !all(catch_weight[["v10"]][catch_weight$year == 2021L] == 2.64) ||
  !all(mp_index$value[mp_index$survey == "Canada Autumn 2J3K" & mp_index$year == 2025L] == 23.718) ||
  !all(mp_index$value[mp_index$survey == "EU 3M 0-1400m" & mp_index$year == 2025L] == 20.650) ||
  !all(recruitment[["v1"]][recruitment$year == 1975L] == 63.3) ||
  !all(exploitable_biomass[["v1"]][exploitable_biomass$year == 1975L] == 91.7)) {
  stop("Recovered Greenland halibut tables failed their source spot checks.", call. = FALSE)
}
if (!setequal(unique(survey_age$survey), c(
  "Canada Autumn 2J3K", "Canada Autumn 3LNO", "Canada Spring 3LNO",
  "EU 3M 0-1400m", "EU-Spain 3NO"
)) || anyDuplicated(paste(survey_age$survey, survey_age$year, survey_age$age))) {
  stop("Recovered Greenland halibut survey age rows do not match the SSM base case.", call. = FALSE)
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
register <- utils::read.csv(register_path, stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)

stock_id <- "dfo_greenland_halibut_2_3klmno"
mp_id <- paste0(stock_id, "_2026_mp")
ssm_id <- paste0(stock_id, "_2023_ssm")
candidate_id <- "DFO:Newfoundland and Labrador:Greenland Halibut (Turbot) - NAFO 2 + 3KLMNO"
candidate_row <- which(register$candidate_id == candidate_id)
candidate_identity_ok <- length(candidate_row) == 1L &&
  isTRUE(register$candidate_unit_id[candidate_row] == stock_id) &&
  isTRUE(register$eligibility[candidate_row] == "eligible")
candidate_unimported <- candidate_identity_ok &&
  isTRUE(register$match_status[candidate_row] == "new") &&
  isTRUE(register$import_status[candidate_row] == "not_started")
candidate_imported <- dry_run && candidate_identity_ok &&
  isTRUE(register$matched_stock_id[candidate_row] == stock_id) &&
  isTRUE(register$match_status[candidate_row] == "matched") &&
  isTRUE(register$import_status[candidate_row] == "partial")
if (!candidate_unimported && !candidate_imported) {
  stop("The Greenland halibut candidate identity or screening status has changed.", call. = FALSE)
}
if (!dry_run && (stock_id %in% stocks_existing$stock_id ||
  any(c(mp_id, ssm_id) %in% assessments_existing$assessment_id))) {
  stop("The Greenland halibut canonical records already exist; refusing a duplicate.", call. = FALSE)
}

assessment_exists <- function(path, ids) {
  con <- file(path, open = "rt")
  on.exit(close(con), add = TRUE)
  prefixes <- paste0('"', ids, '",')
  repeat {
    lines <- readLines(con, n = 50000L, warn = FALSE)
    if (!length(lines)) return(FALSE)
    if (any(vapply(prefixes, function(prefix) any(startsWith(lines, prefix)), logical(1)))) return(TRUE)
  }
}
if (!dry_run && any(vapply(c(assumptions_path, inputs_path, outputs_path), assessment_exists, logical(1), ids = c(mp_id, ssm_id)))) {
  stop("Canonical Greenland halibut child rows already exist.", call. = FALSE)
}

empty_rows <- function(template, n) {
  out <- as.data.frame(matrix("", nrow = n, ncol = ncol(template)), stringsAsFactors = FALSE)
  names(out) <- names(template)
  out
}
repeat_n <- function(x, n) {
  if (length(x) == 1L) rep(x, n) else if (length(x) == n) x else stop("A row field has an unexpected length.", call. = FALSE)
}
input_block <- function(assessment_id, type, measure, basis, value, unit, source_reference,
                        year = NA_integer_, age = NA_integer_, survey = "", fleet = "",
                        region = "", season = "", notes = "", source_type = "official_table") {
  n <- length(value)
  if (!n) stop("No values were recovered for input ", assessment_id, "/", measure, call. = FALSE)
  out <- empty_rows(inputs_existing, n)
  out$assessment_id <- assessment_id
  out$type <- type
  out$measure <- measure
  out$basis <- basis
  for (field in c("survey", "fleet", "region", "season", "notes", "source_type")) {
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
assumption_block <- function(assessment_id, component, setting, value, source_reference,
                             survey = "", region = "", notes = "") {
  n <- length(value)
  out <- empty_rows(assumptions_existing, n)
  out$assessment_id <- assessment_id
  out$component <- component
  out$setting <- setting
  out$value <- as.character(value)
  out$source_reference <- source_reference
  out$survey <- repeat_n(survey, n)
  out$region <- repeat_n(region, n)
  out$notes <- repeat_n(notes, n)
  out
}
output_block <- function(assessment_id, type, measure, value, unit, source_reference,
                         year, age = NA_integer_, age_group = "", survey = "", region = "", notes = "") {
  n <- length(value)
  out <- empty_rows(outputs_existing, n)
  out$assessment_id <- assessment_id
  out$type <- type
  out$measure <- measure
  out$survey <- repeat_n(survey, n)
  out$region <- repeat_n(region, n)
  out$year <- as.character(repeat_n(year, n))
  age <- repeat_n(age, n)
  out$age <- ifelse(is.na(age), "", as.character(age))
  out$age_group <- repeat_n(age_group, n)
  out$value <- as.character(value)
  out$unit <- unit
  out$source_type <- "official_table"
  out$source_reference <- source_reference
  out$notes <- repeat_n(notes, n)
  out
}

stock <- empty_rows(stocks_existing, 1L)
stock$stock_id <- stock_id
stock$charbonneau_id <- ""
stock$authority <- "DFO/NAFO"
stock$authority_stock_id <- "NAFO Subarea 2 + Divisions 3KLMNO"
stock$scientific_name <- "Reinhardtius hippoglossoides"
stock$common_name <- "Greenland halibut"
stock$area <- "NAFO Subarea 2 + Divisions 3KLMNO"
stock$region <- "Newfoundland and Labrador / NAFO Regulatory Area"
stock$ocean <- "Northwest Atlantic"
stock$notes <- paste(
  "Transboundary DFO/NAFO management unit. Distinct from DFO Gulf of St. Lawrence 4RST Greenland halibut and Greenland Subarea 1 units.",
  "The 2026 annual TAC advice is generated by a management procedure; the separately recorded 2023 state-space model update was prepared for MSE and was not applied for the current advice."
)

assessments <- empty_rows(assessments_existing, 2L)
assessments$assessment_id <- c(mp_id, ssm_id)
assessments$stock_id <- stock_id
assessments$assessment_year <- c("2026", "2023")
assessments$terminal_year <- c("2025", "2021")
assessments$estimate_terminal_year <- c("2025", "2021")
assessments$assessment_type <- c("annual management procedure update", "management strategy evaluation update")
assessments$model_family <- c("Management Procedure", "State-space model")
assessments$model_version <- c("Procedure adopted 2024", "NAFO SSM base case 3NO")
assessments$is_current <- c("TRUE", "FALSE")
assessments$is_applied <- c("TRUE", "FALSE")
assessments$framework_year <- c("2024", "2017")
assessments$assessment_url <- c(
  "https://www.nafo.int/Portals/0/PDFs/sc/2026/scs26-12.pdf",
  "https://www.nafo.int/Portals/0/PDFs/sc/2023/scr23-014.pdf"
)
assessments$framework_url <- c(
  "https://www.nafo.int/Portals/0/PDFs/com/2024/comdoc24-01REV.pdf",
  "https://www.nafo.int/Portals/0/PDFs/sc/2023/scr23-014.pdf"
)
assessments$assumptions_status <- c("partial", "partial")
assessments$inputs_status <- c("partial", "partial")
assessments$outputs_status <- c("partial", "partial")
assessments$notes <- c(
  "The 2026 Scientific Council report applies the 2024-adopted management procedure to determine the TAC for 2027 from five survey indices through 2025. It is not a refit of an age-structured population model; population-at-age outputs are not reported.",
  "The 2023 SSM base case updates the age-structured model through 2021 for MSE work. Its age-specific input tables and selected annual outputs are recorded separately from the current management procedure; no age-specific fitted N or F array is tabulated."
)

mp_source <- "NAFO Scientific Council Report 2026, SCS Doc. 26/12, Table i.3, pp. 34-35"
ssm_base <- "NAFO SCR Doc. 23/014, SSM base case (3NO)"
input_rows <- list(
  input_block(
    mp_id, "index", "relative_biomass_index", "index_scale", mp_index$value,
    "kg per tow", mp_source, year = mp_index$year, survey = mp_index$survey,
    region = mp_index$region,
    season = ifelse(grepl("Canada Autumn", mp_index$survey), "Autumn", ""),
    notes = "Annual mean-weight-per-tow index used by the adopted management procedure. The source leaves survey-year gaps blank; no value or scaling factor is imputed. The 2023 SSM Table 5 reports the same index family in kg per tow."
  ),
  input_block(
    ssm_id, "catch", "landings_biomass", "biomass", landings$v1,
    "kilotonnes", "NAFO SCR Doc. 23/014, Table 2, pp. 11-12",
    year = landings$year, fleet = "NAFO commercial fishery",
    notes = "Landings series used by the SSM from 1975 onward; the source table reports kilotonnes."
  ),
  input_block(
    ssm_id, "catch", "numbers_at_age", "numbers", as.vector(t(as.matrix(catch[, -1]))),
    "thousand fish", "NAFO SCR Doc. 23/014, Table 3, pp. 13-14",
    year = rep(catch$year, each = 10L), age = rep(c(1:9, 10L), times = nrow(catch)),
    fleet = "NAFO commercial fishery",
    notes = "The source reports age 10 as 10+. Values are catch numbers-at-age in thousands of fish."
  ),
  input_block(
    ssm_id, "catch_weight", "catch_weight_at_age", "kg_per_fish",
    as.vector(t(as.matrix(catch_weight[, -1]))), "kg per fish",
    "NAFO SCR Doc. 23/014, Table 4, pp. 15-16",
    year = rep(catch_weight$year, each = 10L), age = rep(c(1:9, 10L), times = nrow(catch_weight)),
    fleet = "NAFO commercial fishery",
    notes = "The source reports age 10 as 10+. These are catch weights, not stock/spawning weights."
  ),
  input_block(
    ssm_id, "index", "numbers_at_age", "index_scale", survey_age$value,
    "mean number per tow", "NAFO SCR Doc. 23/014, Table 6, pp. 18-22",
    year = survey_age$year, age = survey_age$age, survey = survey_age$survey,
    region = ifelse(grepl("2J3K", survey_age$survey), "NAFO Divisions 2J3K",
      ifelse(grepl("3LNO", survey_age$survey), "NAFO Divisions 3LNO",
        ifelse(grepl("3M", survey_age$survey), "NAFO Division 3M", "NAFO Divisions 3NO"))),
    season = ifelse(grepl("Autumn", survey_age$survey), "Autumn",
      ifelse(grepl("Spring", survey_age$survey), "Spring", "")),
    notes = paste(
      "SSM 3NO base-case series; the source reports age 10 as 10+.",
      survey_age$source_notes
    )
  ),
  input_block(
    ssm_id, "M", "natural_mortality_at_age", "per_year", rep(0.12, 10L),
    "per year", "NAFO SCR Doc. 23/014, Table 1, p. 10",
    age = 1:10, notes = "Fixed natural mortality M=0.12 per year for ages 1-10+; age 10 represents the 10+ group.",
    source_type = "official_document"
  )
)
inputs <- do.call(rbind, input_rows)

control_values <- data.frame(
  setting = c("MP adoption year", "MP response strength gamma", "MP status period q",
    "MP target alpha", "MP lambda up", "MP lambda down", "MP slope offset X",
    "MP maximum TAC increase", "MP maximum TAC decrease", "exceptional circumstances 2026"),
  value = c("2024", "0.15", "3 years", "0.972", "1", "2", "-0.0056", "0.10", "0.10", "not occurring"),
  stringsAsFactors = FALSE
)
mp_assumptions <- assumption_block(
  mp_id, "management_procedure", control_values$setting, control_values$value,
  "NAFO Scientific Council Report 2026, SCS Doc. 26/12, pp. 32-35"
)
mp_assumptions <- rbind(mp_assumptions, assumption_block(
  mp_id, "management_procedure", "MP combination parameter mu", "0.963",
  "NAFO Scientific Council Report 2026, SCS Doc. 26/12, Table i.2, p. 35"
))
mp_survey <- c("Canada Autumn 2J3K", "Canada Autumn 3LNO", "EU-Spain 3L", "EU-Spain 3NO", "EU 3M 0-1400m")
mp_sigma <- c(0.230, 0.254, 0.239, 0.405, 0.299)
mp_weights <- c(18.904, 15.500, 17.507, 6.097, 11.186)
mp_assumptions <- rbind(mp_assumptions,
  assumption_block(mp_id, "survey", "MP survey log-index residual SD", mp_sigma,
    "NAFO Scientific Council Report 2026, SCS Doc. 26/12, Table i.3, p. 35", survey = mp_survey,
    notes = "Estimated in the SCAA base-case operating-model fit; the MP weights surveys by inverse squared SD."),
  assumption_block(mp_id, "survey", "MP inverse-variance survey weight", mp_weights,
    "NAFO Scientific Council Report 2026, SCS Doc. 26/12, Table i.3, p. 35", survey = mp_survey,
    notes = "Source-reported 1/sigma^2 values; retained as MP control weights, not tinyAM observation weights."),
  assumption_block(mp_id, "management_procedure", "MP index calculation", "Target rule averages the latest 3 available years; target is the 2011-2015 mean; slope uses a log-linear trend over the latest 5 available years; missing survey values are omitted.",
    "NAFO Scientific Council Report 2026, SCS Doc. 26/12, pp. 32-35"),
  assumption_block(mp_id, "management_procedure", "MP output scope", "Annual survey-based TAC advice; no age-structured population model was refit for the 2026 advice.",
    "NAFO Scientific Council Report 2026, SCS Doc. 26/12, pp. 32-35")
)

ssm_assumption_values <- data.frame(
  setting = c("model years and ages", "base-case survey series", "recruitment process",
    "natural mortality", "fixed fishing mortality", "estimated fishing mortality",
    "survey timing", "survey observation error", "process structure"),
  value = c(
    "1975-2021; ages 1-10+",
    paste(c("Canada Autumn 2J3K", "Canada Autumn 3LNO", "Canada Spring 3LNO", "EU-Spain 3NO", "EU 3M 0-1400m"), collapse = "; "),
    "Age-1 recruitment with a cohort state-space process; mean log recruitment estimated.",
    "M=0.12 per year, fixed.",
    "F is fixed at zero for ages 1-2.",
    "F is estimated for ages 3-10+.",
    "Each survey observation is adjusted using the survey-year midpoint as a fraction of year; the numeric midpoint series was not tabulated.",
    "Age-specific mean survey observation error with deviations coupled across ages 1-3, 4-7, and 8-10+.",
    "State-space model with cohort process error and correlated F process across age/year."
  ),
  stringsAsFactors = FALSE
)
ssm_assumptions <- assumption_block(
  ssm_id, "population", ssm_assumption_values$setting, ssm_assumption_values$value,
  "NAFO SCR Doc. 23/014, Tables 1 and 6, pp. 10 and 18-22; Appendix A"
)
assumptions <- rbind(mp_assumptions, ssm_assumptions)

ssm_outputs <- rbind(
  output_block(ssm_id, "recruitment", "recruitment", recruitment[["v1"]],
    "million fish", "NAFO SCR Doc. 23/014, Tables 8, pp. 24-25",
    year = recruitment$year, age = 1,
    notes = "Age-1 recruitment from the 3NO base case; rounded values as printed. No uncertainty is tabulated in this table."),
  output_block(ssm_id, "biomass", "exploitable_biomass", exploitable_biomass[["v1"]],
    "kilotonnes", "NAFO SCR Doc. 23/014, Table 9, pp. 26-27",
    year = exploitable_biomass$year, age_group = "5-9",
    notes = "Exploitable biomass of ages 5-9, not total biomass or SSB; rounded values as printed. No uncertainty is tabulated in this table."),
  output_block(ssm_id, "mortality", "Fbar", fbar[["v1"]],
    "per year", "NAFO SCR Doc. 23/014, Table 10, pp. 28-29",
    year = fbar$year, age_group = "5-9",
    notes = "Mean fishing mortality over ages 5-9 in the 3NO base case; rounded values as printed. No uncertainty is tabulated in this table.")
)
mp_output <- output_block(
  mp_id, "catch", "catch_advice", 14351, "tonnes",
  "NAFO Scientific Council Report 2026, SCS Doc. 26/12, pp. 32-35",
  year = 2027,
  notes = "Final TAC recommended for 2027 by the adopted management procedure; this is catch advice, not a population estimate. Exceptional circumstances were not occurring."
)
outputs <- rbind(mp_output, ssm_outputs)

candidate_update <- register[candidate_row, , drop = FALSE]
candidate_update$matched_stock_id <- stock_id
candidate_update$match_status <- "matched"
candidate_update$inventory_assessment_year <- 2026L
candidate_update$import_status <- "partial"
candidate_update$review_date <- "2026-11-02"
candidate_update$catch_age_evidence <- paste(
  "The 2023 NAFO SSM update reports commercial catch numbers-at-age in thousands of fish, ages 1-10+, 1975-2021; its SSM base-case catch weights-at-age are also tabulated.",
  "This age model was updated for MSE, not used to calculate the 2026 TAC advice."
)
candidate_update$survey_age_evidence <- paste(
  "The 2023 SSM Table 6 reports mean numbers per tow at ages 0-10+ for five base-case surveys, with survey-specific year coverage.",
  "Ages 8+ for Canada Autumn 2J3K in 2018, 2019 and 2021 are excluded from the SSM because deep strata were not covered.",
  "The 2026 MP input table reports annual mean-weight-per-tow indices through 2025 for all five survey series."
)
candidate_update$weights_evidence <- "The 2023 SSM update reports commercial catch weights-at-age in kg, ages 1-10+, 1975-2021. Stock/spawning weights and maturity are not in the SSM base-case inputs reviewed here."
candidate_update$maturity_evidence <- "A maturity-at-age vector is not used by the 2023 SSM input specification and was not recovered for that model. The SCAA companion report has a separate maturity table; it was not mixed into the SSM event."
candidate_update$mortality_evidence <- "The 2023 SSM base case fixes M at 0.12 per year; F is fixed at zero for ages 1-2 and estimated for ages 3-10+."
candidate_update$timing_evidence <- "The SSM observation equation uses survey-year midpoints as fractions of year, but exact numeric timing values are not tabulated. The current MP uses annual survey indices and does not report a fractional timing input."
candidate_update$output_evidence <- paste(
  "The current 2026 MP advice sets a 2027 TAC of 14,351 t and reports no exceptional circumstances.",
  "The 2023 SSM tables report recruitment at age 1, exploitable biomass ages 5-9, and mean F ages 5-9; numeric N-at-age, F-at-age, SSB, and uncertainty arrays were not tabulated."
)
candidate_update$detailed_source_url <- paste(
  "https://www.nafo.int/Portals/0/PDFs/sc/2026/scs26-12.pdf",
  "https://www.nafo.int/Portals/0/PDFs/sc/2023/scr23-014.pdf",
  "https://www.nafo.int/Portals/0/PDFs/sc/2023/scr23-008REV.pdf",
  "https://www.nafo.int/Portals/0/PDFs/com/2024/comdoc24-01REV.pdf",
  sep = "; "
)
candidate_update$decision_reason <- paste(
  "The current 2026 annual MP update and 2023 age-structured SSM MSE update are imported as separate partial assessment events.",
  "The current MP's survey index table and final TAC are distinct from the SSM's catch, survey-age, weight, mortality, and selected output tables.",
  "No current age-structured population fit or full numeric N/F/SSB surfaces are available in the reviewed sources."
)
candidate_update$notes <- paste(
  "The 2026 NAFO Scientific Council report is the latest official update found and recommends the 2027 TAC using all five survey series; TAC=14,351 t.",
  "The 2023 SSM update is the latest detailed age-structured model source located; it was prepared for MSE and is not the production annual TAC model.",
  "Source PDFs, URLs, retrieval dates, and checksums are in source_cache/discovery_dfo_greenland_halibut_2_3klmno_2025/. See source_reviews/dfo_greenland_halibut_2_3klmno_2025.md."
)

if (nrow(inputs) < 1500L || anyDuplicated(paste(inputs$assessment_id, inputs$survey, inputs$year, inputs$age, inputs$measure))) {
  stop("Greenland halibut input rows failed count or uniqueness checks.", call. = FALSE)
}

append_rows <- function(rows, path) {
  utils::write.table(rows, path, sep = ",", quote = TRUE,
    row.names = FALSE, col.names = FALSE, append = TRUE, na = "")
}

if (dry_run) {
  cat("Dry run validated ", nrow(assumptions), " assumptions, ", nrow(inputs),
    " inputs, and ", nrow(outputs), " outputs for ", stock_id,
    ". Database and candidate register were not changed.\n", sep = "")
} else {
  append_rows(stock, stocks_path)
  append_rows(assessments, assessments_path)
  append_rows(assumptions, assumptions_path)
  append_rows(inputs, inputs_path)
  append_rows(outputs, outputs_path)
  register[candidate_row, ] <- candidate_update
  utils::write.csv(register, register_path, row.names = FALSE, na = "", fileEncoding = "UTF-8")
  cat("Imported ", stock_id, ": two separate partial assessment events, ",
    nrow(assumptions), " assumptions, ", nrow(inputs), " inputs, and ",
    nrow(outputs), " outputs.\n", sep = "")
}
