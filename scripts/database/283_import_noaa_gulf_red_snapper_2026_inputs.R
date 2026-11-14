root <- "."
assessment_id <- "noaa_gulf_red_snapper_2026"
candidate_id <- "NOAA:10230"
source_dir <- "source_cache/discovery_noaa_gom_red_snapper_2026"
manifest <- read.csv("provenance/discovery_noaa_gom_red_snapper_2026/sources.csv",
  stringsAsFactors = FALSE, check.names = FALSE, colClasses = "character")
write_mode <- "--write" %in% commandArgs(trailingOnly = TRUE) ||
  identical(Sys.getenv("SAIO_IMPORT_WRITE"), "true")

source("scripts/database/pacific_tables.R")
source("scripts/database/candidate_register_io.R")

sha256_file <- function(path) {
  if (.Platform$OS.type == "windows") {
    x <- system2("certutil.exe", c("-hashfile", shQuote(path), "SHA256"),
      stdout = TRUE, stderr = FALSE)
    x <- toupper(trimws(grep("^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$", x, value = TRUE)))
  } else {
    x <- system2("sha256sum", shQuote(path), stdout = TRUE, stderr = FALSE)
    x <- toupper(strsplit(x, "[[:space:]]+")[[1L]][1L])
  }
  if (length(x) != 1L) stop("Could not hash source file: ", path, call. = FALSE)
  x
}
verify_source <- function(name) {
  row <- manifest[manifest$file == name, , drop = FALSE]
  path <- file.path(source_dir, name)
  if (nrow(row) != 1L || !file.exists(path) ||
      !identical(sha256_file(path), toupper(row$sha256))) {
    stop("Cached source differs from the pinned provenance manifest: ", name,
      call. = FALSE)
  }
  path
}
numeric_cells <- function(line) {
  starts <- gregexpr("[0-9]+(?:,[0-9]{3})*(?:\\.[0-9]+)?", line, perl = TRUE)[[1L]]
  if (starts[1L] < 0L) return(data.frame(value = numeric(), end = integer()))
  tokens <- regmatches(line, list(starts))[[1L]]
  data.frame(value = as.numeric(gsub(",", "", tokens, fixed = TRUE)),
    end = starts + nchar(tokens) - 1L)
}

parse_commercial_landings <- function(pages) {
  out <- list()
  fields <- c(
    "Handline Plus|Central", "Handline Plus|East", "Handline Plus|West",
    "Longline|Central", "Longline|East", "Longline|West"
  )
  for (page in 13:14) {
    lines <- strsplit(pages[[page]], "\n", fixed = TRUE)[[1L]]
    data_lines <- lines[grepl("^\\s*(19|20)[0-9]{2}\\s+", lines)]
    parsed <- lapply(data_lines, numeric_cells)
    full_row <- which(vapply(parsed, nrow, integer(1)) == 7L)
    if (!length(full_row)) stop("No full commercial landings row on DW-02 page ", page, ".")
    reference_end <- parsed[[full_row[1L]]]$end[-1L]
    for (i in seq_along(data_lines)) {
      cells <- parsed[[i]]
      if (nrow(cells) < 2L || nrow(cells) > 7L) {
        stop("Unexpected commercial landings row on DW-02 page ", page, ".")
      }
      year <- as.integer(cells$value[1L])
      if (year < 1964L || year > 2023L) next
      assigned <- rep(NA_real_, length(fields))
      for (j in 2:nrow(cells)) {
        column <- which.min(abs(reference_end - cells$end[j]))
        if (abs(reference_end[column] - cells$end[j]) > 3L || !is.na(assigned[column])) {
          stop("Could not align commercial landings columns on DW-02 page ", page, ".")
        }
        assigned[column] <- cells$value[j]
      }
      for (column in which(!is.na(assigned))) {
        parts <- strsplit(fields[column], "|", fixed = TRUE)[[1L]]
        out[[length(out) + 1L]] <- data.frame(
          year = year, fleet = parts[1L], region = parts[2L],
          value = assigned[column], stringsAsFactors = FALSE
        )
      }
    }
  }
  result <- do.call(rbind, out)
  if (!setequal(unique(result$year), 1964:2023) ||
      anyDuplicated(result[c("year", "fleet", "region")])) {
    stop("DW-02 Table 4 did not produce unique commercial landings for 1964-2023.")
  }
  result
}

