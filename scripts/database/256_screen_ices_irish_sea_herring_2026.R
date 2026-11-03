path <- file.path('discovery', 'candidates.csv')
x <- read.csv(path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
id <- 'ICES:her.27.nirs'
i <- match(id, x$candidate_id)
if (is.na(i)) stop(paste('Expected candidate is missing:', id), call. = FALSE)
updates <- list(
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'eligible',
  import_status = 'not_started',
  catch_age_evidence = 'HAWG 2026 Table 8.2.1.2 reports catch-at-age in thousands for winter-ring ages 1-8+ from 1980-2025; 2009 has no estimate.',
  survey_age_evidence = 'HAWG 2026 Table 8.3.1 reports ISAS age-specific abundance in thousands for winter-ring ages 1-8+ from 1994-2025. A second acoustic series, ISSS, supplies an aggregate SSB index from 2007-2025 (Table 8.3.2).',
  weights_evidence = 'Tables 8.5.1-8.5.2 give catch and spawning-stock weights-at-age in kg; stock weights use Q3 catches and catch weights use all seasons. 2009 is the mean of 2008 and 2010.',
  maturity_evidence = 'Table 8.5.3 provides annual maturity-at-age ogives from Q3 catch biology, ages 1-8+, 1980-2025; 2009 is the mean of 2008 and 2010.',
  mortality_evidence = 'Table 8.5.4 provides fixed age-specific M values borrowed from North Sea herring for all years: 0.787, 0.380, 0.353, 0.335, 0.315, 0.311, 0.304 and 0.304 for ages 1-8+.',
  timing_evidence = 'ISAS is conducted in late August-September (2025: 26 Aug-19 Sep with some transects completed 7-9 Oct); ISSS is conducted in late September/early October. Reported survey dates support seasonal timing approximations, but exact annual SAM observation-time fractions are not stated in the report.',
  output_evidence = 'HAWG 2026 Table 8.7.1.1 and ICES SAG key 21319 provide annual age-1 recruitment, SSB, Fbar ages 2-4, total catch and 95% intervals through 2025. Numeric fitted N/F-at-age arrays were not recovered in these public output tables.',
  detailed_source_url = 'https://doi.org/10.17895/ices.pub.31424315; https://standardgraphs.ices.dk/ViewCharts.aspx?key=21319; https://standardgraphs.ices.dk/ViewSourceData.aspx?key=21319; https://doi.org/10.17895/ices.advice.32133760.v1',
  review_date = '2026-10-29',
  decision_reason = 'Eligible for source curation: the 2026 official SAM assessment report provides numerical catch-at-age, age-specific ISAS acoustic abundance, a second SSB index, catch/stock weights, annual maturity ogives, fixed age-specific M, seasonal survey dates, and comparable annual SSB, recruitment and F outputs with 95% intervals. The report identifies approximations needed for survey timing and reports unresolved stock mixing and estimated acoustic survey catchabilities ranging from 2.7 to 4.9. The latest public ICES-advice GitHub snapshot located is from 2024 and predates the model configuration reviews; use the 2026 report and SAG outputs as the production-run sources.',
  notes = 'No canonical stock matches ICES her.27.nirs. The distinct northern 7.a stock unit is not the Celtic Sea her.27.irls unit south of 52°30\'N or the existing 6.a/7.b-c herring records. HAWG treats the Irish Sea fishery and surveys as a mixed stock including Celtic Sea herring; the extent is unresolved. Cache folder discovery_ices_irish_sea_herring_2026/ holds ICES SAG outputs; the shared 2026 HAWG report is cached under discovery_ices_celtic_sea_herring_2026/.'
)
for (column in names(updates)) x[[column]][i] <- updates[[column]]
lines <- readLines(path, warn = FALSE, encoding = 'UTF-8')
if (length(lines) != nrow(x) + 1L) stop('Multiline CSV rows require a safe update method.', call. = FALSE)
tmp <- tempfile(fileext = '.csv')
write.csv(x[i, , drop = FALSE], tmp, row.names = FALSE, na = '')
updated <- readLines(tmp, warn = FALSE, encoding = 'UTF-8')[-1L]
unlink(tmp)
lines[i + 1L] <- updated
writeLines(lines, path, useBytes = TRUE)
cat('Screened ICES her.27.nirs; eligible for source curation.\n')
