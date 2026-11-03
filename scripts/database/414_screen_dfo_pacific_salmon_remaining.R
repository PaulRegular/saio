root <- "."
path <- file.path(root, 'discovery', 'candidates.csv')
x <- read.csv(path, stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)

candidate_ids <- c(
  'DFO:Pacific:Coho Salmon - North Coast',
  paste0('DFO:Pacific:Pink Salmon ', intToUtf8(8211), ' Fraser'),
  'DFO:Pacific:Pink Salmon - Skeena-Nass',
  'DFO:Pacific:Sockeye Salmon - Nass',
  'DFO:Pacific:Sockeye Salmon - Skeena',
  'DFO:Pacific:Sockeye Salmon - Stikine',
  'DFO:Pacific:WCVI Barkley Sockeye Salmon'
)
rows <- match(candidate_ids, x$candidate_id)
if (is.na(rows[2])) rows[2] <- which(grepl('^DFO:Pacific:Pink Salmon', x$candidate_id) & grepl('Fraser$', x$candidate_id))
if (anyNA(rows)) stop('Expected DFO Pacific salmon rows are missing.', call. = FALSE)

urls <- paste(
  'https://www.pac.dfo-mpo.gc.ca/pacific-smon-pacifique/science/research-recherche/smon-summ-somm-eng.html;',
  'https://www.pac.dfo-mpo.gc.ca/science/fieldnotes-carnet-expeditions/publications/assessment-stock-evaluation-2024-25-eng.html;',
  'https://publications.gc.ca/collections/collection_2025/mpo-dfo/Fs70-7-2025-001-eng.pdf;',
  'https://publications.gc.ca/collections/collection_2025/mpo-dfo/Fs97-6-3661-eng.pdf;',
  'https://publications.gc.ca/collections/collection_2025/mpo-dfo/fs70-5/Fs70-5-2024-056-eng.pdf;',
  'https://www.pac.dfo-mpo.gc.ca/fm-gp/mplans/smon-tr-ifmp-pgip-sm-eng.html;',
  'https://newsrelease.adfg.alaska.gov/index.cfm?adfg=commercialbyareasoutheast.salmon_research_stikineriver_stockassess;',
  'https://publications.gc.ca/collections/collection_2026/mpo-dfo/Fs70-7-2026-022-eng.pdf'
)

set_row <- function(id, unit_id = NA_character_, scientific_name,
                    assessment_area, assessment_year = NA_integer_,
                    match_status, screening_status = 'screened', eligibility,
                    catch_age, survey_age, weights, maturity, mortality,
                    timing, outputs, reason, notes) {
  i <- rows[match(id, candidate_ids)]
  x$candidate_id[i] <<- id
  x$candidate_unit_id[i] <<- unit_id
  x$scientific_name[i] <<- scientific_name
  x$assessment_area[i] <<- assessment_area
  x$inventory_assessment_year[i] <<- assessment_year
  x$match_status[i] <<- match_status
  x$screening_status[i] <<- screening_status
  x$eligibility[i] <<- eligibility
  x$import_status[i] <<- 'not_started'
  x$catch_age_evidence[i] <<- catch_age
  x$survey_age_evidence[i] <<- survey_age
  x$weights_evidence[i] <<- weights
  x$maturity_evidence[i] <<- maturity
  x$mortality_evidence[i] <<- mortality
  x$timing_evidence[i] <<- timing
  x$output_evidence[i] <<- outputs
  x$detailed_source_url[i] <<- urls
  x$review_date[i] <<- '2026-10-30'
  x$decision_reason[i] <<- reason
  x$notes[i] <<- notes
}

