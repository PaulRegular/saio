base <- "database"
read_table <- function(file) data.table::fread(file.path(base, file), na.strings = c("", "NA"), blank.lines.skip = TRUE, data.table = FALSE)
ids <- c("ices_herring_6a_n_2025", "ices_herring_6a_n_2026")
stocks <- read_table("stocks.csv")
a <- read_table("assessments.csv")
z <- read_table("inputs.csv"); z <- z[z$assessment_id %in% ids, ]
o <- read_table("outputs.csv"); o <- o[o$assessment_id %in% ids, ]
stock <- stocks[stocks$stock_id == "ck_ices_hawg_harengus_cs_6a_n", ]
stopifnot(nrow(stock) == 1L, stock$authority_stock_id == "her.27.6aN",
  sum(z$assessment_id == ids[1]) == 1566L, sum(z$assessment_id == ids[2]) == 1629L,
  sum(o$assessment_id == ids[1]) == 33L, sum(o$assessment_id == ids[2]) == 36L,
  all(is.na(z$sampling_time[z$survey == "MSHAS 6.aN" & !is.na(z$survey)])))
a <- a[match(ids, a$assessment_id), ]
stopifnot(identical(a$assessment_year, c(2025L, 2026L)),
  identical(a$terminal_year, c(2024L, 2025L)),
  !a$is_current[1], a$is_current[2], a$is_applied[1], a$is_applied[2],
  all(a$inputs_status == "partial"), all(a$outputs_status == "partial"),
  grepl("Invalid", a$notes[2], fixed = TRUE))
get <- function(id, type, measure, year, age = NA_integer_) {
  v <- z[z$assessment_id == id & z$type == type & z$measure == measure &
    !is.na(z$year) & z$year == year &
    if (is.na(age)) is.na(z$age) else (!is.na(z$age) & z$age == age), , drop = FALSE]
  stopifnot(nrow(v) == 1L); v
}
for (id in ids) {
  stopifnot(get(id, "index", "total_biomass", 2023)$value == 23117,
    get(id, "index", "total_biomass", 2024)$value == 12557,
    get(id, "index", "numbers_at_age", 2023, 1)$value == 46.86,
    get(id, "catch", "numbers_at_age", 2021, 2)$value == 3188,
    get(id, "catch", "total_biomass", 2022)$value == 51,
    get(id, "weight", "weight_at_age", 2019, 9)$value == .212,
    get(id, "maturity", "maturity_at_age", 2018, 2)$value == .37)
  w <- z[z$assessment_id == id & z$type == "weight" & z$year == 2019 & z$age == 8, ]
  stopifnot(nrow(w) == 0L)
  r <- o[o$assessment_id == id & o$measure == "relative_harvest_rate" & o$year == 2023, ]
  wg <- o[o$assessment_id == id & o$measure == "survey_biomass_index_working_group" & o$year == 2023, ]
  stopifnot(nrow(wg) == 1L, wg$value == 22.463, wg$unit == "thousand tonnes",
    nrow(r) == 1L, abs(r$value - 488.42/22463) < 1e-8,
    !any(o$assessment_id == id & o$measure %in% c("SSB", "fishing_mortality_at_age", "numbers_at_age")))
}
stopifnot(is.na(get(ids[1], "catch", "numbers_at_age", 2022, 1)$value),
  get(ids[2], "catch", "numbers_at_age", 2022, 1)$value == 0,
  is.na(get(ids[2], "catch", "numbers_at_age", 2023, 1)$value),
  get(ids[2], "catch_weight", "catch_weight_at_age", 2024, 1)$value == 0,
  get(ids[2], "index", "total_biomass", 2025)$value == 1588,
  get(ids[2], "weight", "weight_at_age", 2025, 1)$value == 63.66,
  get(ids[2], "weight", "weight_at_age", 2025, 1)$unit == "g/fish",
  get(ids[2], "maturity", "maturity_at_age", 2025, 3)$value == .99)
cat("Northern 6.a herring source identity, coverage, conflicts, units and advice status passed.\n")
