root <- "."
cache <- file.path(root, 'source_cache', 'discovery_ices_remaining_units_2026')
register_path <- file.path(root, 'discovery', 'candidates.csv')
today <- '2026-11-01'

sha256_file <- function(path) {
  if (requireNamespace('digest', quietly = TRUE))
    return(tolower(digest::digest(file = path, algo = 'sha256')))
  output <- system2('certutil.exe',
    c('-hashfile', shQuote(normalizePath(path, winslash = '\\', mustWork = TRUE)), 'SHA256'),
    stdout = TRUE)
  hash <- tolower(trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$', output,
    value = TRUE)))
  if (length(hash) != 1L) stop('Could not verify a cached source checksum.', call. = FALSE)
  hash
}
manifest <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE)
required <- c('ices_wgnas_2026_report.pdf', 'wgnas_2026_section2_tables.zip',
  'wgnas_2026_neac_tables.zip', 'wgnas_2026_nac_tables.zip', 'wgnas_2026_wgc_tables.zip',
  'imr_anglerfish_advice_2026.pdf', 'ices_wgef_2023_report.pdf', 'ices_wgef_2024_report.pdf')
if (anyDuplicated(manifest$file) || !all(required %in% manifest$file))
  stop('The cached source manifest is incomplete.', call. = FALSE)
for (file in required) {
  i <- match(file, manifest$file)
  path <- file.path(cache, file)
  if (!file.exists(path) || file.info(path)$size != manifest$bytes[i] ||
      sha256_file(path) != manifest$sha256[i])
    stop('Cached source failed provenance validation: ', file, call. = FALSE)
}
find_table <- function(pattern) {
  paths <- list.files(cache, pattern = '\\.csv$', recursive = TRUE, full.names = TRUE)
  hits <- paths[grepl(pattern, basename(paths), ignore.case = TRUE)]
  if (length(hits) != 1L) stop('Expected one table matching ', pattern, call. = FALSE)
  hits
}
catch <- read.csv(find_table('Table 2\\.1\\.1\\.3.*nominal catches by sea age'))
nac <- read.csv(find_table('Table 4\\.3\\.6\\.1.*NAC PFA'))
neac <- read.csv(find_table('Table 3\\.3\\.5\\.1.*PFA 1SW maturing N-NEAC'))
biology <- read.csv(find_table('Table 4\\.2\\.1\\.1.*biological characteristics NAC'))
wgc <- read.csv(find_table('Table 5\\.2\\.1\\.4.*sea age by COO'))
if (!all(c('year', 'number_1sw', 'number_2sw') %in% names(catch)) ||
    !any(catch$year <= 1980, na.rm=TRUE) || !any(catch$year >= 2025, na.rm=TRUE) ||
    !any(suppressWarnings(as.numeric(as.character(nac$year))) >= 2024, na.rm=TRUE) || !any(suppressWarnings(as.numeric(as.character(neac$year))) >= 2025, na.rm=TRUE) ||
    !all(c('Prop_fem_1SW','Prop_fem_MSW','Egg_fem_1SW','Egg_fem_MSW') %in% names(biology)) ||
    !all(c('seaage_1SW_NAM','seaage_2SW_NAM','seaage_1SW_E','seaage_2SW_E') %in% names(wgc)))
  stop('The cached WGNAS tables do not support the recorded age/stage evidence.', call.=FALSE)

candidates <- read.csv(register_path, stringsAsFactors=FALSE, na.strings=c('', 'NA'), check.names=FALSE)
ids <- c('ICES:thr.27.nea','ICES:anf.27.1-2','ICES:sal.neac.all','ICES:sal.nac.all','ICES:sal.wgc.all')
if (anyDuplicated(candidates$candidate_id) || !all(ids %in% candidates$candidate_id))
  stop('An expected ICES candidate is absent or duplicated.', call.=FALSE)
stocks <- read.csv(file.path(root,'database','stocks.csv'), stringsAsFactors=FALSE, na.strings=c('', 'NA'))
if (any(c('sal.nac.all','sal.neac.all','sal.wgc.all','anf.27.1-2','thr.27.nea') %in% stocks$authority_stock_id))
  stop('An exact canonical stock match needs resolution before screening.', call.=FALSE)

