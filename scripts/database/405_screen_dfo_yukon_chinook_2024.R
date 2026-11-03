root <- "."
path <- file.path(root, 'discovery', 'candidates.csv')
x <- read.csv(path, stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
id <- 'DFO:Pacific:Chinook Salmon - Yukon'
i <- match(id, x$candidate_id)
if (is.na(i)) stop('Expected Yukon Chinook inventory row is missing.', call. = FALSE)

if (x$screening_status[i] == 'screened') {
  stopifnot(x$candidate_unit_id[i] == 'dfo_yukon_chinook_smu',
    x$scientific_name[i] == 'Oncorhynchus tshawytscha',
    x$match_status[i] == 'new', x$eligibility[i] == 'unresolved',
    x$import_status[i] == 'not_started')
  quit(save = 'no')
}
if (x$screening_status[i] != 'not_started' || x$match_status[i] != 'unreviewed') {
  stop('Preserve the existing Yukon Chinook review state.', call. = FALSE)
}

x$candidate_unit_id[i] <- 'dfo_yukon_chinook_smu'
x$scientific_name[i] <- 'Oncorhynchus tshawytscha'
x$assessment_area[i] <- 'Yukon Chinook SMU, Canadian Yukon River; nine Conservation Units; excludes the Porcupine Chinook SMU'
x$inventory_assessment_year[i] <- 2024
x$match_status[i] <- 'new'
x$screening_status[i] <- 'screened'
x$eligibility[i] <- 'unresolved'
x$import_status[i] <- 'not_started'
x$catch_age_evidence[i] <- paste(
  'The pinned public assessment repository contains fishery/district/stock',
  'catch counts in salmon age categories Age1.1-Age2.5 for 1981-2024.',
  'The mapping to the current Yukon Chinook SMU and use in the final',
  'production likelihood have not been verified.'
)
x$survey_age_evidence[i] <- paste(
  'The assessment uses daily border sonar/fish-wheel counts and an aggregate',
  'mark-recapture passage index. Separate annual sex-specific age proportions',
  'for ages 4-7 and CU composition samples are public; an age-specific annual',
  'survey-index matrix was not verified.'
)
x$weights_evidence[i] <- paste(
  'Age, sex and length sampling is documented, and female size is used in an',
  'egg-mass/fecundity calculation. A conventional, run-matched weight-at-age',
  'surface was not verified; egg mass is not stock biomass.'
)
x$maturity_evidence[i] <- paste(
  'The spawner-recruitment analysis uses age-at-return probabilities for ages',
  '4-7, and the forward simulation uses a mean age-at-maturity probability',
  'vector. A conventional production-run maturity-at-age input surface was',
  'not verified.'
)
x$mortality_evidence[i] <- paste(
  'No conventional annual F-at-age or M-at-age surface is estimated. The CU',
  'run reconstruction assumes no en-route adult migration mortality after',
  'border passage; where CU harvest must be reconstructed, aggregate',
  'exploitation assumptions are used.'
)
x$timing_evidence[i] <- paste(
  'The run-reconstruction code models daily border passage over Julian days',
  '160-285 using sonar and fish-wheel observations. This is in-river run timing,',
  'not a standard annual survey timing fraction.'
)
x$output_evidence[i] <- paste(
  'The official 2026/008 summary states that the run reconstruction derives',
  'escapement, harvest and returns by age. It also plots aggregate catch,',
  'spawner abundance, exploitation and returns. The detailed analysis includes',
  'CU spawner-recruitment results, but a complete final-run numeric',
  'N/F/M-at-age matrix was not verified. The current repository snapshot is',
  'labelled subject to change.'
)
x$detailed_source_url[i] <- paste(
  'https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41320517.pdf;',
  'https://github.com/Pacific-salmon-assess/yukon-CK-ResDoc/tree/8bf845e838a3ea56ba071cb3286e5cf210c3b393;',
  'https://github.com/Pacific-salmon-assess/yukon-CK-ResDoc/blob/dba18480b9a538ac8aec31df5903ccdb26448b88/Yukon-chinook-resdoc.4Nov2025.pdf;',
  'https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41117347.pdf;',
  'https://www.pac.dfo-mpo.gc.ca/fm-gp/mplans/smon-yukon-ifmp-pgip-sm-eng.html'
)
x$review_date[i] <- '2026-10-30'
x$decision_reason[i] <- paste(
  'The current DFO unit is the Yukon Chinook SMU within the larger Yukon River',
  'Chinook major stock; the age-resolved assessment covers its nine CUs and',
  'excludes the Porcupine SMU. No exact canonical match was found. Age-related',
  'inputs and age-structured spawner-recruitment work are documented, but the',
  'current source set does not align final-run catch/age matrices, conventional',
  'weight and maturity surfaces, age-specific mortality assumptions, and final',
  'numeric age-specific outputs. The detailed report is in press and the newer',
  'repository snapshot is explicitly subject to change; retain as new with',
  'eligibility unresolved pending a frozen, run-matched source review.'
)
x$notes[i] <- paste(
  'Do not combine this Yukon Chinook SMU with the distinct Porcupine Chinook',
  'SMU or the older Yukon mainstem-only unit. See',
  'discovery/source_reviews/dfo_yukon_chinook_2024.md.'
)

source(file.path(root, 'scripts', 'database', 'candidate_register_io.R'))
replace_candidate_register_row(path, i, x[i, , drop = FALSE], id)