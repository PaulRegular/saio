source_id <- "afma_patagonian_toothfish_macquarie_2025"
stock_id <- "afma_patagonian_toothfish_macquarie"
candidate_id <- "AFMA:MITF"

if (!file.exists("database/stocks.csv")) {
  stop("Run this script from the SAIO repository root.")
}

read_table <- function(path) {
  read.csv(path, stringsAsFactors = FALSE, colClasses = "character",
    na.strings = c("", "NA"), check.names = FALSE)
}

append_rows <- function(path, rows) {
  size <- file.info(path)$size
  if (size > 0) {
    con <- file(path, open = "rb")
    seek(con, where = size - 1, origin = "start")
    final_byte <- readBin(con, what = "raw", n = 1L)
    close(con)
    if (!identical(final_byte, as.raw(10L))) {
      con <- file(path, open = "ab")
      writeBin(as.raw(c(13L, 10L)), con)
      close(con)
    }
  }
  rows[] <- lapply(rows, as.character)
  write.table(rows, path, sep = ",", row.names = FALSE, col.names = FALSE,
    append = TRUE, quote = TRUE, qmethod = "double", na = "", eol = "\n")
}

manifest <- read_table("provenance/afma_mitf_2025_sources.csv")
local_files <- file.path("source_cache", manifest$local_file)
if (any(!file.exists(local_files))) {
  stop("The cached AFMA source PDFs are required before importing this record.")
}
actual_hashes <- toupper(unname(tools::sha256sum(local_files)))
if (!identical(actual_hashes, toupper(manifest$sha256))) {
  stop("A cached AFMA source PDF does not match its recorded SHA-256 checksum.")
}

stocks <- read_table("database/stocks.csv")
assessments <- read_table("database/assessments.csv")
candidates <- read_table("discovery/candidates.csv")
candidate_rows <- which(candidates$candidate_id == candidate_id)
stopifnot(!stock_id %in% stocks$stock_id,
  !source_id %in% assessments$assessment_id,
  length(candidate_rows) == 1L,
  candidates$eligibility[candidate_rows] == "unresolved",
  candidates$import_status[candidate_rows] == "not_started")

catch_table <- read.csv(text = paste(
  "season,ATT,NVT,ATL,NMRL,SMRL,reported_total,TAC",
  "1994/95,427.3,0.0,,,,427,",
  "1995/96,932.9,0.0,,,,933,",
  "1996/97,486.3,500.3,,,,987,1750",
  "1997/98,188.2,382.8,,,,571,1700",
  "1998/99,58.5,40.5,,,,99,640",
  "1999/00,9.0,6.6,,,,16,550",
  "2000/01,25.4,0.6,,,,26,460",
  "2001/02,0.0,0.0,,,,0,282",
  "2002/03,36.4,3.3,,,,40,245",
  "2003/04,352.8,0.7,,,,353,528",
  "2004/05,56.8,0.6,,,,57,208",
  "2005/06,264.5,7.9,,,,272,380",
  "2006/07,237.3,0.0,,,,237,341",
  "2007/08,236.8,0.0,5.4,9.0,69.2,320,476",
  "2008/09,306.1,0.0,0.0,37.1,109.8,453,462",
  "2009/10,,,66.6,8.7,138.2,214,210",
  "2010/11,,,120.2,0.0,143.6,264,290",
  "2011/12,,,148.2,27.4,181.9,358,510",
  "2012/13,,,167.3,14.5,149.7,332,455",
  "2013/14,,,258.5,13.8,131.3,404,415",
  "2014/15,,,141.2,248.0,19.6,409,410",
  "2015/16,,,160.8,81.1,82.6,324,460",
  "2016/17,,,202.4,98.9,133.0,434,450",
  "2017/18,,,104.1,28.5,225.0,358,450",
  "2018/19,,,227.8,111.7,108.7,448,450",
  "2019/20,,,227.9,143.5,79.7,451,450",
  "2020/21,,,292.8,192.9,51.6,537,555",
  "2021/22,,,252.1,34.6,171.4,458,555",
  "2022/23,,,262.9,37.2,139.2,439,635",
  "2023/24,,,186.0,66.4,204.1,457,635",
  "2024/25,,,221.5,32.4,211.5,465,468",
  sep = "\n"
), stringsAsFactors = FALSE, na.strings = "", check.names = FALSE)

