root <- "."
assessment_id <- "ices_bay_biscay_anchovy_2025"
stock_id <- "ices_bay_biscay_anchovy_8"
candidate_id <- "ICES:ane.27.8"
report_path <- file.path(root, "source_cache/ices_ane_27_8/ices_wghansa_2025_report.pdf")
report_text_path <- paste0(report_path, ".txt")
report_hash <- "91a780f00878529c9cee208137a9f9ede22f49ad1a83c5840d1d72395103c6d9"
report_url <- "https://doi.org/10.17895/ices.pub.29335520.v3"
annex_url <- "https://doi.org/10.17895/ices.pub.28053440.v2"
graph_url <- "https://standardgraphs.ices.dk/ViewSourceData.aspx?key=21265"
write_mode <- "--write" %in% commandArgs(trailingOnly = TRUE)

if (!file.exists(report_path) ||
    tolower(unname(tools::sha256sum(report_path))) != report_hash ||
    !file.exists(report_text_path)) {
  stop("The pinned WGHANSA report or its extracted text is missing or changed.", call. = FALSE)
}

report_lines <- readLines(report_text_path, warn = FALSE, encoding = "UTF-8")

number_tokens <- function(x) {
  match <- gregexpr("(?<![[:alnum:]])(?:na|-?(?:[0-9]{1,3}(?:,[0-9]{3})+|[0-9]+)(?:\\.[0-9]+)?)(?![[:alnum:]])",
    x, perl = TRUE)
  starts <- match[[1L]]
  if (length(starts) == 1L && starts == -1L) {
    return(data.frame(start = integer(), length = integer(), value = numeric()))
  }
  token <- regmatches(x, match)[[1L]]
  value <- suppressWarnings(as.numeric(gsub(",", "", token, fixed = TRUE)))
  value[tolower(token) == "na"] <- NA_real_
  data.frame(start = starts, length = nchar(token), value = value)
}

table_section <- function(title_pattern) {
  start <- grep(title_pattern, report_lines, perl = TRUE)
  if (length(start) != 1L) stop("Expected one report table: ", title_pattern, call. = FALSE)
  next_table <- grep("^\\s*Table\\s+[0-9]", report_lines, perl = TRUE)
  next_table <- next_table[next_table > start]
  end <- if (length(next_table)) next_table[1L] - 1L else length(report_lines)
  report_lines[start:end]
}

parse_year_table <- function(lines, expected_values, years_expected, label) {
  row_lines <- grep("^\\s*(19|20)[0-9]{2}\\s+[0-9]", lines, value = TRUE, perl = TRUE)
  rows <- lapply(row_lines, function(line) {
    year_text <- regmatches(line, regexpr("(19|20)[0-9]{2}", line, perl = TRUE))
    year_start <- regexpr("(19|20)[0-9]{2}", line, perl = TRUE)[1L]
    tail <- substring(line, year_start + 4L)
    values <- number_tokens(tail)$value
    if (length(values) != expected_values) {
      stop(label, " year ", year_text, " has ", length(values),
        " values; expected ", expected_values, ".", call. = FALSE)
    }
    c(year = as.integer(year_text), values)
  })
  if (!length(rows)) stop(label, " has no annual rows.", call. = FALSE)
  z <- as.data.frame(do.call(rbind, rows), stringsAsFactors = FALSE)
  z$year <- as.integer(z$year)
  if (anyDuplicated(z$year) || !identical(sort(z$year), years_expected)) {
    stop(label, " year coverage differs from the reviewed report.", call. = FALSE)
  }
  z
}

parse_summary_table <- function(lines) {
  fields <- c("year", "landings", "rec_lower", "rec", "rec_upper", "ssb_lower",
    "ssb", "ssb_upper", "f_lower", "f", "f_upper", "harvest_rate")
  rows <- list()
  row_lines <- grep("^\\s*(19|20)[0-9]{2}\\s+[0-9]", lines, value = TRUE, perl = TRUE)
  for (line in row_lines) {
    if (!grepl("^\\s*(19|20)[0-9]{2}\\s+[0-9]", line, perl = TRUE)) next
    year_text <- regmatches(line, regexpr("(19|20)[0-9]{2}", line, perl = TRUE))
    year_start <- regexpr("(19|20)[0-9]{2}", line, perl = TRUE)[1L]
    values <- number_tokens(substring(line, year_start + 4L))$value
    if (length(values) == 11L) {
      cells <- values
    } else if (length(values) == 8L) {
      cells <- c(values[1:7], NA_real_, NA_real_, NA_real_, values[8])
    } else {
      stop("Annual summary row has an unexpected number of values: ", line, call. = FALSE)
    }
    rows[[length(rows) + 1L]] <- c(year = as.integer(year_text), cells)
  }
  if (!length(rows)) stop("Annual summary table has no annual rows.", call. = FALSE)
  z <- as.data.frame(do.call(rbind, rows), stringsAsFactors = FALSE)
  names(z) <- fields
  z$year <- as.integer(z$year)
  if (anyDuplicated(z$year) || !identical(sort(z$year), 1987:2025) ||
      anyNA(z$rec) || anyNA(z$ssb)) {
    stop("Annual summary coverage or required SSB/recruitment values are incomplete.", call. = FALSE)
  }
  z
}

parse_parameter_table <- function(lines) {
  rows <- lines[grepl("\\s(?:OK|BOUND)\\s*$", lines, perl = TRUE)]
  fields <- strsplit(trimws(rows), "\\s{2,}", perl = TRUE)
  if (!length(fields) || any(lengths(fields) != 7L)) {
    stop("Estimated-parameter table has an unexpected layout.", call. = FALSE)
  }
  z <- as.data.frame(do.call(rbind, fields), stringsAsFactors = FALSE)
  names(z) <- c("label", "value", "se", "minimum", "maximum", "initial", "status")
  for (name in c("value", "se", "minimum", "maximum", "initial")) {
    z[[name]] <- as.numeric(z[[name]])
  }
  if (anyDuplicated(z$label) || anyNA(z$value) || anyNA(z$se) ||
      !all(z$status %in% c("OK", "BOUND"))) {
    stop("Estimated-parameter table contains duplicate or invalid rows.", call. = FALSE)
  }
  z
}