salmon <- list(
  candidate_unit_id='ices_wgnas_north_atlantic_salmo_salar', matched_stock_id=NA_character_,
  match_status='new', screening_status='screened', eligibility='eligible', import_status='not_started',
  catch_age_evidence=paste0('WGNAS 2026 tables provide annual catches by sea age, including 1SW and 2SW, for 1980-2025, ',
    'and regional return inputs. Source arrays still need stock-unit and fishery mapping.'),
  survey_age_evidence=paste0('No conventional fishery-independent index-at-age was identified. ',
    'The life-cycle assessment uses smolt abundance, returns, CPUE and fishery information.'),
  maturity_evidence=paste0('The model reports maturing/non-maturing PFA and returns/spawners ',
    'by sea-age group; maturation is a core life-cycle transition.'),
  mortality_evidence=paste0('This is a hierarchical life-cycle model with marine survival and ',
    'maturation transitions, not a conventional annual age-specific F/M surface.'),
  timing_evidence=paste0('The model follows smolt, post-smolt and 1SW/MSW return stages; ',
    'ordinary survey timing fractions are not directly applicable.'),
  output_evidence=paste0('WGNAS 2026 tables report regional PFA, returns and spawners with medians ',
    'and 5th/95th percentiles. Return/spawner tables extend through 2025; NAC PFA through 2024; ',
    'NEAC PFA tables include forecasts through 2029.'),
  detailed_source_url='https://iceslibrary.figshare.com/articles/report/Working_Group_on_North_Atlantic_Salmon_WGNAS_/32034120',
  review_date=today)
rows <- list()
rows[['ICES:sal.nac.all']] <- modifyList(salmon, list(
  weights_evidence=paste0('NAC biology tables report sex proportions and eggs per female by ',
    '1SW/MSW. WGC weights/fork lengths are mixed-stock fishery samples, not verified as direct NAC inputs.'),
  decision_reason=paste0('Eligible for source curation: the current joint WGNAS 2026 assessment ',
    'provides sea-age-resolved catch/return evidence and official population outputs. NAC is ',
    'one component of the basin-scale assessment, not a separate assessment run.'),
  notes=paste0('Grouped with sal.neac.all under one candidate_unit_id so this joint assessment is ',
    'counted once. The report covers 2025; 2SW is a proxy for all MSW.')))
rows[['ICES:sal.neac.all']] <- modifyList(salmon, list(
  weights_evidence=paste0('A complete NEAC-specific weight-at-age input used by the current ',
    'model was not verified. WGC fishery weights/fork lengths are not substituted for NEAC inputs.'),
  decision_reason=paste0('Eligible for source curation: the current joint WGNAS 2026 assessment ',
    'provides sea-age-resolved catch/return evidence and official population outputs. NEAC is ',
    'one component of the basin-scale assessment, not a separate assessment run.'),
  notes=paste0('Grouped with sal.nac.all under one candidate_unit_id so this joint assessment is ',
    'counted once. The report covers 2025; 2SW is a proxy for all MSW.')))
rows[['ICES:sal.wgc.all']] <- list(
  candidate_unit_id=NA_character_, matched_stock_id=NA_character_, match_status='ambiguous',
  screening_status='screened', eligibility='ineligible', import_status='not_started',
  catch_age_evidence=paste0('WGNAS 2026 reports WGC landings, sampling and sea-age/origin ',
    'composition; not an independent stock-specific catch-at-age series.'),
  survey_age_evidence='Fishery sampling and mixed-stock composition are not a stock abundance index.',
  weights_evidence='WGC tables report sample weight/fork length by age and origin, not a standalone stock biological input.',
  maturity_evidence='No separate WGC-stock maturity series; catches are attributed to NAC and NEAC.',
  mortality_evidence='Exploitation outputs refer to NAC, S-NEAC and N-NEAC populations affected by the fishery.',
  timing_evidence='No independent WGC stock survey series or survey timing was identified.',
  output_evidence='WGNAS reports WGC catch, origin and exploitation information, but no population output for a separate WGC biological stock.',
  detailed_source_url=salmon$detailed_source_url, review_date=today,
  decision_reason='Ineligible as a separate stock candidate and identity-ambiguous: WGC is a mixed-stock fishery area affecting NAC and NEAC populations.',
  notes='No candidate unit assigned, so WGC is not counted as a separate biological unit.')
