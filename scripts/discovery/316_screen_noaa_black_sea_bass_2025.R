root <- "."
candidate_path <- file.path(root, 'discovery', 'candidates.csv')
cache <- file.path(root, 'source_cache', 'discovery_noaa_black_sea_bass_2025')
candidates <- read.csv(candidate_path, stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))

ids <- c('NOAA:10310', 'NOAA:10311')
if (any(grepl('Centropristis striata|black sea bass',
  paste(stocks$scientific_name, stocks$common_name), ignore.case = TRUE))) {
  stop('A canonical black sea bass record exists; review the match before screening.',
    call. = FALSE)
}

reviews <- list(
  'NOAA:10310' = list(
    candidate_unit_id = 'noaa_south_atlantic_black_sea_bass',
    official_stock_id = '10310',
    scientific_name = 'Centropristis striata',
    stock_name = 'Black sea bass - Southern Atlantic Coast',
    assessment_area = 'South Atlantic U.S. waters, Cape Hatteras to Florida',
    inventory_assessment_year = 2025L,
    match_status = 'new',
    screening_status = 'screened',
    eligibility = 'unresolved',
    import_status = 'not_started',
    catch_age_evidence = paste(
      'The SEDAR 76 Update used five fleets with annual landings by weight, discard',
      'mortalities by number, and fleet age/length compositions. Age compositions are',
      'not available in every year; length compositions fill some gaps. The report',
      'does not provide the full numerical annual composition arrays, and a run-matched',
      'machine-readable data package was not verified.'
    ),
    survey_age_evidence = paste(
      'The update fitted two fishery-independent and two fishery-dependent abundance',
      'indices. It includes survey age compositions in some years, but the complete',
      'numerical age-composition inputs were not located.'
    ),
    weights_evidence = paste(
      'The model uses length-at-age and weight-at-age derived from a von Bertalanffy',
      'growth curve and length-weight relationship; life-history values are tabulated.'
    ),
    maturity_evidence = paste(
      'Female maturity is age-based and male transition is age-based; the update uses',
      'age-specific mature weight for spawning biomass.'
    ),
    mortality_evidence = paste(
      'Natural mortality is fixed over time and declines with age using a Lorenzen',
      'relationship rescaled to a constant fully selected M of 0.375 per year.'
    ),
    timing_evidence = paste(
      'The model uses annual time steps and annual fishery and survey series. A fractional',
      'within-year timing for the abundance indices was not verified.'
    ),
    output_evidence = paste(
      'The 2025 update tabulates estimated N-at-age and total F-at-age, as well as',
      'biomass, recruitment, and estimated landings-at-age. M is an assumed input, not',
      'an estimated age-specific output.'
    ),
    detailed_source_url = paste(
      'https://sedarweb.org/assessments/sedar-76/;',
      'https://sedarweb.org/documents/sedar-76-bsb-update/;',
      'https://www.govinfo.gov/content/pkg/FR-2026-09-22/pdf/2026-19341.pdf;',
      'https://sedarweb.org/assessments/sedar-108-south-atlantic-black-sea-bass/'
    ),
    decision_reason = paste(
      'The latest public detailed assessment is the 2025 SEDAR 76 Update, based on data',
      'through 2023. It documents age-structured inputs and age-specific outputs, but',
      'the full run-matched numerical composition inputs were not verified. A revision',
      'was scheduled for late 2026 and SEDAR 108 is underway; keep eligibility unresolved',
      'until the current run and complete inputs are pinned.'
    ),
    notes = paste(
      'The Council/SSC used the 2025 update for ABC advice, while the September 2026',
      'proposed rule describes a further revision in progress and a pending formal status',
      'determination. The 2025 report provides N-at-age, F-at-age, and SSB tables, but',
      'does not expose complete annual age-composition matrices in machine-readable form.',
      'See discovery/source_reviews/noaa_black_sea_bass_south_atlantic_2025.md.'
    )
  ),
  'NOAA:10311' = list(
    candidate_unit_id = 'noaa_mid_atlantic_black_sea_bass',
    official_stock_id = '10311',
    scientific_name = 'Centropristis striata',
    stock_name = 'Black sea bass - Mid-Atlantic Coast',
    assessment_area = 'U.S. Atlantic waters north of Cape Hatteras; two modeled regions divided near Hudson Canyon',
    inventory_assessment_year = 2025L,
    match_status = 'new',
    screening_status = 'screened',
    eligibility = 'unresolved',
    import_status = 'not_started',
    catch_age_evidence = paste(
      'The accepted 2025 management-track assessment updates commercial and recreational',
      'catch data. The multi-WHAM framework uses aggregate removals and age-composition',
      'information, but the complete 2025 run-matched catch and age-composition matrices',
      'were not located in the public report and peer-review materials reviewed.'
    ),
    survey_age_evidence = paste(
      'The 2025 update includes state and federal survey indices and a VAST combined index.',
      'The assessment framework uses numbers-at-age states; complete survey age inputs and',
      'the run-specific age-length-key files were not verified.'
    ),
    weights_evidence = paste(
      'The 2025 assessment report summary identifies age-specific weights as model inputs,',
      'but the final run-matched numerical matrices were not recovered.'
    ),
    maturity_evidence = paste(
      'The 2025 assessment report summary identifies age-specific maturity as a model input,',
      'but the final run-matched numerical schedules were not recovered.'
    ),
    mortality_evidence = paste(
      'The management-track update retains age-structured population dynamics and age-specific',
      'natural mortality for projections; the complete run-specific mortality specification',
      'was not verified from the public summary materials.'
    ),
    timing_evidence = paste(
      'The model combines spatially and seasonally stratified survey information into regional',
      'indices; the fractional within-year timing used for each index was not verified.'
    ),
    output_evidence = paste(
      'The 2025 accepted assessment reports SSB, fully selected F, and recruitment through',
      '2024. Peer review discusses random-effects numbers-at-age, but the complete numerical',
      'N-at-age and F-at-age output series were not located.'
    ),
    detailed_source_url = paste(
      'https://www.fisheries.noaa.gov/species/black-sea-bass/resources;',
      'https://www.fisheries.noaa.gov/s3/2025-07/2025-June-Management-Track-Peer-Review-Panel-Report-508.pdf;',
      'https://asmfc.org/wp-content/uploads/2025/08/2025_BSB_MgmtTrackAssmtReport.pdf;',
      'https://www.fisheries.noaa.gov/s3/2024-01/Panel-Summary-Report-Black-Sea-Bass-RT-Peer-Review-Final-1-4-24.pdf'
    ),
    decision_reason = paste(
      'The 2025 management-track assessment was peer reviewed and accepted as best scientific',
      'information for the Mid-Atlantic stock, with data through 2024. Public summaries confirm',
      'an age-structured multi-WHAM model and age-specific biology, but do not provide sufficient',
      'run-matched numerical inputs or full age-specific outputs to verify translation readiness.'
    ),
    notes = paste(
      'The 2025 panel report states the assessment updates the 2024 multi-WHAM model through',
      '2024 and was accepted. The detailed assessment report link cited by the draft points to',
      'NOAA SASINF; the final run package and its data files remain to be recovered. The model',
      'contains north/south subregions divided near Hudson Canyon; this is one Mid-Atlantic',
      'management stock, not two inventory units. See discovery/source_reviews/',
      'noaa_black_sea_bass_mid_atlantic_2025.md.'
    )
  )
)

