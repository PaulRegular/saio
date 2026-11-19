source("data-raw/scripts/shared/source_manifest_io.R", local = TRUE)

candidate_id <- "DFO:Pacific:Silvergray Rockfish - Coastwide"
candidate_unit_id <- "dfo_silvergray_rockfish_coastwide"
review_date <- "2026-11-14"

candidate <- data.frame(
  candidate_id = candidate_id,
  candidate_unit_id = candidate_unit_id,
  organization = "DFO",
  official_stock_id = "",
  scientific_name = "Sebastes brevispinis",
  stock_name = "Silvergray Rockfish - British Columbia coastwide",
  assessment_area = "British Columbia coastwide, Groundfish Management Areas 3CD5ABCDE, excluding inside waters (4B)",
  inventory_assessment_year = "2025",
  inventory_url = "https://www.isdm-gdsi.gc.ca/csas-sccs/applications/events-evenements/result-eng.asp?year=2026",
  retrieved_on = review_date,
  matched_stock_id = "",
  match_status = "new",
  screening_status = "screened",
  eligibility = "unresolved",
  import_status = "not_started",
  catch_age_evidence = paste(
    "DFO Science Advisory Report 2026/038 Table 3 reports annual catches in tonnes",
    "for 1996-2025 by three subareas, but not catch-at-age. The report says the full",
    "catch history is in a research document in preparation. It describes age",
    "frequencies for three commercial fisheries and three surveys, but publishes no",
    "numeric age-composition arrays or complete age-sample coverage."
  ),
  survey_age_evidence = paste(
    "The assessment uses four synoptic survey indices, two historical survey indices,",
    "and three subarea CPUE series. Three surveys also contribute age frequencies, but",
    "the report gives no numerical age-specific abundance-index series."
  ),
  weights_evidence = paste(
    "Male and female growth and length-weight relationships are estimated outside the",
    "model. No numerical stock-weight-at-age or catch-weight-at-age array is published."
  ),
  maturity_evidence = paste(
    "Female maturity is estimated outside the model; the current numerical maturity",
    "schedule is not published in the advisory report."
  ),
  mortality_evidence = paste(
    "Natural mortality is estimated separately for females and males. Table 1 reports",
    "posterior summaries, not a run input file: female median 0.0639 (5th-95th percentiles",
    "0.0496-0.0801) and male median 0.0566 (0.0427-0.0720)."
  ),
  timing_evidence = paste(
    "The assessment is annual and calendar-year based. The report does not provide a",
    "fraction-of-year timing for individual surveys or CPUE series."
  ),
  output_evidence = paste(
    "The report gives posterior quantiles for B0, beginning-of-2026 female spawning",
    "biomass, relative biomass and exploitation-rate quantities, plus M by sex. It",
    "presents annual stock-status and recruitment trends as figures, but no numeric",
    "annual N-at-age or F-at-age surfaces."
  ),
  detailed_source_url = paste(
    "https://publications.gc.ca/collections/collection_2026/mpo-dfo/fs70-6/Fs70-6-2026-038-eng.pdf",
    "https://publications.gc.ca/site/eng/9.964191/publication.html",
    "https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/365822.pdf",
    sep = "; "
  ),
  review_date = review_date,
  decision_reason = paste(
    "The latest official assessment is the 2025 full coastwide assessment, with advice",
    "for the population at the beginning of 2026. The English advisory report verifies",
    "some current-run catches and summary outputs, so this current unit remains the",
    "primary candidate. Age-input eligibility is unresolved because numerical age",
    "compositions, survey series, age-specific biology, and age-specific population",
    "outputs are not available in the reviewed sources. Do not substitute the 2013",
    "assessment or its 2016 research document for the current run."
  ),
  notes = paste(
    "Source-led candidate; no canonical stock or assessment rows have been created.",
    "Model is two-sex Stock Synthesis 3, ages 0-60 with age 60 as the accumulator,",
    "reconstructing 1935-2025 from an unfished-equilibrium start. The 2025 catch was",
    "assumed equal to 2024 catch; DFO reports realized catch was 12% lower."
  ),
  stringsAsFactors = FALSE,
  check.names = FALSE
)

manifest <- data.frame(
  file = "silvergray_publication_record.html",
  url = "https://publications.gc.ca/site/eng/9.964191/publication.html",
  revision = "DFO publication catalogue record for Science Advisory Report 2026/038, English edition",
  retrieved_on = review_date,
  sha256 = "5AA1034175AD31645BD1FD123D7B963CABC278C686EEF1CC2D4DDF5FD1B72B8A",
  bytes = "92009",
  notes = "",
  stringsAsFactors = FALSE
)

read_table <- function(path) {
  read.csv(path, stringsAsFactors = FALSE, colClasses = "character",
    na.strings = c("", "NA"), check.names = FALSE)
}

register <- read_table("database/candidates.csv")
stocks <- read_table("database/stocks.csv")
stopifnot(
  identical(names(candidate), names(register)),
  !candidate_id %in% register$candidate_id,
  !candidate_unit_id %in% register$candidate_unit_id,
  !any(tolower(stocks$common_name) == "silvergray rockfish", na.rm = TRUE),
  identical(toupper(as.character(tools::sha256sum(
    file.path("source_cache/dfo_silvergray_rockfish_coastwide/source_material", manifest$file)
  ))), manifest$sha256)
)

if ("--write" %in% commandArgs(trailingOnly = TRUE)) {
  manifest_path <- "data-raw/provenance/dfo_silvergray_rockfish_coastwide/sources.csv"
  dir.create(dirname(manifest_path), recursive = TRUE, showWarnings = FALSE)
  write.table(candidate, "database/candidates.csv", sep = ",", row.names = FALSE,
    col.names = FALSE, append = TRUE, quote = TRUE, qmethod = "double", na = "")
  write_source_manifest(manifest, manifest_path,
    row.names = FALSE, na = "")
  source("data-raw/scripts/shared/195_summarize_candidates.R", local = TRUE)
  source("data-raw/scripts/shared/196_summarize_inventory_units.R", local = TRUE)
  cat("Registered Silvergray Rockfish as a screened, unresolved source candidate.\n")
}