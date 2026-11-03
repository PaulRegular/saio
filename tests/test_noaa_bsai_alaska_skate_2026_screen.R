root <- '.'
cache <- file.path(root, 'source_cache/discovery_noaa_bsai_alaska_skate_2026')
candidate_path <- file.path(root, 'discovery/candidates.csv')
screen_path <- file.path(root, 'scripts/database/458_screen_noaa_bsai_alaska_skate_2026.R')
before <- readLines(candidate_path, warn = FALSE)
old_dry_run <- Sys.getenv('TAM_SOURCE_DRY_RUN', unset = NA_character_)
Sys.setenv(TAM_SOURCE_DRY_RUN = '1')
source(screen_path)
if (is.na(old_dry_run)) Sys.unsetenv('TAM_SOURCE_DRY_RUN') else
  Sys.setenv(TAM_SOURCE_DRY_RUN = old_dry_run)
stopifnot(identical(before, readLines(candidate_path, warn = FALSE)))

register <- read.csv(candidate_path, stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
candidate <- register[register$candidate_id == 'NOAA:10736', , drop = FALSE]
source_manifest <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE)
files <- c('NOAA_2023/BSAIskate_2023_SAFE.pdf',
  'NOAA_2023/F_2026_Groundfish_Stock_Assessment_SSC_Review.pdf',
  'NOAA_2023/data_aksk14_2_2023.ss',
  'NOAA_2023/M14_2NAA_summary.csv',
  'NOAA_2023/M14_2biomass_summary.csv',
  'NOAA_2023/M14_2exploitation_summary.csv',
  'NOAA_2023/M14_2recruit_summary.csv',
  'NOAA_2023/M14_2lengthcomps_summary.csv',
  'NOAA_2024/BSAIintro_2024_SAFE.pdf')
source_rows <- match(files, source_manifest$file)
paths <- file.path(cache, files)
sha256_file <- function(path) {
  output <- system2('certutil.exe',
    c('-hashfile', shQuote(normalizePath(path)), 'SHA256'), stdout = TRUE)
  tolower(trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$',
    output, value = TRUE)))
}
data_lines <- readLines(file.path(cache, 'NOAA_2023/data_aksk14_2_2023.ss'), warn = FALSE)
agecomp_header <- grep('^#_yr month fleet sex part ageerr Lbin_lo Lbin_hi Nsamp datavector',
  trimws(data_lines))
meansize_header <- grep('^#_yr month fleet sex part ageerr ignore datavector',
  trimws(data_lines))
section_rows <- function(lines, header) {
  following <- trimws(lines[seq.int(header + 1L, length(lines))])
  following <- following[nzchar(following) & !startsWith(following, '#')]
  end <- which(grepl('^-9999([[:space:]]|$)', following))[1L]
  following[seq_len(end)]
}
agecomp_rows <- section_rows(data_lines, agecomp_header)
meansize_rows <- section_rows(data_lines, meansize_header)
meansize_years <- as.integer(sub('^([0-9]{4}).*$', '\\1', meansize_rows[-length(meansize_rows)]))
naa <- read.csv(file.path(cache, 'NOAA_2023/M14_2NAA_summary.csv'), check.names = FALSE)
review <- paste(readLines(file.path(root,
  'discovery/source_reviews/noaa_bsai_alaska_skate_2026.md'), warn = FALSE), collapse = '\n')
stocks <- read.csv(file.path(root, 'database/stocks.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database/assessments.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
inputs <- read.csv(file.path(root, 'database/inputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
outputs <- read.csv(file.path(root, 'database/outputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
other_goa_skates <- register[register$candidate_id == 'NOAA:11005', , drop = FALSE]

stopifnot(
  nrow(candidate) == 1L,
  candidate$candidate_unit_id == 'noaa_bsai_alaska_skate',
  candidate$official_stock_id == '10736',
  candidate$scientific_name == 'Bathyraja parmifera',
  candidate$match_status == 'new',
  candidate$screening_status == 'screened',
  candidate$eligibility == 'ineligible',
  candidate$import_status == 'not_started',
  grepl('no fishery age-composition', candidate$catch_age_evidence, fixed = TRUE),
  grepl('length-at-age observations', candidate$survey_age_evidence, fixed = TRUE),
  grepl('ages 0-25', candidate$output_evidence, fixed = TRUE),
  nrow(source_manifest[source_manifest$file %in% files, , drop = FALSE]) == length(files),
  all(file.exists(paths)),
  all(file.info(paths)$size == source_manifest$bytes[source_rows]),
  all(tolower(source_manifest$sha256[source_rows]) == vapply(paths, sha256_file, character(1L))),
  length(agecomp_header) == 1L,
  length(agecomp_rows) == 1L,
  grepl('^-9999([[:space:]]|$)', agecomp_rows),
  identical(meansize_years, c(2003L, 2007L, 2008L, 2009L, 2015L)),
  identical(names(naa), c('Yr', as.character(0:25))),
  identical(as.integer(naa$Yr), 1948:2028),
  nrow(other_goa_skates) == 1L,
  other_goa_skates$official_stock_id == '11005',
  other_goa_skates$candidate_unit_id == 'noaa_goa_other_skates',
  other_goa_skates$screening_status == 'screened',
  other_goa_skates$eligibility == 'ineligible',
  !any(stocks$stock_id == 'noaa_bsai_alaska_skate', na.rm = TRUE),
  !any(stocks$authority_stock_id == '10736', na.rm = TRUE),
  !any(tolower(stocks$scientific_name) == 'bathyraja parmifera', na.rm = TRUE),
  !any(assessments$assessment_id == 'noaa_bsai_alaska_skate', na.rm = TRUE),
  !any(inputs$assessment_id == 'noaa_bsai_alaska_skate', na.rm = TRUE),
  !any(outputs$assessment_id == 'noaa_bsai_alaska_skate', na.rm = TRUE),
  grepl('2023 operational update', review, fixed = TRUE),
  grepl('were proposed alternatives', review, fixed = TRUE),
  grepl('December 2026', review, fixed = TRUE),
  grepl('stale comment', review, fixed = TRUE)
)

cat('NOAA BSAI Alaska skate screening checks passed.\n')