parse_commercial_discards <- function(pages, page_ids, table_number, fleet) {
  rows <- list()
  region <- NA_character_
  for (page in page_ids) {
    lines <- strsplit(pages[[page]], "\n", fixed = TRUE)[[1L]]
    for (line in lines) {
      if (grepl("Zone (East)", line, fixed = TRUE)) region <- "East"
      if (grepl("Zone (Central)", line, fixed = TRUE)) region <- "Central"
      if (grepl("Zone (West)", line, fixed = TRUE)) region <- "West"
      if (!grepl("^\\s*(19|20)[0-9]{2}\\s+(Open|Closed)\\b", line,
          ignore.case = TRUE)) next
      if (is.na(region)) stop("Discard table area was not identified.")
      cells <- numeric_cells(line)$value
      if (!length(cells) || !cells[1L] %in% 1996:2023) next
      if (!length(cells) %in% c(3L, 5L)) {
        stop("Unexpected discard row in DW-03 Table ", table_number, ".")
      }
      status <- tolower(sub("^\\s*(19|20)[0-9]{2}\\s+(Open|Closed).*", "\\2",
        line, ignore.case = TRUE))
      rows[[length(rows) + 1L]] <- data.frame(
        year = as.integer(cells[1L]), season = status, region = region,
        fleet = fleet, table = table_number,
        discard_weight = if (length(cells) == 5L) cells[2L] else NA_real_,
        discard_weight_se = if (length(cells) == 5L) cells[3L] else NA_real_,
        discard_numbers = if (length(cells) == 5L) cells[4L] else cells[2L],
        discard_numbers_se = if (length(cells) == 5L) cells[5L] else cells[3L],
        stringsAsFactors = FALSE
      )
    }
  }
  result <- do.call(rbind, rows)
  if (nrow(result) != 117L ||
      !setequal(unique(result$region), c("East", "Central", "West")) ||
      !setequal(unique(result$year), 1996:2023) ||
      sum(!is.na(result$discard_weight)) != 51L ||
      sum(is.na(result$discard_weight)) != 66L ||
      anyDuplicated(result[c("year", "season", "region")])) {
    stop("DW-03 Table ", table_number, " has unexpected area/year coverage.")
  }
  result
}

parse_recreational_catch <- function(pages) {
  pages_by_region <- list(West = 20:22, Central = 23:25, East = 26:28)
  mode_columns <- list(Headboat = c(1L, 2L),
    Charterboat = c(3L, 4L), Private = c(5L, 6L))
  rows <- list()
  for (region in names(pages_by_region)) {
    for (page in pages_by_region[[region]]) {
      lines <- strsplit(pages[[page]], "\n", fixed = TRUE)[[1L]]
      data_lines <- lines[grepl(
        "^\\s*(19|20)[0-9]{2}\\s+(open|closed)\\b", lines, ignore.case = TRUE
      )]
      for (line in data_lines) {
        cells <- numeric_cells(line)$value
        if (!length(cells) || !cells[1L] %in% 1981:2023) next
        values <- cells[-1L]
        row_values <- rep(NA_real_, 8L)
        if (length(values) == 8L) {
          row_values[] <- values
        } else if (length(values) == 6L) {
          row_values[3:8] <- values
        } else {
          stop("Unexpected recreational catch row on DW-05 page ", page, ".")
        }
        year <- as.integer(cells[1L])
        partition <- if (grepl("\\bclosed\\b", line, ignore.case = TRUE)) {
          "federal_closed"
        } else {
          "federal_open"
        }
        table_number <- if (region == "West") "2.1" else
          if (region == "Central") "2.2" else "2.3"
        for (fleet in names(mode_columns)) {
          for (j in seq_along(mode_columns[[fleet]])) {
            column <- mode_columns[[fleet]][j]
            value <- row_values[column]
            if (is.na(value)) next
            rows[[length(rows) + 1L]] <- data.frame(
              year = year, partition = partition, region = region,
              fleet = fleet,
              measure = if (j == 1L) "landings_numbers" else "discard_numbers",
              value = value, table = table_number, stringsAsFactors = FALSE
            )
          }
        }
        if (!is.na(row_values[7L]) && all(!is.na(row_values[c(1L, 3L, 5L)])) &&
            abs(sum(row_values[c(1L, 3L, 5L)]) - row_values[7L]) > 1) {
          stop("DW-05 Table ", table_number, " landings total does not match its modes.")
        }
        if (!is.na(row_values[8L]) && all(!is.na(row_values[c(2L, 4L, 6L)])) &&
            abs(sum(row_values[c(2L, 4L, 6L)]) - row_values[8L]) > 1) {
          stop("DW-05 Table ", table_number, " discard total does not match its modes.")
        }
      }
    }
  }
  result <- do.call(rbind, rows)
  source_rows <- unique(result[c("year", "partition", "region", "table")])
  if (nrow(source_rows) != 258L ||
      !setequal(unique(result$year), 1981:2023) ||
      !setequal(unique(result$region), c("West", "Central", "East")) ||
      !all(c("federal_open", "federal_closed") %in% unique(result$partition))) {
    stop("DW-05 Tables 2.1-2.3 have unexpected year/area/status coverage.")
  }
  result
}

