source("scripts/database/pacific_tables.R")

root <- "."
id <- "afsc_pop_bsai_2024"
native_dir <- file.path(root, "source_cache/afsc_pop_bsai/native")
revision_lines <- grep('"sha"', readLines(
  file.path(root, "source_cache/afsc_pop_bsai/repository_revision.json")
), value = TRUE)
revision <- sub('.*"sha"[[:space:]]*:[[:space:]]*"([^"]+)".*', "\\1", revision_lines)
stopifnot(length(revision) == 1L, grepl("^[a-f0-9]{40}$", revision))
native <- paste0(
  "https://github.com/afsc-assessments/BSAI-POP/tree/", revision,
  "/2024%20assessment"
)
database <- file.path(root, "database")
outputs_file <- file.path(database, "outputs.csv")
outputs <- utils::read.csv(outputs_file, check.names = FALSE)

if (any(outputs$assessment_id == id & outputs$measure == "total_abundance")) {
  cli::cli_abort("Total abundance is already present for {id}.")
}

n <- outputs[outputs$assessment_id == id & outputs$measure == "numbers_at_age", ]
stopifnot(identical(sort(unique(n$year)), 1960:2024),
          identical(sort(unique(n$age)), 3:40),
          all(n$unit == "million fish"))

annual <- stats::aggregate(value ~ year, n, sum)
source_fit <- dget(file.path(native_dir, "m_24_2_reweighted.rdat"))
stopifnot(identical(annual$year, as.integer(source_fit$t.series$year)),
          max(abs(annual$value - source_fit$t.series$totnum)) < 0.02)

derived <- pacific_database_row(
  "outputs", assessment_id = id, type = "population",
  measure = "total_abundance", year = annual$year,
  value = annual$value, unit = "million fish", sex = "combined",
  region = "BSAI", source_type = "derived_source_output",
  source_reference = paste0(native, "; m_24_2_reweighted.rdat$natage"),
  notes = paste(
    "Derived by summing reported population numbers at ages 3-39 and 40+ for each year.",
    "Standard errors and intervals are unavailable because joint uncertainty for N-at-age is not supplied."
  )
)

utils::write.table(derived, outputs_file, sep = ",", row.names = FALSE,
                   col.names = FALSE, append = TRUE, na = "")
cat("Added", nrow(derived), "derived total-abundance outputs for", id, ".\n")
