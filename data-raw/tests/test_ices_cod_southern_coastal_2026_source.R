base <- "database"
read_table <- function(file) data.table::fread(file.path(base, file), na.strings = c("", "NA"), blank.lines.skip = TRUE, data.table = FALSE)
id <- "ices_cod_southern_coastal_2026"
s <- subset(read_table("stocks.csv"), stock_id == "ices_cod_southern_coastal")
a <- subset(read_table("assessments.csv"), assessment_id == id)
z <- subset(read_table("inputs.csv"), assessment_id == id)
o <- subset(read_table("outputs.csv"), assessment_id == id)
stopifnot(nrow(s) == 1L, s$authority_stock_id == "cod.27.2.coastS", nrow(a) == 1L,
  a$is_current, a$is_applied, a$assessment_year == 2026, a$terminal_year == 2025,
  a$model_family == "SPiCT", nrow(z) == 1083L, nrow(o) == 99L,
  sum(z$measure == "landings_numbers_at_age") == 288L,
  sum(z$measure == "numbers_at_age") == 288L,
  sum(z$measure == "catch_weight_at_age") == 288L,
  sum(z$measure == "relative_biomass_index") == 36L,
  sum(z$measure == "log_index_sd") == 36L,
  sum(o$measure == "B_over_Bmsy") == 49L, sum(o$measure == "F_over_Fmsy") == 49L,
  !any(o$measure %in% c("SSB", "numbers_at_age", "fishing_mortality_at_age", "recruitment")),
  !any(o$year == 2026, na.rm = TRUE))
get <- function(measure, year, age = NA_integer_, fleet = NA_character_, survey = NA_character_) {
  x <- z[z$measure == measure & !is.na(z$year) & z$year == year &
    (if (is.na(age)) is.na(z$age) else !is.na(z$age) & z$age == age) &
    (if (is.na(fleet)) TRUE else z$fleet == fleet) &
    (if (is.na(survey)) TRUE else z$survey == survey), ]
  x <- x[!is.na(x$assessment_id), ]; stopifnot(nrow(x) == 1L); x
}
stopifnot(get("total_biomass", 2025, fleet = "Total catch")$value == 6976,
  get("total_biomass", 1977, fleet = "Total catch")$value == 14550,
  get("total_biomass", 1977, fleet = "Total catch")$source_type == "reconstructed_source_input",
  get("total_biomass", 2025, fleet = "Total catch")$source_type == "official_table",
  get("landings_numbers_at_age", 2025, 3)$value == 44,
  get("numbers_at_age", 2025, 3)$value == 280,
  get("catch_weight_at_age", 2025, 10)$value == 12.238,
  get("relative_biomass_index", 2025, survey = "Coastal acoustic-trawl survey A6335, trawl index")$value == 7890,
  get("log_index_sd", 2025, survey = "Shallow net survey N5624")$value == .10,
  o$value[o$measure == "B_over_Bmsy" & o$year == 2025] == .42,
  o$lwr[o$measure == "B_over_Bmsy" & o$year == 2025] == .29,
  o$upr[o$measure == "F_over_Fmsy" & o$year == 2025] == 2.24)
cat("Southern coastal cod assessment, source units and relative states passed.\n")