parse_recreational_discard_cv <- function(pages) {
  pages_by_region <- list(West = 44:48, Central = 49:53, East = 54:58)
  rows <- list()
  for (region in names(pages_by_region)) {
    page_ids <- pages_by_region[[region]]
    page_lines <- unlist(lapply(page_ids, function(page)
      strsplit(pages[[page]], "\n", fixed = TRUE)[[1L]]), use.names = FALSE)
    data_lines <- page_lines[grepl("^\\s*(19|20)[0-9]{2}\\s+", page_lines)]
    numeric_rows <- lapply(data_lines, function(line)
      numeric_cells(gsub("\\([^)]*\\)", "", line, perl = TRUE)))
    full_rows <- which(vapply(numeric_rows, nrow, integer(1)) == 13L)
    if (!length(full_rows)) stop("No full recreational discard CV row for ", region, ".")
    for (i in seq_along(data_lines)) {
      cells <- numeric_rows[[i]]
      if (nrow(cells) < 2L) next
      year <- as.integer(cells$value[1L])
      if (!year %in% 1981:2023) next
      data_values <- cells$value[-1L]
      if (length(data_values) == 12L) {
        fleet_positions <- list(Charterboat = 1:4, Headboat = 5:8,
          Private = 9:12)
      } else if (length(data_values) == 8L) {
        fleet_positions <- list(Charterboat = 1:4, Private = 5:8)
      } else {
        stop("Unexpected recreational discard CV row for ", region,
          " in ", year, ".")
      }
      for (fleet in names(fleet_positions)) {
        position <- fleet_positions[[fleet]]
        rows[[length(rows) + 1L]] <- data.frame(
          year = year, region = region, fleet = fleet,
          value = data_values[position[1L]], cv = data_values[position[2L]],
          partition = if (grepl("\\bopen\\b", data_lines[i], ignore.case = TRUE)) {
            "federal_open"
          } else if (grepl("\\bclosed\\b", data_lines[i], ignore.case = TRUE)) {
            "federal_closed"
          } else {
            stop("Missing open/closed status in recreational discard CV table.")
          },
          table = switch(region, West = "4.1", Central = "4.2", East = "4.3"),
          stringsAsFactors = FALSE
        )
      }
    }
  }
  result <- do.call(rbind, rows)
  if (nrow(result) != 546L || !setequal(unique(result$year), 1981:2023) ||
      anyDuplicated(result[c("year", "region", "fleet", "partition")]) ||
      any(result$cv < 0, na.rm = TRUE)) {
    stop("DW-05 Tables 4.1-4.3 have unexpected discard/CV coverage: rows=",
      nrow(result), "; fleets=", paste(unique(result$fleet), collapse = ","),
      "; regions=", paste(unique(result$region), collapse = ","),
      "; years=", paste(range(result$year), collapse = "-"),
      "; duplicates=", sum(duplicated(result[c("year", "region", "fleet", "partition")])), ".")
  }
  result
}

sar_path <- verify_source("SEDAR98_SAR.pdf")
commercial_path <- verify_source("SEDAR98_DW02.pdf")
discard_path <- verify_source("SEDAR98_DW03.pdf")
recreational_path <- verify_source("SEDAR98_DW05.pdf")
sar_pages <- pdftools::pdf_text(sar_path)
commercial_pages <- pdftools::pdf_text(commercial_path)
discard_pages <- pdftools::pdf_text(discard_path)
recreational_pages <- pdftools::pdf_text(recreational_path)

commercial_landings <- parse_commercial_landings(commercial_pages)
commercial_discards <- rbind(
  parse_commercial_discards(discard_pages, 28:31, 11L, "Handline Plus"),
  parse_commercial_discards(discard_pages, 38:41, 17L, "Longline")
)
recreational_catch <- parse_recreational_catch(recreational_pages)
recreational_discard_cv <- parse_recreational_discard_cv(recreational_pages)
recreational_discard_values <- recreational_catch[
  recreational_catch$measure == "discard_numbers",
  c("year", "region", "fleet", "partition", "value"), drop = FALSE
]
recreational_discard_check <- merge(recreational_discard_values,
  recreational_discard_cv[c("year", "region", "fleet", "partition", "value")],
  by = c("year", "region", "fleet", "partition"), suffixes = c("_table2", "_table4"))
