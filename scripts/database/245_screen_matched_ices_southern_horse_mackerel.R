path <- file.path('discovery', 'candidates.csv')
x <- read.csv(path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
id <- 'ICES:hom.27.9a'
i <- which(x$candidate_id == id)
if (length(i) != 1L || x$matched_stock_id[i] != 'ck_ices_wghansa_trachurus_sp9a' ||
    x$match_status[i] != 'matched' ||
    !x$screening_status[i] %in% c('not_started', 'screened')) {
  stop('Preserve the existing Southern horse mackerel identity.', call. = FALSE)
}

x$screening_status[i] <- 'screened'
x$eligibility[i] <- 'unresolved'
x$import_status[i] <- 'imported'
x$catch_age_evidence[i] <- paste0(
  'The latest detailed official assessment is WGHANSA 2024, with combined Portuguese-Spanish ' ,
  'catch-at-age for 1992-2023, ages 0-11+, in thousands of fish. Age 0 is excluded from the ' ,
  'official catch input.'
)
x$survey_age_evidence[i] <- paste0(
  'Portuguese-Spanish IBTS abundance-at-age covers 1992-2023, ages 0-11+, in number per hour; ' ,
  'the combined series is unavailable in 2012, 2019 and 2020, and age 0 is excluded. The numeric ' ,
  'commercial CPUE and aggregate IBTS biomass series were not recovered.'
)
x$weights_evidence[i] <- paste0(
  'Catch and stock weights cover 1992-2023, ages 0-11+, in kg per fish; stock weights equal ' ,
  'catch weights in the source assessment.'
)
x$maturity_evidence[i] <- paste0(
  'A time-invariant female maturity ogive is used for the combined-sex model.'
)
x$mortality_evidence[i] <- paste0(
  'Natural mortality is fixed by age from the Gislason method.'
)
x$timing_evidence[i] <- paste0(
  'The recovered detailed report does not provide an exact sampling time for the age-specific ' ,
  'IBTS series; a timing choice would need an explicit approximation.'
)
x$output_evidence[i] <- paste0(
  'The 2024 report provides aggregate SSB, recruitment, F(1-10) and FApical with CVs, but ' ,
  'no numerical age-specific N/F outputs. The separate 2026 SAG series is summary-only and ' ,
  'does not supply current age inputs.'
)
x$detailed_source_url[i] <- paste0(
  'https://doi.org/10.17895/ices.pub.26003356.v3; ' ,
  'https://doi.org/10.17895/ices.pub.25002482.v2; ' ,
  'https://sg.ices.dk/ViewSourceData.aspx?key=23760'
)
x$review_date[i] <- '2026-10-29'
x$decision_reason[i] <- paste0(
  'Matched to the current detailed stock record, whose latest age-based production assessment ' ,
  'is 2024; the newer 2026 entry is summary-only. Age-specific catch, IBTS index, fixed M and ' ,
  'maturity are imported, but exact survey timing, numeric commercial CPUE and age-specific ' ,
  'population outputs are unavailable. Eligibility remains unresolved for the full screening criteria.'
)
x$notes[i] <- paste0(
  'See source_reviews/ices_horse_mackerel_9a.md. Do not present the ' ,
  '2026 SAG summary as a detailed assessment or infer age-specific outputs from aggregate results.'
)

lines <- readLines(path, warn = FALSE, encoding = 'UTF-8')
if (length(lines) != nrow(x) + 1L) stop('Multiline CSV rows require a safe update method.', call. = FALSE)
tmp <- tempfile(fileext = '.csv')
write.csv(x[i, , drop = FALSE], tmp, row.names = FALSE, na = '')
lines[i + 1L] <- readLines(tmp, warn = FALSE, encoding = 'UTF-8')[[2L]]
unlink(tmp)
writeLines(lines, path, useBytes = TRUE)
cat('Screened matched Southern horse mackerel; missing timing and output details remain unresolved.\n')
