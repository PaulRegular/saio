root <- "."
cache <- file.path(root, 'source_cache',
  'discovery_noaa_south_atlantic_greater_amberjack_2020')
register_path <- file.path(root, 'discovery', 'candidates.csv')
candidate_id <- 'NOAA:10208'
unit_id <- 'noaa_greater_amberjack_south_atlantic'

sha256_file <- function(path) {
  output <- system2('certutil.exe',
    c('-hashfile', shQuote(normalizePath(path, winslash = '\\', mustWork = TRUE)), 'SHA256'),
    stdout = TRUE)
  hashes <- tolower(trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$',
    output, value = TRUE)))
  if (length(hashes) != 1L) stop('Could not verify source checksum: ', path, call. = FALSE)
  hashes
}

expected <- c(
  SEDAR59_final_SAR.pdf = 'c6cdf134facf545e891905b5cf50f1eb9ea30a545609721850a7537ded90d7dc',
  SEDAR59_WP05_commercial_age_compositions.pdf = '1c1a28dcff29ca3eb50d384d1f16de17e7bbc58d60e6f7f00d35b2a30276bac2',
  SEDAR59_WP11_recreational_age_compositions.pdf = 'd583210fcd3314bc56570b27a9cfd81ce68c802fabef1270048940c213c33b49',
  SEDAR59_project_page.html = 'fc9327bc3ce178f345ad1e9dd90dfaf92be12b5d95f5caaf4a07264c887b8517',
  NOAA_greater_amberjack_resources.html = '3682c8f249b0bc593520a748bfec179b65d552369a5e3b5f876f71ebe5e06e27',
  SEDAR59_WP01_SERFS_video_index.pdf = '43c90d48325a40f7539fcbce19cd1251edcaafe99d107eee09d0d342f83bdadb',
  SEDAR59_WP03_headboat_index.pdf = 'aa455d9a3b392c05d4d03d5f39458685e78d20d4057859efdce36009bb218065',
  SEDAR59_WP04_commercial_handline_index.pdf = 'd2fca1ae1f9933c307d9c1e02e663dd84c8c7755670f710461fb2bea28adcd88'
)
manifest <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE,
  check.names = FALSE)
if (nrow(manifest) != length(expected) || anyDuplicated(manifest$file) ||
    !setequal(manifest$file, names(expected)))
  stop('The Greater Amberjack source manifest is incomplete.', call. = FALSE)
for (file in names(expected)) {
  source_row <- match(file, manifest$file)
  path <- file.path(cache, file)
  if (!file.exists(path) || manifest$retrieved_on[source_row] != '2026-10-31' ||
      as.numeric(manifest$bytes[source_row]) != file.info(path)$size ||
      tolower(manifest$sha256[source_row]) != expected[[file]] ||
      sha256_file(path) != expected[[file]])
    stop('Cached Greater Amberjack source differs from its manifest: ', file, call. = FALSE)
}

noaa_status <- paste(readLines(file.path(cache, 'NOAA_greater_amberjack_resources.html'),
  warn = FALSE), collapse = ' ')
sedar_page <- paste(readLines(file.path(cache, 'SEDAR59_project_page.html'),
  warn = FALSE), collapse = ' ')
if (!grepl('2020', noaa_status, fixed = TRUE) ||
    !grepl('South Atlantic', noaa_status, fixed = TRUE) ||
    !grepl('South Atlantic Greater Amberjack', sedar_page, fixed = TRUE) ||
    !grepl('2017', sedar_page, fixed = TRUE))
  stop('The cached sources do not confirm the SEDAR 59 run identity.', call. = FALSE)

