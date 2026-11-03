# Screen the North Sea witch assessment against its 2026 report and code.
path <- file.path('discovery', 'candidates.csv')
x <- read.csv(path, stringsAsFactors = FALSE, na.strings = 'NA')
i <- which(x$candidate_id == 'ICES:wit.27.3a47d')
if (length(i) != 1L || x$match_status[i] != 'unreviewed' || x$screening_status[i] != 'not_started') stop('Preserve the existing review; candidate state has changed.', call. = FALSE)
x$match_status[i] <- 'new'
x$screening_status[i] <- 'in_progress'
x$catch_age_evidence[i] <- 'WGNSSK 2026 Table 23.4 reports catch numbers-at-age 1-10+ for 2009-2025; table multiplier requires confirmation. Historical total landings are used for 1950-2008.'
x$survey_age_evidence[i] <- 'WGNSSK 2026 section 23.3: IBTS Q1 biomass indices at ages 2-7+ and combined IBTS+BTS Q3 at ages 2-6+, 2009-2025. Numerical age matrices referenced in public SAM data directory; download currently resets connection.'
x$weights_evidence[i] <- 'WGNSSK 2026 Tables 23.5a-c report landing, discard and catch weights by age in kg; Table 23.6 gives fixed stock weights-at-age.'
x$maturity_evidence[i] <- 'WGNSSK 2026 Table 23.7 reports fixed maturity ogive; age 10+ uses mean of ages 10-12, 0.851.'
x$mortality_evidence[i] <- 'WGNSSK 2026 section 23.2.4 assumes M=0.2 per year for all ages and years.'
x$timing_evidence[i] <- 'WGNSSK 2026 identifies Q1 and Q3 surveys; precise observation timing in the model data still needs verification.'
x$output_evidence[i] <- 'WGNSSK 2026 Tables 23.8-23.10 report annual summaries and F and N at age; ICES SAG key 22534 identifies the advice series.'
x$detailed_source_url[i] <- 'https://doi.org/10.17895/ices.pub.32676345.v2'
x$review_date[i] <- '2026-10-28'
x$decision_reason[i] <- 'North Sea witch is geographically distinct from the existing Northwest Atlantic witch records. Confirm numerical survey-age matrices, timing and catch scale before classifying eligibility.'
x$notes[i] <- 'Public ICES code names wit.27.3a47d_2026 on stockassessment.org as data and configuration source. Connection reset during retrieval does not establish unavailability.'
lines <- readLines(path, warn = FALSE, encoding = 'UTF-8')
if (length(lines) != nrow(x) + 1L) stop('Multiline CSV rows require a safe update method.', call. = FALSE)
tmp <- tempfile(fileext = '.csv')
write.csv(x[i, , drop = FALSE], tmp, row.names = FALSE, na = '')
lines[i + 1L] <- readLines(tmp, warn = FALSE, encoding = 'UTF-8')[[2L]]
unlink(tmp)
writeLines(lines, path, useBytes = TRUE)
