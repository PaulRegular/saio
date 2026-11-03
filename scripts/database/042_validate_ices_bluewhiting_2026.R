assessment_id <- "ices_bluewhiting_northeast_atlantic_2026"
root <- "."
database <- lapply(
  c("stocks", "assessments", "assumptions", "inputs", "outputs"),
  function(name) {
    utils::read.csv(
      file.path(root, "database", paste0(name, ".csv")),
      stringsAsFactors = FALSE, na.strings = c("", "NA"),
      check.names = FALSE
    )
  }
)
names(database) <- c("stocks", "assessments", "assumptions", "inputs", "outputs")
sam <- readRDS(file.path(root, "source_cache", assessment_id, "BW-2026.rds"))
years <- as.integer(sam$data$years)
ages <- seq.int(sam$data$minAgePerFleet[[1L]], sam$data$maxAgePerFleet[[1L]])

stock <- database$stocks[database$stocks$stock_id == "ices_bluewhiting_northeast_atlantic", ]
assessment <- database$assessments[database$assessments$assessment_id == assessment_id, ]
inputs <- database$inputs[database$inputs$assessment_id == assessment_id, ]
outputs <- database$outputs[database$outputs$assessment_id == assessment_id, ]

stopifnot(nrow(stock) == 1L, nrow(assessment) == 1L)
stopifnot(assessment$is_current, assessment$is_applied)
stopifnot(
  assessment$assumptions_status == "complete",
  assessment$inputs_status == "complete",
  assessment$outputs_status == "complete"
)
stopifnot(nrow(subset(inputs, type == "catch")) == 460L)
stopifnot(nrow(subset(inputs, type == "index")) == 168L)
stopifnot(nrow(subset(inputs, type == "weight")) == 460L)
stopifnot(nrow(subset(inputs, type == "catch_weight")) == 460L)
stopifnot(nrow(subset(inputs, type == "maturity")) == 460L)
stopifnot(nrow(subset(inputs, type == "M")) == 460L)
stopifnot(all(subset(inputs, type == "index")$sampling_time == 0.245))
stopifnot(all(subset(inputs, type == "index")$unit == "million fish"))
stopifnot(all(subset(inputs, type == "catch")$unit == "thousand fish"))
stopifnot(all(subset(inputs, type == "M")$value == 0.2))
catch_2026 <- subset(inputs, type == "catch" & year == 2026)
catch_weight_2026 <- subset(inputs, type == "catch_weight" & year == 2026)
stopifnot(abs(sum(catch_2026$value * catch_weight_2026$value) - 1110513) < 1)
survey_2024 <- subset(inputs, type == "index" & year == 2024)
stopifnot(identical(
  survey_2024$value,
  c(729, 2885, 18767, 10787, 1843, 577, 518, 487)
))

ssb <- subset(outputs, measure == "SSB" & year == 2025)
recruitment <- subset(outputs, measure == "recruitment" & year == 2025)
fbar <- subset(outputs, measure == "Fbar" & year == 2025)
stopifnot(nrow(ssb) == 1L, abs(ssb$value - 5087028) < 1)
stopifnot(nrow(recruitment) == 1L, abs(recruitment$value - 38731655) < 1)
stopifnot(nrow(fbar) == 1L, abs(fbar$value - 0.5082964) < 1e-6)
total_biomass <- subset(outputs, measure == "total_biomass" & year == 2025)
stopifnot(
  nrow(total_biomass) == 1L,
  abs(total_biomass$value - 8578674) < 1
)
stopifnot(nrow(subset(outputs, measure == "process_sd")) == 3L)
stopifnot(nrow(subset(outputs, measure == "observation_sd")) == 9L)
stopifnot(all(subset(outputs, measure %in% c("process_sd", "observation_sd"))$value > 0))
for (measure in c(
  "numbers_at_age", "fishing_mortality_at_age",
  "natural_mortality_at_age"
)) {
  surface <- outputs[outputs$measure == measure, , drop = FALSE]
  stopifnot(nrow(surface) == length(years) * length(ages))
  stopifnot(all(surface$age_group[surface$age == max(ages)] == "10+"))
  stopifnot(all(is.na(surface$age_group[surface$age != max(ages)])))
}
stopifnot(isTRUE(sam$opt$convergence == 0L), isTRUE(sam$sdrep$pdHess))

cat("Blue whiting database record validated: ", nrow(inputs),
  " inputs, ", nrow(outputs), " outputs.\n",
  sep = ""
)
