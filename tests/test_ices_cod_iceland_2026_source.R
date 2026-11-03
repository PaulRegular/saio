source("R/read_database.R")

database <- read_database()
source_record <- read_assessment("ices_cod_iceland_2026", database)
assessment <- source_record$assessment
stock <- source_record$stocks
inputs <- source_record$inputs
outputs <- source_record$outputs
rows <- function(x, type, measure) x[x$type == type & x$measure == measure, , drop = FALSE]

catch <- rows(inputs, "catch", "numbers_at_age")
index <- rows(inputs, "index", "numbers_at_age")
N <- rows(outputs, "population", "numbers_at_age")
F <- rows(outputs, "mortality", "fishing_mortality_at_age")
SSB <- rows(outputs, "biomass", "SSB")
recruitment <- rows(outputs, "recruitment", "recruitment")
common_total <- rows(outputs, "population", "total_numbers")
all_total <- rows(outputs, "population", "total_numbers_all_ages")

stopifnot(
  nrow(stock) == 1L,
  stock$authority_stock_id == "cod.27.5a",
  stock$common_name == "Icelandic cod",
  stock$area == "ICES Division 5.a (Iceland grounds)",
  stock$ocean == "Northeast Atlantic",
  isTRUE(assessment$is_current), isTRUE(assessment$is_applied),
  assessment$terminal_year == 2026L,
  assessment$inputs_status == "partial",
  assessment$outputs_status == "partial",
  assessment$assumptions_status == "partial",
  nrow(catch) == 852L,
  identical(sort(unique(as.integer(catch$year))), 1955:2025),
  setequal(as.integer(unique(catch$age)), 3:14),
  all(catch$unit == "thousand fish"),
  sum(index$survey == "IS-SMB") == 588L,
  sum(index$survey == "IS-SMH") == 409L,
  sum(index$value[index$survey == "IS-SMB"] == 0) == 17L,
  !any(index$survey == "IS-SMH" & index$year == 2011 & index$age %in% 3:13),
  all(index$basis == "index_scale"),
  all(index$unit == "native survey index units"),
  nrow(rows(inputs, "catch_weight", "weight_at_age")) == 1008L,
  nrow(rows(inputs, "weight", "spawning_weight_at_age")) == 1008L,
  nrow(rows(inputs, "weight", "weight_at_age")) == 1008L,
  all(rows(inputs, "weight", "weight_at_age")$basis == "g_per_fish"),
  nrow(rows(inputs, "maturity", "maturity_at_age")) == 1008L,
  all(rows(inputs, "M", "natural_mortality_at_age")$value == 0.2),
  nrow(N) == 1008L,
  nrow(F) == 994L,
  max(F$year) == 2025L,
  nrow(SSB) == 72L,
  SSB$value[SSB$year == 2026] == 377277,
  nrow(recruitment) == 72L,
  nrow(rows(outputs, "biomass", "reference_biomass")) == 72L,
  nrow(rows(outputs, "mortality", "Fbar")) == 71L,
  all(rows(outputs, "mortality", "Fbar")$age_group == "5-10"),
  nrow(common_total) == 72L,
  nrow(all_total) == 72L,
  all(is.na(common_total$se)),
  all(SSB$source_type == "official_machine_readable"),
  all(is.finite(SSB$lwr) & is.finite(SSB$upr)),
  grepl("371,000", assessment$notes),
  any(outputs$measure == "reference_biomass")
)

source_N <- N[N$age %in% 3:14, ]
source_total <- aggregate(value ~ year, source_N, sum)
stopifnot(isTRUE(all.equal(
  common_total$value[match(source_total$year, common_total$year)],
  source_total$value, tolerance = 1e-12
)))

cat("Icelandic cod source records cover the expected input and output series.\n")