parse_aggregate_inputs <- function() {
  lines <- table_section("^\\s*Table 2\\.5\\.1\\.1:")
  header_index <- grep("^\\s*Year\\s+Pelgas SSB", lines, perl = TRUE)
  if (!length(header_index)) stop("Could not locate the aggregate input header.", call. = FALSE)
  header_index <- header_index[1L]
  labels <- c("Year", "Pelgas SSB", "Pelgas CV", "Bioman SSB", "Bioman CV",
    "Juvena N0", "Juvena CV", "Catch sem1", "Catch sem2")
  starts <- vapply(labels, function(label) {
    start <- regexpr(label, lines[header_index], fixed = TRUE)[1L]
    if (start < 1L) stop("Missing aggregate input column: ", label, call. = FALSE)
    start
  }, integer(1L))
  starts[which(labels == "Juvena N0")] <- starts[5L] + 12L
  rows <- list()
  for (line in lines[(header_index + 1L):length(lines)]) {
    if (!grepl("^\\s*(19|20)[0-9]{2}\\b", line, perl = TRUE)) next
    cells <- rep(NA_real_, length(starts))
    cell_positions <- rep(NA_integer_, length(starts))
    tokens <- number_tokens(line)
    for (k in seq_len(nrow(tokens))) {
      column <- max(which(starts <= tokens$start[k]))
      if (!is.na(cells[column])) stop("Duplicate aggregate input cell ", column,
        " at position ", tokens$start[k], " after ", cell_positions[column],
        " starts ", paste(starts, collapse = ","), " value ", tokens$value[k],
        " in row: ", line, call. = FALSE)
      cells[column] <- tokens$value[k]
      cell_positions[column] <- tokens$start[k]
    }
    rows[[length(rows) + 1L]] <- cells
  }
  if (!length(rows)) stop("No aggregate input rows were parsed.", call. = FALSE)
  z <- as.data.frame(do.call(rbind, rows), stringsAsFactors = FALSE)
  names(z) <- c("year", "pelgas_ssb", "pelgas_cv", "bioman_ssb", "bioman_cv",
    "juvena_n0", "juvena_cv", "catch_s1", "catch_s2")
  z$year <- as.integer(z$year)
  if (!identical(z$year, sort(unique(z$year))) || anyDuplicated(z$year) ||
      min(z$year) != 1987L || max(z$year) != 2025L) {
    stop("Aggregate input years are incomplete or duplicated.", call. = FALSE)
  }
  z
}

parse_age_period_table <- function(lines, label) {
  header_indices <- grep("^\\s*YEAR\\b", lines, perl = TRUE)
  if (!length(header_indices)) stop(label, " has no year blocks.", call. = FALSE)
  out <- list()
  for (block in seq_along(header_indices)) {
    i <- header_indices[block]
    block_end <- if (block < length(header_indices)) header_indices[block + 1L] - 1L else length(lines)
    years_match <- gregexpr("(19|20)[0-9]{2}", lines[i], perl = TRUE)
    years <- as.integer(regmatches(lines[i], years_match)[[1L]])
    period_line <- seq.int(i + 1L, min(block_end, i + 4L))
    period_line <- period_line[grepl("1st half|2nd half", lines[period_line], perl = TRUE)]
    if (length(period_line) != 1L) stop(label, " has no unique half-year header.", call. = FALSE)
    cell_match <- gregexpr("1st half|2nd half", lines[period_line], perl = TRUE)
    cell_starts <- as.integer(cell_match[[1L]])
    expected_cells <- 2L * length(years)
    if (length(cell_starts) < expected_cells) {
      stop(label, " year and half-year columns do not align: ", length(years),
        " years, ", length(cell_starts), " semester columns in ", lines[i], call. = FALSE)
    }
    if (length(cell_starts) > expected_cells) cell_starts <- cell_starts[seq_len(expected_cells)]
    for (j in seq.int(period_line + 1L, block_end)) {
      line <- lines[j]
      trimmed <- sub("^\\s+", "", line)
      if (grepl("^Total\\b", trimmed, perl = TRUE)) break
      if (grepl("^Sources?:|^Period", trimmed, perl = TRUE)) next
      age_match <- regexec("^(?:Age\\s*)?([0-9]+)\\s+", trimmed, perl = TRUE)
      groups <- regmatches(trimmed, age_match)[[1L]]
      if (length(groups) < 2L) next
      age <- as.integer(groups[2L])
      if (age < 0L || age > 5L) next
      tokens <- number_tokens(line)
      token_center <- tokens$start + (tokens$length - 1) / 2
      tokens <- tokens[token_center >= cell_starts[1L], , drop = FALSE]
      token_center <- tokens$start + (tokens$length - 1) / 2
      cell_value <- rep(NA_real_, length(cell_starts))
      cell_positions <- rep(NA_integer_, length(cell_starts))
      for (k in seq_len(nrow(tokens))) {
        column <- max(which(cell_starts <= token_center[k]))
        if (!is.na(cell_value[column])) stop(label, " contains duplicate cell ", column,
          " with starts ", paste(cell_starts, collapse = ","), " in year block ",
          paste(years, collapse = ","), " age ", age, " at ", cell_positions[column],
          " and ", tokens$start[k], ": ", line, call. = FALSE)
        cell_value[column] <- tokens$value[k]
        cell_positions[column] <- tokens$start[k]
      }
      for (k in seq_along(cell_value)) {
        if (is.na(cell_value[k])) next
        out[[length(out) + 1L]] <- data.frame(
          year = years[(k + 1L) %/% 2L],
          season = if (k %% 2L == 1L) "semester_1" else "semester_2",
          age = age, value = cell_value[k], stringsAsFactors = FALSE)
      }
    }
  }
  if (!length(out)) stop(label, " has no age values.", call. = FALSE)
  z <- do.call(rbind, out)
  if (anyDuplicated(z[c("year", "season", "age")])) stop(label, " has duplicate age cells.", call. = FALSE)
  z
}