if (nrow(recreational_discard_check) != 546L ||
    any(recreational_discard_check$value_table2 != recreational_discard_check$value_table4)) {
  stop("DW-05 Tables 2.1-2.3 and 4.1-4.3 discard totals differ.")
}

m_lines <- strsplit(sar_pages[[322L]], "\n", fixed = TRUE)[[1L]]
m_rows <- lapply(m_lines, numeric_cells)
m_rows <- Filter(function(x) nrow(x) == 3L &&
  x$value[1L] == as.integer(x$value[1L]) && x$value[1L] %in% 0:20, m_rows)
m_values <- do.call(rbind, lapply(m_rows, function(x) x$value))
if (nrow(m_values) != 21L ||
    !identical(as.integer(m_values[, 1L]), 0:20) ||
    any(!is.finite(m_values)) || any(m_values[, 3L] <= 0)) {
  stop("Could not parse SEDAR 98 Table 1 adjusted natural mortality vector.")
}
m_vector <- data.frame(age = as.integer(m_values[, 1L]),
  value = m_values[, 3L], stringsAsFactors = FALSE)

input_row <- function(type, measure, basis, value, unit, source_reference,
                      notes, fleet = "", region = "", year = NA_integer_,
                      age = NA_integer_, season = "",
                      partition = "", observation_id = "",
                      transformation = "",
                      source_type = "official_table") {
  pacific_database_row("inputs", assessment_id = assessment_id,
    type = type, measure = measure, basis = basis, value = value, unit = unit,
    fleet = fleet, region = region, year = year,
    year_basis = if (is.na(year)) "" else "calendar_year",
    age = age, season = season, partition = partition,
    observation_id = observation_id, transformation = transformation,
    source_type = source_type, source_reference = source_reference,
    notes = notes)
}

commercial_landing_rows <- do.call(rbind, lapply(seq_len(nrow(commercial_landings)), function(i) {
  d <- commercial_landings[i, ]
  input_row("catch", "landings_biomass", "biomass", d$value,
    "pounds whole weight", "SEDAR98_DW02.pdf, Table 4",
    paste("Source-reported annual landings in pounds whole weight.",
      "The assessment converted commercial landings to metric tons.",
      "Table 4 begins in 1964; values for the model's earlier handline years are not inferred."),
    fleet = d$fleet, region = d$region, year = d$year)
}))

commercial_discard_rows <- do.call(rbind, lapply(seq_len(nrow(commercial_discards)), function(i) {
  d <- commercial_discards[i, ]
  reference <- paste0("SEDAR98_DW03.pdf, Table ", d$table, ", Zone ", d$region)
  number_id <- paste("DW03", d$table, d$region, d$year, d$season,
    "discard_numbers", sep = "-")
  note <- paste(
    "Source estimate and associated standard error are preserved on the natural scale as printed.",
    "The final assessment used log-scale discard standard errors; those are not reconstructed here.",
    "The source reports post-2006 discards as open-season."
  )
  number_row <- input_row("catch", "discard_numbers", "numbers",
    d$discard_numbers, "fish", reference, note,
    fleet = d$fleet, region = d$region, year = d$year,
    season = d$season, observation_id = number_id)
  number_se_row <- input_row("catch", "catch_se", "native_scale",
    d$discard_numbers_se, "fish standard error", reference,
    "Natural-scale standard error for the discard_numbers observation; do not transform.",
    fleet = d$fleet, region = d$region, year = d$year,
    season = d$season, observation_id = number_id)
  if (is.na(d$discard_weight)) return(rbind(number_row, number_se_row))
  weight_id <- paste("DW03", d$table, d$region, d$year, d$season,
    "discard_biomass", sep = "-")
  weight_row <- input_row("catch", "discard_biomass", "biomass",
    d$discard_weight, "pounds whole weight", reference, note,
    fleet = d$fleet, region = d$region, year = d$year,
    season = d$season, observation_id = weight_id)
  weight_se_row <- input_row("catch", "catch_se", "native_scale",
    d$discard_weight_se, "pounds whole weight standard error", reference,
    "Natural-scale standard error for the discard_biomass observation; do not transform.",
    fleet = d$fleet, region = d$region, year = d$year,
    season = d$season, observation_id = weight_id)
  rbind(number_row, number_se_row, weight_row, weight_se_row)
}))

recreational_catch_rows <- do.call(rbind, lapply(seq_len(nrow(recreational_catch)), function(i) {
  d <- recreational_catch[i, ]
  input_row("catch", d$measure, "numbers", d$value, "fish",
    paste0("SEDAR98_DW05.pdf, Table ", d$table),
    paste("Source-reported annual number of fish by mode, area and federal open/closed status.",
      "The table's separate Total columns are not repeated; retain the partition for aggregation."),
    fleet = d$fleet, region = d$region, year = d$year,
    partition = d$partition)
}))

