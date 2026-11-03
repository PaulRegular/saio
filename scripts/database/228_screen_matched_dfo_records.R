path <- file.path('discovery', 'candidates.csv')
x <- read.csv(path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
updates <- list(
  list(
    id = 'DFO:Newfoundland and Labrador:Atlantic Cod - NAFO 3Ps', stock = 'ck_dfo_morhua_3ps', review = 'dfo_cod_3ps_2024.md',
    catch = 'The 2024 detailed HYBRID assessment report gives commercial catch-at-age for 1959-2023, ages 2-14+; unit scale is cross-checked against prior source reports. A separate 2025 annual update is retained without merging its newer rows into the 2024 run.',
    survey = 'The 2024 assessment reports age-specific DFO RV spring, ERHAPS, GEAC, Sentinel Gillnet and Sentinel Line-trawl indices; zeros are retained and survey units/multipliers are unresolved.',
    weights = 'The 2024 report supplies annual model stock weights and catch weights for 1959-2024, ages 2-14+.',
    maturity = 'Annual maturity proportions at ages 2-14+ are supplied for 1959-2024.',
    mortality = 'The HYBRID model estimates condition-dependent M, with response parameters shared for ages 2-5 and 6+.',
    timing = 'Exact survey fractions are not reported. Timing and some likelihood/covariance settings remain unresolved and must not be inferred from quarter names.',
    output = 'The 2024 assessment has aggregate SSB, age-2 recruitment and grouped mean F/M for 2020-2024; complete N/F/M-at-age outputs are not tabulated. Separate 2025 update outputs are stored under its own record.',
    sources = 'https://publications.gc.ca/collections/collection_2026/mpo-dfo/fs70-5/Fs70-5-2026-051-eng.pdf; https://waves-vagues.dfo-mpo.gc.ca/Library/4105829x.pdf; https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41315832.pdf',
    reason = 'Matched to the current 3Ps stock. Latest annual advice is the 2025 HYBRID update, with a separate 2025 record; the 2024 assessment is the latest detailed input run recovered. It provides age-structured inputs and some official outputs, but not full fitted age surfaces or run controls. Do not mix the two assessment records.'
  ),
  list(
    id = 'DFO:Gulf:Atlantic Cod - NAFO 4TVn', stock = 'dfo_cod_4t4vn', review = 'dfo_cod_4t4vn.md',
    catch = 'The latest detailed 2019 SCA assessment includes stock catches for 1965-2018 and landed numbers-at-age for ages 3-12+ in 1971-2018; these do not recover its full catch-composition likelihood. The 2024 update is summary-only and remains separate.',
    survey = 'The 2019 report supports reconstructed aggregate survey indices and age compositions for RV, mobile Sentinel and longline series; original fitted composition samples and some index years are unavailable.',
    weights = 'The 2019 report provides age-specific weights, with missing years that prevent reconstruction of the full RV biomass series.',
    maturity = 'Annual maturity-at-age is available for 1950-2018, carried forward between source-listed change years.',
    mortality = 'The 2019 SCA estimates time-varying M by age groups using a fish-condition covariate; the 2024 assessment reuses the population model but has no detailed numerical age-specific update.',
    timing = 'Exact survey timing fractions and full likelihood settings were not recovered.',
    output = 'The detailed 2019 record contains N/F-at-age and population tables through 2018 plus terminal grouped M and q; the separate 2024 report/dataset adds aggregate SSB/F/M through 2023 but no age-specific fit.',
    sources = 'https://publications.gc.ca/collections/collection_2019/mpo-dfo/fs70-5/Fs70-5-2019-038-eng.pdf; https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41243833.pdf; https://open.canada.ca/data/en/dataset/fe51e3da-0e0b-11ef-90aa-8b219c568296',
    reason = 'Matched to the current 4TVn stock. The 2024 assessment used for advice and the 2019 detailed SCA run are represented separately; 2019 inputs/outputs are not copied to the 2024 event. The detailed source contains age-structured data, but several input surfaces and full age outputs remain partial.'
  ),
  list(
    id = 'DFO:Maritimes:Haddock - NAFO 4X5Y', stock = 'ck_dfo_aeglefinus_4x5y', review = 'dfo_haddock_4x5y.md',
    catch = 'The latest detailed 2016 ADAPT VPA uses commercial catch-at-age for ages 1-11+; the canonical source tables retain finer ages and years, with the VPA pooling applied downstream.',
    survey = 'The 2016 VPA uses DFO Summer RV swept-area abundance-at-age for ages 1-10 over 1985-2015, in thousands of fish; one printed 2015 age cell remains unresolved and omitted.',
    weights = 'Commercial catch weights and RV survey weights are reported by age; the latter extend beyond the ages used by the VPA.',
    maturity = 'A static maturity ogive and spawning weights are available from the 2016 framework per-recruit analysis; they are proxies for population SSB calculations, not annual VPA observation inputs.',
    mortality = 'M is fixed at 0.2 per year except ages 10-11+, where it changes by period from 0.3 to 0.9 per year.',
    timing = 'The 2016 production report does not give annual survey fractions; a tinyAM midyear value is an explicit approximation.',
    output = 'The 2016 report provides F-at-age and Fbar through 2015, N-at-age and age-4+ biomass through 2016, and terminal q; annual N/F/biomass uncertainty is not reported. 2024 advice adds only a 2022 model-based SSB value.',
    sources = 'https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/40722697.pdf; https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/40613215.pdf; https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41306132.pdf',
    reason = 'Matched to the current 4X5Y unit. The 2024 advice is newer but summary-only; the 2016 VPA is the latest detailed age-structured production assessment recovered. Catch/index and official outputs are available, while maturity is a framework proxy, one survey cell and annual uncertainty remain unresolved.'
  ),
  list(
    id = 'DFO:Pacific:Pacific Hake - Offshore', stock = 'joint_hake_coastal', review = 'joint_hake_coastal.md',
    catch = 'The official 2025 SS3 model supplies total catch and age compositions as native percentages with sample sizes and partitions; age-specific catch requires a documented downstream reconstruction.',
    survey = 'The assessment uses an acoustic age-2+ biomass index and survey age compositions; age-specific survey abundance is not a direct input and requires a documented reconstruction from the aggregate index and composition.',
    weights = 'Native annual population, fishery and survey weights-at-age are retained, ages 0-20+; observed compositions cover ages 1-15+.',
    maturity = 'The assessment uses supplied maturity-times-fecundity weights rather than maturity proportions; preserve that distinction in any translation.',
    mortality = 'M is estimated as a single constant with a lognormal prior and bounds 0.05-0.4; the reported posterior median is 0.233454.',
    timing = 'The acoustic survey is in month 7, represented at fraction 0.5; spawning is at the beginning of the year.',
    output = 'The 2025 native assessment and NOAA extraction provide N-at-age, biomass/exploitation-at-age, aggregate biomass, age-0 recruitment and M summaries with uncertainty; instantaneous F-at-age is not recovered.',
    sources = 'https://repository.library.noaa.gov/view/noaa/67186/noaa_67186_DS1.pdf; https://www.pcouncil.org/documents/2026/08/hake-2025-model-files-zip-file.zip/; https://github.com/NOAA-FIMS/case-studies/tree/04aadf2748945371ad7d3e26847035da7801543f/content/data_files',
    reason = 'Matched to the joint U.S.-Canada coastal treaty stock. Detailed 2025 native SS3 inputs and historical outputs are recovered; composition-based catch/index reconstruction and the absence of an instantaneous F-at-age surface remain limitations. The 2026 update is catch-only/projection and is not mixed into the 2025 fit.'
  )
)
for (u in updates) {
  i <- which(x$candidate_id == u$id)
  if (length(i) != 1L || x$matched_stock_id[i] != u$stock ||
      x$match_status[i] != 'matched' || !(x$screening_status[i] %in% c('not_started', 'screened'))) {
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
cat('Screened four matched DFO assessment entries.\n')
