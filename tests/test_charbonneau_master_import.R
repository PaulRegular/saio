source("scripts/database/071_import_charbonneau_master.R")

stock_path <- "database/stocks.csv"
stock_bytes <- readBin(stock_path, what = "raw", n = file.info(stock_path)$size)
stopifnot(!any(stock_bytes == as.raw(0)))

master <- data.frame(
  Genus = c("Gadus", "Clupea", "Atheresthes", "Merlangius", "Melanogrammus", "Melanogrammus", "Scopthalmus"),
  Species = c("morhua", "harengus", "stomias", "merlangus", "aeglefinus", "aeglefinus", "maximus"),
  Assessor_ID = c("DFO", "DFO-GSL", "AFSC", "ICES-WGSCE", "ICES-WGNSSK", "ICES-WGNSSK", "ICES-WGNSSK"),
  unique_ID = c(
    "DFO_morhua_2J3KL",
    "DFO-GSL_harengus_4T-Spring",
    "AFSC_stomias_BSAI-Females",
    "ICES-WGCSE_merlangus_CS7a",
    "ICES-WGNSSK_aeglefinus_NS 4-6a-20",
    "ICES-WGNSSK_aeglefinus_NS 4-3a20,6a",
    "ICES-WGNSSK_maximus_NS 4"
  ),
  PDF.file = c("cod.pdf", "herring.pdf", "arrowtooth.pdf", "whiting.pdf", "haddock-2017.pdf", "haddock-2016.pdf", "turbot.pdf"),
  stringsAsFactors = FALSE
)

stocks <- data.frame(
  stock_id = c("dfo_cod_2j3kl", "afsc_arrowtooth_flounder_bsai", "ices_haddock_north_sea", "ck_ices_wgnssk_maximus_ns_4"),
  charbonneau_id = c("DFO_2J3KL_Gadus_morhua", "", "ICES-WGNSSK_aeglefinus_NS 4-6a-20", "ICES-WGNSSK_maximus_NS 4"),
  authority = c("DFO", "NOAA-AFSC", "ICES", "ICES"),
  authority_stock_id = c("2J3KL", "BSAI arrowtooth", "had.27.46a20", "tur.27.4"),
  scientific_name = c("Gadus morhua", "Atheresthes stomias", "Melanogrammus aeglefinus", "Scophthalmus maximus"),
  common_name = c("Northern cod", "Arrowtooth flounder", "Northern Shelf haddock", "Turbot"),
  area = c("2J3KL", "BSAI", "Subarea 4, Division 6.a and Subdivision 20", "Subarea 4"),
  region = c("Newfoundland and Labrador", "Alaska", "Northeast Atlantic", "Northeast Atlantic"),
  ocean = c("Northwest Atlantic", "Northeast Pacific", "Northeast Atlantic", "Northeast Atlantic"),
  notes = c("Existing stock record.", "Existing aggregate stock.", "Existing haddock stock.", "Corrected scientific name."),
  stringsAsFactors = FALSE
)

matches <- data.frame(
  master_id = "DFO_morhua_2J3KL",
  stock_id = "dfo_cod_2j3kl",
  reason = "scientific name and stock area",
  stringsAsFactors = FALSE
)
overlaps <- data.frame(
  master_id = "AFSC_stomias_BSAI-Females",
  stock_id = "afsc_arrowtooth_flounder_bsai",
  reason = "sex-specific record associated with the existing aggregate stock",
  stringsAsFactors = FALSE
)

