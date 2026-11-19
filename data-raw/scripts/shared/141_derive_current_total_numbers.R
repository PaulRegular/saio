root <- "."
source(file.path(root, "R", "derive_total_numbers.R"))

database <- file.path(root, "database")
outputs_file <- file.path(database, "outputs.csv")
dry_run <- "--dry-run" %in% commandArgs(trailingOnly = TRUE)
assessments <- read.csv(
  file.path(database, "assessments.csv"),
  stringsAsFactors = FALSE,
  na.strings = c("", "NA")
)
outputs <- read.csv(
  outputs_file,
  stringsAsFactors = FALSE,
  na.strings = c("", "NA"),
  check.names = FALSE
)
current_ids <- assessments$assessment_id[assessments$is_current %in% TRUE]
derived <- derive_population_total_numbers(outputs, assessment_ids = current_ids)
skipped <- attr(derived, "skipped")

cat("Derived population totals:", nrow(derived), "rows across",
  length(unique(derived$assessment_id)), "current assessments.\n")
if (length(skipped)) {
  cat("Skipped population surfaces:\n", paste(skipped, collapse = "\n"), "\n")
}
if (nrow(derived) && !dry_run) {
  write.table(
    derived,
    file = outputs_file,
    sep = ",",
    row.names = FALSE,
    col.names = FALSE,
    quote = TRUE,
    qmethod = "double",
    na = "",
    append = TRUE,
    eol = "\n",
    fileEncoding = "UTF-8"
  )
  cat("Appended rows to", outputs_file, "\n")
}
