# Screen the current NOAA Rougheye/Blackspotted Rockfish complex assessment.
path <- file.path('discovery', 'candidates.csv')
x <- read.csv(path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
i <- match('NOAA:14516', x$candidate_id)
if (is.na(i)) stop('Expected NOAA Rougheye/Blackspotted row is missing.', call. = FALSE)
if (x$screening_status[i] == 'screened') {
  stopifnot(x$match_status[i] == 'new', x$eligibility[i] == 'eligible')
} else if (x$screening_status[i] != 'not_started' || x$match_status[i] != 'unreviewed') {
  stop('Preserve the existing NOAA Rougheye/Blackspotted review; candidate row changed.', call. = FALSE)
}

x$scientific_name[i] <- 'Sebastes aleutianus; Sebastes melanostictus'
x$assessment_area[i] <- 'U.S. West Coast'
x$candidate_unit_id[i] <- 'noaa_uswc_rougheye_blackspotted'
x$match_status[i] <- 'new'
x$matched_stock_id[i] <- NA_character_
x$screening_status[i] <- 'screened'
x$eligibility[i] <- 'eligible'
x$import_status[i] <- 'not_started'
x$catch_age_evidence[i] <- paste(
  'The 2025 single-area, two-sex model covers the combined Rougheye and',
  'Blackspotted management complex. It uses catch biomass in metric tonnes',
  'for six fisheries and conditional age-at-length (CAAL) observations from',
  'fishery sampling. CAAL data enter the likelihood; marginal age',
  'compositions are supplied for fit evaluation. Catch-at-age is not a direct',
  'annual input and would require reconstruction from catches and sampled',
  'age information.'
)
x$survey_age_evidence[i] <- paste(
  'The native model includes indices for Triennial, Alaska slope, Northwest',
  'slope, and WCGBTS surveys, with survey age/length observations described',
  'in the report. The data file retains survey observation timing and age',
  'compositions. An age-specific abundance index is not a direct model input',
  'and would require a documented reconstruction from aggregate indices and',
  'age compositions.'
)
x$weights_evidence[i] <- paste(
  'The model derives weight-at-age from its fitted growth and weight-at-length',
  'parameters; the native Report.sso includes biomass-at-age output.'
)
x$maturity_evidence[i] <- paste(
  'The model uses a length-based maturity relationship documented in the',
  '2025 report; age-specific maturity can be derived from the model growth',
  ''
)
x$mortality_evidence[i] <- paste(
  'Female natural mortality is estimated. Male natural mortality is fixed at',
  '0.036 per year following likelihood-profile analysis; alternative M values',
  'are used in the report uncertainty scenarios.'
)
x$timing_evidence[i] <- paste(
  'The native data file records observation months for survey series and the',
  'model has January spawning. Preserve each observation month when converting',
  'to fractional-year survey timing.'
)
x$output_evidence[i] <- paste(
  'The native Report.sso includes annual numbers-at-age, catch-at-age,',
  'biomass-at-age, F-at-age and natural-mortality outputs. The report provides',
  'spawning output, recruitment and management quantities with uncertainty.'
)
x$detailed_source_url[i] <- 'https://www.pcouncil.org/documents/2026/01/status-of-rougheye-and-blackspotted-rockfishes-stock-off-the-u-s-west-coast-in-2025.pdf/'
x$review_date[i] <- '2026-10-29'
x$decision_reason[i] <- paste(
  'NOAA Stock SMART ID 14516 is the U.S. West Coast Rougheye/Blackspotted',
  'management complex, consisting of Sebastes aleutianus and Sebastes',
  'melanostictus treated as one assessment unit. No matching canonical stock',
  'record was found. The adopted 2025 assessment has a matching native',
  'Stock Synthesis bundle with catch totals, CAAL and survey age data,',
  'biological assumptions, and fitted age-specific outputs. Mark eligible',
  'for source curation and an explicitly approximate age-structured',
  'translation; it is one complex and must not be counted as two cases.'
)
x$notes[i] <- paste(
  'The report covers U.S. waters from the U.S.-Canada border to the',
  'U.S.-Mexico border and treats the two species as one management complex',
  'because they are difficult to distinguish in catches. The model uses data',
  'through 2024, two sexes, 140 population ages, and one area. The report and',
  'native bundle identify Stock Synthesis 3.30.23.2. Cached sources and',
  'checksums are listed in',
  'source_cache/discovery_noaa_rougheye_2025/sources.csv.'
)

lines <- readLines(path, warn = FALSE, encoding = 'UTF-8')
starts <- grep('^"(NOAA|ICES|DFO):', lines, perl = TRUE)
if (length(starts) != nrow(x)) stop('Could not map CSV records to physical lines.', call. = FALSE)
record_start <- starts[i]
later <- starts[starts > record_start]
record_end <- if (length(later)) min(later) - 1L else length(lines)
tmp <- tempfile(fileext = '.csv')
write.csv(x[i, , drop = FALSE], tmp, row.names = FALSE, na = '')
updated <- readLines(tmp, warn = FALSE, encoding = 'UTF-8')[-1L]
unlink(tmp)
if (length(updated) != 1L) stop('Updated CSV record unexpectedly contains line breaks.', call. = FALSE)
lines <- c(lines[seq_len(record_start - 1L)], updated,
  if (record_end < length(lines)) lines[(record_end + 1L):length(lines)] else character())
writeLines(lines, path, useBytes = TRUE)