set_row(
  candidate_ids[1], scientific_name = 'Oncorhynchus kisutch',
  assessment_area = 'North Coast, British Columbia; multiple coho management units',
  match_status = 'ambiguous', eligibility = 'unresolved',
  catch_age = 'No single North Coast coho catch-at-age series can be assigned: DFO identifies separate Central Coast, Haida Gwaii, Nass and Skeena coho management units.',
  survey_age = 'The DFO regional overview summarizes monitoring but does not provide a single age-specific abundance index for the broad North Coast label.',
  weights = 'No single age-specific weight series can be assigned to the multi-unit inventory row.',
  maturity = 'No single maturity-at-age series can be assigned to the multi-unit inventory row.',
  mortality = 'No one F/M assumption or mortality-at-age output is identified for this broad label.',
  timing = 'No single within-year timing fraction is established for an age-specific index.',
  outputs = 'The DFO regional summary distinguishes several coho units and gives outlook categories; it does not give one set of comparable population-at-age outputs for North Coast coho.',
  reason = 'DFO describes separate Central Coast, Haida Gwaii, Nass and Skeena coho units. The inventory label does not resolve to one current assessment unit. Keep identity ambiguous and eligibility unresolved; do not aggregate units or create a canonical record.',
  notes = 'No stock, assessment, input or output records were added. Revisit only if the inventory source can be mapped to one current unit.'
)

set_row(
  candidate_ids[2], 'dfo_fraser_pink_odd_smu', 'Oncorhynchus gorbuscha',
  'Fraser Pink Odd Stock Management Unit, Fraser River, British Columbia', 2023L,
  'new', eligibility = 'ineligible',
  catch_age = 'The 2023 assessment reports aggregate catch. It does not document catch numbers-at-age as a model input.',
  survey_age = 'The state-space spawner-recruit assessment uses aggregate escapement observations. The report describes Fraser Pink as a single-age-class stock, not a multi-age population index.',
  weights = 'The report discusses average adult body mass, but does not provide weight-at-age used in a population-at-age assessment.',
  maturity = 'No multi-age maturity schedule is documented for the assessment; the report describes a single age class.',
  mortality = 'The assessment reports aggregate exploitation rates; it does not estimate annual F-at-age or M-at-age surfaces.',
  timing = 'Run-timing forecasts are not included in this stock-assessment response; no within-year timing for an age-specific observation is defined.',
  outputs = 'The 2023 assessment reports aggregate catch, escapement, total run size and exploitation-rate series, with uncertainty for current escapement and HCR projections. It does not report N/F/M-at-age surfaces.',
  reason = 'The latest detailed assessment located is the full 2023 Fraser Pink stock assessment, published as Science Response 2025/001. It uses a state-space spawner-recruit model and describes a single-age-class stock. Although it provides aggregate official outputs, it does not provide the multi-age inputs and outputs required by this age-structured candidate screen.',
  notes = 'A valid copy of Science Response 2025/001 is cached locally. No canonical stock, assessment, input or output records were added.'
)

set_row(
  candidate_ids[3], scientific_name = 'Oncorhynchus gorbuscha',
  assessment_area = 'Skeena and Nass River pink salmon management units, British Columbia',
  match_status = 'ambiguous', eligibility = 'unresolved',
  catch_age = 'The inventory label spans Skeena and Nass Pink units; no single current catch-at-age source can be assigned.',
  survey_age = 'DFO outlooks distinguish Pink Skeena and Pink Nass as separate units. The regional summary does not establish an age-specific abundance-index likelihood for one combined unit.',
  weights = 'No single age-specific weight series can be assigned to the combined label.',
  maturity = 'No single maturity-at-age series can be assigned to the combined label.',
  mortality = 'No single mortality process or age-specific mortality output is identified for the combined label.',
  timing = 'Run timing varies among the separate river units; a single index timing fraction is not established.',
  outputs = 'DFO publishes separate outlooks for Skeena and Nass Pink. No one set of comparable outputs matching the combined inventory label was identified.',
  reason = 'Current DFO material identifies Pink Skeena and Pink Nass separately. The inventory entry spans both current units, so it remains identity ambiguous and eligibility unresolved; do not merge them into one candidate stock.',
  notes = 'No candidate unit or canonical records were added. Review the Skeena and Nass units separately if the inventory can be crosswalked to them.'
)

