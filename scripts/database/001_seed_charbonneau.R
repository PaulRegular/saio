candidate_stocks <- c(
  dfo_cod_2j3kl = "DFO_2J3KL_Gadus_morhua",
  dfo_cod_4t4vn = "DFO_4T-4VN_Gadus_morhua",
  ices_cod_north_sea = "ICES-WGNSSK_NS 4-7d,20_Gadus_morhua",
  ices_cod_northeast_arctic = "ICES-AFWG_NEA1-2_Gadus_morhua",
  ices_haddock_north_sea = "ICES-WGNSSK_NS  4-6a-20_Melanogrammus_aeglefinus",
  ices_herring_north_sea = "ICES-HAWG_ NS-IV 3a,7d_Clupea_harengus",
  afsc_pollock_ebs = "AFSC_ESB_Gadus_chalcogrammus",
  afsc_pollock_goa = "AFSC_GOA_Gadus_chalcogrammus",
  afsc_cod_goa = "AFSC_GOA_Gadus_macrocephalus"
)

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 2L) {
  stop("Supply the curated metadata path and one stock_id from candidate_stocks.", call. = FALSE)
}

metadata <- read.csv(args[1],
  encoding = "latin1", check.names = FALSE,
  stringsAsFactors = FALSE
)
needed <- c(
  "Stock", "Management", "Area", "Genus", "Species", "Model",
  "Meeting_or_reference", "Start Year", "End Year"
)
missing <- setdiff(needed, names(metadata))
if (length(missing)) stop("Curated file is missing: ", paste(missing, collapse = ", "), call. = FALSE)
if (anyDuplicated(metadata$Stock)) stop("Curated Stock identifiers must be unique.", call. = FALSE)

stock_id <- args[2]
if (!stock_id %in% names(candidate_stocks)) {
  stop("Unknown candidate stock_id: ", stock_id, call. = FALSE)
}
charbonneau_id <- unname(candidate_stocks[[stock_id]])
at <- match(charbonneau_id, metadata$Stock)
if (is.na(at)) stop("Curated stock record not found: ", charbonneau_id, call. = FALSE)
seed <- metadata[at, needed, drop = FALSE]
seed$stock_id <- stock_id
seed$charbonneau_id <- charbonneau_id
seed$notes <- paste(
  "Candidate metadata only. Curated years and model labels are not verified current production assessment details."
)
print(seed, row.names = FALSE)
