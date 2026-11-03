root <- '.'
register <- read.csv(file.path(root, 'discovery', 'candidates.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'), stringsAsFactors = FALSE)
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'), stringsAsFactors = FALSE)
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'), stringsAsFactors = FALSE)
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'), stringsAsFactors = FALSE)

candidate <- register[register$candidate_id ==
  'DFO:Pacific:Sockeye Salmon - Fraser (Early Stuart)', , drop = FALSE]
unit_id <- 'dfo_fraser_sockeye_early_stuart'
review_path <- file.path(root, 'discovery', 'source_reviews',
  'dfo_fraser_sockeye_early_stuart.md')
cache <- file.path(root, 'source_cache', 'discovery_dfo_fraser_sockeye')
manifest <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE)
files <- file.path(cache, manifest$file)

stopifnot(
  nrow(candidate) == 1L,
  candidate$candidate_unit_id == unit_id,
  candidate$scientific_name == 'Oncorhynchus nerka',
  is.na(candidate$inventory_assessment_year),
  candidate$match_status == 'new',
  candidate$screening_status == 'screened',
  candidate$eligibility == 'ineligible',
  candidate$import_status == 'not_started',
  grepl('not original fishery catch numbers-at-age', candidate$catch_age_evidence, fixed = TRUE),
  grepl('not survey observations', candidate$survey_age_evidence, fixed = TRUE),
  grepl('1950-2025', candidate$output_evidence, fixed = TRUE),
  !unit_id %in% stocks$stock_id,
  !unit_id %in% assessments$assessment_id,
  !unit_id %in% inputs$assessment_id,
  !unit_id %in% outputs$assessment_id,
  file.exists(review_path),
  nrow(manifest) == 4L,
  all(file.exists(files)),
  all(file.info(files)$size == manifest$bytes),
  all(manifest$retrieved_on == '2026-10-30'),
  identical(as.character(manifest$sha256), c(
    '26E40797893EAB19320D2F89A7F8FA92B8FBFED67018196A5D71DF98F2D2D205',
    '92922DB4F16F48B6B3E0B6A1C5A7C2A6992294BD1F32F4FDED760AD0EA12BDAE',
    '6D1C0B6042ABF5CA9D3AE8A95F42238D55A20EB6F24980FA7982259F006AE14E',
    '799730465B2320F3E8D40453B6E1FD6BAFD62E0048156EEC0227D59CC9BFA15F'
  ))
)

production <- read.csv(files[grepl('detailed-format.csv$', files)],
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
early_stuart <- production[production$production_stock_name == 'Early Stuart', ]
latest <- early_stuart[!is.na(early_stuart$returnyr) & early_stuart$returnyr == 2025, ]
review <- paste(readLines(review_path, warn = FALSE), collapse = ' ')
stopifnot(
  nrow(early_stuart) == 955L,
  min(early_stuart$returnyr, na.rm = TRUE) == 1950L,
  max(early_stuart$returnyr, na.rm = TRUE) == 2025L,
  setequal(unique(early_stuart$age[!is.na(early_stuart$age)]),
    c(21L, 31L, 32L, 41L, 42L, 43L, 51L, 52L, 53L, 62L, 63L, 64L, 72L)),
  nrow(latest) == 13L,
  all(latest$run_size_type == 'in-season-based'),
  sum(!is.na(latest$num_recruits)) == 2L,
  grepl('not a fitted N-at-age surface', review, fixed = TRUE),
  grepl('No canonical stock, assessment, input or output records were added.', review, fixed = TRUE),
  grepl('age-input candidate set', review, fixed = TRUE)
)

cat('DFO Fraser Early Stuart identity, source coverage and eligibility checks passed.\n')
