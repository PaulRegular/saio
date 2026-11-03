# Record the 2026 Bay of Biscay sole discovery review without importing source data.
root <- "."
path <- file.path(root, 'discovery', 'candidates.csv')
x <- read.csv(path, stringsAsFactors = FALSE, na.strings = 'NA')
i <- which(x$candidate_id == 'ICES:sol.27.8ab')
if (length(i) != 1L) stop('Expected one ICES sole 8ab candidate.', call. = FALSE)
if (x$screening_status[i] != 'not_started' || x$match_status[i] != 'unreviewed') stop('Candidate already reviewed; preserve its existing review.', call. = FALSE)
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'), stringsAsFactors = FALSE)
if (any(tolower(stocks$authority_stock_id) == 'sol.27.8ab', na.rm = TRUE)) stop('Existing stock code needs manual reconciliation.', call. = FALSE)
rev <- 'e6b6c484f6c50e1199097682ca6b451f8232e235'
repo <- paste0('https://github.com/ices-advice/2026_sol.27.8ab/tree/', rev, '/2026_sol.27.8ab_assessment')
x$match_status[i] <- 'new'
x$screening_status[i] <- 'in_progress'
x$eligibility[i] <- 'unresolved'
x$catch_age_evidence[i] <- '2026 model.R uses stock.rds catch numbers at ages 2-8+; input object absent from public repository archive.'
x$survey_age_evidence[i] <- '2026 model.R uses French BTS VIII survey ages and a French trawler biomass index; referenced input objects absent from public repository archive.'
x$weights_evidence[i] <- '2026 model.R reads stock, catch, landings and discard weights from stock.rds; numeric object not recovered.'
x$maturity_evidence[i] <- '2026 model.R reads maturity at age from stock.rds; numeric object not recovered.'
x$mortality_evidence[i] <- '2026 model.R reads natural mortality at age from stock.rds; numeric object not recovered.'
x$timing_evidence[i] <- 'data.R specifies French trawler 0.1 to 2/12 and BTS VIII 11/12 to 1 of a year.'
x$output_evidence[i] <- 'ICES 2026 advice reports projected SSB and fishing-mortality scenarios; historical output series remain to be recovered; assessment key 22607: https://asd.ices.dk/viewAdvice/5103.'
x$detailed_source_url[i] <- repo
x$review_date[i] <- as.character(Sys.Date())
x$decision_reason[i] <- 'New stock unit by official ICES code and area; eligibility unresolved until actual production-run input objects and coverage are recovered.'
lines <- readLines(path, warn = FALSE, encoding = 'UTF-8')
if (length(lines) != nrow(x) + 1L) stop('Multiline CSV rows require a safe update method.', call. = FALSE)
tmp <- tempfile(fileext = '.csv')
write.csv(x[i, , drop = FALSE], tmp, row.names = FALSE, na = '')
lines[i + 1L] <- readLines(tmp, warn = FALSE, encoding = 'UTF-8')[[2L]]
unlink(tmp)
writeLines(lines, path, useBytes = TRUE)
cat('Recorded partial source review for ICES sole 8ab.\n')