annual_inputs <- parse_aggregate_inputs()
catch_section <- table_section("^\\s*Table 2\\.2\\.3\\.2:")
weight_section <- table_section("^\\s*Table 2\\.2\\.4\\.1:")
catch_age <- parse_age_period_table(catch_section, "Table 2.2.3.2 catch-at-age")
catch_weight <- parse_age_period_table(weight_section, "Table 2.2.4.1 catch weight-at-age")
if (!identical(sort(unique(catch_age$year)), 1987:2024) ||
    !identical(sort(unique(catch_weight$year)), setdiff(1987:2024, 2007:2009)) ||
    !setequal(unique(catch_age$age), 0:5) || !setequal(unique(catch_weight$age), 0:5)) {
  stop("Catch-at-age or catch-weight year/age coverage differs from the report. Catch years: ",
    paste(range(catch_age$year), collapse = "-"), "; catch-weight years: ",
    paste(range(catch_weight$year), collapse = "-"), "; missing catch years: ",
    paste(setdiff(1987:2024, unique(catch_age$year)), collapse = ","),
    "; missing weight years: ", paste(setdiff(1987:2024, unique(catch_weight$year)), collapse = ","),
    "; ages: ",
    paste(sort(unique(catch_age$age)), collapse = ","), " / ",
    paste(sort(unique(catch_weight$age)), collapse = ","), call. = FALSE)
}

summary_outputs <- parse_summary_table(table_section("^\\s*Table 2\\.5\\.3\\.2:"))
estimated_parameters <- parse_parameter_table(table_section("^\\s*Table 2\\.5\\.3\\.1:"))
f_age <- parse_year_table(
  table_section("^\\s*Table 2\\.5\\.3\\.3:"), 8L, 1987:2024,
  "Table 2.5.3.3 F-at-age")
n_age <- parse_year_table(
  table_section("^\\s*Table 2\\.5\\.3\\.4:"), 4L, 1987:2024,
  "Table 2.5.3.4 N-at-age")

if (annual_inputs$pelgas_ssb[annual_inputs$year == 2025L] != 153374.13 ||
    annual_inputs$bioman_ssb[annual_inputs$year == 2025L] != 157246.81 ||
    annual_inputs$juvena_n0[annual_inputs$year == 2025L] != 386953330 ||
    annual_inputs$catch_s1[annual_inputs$year == 2025L] != 22744 ||
    annual_inputs$catch_s2[annual_inputs$year == 2025L] != 7061) {
  stop("2025 aggregate input anchor values do not match Table 2.5.1.1.", call. = FALSE)
}
if (sum(c(4951, 3430, 266)) != 8647) stop("BIOMAN 2025 age numbers fail the published total check.", call. = FALSE)
expected_parameter_labels <- c("SR_LN(R0)",
  "InitF_seas_1_flt_1Commercial_vessels1", "InitF_seas_2_flt_2Commercial_vessels2",
  "LnQ_base_Pelgas_survey(3)", "Q_extraSD_Pelgas_survey(3)",
  "LnQ_base_Bioman_survey(4)", "Q_extraSD_Bioman_survey(4)",
  "LnQ_base_Juvena_survey(5)", "Q_extraSD_Juvena_survey(5)",
  "AgeSel_P2_Commercial_vessels1(1)", "AgeSel_P4_Commercial_vessels1(1)",
  "AgeSel_P2_Commercial_vessels2(2)", "AgeSel_P4_Commercial_vessels2(2)",
  "AgeSel_P2_Pelgas_survey(3)",
  "AgeSel_P2_Pelgas_survey(3)_BLK2repl_1986",
  "AgeSel_P2_Pelgas_survey(3)_BLK2repl_2007")
if (nrow(estimated_parameters) != 16L ||
    !identical(estimated_parameters$label, expected_parameter_labels) ||
    estimated_parameters$value[estimated_parameters$label == "LnQ_base_Pelgas_survey(3)"] != 0.53 ||
    estimated_parameters$se[estimated_parameters$label == "LnQ_base_Pelgas_survey(3)"] != 0.16) {
  stop("Estimated-parameter rows or anchors differ from Table 2.5.3.1.", call. = FALSE)
}
summary_2025 <- summary_outputs[summary_outputs$year == 2025L, , drop = FALSE]
if (nrow(summary_2025) != 1L || summary_2025$ssb != 119768 ||
    summary_2025$rec != 31134900 || summary_2025$f != 0.27 ||
    !is.na(summary_outputs$f[summary_outputs$year == 2008L])) {
  stop("Annual output anchors or the reported F gap do not match Table 2.5.3.2.", call. = FALSE)
}
catch_anchors <- catch_age[catch_age$year == 1987L & catch_age$age == 1L, , drop = FALSE]
if (!identical(catch_anchors$value[match(c("semester_1", "semester_2"), catch_anchors$season)],
      c(218670, 120098))) stop("Catch-at-age anchor values do not match Table 2.2.3.2.", call. = FALSE)
catch_total_1987 <- aggregate(value ~ season, catch_age[catch_age$year == 1987L, ], sum)
if (!identical(catch_total_1987$value[match(c("semester_1", "semester_2"), catch_total_1987$season)],
      c(431448, 173494))) stop("Catch-at-age totals do not match Table 2.2.3.2.", call. = FALSE)