result <- ck_prepare_master_import(master, stocks, matches = matches, overlaps = overlaps)
stopifnot(
  nrow(result$stocks) == nrow(stocks) + 3L,
  result$matched == 3L,
  result$aliased == 1L,
  result$added == 3L,
  all(vapply(master$unique_ID, function(id) {
    canonical <- sum(result$stocks$charbonneau_id == id, na.rm = TRUE)
    alias <- sum(grepl(paste0("Additional Charbonneau-Keith Master alias: ", id),
      result$stocks$notes, fixed = TRUE))
    canonical + alias == 1L
  }, logical(1))),
  result$stocks$charbonneau_id[result$stocks$stock_id == "dfo_cod_2j3kl"] ==
    "DFO_morhua_2J3KL",
  grepl("Previous Charbonneau identifier retained as alias: DFO_2J3KL_Gadus_morhua",
    result$stocks$notes[result$stocks$stock_id == "dfo_cod_2j3kl"], fixed = TRUE),
  result$stocks$area[result$stocks$charbonneau_id == "DFO-GSL_harengus_4T-Spring"] ==
    "4T-Spring",
  result$stocks$area[result$stocks$charbonneau_id == "AFSC_stomias_BSAI-Females"] ==
    "BSAI-Females",
  result$stocks$authority[result$stocks$charbonneau_id == "AFSC_stomias_BSAI-Females"] ==
    "NOAA-AFSC",
  result$stocks$ocean[result$stocks$charbonneau_id == "AFSC_stomias_BSAI-Females"] ==
    "Northeast Pacific",
  grepl("Potential overlap with existing stock afsc_arrowtooth_flounder_bsai",
    result$stocks$notes[result$stocks$charbonneau_id == "AFSC_stomias_BSAI-Females"], fixed = TRUE),
  grepl("Sex-specific catalogue entry", result$stocks$notes[
    result$stocks$charbonneau_id == "AFSC_stomias_BSAI-Females"], fixed = TRUE),
  grepl("Master unique_ID prefix differs from Assessor_ID ICES-WGSCE",
    result$stocks$notes[result$stocks$charbonneau_id == "ICES-WGCSE_merlangus_CS7a"], fixed = TRUE),
  grepl("Assessor_ID=ICES-WGSCE",
    result$stocks$notes[result$stocks$charbonneau_id == "ICES-WGCSE_merlangus_CS7a"], fixed = TRUE),
  result$mapping$stock_id[result$mapping$master_id == "ICES-WGNSSK_aeglefinus_NS 4-3a20,6a"] ==
    "ices_haddock_north_sea",
  result$mapping$mapping[result$mapping$master_id == "ICES-WGNSSK_aeglefinus_NS 4-3a20,6a"] ==
    "documented alias",
  result$stocks$charbonneau_id[result$stocks$stock_id == "ices_haddock_north_sea"] ==
    "ICES-WGNSSK_aeglefinus_NS 4-6a-20",
  grepl("Additional Charbonneau-Keith Master alias: ICES-WGNSSK_aeglefinus_NS 4-3a20,6a",
    result$stocks$notes[result$stocks$stock_id == "ices_haddock_north_sea"], fixed = TRUE),
  result$stocks$scientific_name[result$stocks$stock_id == "ck_ices_wgnssk_maximus_ns_4"] ==
    "Scophthalmus maximus",
  all(result$stocks$ocean %in% c(
    "Northwest Atlantic", "Northeast Atlantic", "Northeast Pacific", "Northwest Pacific"
  )),
  all(result$stocks$common_name[result$stocks$stock_id %in% result$mapping$stock_id[
    result$mapping$mapping == "new metadata row"]] == ""),
  all(result$stocks$authority_stock_id[result$stocks$stock_id %in% result$mapping$stock_id[
    result$mapping$mapping == "new metadata row"]] == "")
)

rerun <- ck_prepare_master_import(
  master, result$stocks, matches = matches, overlaps = overlaps
)
stopifnot(
  identical(result$stocks, rerun$stocks),
  rerun$matched == nrow(master) - 1L,
  rerun$aliased == 1L,
  rerun$added == 0L
)

bad_matches <- rbind(matches, data.frame(
  master_id = "not_in_master", stock_id = "dfo_cod_2j3kl", reason = "stale",
  stringsAsFactors = FALSE
))
missing_crosswalk_error <- tryCatch({
  ck_prepare_master_import(master, stocks, matches = bad_matches, overlaps = overlaps)
  FALSE
}, error = function(e) grepl("absent from Master.csv", conditionMessage(e), fixed = TRUE))
stopifnot(missing_crosswalk_error)

alias_row <- stocks[stocks$stock_id == "ices_haddock_north_sea", , drop = FALSE]
alias_row$stock_id <- ck_master_slug("ICES-WGNSSK_aeglefinus_NS 4-3a20,6a")
alias_row$charbonneau_id <- "ICES-WGNSSK_aeglefinus_NS 4-3a20,6a"
alias_placeholder_error <- tryCatch({
  ck_prepare_master_import(
    master, rbind(stocks, alias_row), matches = matches, overlaps = overlaps
  )
  FALSE
}, error = function(e) grepl("separate generated stock row", conditionMessage(e), fixed = TRUE))
stopifnot(alias_placeholder_error)

cat("Charbonneau-Keith catalogue mapping, metadata safeguards and idempotency passed.\n")