candidates <- read.csv(register_path, stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
row <- match(candidate_id, candidates$candidate_id)
gulf <- match('NOAA:10207', candidates$candidate_id)
if (is.na(row) || sum(candidates$candidate_id == candidate_id, na.rm = TRUE) != 1L ||
    is.na(gulf) || candidates$official_stock_id[row] != '10208' ||
    candidates$scientific_name[row] != 'Seriola dumerili' ||
    candidates$candidate_unit_id[gulf] != 'noaa_gulf_greater_amberjack' ||
    any(candidates$candidate_unit_id[-row] == unit_id, na.rm = TRUE) ||
    any(tolower(stocks$authority_stock_id) == '10208', na.rm = TRUE) ||
    any(stocks$stock_id == unit_id) ||
    any(unit_id %in% c(assessments$stock_id, inputs$assessment_id, outputs$assessment_id),
      na.rm = TRUE))
  stop('The South Atlantic Greater Amberjack identity conflicts with the register or canonical database.',
    call. = FALSE)

review <- list(
  candidate_unit_id = unit_id,
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'eligible',
  import_status = 'not_started',
  assessment_area = 'South Atlantic U.S. EEZ within South Atlantic Fishery Management Council jurisdiction',
  catch_age_evidence = paste('The 2020 SEDAR 59 assessment covers 1980-2017 and uses an integrated catch-age model.',
    'Its final report Table 2 gives annual commercial landings (1000 lb whole weight), recreational landings (1000 fish), and separate discards (1000 fish).',
    'SEDAR59-WP05 Table 3 provides numeric weighted commercial handline age proportions for 1998-2017.',
    'Recreational weighted age compositions are in SEDAR59-WP11 Figures 3-4 and the SAR Figure 3, with sample sizes tabulated; the exact vectors are not tabulated and would need source-supported figure digitization or recovery from underlying data.',
    'Age-specific discards are not reported.'),
  survey_age_evidence = paste('The fitted model uses three annual aggregate indices: headboat (1980-2017), commercial handline (1993-2017), and fishery-independent SERFS video (2011-2017), with annual values and CVs in SAR Table 4.',
    'No age-specific index is used; catch age compositions and aggregate indices support an age-structured assessment.'),
  weights_evidence = 'SAR Table 1 reports input whole weight at age at mid-year in kg and lb for modeled ages 1-10, including the terminal age grouping.',
  maturity_evidence = 'SAR Table 1 reports input female maturity proportion at age and proportion female for modeled ages 1-10.',
  mortality_evidence = 'SAR Table 1 reports age-dependent natural mortality treated as input. The assessment uses the Charnov et al. curve based on updated von Bertalanffy growth; M is not a time-varying estimated process.',
  timing_evidence = paste('All three indices enter as year-level annual observations; the report does not specify one within-year observation fraction.',
    'Index methods retain seasonal structure: headboat data exclude November-April in the terminal closure period, commercial handline standardization uses May-June and July-September seasons, and the video index models season from Julian-day quartiles.',
    'A single tinyAM timing fraction would require an explicit documented approximation.'),
  output_evidence = 'The final SAR reports estimated abundance at age (Table 6, 1000 fish, ages 1-10, 1980-2017), biomass at age (Table 7, 1000 lb), and status outputs including recruitment, SSB, and F (Table 8 and figures).',
  detailed_source_url = paste('https://www.fisheries.noaa.gov/species/greater-amberjack/resources;',
    'https://sedarweb.org/assessments/sedar-59/;',
    'https://apps-st.fisheries.noaa.gov/sis/docServlet?fileAction=download&fileId=5755;',
    'https://sedarweb.org/documents/s59wp05-commercial-age-and-length-composition-weighting-for-u-s-greater-amberjack-seriola-dumerili/;',
    'https://sedarweb.org/documents/s59wp11-south-atlantic-u-s-greater-amberjack-seriola-dummerili-age-and-length-composition-from-the-recreational-fisheries/;',
    'https://sedarweb.org/documents/s59wp01-standardized-video-counts-of-southeast-u-s-atlantic-greater-amberjack-seriola-dumerili-from-the-southeast-reef-fish-survey/;',
    'https://sedarweb.org/documents/s59wp03-standardized-catch-rates-of-greater-amberjack-seriola-dumerili-in-the-southeast-u-s-from-headboat-logbook-data/;',
    'https://sedarweb.org/documents/s59wp04-standardized-catch-rates-of-greater-amberjack-seriola-dumerili-in-the-southeast-u-s-from-commercial-logbook-data/'),
  review_date = '2026-10-31',
  decision_reason = paste('NOAA identifies the South Atlantic stock status as based on the 2020 assessment; SEDAR 59 is the latest completed detailed run located and uses data through 2017.',
    'Catch totals, annual indices, age-specific biology and M assumptions, and comparable age-specific outputs are available in the final report.',
    'Commercial weighted age proportions are numeric; recreational age proportions require figure digitization, and discard age composition and a single within-year index timing fraction are not published in the reviewed sources.',
    'The source quantities support curation as an eligible age-structured case, with these limitations retained for extraction and any later model specification.'),
  notes = paste('NOAA Stock SMART 10208 is the South Atlantic management unit and is distinct from Gulf of Mexico Stock SMART 10207.',
    'The SEDAR 59 final SAR reports a 1980-2017 assessment period; NOAA current resource information still cites the 2020 assessment.',
    'The SEDAR project page and final report, commercial and recreational age-composition working papers, and three index working papers are cached locally with retrieval dates and SHA-256 checksums under source_cache/discovery_noaa_south_atlantic_greater_amberjack_2020.',
    'No canonical database stock, assessment, input or output records were added. Eligibility indicates source-curation suitability; numeric recreational age proportions and exact index timing remain extraction limitations.')
)

is_unreviewed <- candidates$match_status[row] == 'unreviewed' &&
  candidates$screening_status[row] == 'not_started' &&
  candidates$eligibility[row] == 'unresolved' &&
  (is.na(candidates$candidate_unit_id[row]) || !nzchar(candidates$candidate_unit_id[row]))
current <- lapply(names(review), function(column) as.character(candidates[[column]][row]))
names(current) <- names(review)
same_review <- all(vapply(names(review), function(column)
  identical(current[[column]], as.character(review[[column]])), logical(1L)))
if (!is_unreviewed && !same_review)
  stop('NOAA South Atlantic Greater Amberjack candidate already has a conflicting review.', call. = FALSE)
if (!identical(Sys.getenv('TAM_SOURCE_DRY_RUN'), '1') && (is_unreviewed || !same_review)) {
  for (column in names(review)) candidates[[column]][row] <- review[[column]]
  source(file.path(root, 'scripts/database/candidate_register_io.R'))
  replace_candidate_register_row(register_path, row, candidates[row, , drop = FALSE], candidate_id)
}

cat('Screened NOAA South Atlantic Greater Amberjack as eligible for source curation.\n')
