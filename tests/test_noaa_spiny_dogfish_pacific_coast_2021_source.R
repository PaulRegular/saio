assessment_id <- "noaa_spiny_dogfish_pacific_coast_2021"
.libPaths(c(file.path(".", "source_cache", "r-lib"), .libPaths()))
read_assessment_rows <- function(table) {
  path <- file.path("database", paste0(table, ".csv"))
  header <- readLines(path, n = 1L, warn = FALSE)
  column_names <- names(read.csv(text = header, check.names = FALSE))
  rows_file <- tempfile(fileext = ".csv")
  on.exit(unlink(rows_file), add = TRUE)
  status <- suppressWarnings(system2("rg",
    c("--color", "never", "--no-heading", "-F", assessment_id, path),
    stdout = rows_file, stderr = FALSE))
  if (!is.null(status) && status == 1L) return(data.frame())
  if (!is.null(status) && status != 0L) stop("Could not scan ", path)
  data.table::fread(rows_file, header = FALSE, col.names = column_names,
    na.strings = c("", "NA"), showProgress = FALSE, data.table = FALSE)
}
i <- read_assessment_rows("inputs")
o <- read_assessment_rows("outputs")
stopifnot(nrow(i) == 16214L, nrow(o) == 275294L,
  all(is.finite(i$value)), all(is.finite(o$value)),
  sum(i$measure == "catch_biomass") == 840L,
  sum(i$measure == "log_catch_sd") == 840L,
  sum(i$measure == "relative_biomass_index" & i$type == "index") == 35L,
  sum(i$measure == "relative_abundance_index" & i$type == "index") == 20L,
  sum(i$measure == "log_index_sd") == 55L,
  sum(i$measure == "frequency_at_length") == 9672L,
  sum(i$measure == "conditional_frequency_at_age") == 4752L)
catch <- i[i$measure == "catch_biomass", ]
index <- i[i$type == "index" & i$measure %in% c("relative_biomass_index", "relative_abundance_index"), ]
age <- i[i$measure == "conditional_frequency_at_age", ]
lengths <- i[i$measure == "frequency_at_length", ]
stopifnot(setequal(catch$year, 1916:2020), setequal(catch$fleet,
  c("Bottom_Trawl_Discard", "Bottom_Trawl_Landings", "Midwater_Trawl",
    "At_Sea_Hake_Bycatch", "Nontrawl_Landings", "Nontrawl_Discard",
    "Nontrawl_VitaminA_Fishery", "Recreational_Catch")),
  setequal(index$survey, c("AFSC_Triennial", "AFSC_Slope", "WCGBTS", "NWFSC_Slope", "IPHC")),
  all(index$year %in% 1980:2019), all(index$sampling_time == 0.5),
  length(unique(lengths$observation_id)) == 156L,
  length(unique(age$observation_id)) == 33L, setequal(age$year, 2010L),
  setequal(age$age, 0:71), all(age$type == "biology"),
  all(age$length_bin_lower <= age$length_bin_upper),
  sum(age$sample_size[!duplicated(age$observation_id)]) == 515L,
  !any(i$measure %in% c("catch_numbers", "index_catch_numbers_at_age")))
