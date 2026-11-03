# Screen NOAA northern rockfish units against the latest available assessment sources.
path <- file.path('discovery', 'candidates.csv')
x <- read.csv(path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
ids <- paste0('NOAA:', c('10416', '10417'))
i <- match(ids, x$candidate_id)
if (anyNA(i)) stop('Expected NOAA northern rockfish rows are missing.', call. = FALSE)
if (all(x$screening_status[i] == 'screened')) {
  stopifnot(identical(x$match_status[i], c('new', 'new')),
    identical(x$eligibility[i], c('eligible', 'eligible')))
  quit(save = 'no')
}
if (any(x$match_status[i] != 'unreviewed') || any(x$screening_status[i] != 'not_started')) {
  stop('Preserve the existing review; one or more candidate rows have changed.', call. = FALSE)
}

x$match_status[i] <- 'new'
x$matched_stock_id[i] <- NA_character_
x$screening_status[i] <- 'screened'
x$eligibility[i] <- 'eligible'
x$import_status[i] <- 'not_started'
x$catch_age_evidence[i] <- c(
  'The 2023 full assessment reports fishery catch through 2022 with 2023 projected, plus fishery age compositions for 2000-2009, 2011, 2013, 2015, 2017, and 2019-2021. Catch-at-age is not a direct observation series; composition-year catch could be reconstructed from catch totals and age proportions, with the assessment’s fleet/area and weight conventions preserved.',
  'The 2024 full assessment reports commercial catch biomass in tonnes for 1961-2024 and fishery age compositions for 1998-2002, 2004-2006, 2008-2020 (biennial), and 2022. Catch-at-age is not supplied as a direct observation series; a documented composition-year reconstruction from catch totals and age proportions is possible.'
)
x$survey_age_evidence[i] <- c(
  'The full assessment pairs Aleutian Islands survey age compositions with survey biomass estimates in 1991, 1994, 1997, 2000, 2002, 2004, 2006, 2010, 2012, 2014, 2016, 2018, and 2022. Age-specific survey abundance would be a documented reconstruction from aggregate biomass and observed age composition, not a direct model input.',
  'The 2024 model uses survey biomass and age compositions: biomass in 1990-1999 (triennial), 2001-2021 (biennial), and 2023; age compositions in 1990-1999 (triennial), 2003-2021 (biennial), and 2023. An age-specific index is reconstructable from the aggregate biomass and the corresponding age composition, but is not the native index likelihood.'
)
x$weights_evidence[i] <- c(
  'The age-structured model defines annual population and fishery weight-at-age vectors in kg and describes their growth basis. Exact arrays and scaling should be extracted from the 2023 assessment tables/native inputs before import.',
  'The 2024 report documents age-specific population weights derived from survey growth/length-weight information; the author-preferred m24 model uses the updated biological inputs. Preserve the reported biological basis and verify the exact age vector during import.'
)
x$maturity_evidence[i] <- c(
  'The assessment uses an age-specific maturity vector and estimates maturity parameters. The 2023 report documents the fitted maturity process; extract the run-specific age schedule before import.',
  'The m24 assessment uses an updated externally estimated maturity ogive based on Conrath (2019) and earlier studies. Maturity is age-specific and its input basis is described in the full report; verify the final vector during import.'
)
x$mortality_evidence[i] <- c(
  'Natural mortality is estimated with a prior in the age-structured assessment. The 2023 full assessment and 2026 projection report the carried-forward M of 0.052; the projection does not re-estimate it.',
  'Natural mortality is estimated in the model; the author-preferred m24 reports M near 0.0595 and includes an M prior likelihood. The estimate is not a fixed input.'
)
x$timing_evidence[i] <- c(
  'The model uses annual BSAI bottom-trawl survey observations. The reports identify survey years but do not establish a single within-year observation fraction; a tinyAM timing fraction would need to be documented as an approximation.',
  'The model uses annual GOA bottom-trawl survey biomass and age-composition observations. The report gives survey years but not one fractional observation timing for the annual model; any fraction used in translation would be an explicit approximation.'
)
x$output_evidence[i] <- c(
  'The 2023 full SAFE reports fitted age-structured population and mortality outputs, including numbers-at-age, recruitment and spawning biomass. The September 2026 harvest-projection update reports age-3+ total biomass, female spawning biomass, updated exploitation information and projections, explicitly carrying the 2023 full assessment forward.',
  'The 2024 m24 full assessment reports age-specific abundance, age-2 recruitment, age-2+ total biomass, female spawning biomass and mortality outputs, with uncertainty intervals for key population time series.'
)
x$detailed_source_url[i] <- c(
  'https://meetings.npfmc.org/CommentReview/DownloadFile?fileName=13.+BSAI+Northern+Rockfish.pdf&p=c7d07ded-c246-4798-883b-1aacc01d8172.pdf',
  'https://files.npfmc.org/SAFE/2024/GOAnork.pdf'
)
x$review_date[i] <- '2026-10-29'
x$decision_reason[i] <- c(
  'Provisionally eligible as a new stock unit for source curation: the full age-structured assessment provides catch totals, fishery age compositions, survey biomass and survey age compositions, plus biological schedules and fitted outputs. Catch-at-age and age-specific survey abundance require documented reconstruction; they are not direct observed age-index likelihoods.',
  'Provisionally eligible as a new stock unit for source curation: the full m24 assessment provides commercial catch totals, fishery age compositions, survey biomass and survey age compositions, biological schedules and fitted outputs. Catch-at-age and an age-specific survey index require documented reconstruction from assessment inputs.'
)
x$notes[i] <- c(
  'NOAA Stock SMART ID 10416 is a distinct BSAI unit; no corresponding canonical stock or other-inventory candidate was found. Stock SMART’s 2024 label is stale for the latest source review: the 2026 BSAI chapter says the 2025 full assessment was cancelled, the 2023 full assessment remains the latest full fit, and the 2026 chapter is a harvest projection using 2023 estimates. The next full assessment is scheduled for 2027.',
  'NOAA Stock SMART ID 10417 is a distinct GOA unit; no corresponding canonical stock or other-inventory candidate was found. The latest detailed full fit located is the 2024 m24 assessment. The 2026 SSC review scheduled a GOA Northern Rockfish update for December 2026, which had not yet been released by this review date.'
)

lines <- readLines(path, warn = FALSE, encoding = 'UTF-8')
if (length(lines) != nrow(x) + 1L) stop('Multiline CSV rows require a safe update method.', call. = FALSE)
tmp <- tempfile(fileext = '.csv')
for (j in i) {
  write.csv(x[j, , drop = FALSE], tmp, row.names = FALSE, na = '')
  lines[j + 1L] <- readLines(tmp, warn = FALSE, encoding = 'UTF-8')[[2L]]
}
unlink(tmp)
writeLines(lines, path, useBytes = TRUE)
