path <- file.path('discovery', 'candidates.csv')
x <- read.csv(path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))

cod_urls <- c(
  panel = 'https://d23h0vhsm26o6d.cloudfront.net/2.a.xi_2024-June-Management-Track-Peer-Review-Panel-Report_508_7_18_24.pdf',
  wgom = 'https://apps-nefsc.fisheries.noaa.gov/saw/sasi_files.php?year=2024&species_id=4&stock_id=12&review_type_id=3&filename=2024_COD_WGOM.zip',
  egom = 'https://apps-nefsc.fisheries.noaa.gov/saw/sasi_files.php?year=2024&species_id=4&stock_id=13&review_type_id=3&filename=2024_COD_EGOM.zip',
  sne = 'https://apps-nefsc.fisheries.noaa.gov/saw/sasi_files.php?year=2024&species_id=4&stock_id=14&review_type_id=3&filename=2024_COD_SNE.zip',
  amendment = 'https://repository.library.noaa.gov/view/noaa/73154/noaa_73154_DS1.pdf',
  egb = 'https://repository.library.noaa.gov/view/noaa/55817/noaa_55817_DS1.pdf'
)

updates <- list(
  'NOAA:12805' = list(
    matched_stock_id = 'ck_nefsc_trac_cert_morhua_gb',
    match_status = 'matched', screening_status = 'screened',
    eligibility = 'unresolved', import_status = 'not_started',
    catch_age_evidence = paste('The 2023 TRAC status report describes the stock using survey indicators and explicitly says no assessment model was available; it does not provide a fitted fishery catch-at-age likelihood.'),
    survey_age_evidence = paste('Age observations inform survey-based mortality and distribution indicators, but the 2023 report does not fit an age-specific abundance index.'),
    weights_evidence = paste('The report discusses length, growth and condition summaries; no numerical age-specific weight surface is used by a fitted population model in this report.'),
    maturity_evidence = paste('No numerical maturity-at-age input for a fitted population model is reported.'),
    mortality_evidence = paste('Empirical survey catch-curve mortality indicators are shown; these are not an estimated natural-mortality process in a fitted population model.'),
    timing_evidence = paste('DFO spring and NMFS spring/fall surveys are identified, but the status report has no fitted model timing settings.'),
    output_evidence = paste('The report contains survey biomass and age-structured indicators, not fitted N/F/M-at-age or recruitment surfaces. The current-unit DFO assessment outputs are recorded under the existing Eastern Georges Bank stock.'),
    detailed_source_url = cod_urls['egb'], review_date = '2026-10-29',
    decision_reason = paste('NOAA Stock SMART ID 12805 is the Eastern Georges Bank transboundary unit already represented by ck_nefsc_trac_cert_morhua_gb. The linked 2023 TRAC document is an indicator-based status report without an assessment model; the latest detailed age-structured assessment is the existing DFO EGB framework record. No separate stock or duplicate assessment is created from this NOAA inventory row.'),
    notes = paste('Identity crosswalk: NOAA 12805 Eastern Georges Bank = DFO NAFO 5Zjm / legacy 5Zejm. See discovery/source_reviews/noaa_eastern_georges_bank_2023_identity.md and dfo_cod_5zjm_identity.md. The NOAA repository PDF is linked for review; direct local download returned HTTP 403, while the current-unit DFO source files are already cached.')
  ),
  'NOAA:17280' = list(
    match_status = 'new', matched_stock_id = NA_character_, screening_status = 'screened',
    eligibility = 'unresolved', import_status = 'not_started',
    catch_age_evidence = paste('The accepted-run input-data material and diagnostics show commercial and recreational catch-age composition panels over 1981-2023, ages 1-9+. Numeric composition arrays and annual catch-at-age were not provided in the recovered archive.'),
    survey_age_evidence = paste('The accepted-run materials show age-composition panels for multiple survey indices, with aggregate index series in the report. Numeric survey age-composition arrays were not provided.'),
    weights_evidence = paste('Annual age-specific fleet, survey and stock weights are plotted in the input-data PDF; the numeric run-matched matrices are not included.'),
    maturity_evidence = paste('Stock maturity-at-age is plotted in the input-data PDF, but the numeric run-matched surface is not included.'),
    mortality_evidence = paste('The WHAM assessment and mortality diagnostics are documented, but the selected run-specific numerical M specification/surface is not available in the recovered files.'),
    timing_evidence = paste('The report distinguishes spring and fall indices; exact within-year sampling fractions from the accepted WHAM configuration were not recovered.'),
    output_evidence = paste('The 2024 report gives aggregate SSB (mt), fully selected F (rate), and age-1 recruitment (thousands) through 2023. Age-specific state figures are available, but numerical fitted age surfaces are not.'),
    detailed_source_url = paste(cod_urls['panel'], cod_urls['wgom'], 'https://d23h0vhsm26o6d.cloudfront.net/2.a.vi_Western_Gulf_of_Maine_cod_Update_4.pdf', cod_urls['amendment'], sep = '; '),
    review_date = '2026-10-29',
    decision_reason = paste('The 2024 WHAM assessment created the Western Gulf of Maine unit, distinct from the former combined Gulf of Maine stock and from the current Georges Bank unit. The peer-review panel found the assessment suitable for management advice and selected a final run excluding the 2023 spring BLLS point. The cache contains age-composition and biological figures plus aggregate outputs, but not numeric age inputs or fitted age-output arrays; source eligibility remains unresolved pending those arrays.'),
    notes = paste('Provisional new unit pending completion of the NOAA/ICES/DFO cross-inventory reconciliation. Model years 1981-2023; age grid shown as 1-9+. Source bundle and manifest are cached under source_cache/noaa_cod_new_units_2024/.')
  ),
  'NOAA:17281' = list(
    match_status = 'new', matched_stock_id = NA_character_, screening_status = 'screened',
    eligibility = 'unresolved', import_status = 'not_started',
    catch_age_evidence = paste('The accepted-run input-data material shows catch-age composition for the fishery, but the assessment notes commercial and recreational age compositions have not been characterized since 2013. Numeric arrays were not included in the recovered archive.'),
    survey_age_evidence = paste('The accepted-run material shows age compositions for survey indices; Sentinel Survey compositions for 2012-2021 were updated. Numeric survey age-composition arrays were not included.'),
    weights_evidence = paste('The input-data PDF plots age-specific stock and index weights; numeric run-matched matrices were not included.'),
    maturity_evidence = paste('Maturity-at-age is shown graphically, but the numeric selected-run surface is not included.'),
    mortality_evidence = paste('The WHAM assessment and mortality diagnostics are documented, but the selected run-specific numerical M specification/surface is not available in the recovered files.'),
    timing_evidence = paste('The report distinguishes spring/fall indices and an Eastern Gulf of Maine Sentinel Survey; exact within-year sampling fractions from the accepted WHAM configuration were not recovered.'),
    output_evidence = paste('The 2024 report gives aggregate SSB (mt), fully selected F (rate), and age-1 recruitment (thousands) through 2023. Age-specific state figures are available, but numerical fitted age surfaces are not.'),
    detailed_source_url = paste(cod_urls['panel'], cod_urls['egom'], 'https://d23h0vhsm26o6d.cloudfront.net/2.a.viii_Eastern_Gulf_of_Maine_Atlantic_Cod_Update_2024_Post_Review.pdf', cod_urls['amendment'], sep = '; '),
    review_date = '2026-10-29',
    decision_reason = paste('The 2024 WHAM assessment created the Eastern Gulf of Maine unit, distinct from the former combined Gulf of Maine stock and from Eastern Georges Bank. The peer-review panel found the assessment suitable for management advice. The cache contains age-composition and biological figures plus aggregate outputs, but not numeric age inputs or fitted age-output arrays; recent fishery age compositions are also unavailable after 2013. Source eligibility remains unresolved pending recoverable run-specific age arrays.'),
    notes = paste('Provisional new unit pending completion of the NOAA/ICES/DFO cross-inventory reconciliation. Model years 1981-2023; age grid shown as 1-9+. Source bundle and manifest are cached under source_cache/noaa_cod_new_units_2024/.')
  ),
  'NOAA:17282' = list(
    match_status = 'new', matched_stock_id = NA_character_, screening_status = 'screened',
    eligibility = 'unresolved', import_status = 'not_started',
    catch_age_evidence = paste('The accepted-run plots include fishery catch-age composition. The report notes sparse commercial ages and no ages from the recreational fishery in recent years; numerical age-composition arrays were not included in the recovered archive.'),
    survey_age_evidence = paste('The accepted-run plots include survey age-composition diagnostics, but the report describes limited recent survey age sampling and the numeric age-composition arrays are not included.'),
    weights_evidence = paste('Age-specific weights are shown in assessment plots, but the numeric selected-run surfaces are not included.'),
    maturity_evidence = paste('Maturity/selectivity plots are available in the assessment materials, but a numeric run-matched maturity-at-age surface was not included.'),
    mortality_evidence = paste('The WHAM assessment reports F and population results, but the selected run-specific numerical M specification/surface is not available in the recovered files.'),
    timing_evidence = paste('The report identifies the spring NEFSC survey and recreational CPUE; exact within-year survey timing from the accepted WHAM configuration was not recovered.'),
    output_evidence = paste('The 2024 report gives aggregate SSB (mt), fully selected F (rate), and age-1 recruitment (thousands) through 2023. N-at-age, M-at-age and age-composition figures are available, but numerical fitted age surfaces are not.'),
    detailed_source_url = paste(cod_urls['panel'], cod_urls['sne'], 'https://d23h0vhsm26o6d.cloudfront.net/2.a.iv_Southern_New_England_Cod_2024_report_revised_projections.pdf', cod_urls['amendment'], sep = '; '),
    review_date = '2026-10-29',
    decision_reason = paste('The 2024 WHAM assessment created the Southern New England unit, which was formerly included in the broader Georges Bank unit. The peer-review panel found the assessment suitable for management advice. The cache includes age-composition and age-surface plots plus aggregate outputs, but not numeric age inputs or fitted age-output arrays. Limited recent biological samples leave source eligibility unresolved.'),
    notes = paste('Provisional new unit pending completion of the NOAA/ICES/DFO cross-inventory reconciliation. Model years 1981-2023. The assessment is fit to spring NEFSC survey and recreational CPUE; the latter uses AR1 time-varying q and its age composition uses a Dirichlet-multinomial likelihood. Source bundle and manifest are cached under source_cache/noaa_cod_new_units_2024/.')
  )
)

for (id in names(updates)) {
  i <- match(id, x$candidate_id)
  if (is.na(i)) stop(paste('Expected candidate is missing:', id), call. = FALSE)
  for (column in names(updates[[id]])) x[[column]][i] <- updates[[id]][[column]]
}

lines <- readLines(path, warn = FALSE, encoding = 'UTF-8')
if (length(lines) != nrow(x) + 1L) stop('Multiline CSV rows require a safe update method.', call. = FALSE)
for (id in names(updates)) {
  i <- match(id, x$candidate_id)
  tmp <- tempfile(fileext = '.csv')
  write.csv(x[i, , drop = FALSE], tmp, row.names = FALSE, na = '')
  updated <- readLines(tmp, warn = FALSE, encoding = 'UTF-8')[-1L]
  unlink(tmp)
  lines[i + 1L] <- updated
}
writeLines(lines, path, useBytes = TRUE)
cat('Screened three 2024 NOAA Atlantic cod units and reconciled NOAA 12805 to the existing EGB stock.\n')
