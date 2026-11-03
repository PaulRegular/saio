path <- file.path('discovery', 'candidates.csv')
x <- read.csv(path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
id <- 'ICES:cod.27.1-2'
i <- which(x$candidate_id == id)
if (length(i) != 1L || x$matched_stock_id[i] != 'ices_cod_northeast_arctic' ||
    x$match_status[i] != 'matched' ||
    !x$screening_status[i] %in% c('not_started', 'screened')) {
  stop('Preserve the existing Northeast Arctic cod identity.', call. = FALSE)
}

x$screening_status[i] <- 'screened'
x$eligibility[i] <- 'eligible'
x$import_status[i] <- 'imported'
x$catch_age_evidence[i] <- paste0(
  'The current 2026 JRN-AFWG SAM run contains catch-at-age for 1946-2025, ages 3-15 ' ,
  'with age 15 as the terminal plus group.'
)
x$survey_age_evidence[i] <- paste0(
  'The native fit contains five age-specific index series with 2,377 fitted observations ' ,
  'through 2026. Survey observations use ages 3-12+; absent age 13-15 survey rows remain absent.'
)
x$weights_evidence[i] <- paste0(
  'Native stock- and catch-weight surfaces cover the model ages and years.'
)
x$maturity_evidence[i] <- paste0(
  'Native age-specific maturity and pre-spawning fractions are recovered.'
)
x$mortality_evidence[i] <- paste0(
  'Age-specific natural mortality is supplied and includes externally iterated cannibalism; ' ,
  'M is fixed in the saved SAM fit.'
)
x$timing_evidence[i] <- paste0(
  'Native survey sampling fractions, landings fractions and pre-spawning F/M fractions are ' ,
  'recovered and retained.'
)
x$output_evidence[i] <- paste0(
  'The 2026 native fit supplies age-specific N, F and M plus aggregate recruitment, TSB, SSB ' ,
  'and Fbar. Report trajectories match all 320 published summary values within rounding; the ' ,
  'optimizer converged and the reported Hessian is positive definite.'
)
x$detailed_source_url[i] <- paste0(
  'https://www.hi.no/hi/nettrapporter/imr-vniro-2026-5; ' ,
  'https://www.hi.no/en/hi/nettrapporter/imr-vniro-en-2026-1; ' ,
  'https://stockassessment.org/datadisk/stockassessment/userdirs/user3/NEAcod_2026_final/'
)
x$review_date[i] <- '2026-10-29'
x$decision_reason[i] <- paste0(
  'The ICES SID row identifies the Northeast Arctic cod unit but shows a 2021 inventory ' ,
  'assessment year. The latest detailed official assessment is the 2026 JRN-AFWG run, conducted ' ,
  'outside ICES but using the same stock code and matching stock unit. The cached native SAM ' ,
  'object provides age-based inputs, timing, fixed mortality and fitted population outputs.'
)
x$notes[i] <- paste0(
  'See source_reviews/ices_cod_northeast_arctic.md. Record the 2026 ' ,
  'JRN-AFWG assessment as the current source; do not interpret the SID inventory year as the ' ,
  'latest production run or apply the advice RCT3 forecast as fitted recruitment.'
)

lines <- readLines(path, warn = FALSE, encoding = 'UTF-8')
if (length(lines) != nrow(x) + 1L) stop('Multiline CSV rows require a safe update method.', call. = FALSE)
tmp <- tempfile(fileext = '.csv')
write.csv(x[i, , drop = FALSE], tmp, row.names = FALSE, na = '')
lines[i + 1L] <- readLines(tmp, warn = FALSE, encoding = 'UTF-8')[[2L]]
unlink(tmp)
writeLines(lines, path, useBytes = TRUE)
cat('Screened Northeast Arctic cod against the current official 2026 JRN-AFWG fit.\n')
