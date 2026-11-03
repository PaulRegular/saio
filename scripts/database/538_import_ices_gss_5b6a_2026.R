root <- "."
database <- file.path(root, "database")
cache <- file.path(root, "source_cache", "discovery_ices_gss_5b6a_2026")
assessment_id <- "ices_greater_silver_smelt_5b6a_2026"
stock_id <- "ices_greater_silver_smelt_5b6a"
candidate_id <- "ICES:aru.27.5b6a"
report_url <- "https://doi.org/10.17895/ices.pub.32051352.v1"
taf_revision <- "7b7436c9e90c66c18411b7bf53bdf3ff096e5b33"
taf_url <- paste0(
  "https://github.com/ices-advice/2026_aru.27.5b6a/tree/",
  taf_revision
)
pdf_path <- file.path(cache, "WGDEEP_2026_v1.pdf")
manifest <- utils::read.csv(
  file.path(cache, "sources.csv"),
  stringsAsFactors = FALSE,
  na.strings = c("", "NA"),
  check.names = FALSE
)

pdf_row <- match("WGDEEP_2026_v1.pdf", manifest$file)
if (is.na(pdf_row) || !file.exists(pdf_path) ||
  file.info(pdf_path)$size != as.numeric(manifest$bytes[pdf_row])) {
  stop("The cached WGDEEP report is missing or has changed size.", call. = FALSE)
}
sha256_file <- function(path) {
  result <- system2(
    "certutil.exe",
    c("-hashfile", shQuote(normalizePath(path, winslash = "\\")), "SHA256"),
    stdout = TRUE
  )
  hashes <- tolower(trimws(grep(
    "^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$",
    result,
    value = TRUE
  )))
  if (length(hashes) != 1L) stop("Could not verify the cached PDF checksum.", call. = FALSE)
  hashes
}
if (!identical(tolower(manifest$sha256[pdf_row]), sha256_file(pdf_path))) {
  stop("The cached WGDEEP PDF checksum does not match the source manifest.", call. = FALSE)
}

read_pdf_pages <- function(pages) {
  subset_path <- tempfile(fileext = ".pdf")
  on.exit(unlink(subset_path), add = TRUE)
  invisible(pdftools::pdf_subset(pdf_path, subset_path, pages = pages))
  pdftools::pdf_data(subset_path)
}

parse_number <- function(x) {
  x <- gsub("[^0-9.\\-]", "", paste0(x, collapse = ""))
  suppressWarnings(as.numeric(x))
}

cells_on_row <- function(page, y, column_starts, x_min, tolerance = 20) {
  row <- page[abs(page$y - y) < 0.5 & page$x > x_min, , drop = FALSE]
  row <- row[order(row$x), , drop = FALSE]
  cell <- vapply(row$x, function(x) {
    distance <- abs(column_starts - x)
    at <- which.min(distance)
    if (distance[at] <= tolerance) at else NA_integer_
  }, integer(1))
  out <- rep(NA_real_, length(column_starts))
  for (i in seq_along(column_starts)) {
    pieces <- row$text[cell == i & !is.na(cell)]
    if (length(pieces)) out[i] <- parse_number(pieces)
  }
  out
}

extract_age_table <- function(pages, years, ages, year_x_max,
                              column_starts, regions = list()) {
  pdf_pages <- read_pdf_pages(pages)
  rows <- list()
  for (i in seq_along(pdf_pages)) {
    page_number <- pages[[i]]
    page <- pdf_pages[[i]]
    region <- regions[[as.character(page_number)]]
    if (is.null(region)) region <- c(-Inf, Inf)
    year_words <- page[
      page$x <= year_x_max &
        page$text %in% as.character(years) &
        page$y >= region[[1]] & page$y <= region[[2]],
      , drop = FALSE
    ]
    for (j in seq_len(nrow(year_words))) {
      year <- as.integer(year_words$text[[j]])
      values <- cells_on_row(
        page, year_words$y[[j]], column_starts,
        x_min = year_x_max, tolerance = 20
      )
      rows[[length(rows) + 1L]] <- data.frame(
        year = year, age = ages, value = values
      )
    }
  }
  out <- do.call(rbind, rows)
  out <- out[is.finite(out$value), , drop = FALSE]
  out$year <- as.integer(out$year)
  out$age <- as.integer(out$age)
  cell_key <- paste(out$year, out$age, sep = "|")
  if (anyDuplicated(cell_key)) {
    duplicate_cells <- unique(cell_key[duplicated(cell_key)])
    stop(
      "The PDF table on pages ", paste(pages, collapse = ", "),
      " yielded duplicate year-age cells: ",
      paste(head(duplicate_cells, 8L), collapse = ", "),
      call. = FALSE
    )
  }
  if (!all(years %in% out$year)) {
    stop("The PDF table does not cover all expected years.", call. = FALSE)
  }
  out
}

