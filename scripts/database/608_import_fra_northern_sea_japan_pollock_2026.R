root <- "."
assessment_id <- "fra_northern_sea_japan_pollock_2026"
candidate_id <- "FRA:FRA-SA2026-SC01-01"
stock_id <- "fra_wpollock_northern_sea_japan"
report_rel <- "source_cache/fra_walleye_pollock_northern_sea_of_japan_2026/fra-sa2026-sc01-01.pdf"
report_path <- file.path(root, report_rel)
report_url <- "https://www.fra.go.jp/shigen/fisheries_resources/meeting/stock_assessment_meeting/2026/files/sa2026-sc01/fra-sa2026-sc01-01.pdf"
meeting_url <- "https://www.fra.go.jp/shigen/fisheries_resources/meeting/stock_assessment_meeting/2026/sa2026-sc01.html"
report_hash <- "5A7687624933147E2F4CDA62F25639EAFD468024C88402A7AFB1ADE7CF7269B4"
write_mode <- "--write" %in% commandArgs(trailingOnly = TRUE)

.libPaths(c(file.path(root, "tmp/Rlib"), .libPaths()))
if (!requireNamespace("pdftools", quietly = TRUE)) {
  stop("The source extraction requires pdftools.", call. = FALSE)
}
if (!file.exists(report_path) ||
    toupper(unname(tools::sha256sum(report_path))) != report_hash) {
  stop("The cached FRA report differs from the reviewed source.", call. = FALSE)
}

pdf_data <- pdftools::pdf_data(report_path)
number_pattern <- "^[0-9][0-9,]*(\\.[0-9]+)?$"
number_value <- function(x) as.numeric(gsub(",", "", x, fixed = TRUE))

parse_table6 <- function(pages) {
  age_tokens <- c(as.character(2:9), "10+")
  year_tokens <- as.character(1980:2025)
  age_rows <- list()
  total_rows <- list()

  for (page in 60:64) {
    z <- pages[[page]]
    candidate_y <- sort(unique(z$y[z$text %in% year_tokens]))
    header_y <- candidate_y[vapply(candidate_y, function(hy) {
      years <- as.integer(z$text[z$y == hy & z$text %in% year_tokens])
      length(years) >= 6L && all(diff(years) == 1L)
    }, logical(1L))]
    if (length(header_y) != 6L) {
      stop("Unexpected Table 6 year headers on PDF page ", page, ".", call. = FALSE)
    }

    for (table_no in seq_along(header_y)) {
      hy <- header_y[table_no]
      next_y <- if (table_no < length(header_y)) header_y[table_no + 1L] else Inf
      year_cells <- z[z$y == hy & z$text %in% year_tokens, , drop = FALSE]
      year_cells <- year_cells[order(year_cells$x + year_cells$width), , drop = FALSE]
      years <- as.integer(year_cells$text)
      if (!length(years)) stop("Table 6 has an empty year header.", call. = FALSE)

      labels <- z[z$x < 120 & z$text %in% age_tokens &
        z$y > hy & z$y < next_y, , drop = FALSE]
      row_y <- sort(unique(labels$y))
      if (length(row_y) != 9L) {
        stop("Unexpected age rows on Table 6 PDF page ", page, ".", call. = FALSE)
      }

      for (ry in row_y) {
        label <- labels[labels$y == ry, , drop = FALSE]
        label <- label[order(label$x), , drop = FALSE]
        cells <- z[abs(z$y - ry) <= 1 & z$x > 120 &
          grepl(number_pattern, z$text), , drop = FALSE]
        cells <- cells[order(cells$x + cells$width), , drop = FALSE]
        if (nrow(cells) != length(years)) {
          stop("Table 6 age row has a different number of values than years.",
            call. = FALSE)
        }
        age_value <- if (label$text[1L] == "10+") 10L else as.integer(label$text[1L])
        age_rows[[length(age_rows) + 1L]] <- data.frame(
          page = page, block = table_no, year = years, age = age_value,
          age_group = if (age_value == 10L) "10+" else "",
          value = number_value(cells$text), stringsAsFactors = FALSE
        )
      }

      total_label <- z[z$x < 120 & z$text == "\u8A08" &
        z$y > hy & z$y < next_y, , drop = FALSE]
      if (nrow(total_label)) {
        total_y <- unique(total_label$y)
        if (length(total_y) != 1L) stop("Duplicate Table 6 total labels.", call. = FALSE)
        cells <- z[abs(z$y - total_y) <= 1 & z$x > 120 &
          grepl(number_pattern, z$text), , drop = FALSE]
        cells <- cells[order(cells$x + cells$width), , drop = FALSE]
        if (nrow(cells) != length(years)) {
          stop("Table 6 total row has a different number of values than years.",
            call. = FALSE)
        }
        total_rows[[length(total_rows) + 1L]] <- data.frame(
          page = page, block = table_no, year = years,
          value = number_value(cells$text), stringsAsFactors = FALSE
        )
      }
    }
  }

  ages <- do.call(rbind, age_rows)
  totals <- do.call(rbind, total_rows)
  expected <- 46L * 6L * 9L
  if (nrow(ages) != expected || !setequal(unique(ages$year), 1980:2025) ||
      anyDuplicated(ages[c("block", "year", "age")])) {
    stop("Table 6 age-specific extraction failed coverage checks.", call. = FALSE)
  }
  expected_total_blocks <- c(1L, 2L, 4L, 5L, 6L)
  if (!setequal(unique(totals$block), expected_total_blocks) ||
      nrow(totals) != 46L * length(expected_total_blocks) ||
      anyDuplicated(totals[c("block", "year")])) {
    stop("Table 6 totals extraction failed coverage checks.", call. = FALSE)
  }
  list(ages = ages, totals = totals)
}

