source("R/read_database.R")
source("tests/helper_inventory.R")

x <- read_assessment("afma_patagonian_toothfish_macquarie_2025")
candidate_register <- read.csv("discovery/candidates.csv",
  stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)
candidate <- candidate_register[
  candidate_register$candidate_id == "AFMA:MITF", , drop = FALSE
]
progress <- read.csv("discovery/inventory_progress.csv",
  stringsAsFactors = FALSE)
units <- read.csv("discovery/inventory_units.csv",
  stringsAsFactors = FALSE)
manifest <- read.csv("provenance/afma_mitf_2025_sources.csv",
  stringsAsFactors = FALSE, check.names = FALSE)

check_inventory_accounting(candidate_register, progress, units)

stopifnot(
  x$stocks$stock_id == "afma_patagonian_toothfish_macquarie",
  x$stocks$authority == "AFMA",
  x$stocks$authority_stock_id == "MITF",
  x$stocks$scientific_name == "Dissostichus eleginoides",
  x$stocks$ocean == "Southern Ocean",
  x$assessment$assessment_year == 2025L,
  x$assessment$terminal_year == 2025L,
  x$assessment$estimate_terminal_year == 2025L,
  x$assessment$is_current,
  x$assessment$is_applied,
  all(x$assessment[c("assumptions_status", "inputs_status",
    "outputs_status")] == "partial"),
  nrow(x$inputs) == 84L,
  all(x$inputs$type == "catch"),
  all(x$inputs$measure == "catch_biomass"),
  all(x$inputs$basis == "biomass"),
  all(x$inputs$year_basis == "model_year"),
  all(x$inputs$unit == "t"),
  length(unique(x$inputs$season)) == 31L,
  all(x$inputs$value >= 0),
  any(x$inputs$value == 0),
  sum(x$inputs$season == "2024/25") == 3L,
  x$inputs$value[x$inputs$fleet == "Aurora Trough trawl (ATT)" &
    x$inputs$season == "1994/95"] == 427.3,
  sum(x$assumptions$setting == "natural_mortality") == 1L,
  nrow(x$outputs) == 3L,
  all(x$outputs$measure == "SSB_ratio_to_B0"),
  all(x$outputs$sex == "female"),
  all(x$outputs$year == 2025L),
  x$outputs$value[x$outputs$region == "Whole stock"] == 0.66,
  x$outputs$lwr[x$outputs$region == "North"] == 0.76,
  x$outputs$upr[x$outputs$region == "South"] == 0.40,
  candidate$eligibility == "unresolved",
  candidate$import_status == "partial",
  nrow(manifest) == 2L,
  all(manifest$retrieved_on == "2026-11-06"),
  all(nchar(manifest$sha256) == 64L),
  all(file.exists(file.path("source_cache", manifest$local_file)))
)

cached_files <- file.path("source_cache", manifest$local_file)
stopifnot(identical(
  toupper(unname(tools::sha256sum(cached_files))),
  toupper(manifest$sha256)
))

for (season in unique(x$inputs$season)) {
  fleet_catch <- sum(x$inputs$value[x$inputs$season == season])
  source_total <- c(
    "1994/95" = 427, "1995/96" = 933, "1996/97" = 987, "1997/98" = 571,
    "1998/99" = 99, "1999/00" = 16, "2000/01" = 26, "2001/02" = 0,
    "2002/03" = 40, "2003/04" = 353, "2004/05" = 57, "2005/06" = 272,
    "2006/07" = 237, "2007/08" = 320, "2008/09" = 453, "2009/10" = 214,
    "2010/11" = 264, "2011/12" = 358, "2012/13" = 332, "2013/14" = 404,
    "2014/15" = 409, "2015/16" = 324, "2016/17" = 434, "2017/18" = 358,
    "2018/19" = 448, "2019/20" = 451, "2020/21" = 537, "2021/22" = 458,
    "2022/23" = 439, "2023/24" = 457, "2024/25" = 465
  )
  stopifnot(abs(fleet_catch - unname(source_total[season])) <= 0.55)
}

cat("AFMA Macquarie Island toothfish 2025 source checks passed.\n")
