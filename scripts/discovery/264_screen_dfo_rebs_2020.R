root <- "."
path <- file.path(root, 'discovery', 'candidates.csv')
x <- read.csv(path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'), stringsAsFactors = FALSE)

id <- 'DFO:Pacific:Rougheye Rockfish'
source_review <- file.path(root, 'discovery', 'source_reviews',
  'dfo_rougheye_blackspotted_bc_2020.md')
i <- match(id, x$candidate_id)
if (is.na(i)) stop('Expected DFO Rougheye Rockfish inventory row is missing.', call. = FALSE)
species <- c('Sebastes aleutianus', 'Sebastes melanostictus')
if (any(stocks$scientific_name %in% species)) {
  stop('A canonical REBS stock is present; reconcile its assessment boundary before screening.', call. = FALSE)
}

review <- list(
  candidate_unit_id = NA_character_,
  organization = 'DFO',
  official_stock_id = NA_character_,
  scientific_name = paste(species, collapse = '; '),
  stock_name = 'Rougheye/Blackspotted Rockfish complex',
  assessment_area = 'REBS north 5DE; REBS south 3CD5AB',
  inventory_assessment_year = '2020',
  match_status = 'ambiguous',
  screening_status = 'screened',
  eligibility = 'unresolved',
  import_status = 'not_started',
  catch_age_evidence = paste(
    'The annual two-fishery catch-at-age model uses reconstructed catch histories and',
    'weighted age proportions, not direct annual catch numbers-at-age. The report',
    'documents proportions-at-age for the trawl and Other fisheries, but their exact',
    'vectors were not recovered as machine-readable data. Catch-at-age would require',
    'catch, age proportions and weight-at-age.'
  ),
  survey_age_evidence = paste(
    'The assessment uses survey abundance indices and survey age proportions: WCHG for',
    'REBS north, and QCS, WCVI and NMFS Triennial series for REBS south. The report gives',
    'age-sample years and figures, but exact age-proportion vectors and machine-readable',
    'survey index inputs were not recovered.'
  ),
  weights_evidence = paste(
    'The report documents biological samples, sex-specific growth and allometry used to',
    'derive weight-at-age. Exact run-matched age-specific input vectors were not recovered.'
  ),
  maturity_evidence = paste(
    'Female maturity-at-age is derived from biological samples and is described in Appendix D.',
    'Exact numeric vectors were not recovered as machine-readable source data.'
  ),
  mortality_evidence = paste(
    'The composite base cases use fixed natural-mortality values 0.035, 0.045 and 0.055;',
    'the assessment carries this uncertainty across component runs.'
  ),
  timing_evidence = paste(
    'The model is annual and uses several synoptic and historical survey series. Survey-specific',
    ''
  ),
  output_evidence = paste(
    'The report contains MPD/MCMC stock-status results and population/age-structure figures',
    'for both units, but no machine-readable run object or complete numeric annual age surfaces',
    'were located. The published report includes aggregate spawning-biomass and recruitment',
    'results, but plotted trajectories are not imported as numeric annual outputs.'
  ),
  detailed_source_url = paste(
    'https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41072091.pdf;',
    'https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/40953488.pdf;',
    'https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41033073.pdf'
  ),
  review_date = '2026-10-29',
  decision_reason = paste(
    'The detailed 2020 DFO assessment defines two current BC units (5DE and 3CD5AB),',
    'while the source inventory row does not distinguish them or provide an official stock ID.',
    'The age-structured inputs and outputs are documented, but exact age-proportion vectors and',
    'complete numeric annual outputs were not recovered from the public files. Keep identity',
    'ambiguous and import eligibility unresolved pending source data or run files.'
  ),
  notes = paste(
    'One generic DFO survey row maps to two assessment units: REBS north 5DE (predominantly',
    'Blackspotted) and REBS south 3CD5AB (predominantly Rougheye). No official stock IDs were',
    'located; leave candidate_unit_id blank. This Canadian assessment is geographically',
    'distinct from NOAA Stock SMART 14516, the U.S. West Coast complex. The peer-review record',
    'documents corrections to seamount age inclusion and weak south-stock MCMC diagnostics.',
    'See ignored source_cache/discovery_dfo_rebs_2020/sources.csv.'
  )
)

if (x$screening_status[i] == 'screened') {
  for (column in names(review)) {
    if (!identical(as.character(x[[column]][i]), as.character(review[[column]]))) {
      stop(paste('Previously screened DFO REBS field changed:', column), call. = FALSE)
    }
  }
  if (!file.exists(source_review)) stop('DFO REBS source review is missing.', call. = FALSE)
  cat('DFO Rougheye/Blackspotted Rockfish already screened; no canonical data imported.\n')
  quit(save = 'no', status = 0L)
}

if (x$match_status[i] != 'unreviewed' || x$screening_status[i] != 'not_started') {
  stop('Preserve the existing DFO inventory review state before screening REBS.', call. = FALSE)
}

for (column in names(review)) x[[column]][i] <- review[[column]]
lines <- readLines(path, warn = FALSE, encoding = 'UTF-8')
if (length(lines) != nrow(x) + 1L) stop('Multiline CSV rows require a safe update method.', call. = FALSE)
tmp <- tempfile(fileext = '.csv')
write.csv(x[i, , drop = FALSE], tmp, row.names = FALSE, na = '')
lines[i + 1L] <- readLines(tmp, warn = FALSE, encoding = 'UTF-8')[-1L]
unlink(tmp)
writeLines(lines, path, useBytes = TRUE)
cat('Screened DFO Rougheye/Blackspotted Rockfish; no canonical data imported.\n')
