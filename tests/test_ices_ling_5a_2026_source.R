root <- "."
cache <- file.path(root, "source_cache", "discovery_ices_ling_5a_2026")
assessment_id <- "ices_ling_5a_2026"

source_manifest <- read.csv(file.path(cache, "sources.csv"), stringsAsFactors = FALSE)
provenance_manifest <- read.csv(
  file.path(root, "provenance", "discovery_ices_ling_5a_2026", "sources.csv"),
  stringsAsFactors = FALSE
)
importer <- file.path(root, "scripts", "database", "660_import_ices_ling_5a_2026.R")
old_dry_run <- Sys.getenv("TAM_SOURCE_DRY_RUN", unset = NA_character_)
Sys.setenv(TAM_SOURCE_DRY_RUN = "1")
import_env <- new.env(parent = globalenv())
sys.source(importer, envir = import_env)
if (is.na(old_dry_run)) {
  Sys.unsetenv("TAM_SOURCE_DRY_RUN")
} else {
  Sys.setenv(TAM_SOURCE_DRY_RUN = old_dry_run)
}

stocks <- read.csv(file.path(root, "database", "stocks.csv"),
  stringsAsFactors = FALSE, na.strings = c("", "NA")
)
assessments <- read.csv(file.path(root, "database", "assessments.csv"),
  stringsAsFactors = FALSE, na.strings = c("", "NA")
)
candidate <- read.csv(file.path(root, "discovery", "candidates.csv"),
  stringsAsFactors = FALSE, na.strings = c("", "NA")
)
candidate <- candidate[candidate$candidate_id == "ICES:lin.27.5a", , drop = FALSE]
inventory <- read.csv(file.path(root, "discovery", "inventory_units.csv"),
  stringsAsFactors = FALSE, na.strings = c("", "NA")
)
inventory <- inventory[inventory$unit_key == "candidate:ices_ling_5a", , drop = FALSE]
review <- paste(readLines(
  file.path(root, "discovery", "source_reviews", "ices_ling_5a_2026.md"),
  warn = FALSE
), collapse = "\n")

stopifnot(
  nrow(source_manifest) == 5L,
  identical(source_manifest$file, provenance_manifest$file),
  identical(tolower(source_manifest$sha256), tolower(provenance_manifest$sha256)),
  all(file.exists(file.path(cache, source_manifest$file))),
  nrow(import_env$stock) == 1L,
  import_env$stock$stock_id == "ices_ling_5a",
  import_env$stock$authority_stock_id == "lin.27.5a",
  nrow(import_env$assessment) == 1L,
  import_env$assessment$assessment_year == 2026L,
  import_env$assessment$terminal_year == 2025L,
  import_env$assessment$estimate_terminal_year == 2026L,
  nrow(import_env$inputs) == 152L,
  nrow(import_env$assumptions) == 7L,
  nrow(import_env$outputs) == 191L,
  all(import_env$inputs$source_type %in% c(
    "official_machine_readable", "official_document"
  )),
  all(import_env$outputs$source_type == "official_machine_readable"),
  all(import_env$inputs$value >= 0),
  all(import_env$outputs$lwr <= import_env$outputs$value),
  all(import_env$outputs$value <= import_env$outputs$upr),
  all(import_env$inputs$year[import_env$inputs$type == "catch"] %in% 1979:2025),
  identical(
    sort(unique(import_env$inputs$year[import_env$inputs$type == "catch"])),
    1979:2025
  ),
  all(import_env$inputs$value[
    import_env$inputs$measure == "natural_mortality_at_age"
  ] == 0.15),
  identical(
    sort(import_env$inputs$age[
      import_env$inputs$measure == "natural_mortality_at_age"
    ]),
    2:12
  ),
  all(is.na(import_env$inputs$year[
    import_env$inputs$measure == "natural_mortality_at_age"
  ])),
  all(import_env$outputs$year[import_env$outputs$measure == "Fbar"] == 1979:2025),
  sum(import_env$outputs$year == 2026L) == 3L,
  all(import_env$outputs$scenario[import_env$outputs$year == 2026L] ==
    "2026 advice projection"),
  import_env$inputs$value[
    import_env$inputs$measure == "catch_biomass" & import_env$inputs$year == 2025L
  ] == 9791,
  import_env$outputs$value[
    import_env$outputs$measure == "SSB" & import_env$outputs$year == 2025L
  ] == 35787,
  import_env$source_table$catches[import_env$source_table$year == 2025L] == 9791,
  import_env$source_table$ssb[import_env$source_table$year == 2025L] == 35787,
  nrow(candidate) == 1L,
  candidate$import_status == "partial",
  nrow(inventory) == 1L,
  inventory$import_status == "partial",
  assessments$assessment_id[assessments$assessment_id == assessment_id] == assessment_id,
  assessments$inputs_status[assessments$assessment_id == assessment_id] == "partial",
  assessments$outputs_status[assessments$assessment_id == assessment_id] == "complete",
  grepl("MFRI supplementary tables page provides numeric age series", review, fixed = TRUE),
  grepl("selected 2026 aggregate values are advice projections", review, fixed = TRUE),
  sum(stocks$stock_id == "ices_ling_5a") == 1L,
  sum(assessments$assessment_id == assessment_id) == 1L
)
cat("Icelandic ling 5.a source import checks passed.\n")
