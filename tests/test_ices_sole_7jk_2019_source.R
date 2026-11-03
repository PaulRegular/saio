base <- "database"
read_table <- function(file) data.table::fread(file.path(base, file), na.strings = c("", "NA"), blank.lines.skip = TRUE, data.table = FALSE)
id <- "ices_sole_7jk_2019_xsa"
a <- subset(read_table("assessments.csv"), assessment_id == id)
z <- subset(read_table("inputs.csv"), assessment_id == id)
o <- subset(read_table("outputs.csv"), assessment_id == id)
stopifnot(nrow(a) == 1L, a$stock_id == "ck_ices_wgsce_solea_is7jk", a$is_current,
  a$is_applied, a$assessment_year == 2019, a$terminal_year == 2018,
  nrow(z) == 1317L, nrow(o) == 258L, all(z$region == "ICES divisions 7.j-k"),
  sum(z$measure == "landings_numbers_at_age") == 390L,
  sum(z$measure == "numbers_at_age" & z$type == "index") == 91L,
  sum(o$measure == "numbers_at_age") == 90L,
  sum(o$measure == "fishing_mortality_at_age") == 90L,
  !any(o$year == 2019),
  all(z$unit[z$measure == "landings_numbers_at_age"] == "number (source scale not stated)"),
  all(z$source_type[z$type %in% c("M", "maturity")] == "official_document"))
get <- function(measure, year, age) {
  x <- z[z$measure == measure & !is.na(z$year) & z$year == year & !is.na(z$age) & z$age == age, ]
  stopifnot(nrow(x) == 1L); x$value
}
stopifnot(get("landings_numbers_at_age", 1993, 2) == 32.8,
  get("landings_numbers_at_age", 2018, 3) == .8,
  get("weight_at_age", 2018, 2) == 0,
  get("numbers_at_age", 2018, 3) == 15,
  o$value[o$measure == "SSB" & o$year == 2018] == 536,
  o$value[o$measure == "fishing_mortality_at_age" & o$year == 2018 & o$age == 3] == .051,
  o$value[o$measure == "numbers_at_age" & o$year == 2018 & o$age == 3] == 17)
calculated <- function(yr) {
  catch <- z[z$measure == "landings_numbers_at_age" & !is.na(z$year) & z$year == yr, ]
  weight <- z[z$measure == "weight_at_age" & !is.na(z$year) & z$year == yr, ]
  stopifnot(identical(catch$age, weight$age)); sum(catch$value * weight$value)
}
stopifnot(abs(calculated(1993) - 246) < 1, abs(calculated(1999) - 200) > 90)
cat("Historical 7.j-k sole coverage, source values and unresolved scale passed.\n")
