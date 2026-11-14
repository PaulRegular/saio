old_dry_run <- Sys.getenv("SAIO_SOURCE_DRY_RUN", unset = NA_character_)
Sys.setenv(SAIO_SOURCE_DRY_RUN = "1")

e <- new.env(parent = globalenv())
sys.source("scripts/database/651_import_ices_plaice_iceland_5a_2026_age_tables.R", envir = e)

# Round-trip the punctuation that was corrupted in the assumptions table.
fixture <- data.frame(value = c("1947\u20132026", "N \u00d7 weight", "\u00a74.1"))
path <- tempfile(fileext = ".csv")
e$write_csv(fixture, path)
bytes <- readBin(path, "raw", n = file.info(path)$size)
reloaded <- read.csv(path, encoding = "UTF-8")
stopifnot(!any(bytes == as.raw(0)), identical(enc2utf8(reloaded$value), enc2utf8(fixture$value)))
unlink(path)

get_input <- function(measure) e$inputs[e$inputs$measure == measure, , drop = FALSE]
get_output <- function(measure) e$outputs[e$outputs$measure == measure, , drop = FALSE]
value_at <- function(data, year, age) as.numeric(data$value[data$year == year & data$age == age])

catch <- e$inputs[e$inputs$type == "catch" & e$inputs$measure == "numbers_at_age", , drop = FALSE]
catch_weight <- get_input("catch_weight_at_age")
stock_weight <- get_input("weight_at_age")
maturity <- get_input("maturity_at_age")
spring_index <- e$inputs[e$inputs$type == "index", , drop = FALSE]
natural_mortality <- get_input("natural_mortality_at_age")
N <- get_output("numbers_at_age")
F <- get_output("fishing_mortality_at_age")

stopifnot(
  e$manifest_row$bytes == "4695668",
  e$manifest_row$sha256 == "ddeda8cdf6172a49bbd9658b77a81d225cea1ec7b791cff10fea8256d9fc054e",
  nrow(catch) == 460L,
  nrow(catch_weight) == 460L,
  nrow(stock_weight) == 460L,
  nrow(maturity) == 460L,
  nrow(spring_index) == 405L,
  e$missing_index_cells == 5L,
  nrow(natural_mortality) == 10L,
  nrow(N) == 470L,
  nrow(F) == 460L,
  identical(sort(unique(as.integer(catch$year))), 1980:2025),
  identical(sort(unique(as.integer(spring_index$year))), 1985:2025),
  identical(sort(unique(as.integer(N$year))), 1980:2026),
  identical(sort(unique(as.integer(F$year))), 1980:2025),
  all(as.integer(catch$age) %in% 3:12),
  all(catch$unit == "thousand_fish"),
  all(catch$fleet == "Commercial fishery"),
  value_at(catch, "1980", "3") == 150,
  value_at(catch, "1980", "12") == 104,
  all(catch_weight$unit == "g"),
  all(catch_weight$basis == "g_per_fish"),
  value_at(catch_weight, "1980", "3") == 423,
  all(stock_weight$unit == "g"),
  value_at(stock_weight, "1980", "3") == 244,
  all(maturity$sex == "female"),
  all(as.numeric(maturity$value) >= 0 & as.numeric(maturity$value) <= 1),
  value_at(maturity, "1980", "3") == 0.047,
  all(spring_index$basis == "index_scale"),
  all(spring_index$unit == "number (index scale; multiplier not stated)"),
  all(is.na(spring_index$sampling_time)),
  value_at(spring_index, "1985", "3") == 1.068,
  all(as.numeric(natural_mortality$value) == 0.15),
  all(is.na(natural_mortality$year)),
  value_at(N, "1980", "3") == 26307,
  value_at(N, "2026", "3") > 0,
  all(N$scenario[N$year == "2026"] == "short_term_forecast"),
  all(is.na(N$scenario[N$year != "2026"])),
  value_at(F, "1980", "3") == 0.007,
  all(F$age_group[F$age == "12"] == "12+"),
  all(N$age_group[N$age == "12"] == "12+"),
  e$assessment$outputs_status == "complete",
  e$assessment$inputs_status == "partial",
  e$assessment$assumptions_status == "partial",
  any(e$assumptions$setting == "survey_index_scale" &
    e$assumptions$value == "Scale multiplier not stated"),
  grepl("1979", e$assessment$notes, fixed = TRUE),
  e$register$import_status[e$candidate_row] == "partial",
  e$selected$curation_status[e$selected_row] == "partial_source_import"
)

cat("ICES Icelandic plaice 2026 age-table source test passed.\n")
if (is.na(old_dry_run)) Sys.unsetenv("SAIO_SOURCE_DRY_RUN") else {
  Sys.setenv(SAIO_SOURCE_DRY_RUN = old_dry_run)
}
