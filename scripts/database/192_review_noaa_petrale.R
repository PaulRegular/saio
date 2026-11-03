root <- "."
path <- file.path(root, 'discovery', 'candidates.csv')
x <- read.csv(path, stringsAsFactors = FALSE, na.strings = 'NA')
i <- which(x$candidate_id == 'NOAA:10011')
if (length(i) != 1L || x$screening_status[i] != 'not_started') stop('Preserve the existing review; candidate state has changed.', call. = FALSE)
x$match_status[i] <- 'new'
x$screening_status[i] <- 'in_progress'
x$catch_age_evidence[i] <- '2023 assessment section 2.1.3 describes expanded commercial age frequencies; determine whether available model inputs permit catch numbers-at-age reconstruction.'
x$survey_age_evidence[i] <- '2023 assessment section 2.2.2.3: West Coast groundfish survey biomass index, conditional age-at-length likelihood and marginal age compositions; marginal compositions were not fitted.'
x$weights_evidence[i] <- '2023 assessment estimates sex-specific growth and weight-length relationships; verify recoverable weight-at-age surfaces.'
x$maturity_evidence[i] <- '2023 assessment section 2.3.2: female maturity as a function of length; verify age-specific values.'
x$mortality_evidence[i] <- '2023 assessment section 2.3.1: natural mortality estimated separately by sex using priors.'
x$timing_evidence[i] <- 'Survey timing needs verification from production inputs or supporting assessment text.'
x$output_evidence[i] <- '2023 assessment provides spawning output, expressed in eggs with confidence intervals, and Stock Synthesis output files; confirm comparable age-specific results.'
x$detailed_source_url[i] <- 'https://www.pcouncil.org/stock-assessments-star-reports-stat-reports-rebuilding-analyses-terms-of-reference/groundfish-stock-assessment-documents/'
x$review_date[i] <- as.character(Sys.Date())
x$decision_reason[i] <- 'US West Coast stock differs from the existing Canadian management unit; published model files found, but reconstruction of needed input scales and common age coverage remains to be verified.'
x$notes[i] <- '2025 inventory year corresponds to catch-only projections of the 2023 assessment; verify latest detailed production run and source inputs.'
lines <- readLines(path, warn = FALSE, encoding = 'UTF-8')
if (length(lines) != nrow(x) + 1L) stop('Multiline CSV rows require a safe update method.', call. = FALSE)
tmp <- tempfile(fileext = '.csv')
write.csv(x[i, , drop = FALSE], tmp, row.names = FALSE, na = '')
lines[i + 1L] <- readLines(tmp, warn = FALSE, encoding = 'UTF-8')[[2L]]
unlink(tmp)
writeLines(lines, path, useBytes = TRUE)