recreational_landings <- recreational_catch[
  recreational_catch$measure == "landings_numbers", , drop = FALSE
]
recreational_landing_groups <- split(recreational_landings,
  interaction(recreational_landings$fleet, recreational_landings$region,
    recreational_landings$year, drop = TRUE))
recreational_landing_totals <- do.call(rbind, lapply(recreational_landing_groups, function(x) {
  if (!setequal(x$partition, c("federal_open", "federal_closed"))) return(NULL)
  data.frame(fleet = x$fleet[1L], region = x$region[1L], year = x$year[1L],
    value = sum(x$value), table = x$table[1L], stringsAsFactors = FALSE)
}))
recreational_annual_landing_rows <- do.call(rbind, lapply(seq_len(nrow(recreational_landing_totals)), function(i) {
  d <- recreational_landing_totals[i, ]
  input_row("catch", "landings_numbers", "numbers", d$value, "fish",
    paste0("SEDAR98_DW05.pdf, Table ", d$table),
    paste("Annual model input reconstructed by summing the source-reported federal-open and federal-closed estimates for this mode, area, and year.",
      "The partitioned source rows are also retained separately and are not separate assessment observations."),
    fleet = d$fleet, region = d$region, year = as.integer(d$year),
    source_type = "reconstructed_source_input",
    transformation = "Sum federal_open and federal_closed landings_numbers.")
}))

recreational_cv_rows <- do.call(rbind, lapply(seq_len(nrow(recreational_landing_totals)), function(i) {
  d <- recreational_landing_totals[i, ]
  input_row("catch", "catch_cv", "relative_scale", 0.15, "ratio",
    "SEDAR98_SAR.pdf, Assessment Report, Section 2.3.2",
    paste("The final model fixed CV at 0.15 for annual recreational landings.",
      "This applies to the annual mode-area total reconstructed from federal-open and federal-closed source rows."),
    fleet = d$fleet, region = d$region, year = as.integer(d$year),
    source_type = "official_document")
}))

recreational_discard_cv_rows <- do.call(rbind, lapply(seq_len(nrow(recreational_discard_cv)), function(i) {
  d <- recreational_discard_cv[i, ]
  if (is.na(d$cv)) return(NULL)
  input_row("catch", "catch_cv", "relative_scale", d$cv, "ratio",
    paste0("SEDAR98_DW05.pdf, Table ", d$table),
    "Source-reported CV for the recreational discard estimate in this open/closed partition.",
    fleet = d$fleet, region = d$region, year = d$year,
    partition = d$partition,
    source_type = "official_table")
}))

m_rows <- do.call(rbind, lapply(seq_len(nrow(m_vector)), function(i) {
  d <- m_vector[i, ]
  input_row("M", "natural_mortality_at_age", "per_year", d$value, "per year",
    "SEDAR98_SAR.pdf, Assessment Report, Table 1",
    paste("Fixed adjusted M-at-age used by the assessment; the source table also reports",
      "unadjusted Lorenzen M. Age 0 is fixed at 2.0 and age 1 at 1.2 per year.",
      "Age 20 is the plus group."),
    age = d$age)
}))
new_inputs <- do.call(rbind, list(
  commercial_landing_rows, commercial_discard_rows,
  recreational_catch_rows, recreational_annual_landing_rows,
  recreational_cv_rows, recreational_discard_cv_rows, m_rows
))

input_key_columns <- c(
  "assessment_id", "type", "measure", "basis", "fleet", "survey", "sex",
  "region", "season", "year", "year_basis", "age",
  "observation_id", "length_bin", "length_bin_lower", "length_bin_upper",
  "weight_bin", "age_error", "partition"
)
normalize_fields <- function(x) lapply(x, function(v) {
  v <- as.character(v)
  v[is.na(v)] <- ""
  v
})
input_key <- function(x) do.call(paste,
  c(normalize_fields(x[input_key_columns]), sep = "\r"))
input_record <- function(x) do.call(paste,
  c(normalize_fields(x), sep = "\r"))
if (anyDuplicated(input_key(new_inputs))) stop("New red snapper inputs contain duplicate keys.")