catch_numbers <- extract_age_table(
  pages = c(355L, 356L),
  years = 1995:2025,
  ages = 5:21,
  year_x_max = 45,
  column_starts = c(68, 115, 163, 210, 258, 305, 356, 404, 451,
                    499, 546, 587, 629, 670, 712, 753, 794)
)
catch_weights <- extract_age_table(
  pages = 357L:362L,
  years = 1995:2025,
  ages = 5:9,
  year_x_max = 120,
  column_starts = c(226, 342, 439, 535, 651),
  regions = list("362" = c(-Inf, 200))
)
summer_index <- extract_age_table(
  pages = 362L:364L,
  years = 1998:2025,
  ages = 5:12,
  year_x_max = 120,
  column_starts = c(244, 309, 373, 437, 502, 566, 631, 695),
  regions = list("362" = c(380, Inf), "364" = c(-Inf, 200))
)
deepwater_index <- extract_age_table(
  pages = 364L,
  years = c(2014:2020, 2022:2025),
  ages = 5:14,
  year_x_max = 120,
  column_starts = c(202, 258, 313, 369, 425, 481, 537, 593, 648, 704),
  regions = list("364" = c(250, Inf))
)
deepwater_index <- deepwater_index[deepwater_index$value >= 0, , drop = FALSE]
f_at_age <- extract_age_table(
  pages = 370L:372L,
  years = 1995:2025,
  ages = 5:21,
  year_x_max = 100,
  column_starts = c(118, 152, 190, 228, 266, 304, 342, 380, 418,
                    456, 494, 532, 570, 608, 646, 684, 722),
  regions = list("370" = c(320, Inf), "372" = c(-Inf, 220))
)
n_at_age <- extract_age_table(
  pages = 372L:374L,
  years = 1995:2025,
  ages = 5:21,
  year_x_max = 100,
  column_starts = c(117, 153, 192, 231, 270, 313, 352, 391, 430,
                    469, 508, 547, 582, 618, 653, 689, 724),
  regions = list("372" = c(250, Inf))
)
n_at_age <- n_at_age[n_at_age$value >= 0, , drop = FALSE]

pdf_362 <- read_pdf_pages(362L)[[1]]
maturity_y <- unique(pdf_362$y[pdf_362$text == "Prop"])
age_header_y <- NA_real_
if (length(maturity_y) == 1L) {
  age_header_candidates <- pdf_362$y[
    pdf_362$text == "Year/Age" & pdf_362$y < maturity_y
  ]
  if (length(age_header_candidates)) age_header_y <- max(age_header_candidates)
}
if (!is.finite(age_header_y)) {
  stop("Could not identify the maturity vector and age header.", call. = FALSE)
}
age_headers <- pdf_362[
  abs(pdf_362$y - age_header_y) < 0.5 & pdf_362$x > 130,
  , drop = FALSE
]
age_headers <- age_headers[order(age_headers$x), , drop = FALSE]
maturity_ages <- as.integer(gsub("\\+", "", age_headers$text))
maturity_values <- cells_on_row(
  pdf_362, maturity_y, age_headers$x,
  x_min = 130, tolerance = 5
)
maturity <- data.frame(age = maturity_ages, value = maturity_values)
if (!identical(maturity_ages, 5:21) || any(!is.finite(maturity$value))) {
  stop("The printed maturity-at-age vector is incomplete.", call. = FALSE)
}

extract_scalar_table <- function(pages, years, year_x_max, value_x,
                                 regions = list(), tolerance = 22) {
  pdf_pages <- read_pdf_pages(pages)
  rows <- list()
  for (i in seq_along(pdf_pages)) {
    page_number <- pages[[i]]
    page <- pdf_pages[[i]]
    region <- regions[[as.character(page_number)]]
    if (is.null(region)) region <- c(-Inf, Inf)
    year_words <- page[
      page$x <= year_x_max &
        page$text %in% as.character(years) &
        page$y >= region[[1]] & page$y <= region[[2]],
      , drop = FALSE
    ]
    for (j in seq_len(nrow(year_words))) {
      row <- page[abs(page$y - year_words$y[[j]]) < 0.5, , drop = FALSE]
      candidates <- row[abs(row$x - value_x) <= tolerance, , drop = FALSE]
      if (!nrow(candidates)) next
      candidates <- candidates[order(candidates$x), , drop = FALSE]
      rows[[length(rows) + 1L]] <- data.frame(
        year = as.integer(year_words$text[[j]]),
        value = parse_number(candidates$text)
      )
    }
  }
  if (!length(rows)) return(data.frame(year = integer(), value = numeric()))
  out <- do.call(rbind, rows)
  out <- out[is.finite(out$value), , drop = FALSE]
  if (anyDuplicated(out$year)) stop("The scalar PDF table has duplicate years.", call. = FALSE)
  out
}