for (id in ids) {
  i <- which(candidates$candidate_id == id)
  if (length(i) != 1L) stop('Expected one inventory row: ', id, call. = FALSE)
  review <- reviews[[id]]
  already_applied <- all(vapply(names(review), function(column) {
    identical(as.character(candidates[[column]][i]), as.character(review[[column]]))
  }, logical(1L)))
  if (!already_applied) {
    if (candidates$screening_status[i] != 'not_started' ||
        candidates$match_status[i] != 'unreviewed') {
      stop('Inventory row has a conflicting prior review: ', id, call. = FALSE)
    }
    for (column in names(review)) candidates[[column]][i] <- review[[column]]
  }
}

lines <- readLines(candidate_path, warn = FALSE, encoding = 'UTF-8')
if (length(lines) != nrow(candidates) + 1L) {
  stop('Candidate CSV contains multiline records; refusing unsafe update.', call. = FALSE)
}
for (id in ids) {
  i <- match(id, candidates$candidate_id)
  row <- candidates[i, , drop = FALSE]
  row[] <- lapply(row, as.character)
  tmp <- tempfile(fileext = '.csv')
  write.csv(row, tmp, row.names = FALSE, na = '')
  lines[i + 1L] <- readLines(tmp, warn = FALSE, encoding = 'UTF-8')[-1L]
  unlink(tmp)
}
writeLines(lines, candidate_path, useBytes = TRUE)

