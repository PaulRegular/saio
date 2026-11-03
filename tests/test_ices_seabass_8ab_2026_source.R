root <- "."
script <- file.path(root, "scripts", "database", "557_import_ices_seabass_8ab_2026.R")
old_dry_run <- Sys.getenv("TAM_SOURCE_DRY_RUN", unset = NA_character_)
Sys.setenv(TAM_SOURCE_DRY_RUN = "1")
import <- new.env(parent = globalenv())
sys.source(script, envir = import)
if (is.na(old_dry_run)) Sys.unsetenv("TAM_SOURCE_DRY_RUN") else
  Sys.setenv(TAM_SOURCE_DRY_RUN = old_dry_run)
register <- read.csv(file.path(root, "discovery", "candidates.csv"), stringsAsFactors = FALSE)
selected <- read.csv(file.path(root, "discovery", "selected_batch_01_2026.csv"), stringsAsFactors = FALSE)
assessments <- read.csv(file.path(root, "database", "assessments.csv"), stringsAsFactors = FALSE)
registered <- register[register$candidate_id == "ICES:bss.27.8ab", , drop = FALSE]
selected_row <- selected[selected$candidate_id == "ICES:bss.27.8ab", , drop = FALSE]
assessment_row <- assessments[assessments$assessment_id == "ices_seabass_8ab_2026", , drop = FALSE]

stopifnot(
  all(import$inputs$assessment_id == "ices_seabass_8ab_2026"),
  all(import$outputs$assessment_id == "ices_seabass_8ab_2026"),
  all(import$assumptions$assessment_id == "ices_seabass_8ab_2026"),
  nrow(import$inputs) == 130L,
  identical(sort(unique(as.integer(import$inputs$year[import$inputs$type == "catch"]))), 1985:2025),
  all(import$inputs$unit[import$inputs$type == "catch"] == "tonnes"),
  all(import$inputs$type[import$inputs$measure != "natural_mortality_at_age"] == "catch"),
  sum(import$inputs$measure == "total_biomass") == 41L,
  sum(import$inputs$measure == "landings_biomass") == 41L,
  sum(import$inputs$measure == "discard_biomass") == 41L,
  sum(import$inputs$measure == "natural_mortality_at_age") == 7L,
  identical(as.integer(import$inputs$age[import$inputs$measure == "natural_mortality_at_age"]), 0:6),
  identical(as.numeric(import$inputs$value[import$inputs$measure == "natural_mortality_at_age"]),
    c(0.840918, 0.463849, 0.365109, 0.306347, 0.267492, 0.24, 0.24)),
  nrow(import$outputs) == 125L,
  sum(import$outputs$measure == "SSB") == 42L,
  sum(import$outputs$measure == "recruitment") == 42L,
  sum(import$outputs$measure == "Fbar") == 41L,
  import$fish$ssb[import$fish$year == 2025L] == 26792,
  import$fish$recruitment[import$fish$year == 2025L] == 38600,
  import$fish$fbar[import$fish$year == 2025L] == 0.110,
  import$fish$ssb[import$fish$year == 2026L] == 28227,
  is.na(import$fish$fbar[import$fish$year == 2026L]),
  all(import$outputs$se == ""),
  all(import$outputs$source_type == "official_machine_readable"),
  all(import$outputs$age_group[import$outputs$measure == "Fbar"] == "4-15"),
  import$assessment$terminal_year == "2025",
  import$assessment$estimate_terminal_year == "2026",
  import$assessment$inputs_status == "partial",
  import$assessment$outputs_status == "partial",
  nrow(registered) == 1L,
  registered$import_status == "partial",
  nrow(selected_row) == 1L,
  selected_row$curation_status == "partial_source_import",
  nrow(assessment_row) == 1L,
  assessment_row$terminal_year == 2025L,
  assessment_row$estimate_terminal_year == 2026L,
  assessment_row$inputs_status == "partial",
  assessment_row$outputs_status == "partial"
)

cat("ICES 2026 Bay of Biscay seabass source checks passed.\n")