summer_effort <- extract_scalar_table(
  362L:364L, 1998:2025, 120, 151,
  regions = list("362" = c(380, Inf), "364" = c(-Inf, 200))
)
deepwater_effort <- extract_scalar_table(
  364L, c(2014:2020, 2022:2025), 120, 151,
  regions = list("364" = c(250, Inf))
)
scottish_index <- extract_scalar_table(
  366L, 1998:2025, 120, 231,
  regions = list("366" = c(160, Inf))
)
cpue_index <- extract_scalar_table(
  366L, 1998:2025, 120, 409,
  regions = list("366" = c(160, Inf))
)
scottish_index <- scottish_index[scottish_index$value >= 0, , drop = FALSE]
cpue_index <- cpue_index[cpue_index$value >= 0, , drop = FALSE]
summer_effort <- summer_effort[summer_effort$value >= 0, , drop = FALSE]
deepwater_effort <- deepwater_effort[deepwater_effort$value >= 0, , drop = FALSE]

summary_columns <- c(151, 214, 278, 356, 411, 462, 514, 584, 627, 672, 723)
summary_names <- c(
  "recruitment_low", "recruitment", "recruitment_high",
  "ssb_low", "ssb", "ssb_high", "landings", "discards",
  "fbar_low", "fbar", "fbar_high"
)
summary_pages <- read_pdf_pages(369L:370L)
summary_parts <- list()
for (i in seq_along(summary_pages)) {
  page_number <- 368L + i
  page <- summary_pages[[i]]
  region <- if (page_number == 370L) c(100, 260) else c(100, 800)
  year_words <- page[
    page$x <= 120 &
      page$text %in% as.character(1988:2026) &
      page$y >= region[[1]] & page$y <= region[[2]],
    , drop = FALSE
  ]
  for (j in seq_len(nrow(year_words))) {
    values <- cells_on_row(
      page, year_words$y[[j]], summary_columns,
      x_min = 120, tolerance = 22
    )
    names(values) <- summary_names
    summary_parts[[length(summary_parts) + 1L]] <- data.frame(
      year = as.integer(year_words$text[[j]]),
      as.list(values),
      check.names = FALSE
    )
  }
}
summary <- do.call(rbind, summary_parts)
summary <- summary[order(summary$year), , drop = FALSE]
if (anyDuplicated(summary$year) ||
  !all(1988:2026 %in% summary$year)) {
  stop("The assessment-summary table does not cover 1988-2026 exactly once.", call. = FALSE)
}
for (column in summary_names) summary[[column]] <- as.numeric(summary[[column]])

expected_catch_gaps <- c(
  "2003|20", "2004|20", "2005|19", "2005|20", "2006|20",
  "2006|21", "2007|19", "2007|21", "2018|20", "2018|21"
)
actual_catch_gaps <- setdiff(
  paste(rep(1995:2025, each = 17L), rep(5:21, times = 31L), sep = "|"),
  paste(catch_numbers$year, catch_numbers$age, sep = "|")
)
if (!setequal(actual_catch_gaps, expected_catch_gaps) ||
  nrow(catch_weights) != 31L * 5L ||
  nrow(summer_index) != 28L * 8L ||
  nrow(deepwater_index) != 11L * 10L ||
  nrow(f_at_age) != 31L * 17L ||
  nrow(n_at_age) != 31L * 17L - 10L || any(n_at_age$value < 0) ||
  nrow(scottish_index) != 18L ||
  nrow(cpue_index) != 21L ||
  nrow(summer_effort) != 28L ||
  nrow(deepwater_effort) != 11L) {
  stop(
    "The parsed series coverage differs from the reviewed 2026 report: ",
    paste(c(
      catch = nrow(catch_numbers), catch_gaps = length(actual_catch_gaps),
      weights = nrow(catch_weights),
      summer = nrow(summer_index), deepwater = nrow(deepwater_index),
      F_at_age = nrow(f_at_age), N_at_age = nrow(n_at_age),
      Scottish = nrow(scottish_index), CPUE = nrow(cpue_index),
      summer_effort = nrow(summer_effort), deepwater_effort = nrow(deepwater_effort)
    ), collapse = ", "),
    call. = FALSE
  )
}

value_at_age <- function(data, year, age) {
  data$value[data$year == year & data$age == age]
}
if (
  value_at_age(catch_numbers, 1995L, 9L) != 2459 ||
  value_at_age(catch_weights, 1995L, 5L) != 0.225 ||
  maturity$value[maturity$age == 5L] != 0.13 ||
  value_at_age(summer_index, 1998L, 5L) != 4.317 ||
  value_at_age(deepwater_index, 2014L, 5L) != 50.9 ||
  value_at_age(f_at_age, 1995L, 5L) != 0 ||
  value_at_age(f_at_age, 2025L, 21L) != 0.231 ||
  value_at_age(n_at_age, 1995L, 9L) != 2459 ||
  value_at_age(n_at_age, 2025L, 21L) != 575 ||
  scottish_index$value[scottish_index$year == 1998L] != 64.4 ||
  cpue_index$value[cpue_index$year == 2005L] != 13.54 ||
  summary$ssb[summary$year == 2025L] != 104178 ||
  summary$recruitment[summary$year == 2025L] != 117734 ||
  summary$fbar[summary$year == 2025L] != 0.188
) {
  stop("One or more parsed values differ from the published table examples.", call. = FALSE)
}