files <- c(
  'sedar76_update_south_atlantic_2025.pdf',
  'noaa_management_track_peer_review_2025.pdf',
  'black_sea_bass_management_track_report_2025_draft.pdf',
  'noaa_sa_black_sea_bass_2026_proposed_rule.pdf',
  'noaa_black_sea_bass_2023_research_track_peer_review.pdf'
)
if (!all(file.exists(file.path(cache, files)))) {
  stop('Expected source PDFs are not all cached.', call. = FALSE)
}
prefixes <- vapply(file.path(cache, files), function(path) {
  raw <- readBin(path, 'raw', n = 5L)
  identical(raw, charToRaw('%PDF-'))
}, logical(1L))
if (!all(prefixes)) stop('A cached source does not have a PDF signature.', call. = FALSE)
manifest <- data.frame(
  url = c(
    'https://sedarweb.org/documents/sedar-76-bsb-update/',
    'https://www.fisheries.noaa.gov/s3/2025-07/2025-June-Management-Track-Peer-Review-Panel-Report-508.pdf',
    'https://asmfc.org/wp-content/uploads/2025/08/2025_BSB_MgmtTrackAssmtReport.pdf',
    'https://www.govinfo.gov/content/pkg/FR-2026-09-22/pdf/2026-19341.pdf',
    'https://www.fisheries.noaa.gov/s3/2024-01/Panel-Summary-Report-Black-Sea-Bass-RT-Peer-Review-Final-1-4-24.pdf'
  ),
  bytes = file.info(file.path(cache, files))$size,
  sha256 = toupper(tools::md5sum(file.path(cache, files))),
  status = 'cached',
  retrieved_on = '2026-10-29',
  notes = c(
    'SEDAR 76 Update, March 2025; data through 2023.',
    'NOAA June 2025 management-track peer-review panel report; documents acceptance of the Mid-Atlantic assessment.',
    'Public 2025 assessment summary marked draft for peer review; retained as a summary only, not treated as the final report.',
    'NOAA Federal Register proposed rule, September 2026; describes the pending South Atlantic assessment revision.',
    'NOAA peer-review summary for the 2023 Mid-Atlantic research-track model framework.'
  ),
  file = files,
  stringsAsFactors = FALSE
)
sha256_file <- function(path) {
  if (requireNamespace('digest', quietly = TRUE)) {
    return(digest::digest(file = path, algo = 'sha256'))
  }
  executable <- if (.Platform$OS.type == 'windows') 'certutil' else 'sha256sum'
  output <- system2(executable,
    c(if (.Platform$OS.type == 'windows') '-hashfile' else NULL,
      normalizePath(path, winslash = '/', mustWork = TRUE),
      if (.Platform$OS.type == 'windows') 'SHA256' else NULL),
    stdout = TRUE)
  hash <- grep('^[[:xdigit:]]{64}$', gsub('[[:space:]]', '', output),
    value = TRUE)
  if (length(hash) != 1L) stop('Could not calculate SHA-256 for ', path, call. = FALSE)
  tolower(hash)
}
manifest$sha256 <- vapply(file.path(cache, files), sha256_file, character(1L))
write.csv(manifest, file.path(cache, 'sources.csv'), row.names = FALSE, na = '')
cat('Screened two NOAA black sea bass units; numeric run inputs remain unresolved.\n')
