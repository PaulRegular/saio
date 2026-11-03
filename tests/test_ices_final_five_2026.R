root <- "."
register <- read.csv(file.path(root, 'discovery', 'candidates.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
lookup <- function(id) {
  x <- register[register$candidate_id == id, , drop = FALSE]
  stopifnot(nrow(x) == 1L)
  x
}
nac <- lookup('ICES:sal.nac.all')
neac <- lookup('ICES:sal.neac.all')
wgc <- lookup('ICES:sal.wgc.all')
anglerfish <- lookup('ICES:anf.27.1-2')
thresher <- lookup('ICES:thr.27.nea')
joint_id <- 'ices_wgnas_north_atlantic_salmo_salar'
stopifnot(nac$candidate_unit_id == joint_id, neac$candidate_unit_id == joint_id,
  nac$match_status == 'new', neac$match_status == 'new',
  nac$screening_status == 'screened', neac$screening_status == 'screened',
  nac$eligibility == 'eligible', neac$eligibility == 'eligible',
  nac$import_status == 'not_started', neac$import_status == 'not_started',
  is.na(nac$matched_stock_id), is.na(neac$matched_stock_id),
  wgc$match_status == 'ambiguous', wgc$screening_status == 'screened',
  wgc$eligibility == 'ineligible', is.na(wgc$candidate_unit_id),
  anglerfish$match_status == 'new', anglerfish$screening_status == 'screened',
  anglerfish$eligibility == 'ineligible',
  thresher$match_status == 'new', thresher$screening_status == 'screened',
  thresher$eligibility == 'ineligible')

unit_path <- file.path(root, 'discovery', 'inventory_units.csv')
units <- read.csv(unit_path, stringsAsFactors = FALSE, check.names = FALSE)
joint <- units[units$unit_key == paste0('candidate:', joint_id), , drop = FALSE]
stopifnot(nrow(joint) == 1L, joint$inventory_entries == 2L,
  grepl('ICES:sal.nac.all', joint$candidate_ids, fixed = TRUE),
  grepl('ICES:sal.neac.all', joint$candidate_ids, fixed = TRUE),
  !('ICES:sal.wgc.all' %in% units$candidate_ids))

cache <- file.path(root, 'source_cache', 'discovery_ices_remaining_units_2026')
if (file.exists(file.path(cache, 'sources.csv'))) {
  manifest <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE,
    check.names = FALSE)
required <- c('ices_wgnas_2026_report.pdf', 'wgnas_2026_section2_tables.zip',
  'wgnas_2026_neac_tables.zip', 'wgnas_2026_nac_tables.zip',
  'wgnas_2026_wgc_tables.zip', 'imr_anglerfish_advice_2026.pdf',
  'ices_wgef_2023_report.pdf', 'ices_wgef_2024_report.pdf')
stopifnot(!anyDuplicated(manifest$file), all(required %in% manifest$file),
  all(manifest$retrieved_on[match(required, manifest$file)] == '2026-11-01'),
  all(nzchar(manifest$url[match(required, manifest$file)])),
  all(nzchar(manifest$sha256[match(required, manifest$file)])))

sha256_file <- function(path) {
  if (requireNamespace('digest', quietly = TRUE))
    return(tolower(digest::digest(file = path, algo = 'sha256')))
  output <- system2('certutil.exe',
    c('-hashfile', shQuote(normalizePath(path, winslash = '\\', mustWork = TRUE)), 'SHA256'),
    stdout = TRUE)
  tolower(trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$', output, value = TRUE)))
}
for (name in required) {
  row <- manifest[manifest$file == name, , drop = FALSE]
  path <- file.path(cache, name)
  stopifnot(file.exists(path), file.info(path)$size == row$bytes,
    identical(sha256_file(path), row$sha256))
}

find_table <- function(pattern) {
  paths <- list.files(cache, pattern = '\\.csv$', recursive = TRUE, full.names = TRUE)
  hits <- paths[grepl(pattern, basename(paths), ignore.case = TRUE)]
  stopifnot(length(hits) == 1L)
  hits
}
catch <- read.csv(find_table('Table 2\\.1\\.1\\.3.*nominal catches by sea age'),
  stringsAsFactors = FALSE)
nac_pfa <- read.csv(find_table('Table 4\\.3\\.6\\.1.*NAC PFA'),
  stringsAsFactors = FALSE)
neac_pfa <- read.csv(find_table('Table 3\\.3\\.5\\.1.*PFA 1SW maturing N-NEAC'),
  stringsAsFactors = FALSE)
catch_year <- as.numeric(catch$year)
nac_year <- suppressWarnings(as.numeric(as.character(nac_pfa$year)))
neac_year <- suppressWarnings(as.numeric(as.character(neac_pfa$year)))
stopifnot(all(c('number_1sw', 'number_2sw', 'weight_1sw', 'weight_2sw') %in% names(catch)),
  min(catch_year, na.rm = TRUE) == 1980, max(catch_year, na.rm = TRUE) == 2025,
  max(nac_year, na.rm = TRUE) == 2024, max(neac_year, na.rm = TRUE) == 2029,
  any(neac_pfa$statistic == 'Hindcast' & neac_year <= 2025, na.rm = TRUE))
}

review_path <- file.path(root, 'discovery', 'source_reviews', 'ices_final_five_2026.md')
review <- paste(readLines(review_path, warn = FALSE), collapse = ' ')
stopifnot(file.exists(review_path), grepl('joint stage-based', review, fixed = TRUE),
  grepl('superseded by 2026', review, fixed = TRUE),
  grepl('32034120', review, fixed = TRUE),
  grepl('rapport-fra-havforskningen-2025-79', review, fixed = TRUE),
  grepl('26935504', review, fixed = TRUE),
  grepl('JABBA', review, fixed = TRUE), grepl('category 6.3', review, fixed = TRUE))

stocks <- read.csv(file.path(root, 'database', 'stocks.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
stopifnot(!any(c('sal.nac.all', 'sal.neac.all', 'sal.wgc.all', 'anf.27.1-2', 'thr.27.nea') %in%
    stocks$authority_stock_id),
  !any(c('ices_wgnas_north_atlantic_salmo_salar', 'ices_anf_27_1_2', 'ices_thr_27_nea') %in%
    assessments$stock_id),
  is.data.frame(inputs), is.data.frame(outputs))

cat('ICES final-five source, identity, eligibility, and no-import checks passed.\n')
