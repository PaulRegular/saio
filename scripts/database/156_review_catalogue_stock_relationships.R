# Historical components and sex-specific catalogue entries are not extra current cases.
ck_stock_relationships <- data.frame(
  stock_id = c(
    "ck_ices_wgbfas_harengus_bs_30", "ck_ices_wgbfas_harengus_bs_31",
    "ck_ices_wgbfas_platessa_bs_21_23", "ck_ices_wgbfas_platessa_bs_24_32",
    "ck_afsc_stomias_bsai_females", "ck_afsc_stomias_bsai_males",
    "ck_afsc_quadrituberculatus_bsai_females", "ck_afsc_quadrituberculatus_bsai_males",
    "ck_afsc_polyxystra_eebsai_females", "ck_afsc_polyxystra_eebsai_males"
  ),
  charbonneau_id = c(
    "ICES-WGBFAS_harengus_BS 30", "ICES-WGBFAS_harengus_BS 31",
    "ICES-WGBFAS_platessa_BS 21-23", "ICES-WGBFAS_platessa_BS 24-32",
    "AFSC_stomias_BSAI-Females", "AFSC_stomias_BSAI-Males",
    "AFSC_quadrituberculatus_BSAI-Females", "AFSC_quadrituberculatus_BSAI-males",
    "AFSC_polyxystra_EEBSAI-Females", "AFSC_polyxystra_EEBSAI-Males"
  ),
  area = c("BS 30", "BS 31", "BS 21-23", "BS 24-32", "BSAI-Females", "BSAI-Males",
    "BSAI-Females", "BSAI-males", "EEBSAI-Females", "EEBSAI-Males"),
  scientific_name = rep(c("Clupea harengus", "Pleuronectes platessa", "Atheresthes stomias",
    "Pleuronectes quadrituberculatus", "Lepidopsetta polyxystra"), each = 2),
  parent_id = rep(c("ices_herring_gulf_bothnia", "ices_plaice_baltic_21_32",
    "afsc_arrowtooth_flounder_bsai", "afsc_alaska_plaice_bsai", "afsc_northern_rock_sole_ebs"), each = 2),
  common_name = c("Bothnian Sea herring (historical unit)", "Bothnian Bay herring (historical unit)",
    "Plaice in subdivisions 21-23 (historical unit)", "Plaice in subdivisions 24-32 (historical unit)",
    "BSAI arrowtooth flounder (female catalogue entry)", "BSAI arrowtooth flounder (male catalogue entry)",
    "BSAI Alaska plaice (female catalogue entry)", "BSAI Alaska plaice (male catalogue entry)",
    "EBS northern rock sole (female catalogue entry)", "EBS northern rock sole (male catalogue entry)"),
  relationship = rep(c(
    "historical assessment component merged in 2017",
    "historical assessment component merged at WKBPLAICE in October 2024 (report published 2025)",
    "sex-specific catalogue entry associated with the BSAI management stock",
    "sex-specific catalogue entry associated with the BSAI management stock; current assessment area is the Eastern Bering Sea",
    "sex-specific catalogue entry associated with the BSAI management stock; current assessment area is the Eastern Bering Sea"
  ), each = 2),
  source_reference = rep(c(
    "https://literatur.thuenen.de/digbib_extern/dn071152.pdf; section 4.3, stock identity",
    "https://doi.org/10.17895/ices.pub.28400255; Executive summary and section 3.1",
    "https://apps-afsc.fisheries.noaa.gov/Plan_Team/2022/BSAIatf.pdf; model description and Table 6.16",
    "https://files.npfmc.org/SAFE/2024/BSAIplaice.pdf; General Model Structure and Model 24.1b",
    "https://files.npfmc.org/SAFE/2024/BSAIrocksole.pdf; Analytic Approach and Tables 8.23-8.24"
  ), each = 2),
  stringsAsFactors = FALSE
)