parse_paired_table <- function(z, year_range, y_range) {
  years <- as.character(year_range)
  year_rows <- z[z$text %in% years & z$y >= y_range[1L] &
    z$y <= y_range[2L], , drop = FALSE]
  out <- list()
  for (yy in sort(unique(year_rows$y))) {
    cells <- z[z$y == yy & z$y >= y_range[1L] & z$y <= y_range[2L] &
      (z$text %in% years | grepl(number_pattern, z$text)), , drop = FALSE]
    cells <- cells[order(cells$x + cells$width), , drop = FALSE]
    if (nrow(cells) %% 2L != 0L) stop("Survey table row is not year-value paired.", call. = FALSE)
    if (!nrow(cells)) next
    row_year <- as.integer(cells$text[seq(1L, nrow(cells), by = 2L)])
    values <- number_value(cells$text[seq(2L, nrow(cells), by = 2L)])
    out[[length(out) + 1L]] <- data.frame(year = row_year, value = values)
  }
  do.call(rbind, out)
}

parse_table53 <- function(z) {
  year_tokens <- as.character(2005:2024)
  year_rows <- z[z$text %in% year_tokens & z$y >= 150 & z$y <= 480, , drop = FALSE]
  out <- list()
  for (i in seq_len(nrow(year_rows))) {
    year_cell <- year_rows[i, , drop = FALSE]
    yy <- year_cell$y
    year <- as.integer(year_cell$text)
    cells <- z[z$y == yy & z$x > 150 & grepl(number_pattern, z$text),
      , drop = FALSE]
    if (nrow(cells)) {
      cells$age <- ifelse(cells$x < 230, 0L, ifelse(cells$x < 305, 1L, 2L))
      cells <- cells[order(cells$x), , drop = FALSE]
      if (anyDuplicated(cells$age)) stop("Duplicate age cell in Table 5-3.", call. = FALSE)
      out[[length(out) + 1L]] <- data.frame(
        year = year, age = cells$age, value = number_value(cells$text),
        stringsAsFactors = FALSE
      )
    }
  }
  do.call(rbind, out)
}

table6 <- parse_table6(pdf_data)
table51 <- parse_paired_table(pdf_data[[58]], 1998:2025, c(160, 300))
table52 <- parse_paired_table(pdf_data[[58]], 2005:2026, c(430, 600))
table53 <- parse_table53(pdf_data[[59]])
if (nrow(table51) != 28L || !setequal(table51$year, 1998:2025) ||
    nrow(table52) != 22L || !setequal(table52$year, 2005:2026) ||
    nrow(table53) != 56L ||
    anyDuplicated(table53[c("year", "age")]) ||
    !setequal(unique(table53$year), 2005:2024)) {
  stop("Survey table extraction failed expected coverage checks.", call. = FALSE)
}
if (table51$value[table51$year == 1998] != 243745 ||
    table51$value[table51$year == 2025] != 130544 ||
    table52$value[table52$year == 2005] != 61 ||
    table52$value[table52$year == 2026] != 798 ||
    table53$value[table53$year == 2005 & table53$age == 1] != 20 ||
    table53$value[table53$year == 2024 & table53$age == 0] != 430.4) {
  stop("Survey table extraction failed source-value spot checks.", call. = FALSE)
}

