path <- file.path('discovery', 'candidates.csv')
x <- read.csv(path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))

id <- 'NOAA:10190'
i <- match(id, x$candidate_id)
if (is.na(i)) stop('Expected NOAA Pacific sanddab inventory row was not found.', call. = FALSE)
if (!is.na(x$matched_stock_id[i]) && nzchar(x$matched_stock_id[i])) {
  stop('Unexpected canonical match for NOAA Pacific sanddab.', call. = FALSE)
}

review <- list(
  candidate_unit_id = 'noaa_pacific_sanddab_us',
  scientific_name = 'Citharichthys sordidus',
  stock_name = 'Pacific sanddab - Pacific Coast',
  assessment_area = 'U.S. Pacific Coast, coastwide',
  inventory_assessment_year = '2013',
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'unresolved',
  import_status = 'not_started',
  catch_age_evidence = paste(
    'The 2013 Stock Synthesis report includes sex-specific age compositions from',
    'retained California trawl catches (2003, 2007-2008) and retained Oregon/',
    'Washington trawl catches (1995-2012, with gaps), ages 0-11. It also reports',
    'total catch including discards, but age samples are from retained fish only;',
    'the sources reviewed do not support an unbiased total catch-at-age reconstruction.'
  ),
  survey_age_evidence = paste(
    'The NWFSC survey supplies aggregate biomass indices and conditional age-at-length',
    'compositions; the model also uses triennial-survey biomass indices. These are not',
    'direct age-specific abundance indices. Age-composition values are presented in',
    'the report, but numeric run input files were not located.'
  ),
  weights_evidence = paste(
    'The report describes growth and length-weight biology used to derive model',
    'weight-at-age; the run-matched numeric biological input arrays were not recovered.'
  ),
  maturity_evidence = paste(
    'The assessment describes maturity biology and maturity changes, but the final',
    'run-specific maturity-at-age array was not recovered as machine-readable input.'
  ),
  mortality_evidence = paste(
    'The age-structured Stock Synthesis model estimates natural mortality from age and',
    'life-history information and reports sensitivity analyses; exact run input files',
    'and numeric age-specific mortality values were not recovered.'
  ),
  timing_evidence = paste(
    'The assessment is annual and uses aggregate NWFSC and triennial survey indices.',
    'A fractional within-year timing for those indices was not verified.'
  ),
  output_evidence = paste(
    'The 2013 report gives annual spawning biomass, depletion and exploitation outputs;',
    'it estimates the stock at 95.5% of unfished biomass at the beginning of 2013.',
    'The STAR Panel did not recommend the model for management because biomass scale',
    'was uncertain relative to fishery-independent surveys. It was accepted for status',
    'determination only; numeric population N-at-age and F-at-age matrices were not recovered.'
  ),
  detailed_source_url = paste(
    'https://www.pcouncil.org/documents/2014/01/status-of-the-u-s-pacific-sanddab-resource-in-2013-august-2013.pdf;',
    'https://www.fisheries.noaa.gov/s3/2021-04/Appendix-D.pdf;',
    'https://www.pcouncil.org/documents/2016/06/g4_att4_safe_electonly_jun2016bb.pdf;',
    'https://www.pcouncil.org/documents/2022/05/september-8-9-2021-ssc-minutes.pdf/;',
    'https://www.pcouncil.org/documents/2025/10/f-3-attachment-1-draft-harvest-specifications-sections-of-the-pacific-coast-groundfish-fishery-2027-2028-harvest-specification-and-management-measures.pdf;',
    'https://www.pcouncil.org/actions/phase-2-identification-of-groundfish-in-need-of-conservation-and-management-and-defining-their-stocks/'
  ),
  review_date = '2026-10-29',
  decision_reason = paste(
    'NOAA Stock SMART 10190 maps to the coastwide U.S. Pacific sanddab stock; PFMC',
    'Amendment 37 also identifies a single coastwide unit. The latest detailed age-',
    'structured assessment is the 2013 report (data through 2012), but NOAA lists it as',
    'not adequate and partially accepted for status determinations only. PFMC did not',
    'use it to set harvest specifications because biomass scale was uncertain; the',
    '2027-2028 draft continues a Category 3 harvest contribution. Age compositions are',
    'available, but all age samples were from retained fish while total catches include',
    'discards, leaving total catch-at-age and run-matched inputs unresolved. No canonical',
    'data were imported.'
  ),
  notes = paste(
    'Provisional new unit; no canonical stock match found. The 2013 age-structured',
    'assessment can support a status-only comparison, not reproduction of the current',
    'Category 3 harvest specification. Do not treat its biomass output as a precise',
    'management reference point.'
  )
)

for (column in names(review)) x[[column]][i] <- review[[column]]

lines <- readLines(path, warn = FALSE, encoding = 'UTF-8')
if (length(lines) != nrow(x) + 1L) {
  stop('Candidate CSV contains multiline records; refusing unsafe update.', call. = FALSE)
}
row <- x[i, , drop = FALSE]
row[] <- lapply(row, as.character)
tmp <- tempfile(fileext = '.csv')
write.csv(row, tmp, row.names = FALSE, na = '')
lines[i + 1L] <- readLines(tmp, warn = FALSE, encoding = 'UTF-8')[-1L]
unlink(tmp)
writeLines(lines, path, useBytes = TRUE)
cat('Screened NOAA Stock SMART 10190, Pacific sanddab.\n')
