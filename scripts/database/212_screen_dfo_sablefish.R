# Screen the current BC Sablefish unit against DFO's 2022 operating model sources.
path <- file.path('discovery', 'candidates.csv')
x <- read.csv(path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
i <- match('DFO:Pacific:Sablefish', x$candidate_id)
if (is.na(i)) stop('Expected DFO Sablefish row is missing.', call. = FALSE)
if (x$screening_status[i] == 'screened') {
  stopifnot(x$match_status[i] == 'new', x$eligibility[i] == 'unresolved')
  quit(save = 'no')
}
if (x$match_status[i] != 'unreviewed' || x$screening_status[i] != 'not_started') {
  stop('Preserve the existing review; the candidate row has changed.', call. = FALSE)
}

x$scientific_name[i] <- 'Anoplopoma fimbria'
x$assessment_area[i] <- 'British Columbia coastwide'
x$match_status[i] <- 'new'
x$matched_stock_id[i] <- NA_character_
x$screening_status[i] <- 'screened'
x$eligibility[i] <- 'unresolved'
x$import_status[i] <- 'not_started'
x$catch_age_evidence[i] <- paste(
  'The latest detailed age-structured operating model uses gear-specific',
  'landed catches (trap, longline hook, trawl; 1965-2021) and at-sea releases,',
  'with age compositions modeled separately. Trap-fishery age samples cover',
  '1982-2016 with gaps; hook and trawl have no age-composition inputs. The',
  'report provides catch biomass by gear and age compositions as figures,',
  'but no public numeric commercial age-composition arrays were located.',
  'Complete catch numbers-at-age therefore cannot be reconstructed from the',
  'verified public data without model-derived allocations.'
)
x$survey_age_evidence[i] <- paste(
  'The 2022 operating model uses trap CPUE (1979-2009), the standardized',
  'trap survey (1990-2009), and the stratified random trap survey (2003-2021)',
  'as total-biomass indices. Survey age compositions are reported for the',
  'standardized survey (1990-2009) and StRS (2003-2014). DFO Open Data now',
  'provides StRS biological records with non-missing ages in every year',
  '2003-2021, plus later years; those later records must not be mixed into',
  'the 2022 model. The public records can support a source-specific StRS',
  'reconstruction, but are not the full set of accepted model compositions.'
)
x$weights_evidence[i] <- paste(
  'The 2022 operating model keeps sex-specific length-at-age, weight-at-age,',
  'and maturity-at-age biological parameters fixed at values used in 2016/2019.',
  'Cox et al. (2023), Research Document 2023/023, documents the earlier',
  'operating-model biology; the 2026 technical report updates life-history',
  'analyses through 2024 and is not a run-matched replacement.'
)
x$maturity_evidence[i] <- paste(
  'Female maturity-at-age is an externally estimated fixed input retained',
  'from the earlier operating-model cycle. The 2022 report describes the',
  'source and points to Cox et al. (2023); the 2025 biology report includes',
  'later maturity analyses, which are not the values used in the 2022 run.'
)
x$mortality_evidence[i] <- paste(
  'Male and female natural mortality are estimated independently with the',
  'same Normal prior (mean 0.1 and standard deviation 0.1 per year). The 2022',
  'research document reports posterior estimates and uncertainty by scenario.'
)
x$timing_evidence[i] <- paste(
  'The 2022 model places trap CPUE at fraction 0.5 of the year and the surveys',
  'at fraction 0.75, consistent with their October-November timing.'
)
x$output_evidence[i] <- paste(
  'The 2024/072 research document reports posterior spawning-biomass and',
  'age-1 recruitment time series, uncertainty, reference points, natural',
  'mortality estimates, and model-fit figures. Numeric annual N-at-age and',
  'F-at-age output matrices were not located in the public report sources.'
)
x$detailed_source_url[i] <- 'https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41279281.pdf'
x$review_date[i] <- '2026-10-29'
x$decision_reason[i] <- paste(
  'No canonical British Columbia coastwide Sablefish stock is present; the',
  'U.S. West Coast and Alaska Sablefish inventory entries are separate',
  'management units. The current 2025-26 advice applies a management',
  'procedure based on an aggregate state-space production model. The latest',
  'detailed age-structured operating model is the 2022 update using data',
  'through 2021. Its age-based inputs and outputs are documented, but raw',
  'commercial trap age compositions and numeric age-specific fitted outputs',
  'were not recovered, so age-based import eligibility remains unresolved.'
)
x$notes[i] <- paste(
  'The DFO inventory row has no official assessment code; do not invent one.',
  '2025-26 management advice uses the MP/SSPM, not a new age-structured fit.',
  'Keep the 2022 age-structured OM (data through 2021) separate. DFO Open',
  'Data StRS records currently extend later than that run; filter to its',
  'accepted years for any future extraction. Source cache and checksums are',
  'in source_cache/dfo_bc_sablefish_20261029/sources.csv.'
)

lines <- readLines(path, warn = FALSE, encoding = 'UTF-8')
if (length(lines) != nrow(x) + 1L) stop('Multiline CSV rows require a safe update method.', call. = FALSE)
tmp <- tempfile(fileext = '.csv')
write.csv(x[i, , drop = FALSE], tmp, row.names = FALSE, na = '')
lines[i + 1L] <- readLines(tmp, warn = FALSE, encoding = 'UTF-8')[[2L]]
unlink(tmp)
writeLines(lines, path, useBytes = TRUE)