make_row <- function(fields, values) {
  row <- as.list(rep("", length(fields)))
  names(row) <- fields
  for (nm in intersect(names(values), fields)) {
    value <- values[[nm]]
    row[[nm]] <- if (length(value) == 0L || is.na(value[1L])) "" else
      as.character(value[1L])
  }
  as.data.frame(row, stringsAsFactors = FALSE, check.names = FALSE)
}
make_rows <- function(fields, rows) {
  if (!length(rows)) return(as.data.frame(setNames(replicate(length(fields),
    character(), simplify = FALSE), fields), check.names = FALSE))
  do.call(rbind, rows)
}
read_csv <- function(path) utils::read.csv(path, stringsAsFactors = FALSE,
  colClasses = "character", check.names = FALSE, na.strings = c("", "NA"))
read_empty_csv <- function(path) utils::read.csv(path, nrows = 0L,
  stringsAsFactors = FALSE, colClasses = "character", check.names = FALSE,
  na.strings = c("", "NA"))
read_fields <- function(path) names(utils::read.csv(path, nrows = 0L,
  check.names = FALSE))
append_csv <- function(path, rows) {
  if (!nrow(rows)) return(invisible(NULL))
  fields <- read_fields(path)
  if (length(setdiff(fields, names(rows)))) stop("Proposed rows do not match ", path, ".",
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
  lines <- character()
  repeat {
    chunk <- readLines(connection, n = 50000L, warn = FALSE)
    if (!length(chunk)) break
    lines <- c(lines, chunk[startsWith(chunk, prefix)])
  }
  if (!length(lines)) return(utils::read.csv(text = header,
    stringsAsFactors = FALSE, colClasses = "character",
    check.names = FALSE, na.strings = c("", "NA")))
  utils::read.csv(text = paste(c(header, lines), collapse = "\n"),
    stringsAsFactors = FALSE, colClasses = "character",
    check.names = FALSE, na.strings = c("", "NA"))
}
normalize_rows <- function(rows) {
  rows[] <- lapply(rows, function(x) {
    x <- as.character(x)
    x[is.na(x)] <- ""
    x
  })
  rows
}
row_keys <- function(rows, fields) {
  do.call(paste, c(lapply(rows[fields], function(x) ifelse(is.na(x), "", x)),
    sep = "\r"))
}
rows_to_add <- function(existing, proposed, key_fields) {
  existing <- normalize_rows(existing)
  proposed <- normalize_rows(proposed)
  old_keys <- row_keys(existing, key_fields)
  new_keys <- row_keys(proposed, key_fields)
  if (anyDuplicated(new_keys)) stop("Proposed rows contain duplicate keys.", call. = FALSE)
  for (i in which(new_keys %in% old_keys)) {
    j <- match(new_keys[i], old_keys)
    if (!identical(unlist(existing[j, names(proposed), drop = FALSE],
      use.names = FALSE), unlist(proposed[i, , drop = FALSE], use.names = FALSE))) {
      stop("An existing row key has a different source value.", call. = FALSE)
    }
  }
  proposed[!new_keys %in% old_keys, , drop = FALSE]
}
ensure_append <- function(path, proposed, id_field) {
  existing <- read_csv(path)
  ids <- as.character(existing[[id_field]])
  found <- which(ids == as.character(proposed[[id_field]][1L]))
  if (!length(found)) {
    append_csv(path, proposed)
  } else if (length(found) != 1L ||
      !identical(unlist(normalize_rows(existing[found, names(proposed), drop = FALSE]),
        use.names = FALSE), unlist(normalize_rows(proposed), use.names = FALSE))) {
    stop("Existing ", id_field, " does not match the reviewed record.", call. = FALSE)
  }
}

manifest <- read_csv("provenance/fra_northern_sea_japan_pollock_2026/manifest.csv")
if (nrow(manifest) != 1L || manifest$sha256 != report_hash ||
    manifest$source_url != report_url || manifest$retrieved_on != "2026-11-08") {
  stop("Source manifest does not match the reviewed FRA report.", call. = FALSE)
}

stock_fields <- read_fields("database/stocks.csv")
assessment_fields <- read_fields("database/assessments.csv")
input_fields <- read_fields("database/inputs.csv")
assumption_fields <- read_fields("database/assumptions.csv")
output_fields <- read_fields("database/outputs.csv")
reference_base <- "FRA-SA2026-SC01-01"

stock_row <- make_row(stock_fields, list(
  stock_id = stock_id, charbonneau_id = "",
  authority = "FRA", authority_stock_id = "",
  scientific_name = "Gadus chalcogrammus",
  common_name = "Northern Sea of Japan walleye pollock",
  area = "Northern Sea of Japan; Noto Peninsula to western Sakhalin",
  region = "Northern Sea of Japan", ocean = "Northwest Pacific",
  notes = "No separate FRA stock-unit code was identified in the 2026 assessment document; the assessment document number is retained in the assessment record. Distinct from U.S.-managed Alaska walleye pollock units."
))
assessment_row <- make_row(assessment_fields, list(
  assessment_id = assessment_id, stock_id = stock_id,
  assessment_year = 2026L, terminal_year = 2025L,
  estimate_terminal_year = 2025L, assessment_type = "annual",
  model_family = "VPA", model_version = "Tuned Pope cohort analysis; ridge VPA terminal-F penalty",
  is_current = "TRUE", is_applied = "TRUE", framework_year = "",
  assessment_url = report_url, framework_url = "",
  data_url = "", model_url = "", repository_url = "",
  assumptions_status = "partial", inputs_status = "complete",
  outputs_status = "partial",
  notes = "FRA 2026 assessment meeting report, document FRA-SA2026-SC01-01. The official meeting page labels the detailed version preliminary while formatting is finalized. Point estimates are tabulated; numerical uncertainty intervals are not."
))

input_rows <- list()
input_row <- function(type, measure, basis, value, unit, source_reference,
    notes = "", fleet = "", survey = "", sex = "", region = "", season = "",
    year = "", year_basis = "", age = "", sampling_time = "",
    source_type = "official_table", transformation = "") {
  make_row(input_fields, list(
    assessment_id = assessment_id, type = type, measure = measure,
    basis = basis, fleet = fleet, survey = survey, sex = sex,
    region = region, season = season, year = year, year_basis = year_basis,
    age = age, value = value, unit = unit, sampling_time = sampling_time,
    source_type = source_type, source_reference = source_reference,
    transformation = transformation, notes = notes
  ))
}
output_rows <- list()
output_row <- function(type, measure, value, unit, source_reference, notes = "",
    year = "", age = "", age_group = "", sex = "", source_type = "official_table",
    transformation = "") {
  make_row(output_fields, list(
    assessment_id = assessment_id, type = type, measure = measure,
    sex = sex, year = year, age = age, age_group = age_group,
    value = value, unit = unit, source_type = source_type,
    source_reference = source_reference, notes = notes
  ))
}
assumption_rows <- list()
assumption_row <- function(component, setting, value, source_reference, notes = "",
    survey = "", sex = "", region = "") {
  make_row(assumption_fields, list(
    assessment_id = assessment_id, component = component, setting = setting,
    value = value, source_reference = source_reference, notes = notes,
    survey = survey, sex = sex, region = region
  ))
}

table6_age <- table6$ages
table6_total <- table6$totals
catch_ref <- paste(reference_base, "Supplementary Material 6, p. 60-64, age-specific catch numbers")
catch_inputs <- table6_age[table6_age$block == 1L, ]
for (i in seq_len(nrow(catch_inputs))) {
  input_rows[[length(input_rows) + 1L]] <- input_row(
    "catch", "numbers_at_age", "numbers", catch_inputs$value[i],
    "thousand fish", catch_ref,
    notes = "Reported age-specific catch number. Fishery years run April-March; ages are assigned on April 1. Age 10 is the 10+ plus group.",
    fleet = "Total fishery", year = catch_inputs$year[i],
    year_basis = "model_year", age = catch_inputs$age[i]
  )
}

survey51_ref <- paste(reference_base, "Supplementary Table 5-1, p. 58")
for (i in seq_len(nrow(table51))) {
  year <- table51$year[i]
  excluded <- year %in% c(2002L, 2012L)
  input_rows[[length(input_rows) + 1L]] <- input_row(
    "index", "total_biomass", "biomass", table51$value[i], "tonnes",
    survey51_ref,
    notes = paste0(
      "October spawning-stock distribution survey biomass index. Published values for 2002 and 2012 were excluded from VPA tuning because survey coverage was insufficient.",
      if (excluded) " This observation is published but excluded from tuning." else ""
    ),
    survey = "October spawning-stock distribution survey",
    season = "October", year = year, year_basis = "model_year",
    sampling_time = 0.5
  )
}

survey52_ref <- paste(reference_base, "Supplementary Table 5-2, p. 58")
for (i in seq_len(nrow(table52))) {
  year <- table52$year[i]
  note <- "Age-0 abundance from the new-recruitment larval/juvenile distribution survey; year is the birth cohort. Source unit is 100 million fish."
  if (year == 2005L) note <- paste(note, "The source identifies the 2005 value as a reference value.")
  if (year == 2026L) note <- paste(note, "The 2026 value is marked as a rapid survey result; it is retained as published and falls beyond the assessment estimate terminal year.")
  input_rows[[length(input_rows) + 1L]] <- input_row(
    "index", "numbers_at_age", "numbers", table52$value[i],
    "100 million fish", survey52_ref, notes = note,
    survey = "New-recruitment larval/juvenile distribution survey",
    year = year, year_basis = "birth_cohort", age = 0L
  )
}

survey53_ref <- paste(reference_base, "Supplementary Table 5-3, p. 59")
for (i in seq_len(nrow(table53))) {
  input_rows[[length(input_rows) + 1L]] <- input_row(
    "index", "numbers_at_age", "numbers", table53$value[i], "million fish",
    survey53_ref,
    notes = "Juvenile distribution survey around Musashi Bank. Only reported numeric cells are stored; source dashes remain missing, not zero. The report identifies age-1 abundance from 2007 onward as a useful recruitment indicator.",
    survey = "Juvenile distribution survey (Musashi Bank)",
    region = "Musashi Bank surrounding waters",
    year = table53$year[i], year_basis = "birth_cohort",
    age = table53$age[i]
  )
}

weight_early <- c(113, 178, 290, 377, 456, 518, 538, 581, 640)
weight_late <- c(78, 169, 268, 360, 438, 501, 550, 588, 636)
maturity_female_early <- c(0, 31, 89, 99, 100, 100, 100, 100, 100) / 100
maturity_female_late <- c(4, 25, 73, 91, 97, 97, 97, 97, 97) / 100
maturity_combined_early <- c(9, 48, 90, 99, 100, 100, 100, 100, 100) / 100
maturity_combined_late <- c(6, 44, 83, 92, 97, 97, 97, 97, 97) / 100
ages <- 2:10
for (period in c("early", "late")) {
  year <- if (period == "early") 2005L else 2006L
  window <- if (period == "early") "2005 fishing year and earlier" else "2006 fishing year and later"
  weights <- if (period == "early") weight_early else weight_late
  female <- if (period == "early") maturity_female_early else maturity_female_late
  combined <- if (period == "early") maturity_combined_early else maturity_combined_late
  for (j in seq_along(ages)) {
    age <- ages[j]
    input_rows[[length(input_rows) + 1L]] <- input_row(
      "weight", "weight_at_age", "g_per_fish", weights[j], "g/fish",
      paste(reference_base, "Supplementary Table 2-1, p. 41"),
      notes = paste("Stock weight-at-age; period applies to", window,
        "and earlier/later years as stated in the source. Age 10 is 10+."),
      year = year, year_basis = "model_year", age = age
    )
    input_rows[[length(input_rows) + 1L]] <- input_row(
      "maturity", "maturity_at_age", "proportion", female[j], "proportion",
      paste(reference_base, "Supplementary Table 2-2, p. 41"),
      notes = paste("Female maturity-at-age used for spawning biomass; source percentages divided by 100. Schedule applies to", window, "and earlier/later years. Age 10 is 10+."),
      sex = "female", year = year, year_basis = "model_year", age = age,
      transformation = "Source percentage divided by 100 to express maturity as a proportion."
    )
    input_rows[[length(input_rows) + 1L]] <- input_row(
      "maturity", "maturity_at_age", "proportion", combined[j], "proportion",
      paste(reference_base, "Supplementary Table 2-3, p. 41"),
      notes = paste("Combined-sex maturity-at-age used for the October spawning-stock index; source percentages divided by 100. Schedule applies to", window, "and earlier/later years. Age 10 is 10+."),
      survey = "October spawning-stock distribution survey",
      sex = "combined", year = year, year_basis = "model_year", age = age,
      transformation = "Source percentage divided by 100 to express maturity as a proportion."
    )
  }
}

m_ages <- 0:10
m_values <- c(0.30, 0.30, 0.30, rep(0.25, 8))
for (j in seq_along(m_ages)) {
  age <- m_ages[j]
  note <- if (age < 2L) {
    "M for ages 0-1 is assumed equal to age-2 M only to derive April abundance indices; these ages are outside the fitted VPA population range."
  } else {
    "Fixed natural mortality in the tuned VPA; age 2 M is 0.30 per year and ages 3+ use 0.25 per year. Age 10 is the 10+ plus group."
  }
  m_reference <- if (age < 2L) {
    paste(reference_base, "Section 3, p. 7")
  } else {
    paste(reference_base, "Section 3, p. 7; Supplementary Table 2-4, p. 42")
  }
  input_rows[[length(input_rows) + 1L]] <- input_row(
    "M", "natural_mortality_at_age", "per_year", m_values[j], "per_year",
    m_reference, notes = note, age = age,
    source_type = if (age < 2L) "official_document" else "official_table"
  )
}

output_ref <- paste(reference_base, "Supplementary Material 6, pp. 60-64")
output_specs <- list(
  list(block = 2L, type = "catch", measure = "catch_biomass_at_age",
    unit = "tonnes", note = "Reported age-specific catch biomass. The source notes that values through the 2007 fishing year were calculated from catch numbers and stock weight-at-age and are not actual catch biomass."),
  list(block = 3L, type = "mortality", measure = "fishing_mortality_at_age",
    unit = "per_year", note = "Age-specific fishing mortality; the 10+ value is set equal to age-9 F."),
  list(block = 4L, type = "population", measure = "numbers_at_age",
    unit = "thousand fish", note = "Estimated abundance at the start of the April-March fishing year; age 10 is the 10+ plus group."),
  list(block = 5L, type = "biomass", measure = "biomass_at_age",
    unit = "tonnes", note = "Estimated stock biomass-at-age; age 10 is the 10+ plus group."),
  list(block = 6L, type = "biomass", measure = "mature_biomass_at_age",
    unit = "tonnes", note = "Estimated age-specific spawning biomass; source maturity convention is female maturity-at-age.")
)
for (spec in output_specs) {
  d <- table6_age[table6_age$block == spec$block, ]
  for (i in seq_len(nrow(d))) {
    output_rows[[length(output_rows) + 1L]] <- output_row(
      spec$type, spec$measure, d$value[i], spec$unit, output_ref,
      notes = spec$note, year = d$year[i], age = d$age[i],
      age_group = d$age_group[i]
    )
  }
}

total_specs <- list(
  list(block = 4L, type = "population", measure = "total_numbers",
    unit = "thousand fish", note = "Reported total abundance; sum over ages 2-10+."),
  list(block = 5L, type = "biomass", measure = "total_biomass",
    unit = "tonnes", note = "Reported total stock biomass; sum over ages 2-10+."),
  list(block = 6L, type = "biomass", measure = "SSB",
    unit = "tonnes", note = "Reported total spawning biomass; the source table reports age-specific components and their total.")
)
for (spec in total_specs) {
  d <- table6_total[table6_total$block == spec$block, ]
  for (i in seq_len(nrow(d))) {
    output_rows[[length(output_rows) + 1L]] <- output_row(
      spec$type, spec$measure, d$value[i], spec$unit, output_ref,
      notes = paste(spec$note, "No tabulated uncertainty estimate is available."),
      year = d$year[i]
    )
  }
}
recruitment <- table6_age[table6_age$block == 4L & table6_age$age == 2L, ]
for (i in seq_len(nrow(recruitment))) {
  output_rows[[length(output_rows) + 1L]] <- output_row(
    "recruitment", "recruitment", recruitment$value[i], "thousand fish",
    output_ref,
    notes = "Recruitment is represented by abundance at the model recruitment age 2 at the start of the fishing year.",
    year = recruitment$year[i], age = 2L, source_type = "derived_source_output",
    transformation = "Identified recruitment with the reported age-2 abundance because age 2 is the model recruitment age."
  )
}

input_rows <- make_rows(input_fields, input_rows)
output_rows <- make_rows(output_fields, output_rows)
assumptions <- list(
  assumption_row("population", "assessment_method", "Tuned Pope cohort analysis (VPA)",
    paste(reference_base, "Section 3, p. 7")),
  assumption_row("population", "model_years", "Fishing years 1980-2025; April-March",
    paste(reference_base, "Supplementary Material 6, pp. 60-64"),
    "Age is assigned on April 1."),
  assumption_row("population", "modeled_ages", "2-10+",
    paste(reference_base, "Section 3, p. 7; Supplementary Material 6, pp. 60-64"),
    "Age 10 is the plus group."),
  assumption_row("recruitment", "recruitment_age", "2",
    paste(reference_base, "Section 3, p. 7"),
    "Age-2 abundance at the start of each fishing year is used as recruitment."),
  assumption_row("fishing_mortality", "terminal_F_estimation",
    "Ridge VPA; lambda = 0.9887",
    paste(reference_base, "Section 3, p. 7; Supplementary Figure 2-3, p. 36"),
    "Penalty selected from the retrospective residual criterion."),
  assumption_row("fishing_mortality", "plus_group_F",
    "F at age 10+ set equal to F at age 9",
    paste(reference_base, "Section 3, p. 7; Supplementary Material 6, pp. 60-64")),
  assumption_row("natural_mortality", "fixed_M_at_age_2", "0.30 per year",
    paste(reference_base, "Section 3, p. 7")),
  assumption_row("natural_mortality", "fixed_M_at_ages_3_plus", "0.25 per year",
    paste(reference_base, "Section 3, p. 7")),
  assumption_row("index", "age0_1_abundance_reconstruction",
    "M at ages 0-1 equals age-2 M; catch numbers at ages 0-1 are zero",
    paste(reference_base, "Section 3, p. 7"),
    "Used only to derive April age-0 and age-1 abundance indices from age-2 abundance; ages 0-1 are outside the fitted VPA population range."),
  assumption_row("index", "number_of_acoustic_indices", "3",
    paste(reference_base, "Section 3, p. 7"),
    "October spawning-stock biomass, age-0 recruitment survey, and juvenile distribution survey."),
  assumption_row("index", "october_survey_exclusions", "2002 and 2012 excluded from tuning",
    paste(reference_base, "Supplementary Table 5-1, p. 58"),
    "Both observations are published but excluded because survey coverage was insufficient.",
    survey = "October spawning-stock distribution survey"),
  assumption_row("index", "index_likelihood_and_error_model", "unknown",
    paste(reference_base, "Section 3, p. 7"),
    "The detailed report does not provide enough information to resolve the complete fitted index likelihood and observation-error specification."),
  assumption_row("biology", "stock_weight_periods",
    "2005 and earlier; 2006 and later",
    paste(reference_base, "Supplementary Table 2-1, p. 41"),
    "Earlier weights were calculated from March-May fish measurements from 1995-2002; later weights use the growth model from Hoshino et al. (2021)."),
  assumption_row("biology", "female_maturity_periods",
    "2005 and earlier; 2006 and later",
    paste(reference_base, "Supplementary Table 2-2, p. 41"),
    "Earlier values were calculated from Nov-Jan fishery measurements from 2007-2013; later values use Hoshino et al. (2021)."),
  assumption_row("biology", "combined_sex_maturity_purpose",
    "Used for the October spawning-stock distribution index",
    paste(reference_base, "Supplementary Table 2-3, p. 41"),
    "Source maturity percentages are stored as proportions in inputs.csv.",
    survey = "October spawning-stock distribution survey"),
  assumption_row("population", "catch_age_reconstruction",
    "Age-specific total catch",
    paste(reference_base, "Section 3, p. 7; Supplementary Material 6, pp. 60-64"),
    "Reported catch-at-age includes Korean catches; where direct age composition is unavailable, the report assigns the same age composition as the Japanese offshore trawl catch. Do not split the published total into invented fleets.")
)
assumption_rows <- make_rows(assumption_fields, assumptions)

stock_rows <- read_csv("database/stocks.csv")
assessment_rows <- read_csv("database/assessments.csv")
candidates_path <- "discovery/candidates.csv"
candidate_rows <- read_csv(candidates_path)
candidate_index <- which(candidate_rows$candidate_id == candidate_id)
if (length(candidate_index) != 1L) {
  stop("Expected exactly one screened candidate.", call. = FALSE)
}
assessment_exists <- assessment_id %in% assessment_rows$assessment_id
candidate <- candidate_rows[candidate_index, , drop = FALSE]
candidate$matched_stock_id <- stock_id
candidate$match_status <- "matched"
candidate$import_status <- "imported"
candidate$catch_age_evidence <- paste(
  "Imported Supplementary Table 6 age-specific catch numbers for 1980-2025, ages 2-9 and 10+, in thousand fish."
)
candidate$survey_age_evidence <- paste(
  "Imported October spawning-stock biomass index for 1998-2025, age-0 recruitment survey by cohort for 2005-2026, and juvenile survey age-0/1/2 observations for 2005-2024, retaining missing cells."
)
candidate$weights_evidence <- "Imported stock weight-at-age ages 2-10+ for the <=2005 and >=2006 schedules, in g/fish."
candidate$maturity_evidence <- "Imported female maturity for SSB and combined-sex maturity for the October index, ages 2-10+, for <=2005 and >=2006 schedules."
candidate$mortality_evidence <- "Imported fixed M-at-age: 0.30 per year at age 2 and 0.25 per year at ages 3+; ages 0-1 use age-2 M only when deriving April abundance indices."
candidate$timing_evidence <- paste(
  "Fishing year April-March and age assigned April 1. October index timing represented as 0.5 of fishing year; exact survey timing for the cohort indices is not reported."
)
candidate$output_evidence <- paste(
  "Imported Table 6 catch biomass-at-age, F-at-age, N-at-age, biomass-at-age, SSB-at-age, totals, and age-2 recruitment for 1980-2025. Numerical uncertainty intervals are not tabulated."
)
candidate$decision_reason <- paste(
  "The FRA 2026 official assessment meeting provides a detailed preliminary report with numerical age-specific catch, three survey series, biological inputs, fixed M, and model outputs.",
  "The official meeting page says the detailed report is preliminary pending formatting; verify any finalized replacement before reuse."
)
candidate$notes <- paste(
  "No separate official stock-unit code was identified; FRA-SA2026-SC01-01 is the assessment document number. Source cache and checksum are recorded in provenance/fra_northern_sea_japan_pollock_2026/manifest.csv."
)

assumption_key <- c("assessment_id", "component", "fleet", "survey", "sex",
  "region", "season", "setting")
input_key <- c("assessment_id", "type", "measure", "basis", "fleet", "survey",
  "sex", "region", "season", "year", "year_basis", "age", "observation_id",
  "partition")
output_key <- c("assessment_id", "type", "measure", "fleet", "survey", "sex",
  "region", "season", "year", "age", "age_group", "scenario")
assumptions_to_add <- rows_to_add(read_csv("database/assumptions.csv"),
  assumption_rows, assumption_key)
existing_inputs <- if (assessment_exists) {
  read_assessment_rows("database/inputs.csv", assessment_id)
} else {
  read_empty_csv("database/inputs.csv")
}
existing_outputs <- if (assessment_exists) {
  read_assessment_rows("database/outputs.csv", assessment_id)
} else {
  read_empty_csv("database/outputs.csv")
}
inputs_to_add <- rows_to_add(existing_inputs, input_rows, input_key)
outputs_to_add <- rows_to_add(existing_outputs, output_rows, output_key)

cat("FRA Northern Sea of Japan pollock source import\n")
cat("  candidate: ", candidate_id, "\n", sep = "")
cat("  inputs ready: ", nrow(inputs_to_add), " (", nrow(input_rows), " total)\n", sep = "")
cat("  assumptions ready: ", nrow(assumptions_to_add), " (", nrow(assumption_rows), " total)\n", sep = "")
cat("  outputs ready: ", nrow(outputs_to_add), " (", nrow(output_rows), " total)\n", sep = "")
cat("  Table 6 age rows: ", nrow(table6$ages), "; years: 1980-2025; ages: 2-10+\n", sep = "")
cat("  Table 5-1: ", nrow(table51), " values; 5-2: ", nrow(table52),
  " values; 5-3: ", nrow(table53), " populated cells\n", sep = "")
if (!write_mode) {
  cat("Dry run only. Add --write to append the verified source records.\n")
} else {
  source(file.path(root, "scripts/database/candidate_register_io.R"), local = TRUE)
  ensure_append("database/stocks.csv", stock_row, "stock_id")
  ensure_append("database/assessments.csv", assessment_row, "assessment_id")
  append_csv("database/assumptions.csv", assumptions_to_add)
  append_csv("database/inputs.csv", inputs_to_add)
  append_csv("database/outputs.csv", outputs_to_add)
  replace_candidate_register_row(candidates_path, candidate_index, candidate,
    candidate_id)
  cat("Wrote the source records and marked the candidate imported.\n")
}
