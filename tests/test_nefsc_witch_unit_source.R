base <- "database"
read_table <- function(file) data.table::fread(file.path(base, file), na.strings = c("", "NA"), blank.lines.skip = TRUE, data.table = FALSE)
ids <- c("nefsc_witch_flounder_unit_2024", "nefsc_witch_flounder_unit_2026_data_update")
s <- subset(read_table("stocks.csv"), stock_id == "nefsc_witch_flounder_unit")
a <- subset(read_table("assessments.csv"), assessment_id %in% ids)
z <- subset(read_table("inputs.csv"), assessment_id %in% ids)
o <- subset(read_table("outputs.csv"), assessment_id %in% ids)
stopifnot(nrow(s) == 1L, is.na(s$charbonneau_id) || s$charbonneau_id == "", nrow(a) == 2L,
  a$is_current[match(ids[1], a$assessment_id)], !a$is_current[match(ids[2], a$assessment_id)],
  a$is_applied[match(ids[1], a$assessment_id)], !a$is_applied[match(ids[2], a$assessment_id)],
  sum(z$assessment_id == ids[1]) == 33L, sum(z$assessment_id == ids[2]) == 370L,
  sum(o$assessment_id == ids[1]) == 23L,
  !any(o$assessment_id == ids[2]),
  !any(o$measure %in% c("SSB", "fishing_mortality_at_age", "numbers_at_age", "recruitment")))
get <- function(id, measure, year, survey = NA_character_) {
  rows <- z[z$assessment_id == id & z$measure == measure & z$year == year &
    if (is.na(survey)) (is.na(z$survey) | z$survey == "") else (!is.na(z$survey) & z$survey == survey), ]
  stopifnot(nrow(rows) == 1L); rows
}
stopifnot(get(ids[1], "discard_biomass", 2023)$value == 85,
  get(ids[2], "discard_biomass", 2023)$value == 89,
  get(ids[2], "total_biomass", 2025)$value == 1177,
  get(ids[2], "relative_biomass_index", 2023, "NEFSC fall bottom trawl")$value == .8741,
  get(ids[2], "relative_standard_error", 2023, "NEFSC fall bottom trawl")$value == .1741,
  get(ids[2], "relative_biomass_index", 2026, "NEFSC spring bottom trawl")$value == .4774,
  sum(z$assessment_id == ids[2] & z$measure == "relative_biomass_index" & z$season == "fall") == 62L,
  sum(z$assessment_id == ids[2] & z$measure == "relative_biomass_index" & z$season == "spring") == 57L,
  all(is.na(z$sampling_time[z$assessment_id == ids[2] & z$type == "index"])),
  !any(z$assessment_id == ids[2] & z$type == "index" & z$year == 2020),
  !any(z$assessment_id == ids[2] & z$type == "index" & z$year == 2023 & z$season == "spring"),
  o$value[o$assessment_id == ids[1] & o$measure == "exploitable_biomass" & o$year == 2023] == 30093,
  o$value[o$assessment_id == ids[1] & o$measure == "exploitable_biomass" & o$year == 2024] == 35270)
cat("Witch unit identity, assessment and separate monitoring data passed.\n")
