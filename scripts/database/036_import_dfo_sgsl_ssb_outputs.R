assessment_id <- "dfo_cod_4t4vn_2024"
cache <- "source_cache/dfo_cod_4t4vn"
database <- "database"
data_file <- "NAFO-4T4VN-Atlantic-Cod-spawning-stock-biomass-estimates-1950-2023.csv"
dict_file <- "Atlantic-Cod-biomass-estimates-data-dictionary.csv"
data_url <- paste0(
  "https://api-proxy.edh-cde.dfo-mpo.gc.ca/catalogue/records/",
  "fe51e3da-0e0b-11ef-90aa-8b219c568296/attachments/", data_file
)
dict_url <- paste0(
  "https://api-proxy.edh-cde.dfo-mpo.gc.ca/catalogue/records/",
  "fe51e3da-0e0b-11ef-90aa-8b219c568296/attachments/", dict_file
)

manifest <- read.csv(file.path(cache, "manifest.csv"),
  stringsAsFactors = FALSE,
  na.strings = "", check.names = FALSE
)
required_files <- c(data_file, dict_file)
if (!all(required_files %in% manifest$source_file)) {
  stop("The DFO SSB CSV and dictionary must be recorded in the source manifest.")
}
if (manifest$source_url[match(data_file, manifest$source_file)] != data_url ||
  manifest$source_url[match(dict_file, manifest$source_file)] != dict_url) {
  stop("The source manifest URLs do not match the DFO data resources.")
}

source <- read.csv(file.path(cache, data_file),
  colClasses = "character",
  na.strings = character(), check.names = FALSE,
  encoding = "UTF-8"
)
prefixes <- c(
  "year", "biomass.median_", "biomass.025_", "biomass.25_",
  "biomass.75_", "biomass.975_"
)
if (ncol(source) != length(prefixes) ||
  !all(vapply(seq_along(prefixes), function(i) {
    startsWith(names(source)[i], prefixes[i])
  }, logical(1)))) {
  stop("The DFO SSB CSV columns do not match the expected data dictionary.")
}

years <- as.integer(source[[1]])
values <- do.call(cbind, unname(lapply(source[2:6], as.numeric)))
if (nrow(source) != 74L || !identical(years, 1950:2023) ||
  any(!is.finite(values)) ||
  any(values[, 2] > values[, 3]) ||
  any(values[, 3] > values[, 1]) ||
  any(values[, 1] > values[, 4]) ||
  any(values[, 4] > values[, 5])) {
  stop("The DFO annual SSB values or percentile ordering are invalid.")
}

outputs_path <- file.path(database, "outputs.csv")
lines <- readLines(outputs_path, warn = FALSE, encoding = "UTF-8")
lines <- sub("\\r$", "", lines)
outputs <- read.csv(
  text = lines, colClasses = "character", na.strings = "",
  check.names = FALSE, encoding = "UTF-8"
)
if (nrow(outputs) != length(lines) - 1L) {
  stop("Expected one physical CSV line per output record.")
}
current_ssb <- outputs$assessment_id == assessment_id & outputs$measure == "SSB"
if (sum(current_ssb) == 1L) {
  report_value <- as.numeric(outputs$value[current_ssb])
  if (round(report_value) != round(values[nrow(values), 1])) {
    stop("The dataset's terminal SSB does not round to the official report value.")
  }
} else if (sum(current_ssb) != length(years)) {
  stop("Expected one report SSB row or a complete annual SSB series to replace.")
}

new <- as.data.frame(matrix("", nrow = length(years), ncol = ncol(outputs)),
  stringsAsFactors = FALSE
)
names(new) <- names(outputs)
new$assessment_id <- assessment_id
new$type <- "biomass"
new$measure <- "SSB"
new$year <- as.character(years)
new$value <- source[[2]]
new$lwr <- source[[3]]
new$upr <- source[[6]]
new$unit <- "kt"
new$source_type <- "official_machine_readable"
new$source_reference <- paste0(
  "DFO SSB annual estimates dataset fe51e3da-0e0b-11ef-90aa-8b219c568296; ",
  data_file, "; data dictionary: ", dict_file
)
base_note <- paste(
  "MCMC median in thousand tonnes; lwr/upr are the source 2.5th/97.5th",
  "percentiles (central 95% percentile range). The 25th/75th percentiles",
  "are retained in the cached source CSV."
)
new$notes <- base_note
terminal <- years == 2023L
new$notes[terminal] <- paste(
  base_note,
  "The median rounds to 12 kt as in DFO Science Advisory Report 2024/026.",
  "The dataset's 95% percentile range differs from the report's stated",
  "10.5-21.6 kt interval; see the stock source review."
)

csv_field <- function(x) {
  if (is.na(x)) {
    return("")
  }
  x <- enc2utf8(as.character(x))
  if (grepl('[",\r\n]', x) || grepl("^\\s|\\s$", x)) {
    paste0('"', gsub('"', '""', x, fixed = TRUE), '"')
  } else {
    x
  }
}
new_lines <- vapply(seq_len(nrow(new)), function(i) {
  paste(vapply(new[i, ], csv_field, character(1)), collapse = ",")
}, character(1))

if (any(current_ssb)) {
  first_current <- which(current_ssb)[1]
  insert_after <- first_current
  keep_lines <- c(TRUE, !current_ssb)
  preserved <- lines[keep_lines]
  before <- preserved[seq_len(insert_after)]
  after <- if (insert_after < length(preserved)) {
    preserved[seq.int(insert_after + 1L, length(preserved))]
  } else {
    character()
  }
} else {
  before <- lines
  after <- character()
}

temporary <- tempfile(tmpdir = dirname(outputs_path))
writeLines(enc2utf8(c(before, new_lines, after)), temporary,
  sep = "\n", useBytes = TRUE
)
if (!file.copy(temporary, outputs_path, overwrite = TRUE)) {
  unlink(temporary)
  stop("Could not replace outputs.csv.")
}
unlink(temporary)

check <- read.csv(outputs_path,
  colClasses = "character", na.strings = "",
  check.names = FALSE, encoding = "UTF-8"
)
check <- check[check$assessment_id == assessment_id & check$measure == "SSB", ]
if (nrow(check) != length(years) || !identical(as.integer(check$year), years) ||
  !identical(check$value, source[[2]]) ||
  !identical(check$lwr, source[[3]]) ||
  !identical(check$upr, source[[6]])) {
  stop("The imported SSB series failed its database round-trip check.")
}
cat("Imported ", nrow(check), " Southern Gulf cod SSB estimates (",
  min(years), "-", max(years), ").\n",
  sep = ""
)
