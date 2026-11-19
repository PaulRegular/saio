base <- "database"
read_table <- function(file) data.table::fread(file.path(base, file), na.strings = c("", "NA"), blank.lines.skip = TRUE, data.table = FALSE)
ids <- c("ices_herring_6a_s_7bc_2025", "ices_herring_6a_s_7bc_2026")
stocks <- read_table("stocks.csv"); a <- read_table("assessments.csv"); assumptions <- read_table("assumptions.csv")
z <- read_table("inputs.csv"); z <- z[z$assessment_id %in% ids, ]
o <- read_table("outputs.csv"); o <- o[o$assessment_id %in% ids, ]
stock <- stocks[stocks$stock_id == "ck_ices_hawg_harengus_cs6_a_s_7b_c", ]
stopifnot(nrow(stock) == 1L, stock$authority_stock_id == "her.27.6aS7bc",
  sum(z$assessment_id == ids[1]) == 1903L, sum(z$assessment_id == ids[2]) == 1960L,
  sum(o$assessment_id == ids[1]) == 22L, sum(o$assessment_id == ids[2]) == 24L,
  all(is.na(z$sampling_time[z$survey == "MSHAS 6.aS 7.b-c" & !is.na(z$survey)])))
a <- a[match(ids, a$assessment_id), ]
stopifnot(identical(a$assessment_year, c(2025L, 2026L)),
  identical(a$terminal_year, c(2024L, 2025L)),
  !a$is_current[1], a$is_current[2], all(a$is_applied),
  all(a$inputs_status == "partial"), all(a$outputs_status == "partial"),
  grepl("Invalid", a$notes[2], fixed = TRUE))
get <- function(id, type, measure, year, age = NA_integer_) {
  v <- z[z$assessment_id == id & z$type == type & z$measure == measure &
    !is.na(z$year) & z$year == year &
    if (is.na(age)) is.na(z$age) else (!is.na(z$age) & z$age == age), , drop = FALSE]
  stopifnot(nrow(v) == 1L); v
}
for (id in ids) {
  repaired <- get(id, "catch", "numbers_at_age", 1991, 5)
  stopifnot(repaired$value == 100444,
    repaired$source_type == "reconstructed_source_input",
    grepl("wrapped", repaired$transformation),
    get(id, "catch", "numbers_at_age", 1970, 1)$value == 135,
    get(id, "catch", "numbers_at_age", 2024, 3)$value == 7621,
    get(id, "index", "total_biomass", 2024)$value == 54657,
    get(id, "index", "total_biomass", 2024)$source_type == "official_machine_readable",
    get(id, "catch", "total_biomass", 2024)$source_type == "official_machine_readable",
    get(id, "index", "relative_standard_error", 2024)$value == .36,
    get(id, "biology", "mean_catch_length", 2024)$value == 25.4,
    get(id, "biology", "length_at_first_capture", 2024)$value == 23.5,
    get(id, "biology", "MSY_proxy_length", 2024)$value == 26.5,
    get(id, "index", "numbers_at_age", 2014, 2)$value == 30.02,
    get(id, "weight", "weight_at_age", 2014, 2)$value == 134.74,
    get(id, "weight", "weight_at_age", 2014, 2)$unit == "g/fish",
    get(id, "maturity", "maturity_at_age", 2014, 1)$value == 0,
    !any(o$assessment_id == id & o$measure %in% c("SSB", "fishing_mortality_at_age", "numbers_at_age")))
  m <- subset(z, assessment_id == id & type == "M" & age == 5)
  stopifnot(nrow(m) == 1L, m$value == .207, is.na(m$year))
  missing_age <- z[z$assessment_id == id & z$type == "index" & z$measure == "numbers_at_age" &
    !is.na(z$year) & z$year == 2014 & !is.na(z$age) & z$age == 1, ]
  stopifnot(nrow(missing_age) == 0L)
}
rule <- subset(assumptions, assessment_id == ids[2] & setting == "chr_rule")
stopifnot(nrow(rule) == 1L, grepl("b=0.151", rule$notes, fixed = TRUE),
  grepl("51340", rule$notes, fixed = TRUE))
stopifnot(get(ids[2], "catch", "numbers_at_age", 2025, 1)$value == 329,
  get(ids[2], "index", "total_biomass", 2025)$value == 7774,
  get(ids[2], "index", "relative_standard_error", 2025)$value == .39,
  get(ids[2], "index", "numbers_at_age", 2025, 9)$value == 0,
  !any(z$assessment_id == ids[2] & z$type == "weight" & z$year == 2025 & z$age == 9, na.rm = TRUE),
  !any(z$assessment_id == ids[2] & z$type == "maturity" & z$year == 2025 & z$age == 9, na.rm = TRUE))
cat("Southern 6.a/7.b-c herring coverage, wrapped cell, units, missing ages and advice status passed.\n")
