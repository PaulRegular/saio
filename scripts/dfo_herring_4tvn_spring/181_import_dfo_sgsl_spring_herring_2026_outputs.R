base <- "."
database <- file.path(base, "database")
source_dir <- file.path(base, "source_cache/dfo_sgsl_herring_spring_2023")
assessment_id <- "dfo_herring_4tvn_spring_2026"
report_url <- paste0(
  "https://publications.gc.ca/collections/collection_2026/mpo-dfo/",
  "fs70-6/Fs70-6-2026-028-eng.pdf"
)
report_path <- file.path(source_dir, "2026_028_latest_advice.pdf")
manifest_path <- file.path(source_dir, "manifest.csv")

if (!file.exists(report_path) || !file.exists(manifest_path)) {
  stop("Cache DFO Science Advisory Report 2026/028 before importing.")
}
manifest <- read.csv(manifest_path, na.strings = c("", "NA"),
  stringsAsFactors = FALSE)
source_row <- manifest[!is.na(manifest$assessment_id) &
  manifest$source_file == basename(report_path), , drop = FALSE]
sha256 <- function(path) {
  if (.Platform$OS.type == "windows") {
    command <- "certutil"
    args <- c("-hashfile", shQuote(normalizePath(path, winslash = "\\")), "SHA256")
    hash_lines <- system2(command, args, stdout = TRUE, stderr = TRUE)
    hash_lines <- trimws(hash_lines)
    hash_lines <- hash_lines[grepl("^[0-9A-Fa-f ]+$", hash_lines) & nchar(gsub(" ", "", hash_lines)) == 64L]
    if (length(hash_lines)) return(tolower(gsub("[[:space:]]", "", hash_lines[[1L]])))
  } else {
    command <- Sys.which("sha256sum")
    args <- shQuote(path)
    if (!nzchar(command)) {
      command <- Sys.which("shasum")
      args <- c("-a", "256", shQuote(path))
    }
    if (nzchar(command)) {
      result <- system2(command, args, stdout = TRUE, stderr = TRUE)
      return(tolower(strsplit(result[[1L]], "[[:space:]]+")[[1L]][[1L]]))
    }
  }
  stop("No SHA-256 utility is available to verify the cached report.")
}
checksum <- sha256(report_path)
if (nrow(source_row) != 1L ||
    tolower(source_row$sha256) != tolower(checksum)) {
  stop("The cached DFO 2026/028 report does not match its manifest checksum.")
}

report_text <- paste(readLines(file.path(source_dir, "2026_028_latest_advice.txt"),
  warn = FALSE, encoding = "UTF-8"), collapse = " ")
report_text <- gsub("[[:space:]]+", " ", report_text)
required_text <- c(
  "Estimated SSB in 2024 and 2025 were 11,816 t",
  "Natural mortality was 0.43 and 0.44",
  "Recruitment values for 2024 and 2025 were 65,970,950"
)
if (!all(vapply(required_text, grepl, logical(1), x = report_text,
  fixed = TRUE))) {
  stop("The cached report text does not contain the reviewed 2026 estimates.")
}

blank_rows <- function(file, n) {
  columns <- names(read.csv(file.path(database, file), nrows = 0,
    check.names = FALSE))
  x <- as.data.frame(matrix("", n, length(columns)), stringsAsFactors = FALSE)
  names(x) <- columns
  x$assessment_id <- assessment_id
  x
}