input_columns <- names(utils::read.csv(
  file.path(database, "inputs.csv"), nrows = 0, check.names = FALSE
))
output_columns <- names(utils::read.csv(
  file.path(database, "outputs.csv"), nrows = 0, check.names = FALSE
))
input_rows <- function(data, type, measure, basis, unit,
                       fleet = NA_character_, survey = NA_character_,
                       season = NA_character_, source_type = "official_table",
                       source_reference, transformation,
                       notes = "") {
  n <- nrow(data)
  out <- as.data.frame(matrix(NA_character_, n, length(input_columns)))
  names(out) <- input_columns
  out$assessment_id <- assessment_id
  out$type <- type
  out$measure <- measure
  out$basis <- basis
  out$fleet <- fleet
  out$survey <- survey
  out$region <- "ICES divisions 5.b and 6.a"
  out$season <- season
  out$year <- if ("year" %in% names(data)) {
    as.integer(data$year)
  } else {
    rep(NA_integer_, n)
  }
  out$year_basis <- ifelse(is.na(out$year), NA_character_, "calendar_year")
  out$age <- if ("age" %in% names(data)) {
    as.integer(data$age)
  } else {
    rep(NA_integer_, n)
  }
  out$value <- as.numeric(data$value)
  out$unit <- unit
  out$source_type <- source_type
  out$source_reference <- source_reference
  out$transformation <- transformation
  out$notes <- rep(notes, length.out = n)
  out
}
output_rows <- function(data, type, measure, unit, source_reference,
                        age = NA_integer_, age_group = NA_character_,
                        notes = "") {
  n <- nrow(data)
  out <- as.data.frame(matrix(NA_character_, n, length(output_columns)))
  names(out) <- output_columns
  out$assessment_id <- assessment_id
  out$type <- type
  out$measure <- measure
  out$year <- as.integer(data$year)
  if ("age" %in% names(data)) {
    out$age <- as.integer(data$age)
  } else {
    out$age <- rep(age, length.out = n)
  }
  out$age_group <- rep(age_group, length.out = n)
  out$value <- as.numeric(data$value)
  if ("lwr" %in% names(data)) out$lwr <- as.numeric(data$lwr)
  if ("upr" %in% names(data)) out$upr <- as.numeric(data$upr)
  out$unit <- unit
  out$source_type <- "official_table"
  out$source_reference <- source_reference
  out$notes <- rep(notes, length.out = n)
  out
}
new_assumption <- function(component, setting, value, source_reference,
                           notes = "", survey = NA_character_) {
  data.frame(
    assessment_id = assessment_id, component = component,
    fleet = NA_character_, survey = survey, sex = NA_character_,
    region = NA_character_, season = NA_character_, setting = setting,
    value = value, source_reference = source_reference, notes = notes,
    stringsAsFactors = FALSE
  )
}

stock <- data.frame(
  stock_id = stock_id,
  charbonneau_id = NA_character_,
  authority = "ICES",
  authority_stock_id = "aru.27.5b6a",
  scientific_name = "Argentina silus",
  common_name = "Greater silver smelt",
  area = "ICES divisions 5.b and 6.a",
  region = "Faroes grounds and west of Scotland",
  ocean = "Northeast Atlantic",
  notes = paste(
    "Current ICES management unit aru.27.5b6a.",
    "Distinct from aru.27.5a14, aru.27.123a4, and aru.27.6b7-1012."
  ),
  stringsAsFactors = FALSE
)
assessment <- data.frame(
  assessment_id = assessment_id,
  stock_id = stock_id,
  assessment_year = 2026L,
  terminal_year = 2025L,
  estimate_terminal_year = 2026L,
  assessment_type = "annual",
  model_family = "SAM",
  model_version = paste("ICES WGDEEP 2026 production run; TAF", taf_revision),
  is_current = TRUE,
  is_applied = TRUE,
  framework_year = 2021L,
  assessment_url = report_url,
  framework_url = NA_character_,
  data_url = report_url,
  model_url = taf_url,
  repository_url = taf_url,
  assumptions_status = "partial",
  inputs_status = "partial",
  outputs_status = "partial",
  notes = paste(
    "Current 2026 ICES production assessment for aru.27.5b6a.",
    "Data terminal year is 2025; the report also gives a 2026 stochastic recruitment forecast and SSB forecast."
  ),
  stringsAsFactors = FALSE
)