weight_anchor <- catch_weight[catch_weight$year == 1987L & catch_weight$age == 1L, , drop = FALSE]
if (!identical(weight_anchor$value[match(c("semester_1", "semester_2"), weight_anchor$season)],
      c(21, 21.9))) stop("Catch-weight anchor values do not match Table 2.2.4.1.", call. = FALSE)
if (f_age[f_age$year == 1987L, 2L] != 0 || f_age[f_age$year == 1987L, 4L] != 0.47 ||
    n_age[n_age$year == 1987L, 2L] != 0 || n_age[n_age$year == 1987L, 3L] != 1227870) {
  stop("Age-specific output anchor values do not match Tables 2.5.3.3-2.5.3.4.", call. = FALSE)
}

make_row <- function(fields, values) {
  row <- as.list(rep("", length(fields)))
  names(row) <- fields
  for (name in intersect(names(values), fields)) {
    value <- values[[name]]
    row[[name]] <- if (!length(value) || is.na(value[1L])) "" else as.character(value[1L])
  }
  as.data.frame(row, stringsAsFactors = FALSE, check.names = FALSE)
}
make_rows <- function(fields, rows) {
  if (!length(rows)) return(as.data.frame(setNames(replicate(length(fields), character(), simplify = FALSE), fields), check.names = FALSE))
  do.call(rbind, lapply(rows, function(values) make_row(fields, values)))
}
read_csv <- function(path) utils::read.csv(path, stringsAsFactors = FALSE,
  colClasses = "character", check.names = FALSE, na.strings = c("", "NA"))
read_fields <- function(path) names(utils::read.csv(path, nrows = 0L, check.names = FALSE))
empty_csv <- function(path) utils::read.csv(path, nrows = 0L, stringsAsFactors = FALSE,
  colClasses = "character", check.names = FALSE, na.strings = c("", "NA"))
append_csv <- function(path, rows) {
  if (!nrow(rows)) return(invisible(NULL))
  fields <- read_fields(path)
  if (length(setdiff(fields, names(rows)))) stop("Proposed rows do not match ", path, call. = FALSE)
  utils::write.table(rows[fields], path, sep = ",", row.names = FALSE,
    col.names = FALSE, quote = TRUE, qmethod = "double", na = "", append = TRUE, eol = "\n")
}
read_assessment_rows <- function(path, id) {
  connection <- file(path, open = "rt")
  on.exit(close(connection))
  header <- readLines(connection, n = 1L, warn = FALSE)
  prefix <- paste0('"', id, '"')
  selected <- character()
  repeat {
    chunk <- readLines(connection, n = 50000L, warn = FALSE)
    if (!length(chunk)) break
    selected <- c(selected, chunk[startsWith(chunk, prefix)])
  }
  utils::read.csv(text = paste(c(header, selected), collapse = "\n"),
    stringsAsFactors = FALSE, colClasses = "character", check.names = FALSE,
    na.strings = c("", "NA"))
}
remove_blank_apical_f_rows <- function(path) {
  fields <- read_fields(path)
  indices <- match(c("assessment_id", "type", "measure", "value"), fields)
  if (anyNA(indices)) stop("Output schema is missing fields needed to remove blank F rows.", call. = FALSE)
  year_index <- match("year", fields)
  if (is.na(year_index)) stop("Output schema is missing year.", call. = FALSE)
  temporary <- paste0(path, ".cleaning")
  if (file.exists(temporary)) unlink(temporary)
  input <- file(path, open = "rt")
  output <- file(temporary, open = "wt")
  on.exit({
    try(close(input), silent = TRUE)
    try(close(output), silent = TRUE)
  }, add = TRUE)
  header <- readLines(input, n = 1L, warn = FALSE, encoding = "bytes")
  writeLines(header, output, useBytes = TRUE)
  removed <- 0L
  prefix <- paste0('"', assessment_id, '"')
  repeat {
    chunk <- readLines(input, n = 50000L, warn = FALSE, encoding = "bytes")
    if (!length(chunk)) break
    drop <- vapply(chunk, function(line) {
      if (!startsWith(line, prefix)) return(FALSE)
      parts <- strsplit(line, '","', fixed = TRUE)[[1L]]
      parts <- sub('^"', "", parts)
      parts <- sub('"$', "", parts)
      length(parts) >= max(indices, year_index) &&
        parts[indices[2L]] == "mortality" && parts[indices[3L]] == "F_apical" &&
        !nzchar(parts[indices[4L]])
    }, logical(1L))
    removed <- removed + sum(drop)
    writeLines(chunk[!drop], output, useBytes = TRUE)
  }
  close(input)
  close(output)
  if (removed) {
    backup <- paste0(path, ".before_blank_f_cleanup")
    if (file.exists(backup)) stop("A previous outputs.csv cleanup backup already exists.", call. = FALSE)
    if (!file.rename(path, backup)) stop("Could not preserve outputs.csv before cleanup.", call. = FALSE)
    if (!file.rename(temporary, path)) {
      file.rename(backup, path)
      stop("Could not replace outputs.csv after removing blank apical-F rows.", call. = FALSE)
    }
    unlink(backup)
  } else unlink(temporary)
  removed
}
normalize_rows <- function(rows) {
  rows[] <- lapply(rows, function(x) { x <- as.character(x); x[is.na(x)] <- ""; x })
  rows
}
row_keys <- function(rows, fields) do.call(paste,
  c(lapply(rows[fields], function(x) ifelse(is.na(x), "", as.character(x))), sep = "\r"))
