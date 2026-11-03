root <- "."
id <- "afsc_cod_goa_2026"
report <- "https://meetings.npfmc.org/CommentReview/DownloadFile?fileName=C1+GOA+Pcod+Assessment.pdf&p=f00593eb-12f5-458c-842e-a5cdd45306bb.pdf"
model <- "https://github.com/afsc-assessments/goapcod/blob/e632807e4947686c16caf99b864bfe8466f8dbca/docs/2025_Assessment/January_Model/model_files/M24.0_SS3_files.zip"

outputs_path <- file.path(root, "database/outputs.csv")
outputs <- read.csv(outputs_path, stringsAsFactors = FALSE, check.names = FALSE)
measures <- c("growth_length_at_age", "growth_rate", "growth_sd_length_at_age")
if (any(outputs$assessment_id == id & outputs$measure %in% measures)) {
  stop("GOA growth parameters are already present in outputs.csv.", call. = FALSE)
}
output_rows <- data.frame(
  assessment_id = id,
  type = "biology",
  measure = c(
    "growth_length_at_age", "growth_length_at_age", "growth_rate",
    "growth_sd_length_at_age", "growth_sd_length_at_age"
  ),
  fleet = "", survey = "", sex = "", region = "", season = "", year = NA_real_,
  age = c(1, 10, NA, 1, 10), age_group = "",
  value = c(17.64, 99.46, 0.19, 4.01, 9.1),
  se = c(0.303, 0.015, 0.002, 0.182, 0.347),
  lwr = NA_real_, upr = NA_real_,
  unit = c("cm", "cm", "per year", "cm", "cm"),
  source_type = "official_table",
  source_reference = paste(report, "Table 2.6", sep = "; "),
  notes = c(
    "Rounded official-model estimate and reported SD from Table 2.6; SD is on the natural parameter scale. No confidence interval reconstructed. Age 10 is the terminal plus group.",
    "Rounded official-model estimate and reported SD from Table 2.6; SD is on the natural parameter scale. No confidence interval reconstructed. Age 10 is the terminal plus group.",
    "Rounded official-model estimate and reported SD from Table 2.6; SD is on the natural parameter scale. No confidence interval reconstructed.",
    "Rounded official-model estimate and reported SD from Table 2.6; SD is on the natural parameter scale. No confidence interval reconstructed. Age 10 is the terminal plus group.",
    "Rounded official-model estimate and reported SD from Table 2.6; SD is on the natural parameter scale. No confidence interval reconstructed. Age 10 is the terminal plus group."
  ),
  stringsAsFactors = FALSE
)
utils::write.table(output_rows[names(outputs)], outputs_path,
  sep = ",", quote = TRUE,
  row.names = FALSE, col.names = FALSE, append = TRUE, na = ""
)

assumptions_path <- file.path(root, "database/assumptions.csv")
assumptions <- read.csv(assumptions_path, stringsAsFactors = FALSE, check.names = FALSE)
if (any(assumptions$assessment_id == id &
  assumptions$setting %in% c("growth_model", "growth_variability"))) {
  stop("GOA growth assumptions are already present in assumptions.csv.", call. = FALSE)
}
assumption_rows <- data.frame(
  assessment_id = id,
  component = "biology",
  fleet = "", survey = "", sex = "", region = "", season = "",
  setting = c("growth_model", "growth_variability"),
  value = c(
    "Von Bertalanffy; length-at-age parameters anchored at ages 1 and 10",
    "Standard deviation is a function of length-at-age"
  ),
  source_reference = paste(model, "Model24_0.ctl", sep = "; "),
  notes = c(
    "Model 24.0 control file: one growth pattern, GrowthModel=1 (von Bertalanffy with L1 and L2), maximum modeled age 10.",
    "Model 24.0 control file: CV_Growth_Pattern=2 (SD as a function of length-at-age); endpoint estimates are recorded in outputs.csv from Table 2.6."
  ),
  stringsAsFactors = FALSE
)
utils::write.table(assumption_rows[names(assumptions)], assumptions_path,
  sep = ",",
  quote = TRUE, row.names = FALSE, col.names = FALSE,
  append = TRUE, na = ""
)

check_outputs <- read.csv(outputs_path, stringsAsFactors = FALSE)
check_assumptions <- read.csv(assumptions_path, stringsAsFactors = FALSE)
z <- check_outputs[check_outputs$assessment_id == id & check_outputs$measure %in% measures, ]
a <- check_assumptions[check_assumptions$assessment_id == id & check_assumptions$setting %in% c("growth_model", "growth_variability"), ]
stopifnot(nrow(z) == 5L, nrow(a) == 2L, all(is.finite(z$value)), all(is.finite(z$se)), all(z$se > 0), all(z$source_type == "official_table"))
message("Recorded five published growth-parameter estimates and two native growth assumptions.")
