root <- "."
assessment_id <- "nefsc_haddock_georges_bank_2026"
assessment_path <- file.path(root, "database", "assessments.csv")
outputs_path <- file.path(root, "database", "outputs.csv")
source_url <- paste0(
  "https://apps-nefsc.fisheries.noaa.gov/saw/sasi_files.php?year=2026&species_id=5&",
  "stock_id=1&review_type_id=6&info_type_id=-1&map_type_id=&",
  "filename=Georges_Bank_haddock_Update_2026_06_17_100805.801712.pdf"
)
report_text <- file.path(
  root, "source_cache", "nefsc_haddock_georges_bank_2026",
  "2026_assessment_text.txt"
)

if (!file.exists(report_text)) {
  stop("The cached 2026 assessment report text is required.", call. = FALSE)
}

lines <- readLines(report_text, warn = FALSE, encoding = "UTF-8")
projection_lines <- lines[grepl("^(202[6-9]|203[01])[[:space:]]+[0-9,]+[[:space:]]", lines)]
if (length(projection_lines) != 6L) {
  stop("Expected six annual rows in Table 3.", call. = FALSE)
}

parse_row <- function(line) {
  numbers <- regmatches(line, gregexpr("[0-9][0-9,]*(\\.[0-9]+)?", line))[[1L]]
  as.numeric(gsub(",", "", numbers, fixed = TRUE))
}

rows <- lapply(projection_lines, parse_row)
years <- vapply(rows, `[[`, numeric(1), 1L)
if (!identical(years, as.numeric(2026:2031)) || any(lengths(rows) != 8L)) {
  stop("Table 3 year or value layout did not match the published table.", call. = FALSE)
}

projection <- data.frame(
  year = years,
  catch = vapply(rows, `[[`, numeric(1), 2L),
  catch_lwr = vapply(rows, function(x) if (x[[1L]] == 2026) NA_real_ else x[[3L]], numeric(1)),
  catch_upr = vapply(rows, function(x) if (x[[1L]] == 2026) NA_real_ else x[[4L]], numeric(1)),
  SSB = vapply(rows, function(x) if (x[[1L]] == 2026) x[[3L]] else x[[5L]], numeric(1)),
  SSB_lwr = vapply(rows, function(x) if (x[[1L]] == 2026) x[[4L]] else x[[6L]], numeric(1)),
  SSB_upr = vapply(rows, function(x) if (x[[1L]] == 2026) x[[5L]] else x[[7L]], numeric(1)),
  Fbar = vapply(rows, function(x) if (x[[1L]] == 2026) x[[6L]] else x[[8L]], numeric(1)),
  Fbar_lwr = vapply(rows, function(x) if (x[[1L]] == 2026) x[[7L]] else NA_real_, numeric(1)),
  Fbar_upr = vapply(rows, function(x) if (x[[1L]] == 2026) x[[8L]] else NA_real_, numeric(1))
)

assessment_bytes <- readBin(assessment_path, what = "raw",
  n = file.info(assessment_path)$size)
old_record <- paste0(assessment_id, ",nefsc_haddock_georges_bank,2026,2025,2025,annual")
new_record <- sub(",2025,2025,annual", ",2025,2031,annual", old_record, fixed = TRUE)
find_record <- function(text, pattern) {
  location <- gregexpr(pattern, text, fixed = TRUE)[[1L]]
  if (location[[1L]] == -1L) integer() else location
}
replace_once <- function(bytes, old, new) {
  text <- rawToChar(bytes)
  old_location <- find_record(text, old)
  new_location <- find_record(text, new)
  if (length(old_location) == 1L && !length(new_location)) {
    before <- if (old_location == 1L) raw() else bytes[seq_len(old_location - 1L)]
    after_start <- old_location + length(charToRaw(old))
    after <- if (after_start > length(bytes)) raw() else bytes[seq.int(after_start, length(bytes))]
    return(c(before, charToRaw(new), after))
  }
  if (length(new_location) == 1L && !length(old_location)) return(bytes)
  stop("Expected exactly one matching assessment text value.", call. = FALSE)
}
assessment_bytes <- replace_once(assessment_bytes, old_record, new_record)
assessment_text <- rawToChar(assessment_bytes)
note_start <- find_record(assessment_text, "Only published 2018")
note_end <- find_record(assessment_text, "2025 totals/summaries and fixed M entered.")
new_note <- "Published 2018-2025 catch totals and summary outputs, 2026-2031 projections, and fixed M are entered."
if (length(note_start) == 1L && length(note_end) == 1L && note_end > note_start) {
  after_note <- note_end + length(charToRaw("2025 totals/summaries and fixed M entered."))
  before <- assessment_bytes[seq_len(note_start - 1L)]
  after <- assessment_bytes[seq.int(after_note, length(assessment_bytes))]
  assessment_bytes <- c(before, charToRaw(new_note), after)
} else if (length(find_record(assessment_text, new_note)) != 1L) {
  stop("Expected the Georges Bank haddock assessment note to be unique.", call. = FALSE)
}
writeBin(assessment_bytes, assessment_path)