rows_to_add <- function(existing, proposed, key_fields, label) {
  existing <- normalize_rows(existing)
  proposed <- normalize_rows(proposed)
  old_key <- row_keys(existing, key_fields)
  new_key <- row_keys(proposed, key_fields)
  if (anyDuplicated(new_key)) stop(label, " proposal has duplicate canonical keys.", call. = FALSE)
  for (i in which(new_key %in% old_key)) {
    j <- match(new_key[i], old_key)
    if (!identical(unlist(existing[j, names(proposed), drop = FALSE], use.names = FALSE),
        unlist(proposed[i, , drop = FALSE], use.names = FALSE))) {
      stop(label, " conflicts with an existing canonical value.", call. = FALSE)
    }
  }
  proposed[!new_key %in% old_key, , drop = FALSE]
}

stock_fields <- read_fields("database/stocks.csv")
assessment_fields <- read_fields("database/assessments.csv")
assumption_fields <- read_fields("database/assumptions.csv")
input_fields <- read_fields("database/inputs.csv")
output_fields <- read_fields("database/outputs.csv")
stock_row <- make_row(stock_fields, list(
  stock_id = stock_id, authority = "ICES", authority_stock_id = "ane.27.8",
  scientific_name = "Engraulis encrasicolus", common_name = "Bay of Biscay anchovy",
  area = "ICES Subarea 8 (Bay of Biscay)", region = "Bay of Biscay",
  ocean = "Northeast Atlantic",
  notes = "Current ICES Subarea 8 stock unit; distinct from the two Division 9.a anchovy stocks."))
assessment_row <- make_row(assessment_fields, list(
  assessment_id = assessment_id, stock_id = stock_id, assessment_year = 2025L,
  terminal_year = 2025L, estimate_terminal_year = 2025L, assessment_type = "full_assessment",
  model_family = "Stock Synthesis", model_version = "3.30.22.beta", is_current = TRUE,
  is_applied = TRUE, framework_year = "", assessment_url = report_url,
  framework_url = annex_url, data_url = graph_url, assumptions_status = "partial",
  inputs_status = "partial", outputs_status = "partial",
  notes = paste("WGHANSA 2025 production run used for 2026 advice (assessment key 21265).",
    "Report tables provide aggregate indices, catch-at-age and catch weights through 2024,",
    "a 2025 BIOMAN age estimate, and annual/age-specific outputs. Historical BIOMAN and",
    "PELGAS age inputs are partly graphical; exact survey timing, native input files, and",
    "some unit mappings remain unresolved. 2025 catch is provisional.")))

input_rows <- list()
add_input <- function(type, measure, basis, value, unit, year = NA_integer_, age = NA_integer_,
                      fleet = "", survey = "", season = "", year_basis = "",
                      source_type = "official_table", source_reference, transformation = "", notes = "") {
  input_rows[[length(input_rows) + 1L]] <<- make_row(input_fields, list(
    assessment_id = assessment_id, type = type, measure = measure, basis = basis,
    fleet = fleet, survey = survey, season = season, year = year, year_basis = year_basis,
    age = age, value = value, unit = unit, source_type = source_type,
    source_reference = source_reference, transformation = transformation, notes = notes))
}

for (i in seq_len(nrow(annual_inputs))) {
  r <- annual_inputs[i, ]
  for (survey in c("PELGAS", "BIOMAN")) {
    prefix <- tolower(survey)
    biomass <- r[[paste0(prefix, "_ssb")]]
    cv <- r[[paste0(prefix, "_cv")]]
    if (!is.na(biomass)) add_input("index", "total_biomass", "biomass", biomass,
      "tonnes", year = r$year, year_basis = "calendar_year", survey = survey,
      source_reference = paste(report_url, "Table 2.5.1.1", sep = "; "),
      notes = "Published survey spawning-biomass estimate used as an assessment input.")
    if (!is.na(cv)) add_input("index", "biomass_index_cv", "relative_scale", cv,
      "ratio", year = r$year, year_basis = "calendar_year", survey = survey,
      source_reference = paste(report_url, "Table 2.5.1.1", sep = "; "))
  }
  if (!is.na(r$juvena_n0)) add_input("index", "recruitment_index", "numbers",
    r$juvena_n0, "reported fish count; table unit not stated", year = r$year,
    year_basis = "calendar_year", survey = "JUVENA",
    source_reference = paste(report_url, "Table 2.5.1.1", sep = "; "),
    notes = "Directly reported JUVENA N0. The table does not state the unit; do not silently rescale.")
  if (!is.na(r$juvena_cv)) add_input("index", "recruitment_index_cv", "relative_scale",
    r$juvena_cv, "ratio", year = r$year, year_basis = "calendar_year", survey = "JUVENA",
    source_reference = paste(report_url, "Table 2.5.1.1", sep = "; "),
    notes = "CV for the directly reported age-0 JUVENA N0 index.")
  for (season in c("semester_1", "semester_2")) {
    value <- r[[if (season == "semester_1") "catch_s1" else "catch_s2"]]
    if (!is.na(value)) add_input("catch", "catch_biomass", "biomass", value,
      "tonnes", year = r$year, year_basis = "calendar_year", season = season,
      fleet = "Total catch", source_reference = paste(report_url, "Table 2.5.1.1", sep = "; "),
      notes = if (r$year == 2025L) "Provisional assessment-year catch assumption." else "")
  }
}

for (i in seq_len(nrow(catch_age))) add_input("catch", "numbers_at_age", "numbers",
  catch_age$value[i], "thousand fish", year = catch_age$year[i], age = catch_age$age[i],
  year_basis = "calendar_year", season = catch_age$season[i],
  fleet = "International fishery (live bait included through 1999)",
  source_reference = paste(report_url, "Table 2.2.3.2", sep = "; "))
for (i in seq_len(nrow(catch_weight))) add_input("catch_weight", "catch_weight_at_age", "g_per_fish",
  catch_weight$value[i], "g per fish", year = catch_weight$year[i], age = catch_weight$age[i],
  year_basis = "calendar_year", season = catch_weight$season[i],
  fleet = "International fishery", source_reference = paste(report_url, "Table 2.2.4.1", sep = "; "))

