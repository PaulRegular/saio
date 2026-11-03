# Give source-screened, unmatched inventory units stable internal keys.
root <- "."
register_path <- file.path(root, 'discovery', 'candidates.csv')
register <- read.csv(register_path, stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
source(file.path(root, 'scripts', 'database', 'candidate_register_io.R'))

candidate_ids <- c(
  'NOAA:10002', 'NOAA:10004', 'NOAA:10005', 'NOAA:10011', 'NOAA:10015',
  'NOAA:10016', 'NOAA:10021', 'NOAA:10022', 'NOAA:10028', 'NOAA:10030',
  'NOAA:10035', 'NOAA:10046', 'NOAA:10054', 'NOAA:10393', 'NOAA:10415',
  'NOAA:10416', 'NOAA:10417', 'NOAA:10426', 'NOAA:10457', 'NOAA:10458',
  'NOAA:10460', 'NOAA:10461', 'NOAA:10462', 'NOAA:10466', 'NOAA:10562',
  'NOAA:10568', 'NOAA:11056', 'NOAA:14804', 'NOAA:14805', 'NOAA:15342',
  'NOAA:17280', 'NOAA:17281', 'NOAA:17282', 'NOAA:17357',
  'ICES:her.27.irls', 'ICES:mac.27.nea', 'ICES:whg.27.7b-ce-k',
  'ICES:pol.27.67', 'ICES:meg.27.8c9a', 'ICES:ple.27.7bc',
  'ICES:ple.27.7h-k', 'ICES:sol.27.7bc', 'ICES:cod.27.6b',
  'ICES:anf.27.3a46', 'ICES:sol.27.8c9a', 'ICES:her.27.nirs',
  'ICES:had.27.7a', 'ICES:wit.27.3a47d', 'ICES:bss.27.4bc7ad-h',
  'ICES:sol.27.8ab', 'ICES:sol.27.7a',
  'DFO:Maritimes:Acadian Redfish - Unit 3',
  'DFO:Maritimes:Atlantic Cod - NAFO 4X5Y',
  'DFO:Pacific:Bocaccio Rockfish',
  'DFO:Pacific:Pacific Herring - Central Coast',
  'DFO:Pacific:Pacific Herring - Haida Gwaii',
  'DFO:Pacific:Pacific Herring - Prince Rupert District',
  'DFO:Pacific:Pacific Herring - West Coast of Vancouver Island',
  'DFO:Pacific:Sablefish',
  'DFO:Gulf:White Hake - NAFO 4T',
  'DFO:Gulf:Yellowtail Flounder - NAFO 4T',
  'DFO:Pacific:Yellowtail Rockfish - British Columbia coastwide')

make_key <- function(i) {
  organization <- register$organization[i]
  if (organization == 'NOAA') {
    stock_id <- sub('^NOAA:', '', register$candidate_id[i])
    if (register$official_stock_id[i] != stock_id)
      stop('NOAA inventory ID mismatch: ', register$candidate_id[i], '.', call. = FALSE)
    return(paste0('noaa_stocksmart_', stock_id))
  }
  if (organization == 'ICES') {
    stock_code <- sub('^ICES:', '', register$candidate_id[i])
    if (register$official_stock_id[i] != stock_code)
      stop('ICES stock code mismatch: ', register$candidate_id[i], '.', call. = FALSE)
    return(paste0('ices_', gsub('[^a-z0-9]+', '_', tolower(stock_code))))
  }
  if (organization == 'DFO') {
    label <- sub('^DFO:', '', register$candidate_id[i])
    label <- iconv(label, from = 'UTF-8', to = 'ASCII//TRANSLIT')
    label <- gsub('[^a-zA-Z0-9]+', '_', tolower(label))
    return(paste0('dfo_sff_2024_', gsub('(^_+|_+$)', '', label)))
  }
  stop('Unsupported inventory organization: ', organization, '.', call. = FALSE)
}

row_index <- match(candidate_ids, register$candidate_id)
if (anyNA(row_index) || anyDuplicated(row_index))
  stop('Expected source inventory candidates are missing or duplicated.', call. = FALSE)
keys <- vapply(row_index, make_key, character(1L))
if (anyDuplicated(keys)) stop('Generated candidate unit keys are not unique.', call. = FALSE)
if (any(keys %in% register$candidate_unit_id[-row_index]))
  stop('Generated candidate unit key conflicts with an existing key.', call. = FALSE)

for (j in seq_along(row_index)) {
  i <- row_index[j]
  old_key <- register$candidate_unit_id[i]
  if (!is.na(old_key) && nzchar(old_key) && old_key != keys[j])
    stop('Candidate unit key already differs for ', candidate_ids[j], '.', call. = FALSE)
  if (register$match_status[i] != 'new' ||
      !is.na(register$matched_stock_id[i]) && nzchar(register$matched_stock_id[i]) ||
      register$screening_status[i] != 'screened')
    stop('Candidate identity or screening state changed: ', candidate_ids[j], '.', call. = FALSE)
  if (is.na(old_key) || !nzchar(old_key)) {
    register$candidate_unit_id[i] <- keys[j]
    replace_candidate_register_row(register_path, i,
      register[i, , drop = FALSE], candidate_ids[j])
  }
}

source(file.path(root, 'scripts', 'database', '195_summarize_discovery.R'))
source(file.path(root, 'scripts', 'database', '196_summarize_inventory_units.R'))
cat('Assigned stable internal keys to 62 source-screened new inventory units.\n')
