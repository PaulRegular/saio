source("scripts/shared/candidate_reports.R", local = TRUE)
out <- candidate_progress()
if (sys.nframe() == 0L) {
  utils::write.csv(out, row.names = FALSE, na = "")
}