ck_review_stock_relationships <- function(stocks) {
  if (anyDuplicated(stocks$stock_id)) cli::cli_abort("Stock IDs must be unique before reviewing catalogue relationships.")
  for (i in seq_len(nrow(ck_stock_relationships))) {
    link <- ck_stock_relationships[i, ]
    at <- match(link$stock_id, stocks$stock_id)
    parent <- match(link$parent_id, stocks$stock_id)
    if (is.na(at) || is.na(parent)) cli::cli_abort("Missing catalogue stock or related current stock for {link$stock_id}.")
    if (!isTRUE(stocks$charbonneau_id[at] == link$charbonneau_id) ||
        !isTRUE(stocks$area[at] == link$area) ||
        !isTRUE(stocks$scientific_name[at] == link$scientific_name) ||
        !isTRUE(stocks$scientific_name[parent] == link$scientific_name) ||
        !isTRUE(stocks$ocean[at] == stocks$ocean[parent]) ||
        !isTRUE(stocks$authority[at] == stocks$authority[parent])) {
      cli::cli_abort("Catalogue identity or related stock disagrees with the reviewed source for {link$stock_id}.")
    }
    note <- paste0(
      "Reviewed catalogue relationship (2026-10-26): ", link$relationship,
      "; related current stock_id=", link$parent_id, ". Source: ", link$source_reference,
      ". Original catalogue ID and area are retained. This is not an identical assessment run or a basis for copying data between records."
    )
    old_note <- stocks$notes[at]
    if (is.na(old_note)) old_note <- ""
    if (grepl("Reviewed catalogue relationship (", old_note, fixed = TRUE) &&
        !grepl(note, old_note, fixed = TRUE)) {
      cli::cli_abort("Conflicting previous relationship review for {link$stock_id}.")
    }
    old_note <- sub("Potential overlap with existing stock ",
      "Original import flagged a potential overlap with existing stock ", old_note, fixed = TRUE)
    old_note <- sub("Kept separate because one-to-one identity was not established.",
      "The original import retained this entry before the present relationship review.", old_note, fixed = TRUE)
    if (!grepl(note, old_note, fixed = TRUE)) old_note <- trimws(paste(old_note, note))
    stocks$notes[at] <- old_note
    stocks$common_name[at] <- link$common_name
  }
  for (parent_id in unique(ck_stock_relationships$parent_id)) {
    links <- ck_stock_relationships[ck_stock_relationships$parent_id == parent_id, ]
    at <- match(parent_id, stocks$stock_id)
    note <- paste0("Related historical/component catalogue rows: ",
      paste(links$stock_id, collapse = ", "),
      ". These retain their original identifiers and are not additional current assessment cases; see source_reviews/charbonneau_keith_master_catalogue.md.")
    if (is.na(stocks$notes[at])) stocks$notes[at] <- ""
    if (!grepl(note, stocks$notes[at], fixed = TRUE)) stocks$notes[at] <- trimws(paste(stocks$notes[at], note))
  }
  stocks
}

ck_import_stock_relationships <- function(database_dir = "database",
                                        source_dir = "source_cache") {
  # Require the reviewed authoritative sources, not merely a taxonomic name match.
  sources <- c(
    "ices_herring_gulf_bothnia_2026/WGBFAS_2026_report.pdf",
    "ck_ices_wgcse_platessa_is7e/WKBPLAICE_2024_published_2025.pdf",
    "afsc_arrowtooth_flounder_bsai_2022/BSAIatf_SAFE_2022.pdf",
    "afsc_alaska_plaice_bsai_2024/BSAIplaice_SAFE_2024.pdf",
    "afsc_northern_rock_sole_ebs_2024/BSAIrocksole_SAFE_2024.pdf"
  )
  expected <- c(
    "7e8a6ac51f72abf7d1f026e0997f764267f07690cb2b78e32e073e13fd658732",
    "7802fdfcd791cb289a3deab1466a67a30ec46af13bff35c8bafa9655ca613aac",
    "bb67453ed94a44c2761218b4febb02c32d1c1ccb3442d6118228cf2e863953d7",
    "4b17015bfbf497fbacbebf1911b6e8326bd8426cf357cf8bd37608a4aa147617",
    "e8707161573756f7d630d3b746fbd8a8a9246cb1654d3941d076d775cb353ae9"
  )
  paths <- file.path(source_dir, sources)
  if (!all(file.exists(paths)) || !identical(vapply(paths, function(path)
      digest::digest(file = path, algo = "sha256"), character(1), USE.NAMES = FALSE), expected)) {
    cli::cli_abort("Cache the five reviewed source PDFs with their verified checksums before importing relationships.")
  }
  path <- file.path(database_dir, "stocks.csv")
  stocks <- utils::read.csv(path, colClasses = "character", na.strings = "", check.names = FALSE)
  updated <- ck_review_stock_relationships(stocks)
  changed <- which(vapply(seq_len(nrow(stocks)), function(i) !identical(
    stocks[i, c("notes", "common_name")], updated[i, c("notes", "common_name")]
  ), logical(1)))
  if (!length(changed)) return(invisible(updated))
  contents <- rawToChar(readBin(path, "raw", n = file.info(path)$size))
  lines <- strsplit(contents, "\n", fixed = TRUE)[[1L]]
  tmp <- tempfile(tmpdir = database_dir)
  on.exit(unlink(tmp), add = TRUE)
  for (i in changed) {
    selected <- which(startsWith(lines, paste0('"', stocks$stock_id[i], '",')))
    stopifnot(length(selected) == 1L)
    utils::write.table(updated[i, ], tmp, sep = ",", quote = TRUE, row.names = FALSE,
      col.names = FALSE, na = "", fileEncoding = "UTF-8")
    replacement <- readLines(tmp, encoding = "UTF-8", warn = FALSE)
    stopifnot(length(replacement) == 1L)
    lines[selected] <- paste0(replacement, if (endsWith(lines[selected], "\r")) "\r" else "")
  }
  writeBin(charToRaw(paste0(paste(lines, collapse = "\n"), if (endsWith(contents, "\n")) "\n" else "")), tmp)
  if (!file.copy(tmp, path, overwrite = TRUE)) cli::cli_abort("Could not update stocks.csv.")
  cat("Reviewed 10 catalogue entries related to five existing stocks; only stock names and notes updated.\n")
  invisible(updated)
}

if (sys.nframe() == 0L) ck_import_stock_relationships()
