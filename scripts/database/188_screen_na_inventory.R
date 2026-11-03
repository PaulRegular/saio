# Reviewed exact-name/area matches and unambiguous non-finfish exclusions.
root <- "."
path <- file.path(root, 'discovery', 'candidates.csv')
candidates <- read.csv(path, stringsAsFactors = FALSE, na.strings = 'NA')
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'), stringsAsFactors = FALSE, na.strings = 'NA')
map <- data.frame(candidate_id = c(
  'NOAA:10019','NOAA:10029','NOAA:10033','NOAA:10034','NOAA:10286',
  'NOAA:10506','NOAA:10510','NOAA:10511','NOAA:10513','NOAA:10515',
  'NOAA:10518','NOAA:10520','NOAA:10523','NOAA:11055','NOAA:11662','NOAA:12745',
  'DFO:Gulf:American Plaice - NAFO 4T',
  'DFO:Newfoundland and Labrador:Atlantic Cod - NAFO 2J3KL',
  'DFO:Quebec:Atlantic Cod - NAFO 3Pn4RS',
  'DFO:Newfoundland and Labrador:Atlantic Cod - NAFO 3Ps',
  'DFO:Gulf:Atlantic Cod - NAFO 4TVn',
  'DFO:Gulf:Atlantic Herring - NAFO 4T (Fall Spawner)',
  'DFO:Gulf:Atlantic Herring - NAFO 4T (Spring Spawner)',
  'DFO:Maritimes:Haddock - NAFO 4X5Y',
  'DFO:Pacific:Pacific Herring - Strait of Georgia'),
  stock_id = c('ck_nefsc_platessoides_5yz','ck_nefsc_americanus_5z',
  'ck_dfo_nefsc_ferruginea_gb','ck_nefsc_garmiii_ferruginea_sne_ma','ck_nefsc_saw_chrysops_usatl',
  'afsc_cod_goa','afsc_pollock_ebs','afsc_pollock_ai','afsc_pollock_goa','ck_nefsc_virens_5yz',
  'ck_nefsc_garmiii_tenuis_gom_gb','nefsc_haddock_georges_bank','joint_hake_coastal',
  'afsc_pop_bsai','afsc_atka_mackerel_bsai','afsc_cod_ai',
  'ck_dfo_platessoides_4t','dfo_cod_2j3kl','dfo_cod_3pn4rs','ck_dfo_morhua_3ps',
  'dfo_cod_4t4vn','ck_dfo_gsl_harengus_4t_fall','dfo_herring_4tvn_spring',
  'ck_dfo_aeglefinus_4x5y','dfo_herring_sog'), stringsAsFactors = FALSE)
if (anyDuplicated(map$candidate_id)) stop('Duplicate candidate mapping.', call. = FALSE)
ci <- match(map$candidate_id, candidates$candidate_id)
si <- match(map$stock_id, stocks$stock_id)
if (anyNA(ci) || anyNA(si)) stop('A reviewed candidate or stock is missing.', call. = FALSE)
lines <- readLines(path, warn = FALSE, encoding = 'UTF-8')
if (length(lines) != nrow(candidates) + 1L) stop('Multiline CSV rows require a safe update method.', call. = FALSE)
changed <- integer()
for (j in seq_along(ci)) {
  i <- ci[j]; k <- si[j]
  if (candidates$match_status[i] != 'unreviewed') next
  if (candidates$organization[i] == 'NOAA' &&
      tolower(candidates$scientific_name[i]) != tolower(stocks$scientific_name[k])) {
    stop('NOAA species mismatch: ', candidates$candidate_id[i], call. = FALSE)
  }
  candidates$matched_stock_id[i] <- stocks$stock_id[k]
  candidates$match_status[i] <- 'matched'
  if (is.na(candidates$scientific_name[i]) || !nzchar(candidates$scientific_name[i])) candidates$scientific_name[i] <- stocks$scientific_name[k]
  candidates$review_date[i] <- as.character(Sys.Date())
  candidates$decision_reason[i] <- 'Inventory name and area correspond to the existing stock record; production run and source-data eligibility remain to be verified.'
  changed <- c(changed, i)
}
exclude <- which(candidates$organization == 'DFO' & candidates$screening_status == 'not_started' &
  grepl('(^american lobster|^lobster|crab|shrimp|scallop|clam|oyster|geoduck|urchin|cucumber|whelk|euphausiid|walrus|^beluga|^bowhead|^grey seal|^harp seal|^narwhal|^spot prawn)', candidates$stock_name, ignore.case = TRUE))
for (i in exclude) {
  candidates$screening_status[i] <- 'screened'
  candidates$eligibility[i] <- 'ineligible'
  candidates$review_date[i] <- as.character(Sys.Date())
  candidates$decision_reason[i] <- 'Non-finfish stock in the DFO sustainability survey; outside the initial marine-finfish discovery scope.'
  changed <- c(changed, i)
}
freshwater <- which(candidates$organization == 'DFO' & candidates$screening_status == 'not_started' &
  grepl('^(lake trout|lake whitefish|inconnu).*great slave lake', candidates$stock_name, ignore.case = TRUE))
for (i in freshwater) {
  candidates$screening_status[i] <- 'screened'
  candidates$eligibility[i] <- 'ineligible'
  candidates$review_date[i] <- as.character(Sys.Date())
  candidates$decision_reason[i] <- 'Great Slave Lake freshwater stock; outside the initial marine-finfish discovery scope.'
  changed <- c(changed, i)
}
changed <- unique(changed)
if (!length(changed)) { cat('No new reviewed entries.\n'); quit(save = 'no', status = 0L) }
tmp <- tempfile(fileext = '.csv')
for (i in changed) {
  write.csv(candidates[i, , drop = FALSE], tmp, row.names = FALSE, na = '')
  lines[i + 1L] <- readLines(tmp, warn = FALSE, encoding = 'UTF-8')[[2L]]
}
unlink(tmp)
writeLines(lines, path, useBytes = TRUE)
cat('Updated', length(changed), 'entries, including', length(exclude), 'non-finfish exclusions.\n')