rows[['ICES:anf.27.1-2']] <- list(
  candidate_unit_id='ices_anf_27_1_2', matched_stock_id=NA_character_, match_status='new',
  screening_status='screened', eligibility='ineligible', import_status='not_started',
  catch_age_evidence='2026 Norwegian advice reports aggregate commercial landings, not catch-at-age or age compositions.',
  survey_age_evidence='The national assessment uses aggregate Coastal Reference Fleet CPUE, not an age-specific abundance index.',
  weights_evidence='No age-specific weight input is documented for the current JABBA model.',
  maturity_evidence='No maturity-at-age input is used or reported for this surplus-production model.',
  mortality_evidence='The current advice uses JABBA with aggregate biomass and fishing-pressure outputs, not age-specific mortality.',
  timing_evidence='The report identifies a commercial CPUE reference fleet but gives no survey timing fraction.',
  output_evidence='The report provides relative biomass and fishing-pressure summaries, not N/F/M-at-age or recruitment outputs.',
  detailed_source_url='https://www.hi.no/hi/nettrapporter/rapport-fra-havforskningen-2025-79',
  review_date=today,
  decision_reason=paste0('Ineligible for age-disaggregated curation: the latest Norwegian assessment ',
    'used for 2026 advice is JABBA, based on aggregate landings and reference-fleet CPUE.'),
  notes='IMR Report 2025-79 was published 2025-12-11 and uses data through mid-October 2025; it covers both Lophius species.')
rows[['ICES:thr.27.nea']] <- list(
  candidate_unit_id='ices_thr_27_nea', matched_stock_id=NA_character_, match_status='new',
  screening_status='screened', eligibility='ineligible', import_status='not_started',
  catch_age_evidence='WGEF 2023/2024 reports describe irregular, unreliable thresher catches; no catch-at-age input was identified.',
  survey_age_evidence='No age-specific abundance index or quantitative population index was identified for this category 6.3 unit.',
  weights_evidence='No age-specific weight input used in a current ICES population assessment was identified.',
  maturity_evidence='No maturity-at-age input to a quantitative stock assessment was identified.',
  mortality_evidence='ICES SID lists a 2023 data-limited record; WGEF reports no quantitative age-structured assessment.',
  timing_evidence='No abundance survey index was found, so survey timing is unavailable.',
  output_evidence='WGEF reports provide precautionary advice and catch information, not age-structured population outputs.',
  detailed_source_url='https://iceslibrary.figshare.com/articles/report/Report_of_the_Working_Group_on_Elasmobranch_Fishes_WGEF_/26935504',
  review_date=today,
  decision_reason='Ineligible for age-disaggregated curation: reviewed WGEF material reports data-limited advice and no quantitative age-structured output for Northeast Atlantic threshers.',
  notes='ICES 2026 SID lists Alopias spp., year 2023, category 6.3; WGEF 2024 is the latest reviewed group report.')

source(file.path(root,'scripts','database','candidate_register_io.R'))
for (id in names(rows)) {
  i <- match(id, candidates$candidate_id)
  desired <- rows[[id]]
  current <- candidates[i,names(desired),drop=FALSE]
  same <- all(vapply(names(desired),function(n) {
    x <- current[[n]]; y <- desired[[n]]
    if (is.na(x)) is.na(y) else !is.na(y) && identical(as.character(x),as.character(y))
  },logical(1L)))
  if (same) next
prior_review <- candidates$match_status[i] == desired$match_status &&
    candidates$screening_status[i] == 'screened' &&
    candidates$eligibility[i] == desired$eligibility &&
    candidates$import_status[i] == 'not_started' &&
    identical(as.character(candidates$candidate_unit_id[i]), as.character(desired$candidate_unit_id)) &&
    identical(as.character(candidates$matched_stock_id[i]), as.character(desired$matched_stock_id)) &&
    all(vapply(setdiff(names(desired), c('output_evidence', 'catch_age_evidence')), function(n) {
      x <- current[[n]]; y <- desired[[n]]
      if (is.na(x)) is.na(y) else !is.na(y) && identical(as.character(x), as.character(y))
    }, logical(1L)))
  pristine <- candidates$match_status[i]=='unreviewed' &&
    candidates$screening_status[i]=='not_started' && candidates$eligibility[i]=='unresolved' &&
    (is.na(candidates$candidate_unit_id[i]) || !nzchar(candidates$candidate_unit_id[i]))
  if (!pristine && !prior_review) stop('Unexpected existing review state for ',id,call.=FALSE)
  for(n in names(desired)) candidates[[n]][i] <- desired[[n]]
  replace_candidate_register_row(register_path,i,candidates[i,,drop=FALSE],id)
  candidates <- read.csv(register_path,stringsAsFactors=FALSE,na.strings=c('', 'NA'),check.names=FALSE)
}
source(file.path(root,'scripts','database','195_summarize_discovery.R'))
source(file.path(root,'scripts','database','196_summarize_inventory_units.R'))
cat('Screened the five remaining ICES rows; NAC and NEAC are one joint assessment unit.\n')