# One documented Iberian catalogue error does not make two anchovy species synonyms.
anchovy_master <- master[1L, ]
anchovy_master$Genus <- "Engraulis"; anchovy_master$Species <- "mordax"
anchovy_master$Assessor_ID <- "ICES-WGHANSA"
anchovy_master$unique_ID <- "ICES-WGHANSA_mordax_SP9a"
anchovy_stock <- stocks[4L, ]
anchovy_stock$stock_id <- "ck_ices_wghansa_mordax_sp9a"
anchovy_stock$charbonneau_id <- anchovy_master$unique_ID
anchovy_stock$scientific_name <- "Engraulis encrasicolus"
anchovy_stock$area <- "SP9a"
reviewed <- ck_prepare_master_import(rbind(master, anchovy_master), rbind(stocks, anchovy_stock),
  matches = matches, overlaps = overlaps)
stopifnot(reviewed$stocks$scientific_name[reviewed$stocks$stock_id == anchovy_stock$stock_id] ==
  "Engraulis encrasicolus", ck_master_taxon_key("Engraulis mordax") != ck_master_taxon_key("Engraulis encrasicolus"))
anchovy_master$unique_ID <- "ICES-WGHANSA_mordax_other_area"
anchovy_stock$charbonneau_id <- anchovy_master$unique_ID
stopifnot(tryCatch({
  ck_prepare_master_import(rbind(master, anchovy_master), rbind(stocks, anchovy_stock),
    matches = matches, overlaps = overlaps); FALSE
}, error = function(e) grepl("conflicting scientific names", conditionMessage(e), fixed = TRUE)))

master_path <- file.path("source_cache", "charbonneau_keith", "Master.csv"
)
if (file.exists(master_path)) {
  source_stocks <- read.csv(
    "database/stocks.csv",
    stringsAsFactors = FALSE, check.names = FALSE, na.strings = c("", "NA")
  )
  master_ids <- read.csv(master_path, stringsAsFactors = FALSE)$unique_ID
  represented <- vapply(master_ids, function(id) {
    canonical <- any(source_stocks$charbonneau_id == id, na.rm = TRUE)
    alias <- any(grepl(
      paste0("Additional Charbonneau-Keith Master alias: ", id),
      source_stocks$notes, fixed = TRUE
    ))
    canonical || alias
  }, logical(1))
  if (all(represented)) {
    alias_note <- paste0(
      "Additional Charbonneau-Keith Master alias: ",
      ck_master_aliases$master_id
    )
    northern_haddock <- source_stocks[
      source_stocks$stock_id == "ices_haddock_north_sea", , drop = FALSE
    ]
    stopifnot(
      !ck_master_slug(ck_master_aliases$master_id) %in% source_stocks$stock_id,
      nrow(northern_haddock) == 1L,
      grepl(alias_note, northern_haddock$notes, fixed = TRUE)
    )
    db_dir <- "database"
    files <- c("stocks.csv", "assessments.csv", "assumptions.csv", "inputs.csv", "outputs.csv")
    temp_dir <- tempfile("ck-master-import-")
    dir.create(temp_dir)
    for (file in files) file.copy(file.path(db_dir, file), temp_dir)
    original_other_tables <- tools::md5sum(file.path(
      temp_dir, c("assessments.csv", "assumptions.csv", "inputs.csv", "outputs.csv")
    ))
    temp_stocks <- file.path(temp_dir, "stocks.csv")
    seed_stocks <- source_stocks[!source_stocks$stock_id %in% ck_master_slug(master_ids), ]
    utils::write.csv(seed_stocks, temp_stocks, row.names = FALSE, na = "")
    first_import <- ck_import_master(master_path, temp_stocks)
    imported_stocks <- read.csv(temp_stocks, stringsAsFactors = FALSE, na.strings = c("", "NA"))
    after_other_tables <- tools::md5sum(file.path(
      temp_dir, c("assessments.csv", "assumptions.csv", "inputs.csv", "outputs.csv")
    ))
    second_import <- ck_import_master(master_path, temp_stocks)
    second_stocks <- read.csv(temp_stocks, stringsAsFactors = FALSE, na.strings = c("", "NA"))
    stopifnot(
      nrow(imported_stocks) == nrow(seed_stocks) + first_import$added,
      first_import$matched == 27L,
      first_import$aliased == 1L,
      first_import$added == 74L,
      second_import$matched == length(master_ids) - 1L,
      second_import$aliased == 1L,
      second_import$added == 0L,
      identical(imported_stocks, second_stocks),
      identical(original_other_tables, after_other_tables)
    )
    unlink(temp_dir, recursive = TRUE)
  }
}

cat("Charbonneau-Keith catalogue database integration checks passed when the local cache is available.\n")