N <- o[o$measure == "numbers_at_age", ]
B <- o[o$measure == "biomass_at_age", ]
F_fleet <- o[o$measure == "fishing_mortality_at_age" & !is.na(o$fleet) & nzchar(o$fleet), ]
F_total <- o[o$measure == "fishing_mortality_at_age" & (is.na(o$fleet) | !nzchar(o$fleet)), ]
M <- o[o$measure == "natural_mortality_at_age", ]
weights <- o[o$measure == "weight_at_age", ]
maturity <- o[o$measure == "maturity_at_age", ]
spawning <- o[o$measure == "spawning_output", ]
recruitment <- o[o$measure == "recruitment", ]
total_numbers <- o[o$measure == "total_numbers", ]
age1plus <- o[o$measure == "biomass_by_age_group", ]
stopifnot(nrow(N) == 106L * 2L * 96L, nrow(B) == nrow(N),
  nrow(F_fleet) == 106L * 8L * 2L * 96L,
  nrow(F_total) == nrow(N), nrow(M) == nrow(N), nrow(weights) == nrow(N),
  nrow(maturity) == 106L * 96L, nrow(spawning) == 106L,
  nrow(recruitment) == 106L, nrow(total_numbers) == 106L,
  nrow(age1plus) == 117L, all(N$year %in% 1916:2021),
  setequal(N$age, 0:95), setequal(N$sex, c("female", "male")),
  all(abs(M$value[M$age %in% 0:94] - 0.065) < 1e-10),
  all(M$value[M$age == 95] == 0.065),
  all(M$source_type[M$age == 95] == "derived_source_output"),
  all(maturity$value >= 0 & maturity$value <= 1),
  all(is.na(N$se) & is.na(N$lwr) & is.na(N$upr)),
  setequal(spawning$year[!is.na(spawning$lwr)], 2011:2021),
  setequal(recruitment$year[!is.na(recruitment$lwr)], 2011:2021))
ssb2021 <- spawning[spawning$year == 2021L, ]
rec2021 <- recruitment[recruitment$year == 2021L, ]
stopifnot(nrow(ssb2021) == 1L, abs(ssb2021$value - 13613.1) < 0.2,
  ssb2021$lwr == 7994, ssb2021$upr == 19232,
  nrow(rec2021) == 1L, abs(rec2021$value - 9108.74) < 0.02,
  rec2021$lwr == 6666, rec2021$upr == 12446)
N_sum <- aggregate(value ~ year, N, sum)
stopifnot(max(abs(total_numbers$value[match(N_sum$year, total_numbers$year)] - N_sum$value)) < 1e-8)
F_sum <- aggregate(value ~ year + sex + age, F_fleet, sum)
F_check <- merge(F_sum, F_total[, c("year", "sex", "age", "value")],
  by = c("year", "sex", "age"), suffixes = c("_fleet", "_sum"))
stopifnot(nrow(F_check) == nrow(F_total),
  max(abs(F_check$value_fleet - F_check$value_sum)) < 1e-9)
model_bio <- age1plus[grepl("WCGBTS q=0.43", age1plus$scenario) &
  age1plus$year == 2021L, ]
report_bio <- age1plus[age1plus$scenario == "report Table ES-8" &
  age1plus$year == 2021L, ]
stopifnot(nrow(model_bio) == 1L, abs(model_bio$value - 110047) < 1,
  nrow(report_bio) == 1L, report_bio$value == 255602)
stocks <- read.csv("database/stocks.csv", stringsAsFactors = FALSE, na.strings = c("", "NA"))
assessments <- read.csv("database/assessments.csv", stringsAsFactors = FALSE, na.strings = c("", "NA"))
candidates <- read.csv("discovery/candidates.csv", stringsAsFactors = FALSE, na.strings = c("", "NA"))
units <- read.csv("discovery/inventory_units.csv", stringsAsFactors = FALSE, na.strings = c("", "NA"))
stock <- stocks[stocks$stock_id == "noaa_spiny_dogfish_pacific_coast", ]
assessment <- assessments[assessments$assessment_id == assessment_id, ]
candidate <- candidates[candidates$candidate_id == "NOAA:10702", ]
unit <- units[!is.na(units$candidate_unit_id) & units$candidate_unit_id == "noaa_spiny_dogfish_pacific_coast_2021", ]
stopifnot(nrow(stock) == 1L, stock$scientific_name == "Squalus suckleyi",
  stock$ocean == "Northeast Pacific", nrow(assessment) == 1L,
  assessment$terminal_year == 2020L, assessment$estimate_terminal_year == 2021L,
  assessment$inputs_status == "partial", assessment$outputs_status == "partial",
  nrow(candidate) == 1L, candidate$match_status == "matched",
  candidate$matched_stock_id == stock$stock_id, candidate$import_status == "partial",
  nrow(unit) == 1L, unit$matched_stock_id == stock$stock_id,
  unit$import_status == "partial")
cat("NOAA Pacific spiny dogfish 2021 source checks passed.\n")