catch_numbers$notes <- ifelse(
  catch_numbers$age == 21L,
  "Age 21 is the 21+ group. Published table values are retained as printed.",
  "Published table values are retained as printed."
)
inputs <- rbind(
  input_rows(
    catch_numbers, "catch", "numbers_at_age", "numbers",
    "thousand fish", fleet = "Combined commercial catch-at-age",
    source_reference = paste0(report_url, "; Table 6.3.5, PDF pp. 355-356"),
    transformation = "Transcribed from the published catch-numbers-at-age table without numerical conversion.",
    notes = catch_numbers$notes
  ),
  input_rows(
    catch_weights, "catch_weight", "weight_at_age", "kg_per_fish",
    "kg per fish", fleet = "Commercial catch",
    source_reference = paste0(report_url, "; Table 6.3.6, PDF pp. 357-362"),
    transformation = "Transcribed from the published table without numerical conversion.",
    notes = "Published weights are tabulated only for ages 5-9; the report's weight plot is not digitized here. Age 21+ weights remain unavailable."
  ),
  input_rows(
    catch_weights, "weight", "weight_at_age", "kg_per_fish",
    "kg per fish",
    source_type = "reconstructed_source_input",
    source_reference = paste0(report_url, "; Table 6.3.6 and section 6.3.4.5"),
    transformation = "Copied the published catch weights to stock weights because the assessment report explicitly assumes stock weights equal catch weights.",
    notes = "Only ages 5-9 are represented because the full age-specific input file was not recovered; age 21+ weights remain unavailable."
  ),
  input_rows(
    maturity, "maturity", "maturity_at_age", "proportion",
    "proportion", source_reference = paste0(report_url, "; Table 6.3.7, PDF p. 362"),
    transformation = "Transcribed the fixed maturity proportions by age without numerical conversion.",
    notes = "Time-invariant maturity; age 21 is the 21+ group."
  ),
  input_rows(
    summer_index, "index", "numbers_at_age", "index_scale",
    "survey index (unit unresolved)",
    survey = "Faroese summer groundfish survey",
    season = "summer",
    source_reference = paste0(report_url, "; Table 6.3.8, PDF pp. 362-364"),
    transformation = "Transcribed finite age-specific index values; the report's -1 missing-value sentinel is omitted.",
    notes = "Ages 5-12. Values are on the reported index scale; the report does not state a physical unit. Exact annual timing fractions are not available."
  ),
  input_rows(
    deepwater_index, "index", "numbers_at_age", "index_scale",
    "survey index (unit unresolved)",
    survey = "Faroese deepwater survey",
    season = "autumn",
    source_reference = paste0(report_url, "; Table 6.3.9, PDF p. 364"),
    transformation = "Transcribed finite age-specific index values; the 2021 no-survey row (-1 sentinel) is omitted.",
    notes = "Ages 5-14; the report identifies the survey as occurring in September. Exact annual timing fractions are not available."
  ),
  input_rows(
    summer_effort, "covariate", "effort", "native_covariate",
    "reported effort (unit unspecified)",
    survey = "Faroese summer groundfish survey",
    season = "summer",
    source_reference = paste0(report_url, "; Table 6.3.8, PDF pp. 362-364"),
    transformation = "Transcribed the separate column labelled Effort; no conversion or interpretation as survey timing is applied.",
    notes = "The report and recovered TAF snapshot do not define the effort unit or establish that it is a within-year sampling fraction."
  ),
  input_rows(
    deepwater_effort, "covariate", "effort", "native_covariate",
    "reported effort (unit unspecified)",
    survey = "Faroese deepwater survey",
    season = "autumn",
    source_reference = paste0(report_url, "; Table 6.3.9, PDF p. 364"),
    transformation = "Transcribed the separate column labelled Effort; the 2021 no-survey sentinel is omitted.",
    notes = "The report and recovered TAF snapshot do not define the effort unit or establish that it is a within-year sampling fraction."
  ),
  input_rows(
    scottish_index, "index", "relative_biomass_index", "index_scale",
    "relative biomass index (unit unspecified)",
    survey = "Scottish MSS Deepwater Slope survey",
    source_reference = paste0(report_url, "; Table 6.3.10, PDF p. 366"),
    transformation = "Transcribed finite reported values; -1 indicates unavailable years and is omitted.",
    notes = "The series is an aggregate biomass index used in assessment tuning; no physical unit is stated in the report table."
  ),
  input_rows(
    cpue_index, "index", "relative_biomass_index", "index_scale",
    "relative CPUE index (unit unspecified)",
    survey = "Combined Faroese-EU CPUE",
    source_reference = paste0(report_url, "; Table 6.3.10, PDF p. 366"),
    transformation = "Transcribed finite reported values; blank years are omitted.",
    notes = "Standardized commercial CPUE input used in assessment tuning; the report table does not state a physical unit."
  )
)