stopifnot(nrow(catch_table) == 31L,
  !anyDuplicated(catch_table$season),
  all(abs(rowSums(catch_table[c("ATT", "NVT", "ATL", "NMRL", "SMRL")], na.rm = TRUE) - catch_table$reported_total) <= 0.55))

fleet_names <- c(
  ATT = "Aurora Trough trawl (ATT)",
  NVT = "Northern Valley trawl (NVT)",
  ATL = "Aurora Trough longline (ATL)",
  NMRL = "Northern Macquarie Ridge longline (NMRL)",
  SMRL = "Southern Macquarie Ridge longline (SMRL)"
)
fleet_regions <- c(ATT = "South", NVT = "North", ATL = "South",
  NMRL = "North", SMRL = "South")
catch_reference <- paste(
  "Bessell-Browne and Hillary (2025), Table 2, PDF p. 14"
)

inputs <- do.call(rbind, lapply(names(fleet_names), function(code) {
  rows <- which(!is.na(catch_table[[code]]))
  season <- catch_table$season[rows]
  data.frame(
    assessment_id = source_id,
    type = "catch",
    measure = "catch_biomass",
    basis = "biomass",
    fleet = unname(fleet_names[[code]]),
    survey = NA_character_,
    sex = NA_character_,
    region = unname(fleet_regions[[code]]),
    season = season,
    year = sub("/.*$", "", season),
    year_basis = "model_year",
    age = NA_character_,
    value = catch_table[[code]][rows],
    unit = "t",
    sampling_time = NA_character_,
    source_type = "official_table",
    source_reference = catch_reference,
    transformation = NA_character_,
    notes = paste0(
      "Fishing season ", season,
      "; catch is removals only. The assessment treats fleet catches as known and exact."
    ),
    stringsAsFactors = FALSE
  )
}))

stock <- data.frame(
  stock_id = stock_id,
  charbonneau_id = NA_character_,
  authority = "AFMA",
  authority_stock_id = "MITF",
  scientific_name = "Dissostichus eleginoides",
  common_name = "Patagonian toothfish at Macquarie Island",
  area = "Macquarie Island Toothfish Fishery (MITF), Australian waters",
  region = "Macquarie Island",
  ocean = "Southern Ocean",
  notes = paste(
    "One reproductive stock, represented in the 2025 assessment by north and south model areas.",
    "No Charbonneau-Keith catalogue match was identified."
  ),
  stringsAsFactors = FALSE
)

assessment <- data.frame(
  assessment_id = source_id,
  stock_id = stock_id,
  assessment_year = "2025",
  terminal_year = "2025",
  estimate_terminal_year = "2025",
  assessment_type = "update",
  model_family = "Integrated length-age assessment (TMB)",
  model_version = "2025 Macquarie Island toothfish spatial assessment",
  is_current = "TRUE",
  is_applied = "TRUE",
  framework_year = NA_character_,
  assessment_url = "https://www.afma.gov.au/sites/default/files/2025-09/MITF-toothfish-stock-assessment-2025.pdf",
  framework_url = NA_character_,
  data_url = "https://www.afma.gov.au/fisheries/macquarie-island-toothfish-fishery",
  model_url = NA_character_,
  repository_url = NA_character_,
  assumptions_status = "partial",
  inputs_status = "partial",
  outputs_status = "partial",
  notes = paste(
    "The report describes a 2025 update to the adopted model and a model grid through 2025.",
    "SARAG 73 advised adopting the assessment as the scientific basis for a TAC recommendation;",
    "SouthMAC 45 recorded the 2025 stock status and recommended a 404 t TAC for 2026/27 and 2027/28.",
    "Only fleet-specific catch biomass and terminal female SSB relative to unfished levels are imported.",
    "Age-composition and tag arrays, numeric annual population trajectories, and run-matched biological surfaces were not located."
  ),
  stringsAsFactors = FALSE
)

