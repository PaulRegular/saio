path <- file.path('discovery', 'candidates.csv')
x <- read.csv(path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
updates <- list(
  list(id = 'ICES:pok.27.5a', stock = 'ck_ices_nwwg_virens_fa5a',
    review = 'ices_saithe_iceland_2026.md',
    catch = 'The official 2026 MFRI SAM assessment reports commercial catch-at-age for 1980-2025, ages 3-14+, in thousand fish.',
    survey = 'The March SMB survey provides age-specific abundance indices for ages 3-14+ in 1985-2026; index scale is not calibrated and some age-year cells are blank.',
    weights = 'Stock weights-at-age are reported in grams per fish for 1980-2026; catch weights are supplementary and not identified as assessment inputs.',
    maturity = 'Proportion mature at age is reported for 1980-2026.',
    mortality = 'M is fixed at 0.2 per year for all modeled ages.',
    timing = 'Survey timing is approximated at 0.20 for March; exact production sampling fraction is unpublished.',
    output = 'MFRI tables report N-at-age through 2026 and F-at-age through 2025; ICES SAG reports SSB, age-3 recruitment and age-4+ reference biomass with 95% intervals. Age-specific uncertainty is unavailable.',
    sources = 'https://www.hafogvatn.is/static/extras/images/3_pol_2026_1_techreport_en.html; https://www.hafogvatn.is/static/extras/images/3_pol_2026_1_tables_en.html; https://standardgraphs.ices.dk/ViewSourceData.aspx?key=22624',
    reason = 'Matched to the current Icelandic Division 5.a saithe unit and 2026 production SAM assessment. Direct age-specific catch and survey series, biology, fixed M and population/mortality outputs are recovered. Exact production settings, index scale and age-specific uncertainty remain unresolved.'),
  list(id = 'ICES:had.27.5a', stock = 'ices_haddock_iceland',
    review = 'ices_haddock_iceland_2026.md',
    catch = 'The official 2026 MFRI assessment reports commercial catch-at-age for 1979-2025, ages 1-12+, in thousands of fish.',
    survey = 'Age-specific IS-SMB indices cover ages 1-12 in 1985-2026; IS-SMH covers 1995-2025. Units are native/unscaled and some older-age cells are missing.',
    weights = 'Catch and stock weights-at-age are reported for ages 1-12; stock weights cover 1979-2026.',
    maturity = 'Annual maturity-at-age is reported for 1979-2026; pre-1985 values repeat the 1985 vector.',
    mortality = 'M is fixed at 0.2 per year for ages 1-12.',
    timing = 'The source identifies March and October surveys; 0.20 and 0.80 are month-midpoint approximations, not verified 2026 production fractions.',
    output = 'MFRI tables report N-at-age through 2026 and F-at-age through 2025, plus aggregate summaries. Summary range coverage is unspecified and age-specific uncertainty is unavailable.',
    sources = 'https://www.hafogvatn.is/static/extras/images/2_had_2026_1_techreport_en.html; https://www.hafogvatn.is/static/extras/images/2_had_2026_1_tables_en.html; https://doi.org/10.17895/ices.pub.28444499.v1',
    reason = 'Matched to the current Icelandic Division 5.a haddock unit and 2026 production SAM assessment. Catch, two age-specific surveys, biology, fixed M and fitted population/mortality surfaces are recovered. Native survey scales, exact timing, process covariance and age-specific uncertainty remain incomplete.'),
  list(id = 'ICES:cod.27.5b1', stock = 'ck_ices_nwwg_morhua_fapl5b1',
    review = 'ices_cod_faroe_plateau_2025.md',
    catch = 'The selected official 2025 SAM run uses 590 commercial catch-at-age observations from 1959-2025, thousand fish, ages 2-10+; age-1 slots are empty and excluded.',
    survey = 'The model uses summer and spring age-specific indices at ages 1-9, 270 and 280 finite observations respectively, on native index scales.',
    weights = 'Annual stock, catch, landings and discard weights are retained from native SAM data.',
    maturity = 'Annual maturity-at-age is retained from native SAM data.',
    mortality = 'M is fixed at 0.2 per year across all ages and years.',
    timing = 'Native survey fractions are 0.65 for summer and 0.225 for spring; pre-spawning F and M fractions are zero.',
    output = 'The selected 2025 fit provides N/F-at-age, q, fitted observations, recruitment, SSB, total biomass and Fbar. Published series and 2024-2025 checks match; fit converged with positive-definite Hessian and gradient below 2e-12.',
    sources = 'https://doi.org/10.17895/ices.advice.28162805; https://sg.ices.dk/ViewSourceData.aspx?key=21240; https://stockassessment.org/datadisk/stockassessment/userdirs/user3/Cod_27_5b1_2025/',
    reason = 'Matched to Faroe Plateau cod and the official 2025 SAM production run. Native age-based inputs and outputs, run identity and convergence are verified; canonical record is complete.'),
  list(id = 'ICES:had.27.5b', stock = 'ck_ices_nwwg_aeglefinus_fa5b',
    review = 'ices_haddock_faroe_2025.md',
    catch = 'The official NWWG2025_had SAM run provides catch-at-age for 1957-2025, ages 1-10+, retaining source zeros that SAM excludes from its lognormal likelihood.',
    survey = 'SUMMERSURVEY covers ages 1-8 in 1996-2025 at time 0.65; SPRINGSURVEY covers ages 1-7 in 1994-2025 at time 0.225.',
    weights = 'Native annual stock, catch, landings and discard weights are retained by age.',
    maturity = 'Native annual maturity-at-age is retained.',
    mortality = 'M is fixed at 0.2 per year at all ages and years.',
    timing = 'Native fitted sampling times are 0.65 for summer and 0.225 for spring; pre-spawning F and M fractions are zero.',
    output = 'Native outputs include N/F-at-age, recruitment, SSB, total biomass, Fbar, q and fitted observations, with conditional state uncertainty. Selected fit converged with code 0, positive-definite Hessian and max gradient below 8e-11.',
    sources = 'https://doi.org/10.17895/ices.advice.30738524; https://stockassessment.org/datadisk/stockassessment/userdirs/user3/NWWG2025_had/',
    reason = 'Matched to Faroe Plateau haddock and the selected official 2025 SAM production run. Native age-based inputs and fitted outputs are verified; source review confirms run selection and convergence.'),
  list(id = 'ICES:pok.27.5b', stock = 'ck_ices_nwwg_virens_fa5b',
    review = 'ices_saithe_faroe_2025.md',
    catch = 'The selected 2025 SAM run provides commercial catch-at-age in thousand fish for 1961-2025, ages 3-15+, including source zeros.',
    survey = 'Summer and spring age-specific catch-rate indices cover ages 3-10; source catch numbers and effort are retained alongside the per-effort indices used by SAM.',
    weights = 'Native annual stock, catch, landings and discard weights are retained; source stock/catch weights are missing for 2025 and are estimated internally by SAM.',
    maturity = 'Annual maturity-at-age is retained from the native assessment data.',
    mortality = 'M is fixed at 0.2 per year for ages 3-15.',
    timing = 'Native fitted survey fractions are 0.65 and 0.225; before-spawning F and M fractions are zero.',
    output = 'Native SAM outputs include N/F-at-age, q, fitted catch/index predictions, recruitment, SSB, total biomass and Fbar with conditional uncertainty. The selected fit matches 2025 report summaries and converged with positive-definite Hessian.',
    sources = 'https://asd.ices.dk/viewAdvice/4018; https://doi.org/10.17895/ices.pub.21565164; https://stockassessment.org/datadisk/stockassessment/userdirs/user3/fsaithe-NWWG-2025/',
    reason = 'Matched to Faroe saithe and the official 2025 fsaithe-NWWG-2025 SAM run. Native age-based inputs/outputs and fit identity are verified. One survey index is reconstructed from source catch numbers and effort, and 2025 biological surfaces are estimated by SAM.')
)
for (u in updates) {
  i <- which(x$candidate_id == u$id)
  if (length(i) != 1L || x$matched_stock_id[i] != u$stock ||
      x$match_status[i] != 'matched' ||
      !x$screening_status[i] %in% c('not_started', 'screened')) {
    stop('Preserve the current identity or screen for ', u$id, '.', call. = FALSE)
  }
  x$screening_status[i] <- 'screened'
  x$eligibility[i] <- 'eligible'
  x$import_status[i] <- 'imported'
  for (field in c('catch_age_evidence','survey_age_evidence','weights_evidence',
                  'maturity_evidence','mortality_evidence','timing_evidence','output_evidence')) {
    key <- switch(field, catch_age_evidence = 'catch', survey_age_evidence = 'survey',
      weights_evidence = 'weights', maturity_evidence = 'maturity',
      mortality_evidence = 'mortality', timing_evidence = 'timing',
      output_evidence = 'output')
    x[[field]][i] <- u[[key]]
  }
  x$detailed_source_url[i] <- u$sources
  x$review_date[i] <- '2026-10-29'
  x$decision_reason[i] <- u$reason
  x$notes[i] <- paste0('Already curated in the canonical database; see ',
    'source_reviews/', u$review, '.')
}
lines <- readLines(path, warn = FALSE, encoding = 'UTF-8')
if (length(lines) != nrow(x) + 1L) stop('Multiline CSV rows require a safe update method.', call. = FALSE)
tmp <- tempfile(fileext = '.csv')
for (u in updates) {
  i <- match(u$id, x$candidate_id)
  write.csv(x[i, , drop = FALSE], tmp, row.names = FALSE, na = '')
  lines[i + 1L] <- readLines(tmp, warn = FALSE, encoding = 'UTF-8')[[2L]]
}
unlink(tmp)
writeLines(lines, path, useBytes = TRUE)
cat('Screened five matched Iceland/Faroe ICES assessment entries.\n')
