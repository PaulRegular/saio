# Record the 2026 official historical summary, distinct from forecast scenarios.
path <- file.path('discovery', 'candidates.csv')
x <- read.csv(path, stringsAsFactors = FALSE, na.strings = 'NA')
i <- which(x$candidate_id == 'ICES:mac.27.nea')
if (length(i) != 1L || x$screening_status[i] != 'in_progress' || x$eligibility[i] != 'unresolved') stop('Preserve the existing review; candidate state has changed.', call. = FALSE)
x$output_evidence[i] <- 'ICES SAG key 25875 reports historical SSB and total biomass in tonnes, age-2 recruitment in thousands, and F ages 4-8 for 1998-2025, with low and high values; some 2026 outputs also reported. Interval definition needs verification.'
lines <- readLines(path, warn = FALSE, encoding = 'UTF-8')
if (length(lines) != nrow(x) + 1L) stop('Multiline CSV rows require a safe update method.', call. = FALSE)
tmp <- tempfile(fileext = '.csv')
write.csv(x[i, , drop = FALSE], tmp, row.names = FALSE, na = '')
lines[i + 1L] <- readLines(tmp, warn = FALSE, encoding = 'UTF-8')[[2L]]
unlink(tmp)
writeLines(lines, path, useBytes = TRUE)