landings <- summary[
  summary$year >= 1988L & summary$year <= 2025L &
    is.finite(summary$landings),
  c("year", "landings"), drop = FALSE
]
names(landings)[2] <- "value"
discards <- summary[
  summary$year >= 2014L & summary$year <= 2025L &
    is.finite(summary$discards),
  c("year", "discards"), drop = FALSE
]
names(discards)[2] <- "value"
landings_input <- input_rows(
  landings, "catch", "total_biomass", "biomass", "tonnes",
  fleet = "Combined landings, divisions 5.b and 6.a",
  source_reference = paste0(report_url, "; Table 6.4.13, PDF pp. 369-370"),
  transformation = "Transcribed the report's annual landings totals without numerical conversion.",
  notes = "Landings are source observations, not model-estimated catches. Values marked preliminary in 2025 remain identified in the notes."
)
landings_input$notes[landings_input$year == 2025L] <- paste(
  landings_input$notes[landings_input$year == 2025L],
  "The report marks 2025 landings as preliminary."
)
discards_input <- input_rows(
  discards, "catch", "total_biomass", "biomass", "tonnes",
  fleet = "Reported discards, divisions 5.b and 6.a",
  source_reference = paste0(report_url, "; Table 6.4.13, PDF pp. 369-370"),
  transformation = "Transcribed finite report values without numerical conversion.",
  notes = "The report table begins reporting discards in 2014; age allocation is not published. The 2025 value is preliminary."
)
inputs <- rbind(inputs, landings_input, discards_input)

summary_output <- summary[summary$year >= 1995L & summary$year <= 2026L, ]
ssb_data <- data.frame(
  year = summary_output$year,
  value = summary_output$ssb,
  lwr = summary_output$ssb_low,
  upr = summary_output$ssb_high
)
ssb_data <- ssb_data[is.finite(ssb_data$value), , drop = FALSE]
rec_data <- data.frame(
  year = summary_output$year,
  value = summary_output$recruitment,
  lwr = summary_output$recruitment_low,
  upr = summary_output$recruitment_high,
  age = 5L
)
rec_data <- rec_data[is.finite(rec_data$value), , drop = FALSE]
fbar_data <- data.frame(
  year = summary_output$year,
  value = summary_output$fbar,
  lwr = summary_output$fbar_low,
  upr = summary_output$fbar_high
)
fbar_data <- fbar_data[is.finite(fbar_data$value), , drop = FALSE]

f_at_age$notes <- ifelse(
  f_at_age$age == 21L,
  "Age 21 is the 21+ group; no age-specific uncertainty is published.",
  "Estimated fishing mortality at age; no age-specific uncertainty is published."
)
n_at_age$notes <- ifelse(
  n_at_age$age == 21L,
  "Age 21 is the terminal 21+ group; the report table omits the plus sign. No age-specific uncertainty is published.",
  "Estimated stock numbers at age; the report's -1 missing-value sentinel is omitted. No age-specific uncertainty is published."
)
outputs <- rbind(
  output_rows(
    n_at_age, "population", "numbers_at_age", "thousand fish",
    paste0(report_url, "; Table 6.4.15, PDF pp. 350-352"),
    notes = n_at_age$notes
  ),
  output_rows(
    f_at_age, "mortality", "fishing_mortality_at_age", "per year",
    paste0(report_url, "; Table 6.3.14, PDF pp. 370-374"),
    notes = f_at_age$notes
  ),
  output_rows(
    ssb_data, "biomass", "SSB", "tonnes",
    paste0(report_url, "; Table 6.4.13, PDF pp. 369-370"),
    notes = ifelse(
      ssb_data$year == 2026L,
      "2026 stochastic forecast; the report gives 95% low/high bounds.",
      "The report identifies low/high values as 95% confidence intervals."
    )
  ),
  output_rows(
    rec_data, "recruitment", "recruitment", "thousand fish",
    paste0(report_url, "; Table 6.4.13, PDF pp. 369-370"),
    notes = ifelse(
      rec_data$year == 2026L,
      "Recruitment at age 5; the report's 2026 value is the stochastic forecast mean from 2022-2024 and includes 95% bounds.",
      "Recruitment at age 5; low/high values are 95% confidence intervals."
    )
  ),
  output_rows(
    fbar_data, "mortality", "Fbar", "per year",
    paste0(report_url, "; Table 6.4.13, PDF pp. 369-370"),
    age_group = "6-14",
    notes = "Fishing mortality averaged over ages 6-14; the report identifies low/high values as 95% confidence intervals."
  )
)