set_row(
  candidate_ids[4], 'dfo_nass_sockeye_smu', 'Oncorhynchus nerka',
  'Nass River Sockeye aggregate, British Columbia; seven Conservation Units',
  match_status = 'new', eligibility = 'ineligible',
  catch_age = 'The 2025 DFO data review describes aggregate catches and run reconstruction, but not catch-at-age as a multi-age population-model likelihood.',
  survey_age = 'Age composition is used to calculate brood-year recruitment from aggregate run size. This is not an age-specific abundance-index likelihood.',
  weights = 'No weight-at-age surface is documented as an input to the spawner-recruit assessment.',
  maturity = 'Age composition informs brood-year recruitment, but the reviewed assessment does not document a maturity-at-age population surface.',
  mortality = 'The assessment reports aggregate exploitation/run reconstructions and stock-recruit parameters, not annual F-at-age or M-at-age.',
  timing = 'The reviewed stock-recruit analysis does not define a within-year timing fraction for an age-specific index.',
  outputs = 'Detailed reports provide aggregate spawner, run and derived recruitment series and stock-recruit benchmarks. They do not provide age-specific N/F/M surfaces.',
  reason = 'The latest detailed public sources reviewed describe population structure, run reconstruction and stock-recruit analyses. Age compositions are used to back-calculate recruitment, but the assessed quantities are aggregate spawner-recruit series and benchmarks rather than an age-structured population model. Screen ineligible for the current age-disaggregated candidate set.',
  notes = 'Sources include DFO Canadian Technical Report 3661 (2025) and Research Document 2024/056. Their source pages and full-text indexing were reviewed; local PDF downloads returned the Government Publications archived-information page, so only the successfully retrieved DFO pages and Fraser Pink report are in the local cache.'
)

set_row(
  candidate_ids[5], 'dfo_skeena_sockeye_smu', 'Oncorhynchus nerka',
  'Skeena River Sockeye aggregate, British Columbia; wild and enhanced components',
  match_status = 'new', eligibility = 'ineligible',
  catch_age = 'The 2025 DFO data review describes run reconstruction and catches, but not catch-at-age as a multi-age population-model likelihood.',
  survey_age = 'Age composition is used to calculate brood-year recruitment from aggregate run size; it is not an age-specific abundance-index likelihood.',
  weights = 'No weight-at-age surface is documented as an input to the spawner-recruit assessment.',
  maturity = 'Age composition informs brood-year recruitment, but the reviewed assessment does not document a maturity-at-age population surface.',
  mortality = 'The assessment reports aggregate exploitation/run reconstructions and stock-recruit parameters, not annual F-at-age or M-at-age.',
  timing = 'The reviewed stock-recruit analysis does not define a within-year timing fraction for an age-specific index.',
  outputs = 'Detailed reports provide aggregate spawner, run and derived recruitment series and stock-recruit benchmarks. They do not provide age-specific N/F/M surfaces.',
  reason = 'The latest detailed public sources reviewed describe population structure, run reconstruction and stock-recruit analyses. Age compositions are used to back-calculate recruitment, but the assessed quantities are aggregate spawner-recruit series and benchmarks rather than an age-structured population model. Screen ineligible for the current age-disaggregated candidate set.',
  notes = 'Sources include DFO Canadian Technical Report 3661 (2025) and Research Document 2024/056. Their source pages and full-text indexing were reviewed; local PDF downloads returned the Government Publications archived-information page, so only the successfully retrieved DFO pages and Fraser Pink report are in the local cache.'
)

