root <- "."
candidate_path <- file.path(root, 'discovery', 'candidates.csv')
stocks_path <- file.path(root, 'database', 'stocks.csv')

candidates <- read.csv(candidate_path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
stocks <- read.csv(stocks_path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
candidate_id <- 'DFO:Arctic:North Slope Dolly Varden - Big Fish, Rat, Firth, Babbage, Vittrekwa'
i <- match(candidate_id, candidates$candidate_id)

if (is.na(i) || sum(candidates$candidate_id == candidate_id) != 1L) {
  stop('Expected single DFO North Slope Dolly Varden inventory row was not found.', call. = FALSE)
}
if (candidates$screening_status[i] != 'not_started' ||
    candidates$match_status[i] != 'unreviewed' ||
    candidates$eligibility[i] != 'unresolved') {
  stop('DFO North Slope Dolly Varden row has an unexpected prior review state.', call. = FALSE)
}

candidate_area <- paste(stocks$area, stocks$region, stocks$notes)
if (any(grepl('Dolly Varden|Salvelinus malma',
    paste(stocks$scientific_name, candidate_area), ignore.case = TRUE), na.rm = TRUE)) {
  stop('A canonical Dolly Varden record now exists; reconcile it before rerunning.', call. = FALSE)
}

review <- list(
  scientific_name = 'Salvelinus malma malma',
  assessment_area = "Gwich'in Settlement Area and Inuvialuit Settlement Region; multiple river populations",
  match_status = 'ambiguous',
  screening_status = 'screened',
  eligibility = 'unresolved',
  import_status = 'not_started',
  catch_age_evidence = paste(
    'The Rat River component has total subsistence harvest estimates in numbers and observed',
    'catch-at-age proportions for 1996-2014. The 2025 iSCAM analysis limited age compositions',
    'to 113 mm and 127 mm gillnets; ages 3-13 were observed and ages 10+ were pooled. These',
    'findings do not establish age-structured inputs for the other river populations.'
  ),
  survey_age_evidence = paste(
    'For the Rat River iSCAM, the abundance signal is standardized fishery-dependent CPUE',
    '(fish per set), not a fishery-independent survey or age-specific abundance index. No',
    'comparable age-index series was verified for the composite inventory entry.'
  ),
  weights_evidence = paste(
    'The Rat River report provides length-weight and growth relationships from which the model',
    'derives weight-at-age; the exact input series must be checked against its referenced biology',
    'report. No common weight-at-age input applies across the listed river populations.'
  ),
  maturity_evidence = paste(
    'The Rat River model uses an age-based maturity relationship referenced to the 2020 mark-',
    'recapture research document. The corresponding run-specific age vector and values require',
    'verification before import.'
  ),
  mortality_evidence = paste(
    'The Rat River iSCAM uses age-specific natural mortality. The 2025 study estimates M-at-age',
    'using life-history, length-based and weight-based methods and reports a geometric mean;',
    'mortality assumptions for the other river populations are not established here.'
  ),
  timing_evidence = paste(
    'The Rat River monitoring midpoint is August 14 (day 226), represented as 0.62 of a year',
    'in the 2025 iSCAM. This timing is specific to that monitoring series.'
  ),
  output_evidence = paste(
    'The Rat River iSCAM reports annual total abundance, age-1 recruitment, SSB, fishing',
    'mortality/exploitation and age-composition fits for 1996-2014, principally in figures.',
    'The 2017 advisory report and 2025 research document are separate model/reporting events;',
    'numeric annual N-at-age/F-at-age arrays were not verified. The 2026 report is a newer',
    'mark-recapture/biology source for 2015-2022, not yet verified as an updated model run.'
  ),
  detailed_source_url = paste(
    'https://www.dfo-mpo.gc.ca/fisheries-peches/ifmp-gmp/dolly-varden/2019/index-eng.html;',
    'https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/40596692.pdf;',
    'https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/40946137.pdf;',
    'https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/40953324.pdf;',
    'https://publications.gc.ca/collections/collection_2025/mpo-dfo/fs70-5/Fs70-5-2025-050-eng.pdf;',
    'https://publications.gc.ca/collections/collection_2026/mpo-dfo/fs70-5/Fs70-5-2026-053-eng.pdf'
  ),
  review_date = '2026-10-29',
  decision_reason = paste(
    'This DFO inventory row aggregates multiple river populations with separate assessment',
    'histories, so it cannot be treated as one stock unit. Rat River is a promising distinct',
    'candidate with a documented iSCAM and age-composition inputs, but input/output precision',
    'and the relationship of the 2025 analysis to the official advice run need further review.',
    'Keep overall eligibility unresolved until the source entry is split into verified units.'
  ),
  notes = paste(
    'The 2019 IFMP identifies separate Big Fish, Rat, Firth, Babbage, Vittrekwa and Fish Creek',
    'populations. As of that IFMP, formal peer-reviewed assessments were listed for Rat (2009-2014',
    'data; review held 2015, SAR published 2017), Big Fish (2013), Babbage (2017), and Firth',
    '(2003); Vittrekwa had no formal assessment and Fish Creek population studies began in 2016.',
    'Rat River has a 2025 multimodel research document using data through 2014 and a newer 2026',
    'mark-recapture research document covering 2015-2022. The latter catalogue record is cached,',
    'but its 15.20 MB PDF could not be retrieved locally: the official download redirected to an',
    'archived-information page and the browser fetch exceeded its file-size limit. The 2025 PDF',
    'download redirected similarly; its official catalogue metadata is cached. No stock or numeric',
    'assessment records were added. Cached files and SHA-256 values are in the ignored local source cache.'
  )
)

for (column in names(review)) candidates[[column]][i] <- review[[column]]
lines <- readLines(candidate_path, warn = FALSE, encoding = 'UTF-8')
if (length(lines) != nrow(candidates) + 1L) {
  stop('Candidate CSV contains multiline records; refusing unsafe update.', call. = FALSE)
}
row <- candidates[i, , drop = FALSE]
row[] <- lapply(row, as.character)
tmp <- tempfile(fileext = '.csv')
write.csv(row, tmp, row.names = FALSE, na = '')
lines[i + 1L] <- readLines(tmp, warn = FALSE, encoding = 'UTF-8')[-1L]
unlink(tmp)
writeLines(lines, candidate_path, useBytes = TRUE)
cat('Screened the North Slope Dolly Varden composite entry; retained unresolved unit-level eligibility and documented Rat River as a distinct follow-up candidate.\n')