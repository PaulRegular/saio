# Create the initial discovery register from pinned, locally cached inventories.
# This is a discovery snapshot; source availability and identities need review.
root <- "."
cache <- file.path(root, 'source_cache')
out <- file.path(root, 'discovery', 'candidates.csv')
if (file.exists(out)) stop('Candidate register already exists; preserve reviewed rows.', call. = FALSE)
if (!requireNamespace('jsonlite', quietly = TRUE) || !requireNamespace('xml2', quietly = TRUE)) {
  stop('Install jsonlite and xml2 to build the inventory.', call. = FALSE)
}
env <- new.env(parent = emptyenv())
load(file.path(cache, 'discovery_noaa_stocksmart', 'stock_assessment_summary.rda'), envir = env)
noaa <- env$stock_assessment_summary
noaa <- noaa[order(noaa$stock_id, -as.numeric(noaa$assessment_year), noaa$assessment_id, na.last = TRUE), ]
noaa <- noaa[!duplicated(noaa$stock_id), ]
ices <- jsonlite::fromJSON(file.path(cache, 'discovery_ices_sid', 'stock_list_2026.json'))
h <- xml2::read_html(file.path(cache, 'discovery_dfo_sustainability', 'survey_2024.html'))
tables <- xml2::xml_find_all(h, '//table')
headers <- vapply(tables, function(t) paste(trimws(xml2::xml_text(xml2::xml_find_all(t, './/th'))), collapse = '|'), character(1))
k <- which(grepl('Fish stock', headers, fixed = TRUE) & grepl('DFO Region', headers, fixed = TRUE))
if (length(k) != 1L) stop('Could not uniquely identify DFO survey table.', call. = FALSE)
trs <- xml2::xml_find_all(tables[[k]], './/tr')
cells <- lapply(trs, function(t) trimws(xml2::xml_text(xml2::xml_find_all(t, './td'))))
cells <- cells[lengths(cells) >= 2L]
dfo <- data.frame(name = vapply(cells, `[[`, character(1), 1L), region = vapply(cells, `[[`, character(1), 2L))
make_rows <- function(id, organization, official_id, scientific_name, name, area, year, inventory_url, notes) {
  data.frame(candidate_id = id, candidate_unit_id = '', organization = organization, official_stock_id = official_id,
    scientific_name = scientific_name, stock_name = name, assessment_area = area,
    inventory_assessment_year = year, inventory_url = inventory_url,
    retrieved_on = '2026-10-28', matched_stock_id = '', match_status = 'unreviewed',
    screening_status = 'not_started', eligibility = 'unresolved', import_status = 'not_started',
    catch_age_evidence = '', survey_age_evidence = '', weights_evidence = '',
    maturity_evidence = '', mortality_evidence = '', timing_evidence = '',
    output_evidence = '', detailed_source_url = '', review_date = '', decision_reason = '',
    notes = notes, stringsAsFactors = FALSE)
}
rows <- rbind(
  make_rows(paste0('NOAA:', noaa$stock_id), 'NOAA', as.character(noaa$stock_id),
    noaa$scientific_name, noaa$stock_name, noaa$stock_area, noaa$assessment_year,
    'https://apps-st.fisheries.noaa.gov/stocksmart',
    'Latest inventory metadata row; official run and age-data availability unverified.'),
  make_rows(paste0('ICES:', ices$StockKeyLabel), 'ICES', ices$StockKeyLabel,
    ices$SpeciesScientificName, ices$StockKeyDescription, ices$EcoRegion,
    ices$YearOfLastAssessment, 'https://sid.ices.dk/services/year/2026',
    'Published 2026 stock list; inventory membership does not establish assessment eligibility.'),
  make_rows(paste('DFO', dfo$region, dfo$name, sep = ':'), 'DFO', '', '', dfo$name,
    dfo$region, NA_integer_, 'https://www.dfo-mpo.gc.ca/reports-rapports/regs/sff-cpd/survey-sondage/index-en.html',
    '2024 selected-stock sustainability survey; not an exhaustive DFO inventory; stock identity and age data unverified.')
)
if (anyNA(rows$candidate_id) || anyDuplicated(rows$candidate_id)) stop('Duplicate or missing candidate IDs.', call. = FALSE)
dir.create(dirname(out), recursive = TRUE, showWarnings = FALSE)
write.csv(rows, out, row.names = FALSE, na = '')
print(table(rows$organization))