set_row(
  candidate_ids[6], 'dfo_stikine_sockeye_smu', 'Oncorhynchus nerka',
  'Stikine River transboundary sockeye management unit, British Columbia and Alaska',
  match_status = 'new', eligibility = 'ineligible',
  catch_age = 'The reviewed current DFO/ADF&G sources describe run-size and harvest estimation, not catch-at-age as an input to an age-structured population likelihood.',
  survey_age = 'Since 2021 the detailed assessment has used genetic mark-recapture to estimate stock composition and in-river abundance. Biological age samples are collected, but the reviewed source does not use them as an age-specific abundance-index likelihood.',
  weights = 'No weight-at-age assessment input was identified.',
  maturity = 'No maturity-at-age population surface was identified.',
  mortality = 'The reviewed public assessment description concerns stock composition and run abundance; no annual F-at-age or M-at-age surface was identified.',
  timing = 'Test fishery and migration timing are used for run reconstruction; no timing fraction for an age-specific population index is defined.',
  outputs = 'The current DFO/ADF&G material concerns aggregate run estimates and four historical management stock groups, not comparable annual N/F/M-at-age surfaces.',
  reason = 'The current Stikine assessment described by ADF&G and DFO is a genetic mark-recapture/run-size assessment, with age/sex/length observations collected as supporting samples rather than a multi-age population model. Screen ineligible for this age-structured candidate set.',
  notes = 'The management unit is jointly assessed by DFO, the Tahltan Central Government and ADF&G under the Pacific Salmon Treaty. No canonical records were added.'
)

set_row(
  candidate_ids[7], 'dfo_wcvi_barkley_sockeye_smu', 'Oncorhynchus nerka',
  'West Coast Vancouver Island - Barkley Sockeye Stock Management Unit, British Columbia',
  2024L, 'new', screening_status = 'in_progress', eligibility = 'unresolved',
  catch_age = 'The 2024 assessment response has been located, but its detailed catch inputs have not yet been reviewed.',
  survey_age = 'The 2024 assessment response has been located, but the role of age composition and any age-specific index remain to be verified from its detailed methods.',
  weights = 'Weight-at-age evidence remains unreviewed in the 2024 assessment source.',
  maturity = 'Maturity-at-age evidence remains unreviewed in the 2024 assessment source.',
  mortality = 'Mortality assumptions and age-specific outputs remain to be verified from the detailed 2024 assessment source.',
  timing = 'Survey/index timing remains unreviewed.',
  outputs = 'DFO Science Response 2026/022 reports the 2024 Barkley Sockeye assessment and harvest advice; age-specific output availability has not yet been confirmed.',
  reason = 'The current DFO stock-management summary identifies a distinct West Coast Vancouver Island - Barkley unit, and DFO has published a Science Response for the 2024 assessment. Continue screening the report for age-specific inputs, assumptions and outputs before assigning eligibility.',
  notes = 'The official publication page and PDF URL were located. A local download attempt returned the Government Publications archived-information page rather than the PDF; keep the screen in progress and do not classify based on the incomplete text.'
)

source(file.path(root, 'scripts', 'database', 'candidate_register_io.R'))
for (i in rows) {
  if (i == rows[2]) {
    helper_id <- paste0("DFO:Pacific:Pink Salmon ", "<U+2013>", " Fraser")
    helper_row <- x[i, , drop = FALSE]
    helper_row$candidate_id <- helper_id
    replace_candidate_register_row(path, i, helper_row, helper_id)
    bytes <- readBin(path, "raw", n = file.info(path)[["size"]])
    bounds <- csv_record_bounds(bytes)
    record <- i + 1L
    first <- bounds$start[record] + 1L
    old_id <- charToRaw(helper_id)
    new_id <- charToRaw(x$candidate_id[i])
    last <- first + length(old_id) - 1L
    if (!identical(bytes[first:last], old_id)) stop("Could not restore the UTF-8 Pink assessment identifier.", call. = FALSE)
    before <- if (first > 1L) bytes[seq_len(first - 1L)] else raw(0L)
    after <- if (last < length(bytes)) bytes[(last + 1L):length(bytes)] else raw(0L)
    writeBin(c(before, new_id, after), path)
  } else {
    replace_candidate_register_row(path, i, x[i, , drop = FALSE], x$candidate_id[i])
  }
}