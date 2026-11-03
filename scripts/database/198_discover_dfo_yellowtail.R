# Add the 2024 Canadian yellowtail assessment identified in the Pacific regional listing.
path <- file.path('discovery', 'candidates.csv')
x <- read.csv(path, stringsAsFactors = FALSE, na.strings = 'NA')
id <- 'DFO:Pacific:Yellowtail Rockfish - British Columbia coastwide'
if (id %in% x$candidate_id) { cat('Candidate already exists; preserve its review.\n'); quit(save = 'no', status = 0L) }
r <- x[1L, , drop = FALSE]
r[] <- ''
r$candidate_id <- id
r$organization <- 'DFO'
r$scientific_name <- 'Sebastes flavidus'
r$stock_name <- 'Yellowtail Rockfish - British Columbia coastwide'
r$assessment_area <- '3CD5ABCDE excluding 4B'
r$inventory_assessment_year <- '2024'
r$inventory_url <- 'https://www.pac.dfo-mpo.gc.ca/fm-gp/mplans/ground-fond-ifmp-pgip-sm-eng.html'
r$retrieved_on <- '2026-10-28'
r$match_status <- 'new'
r$screening_status <- 'in_progress'
r$eligibility <- 'unresolved'
r$import_status <- 'not_started'
r$catch_age_evidence <- 'SAR 2025/026 and pinned base input contain total biomass catch and fishery age proportions; verify whether expansion to catch numbers-at-age is supported without fitted states.'
r$survey_age_evidence <- 'SAR 2025/026: six survey abundance indices and age-frequency proportions from three surveys; inspect observed scales, sample years and age coverage.'
r$weights_evidence <- 'SAR 2025/026: sex-specific growth and weight-length relationships estimated externally; native control sets use_watage=0. Recover appropriate age-specific weights.'
r$maturity_evidence <- 'SAR 2025/026: female maturity estimated externally; control file reads an age-maturity matrix. Verify the matrix and age definition.'
r$mortality_evidence <- 'SAR 2025/026 states sex-specific estimated natural mortalities; production posterior values and uncertainty require verification.'
r$timing_evidence <- 'The base input has survey observation months; verify year-specific timing and stock-synthesis convention.'
r$output_evidence <- 'SAR 2025/026 Figure 1 plots age-0 recruitment and relative spawning biomass with 90% credibility intervals; historical numeric output and comparable absolute SSB need recovery.'
r$detailed_source_url <- 'https://github.com/pbs-software/pbs-synth/tree/16f1d4368ad7d3e854219ca1c2d9d6353252c861/models/input/2024/YTR/BC/Base/B1.R02v2/02.01'
r$review_date <- '2026-10-28'
r$decision_reason <- 'British Columbia unit is distinct from US northern yellowtail; current base inputs are public but reconstruction and numerical official outputs remain unresolved.'
r$notes <- 'Regional DFO listing supplementary to 2024 Sustainability Survey. 2024 catch is a repeated 2023 provisional value.'
lines <- readLines(path, warn = FALSE, encoding = 'UTF-8')
if (length(lines) != nrow(x) + 1L) stop('Multiline CSV rows require a safe update method.', call. = FALSE)
tmp <- tempfile(fileext = '.csv')
write.csv(r, tmp, row.names = FALSE, na = '')
lines <- c(lines, readLines(tmp, warn = FALSE, encoding = 'UTF-8')[[2L]])
unlink(tmp)
writeLines(lines, path, useBytes = TRUE)
cat('Added regional DFO discovery candidate; source eligibility is unresolved.\n')