read_assessment_rows <- function(path, id) {
  header <- readLines(path, n = 1L, warn = FALSE)
  rows <- suppressWarnings(system2("rg", c("--color", "never", "--no-heading",
    "--no-line-number", "-F", id, path), stdout = TRUE, stderr = FALSE))
  status <- attr(rows, "status")
  if (is.null(status)) status <- 0L
  if (status == 1L) rows <- character()
  else if (status != 0L) stop("Could not read assessment rows from ", path, ".")
  rows <- rows[startsWith(rows, paste0('"', id, '",'))]
  if (!length(rows)) return(read.csv(text = header, stringsAsFactors = FALSE,
    na.strings = c("", "NA"), check.names = FALSE))
  read.csv(text = paste(c(header, rows), collapse = "\n"),
    stringsAsFactors = FALSE, na.strings = c("", "NA"),
    check.names = FALSE, colClasses = "character")
}
existing_inputs <- read_assessment_rows("database/inputs.csv", assessment_id)
new_keys <- input_key(new_inputs)
old_keys <- input_key(existing_inputs)
for (i in which(new_keys %in% old_keys)) {
  old <- match(new_keys[i], old_keys)
  if (!identical(input_record(new_inputs[i, , drop = FALSE]),
      input_record(existing_inputs[old, , drop = FALSE]))) {
    stop("An existing red snapper input has the same key but different source data.")
  }
}
missing_inputs <- new_inputs[!new_keys %in% old_keys, , drop = FALSE]

assumption_rows <- list(
  pacific_database_row("assumptions", assessment_id = assessment_id,
    component = "catch", setting = "commercial_landings",
    value = "Handline Plus and Longline annual landings, 1964-2023, by area.",
    source_reference = "SEDAR98_DW02.pdf, Table 4",
    notes = paste("Preserved in pounds whole weight. The assessment model uses metric tons.",
      "The report's model period begins in 1950; Table 4 does not provide 1950-1963 values.")),
  pacific_database_row("assumptions", assessment_id = assessment_id,
    component = "catch", setting = "recreational_landings_and_discards",
    value = "Tables 2.1-2.3 report area- and mode-specific landings/discards for 1981-2023.",
    source_reference = "SEDAR98_DW05.pdf, Tables 2.1-2.3",
    notes = paste("Values are in fish and retain the source FED_CLOSED open/closed partition.",
      "Annual model landings are reconstructed by summing open and closed source rows; the model uses thousands of fish and fixed CV 0.15.",
      "Discard estimates and CVs are retained by source status; Tables 4.1-4.3 CV values match the Table 2 discard estimates.",
      "The model's historical 1955-1980 recreational landings are not tabulated here.")),
  pacific_database_row("assumptions", assessment_id = assessment_id,
    component = "catch", setting = "commercial_discards",
    value = "Vertical-line and bottom-longline discard estimates, 1996-2023.",
    source_reference = "SEDAR98_DW03.pdf, Tables 11 and 17",
    notes = paste("Source numbers and available weights, with natural-scale SEs, are retained.",
      "The assessment uses discards in thousands of fish with log-scale SE settings.")),
  pacific_database_row("assumptions", assessment_id = assessment_id,
    component = "observation", setting = "commercial_landing_cv",
    value = "CV 0.05 before 1990; Data Workshop recommended CVs from 1990-2023.",
    source_reference = "SEDAR98_SAR.pdf, Assessment Report, Section 2.3.1",
    notes = "The annual post-1990 values are not tabulated at the fleet-area resolution used by the model."),
  pacific_database_row("assumptions", assessment_id = assessment_id,
    component = "observation", setting = "recreational_landing_cv",
    value = "Fixed CV 0.15 for annual recreational landings.",
    source_reference = "SEDAR98_SAR.pdf, Assessment Report, Section 2.3.2",
    notes = "This differs from the Data Workshop uncertainty estimates; the final model fixed the CV for stability."),
  pacific_database_row("assumptions", assessment_id = assessment_id,
    component = "observation", setting = "recreational_discard_uncertainty",
    value = "Data Workshop annual uncertainty estimates were used for recreational discards, 1981-2023.",
    source_reference = "SEDAR98_SAR.pdf, Assessment Report, Section 2.3.4; SEDAR98_DW05.pdf, Tables 4.1-4.3",
    notes = "The published tables report CVs, now retained by mode, area, year and FED_CLOSED status. The assessment's conversion to likelihood-scale standard errors is not reconstructed.")
)