assumptions <- do.call(rbind, list(
  new_assumption("assessment", "model_family", "SAM", report_url),
  new_assumption("assessment", "assessment_code", "2026_aru.27.5b6a_assessment", taf_url),
  new_assumption("assessment", "TAF_revision", taf_revision, taf_url),
  new_assumption("assessment", "benchmark_framework", "Benchmark adopted in 2020 and used for the SAM formulation", paste0(report_url, "; section 6.3.6"),
    "The 2026 report says the assessment was upgraded from a trend-based assessment to SAM following the benchmark."),
  new_assumption("population", "data_terminal_year", "2025", report_url),
  new_assumption("population", "age_range", "5-21+", report_url,
    "Age 21 is the plus group."),
  new_assumption("population", "model_start_year", "1995", report_url,
    "The SAM model is initiated in 1995."),
  new_assumption("recruitment", "recruitment_age", "5", report_url),
  new_assumption("catch", "catch_at_age_source", "1995-2004 Faroese sampling raised to international catches; 2005-2025 InterCatch age data from Faroe Islands and the Netherlands", report_url,
    "The published table has the catch-number-at-age series used in the assessment."),
  new_assumption("catch", "catch_age_TAF_adjustment", "The pinned 2026 TAF data.R rescales catch-at-age for 2018-2025 to reconcile calculated catch with SOPcorr totals", paste0("TAF data.R at ", taf_url),
    "The source table values are imported as printed. The TAF source catch-weight files needed to reproduce the year-specific scaling factors were not recovered, so no additional correction is applied to the canonical values."),
  new_assumption("survey", "age_specific_tuning", "Faroese summer survey ages 5-12; Faroese deepwater survey ages 5-14", paste0(report_url, "; Tables 6.3.8-6.3.9")),
  new_assumption("survey", "aggregate_tuning", "Scottish MSS Deepwater Slope biomass index and combined Faroese-EU standardized CPUE", paste0(report_url, "; Table 6.3.10")),
  new_assumption("survey", "sampling_time", "Exact annual sampling fractions not recovered", paste0(report_url, "; Tables 6.3.8-6.3.10; TAF data.R at ", taf_url),
    "Table columns are labelled Effort; their meaning and units are unresolved, so the values are retained separately and not used as sampling times."),
  new_assumption("survey", "survey_index_units", "Source index scale; physical units not stated", paste0(report_url, "; Tables 6.3.8-6.3.10")),
  new_assumption("weight", "catch_weight_at_age", "Tabulated for ages 5-9 in 1995-2025; full age-range weights are plotted but not digitized", paste0(report_url, "; Table 6.3.6 and Figure 6.3.8"),
    "The report cautions that weights for fish older than 15 in 2019 may be unreliable because of small age samples."),
  new_assumption("weight", "stock_weight_at_age", "Stock weights are assumed equal to catch weights", paste0(report_url, "; section 6.3.4.4"),
    "Canonical stock-weight rows are limited to the ages with published numeric catch weights, 5-9."),
  new_assumption("maturity", "maturity_at_age", "Fixed proportion-at-age vector for ages 5-21+", paste0(report_url, "; Table 6.3.7")),
  new_assumption("M", "natural_mortality", "Fixed M=0.15 for all ages and years", paste0(report_url, "; section 6.3.4.5")),
  new_assumption("mortality", "Fbar_ages", "6-14", paste0(report_url, "; Table 6.4.13")),
  new_assumption("uncertainty", "aggregate_output_bounds", "Table 6.4.13 reports 95% confidence intervals for recruitment, SSB, and Fbar", paste0(report_url, "; Table 6.4.13")),
  new_assumption("assessment", "native_model_files", "TAF code recovered; raw input files, fitted SAM object, and generated output files not recovered; selected N-at-age and F-at-age tables are published in the report", taf_url,
    "The public repository snapshot contains data/model scripts but not the referenced data files or fitted output objects. Tables 6.3.14 and 6.4.15 provide N-at-age and F-at-age point estimates.")
))

if (any(!is.finite(inputs$value)) || any(!is.finite(outputs$value)) ||
  anyDuplicated(paste(inputs$type, inputs$measure, inputs$fleet,
    inputs$survey, inputs$year, inputs$age, sep = "|")) ||
  anyDuplicated(paste(outputs$type, outputs$measure, outputs$fleet,
    outputs$year, outputs$age, outputs$age_group, sep = "|"))) {
  stop("The source rows contain missing values or duplicate series keys.", call. = FALSE)
}

stocks_path <- file.path(database, "stocks.csv")
assessments_path <- file.path(database, "assessments.csv")
assumptions_path <- file.path(database, "assumptions.csv")
inputs_path <- file.path(database, "inputs.csv")
outputs_path <- file.path(database, "outputs.csv")
register_path <- file.path(root, "discovery", "candidates.csv")
stocks_existing <- utils::read.csv(stocks_path, stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE
)
assessments_existing <- utils::read.csv(assessments_path, stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE
)
register <- utils::read.csv(register_path, stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE
)
candidate_row <- which(register$candidate_id == candidate_id)
if (length(candidate_row) != 1L ||
  register$candidate_unit_id[candidate_row] != stock_id ||
  register$official_stock_id[candidate_row] != "aru.27.5b6a" ||
  register$eligibility[candidate_row] != "eligible" ||
  register$match_status[candidate_row] != "new") {
  stop("The candidate-register identity or screening has changed.", call. = FALSE)
}
if (stock_id %in% stocks_existing$stock_id ||
  "aru.27.5b6a" %in% stocks_existing$authority_stock_id ||
  assessment_id %in% assessments_existing$assessment_id) {
  stop("The canonical greater silver smelt records already exist; refusing a duplicate.", call. = FALSE)
}
assessment_exists <- function(path) {
  con <- file(path, open = "rt")
  on.exit(close(con), add = TRUE)
  prefix <- paste0('"', assessment_id, '"')
  repeat {
    lines <- readLines(con, n = 50000L, warn = FALSE)
    if (!length(lines)) return(FALSE)
    if (any(startsWith(lines, prefix))) return(TRUE)
  }
}
if (any(vapply(
  c(assumptions_path, inputs_path, outputs_path),
  assessment_exists, logical(1)
))) {
  stop("Canonical child rows already exist for this assessment.", call. = FALSE)
}