assumption <- function(component, setting, value, source_reference, notes = "",
                       fleet = NA_character_, region = NA_character_) {
  data.frame(
    assessment_id = source_id,
    component = component,
    fleet = fleet,
    survey = NA_character_,
    sex = NA_character_,
    region = region,
    season = NA_character_,
    setting = setting,
    value = value,
    source_reference = source_reference,
    notes = notes,
    stringsAsFactors = FALSE
  )
}

assumptions <- do.call(rbind, list(
  assumption("population", "stock_structure",
    "One reproductive stock with movement and recruitment in two spatial model areas, North and South.",
    "Bessell-Browne and Hillary (2025), Executive Summary, PDF p. 5"),
  assumption("population", "model_dimensions",
    "Model years 1985-2025; ages 1-52; length classes 0-190 cm; two spatial areas.",
    "Bessell-Browne and Hillary (2025), Section 4.6, PDF p. 23"),
  assumption("population", "fleet_structure",
    "Five fleets: ATT (Aurora Trough trawl, South), NVT (Northern Valley trawl, North), ATL (Aurora Trough longline, South), NMRL (Northern Macquarie Ridge longline, North), and SMRL (Southern Macquarie Ridge longline, South).",
    "Bessell-Browne and Hillary (2025), Sections 4.1.1 and 4.6, PDF pp. 12 and 23"),
  assumption("observation", "catch_treatment",
    "Annual fleet catches are treated as known and exact, not fitted; catch values are removals only.",
    "Bessell-Browne and Hillary (2025), Section 4.1.1 and Table 2, PDF pp. 12 and 14"),
  assumption("observation", "length_frequency_likelihood",
    "Sex-combined fleet length frequencies use a Dirichlet-multinomial likelihood; initial effective sample size is number of hauls for trawl and shots for longline, with over-dispersion estimated by fleet.",
    "Bessell-Browne and Hillary (2025), Sections 4.1.2 and 4.4.1, PDF pp. 15 and 22",
    "Numerical length-frequency arrays were not located in public sources."),
  assumption("observation", "conditional_age_at_length_likelihood",
    "Age within length class is modeled with a multinomial likelihood for each fleet and sex.",
    "Bessell-Browne and Hillary (2025), Sections 4.1.3 and 4.4.2, PDF pp. 17 and 22",
    "Age data cover selected fishing seasons from 1996/97 through 2023/24; numeric age counts within length bins were not located."),
  assumption("observation", "tagging_likelihood",
    "Tag recaptures are modeled with a spatial, length-structured multi-state Brownie likelihood with Dirichlet-multinomial over-dispersion.",
    "Bessell-Browne and Hillary (2025), Sections 4.1.4 and 4.4.3, PDF pp. 18 and 22",
    "Run-matched release and recapture arrays were not located in public sources."),
  assumption("mortality", "natural_mortality",
    "Base assessment fixes age-independent natural mortality at M = 0.13 per year; M = 0.155 per year is a sensitivity.",
    "Bessell-Browne and Hillary (2025), Section 4.2 and Table 9, PDF pp. 20 and 41"),
  assumption("biology", "length_weight_relationship",
    "Weight (tonnes) = 4.4e-6 × length (cm)^3.14.",
    "Bessell-Browne and Hillary (2025), Section 4.2, PDF p. 20",
    "Length-based relationship; no numeric run-matched weight-at-age matrix was located."),
  assumption("assessment", "official_use",
    "SARAG 73 advised adopting the 2025 assessment as the scientific basis for a TAC recommendation; SouthMAC 45 recommended 404 t for 2026/27 and 2027/28.",
    "SouthMAC 45 Final Minutes, Agenda item 4.1, PDF p. 3",
    "This supports marking the 2025 assessment as applied for management advice.")
))