upsert_small_csv <- function(path, id_column, id, key_columns, updates, additions = list()) {
  bytes <- readBin(path, "raw", n = file.info(path)$size)
  table <- read.csv(path,
    stringsAsFactors = FALSE, na.strings = c("", "NA"),
    check.names = FALSE, colClasses = "character")
  serialize_row <- function(row) {
    tmp <- tempfile()
    on.exit(unlink(tmp), add = TRUE)
    write.table(row, tmp, sep = ",", row.names = FALSE, col.names = FALSE,
      quote = TRUE, na = "", qmethod = "double", eol = "\n")
    raw <- readBin(tmp, "raw", n = file.info(tmp)$size)
    if (length(raw) && tail(raw, 1L) == as.raw(10L)) raw <- raw[-length(raw)]
    if (length(raw) && tail(raw, 1L) == as.raw(13L)) raw <- raw[-length(raw)]
    raw
  }
  replace_row <- function(bytes, row_index, row) {
    bounds <- csv_record_bounds(bytes)
    record_index <- row_index + 1L
    if (record_index < 2L || record_index > length(bounds$start)) {
      stop("CSV record index is out of range in ", basename(path), ".")
    }
    first <- bounds$start[record_index]
    last <- bounds$end[record_index]
    next_byte <- last + 1L
    has_carriage_return <- FALSE
    while (next_byte <= length(bytes) && bytes[next_byte] == as.raw(13L)) {
      has_carriage_return <- TRUE
      next_byte <- next_byte + 1L
    }
    line_ending <- raw(0L)
    if (next_byte <= length(bytes) && bytes[next_byte] == as.raw(10L)) {
      line_ending <- c(if (has_carriage_return) as.raw(13L) else raw(0L), as.raw(10L))
      next_byte <- next_byte + 1L
    }
    prefix <- if (first > 1L) bytes[seq_len(first - 1L)] else raw(0L)
    suffix <- if (next_byte <= length(bytes)) bytes[next_byte:length(bytes)] else raw(0L)
    c(prefix, serialize_row(row), line_ending, suffix)
  }
  normalized_cell <- function(x) {
    x <- as.character(x)
    if (!length(x) || is.na(x) || !nzchar(x)) "" else x
  }
  for (update in updates) {
    hit <- table[[id_column]] == id
    for (key in names(update$key)) hit <- hit & table[[key]] == update$key[[key]]
    row_index <- which(hit)
    if (length(row_index) != 1L) stop("Could not uniquely identify ", basename(path),
      " row for ", paste(names(update$key), update$key, sep = "=", collapse = ", "),
      " (matches: ", length(row_index), ").")
    for (field in names(update$values)) table[row_index, field] <- update$values[[field]]
    bytes <- replace_row(bytes, row_index, table[row_index, , drop = FALSE])
  }
  for (addition in additions) {
    hit <- table[[id_column]] == id
    for (key in key_columns) hit <- hit & table[[key]] == addition[[key]]
    row_index <- which(hit)
    if (length(row_index) > 1L) stop("Duplicate assumption key in ", basename(path), ".")
    if (length(row_index) == 1L) {
      for (field in names(addition)) {
        if (!identical(normalized_cell(table[row_index, field]),
            normalized_cell(addition[[field]]))) {
          stop("Existing assumption differs for setting ", addition$setting, ".")
        }
      }
    } else {
      newline <- if (length(bytes) >= 2L &&
          bytes[length(bytes) - 1L] == as.raw(13L) &&
          bytes[length(bytes)] == as.raw(10L)) c(as.raw(13L), as.raw(10L)) else as.raw(10L)
      if (length(bytes) && tail(bytes, 1L) != as.raw(10L)) bytes <- c(bytes, newline)
      bytes <- c(bytes, serialize_row(addition), newline)
      table <- rbind(table, addition)
    }
  }
  writeBin(bytes, path)
}