update_candidate_line <- function(path, row) {
  new_line <- paste(capture.output(utils::write.table(
    row, file = "", sep = ",", quote = TRUE, row.names = FALSE,
    col.names = FALSE, na = ""
  )), collapse = "")
  text <- rawToChar(readBin(path, what = "raw", n = file.info(path)$size))
  line_match <- gregexpr(
    '(?m)^"ICES:aru\\.27\\.5b6a",[^\\r\\n]*(?=\\r?$)',
    text, perl = TRUE
  )[[1]]
  if (length(line_match) != 1L || line_match[[1]] < 0L) {
    stop("Could not safely locate the single candidate-register row.", call. = FALSE)
  }
  regmatches(text, list(line_match)) <- list(new_line)
  connection <- file(path, open = "wb")
  on.exit(close(connection), add = TRUE)
  writeBin(charToRaw(text), connection)
}

candidate_update <- register[candidate_row, , drop = FALSE]
candidate_update$matched_stock_id <- stock_id
candidate_update$import_status <- "partial"
candidate_update$review_date <- "2026-11-02"
candidate_update$catch_age_evidence <- paste(
  "Table 6.3.5 reports catch numbers-at-age for 1995-2025, ages 5-21+, in thousands.",
  "Ten age cells are blank in the published table and remain missing."
)
candidate_update$survey_age_evidence <- paste(
  "The Faroese summer survey table covers ages 5-12 in 1998-2025.",
  "The Faroese deepwater survey covers ages 5-14 in 2014-2020 and 2022-2025; 2021 is marked no survey.",
  "Scottish deepwater-slope and Faroese-EU CPUE series are aggregate indices."
)
candidate_update$weights_evidence <- paste(
  "Table 6.3.6 reports annual catch weights for ages 5-9 through 2025.",
  "The report assumes stock weights equal catch weights.",
  "Older-age values are plotted but not numerically tabulated and are not digitized."
)
candidate_update$output_evidence <- paste(
  "Tables 6.4.13, 6.3.14 and 6.4.15 provide SSB, recruitment, Fbar, F-at-age and N-at-age.",
  "Aggregate SSB, recruitment and Fbar include 95% intervals; age-specific N and F are point estimates."
)
candidate_update$decision_reason <- paste(
  "The 2026 current-unit assessment has been imported as partial.",
  "Catch-at-age has ten source blanks; numeric weights for ages 10-21+ and exact survey timing remain unavailable.",
  "Selected population and mortality outputs are recoverable from report tables."
)
candidate_update$notes <- paste(
  "The current 2026 assessment for aru.27.5b6a is recorded as a partial canonical record.",
  "See source_reviews/ices_greater_silver_smelt_5b6a_2026.md for provenance and remaining gaps."
)
candidate_test_path <- tempfile(fileext = ".csv")
if (!file.copy(register_path, candidate_test_path, overwrite = TRUE)) {
  stop("Could not prepare the candidate-register update check.", call. = FALSE)
}
update_candidate_line(candidate_test_path, candidate_update)
candidate_test <- utils::read.csv(candidate_test_path, stringsAsFactors = FALSE)
if (candidate_test$import_status[candidate_row] != "partial" ||
  candidate_test$matched_stock_id[candidate_row] != stock_id) {
  stop("The candidate-register update did not preserve its target values.", call. = FALSE)
}
unlink(candidate_test_path)

append_rows <- function(rows, path) {
  utils::write.table(
    rows, path, sep = ",", quote = TRUE, row.names = FALSE,
    col.names = FALSE, append = TRUE, na = ""
  )
}
if (identical(Sys.getenv("TINYAM_IMPORT_DRY_RUN"), "1")) {
  cat(
    "Dry run validated ", nrow(inputs), " input rows, ",
    nrow(outputs), " output rows and ", nrow(assumptions),
    " assumption rows; F-at-age has ", nrow(f_at_age),
    " rows and stock numbers-at-age has ", nrow(n_at_age),
    " rows. Canonical files were not changed.\n",
    sep = ""
  )
} else {
  append_rows(stock, stocks_path)
  append_rows(assessment, assessments_path)
  append_rows(assumptions, assumptions_path)
  append_rows(inputs, inputs_path)
  append_rows(outputs, outputs_path)
  update_candidate_line(register_path, candidate_update)
  cat(
    "Imported ", stock_id, ": ", nrow(inputs), " input rows, ",
    nrow(outputs), " output rows, and ", nrow(assumptions),
    " assumption rows. Completeness remains partial.\n",
    sep = ""
  )
}