for (i in seq_along(c(4951, 3430, 266))) {
  age <- i
  n_value <- c(4951, 3430, 266)[i]
  n_cv <- c(0.2133, 0.1172, 0.1798)[i]
  add_input("index", "numbers_at_age", "numbers", n_value, "million fish",
    year = 2025L, age = age, year_basis = "calendar_year", survey = "BIOMAN",
    source_reference = paste(report_url, "Table 2.3.1.4", sep = "; "),
    notes = "Published survey estimate; age 3 is the 3+ group. Model configuration is in thousands, so translation requires a documented unit conversion.")
  add_input("index", "numbers_at_age_cv", "relative_scale", n_cv, "ratio",
    year = 2025L, age = age, year_basis = "calendar_year", survey = "BIOMAN",
    source_reference = paste(report_url, "Table 2.3.1.4", sep = "; "))
}
for (i in seq_along(c(13.7, 25.1, 28.5))) add_input("weight", "spawning_weight_at_age",
  "g_per_fish", c(13.7, 25.1, 28.5)[i], "g per fish", year = 2025L,
  age = i, year_basis = "calendar_year", survey = "BIOMAN",
  source_reference = paste(report_url, "Table 2.3.1.4", sep = "; "),
  notes = "BIOMAN 2025 biological weight-at-age; kept distinct from fishery catch weight-at-age.")

for (a in 0:3) add_input("maturity", "maturity_at_age", "proportion",
  c(0, 1, 1, 1)[a + 1L], "proportion", age = a,
  source_type = "official_document", source_reference = paste(report_url, "section 2.4.1", sep = "; "),
  notes = "Fixed maturity schedule; age 3 is the 3+ group.")
for (a in 0:3) add_input("M", "natural_mortality_at_age", "per_year",
  c(2.17, 0.80, 1.20, 2.26)[a + 1L], "per year", age = a,
  source_type = "official_document", source_reference = paste(report_url, "section 2.4.2", sep = "; "),
  notes = if (a == 0L) "Fixed in 2025 run; age-0 value back-calculated with Gislason model." else if (a == 3L) "Fixed in 2025 run; age-3+ value was estimated at the 2024 benchmark and retained." else "Fixed in the 2025 run." )

output_rows <- list()
add_output <- function(type, measure, year, value, unit, lwr = NA_real_, upr = NA_real_,
                       age = NA_integer_, fleet = "", survey = "", season = "",
                       source_type = "official_table",
                       source_reference, notes = "", se = NA_real_) {
  output_rows[[length(output_rows) + 1L]] <<- make_row(output_fields, list(
    assessment_id = assessment_id, type = type, measure = measure, year = year,
    age = age, fleet = fleet, survey = survey, season = season, value = value,
    se = se, lwr = lwr, upr = upr,
    unit = unit, source_type = source_type, source_reference = source_reference,
    notes = notes))
}

for (i in seq_len(nrow(estimated_parameters))) {
  p <- estimated_parameters[i, ]
  label <- p$label
  parameter_key <- tolower(gsub("_+$", "", gsub("[^[:alnum:]]+", "_", label)))
  survey <- if (grepl("Pelgas", label, ignore.case = TRUE)) "PELGAS" else
    if (grepl("Bioman", label, ignore.case = TRUE)) "BIOMAN" else
      if (grepl("Juvena", label, ignore.case = TRUE)) "JUVENA" else ""
  fleet <- if (grepl("Commercial_vessels1", label, fixed = TRUE)) "Commercial vessels 1" else
    if (grepl("Commercial_vessels2", label, fixed = TRUE)) "Commercial vessels 2" else ""
  season <- if (grepl("seas_1", label, fixed = TRUE)) "semester_1" else
    if (grepl("seas_2", label, fixed = TRUE)) "semester_2" else ""
  unit <- if (label == "SR_LN(R0)") "log(thousand fish)" else if (
    grepl("^LnQ_base_", label)) "natural-log q" else if (
    grepl("^Q_extraSD_", label)) "log-scale SD" else "Stock Synthesis parameter scale"
  parameter_notes <- paste0("Stock Synthesis parameter label: ", label,
    ". Parm_StDev is retained as the reported SE on the original parameter scale. ",
    "Parameter status: ", p$status, "; bounds and starting values are not output estimates.")
  add_output("parameter", paste0("ss_parameter_", parameter_key), NA_integer_,
    p$value, unit, se = p$se, fleet = fleet, survey = survey, season = season,
    source_reference = paste(report_url, "Table 2.5.3.1", sep = "; "),
    notes = parameter_notes)
}

for (i in seq_len(nrow(summary_outputs))) {
  r <- summary_outputs[i, ]
  add_output("biomass", "SSB", r$year, r[[7L]], "tonnes", r[[6L]], r[[8L]],
    source_reference = paste(report_url, "Table 2.5.3.2", sep = "; "))
  add_output("recruitment", "recruitment", r$year, r[[4L]], "thousand fish", r[[3L]], r[[5L]],
    source_reference = paste(report_url, "Table 2.5.3.2", sep = "; "))
  if (!is.na(r$f)) add_output("mortality", "F_apical", r$year, r$f, "per year",
    r$f_lower, r$f_upper, source_reference = paste(report_url, "Table 2.5.3.2", sep = "; "),
    notes = "Apical F (maximum F-at-age by year); 2025 values use provisional catch input.")
}

