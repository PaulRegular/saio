assessment_id <- "dfo_cod_2j3kl_2025"
database <- "database"
path <- file.path(database, "inputs.csv")
source_reference <- paste(
  "DFO Research Document 2025/061, Figure 32, p. 38",
  "https://publications.gc.ca/collections/collection_2025/mpo-dfo/fs70-5/Fs70-5-2025-061-eng.pdf",
  sep = "; "
)

years <- c(1985:1992, 1996, 1999:2005, 2007:2015, 2017:2019, 2022:2024)
log_biomass_kt <- c(
  8.13, 8.20, 7.83, 8.34, 8.20, 8.65, 4.92, 4.92, 3.85,
  5.22, 4.45, 4.80, 4.33, 4.66, 4.71, 4.54,
  5.50, 5.52, 5.50, 3.08, 5.29, 5.15, 6.48, 6.64, 5.90,
  4.87, 5.64, 5.62, 5.55, 5.81, 6.46
)
if (length(years) != length(log_biomass_kt) || any(!is.finite(log_biomass_kt))) {
  stop("The digitized Capelin series has inconsistent years or values.", call. = FALSE)
}

original <- readLines(path, warn = FALSE, encoding = "UTF-8")
inputs <- read.csv(
  text = original, colClasses = "character", na.strings = "",
  check.names = FALSE
)
new <- inputs[rep(NA_integer_, length(years)), ]
new$assessment_id <- assessment_id
new$type <- "covariate"
new$measure <- "capelin_biomass_index"
new$basis <- "native_covariate"
new$survey <- "3L spring acoustic survey"
new$region <- "NAFO Division 3L"
new$season <- "spring"
new$year <- years
new$year_basis <- "calendar_year"
new$value <- exp(log_biomass_kt)
new$unit <- "kt"
new$source_type <- "digitized"
new$source_reference <- source_reference
new$transformation <- paste(
  "Digitized the 3L Acoustic Survey point from Figure 32's",
  "ln(Capelin Biomass [kt]) axis; round the plotted log value to 0.01,",
  "then exponentiate to recover approximate kt."
)
new$notes <- paste(
  "Approximate raster digitization of the acoustic index, not the original",
  "unrounded survey estimate. These are the 3L Capelin years listed as",
  "covariate inputs in DFO Research Document 2026/026, pp. 14-15."
)

reported_values_kt <- c("2013" = 668, "2014" = 779, "2024" = 647)
reported_rows <- as.character(new$year) %in% names(reported_values_kt)
new$value[reported_rows] <- unname(
  reported_values_kt[as.character(new$year[reported_rows])]
)
new$source_type[reported_rows] <- "official_document"
new$source_reference[reported_rows] <- paste(
  "DFO Research Document 2025/061, p. 8, Spring acoustic survey abundance and biomass;",
  "https://publications.gc.ca/collections/collection_2025/mpo-dfo/fs70-5/Fs70-5-2025-061-eng.pdf"
)
new$transformation[reported_rows] <-
  "Reported in kt to the nearest kt; retained at the stated precision."
new$notes[reported_rows] <- paste(
  "Explicit rounded 3L spring acoustic biomass value from the Capelin assessment report;",
  "replaces the approximate Figure 32 digitization for this year."
)

replace <- inputs$assessment_id == assessment_id &
  inputs$measure == "capelin_biomass_index"
writeLines(original[c(TRUE, !replace)], path, useBytes = TRUE)
write.table(
  new, path, sep = ",", quote = TRUE, row.names = FALSE,
  col.names = FALSE, append = TRUE, na = "", fileEncoding = "UTF-8"
)

cat("Imported", nrow(new), "3L Capelin covariate values for Northern cod; exact report values were used where available.\n")
