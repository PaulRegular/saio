source("scripts/discovery/candidate_reports.R", local = TRUE)
units <- candidate_units()
if (sys.nframe() == 0L) {
  utils::write.csv(units, row.names = FALSE, na = "")
}
