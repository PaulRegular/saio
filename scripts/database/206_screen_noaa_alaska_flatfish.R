# Screen five Alaska flatfish candidates against current official assessment sources.
path <- file.path('discovery', 'candidates.csv')
x <- read.csv(path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
ids <- paste0('NOAA:', c('10002', '10003', '10004', '10015', '10016'))
i <- match(ids, x$candidate_id)
if (anyNA(i)) stop('Expected NOAA candidate rows are missing.', call. = FALSE)
if (all(x$screening_status[i] == 'screened')) {
  stopifnot(identical(x$eligibility[i], c('ineligible', 'ineligible', 'ineligible', 'eligible', 'ineligible')))
  quit(save = 'no')
}
if (any(x$match_status[i] != 'unreviewed') || any(x$screening_status[i] != 'not_started')) {
  stop('Preserve the existing review; one or more candidate rows have changed.', call. = FALSE)
}

x$match_status[i] <- c('new', 'matched', 'new', 'new', 'new')
x$matched_stock_id[i] <- c(NA, 'afsc_arrowtooth_flounder_bsai', NA, NA, NA)
x$screening_status[i] <- 'screened'
x$eligibility[i] <- c('ineligible', 'ineligible', 'ineligible', 'eligible', 'ineligible')
x$import_status[i] <- c('not_started', 'imported', 'not_started', 'not_started', 'not_started')
x$catch_age_evidence[i] <- c(
  '2024 BSAI SAFE reports fishery catch biomass and fishery length compositions; it does not report a fishery catch-age series. Sparse survey ages do not supply catch numbers-at-age.',
  'The 2022 production assessment uses catch biomass and fishery length compositions; its source review found no accepted fishery age-composition likelihood. Existing canonical data are partial.',
  'The 2025 data review and 2026 draft list total fishery catch biomass and fishery length compositions, not fishery age compositions or catch-at-age. Length compositions alone do not establish catch-age inputs.',
  '2024 operational update reports catch totals for 1963-2024 and marginal fishery age compositions for 2000-2001, 2004-2007, and 2009-2021. Composition is flathead sole only while several catch fleets combine flathead sole and Bering flounder.',
  'The latest full 2022 assessment reports catch biomass and fishery length compositions but no fishery catch-age observations; later documents are projection updates.'
)
x$survey_age_evidence[i] <- c(
  'BSAI SAFE reports survey biomass and length data; age compositions are sparse (EBS slope in 2002 and 2012; Aleutian Islands in 2010, 2016, 2018, and 2022), not a continuous age-specific index.',
  'The 2022 report describes survey age samples in selected years, but they do not replace missing fishery catch-age observations.',
  'The 2026 draft reports GOA bottom-trawl age compositions for 1993-2025 with survey biomass; these can inform an age-specific survey index but do not establish catch-at-age.',
  'The 2024 update reports aggregate biomass and conditional age-at-length survey data for 1982, 1985, 1992-1995, 1999-2019, and 2021-2023. An age-specific index would require a documented reconstruction from CAAL, length composition, and biomass.',
  'The 2022 model uses survey biomass and CAAL; its marginal survey age compositions are ghosted and excluded from the likelihood. No fishery age composition is reported.'
)
x$weights_evidence[i] <- c(
  'The 2024 assessment describes growth and length-weight biology; age-specific weights require extraction from the official model inputs or outputs.',
  'See the existing BSAI arrowtooth source review for fixed biological inputs and the unresolved age-specific observation arrays.',
  'The 2025 data review and 2026 draft document age-length transitions and updated weight-at-age biology; the exact production-run matrices need source extraction.',
  'The 2024 model uses estimated sex-specific growth and an externally estimated weight-length relationship; age-specific weights are available from the pinned model run.',
  'The 2022 assessment describes growth and weight-at-age biology; it does not supply the missing fishery age observations.'
)
x$maturity_evidence[i] <- c(
  'The 2024 report cites the maturity schedule of Stark (2011); an age-specific vector requires source extraction.',
  'The 2022 production report documents female maturity and fixed sex-specific M; see the canonical stock review.',
  'The 2025 data review and 2026 draft describe maturity assumptions and the recommended fixed-M model; final run-specific biological matrices remain to be checked.',
  'The 2024 update reports an externally estimated age-based logistic maturity ogive (50% at age 9.7; 95% at age 12.8).',
  'The 2022 report documents maturity and fixed M; see the detailed assessment and model materials.'
)
x$mortality_evidence[i] <- c(
  'The 2024 assessment fixes natural mortality at 0.11 per year.',
  'The 2022 source review reports fixed M of 0.2 for females and 0.35 for males.',
  'The recommended 2026 Model 25.0 fixes M at 0.20 for females and 0.35 for males; Model 25.1 estimates sex-specific M as a sensitivity.',
  'The 2024 update fixes M at 0.2 per year for both sexes.',
  'The 2022 assessment uses fixed M=0.2; confirm details against its full source review before any translation.'
)
x$timing_evidence[i] <- c(
  'The assessment uses annual BSAI trawl-survey observations; a fractional within-year timing is not established by the reviewed source.',
  'Annual assessment and survey timing details are recorded in the existing source review; no new age-specific catch observation is supported.',
  'The GOA bottom-trawl survey is a summer survey; the report does not give a single observation fraction for the annual model, so translation timing would be an explicit approximation.',
  'Bering Sea and Aleutian Islands trawl surveys are summer surveys in a one-season annual assessment; an exact tinyAM fractional timing is not specified in the brief update.',
  'The GOA bottom-trawl survey is conducted in summer; any fractional timing would need to be stated as an approximation.'
)
x$output_evidence[i] <- c(
  'The 2024 SAFE provides age-structured assessment results, but this does not supply missing observed catch-at-age inputs.',
  'The existing canonical record contains partial reported inputs and outputs; the 2022 report provides age-structured assessment results.',
  'The detailed 2026 assessment draft reports age-structured outputs; the final October 2026 SSC report selects Model 25.0 for management advice. The full SAFE chapter remains pre-dissemination draft material at review date.',
  'The 2024 report and pinned revision bafa7658d31e0b99fe11d626a58e1c01807c69ee provide fitted N-at-age and other Stock Synthesis outputs.',
  'The 2022 full assessment reports fitted age-structured outputs; later 2024 and 2026 documents are projection updates.'
)
x$detailed_source_url[i] <- c(
  'https://files.npfmc.org/SAFE/2024/BSAIkamchatka.pdf',
  'https://apps-afsc.fisheries.noaa.gov/Plan_Team/2022/BSAIatf.pdf',
  'https://meetings.npfmc.org/Meeting/Details/5140',
  'https://files.npfmc.org/SAFE/2024/BSAIflathead.pdf',
  'https://apps-afsc.fisheries.noaa.gov/Plan_Team/2022/GOAflathead.pdf'
)
x$review_date[i] <- '2026-10-29'
x$decision_reason[i] <- c(
  'Ineligible for the age-input screen: no fishery catch-age series or source age composition was verified; sparse survey ages cannot support catch numbers-at-age. The 2024 report is the latest full production assessment; later material is projection-only.',
  'Matched to the existing BSAI arrowtooth stock and not a new case. Ineligible for an age-data translation because the fishery likelihood uses catch biomass and length compositions, with no verified fishery age-composition input.',
  'Ineligible under the source-age screen: the detailed current report lists catch biomass and fishery length compositions but no fishery catch-age observations. Survey age compositions do not fill that catch-data gap; the detailed 2026 report is still a draft.',
  'Eligible with documented reconstruction: the operational 2024 assessment supplies catch totals and fishery age compositions, plus survey biomass and CAAL/length information. Preserve the flathead-versus-combined-catch distinction and label any derived age-specific survey index as approximate.',
  'Ineligible for the age-input screen: the latest full assessment reports catch biomass and fishery length compositions, while survey marginal age compositions are excluded from its likelihood; no fishery catch-age input was verified.'
)
x$notes[i] <- c(
  'NOAA Stock SMART 10002; 2024 Model 16.0b is the latest full run located. Sparse survey age samples and age-structured model outputs are not substitutes for fishery catch-age data.',
  'NOAA:10003 maps to afsc_arrowtooth_flounder_bsai; Stock SMART lists Reinhardtius stomias, while the official report and canonical record use Atheresthes stomias. The existing canonical assessment record is partial; do not count this inventory row as new.',
  'NOAA Stock SMART snapshot says 2024 and lists Reinhardtius stomias, while the assessment report uses Atheresthes stomias. The latest full assessment reviewed is 2026; the October SSC selected Model 25.0 for management advice, though the detailed SAFE chapter was still a draft on 2026-10-29.',
  'NOAA Stock SMART 10015 is the Flathead Sole-Bering Flounder stock-complex assessment. Treat as one assessment, not separate flathead and Bering flounder candidates; see discovery/source_reviews/noaa_flathead_bsai.md.',
  'NOAA Stock SMART 10016; use the 2022 operational run. The 2024 and 2026 documents are projection updates rather than new full age-data assessments.'
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