output <- function(region, value, lwr, upr, source_reference, notes) {
  data.frame(
    assessment_id = source_id,
    type = "biomass",
    measure = "SSB_ratio_to_B0",
    fleet = NA_character_,
    survey = NA_character_,
    sex = "female",
    region = region,
    season = NA_character_,
    year = "2025",
    age = NA_character_,
    age_group = NA_character_,
    value = as.character(value),
    se = NA_character_,
    lwr = as.character(lwr),
    upr = as.character(upr),
    unit = "ratio",
    source_type = "official_table",
    source_reference = source_reference,
    notes = notes,
    scenario = NA_character_,
    stringsAsFactors = FALSE
  )
}

output_reference <- paste(
  "Bessell-Browne and Hillary (2025), Section 5.5, PDF p. 40"
)
outputs <- do.call(rbind, list(
  output("Whole stock", 0.66, 0.60, 0.73, output_reference,
    "Posterior median and 95% credible interval for female SSB relative to unfished levels; reported as current ca. 2025."),
  output("North", 0.83, 0.76, 0.91, output_reference,
    "Posterior median and 95% credible interval for northern-area female SSB relative to unfished levels."),
  output("South", 0.36, 0.32, 0.40, output_reference,
    "Posterior median and 95% credible interval for southern-area female SSB relative to unfished levels.")
))

stopifnot(nrow(inputs) == 84L,
  all(inputs$type == "catch"),
  all(inputs$measure == "catch_biomass"),
  all(inputs$basis == "biomass"),
  all(inputs$year_basis == "model_year"),
  all(outputs$measure == "SSB_ratio_to_B0"))

append_rows("database/stocks.csv", stock)
append_rows("database/assessments.csv", assessment)
append_rows("database/assumptions.csv", assumptions)
append_rows("database/inputs.csv", inputs)
append_rows("database/outputs.csv", outputs)

candidates$import_status[candidate_rows] <- "partial"
candidates$decision_reason[candidate_rows] <- paste(
  "A partial canonical record was imported from the current 2025 assessment.",
  "The report supplies fleet-specific catch biomass and terminal female SSB/B0 estimates.",
  "Age-input eligibility remains unresolved because conditional age-at-length arrays",
  "and tag data are not publicly available as run-matched numeric inputs."
)
candidates$notes[candidate_rows] <- paste(
  "Partial source import now includes all reported Table 2 fleet catches and terminal",
  "female SSB/B0 summaries for the whole stock, North, and South. No age compositions,",
  "length-frequency arrays, tag arrays, or annual population time series were imported.",
  "See source_reviews/afma_mitf_2025.md."
)
candidate_path <- "discovery/candidates.csv"
candidate_lines <- readLines(candidate_path, warn = FALSE)
candidate_line_index <- which(startsWith(candidate_lines, paste0('"', candidate_id, '",')))
if (length(candidate_line_index) != 1L) {
  stop("The AFMA candidate row could not be located uniquely.")
}
candidate_tmp <- tempfile()
write.table(candidates[candidate_rows, , drop = FALSE], candidate_tmp,
  sep = ",", row.names = FALSE, col.names = FALSE, quote = TRUE,
  qmethod = "double", na = "")
candidate_lines[candidate_line_index] <- readLines(candidate_tmp, warn = FALSE)
unlink(candidate_tmp)
writeLines(candidate_lines, candidate_path, useBytes = TRUE)

source("scripts/database/195_summarize_discovery.R", local = TRUE)
source("scripts/database/196_summarize_inventory_units.R", local = TRUE)

cat("Imported partial AFMA MITF 2025 catch inputs, assumptions, and stock-status outputs.\n")
cat("Age-composition, length-frequency, and tag arrays remain unavailable in public sources.\n")
