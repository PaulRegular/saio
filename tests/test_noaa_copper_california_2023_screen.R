root <- "."
old_dry_run <- Sys.getenv("TAM_SOURCE_DRY_RUN", unset = NA_character_)
Sys.setenv(TAM_SOURCE_DRY_RUN = "1")
screen <- new.env(parent = globalenv())
source(file.path(root,
  "scripts/database/476_screen_noaa_copper_california_2023.R"), local = screen)
if (is.na(old_dry_run)) Sys.unsetenv("TAM_SOURCE_DRY_RUN") else
  Sys.setenv(TAM_SOURCE_DRY_RUN = old_dry_run)

candidate_ids <- c("NOAA:15332", "NOAA:15333")
assessment_id <- "noaa_copper_rockfish_california_2023"
stock_id <- "noaa_copper_rockfish_california"
candidates <- screen$candidates[match(candidate_ids, screen$candidates$candidate_id), ]
assessment <- screen$assessments[screen$assessments$assessment_id == assessment_id, ]
inputs <- screen$inputs[screen$inputs$assessment_id == assessment_id, ]
outputs <- screen$outputs[screen$outputs$assessment_id == assessment_id, ]
review <- paste(readLines(file.path(root,
  "discovery/source_reviews/noaa_copper_rockfish_california_2023.md"),
  warn = FALSE), collapse = " ")

stopifnot(
  screen$north$age_rows == 489L, screen$north$conditional == 450L,
  screen$north$marginal == 39L,
  screen$south$age_rows == 771L, screen$south$conditional == 747L,
  screen$south$marginal == 24L,
  all(candidates$match_status == "new"),
  all(candidates$screening_status == "screened"),
  all(candidates$eligibility == "eligible"),
  all(candidates$import_status == "partial"),
  all(candidates$matched_stock_id == stock_id),
  nrow(screen$stocks[screen$stocks$stock_id == stock_id, ]) == 1L,
  nrow(assessment) == 1L, assessment$terminal_year == 2022L,
  assessment$estimate_terminal_year == 2023L,
  sum(inputs$type == "catch" & inputs$measure == "catch_biomass") == 653L,
  sum(inputs$measure == "relative_biomass_index") == 153L,
  sum(inputs$measure == "log_index_sd") == 153L,
  sum(inputs$measure == "conditional_frequency_at_age") > 0L,
  sum(inputs$measure == "frequency_at_age") > 0L,
  sum(inputs$measure == "frequency_at_length") > 0L,
  !any(inputs$measure %in% c("catch_numbers", "catch_numbers_at_age")),
  sum(outputs$measure == "numbers_at_age") == 21828L,
  sum(outputs$measure == "biomass_at_age") == 21828L,
  sum(outputs$measure == "fishing_mortality_at_age") == 87312L,
  sum(outputs$measure == "catch_numbers_at_age") == 87312L,
  sum(outputs$measure == "total_abundance") == 214L,
  sum(outputs$measure == "recruitment") == 214L,
  sum(outputs$measure == "spawning_output") == 216L,
  all(unique(outputs$region) %in% c("North of Point Conception", "South of Point Conception")),
  grepl("not an observed catch-at-age input", review, fixed = TRUE),
  grepl("Lbin_method=3", review, fixed = TRUE),
  grepl("billions of eggs", review, fixed = TRUE)
)

n_age <- outputs[outputs$measure == "numbers_at_age" &
  outputs$region == "North of Point Conception" & outputs$year == 2022, ]
total <- outputs[outputs$measure == "total_abundance" &
  outputs$region == "North of Point Conception" & outputs$year == 2022, ]
stopifnot(nrow(total) == 1L, abs(sum(n_age$value) - total$value) < 1e-8)

ssb_2023 <- outputs[outputs$measure == "spawning_output" & outputs$year == 2023, ]
stopifnot(
  nrow(ssb_2023) == 2L,
  isTRUE(all.equal(ssb_2023$value[ssb_2023$region == "North of Point Conception"], 208.74)),
  isTRUE(all.equal(ssb_2023$value[ssb_2023$region == "South of Point Conception"], 32.06)),
  isTRUE(all.equal(ssb_2023$lwr[ssb_2023$region == "North of Point Conception"], 77.33)),
  isTRUE(all.equal(ssb_2023$upr[ssb_2023$region == "South of Point Conception"], 51.42))
)

cat("NOAA California copper source import and output checks passed.\n")
