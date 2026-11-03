# Record 2026 WGBIE tables and unresolved input-definition discrepancies.
root <- "."
path <- file.path(root, 'discovery', 'candidates.csv')
x <- read.csv(path, stringsAsFactors = FALSE, na.strings = 'NA')
i <- which(x$candidate_id == 'ICES:sol.27.8ab')
if (length(i) != 1L || x$screening_status[i] != 'in_progress' || x$eligibility[i] != 'unresolved') stop('Preserve the existing review; candidate state has changed.', call. = FALSE)
url <- 'https://doi.org/10.17895/ices.pub.32790321.v1'
x$catch_age_evidence[i] <- paste('WGBIE 2026 Table 7.4: catch numbers at ages 2-8+, 1984-2025; table does not state its numerical multiplier.', url)
x$survey_age_evidence[i] <- paste('WGBIE 2026 Table 7.7: French BTS VIII standardized indices ages 2-7, 2007-2025; Table 7.8 trawler biomass index, 2010-2025.', url)
x$weights_evidence[i] <- paste('WGBIE 2026 Tables 7.5-7.6: catch and stock weights at ages 2-8+, 1984-2025, kg.', url)
x$maturity_evidence[i] <- paste('WGBIE 2026 Table 7.2: maturity ages 2-8+; fixed ogive.', url)
x$mortality_evidence[i] <- paste('WGBIE 2026 Table 7.3 and section 7.4.2 disagree at ages 5 and 7; the 2024 benchmark Table 4.1 corroborates the settings vector, but the actual 2026 production input is unresolved.', url)
x$timing_evidence[i] <- '2026 ICES repository data.R gives French trawler 0.1 to 2/12 and BTS VIII 11/12 to 1 of a year.'
x$output_evidence[i] <- paste('WGBIE 2026 Tables 7.11, 7.14 and 7.15 report SSB, recruitment, F and N by age; Table 7.11 labels intervals as 90%.', url)
x$review_date[i] <- as.character(Sys.Date())
x$decision_reason[i] <- 'New ICES stock unit; numerical source tables identified, but catch scale and conflicting mortality values require verification before eligibility.'
lines <- readLines(path, warn = FALSE, encoding = 'UTF-8')
if (length(lines) != nrow(x) + 1L) stop('Multiline CSV rows require a safe update method.', call. = FALSE)
tmp <- tempfile(fileext = '.csv')
write.csv(x[i, , drop = FALSE], tmp, row.names = FALSE, na = '')
lines[i + 1L] <- readLines(tmp, warn = FALSE, encoding = 'UTF-8')[[2L]]
unlink(tmp)
writeLines(lines, path, useBytes = TRUE)
cat('Recorded numerical WGBIE source tables and unresolved definitions.\n')