for (i in seq_len(nrow(f_age))) {
  values <- as.numeric(unlist(f_age[i, -1L, drop = FALSE], use.names = FALSE))
  for (age in 0:3) for (season_index in 1:2) {
    season <- if (season_index == 1L) "semester_1" else "semester_2"
    add_output("mortality", "fishing_mortality_at_age", f_age$year[i],
      values[age * 2L + season_index], "per year", age = age, season = season,
      source_reference = paste(report_url, "Table 2.5.3.3", sep = "; "),
      notes = if (age == 3L) "Age 3 is the 3+ group." else "")
  }
}

for (i in seq_len(nrow(n_age))) {
  values <- as.numeric(unlist(n_age[i, -1L, drop = FALSE], use.names = FALSE))
  for (age in 0:3) add_output("population", "numbers_at_age", n_age$year[i],
    values[age + 1L], "thousand fish", age = age,
    source_reference = paste(report_url, "Table 2.5.3.4", sep = "; "),
    notes = if (age == 3L) "Age 3 is the 3+ group." else "")
  add_output("population", "total_numbers", n_age$year[i], sum(values),
    "thousand fish", source_type = "derived_source_output",
    source_reference = paste(report_url, "Table 2.5.3.4", sep = "; "),
    notes = "Derived by summing the four reported N-at-age groups; age 3 is 3+.")
}

assumption_rows <- list()
add_assumption <- function(component, setting, value, source_reference, notes = "") {
  assumption_rows[[length(assumption_rows) + 1L]] <<- make_row(assumption_fields, list(
    assessment_id = assessment_id, component = component, setting = setting,
    value = value, source_reference = source_reference, notes = notes))
}
add_assumption("model", "model_family", "Stock Synthesis 3.30.22.beta",
  paste(report_url, "assessment section", sep = "; "))
add_assumption("model", "assessment_key", "21265",
  "https://standardgraphs.ices.dk/ViewSourceData.aspx?key=21265")
add_assumption("model", "age_structure", "Ages 0, 1, 2, and 3+ in the fitted model",
  paste(report_url, "Table 2.5.2.1", sep = "; "),
  "The source catch table is preserved at ages 0-5; fitted age composition is grouped to 3+.")
add_assumption("model", "season_structure", "January-June and July-December",
  paste(report_url, "Table 2.5.2.1", sep = "; "))
add_assumption("model", "spawning_date", "15 May",
  paste(report_url, "section 2.5.2", sep = "; "))
add_assumption("model", "recruitment_settlement", "1 July",
  paste(report_url, "section 2.5.2", sep = "; "))
add_assumption("survey", "sampling_time", "Exact model sampling fractions unresolved",
  paste(annex_url, "survey timing description", sep = "; "),
  "Report describes BIOMAN and PELGAS as spring surveys and JUVENA as autumn; no exact fitted fractions are entered.")
add_assumption("mortality", "natural_mortality_at_age", "2.17, 0.80, 1.20, 2.26 per year at ages 0, 1, 2, 3+",
  paste(report_url, "section 2.4.2", sep = "; "),
  "Fixed for the 2025 run; age-0 M was derived with Gislason and age-3+ M was retained from the 2024 benchmark.")
add_assumption("biology", "maturity_at_age", "0 at age 0; 1 at ages 1, 2, 3+",
  paste(report_url, "section 2.4.1", sep = "; "))
assumption_rows <- make_rows(assumption_fields, assumption_rows)
input_rows <- make_rows(input_fields, input_rows)
output_rows <- make_rows(output_fields, output_rows)

existing_stocks <- read_csv("database/stocks.csv")
existing_assessments <- read_csv("database/assessments.csv")
append_one <- function(path, proposed, id_field, existing) {
  rows <- existing[existing[[id_field]] == proposed[[id_field]][1L], , drop = FALSE]
  if (!nrow(rows)) append_csv(path, proposed)
  else if (nrow(rows) != 1L || !identical(unlist(normalize_rows(rows[names(proposed)]), use.names = FALSE),
      unlist(normalize_rows(proposed), use.names = FALSE))) {
    stop("Existing ", id_field, " conflicts with the reviewed record.", call. = FALSE)
  }
}
existing_stock <- existing_stocks[existing_stocks$stock_id == stock_id, , drop = FALSE]
existing_assessment <- existing_assessments[existing_assessments$assessment_id == assessment_id, , drop = FALSE]
if (any(existing_stocks$authority_stock_id == "ane.27.8", na.rm = TRUE) && !nrow(existing_stock)) {
  stop("ICES ane.27.8 already exists under a different stock identifier.", call. = FALSE)
}
assumptions_existing <- if (nrow(existing_assessment)) read_assessment_rows("database/assumptions.csv", assessment_id) else empty_csv("database/assumptions.csv")
inputs_existing <- if (nrow(existing_assessment)) read_assessment_rows("database/inputs.csv", assessment_id) else empty_csv("database/inputs.csv")
outputs_existing <- if (nrow(existing_assessment)) read_assessment_rows("database/outputs.csv", assessment_id) else empty_csv("database/outputs.csv")
blank_apical_f_rows <- if (nrow(outputs_existing)) outputs_existing[
  outputs_existing$measure == "F_apical" &
    (is.na(outputs_existing$value) | !nzchar(outputs_existing$value)), , drop = FALSE] else outputs_existing
if (write_mode && nrow(blank_apical_f_rows)) {
  removed <- remove_blank_apical_f_rows("database/outputs.csv")
  if (removed != nrow(blank_apical_f_rows)) stop("Blank apical-F row cleanup count changed unexpectedly.", call. = FALSE)
  outputs_existing <- read_assessment_rows("database/outputs.csv", assessment_id)
}