reference <- "DFO Science Advisory Report 2026/028; Stock Status and Trends, p. 6"
years <- c(2024L, 2025L)
outputs <- rbind(
  {
    x <- blank_rows("outputs.csv", 2L)
    x$type <- "biomass"
    x$measure <- "SSB"
    x$year <- as.character(years)
    x$value <- c("11816", "17412")
    x$lwr <- c("8035", "9990")
    x$upr <- c("17377", "30349")
    x$unit <- "tonnes"
    x$source_type <- "official_table"
    x$source_reference <- reference
    x$notes <- paste(
      "Estimated spawning stock biomass at April 1, accounting for three",
      "months of natural mortality. Reported 95% confidence interval."
    )
    x
  },
  {
    x <- blank_rows("outputs.csv", 2L)
    x$type <- "recruitment"
    x$measure <- "recruitment"
    x$year <- as.character(years)
    x$age <- "2"
    x$value <- c("65970950", "84872640")
    x$unit <- "fish"
    x$source_type <- "official_table"
    x$source_reference <- reference
    x$notes <- "Estimated number of age-2 fish; no uncertainty reported."
    x
  },
  {
    x <- blank_rows("outputs.csv", 2L)
    x$type <- "mortality"
    x$measure <- "natural_mortality_at_age"
    x$year <- as.character(years)
    x$age_group <- "8-11+"
    x$value <- c("0.43", "0.44")
    x$unit <- "per year"
    x$source_type <- "official_table"
    x$source_reference <- reference
    x$notes <- paste(
      "Estimated natural mortality for ages 8-11+; no uncertainty reported.",
      "The report states that M for ages 2-7 is fixed at 0.3 per year."
    )
    x
  }
)

assumptions <- blank_rows("assumptions.csv", 1L)
assumptions$component <- "M"
assumptions$setting <- "natural_mortality_age_groups"
assumptions$value <- paste(
  "Ages 2-7 fixed at M=0.3 per year; ages 8-11+ estimated as a group"
)
assumptions$source_reference <- reference
assumptions$notes <- paste(
  "Selected values for the older age group are reported for 2024 and 2025.",
  "The summary does not provide age-specific estimates within ages 8-11+."
)

replace_rows <- function(file, matches, replacement) {
  path <- file.path(database, file)
  contents <- rawToChar(readBin(path, "raw", n = file.info(path)$size))
  lines <- strsplit(contents, "\n", fixed = TRUE)[[1L]]
  has_final_newline <- endsWith(contents, "\n")

  table <- read.csv(path, stringsAsFactors = FALSE, check.names = FALSE,
    na.strings = c("", "NA"), colClasses = "character")
  selected <- which(matches(table))
  if (length(lines) != nrow(table) + 1L) {
    stop("Unexpected line layout in ", file, ".", call. = FALSE)
  }
  if (length(selected)) lines <- lines[-(selected + 1L)]
  tmp <- tempfile(tmpdir = database)
  on.exit(unlink(tmp), add = TRUE)
  write.table(replacement, tmp, sep = ",", quote = TRUE, row.names = FALSE,
    col.names = FALSE, na = "", fileEncoding = "UTF-8")
  added <- readLines(tmp, encoding = "UTF-8", warn = FALSE)
  updated <- paste0(paste(c(lines, added), collapse = "\n"),
    if (has_final_newline) "\n" else "")
  writeBin(charToRaw(updated), path)
}

replace_rows("outputs.csv", function(x) {
  x$assessment_id == assessment_id &
    startsWith(x$source_reference, reference)
}, outputs)
replace_rows("assumptions.csv", function(x) {
  x$assessment_id == assessment_id &
    x$setting == "natural_mortality_age_groups"
}, assumptions)

update_assessment <- function() {
  path <- file.path(database, "assessments.csv")
  lines <- readLines(path, warn = FALSE, encoding = "UTF-8")
  table <- read.csv(path, stringsAsFactors = FALSE, check.names = FALSE,
    na.strings = c("", "NA"), colClasses = "character")
  row <- which(table$assessment_id == assessment_id)
  if (length(row) != 1L || length(lines) != nrow(table) + 1L) {
    stop("Could not uniquely locate the 2026 assessment record.")
  }
  table$notes[row] <- paste(
    "Official assessment to 2025, reported in DFO Science Advisory Report",
    "2026/028. Selected 2024-2025 SSB, age-2 recruitment, and grouped",
    "ages 8-11+ M outputs are recorded from the report. Detailed input",
    "tables, complete methods, and full age-specific output series remain",
    "unavailable while the Research Document is in preparation."
  )
  lines[row + 1L] <- capture.output(write.csv(
    table[row, , drop = FALSE], row.names = FALSE, na = ""
  ))[[2L]]
  writeLines(lines, path, useBytes = TRUE)
}
update_assessment()

message("Imported six selected 2024-2025 outputs for the separate 2026 herring assessment.")
