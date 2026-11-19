root <- file.path("database")
inputs <- read.csv(file.path(root, "inputs.csv"), na.strings = c("", "NA"))
outputs <- read.csv(file.path(root, "outputs.csv"), na.strings = c("", "NA"))
inputs <- subset(inputs, assessment_id == "ices_cod_north_sea_2025")
outputs <- subset(outputs, assessment_id == "ices_cod_north_sea_2025")

surveys <- c(
  "Survey_Q1_NW", "Survey_Q1_SO", "Survey_Q1_VI", "Survey_Q34",
  "Survey_Rec_NW", "Survey_Rec_SO", "Survey_Rec_VI"
)
stopifnot(setequal(na.omit(inputs$survey), surveys))
obs <- subset(inputs, type == "index" & measure == "numbers_at_age")
sds <- subset(inputs, type == "index" & measure == "log_index_sd")
key <- function(x) paste(x$survey, x$year, x$age)
stopifnot(setequal(key(obs), key(sds)), all(sds$value > 0))
for (survey in surveys) {
  x <- obs[obs$survey == survey, ]
  expected <- if (grepl("Q1", survey)) 0.125 else if (survey == "Survey_Q34") 0.75 else 0
  stopifnot(all(x$sampling_time == expected))
}

# Missing source observations stay missing; fitted biological values never fill them.
stopifnot(!any(inputs$type == "M" & inputs$year > 2022))
stopifnot(!any(obs$survey == "Survey_Q34" & obs$year == 2004 & obs$age == 7))
stopifnot(nrow(subset(inputs, type == "weight")) == 894L)
catch <- subset(inputs, type == "catch" & measure == "numbers_at_age")
stopifnot(nrow(catch) == 42L * 7L, setequal(catch$year, 1983:2024))
fraction <- subset(inputs, measure == "landings_fraction_at_age")
stopifnot(
  nrow(fraction) == nrow(catch), all(fraction$value >= 0 & fraction$value <= 1),
  all(fraction$source_type == "reconstructed_source_input")
)

composition <- subset(inputs, measure == "landings_proportion")
stopifnot(nrow(composition) == 30L * 7L, setequal(composition$year, 1995:2024))
stopifnot(
  nrow(subset(composition, !is.na(region))) == 90L,
  nrow(subset(composition, is.na(region))) == 120L
)

for (region in c("Northwestern", "Southern", "Viking")) {
  x <- outputs[outputs$region == region, ]
  stopifnot(
    nrow(subset(x, measure == "numbers_at_age")) == 43L * 7L,
    nrow(subset(x, measure == "fishing_mortality_at_age")) == 42L * 7L,
    nrow(subset(x, measure == "natural_mortality_at_age")) == 43L * 7L
  )
  n <- subset(x, measure == "numbers_at_age" & age == 1)
  r <- subset(x, measure == "recruitment")
  both <- merge(n, r, by = "year", suffixes = c("_N", "_R"))
  stopifnot(nrow(both) == 43L, all(abs(both$value_N - both$value_R) <= 0.501))
  f <- subset(x, measure == "fishing_mortality_at_age" & age %in% 2:4)
  fbar <- subset(x, measure == "Fbar")
  both <- merge(aggregate(value ~ year, f, mean), fbar, by = "year", suffixes = c("_age", "_reported"))
  stopifnot(all(abs(both$value_age - both$value_reported) <= 0.000501))
}
cat("Northern Shelf cod source coverage and common-definition checks passed.\n")
