# Cross-check the working-group summary against the published assessment graph.
path <- file.path('discovery', 'candidates.csv')
x <- read.csv(path, stringsAsFactors = FALSE, na.strings = 'NA')
i <- which(x$candidate_id == 'ICES:sol.27.7a')
if (length(i) != 1L || x$screening_status[i] != 'in_progress' || x$eligibility[i] != 'unresolved') stop('Preserve the existing review; candidate state has changed.', call. = FALSE)
x$output_evidence[i] <- 'WGCSE 2026 Tables 19.13-19.16 provide F and N at age and annual summaries; SAG key 22641 reproduces the 2024 and 2025 recruitment, SSB and F summaries and identifies the 2026 advice assessment.'
x$decision_reason[i] <- 'Irish Sea sole is not represented by the existing sole stock areas. Historical output matches 2026 advice key 22641; the numerical time-varying maturity input remains unresolved.'
lines <- readLines(path, warn = FALSE, encoding = 'UTF-8')
if (length(lines) != nrow(x) + 1L) stop('Multiline CSV rows require a safe update method.', call. = FALSE)
tmp <- tempfile(fileext = '.csv')
write.csv(x[i, , drop = FALSE], tmp, row.names = FALSE, na = '')
lines[i + 1L] <- readLines(tmp, warn = FALSE, encoding = 'UTF-8')[[2L]]
unlink(tmp)
writeLines(lines, path, useBytes = TRUE)