update_database_metadata <- function() {
  assumption_updates <- list(
    list(key = c(component = "M", setting = "natural_mortality"),
      values = list(
        value = "Fixed age-specific Lorenzen M vector; base M(age 0)=0.86 and M(age 1)=0.64 per year, adjusted to 2.0 and 1.2; ages 2-20 use the adjusted vector in Table 1.",
        notes = "The imported natural_mortality_at_age rows store the adjusted M values used by the model; M is fixed over years and areas."
      )),
    list(key = c(component = "biology", setting = "maturity"),
      values = list(
        value = "Fixed logistic age-maturity parameters: East/Central MA50=1.95 and M SlopeA50=-1.57; West MA50=2.47 and M SlopeA50=-1.18.",
        notes = "Central and East use the East-area estimates. Numerical age-specific proportions are not tabulated and have not been derived."
      )),
    list(key = c(component = "biology", setting = "weight_at_age"),
      values = list(
        value = "A fixed length-weight relationship and estimated area-specific growth parameters generate weight at age within Stock Synthesis.",
        notes = "A standalone annual weight-at-age input vector was not located in the reviewed sources."
      ))
  )
  upsert_small_csv("database/assumptions.csv", "assessment_id", assessment_id,
    c("component", "setting"), assumption_updates, assumption_rows)
  assessment_updates <- list(list(key = c(), values = list(
    notes = paste(
      "Latest detailed run located for NOAA:10230; final report released in October 2026.",
      "SSC review was pending, so is_applied=FALSE. Source inputs now include aggregate indices,",
      "commercial and recreational catches, reported discard errors, and fixed M-at-age.",
      "Catch compositions, numerical age-specific maturity/weight surfaces, and age-specific N/F remain incomplete.",
      "See discovery/source_reviews/noaa_gulf_red_snapper_2026.md."
    )
  )))
  upsert_small_csv("database/assessments.csv", "assessment_id", assessment_id,
    character(), assessment_updates)
  candidate_path <- "discovery/candidates.csv"
  candidates <- read.csv(candidate_path, stringsAsFactors = FALSE,
    na.strings = c("", "NA"), check.names = FALSE, colClasses = "character")
  candidate_row <- which(candidates$candidate_id == candidate_id)
  if (length(candidate_row) != 1L) stop("Candidate ID is not unique.")
  candidates$matched_stock_id[candidate_row] <- "noaa_gulf_red_snapper"
  candidates$match_status[candidate_row] <- "matched"
  candidates$import_status[candidate_row] <- "partial"
  candidates$catch_age_evidence[candidate_row] <- paste(
    "Commercial landings are imported for 1964-2023 from SEDAR98-DW-02 Table 4 in pounds whole weight.",
    "Commercial vertical-line and bottom-longline discard estimates for 1996-2023, with source SEs,",
    "are imported from DW-03 Tables 11 and 17. Recreational landings and discards by mode, area and",
    "federal open/closed status for 1981-2023 are imported from DW-05 Tables 2.1-2.3.",
    "These are aggregate removals; numerical catch-at-age likelihood arrays are not available."
  )
  candidates$survey_age_evidence[candidate_row] <- paste(
    "Aggregate mean-one-scaled abundance indices and source CVs from SEDAR 98 Tables 5.8.1-5.8.3 are imported.",
    "Age compositions for some survey fleets are described separately and may be derived from age-length keys;",
    "their numerical likelihood arrays were not available in the reviewed sources."
  )
  candidates$weights_evidence[candidate_row] <- paste(
    "Stock weights at age are generated from estimated area-specific growth and fixed length-weight relationships.",
    "A standalone numerical weight-at-age vector is not published in the reviewed sources."
  )
  candidates$maturity_evidence[candidate_row] <- paste(
    "Fixed logistic maturity parameters are imported for East/Central and West from final report Table 2.",
    "A numerical maturity-at-age vector is not published in the reviewed sources."
  )
  candidates$mortality_evidence[candidate_row] <- paste(
    "The fixed adjusted natural-mortality vector at ages 0-20+ is imported from the final report Table 1.",
    "It is time-invariant and fixed across model areas."
  )
  candidates$notes[candidate_row] <- paste(
    "Official aggregate catches, fixed M, survey index series and summary outputs are imported.",
    "The final model's numerical composition arrays, age-specific biological surfaces, and age-specific N/F outputs remain unavailable.",
    "See discovery/source_reviews/noaa_gulf_red_snapper_2026.md."
  )
  replace_candidate_register_row(candidate_path, candidate_row,
    candidates[candidate_row, , drop = FALSE], candidate_id)
}

if (!write_mode) {
  cat(
    "Dry run: ", nrow(commercial_landing_rows), " commercial landings rows; ",
    sum(commercial_discard_rows$measure == "discard_numbers"), " commercial discard-number rows; ",
    sum(commercial_discard_rows$measure == "discard_biomass"), " commercial discard-biomass rows; ",
    sum(recreational_catch_rows$measure == "landings_numbers"), " recreational landings rows; ",
    sum(recreational_catch_rows$measure == "discard_numbers"), " recreational discard rows; ",
    nrow(recreational_annual_landing_rows), " reconstructed annual recreational landings rows; ",
    nrow(recreational_cv_rows), " fixed recreational landings-CV rows; ",
    nrow(recreational_discard_cv_rows), " source recreational discard-CV rows; ",
    nrow(m_rows), " fixed M-at-age rows; ", nrow(missing_inputs),
    " rows to append.\n",
    sep = ""
  )
  print(table(new_inputs$measure))
} else {
  if (nrow(missing_inputs)) {
    write.table(missing_inputs, "database/inputs.csv", sep = ",",
      row.names = FALSE, col.names = FALSE, append = TRUE, na = "")
  }
  update_database_metadata()
  cat("Imported ", nrow(missing_inputs), " new Gulf red snapper source-input rows.\n",
    sep = "")
}
