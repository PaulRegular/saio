source("R/read_database.R")

database <- read_database()
record <- read_assessment("afma_sessf_eastern_school_whiting_2024", database)
outputs <- record$outputs

ssb0 <- subset(outputs, measure == "unfished_spawning_biomass" &
  scenario == "2024 combined Tier 1 base case")
ssb2025 <- subset(outputs, measure == "SSB" & year == 2025L &
  scenario == "2024 combined Tier 1 base case")
ratio <- subset(outputs, measure == "SSB_ratio_to_B0" & year == 2025L &
  scenario == "2024 combined Tier 1 base case")

stopifnot(
  record$assessment$assessment_year == 2024L,
  all(record$assessment[c("assumptions_status", "inputs_status", "outputs_status")] == "partial"),
  nrow(record$inputs) == 0L,
  nrow(outputs) == 111L,
  nrow(ssb0) == 1L,
  ssb0$value == 13207,
  is.na(ssb0$year),
  nrow(ssb2025) == 1L,
  ssb2025$value == 7110,
  ssb2025$unit == "tonnes",
  ssb2025$scenario == "2024 combined Tier 1 base case",
  nrow(ratio) == 1L,
  ratio$value == 54,
  ratio$unit == "percent",
  all(is.na(c(ssb0$se, ssb0$lwr, ssb0$upr, ssb2025$se, ssb2025$lwr, ssb2025$upr))),
  all(grepl("SERAG Meeting 2, November 2024", c(ssb0$source_reference, ssb2025$source_reference)))
)

candidate <- read.csv("discovery/candidates.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
candidate <- subset(candidate, candidate_id == "AFMA:SESSF_Eastern_School_Whiting")
manifest <- read.csv("provenance/afma_school_whiting_2024/manifest.csv",
  stringsAsFactors = FALSE)
minutes <- subset(manifest, grepl("serag_meeting_2_2024_minutes.pdf", local_file, fixed = TRUE))
minutes_path <- file.path("source_cache", minutes$local_file)
review <- paste(readLines("source_reviews/afma_school_whiting_sessf.md", warn = FALSE), collapse = " ")

stopifnot(
  nrow(candidate) == 1L,
  grepl("13,207 t", candidate$output_evidence, fixed = TRUE),
  grepl("7,110 t", candidate$output_evidence, fixed = TRUE),
  nrow(minutes) == 1L,
  file.exists(minutes_path),
  toupper(unname(tools::sha256sum(minutes_path))) == minutes$sha256,
  grepl("13,207 tonnes", review, fixed = TRUE),
  grepl("7,110 tonnes", review, fixed = TRUE)
)

cat("AFMA eastern school whiting source outputs and provenance passed.\n")
