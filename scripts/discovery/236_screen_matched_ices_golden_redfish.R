path <- file.path('discovery', 'candidates.csv')
x <- read.csv(path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
id <- 'ICES:reg.27.1-2'
i <- which(x$candidate_id == id)
if (length(i) != 1L || x$matched_stock_id[i] != 'ck_ices_afwg_norvegicus_deep1_2' ||
    x$match_status[i] != 'matched' ||
    !x$screening_status[i] %in% c('not_started', 'screened')) {
  stop('Preserve the existing Northeast Arctic golden redfish identity.', call. = FALSE)
}

x$screening_status[i] <- 'screened'
x$eligibility[i] <- 'ineligible'
x$import_status[i] <- 'imported'
x$catch_age_evidence[i] <- paste0(
  'The current 2026 assessment uses total commercial landings in tonnes for 1908-2025; ',
  'it does not fit catch-at-age. The historical age-length Gadget assessment was replaced.'
)
x$survey_age_evidence[i] <- paste0(
  'The current SPiCT model uses an aggregate bottom-trawl biomass index for redfish over ',
  '30 cm, 1991-2025. Numerical index rows and age-specific abundance observations were not recovered.'
)
x$weights_evidence[i] <- paste0(
  'Age-specific weights are not inputs to the current aggregate SPiCT assessment.'
)
x$maturity_evidence[i] <- paste0(
  'Age-specific maturity is not an input to the current aggregate SPiCT assessment.'
)
x$mortality_evidence[i] <- paste0(
  'The current SPiCT assessment estimates aggregate production dynamics; age-specific M ',
  'is not part of the selected assessment.'
)
x$timing_evidence[i] <- paste0(
  'An age-structured survey sampling fraction is not applicable to the current aggregate ',
  'index; its exact production observation times are not recovered.'
)
x$output_evidence[i] <- paste0(
  'Official outputs are relative B/BMSY through 2026 and F/FMSY through 2025. Absolute ',
  'biomass, recruitment, F-at-age, M-at-age and N-at-age are not reported for the current model.'
)
x$detailed_source_url[i] <- paste0(
  'https://doi.org/10.17895/ices.advice.30932315.v1; ',
  'https://doi.org/10.17895/ices.pub.32134696; ',
  'https://doi.org/10.17895/ices.pub.32019630; ',
  'https://standardgraphs.ices.dk/ViewSourceData.aspx?key=23725'
)
x$review_date[i] <- '2026-10-29'
x$decision_reason[i] <- paste0(
  'Matched to the current Northeast Arctic golden redfish unit. The 2026 official assessment ',
  'replaced the historical age-length Gadget model with category-2 SPiCT using aggregate ',
  'catch and biomass information. It is ineligible for the current age-structured screen; ',
  'the relative B/BMSY and F/FMSY outputs remain imported as native aggregate measures.'
)
x$notes[i] <- paste0(
  'See source_reviews/ices_golden_redfish_northeast_arctic.md. ',
  'Do not use the historical age-length model label to infer age-structured inputs for the ',
  'current assessment; no age allocation or absolute biomass scaling is introduced.'
)

lines <- readLines(path, warn = FALSE, encoding = 'UTF-8')
if (length(lines) != nrow(x) + 1L) stop('Multiline CSV rows require a safe update method.', call. = FALSE)
tmp <- tempfile(fileext = '.csv')
write.csv(x[i, , drop = FALSE], tmp, row.names = FALSE, na = '')
lines[i + 1L] <- readLines(tmp, warn = FALSE, encoding = 'UTF-8')[[2L]]
unlink(tmp)
writeLines(lines, path, useBytes = TRUE)
cat('Screened matched Northeast Arctic golden redfish under its current aggregate SPiCT method.\n')
