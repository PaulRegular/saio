root <- "."
path <- file.path(root, 'discovery', 'candidates.csv')
x <- read.csv(path, stringsAsFactors = FALSE, na.strings = 'NA')
i <- which(x$candidate_id == 'DFO:Maritimes:Atlantic Cod - NAFO 4X5Y')
if (length(i) != 1L || x$screening_status[i] != 'not_started') stop('Preserve the existing review; candidate state has changed.', call. = FALSE)
x$scientific_name[i] <- 'Gadus morhua'
x$assessment_area[i] <- 'NAFO 4X5Y'
x$match_status[i] <- 'new'
x$screening_status[i] <- 'in_progress'
x$catch_age_evidence[i] <- 'DFO SAR 2026/016 Fig. 2 depicts groundfish catch at age; source values and lobster-bycatch inputs for the 2024-data WHAM run need recovery.'
x$survey_age_evidence[i] <- 'DFO SAR 2026/016 Fig. 2 depicts summer survey abundance at age; 1983-2024 data are listed, but source values remain to be recovered.'
x$weights_evidence[i] <- '2022/006 documents previous framework inputs; 2024-data run-specific weights remain to be verified.'
x$maturity_evidence[i] <- '2024-data WHAM maturity inputs remain to be recovered.'
x$mortality_evidence[i] <- 'DFO SAR 2026/016 reports estimated natural mortality at age and Fig. 2; exact input and fitted age series remain to be recovered.'
x$timing_evidence[i] <- 'DFO SAR 2026/016 identifies the summer ecosystem survey; precise timing remains to be verified.'
x$output_evidence[i] <- 'DFO SAR 2026/016 Fig. 1 plots SSB and age-1 abundance with 95% intervals; 2025 SSB is 2,666 mt and 2024 age-1 abundance is 0.94 million; full numeric series remain to be recovered.'
x$detailed_source_url[i] <- 'https://publications.gc.ca/collections/collection_2026/mpo-dfo/fs70-6/Fs70-6-2026-016-eng.pdf'
x$review_date[i] <- as.character(Sys.Date())
x$decision_reason[i] <- 'New 4X5Y stock unit; the 2026 advice identifies an updated WHAM assessment but its detailed numerical inputs and outputs require further source search.'
x$notes[i] <- 'The 2026 report switches from VPA to WHAM and cites a framework in preparation; do not substitute 2018-framework inputs for the current run.'
lines <- readLines(path, warn = FALSE, encoding = 'UTF-8')
if (length(lines) != nrow(x) + 1L) stop('Multiline CSV rows require a safe update method.', call. = FALSE)
tmp <- tempfile(fileext = '.csv')
write.csv(x[i, , drop = FALSE], tmp, row.names = FALSE, na = '')
lines[i + 1L] <- readLines(tmp, warn = FALSE, encoding = 'UTF-8')[[2L]]
unlink(tmp)
writeLines(lines, path, useBytes = TRUE)