assumption_key <- intersect(c("assessment_id", "component", "fleet", "survey", "sex", "region", "season", "setting"), assumption_fields)
input_key <- intersect(c("assessment_id", "type", "measure", "basis", "fleet", "survey", "sex", "region", "season", "year", "year_basis", "age", "observation_id", "partition"), input_fields)
output_key <- intersect(c("assessment_id", "type", "measure", "fleet", "survey", "sex", "region", "season", "year", "age", "age_group", "scenario"), output_fields)
assumptions_to_add <- rows_to_add(assumptions_existing, assumption_rows, assumption_key, "Assumption")
inputs_to_add <- rows_to_add(inputs_existing, input_rows, input_key, "Input")
outputs_to_add <- rows_to_add(outputs_existing, output_rows, output_key, "Output")

cat("Bay of Biscay anchovy (ane.27.8), 2025 source import\n")
cat("  assumptions: ", nrow(assumptions_to_add), " new of ", nrow(assumption_rows), "\n", sep = "")
cat("  inputs: ", nrow(inputs_to_add), " new of ", nrow(input_rows), "\n", sep = "")
cat("  outputs: ", nrow(outputs_to_add), " new of ", nrow(output_rows), "\n", sep = "")
if (nrow(blank_apical_f_rows)) cat("  blank apical-F rows to remove: ", nrow(blank_apical_f_rows), "\n", sep = "")
cat("  source gaps: historical survey age values, exact survey timing, native model inputs, 2025 first-semester catch-at-age, and age-specific output uncertainty remain unresolved.\n")
if (!write_mode) {
  cat("Dry run only. Add --write to append the reviewed rows.\n")
} else {
  append_one("database/stocks.csv", stock_row, "stock_id", existing_stocks)
  append_one("database/assessments.csv", assessment_row, "assessment_id", existing_assessments)
  append_csv("database/assumptions.csv", assumptions_to_add)
  append_csv("database/inputs.csv", inputs_to_add)
  append_csv("database/outputs.csv", outputs_to_add)

  register_path <- file.path("discovery", "candidates.csv")
  register <- read.csv(register_path, stringsAsFactors = FALSE, check.names = FALSE,
    na.strings = c("", "NA"))
  candidate_row <- which(register$candidate_id == candidate_id)
  if (length(candidate_row) != 1L) stop("Expected one selected candidate register row.", call. = FALSE)
  register$matched_stock_id[candidate_row] <- stock_id
  register$match_status[candidate_row] <- "matched"
  register$import_status[candidate_row] <- "partial"
  register$catch_age_evidence[candidate_row] <- "Table 2.2.3.2 catch-at-age for ages 0-5 by semester is imported through 2024. Table 2.5.2.1 describes 2025 first-semester age data in the model configuration, but that numerical series is not available in the reviewed report table; 2025 catch biomass remains provisional and is imported separately."
  register$survey_age_evidence[candidate_row] <- "Table 2.5.1.1 aggregate PELGAS/BIOMAN SSB and CV and JUVENA N0/CV are imported. JUVENA N0 is kept at its reported scale because the table does not state a unit. The model-configuration table lists PELGAS and BIOMAN age-series coverage but contains no numeric annual observations. BIOMAN 2025 numbers-at-age and CVs are imported from Table 2.3.1.4 in million fish; the model uses thousands, so translation requires a documented conversion. Historical age series remain graphical and unimported."
  register$weights_evidence[candidate_row] <- "Catch weights-at-age by semester through 2024 and BIOMAN 2025 spawning weights-at-age are imported in grams per fish. Historical spawning weights remain graphical/unrecovered."
  register$maturity_evidence[candidate_row] <- "Fixed maturity-at-age 0, 1, 1, 1 for ages 0, 1, 2, 3+ imported from section 2.4.1."
  register$mortality_evidence[candidate_row] <- "Fixed M-at-age 2.17, 0.80, 1.20, 2.26 per year at ages 0, 1, 2, 3+ imported from section 2.4.2; age 0 is Gislason-derived and age 3+ retained from the 2024 benchmark."
  register$timing_evidence[candidate_row] <- "Two seasons, spawning date, and recruitment settlement are recorded. Exact model sampling fractions for BIOMAN, PELGAS, and JUVENA remain unresolved."
  register$output_evidence[candidate_row] <- "Annual SSB, recruitment, and apical F with reported 95% intervals are imported through 2025; seasonal F-at-age and beginning-of-year N-at-age are imported through 2024. The 16 non-deviation Stock Synthesis parameter estimates and reported SEs from Table 2.5.3.1 are imported. Total N is derived from reported age groups; age-specific output uncertainty is unavailable."
  register$decision_reason[candidate_row] <- "Partially curated the latest official detailed assessment. Inputs and outputs are recoverable from report tables, while historical survey age-specific observations, exact survey timing, and native model data remain unavailable; keep the canonical record partial."
  note_suffix <- "Partial source import completed; see discovery/source_reviews/ices_bay_biscay_anchovy_2025.md and scripts/database/611_import_ices_bay_biscay_anchovy_2025.R."
  old_notes <- sub(" Partial source import completed;.*$", "", register$notes[candidate_row])
  register$notes[candidate_row] <- paste0(old_notes, " ", note_suffix)
  source(file.path("scripts", "database", "candidate_register_io.R"))
  replace_candidate_register_row(register_path, candidate_row, register[candidate_row, , drop = FALSE], candidate_id)

  selected_path <- file.path("discovery", "selected_batch_19_2026.csv")
  selected <- read.csv(selected_path, stringsAsFactors = FALSE, check.names = FALSE)
  selected_row <- which(selected$candidate_id == candidate_id)
  if (length(selected_row) == 1L) {
    selected$curation_status[selected_row] <- "partial_source_import"
    utils::write.csv(selected, selected_path, row.names = FALSE, na = "")
  }
  source(file.path("scripts", "database", "195_summarize_discovery.R"), local = new.env(parent = globalenv()))
  source(file.path("scripts", "database", "196_summarize_inventory_units.R"), local = new.env(parent = globalenv()))
  cat("Appended the partial canonical source record and updated the discovery register.\n")
}
