# Record source screening for Northeast Atlantic mackerel.
path <- file.path('discovery', 'candidates.csv')
x <- read.csv(path, stringsAsFactors = FALSE, na.strings = 'NA')
i <- which(x$candidate_id == 'ICES:mac.27.nea')
if (length(i) != 1L || x$match_status[i] != 'unreviewed' || x$screening_status[i] != 'not_started') stop('Preserve the existing review; candidate state has changed.', call. = FALSE)
x$match_status[i] <- 'new'
x$screening_status[i] <- 'in_progress'
x$catch_age_evidence[i] <- '2026 ICES repository data0.01.r reads age-disaggregated catch from cn.dat; numerical input is absent from the public repository archive.'
x$survey_age_evidence[i] <- '2026 advice: IESSNS index ages 3-11 for 2010 and 2012-2026, age 2 for 2018-2026; RFID tagging ages 2-11 for 2013-2025; egg index 1992-2025. Numerical production inputs need recovery.'
x$weights_evidence[i] <- '2026 ICES repository reads stock, catch, landings and discards mean weights by age; numerical input files absent from repository.'
x$maturity_evidence[i] <- '2026 ICES repository reads maturity input mo.dat; numerical input file absent from repository.'
x$mortality_evidence[i] <- '2026 ICES repository reads natural mortality input nm.dat; numerical input file absent from repository.'
x$timing_evidence[i] <- '2026 ICES repository reads survey data and proportions of annual F and M before spawning; exact survey timing requires numerical source inputs.'
x$output_evidence[i] <- '2026 ICES advice key 25875 provides catch scenarios; seek the historical SSB, recruitment, N and F numerical results from that same run.'
x$detailed_source_url[i] <- 'https://github.com/ices-advice/2026_mac.27.nea/tree/708b4fcd2e7b5a14206beec1806015a7fbecbfda/2026_mac.27.nea_assessment'
x$review_date[i] <- '2026-10-28'
x$decision_reason[i] <- 'Northeast Atlantic unit is distinct from the existing Northwest Atlantic mackerel units; the model code identifies age inputs but production data and numerical historical outputs require recovery.'
lines <- readLines(path, warn = FALSE, encoding = 'UTF-8')
if (length(lines) != nrow(x) + 1L) stop('Multiline CSV rows require a safe update method.', call. = FALSE)
tmp <- tempfile(fileext = '.csv')
write.csv(x[i, , drop = FALSE], tmp, row.names = FALSE, na = '')
lines[i + 1L] <- readLines(tmp, warn = FALSE, encoding = 'UTF-8')[[2L]]
unlink(tmp)
writeLines(lines, path, useBytes = TRUE)