outputs <- read.csv(outputs_path,
  stringsAsFactors = FALSE, check.names = FALSE, na.strings = c("", "NA"))
required <- c("assessment_id", "type", "measure", "fleet", "survey", "sex",
  "region", "season", "year", "age", "age_group", "value", "se",
  "lwr", "upr", "unit", "source_type", "source_reference", "notes")
if (!identical(names(outputs), required)) {
  stop("The canonical outputs table has an unexpected structure.", call. = FALSE)
}

output_row <- function(type, measure, year, value, unit, lwr = NA_real_,
                       upr = NA_real_, age_group = "", fleet = "", notes) {
  data.frame(
    assessment_id = assessment_id, type = type, measure = measure,
    fleet = fleet, survey = "", sex = "", region = "", season = "",
    year = year, age = NA_real_, age_group = age_group, value = value,
    se = NA_real_, lwr = lwr, upr = upr, unit = unit,
    source_type = "official_table",
    source_reference = paste(source_url, "Table 3", sep = "; "),
    notes = notes, stringsAsFactors = FALSE
  )
}

projected <- do.call(rbind, lapply(seq_len(nrow(projection)), function(i) {
  row <- projection[i, ]
  year <- row$year
  catch_note <- if (year == 2026) {
    "2026 catch assumption supplied by the Groundfish Plan Development Team; not an estimated WHAM catch."
  } else {
    "Projected total fishery catch under fishing at 100% of F40%SPR; the report presents a 95% interval."
  }
  f_note <- if (year == 2026) {
    "Projected Fbar for ages 5-7; 95% interval as reported."
  } else {
    "Scenario value fixed at F40%SPR = 0.27 for 2027-2031; the report gives no uncertainty interval."
  }
  rbind(
    output_row("catch", "predicted_catch", year, row$catch, "t",
      row$catch_lwr, row$catch_upr, fleet = "Total fishery catch", notes = catch_note),
    output_row("biomass", "SSB", year, row$SSB, "t", row$SSB_lwr,
      row$SSB_upr, notes = "Projected spawning stock biomass; 95% interval as reported. Point-estimate summary is not specified in the report."),
    output_row("mortality", "Fbar", year, row$Fbar, "per year",
      row$Fbar_lwr, row$Fbar_upr,
      age_group = paste0("5", intToUtf8(0x2013), "7"), notes = f_note)
  )
}))

existing <- outputs[outputs$assessment_id == assessment_id &
  outputs$year %in% 2026:2031 &
  outputs$measure %in% c("predicted_catch", "SSB", "Fbar"), , drop = FALSE]
if (nrow(existing)) {
  key <- function(x) paste(x$measure, x$year, sep = "\034")
  expected <- projected
  expected$age_group[expected$age_group == ""] <- NA_character_
  columns <- c("type", "measure", "year", "age_group", "value", "lwr", "upr", "unit")
  index <- match(key(expected), key(existing))
  same <- nrow(existing) == nrow(expected) && !anyNA(index)
  if (same) {
    same <- all(vapply(columns, function(name) {
      actual <- existing[[name]][index]
      wanted <- expected[[name]]
      if (is.numeric(wanted)) {
        all(is.na(actual) == is.na(wanted)) &&
          all(actual[!is.na(wanted)] == wanted[!is.na(wanted)])
      } else {
        same_missing <- all(is.na(actual) == is.na(wanted))
        take <- which(!is.na(wanted))
        same_missing && all(vapply(take, function(i) {
          identical(charToRaw(as.character(actual[i])),
            charToRaw(as.character(wanted[i])))
        }, logical(1)))
      }
    }, logical(1)))
  }
  if (!same) stop("Existing Georges Bank haddock projection rows do not match Table 3.", call. = FALSE)
  cat("Georges Bank haddock projection rows are already current.\n")
} else {
  quote_field <- function(value) {
    if (is.na(value)) value <- ""
    paste0('"', gsub('"', '""', enc2utf8(as.character(value)), fixed = TRUE), '"')
  }
  csv_rows <- vapply(seq_len(nrow(projected)), function(i) {
    paste(vapply(projected, function(column) quote_field(column[[i]]), character(1)),
      collapse = ",")
  }, character(1))
  connection <- file(outputs_path, open = "ab")
  writeBin(charToRaw(enc2utf8(paste0(paste(csv_rows, collapse = "\r\n"), "\r\n"))),
    connection)
  close(connection)
  cat("Imported 18 Georges Bank haddock projection rows for 2026-2031.\n")
}
