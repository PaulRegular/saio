ck_abort <- function(message) stop(message, call. = FALSE)

ck_master_revision <- "7e4daca3cbfc14ce7fa0b28ed824eebe7113249b"
ck_master_md5 <- "430d85ba1f4144fc87bca098c8090699"
ck_master_url <- paste0(
  "https://raw.githubusercontent.com/JulieCharbonneau/",
  "Age-structured-marine-fish-database/", ck_master_revision, "/Master.csv"
)

ck_master_matches <- data.frame(
  master_id = c(
    "DFO_morhua_2J3KL",
    "DFO-GSL_morhua_3Pn, 4RS",
    "DFO-GSL_morhua_4T,4VN",
    "DFO-GSL_harengus_4T-Spring",
    "ICES-WGNSSK_morhua_4-7d,20",
    "ICES-HAWG_harengus_ NS-IV 3a,7d",
    "ICES-NWWG_aeglefinus_ICE5a",
    "ICES-WGNSSK_aeglefinus_NS 4-6a-20",
    "ICES-AFWG_ morhua _NEA 1,2",
    "ICES-WGWIDE_ poutassou_NEA 1-9,12,14",
    "ICES-WGWIDE_ harengus_NEA 1,2,5,4a,14a",
    "ICES-WGBFAS_sprattus_BS 22-32",
    "ICES-WGNSSK_ platessa_NS 4,20",
    "ICES-WGNSSK_virens_NS 4,6,3a",
    "ICES-WGNSSK_merlangus_NS 4-7d",
    "ICES-WGNSSK_esmarkii_NS 4, 3aN",
    "NEFSC_scombrus_NWA",
    "CERT-TRAC_aeglefinus_GB",
    "AFSC_chalcogramma_EBS",
    "AFSC_chalcogramma_GOA",
    "AFSC_macrocephalus_GOA",
    "AFSC_alutus_BSAI",
    "AFSC_monopterygius_BSAI",
    "AFSC_chalcogramma_AI",
    "AFSC_ macrocephalus_BSAI",
    "AFSC_macrocephalus_AL to (AI)",
    "AFSC_ aspera_EEBSAI"
  ),
  stock_id = c(
    "dfo_cod_2j3kl",
    "dfo_cod_3pn4rs",
    "dfo_cod_4t4vn",
    "dfo_herring_4tvn_spring",
    "ices_cod_north_sea",
    "ices_herring_north_sea",
    "ices_haddock_iceland",
    "ices_haddock_north_sea",
    "ices_cod_northeast_arctic",
    "ices_bluewhiting_northeast_atlantic",
    "ices_herring_norwegian_spring_spawning",
    "ices_sprat_baltic",
    "ices_plaice_north_sea",
    "ices_saithe_north_sea",
    "ices_whiting_north_sea",
    "ices_norway_pout_north_sea",
    "nefsc_atlantic_mackerel",
    "nefsc_haddock_georges_bank",
    "afsc_pollock_ebs",
    "afsc_pollock_goa",
    "afsc_cod_goa",
    "afsc_pop_bsai",
    "afsc_atka_mackerel_bsai",
    "afsc_pollock_ai",
    "afsc_cod_ebs",
    "afsc_cod_ai",
    "afsc_yellowfin_sole_ebs"
  ),
  reason = c(
    "scientific name and stock area 2J3KL",
    "scientific name and stock area 3Pn/4RS",
    "scientific name and stock area 4T/4Vn",
    "spring-spawning 4T herring stock identity",
    "scientific name and ICES stock area",
    "species, spawning component, and ICES stock area",
    "scientific name and ICES Division 5.a",
    "scientific name and ICES stock area",
    "scientific name and ICES subareas 1 and 2",
    "scientific name and ICES blue-whiting stock area",
    "scientific name and ICES Norwegian spring-spawning stock area",
    "scientific name and Baltic subdivisions 22-32",
    "scientific name and ICES stock area",
    "scientific name and ICES stock area",
    "scientific name and ICES stock area",
    "scientific name and ICES stock area",
    "scientific name and Northwest Atlantic stock area",
    "scientific name and Georges Bank stock area",
    "pollock synonym and Eastern Bering Sea stock area",
    "pollock synonym and Gulf of Alaska stock area",
    "scientific name and Gulf of Alaska stock area",
    "scientific name and Bering Sea/Aleutian Islands stock area",
    "scientific name and Bering Sea/Aleutian Islands stock area",
    "pollock synonym and Aleutian Islands stock area",
    "legacy identifier/PDF label indicate Eastern Bering Sea; Master area key says BSAI, so retain the discrepancy",
    "scientific name and Aleutian Islands stock area",
    "scientific name and Eastern Bering Sea stock area"
  ),
  stringsAsFactors = FALSE
)

ck_master_aliases <- data.frame(
  master_id = "ICES-WGNSSK_aeglefinus_NS 4-3a20,6a",
  stock_id = "ices_haddock_north_sea",
  reason = paste(
    "The 2016 and 2017 catalogue labels identify the same Northern Shelf",
    "haddock assessment unit; the 2017 label is retained as canonical."
  ),
  stringsAsFactors = FALSE
)

ck_master_possible_overlaps <- data.frame(
  master_id = c(
    "NEFSC-GARMIII_dentatus_MA",
    "NEFSC-GARMIII_aeglefinus_5Y",
    "ICES-HAWG_harengus_WBS 22-24",
    "AFSC_stomias_BSAI-Females",
    "AFSC_stomias_BSAI-Males",
    "AFSC_quadrituberculatus_BSAI-Females",
    "AFSC_quadrituberculatus_BSAI-males",
    "AFSC_polyxystra_EEBSAI-Females",
    "AFSC_polyxystra_EEBSAI-Males"
  ),
  stock_id = c(
    "nefsc_summer_flounder",
    "nefsc_haddock_georges_bank",
    "ices_herring_western_baltic",
    "afsc_arrowtooth_flounder_bsai",
    "afsc_arrowtooth_flounder_bsai",
    "afsc_alaska_plaice_bsai",
    "afsc_alaska_plaice_bsai",
    "afsc_northern_rock_sole_ebs",
    "afsc_northern_rock_sole_ebs"
  ),
  reason = c(
    "same species, but the catalogue area and existing management-unit boundary need verification",
    "same species and broad bank area, but the catalogue assessment variant is not confirmed",
    "the catalogue covers subdivisions 22-24 while the existing stock spans 20-24",
    "sex-specific catalogue record associated with the existing aggregate stock",
    "sex-specific catalogue record associated with the existing aggregate stock",
    "sex-specific catalogue record associated with the existing aggregate stock",
    "sex-specific catalogue record associated with the existing aggregate stock",
    "sex-specific catalogue record associated with the existing aggregate stock",
    "sex-specific catalogue record associated with the existing aggregate stock"
  ),
  stringsAsFactors = FALSE
)

ck_master_authority <- function(assessor_id) {
  result <- rep(NA_character_, length(assessor_id))
  joint <- assessor_id %in% c("DFO-NEFSC", "CERT-TRAC", "NEFSC-TRAC-CERT")
  result[joint] <- "NOAA-DFO"
  result[!joint & startsWith(assessor_id, "DFO")] <- "DFO"
  result[!joint & assessor_id == "AFSC"] <- "NOAA-AFSC"
  result[!joint & startsWith(assessor_id, "NEFSC")] <- "NOAA-NEFSC"
  result[!joint & startsWith(assessor_id, "ICES")] <- "ICES"
  if (anyNA(result)) {
    ck_abort(paste0("Unmapped Charbonneau-Keith assessor code: ", paste(assessor_id[is.na(result)], collapse = ", ")))
  }
  result
}

ck_master_ocean <- function(assessor_id) {
  result <- rep(NA_character_, length(assessor_id))
  result[assessor_id == "AFSC"] <- "Northeast Pacific"
  result[startsWith(assessor_id, "ICES")] <- "Northeast Atlantic"
  atlantic <- result %in% c(NA_character_, "")
  result[atlantic] <- "Northwest Atlantic"
  if (any(!result %in% c(
    "Northwest Atlantic", "Northeast Atlantic",
    "Northeast Pacific", "Northwest Pacific"
  ))) {
    ck_abort("Could not assign a supported regional basin.")
  }
  result
}

ck_master_area <- function(unique_id) {
  parts <- strsplit(unique_id, "_", fixed = TRUE)
  area <- vapply(parts, function(x) {
    if (length(x) < 3L) return(NA_character_)
    trimws(paste(x[-c(1L, 2L)], collapse = "_"))
  }, character(1))
  if (anyNA(area) || any(!nzchar(area))) {
    ck_abort(paste0("Could not recover area suffix from Master unique_ID: ", paste(unique_id[is.na(area) | !nzchar(area)], collapse = ", ")))
  }
  area
}

ck_master_slug <- function(x) {
  slug <- tolower(gsub("[^a-zA-Z0-9]+", "_", x))
  slug <- gsub("^_+|_+$", "", slug)
  paste0("ck_", slug)
}

ck_master_taxon_key <- function(x) {
  taxon <- tolower(trimws(as.character(x)))
  taxon[taxon == "theragra chalcogramma"] <- "gadus chalcogrammus"
  taxon[taxon == "scopthalmus maximus"] <- "scophthalmus maximus"
  taxon
}

ck_master_note <- function(old_note, addition, key = addition) {
  old_note <- ifelse(is.na(old_note), "", old_note)
  already_present <- grepl(key, old_note, fixed = TRUE)
  ifelse(already_present, old_note, ifelse(nzchar(old_note), paste(old_note, addition), addition))
}

ck_prepare_master_import <- function(
  master,
  stocks,
  revision = ck_master_revision,
  matches = ck_master_matches,
  overlaps = ck_master_possible_overlaps,
  aliases = ck_master_aliases
) {
  required_master <- c("Genus", "Species", "Assessor_ID", "unique_ID", "PDF.file")
  missing <- setdiff(required_master, names(master))
  if (length(missing)) {
    ck_abort(paste0("Master.csv is missing required columns: ", paste(missing, collapse = ", ")))
  }
  required_stocks <- c(
    "stock_id", "charbonneau_id", "authority", "authority_stock_id",
    "scientific_name", "common_name", "area", "region", "ocean", "notes"
  )
  missing <- setdiff(required_stocks, names(stocks))
  if (length(missing)) {
    ck_abort(paste0("stocks.csv is missing required columns: ", paste(missing, collapse = ", ")))
  }

  ids <- as.character(master$unique_ID)
  if (anyNA(ids) || any(!nzchar(ids)) || anyDuplicated(ids)) {
    ck_abort("Master unique_ID values must be non-empty and unique.")
  }
  if (anyDuplicated(stocks$stock_id)) {
    ck_abort("Existing stock_id values are not unique.")
  }

  absent_matches <- setdiff(matches$master_id, ids)
  if (length(absent_matches)) {
    ck_abort(paste0("Master crosswalk contains identifiers absent from Master.csv: ", paste(absent_matches, collapse = ", ")))
  }
  absent_aliases <- setdiff(aliases$master_id, ids)
  if (length(absent_aliases)) {
    ck_abort(paste0("Master alias crosswalk contains identifiers absent from Master.csv: ", paste(absent_aliases, collapse = ", ")))
  }
  if (anyDuplicated(matches$master_id) || anyDuplicated(matches$stock_id)) {
    ck_abort("Master crosswalk matches must be one-to-one.")
  }
  if (anyDuplicated(aliases$master_id) || any(aliases$master_id %in% matches$master_id)) {
    ck_abort("Master aliases must be unique and cannot also be direct matches.")
  }
  if (any(!matches$stock_id %in% stocks$stock_id)) {
    ck_abort("Master crosswalk points to a missing existing stock_id.")
  }
  if (any(!aliases$stock_id %in% stocks$stock_id)) {
    ck_abort("Master alias crosswalk points to a missing existing stock_id.")
  }
  alias_placeholder <- intersect(ck_master_slug(aliases$master_id), stocks$stock_id)
  if (length(alias_placeholder)) {
    ck_abort(paste0(
      "A documented alias still has a separate generated stock row. Verify that",
      " no assessment records reference it, then reconcile it with the target",
      " stock before importing: ", paste(alias_placeholder, collapse = ", ")
    ))
  }

  source_prefix <- sub("_.*$", "", ids)
  source <- data.frame(
    master_id = ids,
    assessor_id = as.character(master$Assessor_ID),
    scientific_name = paste(trimws(master$Genus), trimws(master$Species)),
    area = ck_master_area(ids),
    authority = ck_master_authority(as.character(master$Assessor_ID)),
    ocean = ck_master_ocean(as.character(master$Assessor_ID)),
    pdf_file = as.character(master[["PDF.file"]]),
    stringsAsFactors = FALSE
  )
  source$region <- ifelse(source$ocean == "Northeast Pacific", "Alaska", source$ocean)
  source$prefix_mismatch <- trimws(source_prefix) != trimws(source$assessor_id)

  manual_ids <- c(matches$master_id, aliases$master_id)
  direct_ids <- setdiff(ids, manual_ids)
  current_ids <- ifelse(is.na(stocks$charbonneau_id), "", stocks$charbonneau_id)
  direct_matches <- lapply(direct_ids, function(id) {
    at <- which(current_ids == id)
    if (length(at) > 1L) {
      ck_abort(paste0("Master identifier ", id, " already appears on multiple stock rows."))
    }
    if (!length(at)) return(NULL)
    data.frame(
      master_id = id,
      stock_id = stocks$stock_id[at],
      reason = "exact existing Charbonneau-Keith identifier",
      stringsAsFactors = FALSE
    )
  })
  direct_matches <- Filter(Negate(is.null), direct_matches)
  all_matches <- rbind(matches, if (length(direct_matches)) do.call(rbind, direct_matches) else NULL)
  if (anyDuplicated(all_matches$master_id) || anyDuplicated(all_matches$stock_id)) {
    ck_abort("Resolved Master matches must be one-to-one.")
  }

  source_at <- match(all_matches$master_id, source$master_id)
  stock_at <- match(all_matches$stock_id, stocks$stock_id)
  source_taxon <- ck_master_taxon_key(source$scientific_name[source_at])
  existing_taxon <- ck_master_taxon_key(stocks$scientific_name[stock_at])
  # The Iberian catalogue row misnames European anchovy as Pacific E. mordax.
  reviewed_anchovy <- source$master_id[source_at] == "ICES-WGHANSA_mordax_SP9a" &
    source_taxon == "engraulis mordax" & existing_taxon == "engraulis encrasicolus"
  if (any(source_taxon != existing_taxon & !reviewed_anchovy)) {
    ck_abort("A crosswalk match has conflicting scientific names.")
  }
  if (any(source$ocean[source_at] != stocks$ocean[stock_at])) {
    ck_abort("A crosswalk match has conflicting regional basins.")
  }

  alias_source_at <- match(aliases$master_id, source$master_id)
  alias_stock_at <- match(aliases$stock_id, stocks$stock_id)
  alias_taxon <- ck_master_taxon_key(source$scientific_name[alias_source_at])
  target_taxon <- ck_master_taxon_key(stocks$scientific_name[alias_stock_at])
  if (any(alias_taxon != target_taxon) ||
      any(source$ocean[alias_source_at] != stocks$ocean[alias_stock_at]) ||
      any(source$authority[alias_source_at] != stocks$authority[alias_stock_at])) {
    ck_abort("A Master alias conflicts with the target stock's species, authority, or regional basin.")
  }

  final <- stocks
  for (i in seq_len(nrow(all_matches))) {
    source_row <- source[source$master_id == all_matches$master_id[i], , drop = FALSE]
    at <- match(all_matches$stock_id[i], final$stock_id)
    old_id <- final$charbonneau_id[at]
    note <- paste0(
      "Matched to Charbonneau-Keith Master unique_ID ",
      all_matches$master_id[i], " by ", all_matches$reason[i],
      "; source revision ", revision,
      ". This catalogue match does not establish current official assessment status."
    )
    if (!is.na(old_id) && nzchar(old_id) && old_id != all_matches$master_id[i]) {
      note <- paste0(
        note, " Previous Charbonneau identifier retained as alias: ", old_id, "."
      )
    }
    final$charbonneau_id[at] <- all_matches$master_id[i]
    if (!grepl("Metadata-only entry from Charbonneau-Keith Master.csv", final$notes[at], fixed = TRUE)) {
      final$notes[at] <- ck_master_note(
        final$notes[at], note,
        key = paste0("Matched to Charbonneau-Keith Master unique_ID ", all_matches$master_id[i])
      )
    }
  }

  for (i in seq_len(nrow(aliases))) {
    at <- match(aliases$stock_id[i], final$stock_id)
    addition <- paste0(
      "Additional Charbonneau-Keith Master alias: ", aliases$master_id[i],
      "; ", aliases$reason[i], " Source revision ", revision, "."
    )
    final$notes[at] <- ck_master_note(
      final$notes[at], addition,
      key = paste0("Additional Charbonneau-Keith Master alias: ", aliases$master_id[i])
    )
  }

  unmatched <- source[!source$master_id %in% c(all_matches$master_id, aliases$master_id), , drop = FALSE]
  if (nrow(unmatched)) {
    unmatched$stock_id <- ck_master_slug(unmatched$master_id)
    if (anyDuplicated(unmatched$stock_id) || any(unmatched$stock_id %in% final$stock_id)) {
      ck_abort("Generated Charbonneau stock_id values collide with existing identifiers.")
    }
    overlap_at <- match(unmatched$master_id, overlaps$master_id)
    overlap_note <- rep("", nrow(unmatched))
    has_overlap <- !is.na(overlap_at)
    if (any(has_overlap)) {
      missing_overlap_stock <- !overlaps$stock_id[overlap_at[has_overlap]] %in% stocks$stock_id
      if (any(missing_overlap_stock)) {
        ck_abort("An overlap note references a missing existing stock_id.")
      }
      overlap_note[has_overlap] <- paste0(
        "Potential overlap with existing stock ",
        overlaps$stock_id[overlap_at[has_overlap]], ": ",
        overlaps$reason[overlap_at[has_overlap]],
        ". Kept separate because one-to-one identity was not established."
      )
    }
    sex_specific <- grepl("-(Females|Males)$", unmatched$area, ignore.case = TRUE)
    mismatch_note <- ifelse(
      unmatched$prefix_mismatch,
      paste0(
        " Master unique_ID prefix differs from Assessor_ID ",
        unmatched$assessor_id, "; both source fields are retained."
      ),
      ""
    )
    sex_note <- ifelse(
      sex_specific,
      " Sex-specific catalogue entry; it is not counted as an additional assessment case.",
      ""
    )
    notes <- paste0(
      "Metadata-only entry from Charbonneau-Keith Master.csv, revision ",
      revision, "; not a verified current official assessment. Assessor_ID=",
      unmatched$assessor_id, "; Master PDF.file label=", unmatched$pdf_file,
      "; area retained from unique_ID; regional basin assigned from assessor family.",
      mismatch_note, sex_note,
      ifelse(nzchar(overlap_note), paste0(" ", overlap_note), "")
    )
    new_stocks <- data.frame(
      stock_id = unmatched$stock_id,
      charbonneau_id = unmatched$master_id,
      authority = unmatched$authority,
      authority_stock_id = "",
      scientific_name = unmatched$scientific_name,
      common_name = "",
      area = unmatched$area,
      region = unmatched$region,
      ocean = unmatched$ocean,
      notes = notes,
      stringsAsFactors = FALSE
    )
    final <- rbind(final, new_stocks)
  }

  counts <- vapply(ids, function(id) {
    canonical <- sum(final$charbonneau_id == id, na.rm = TRUE)
    alias <- sum(grepl(
      paste0("Additional Charbonneau-Keith Master alias: ", id),
      final$notes, fixed = TRUE
    ))
    canonical + alias
  }, integer(1))
  if (any(counts != 1L)) {
    ck_abort(paste0(
      "Every Master unique_ID must appear exactly once as a canonical identifier or documented alias. Invalid identifiers: ",
      paste(ids[counts != 1L], collapse = ", ")
    ))
  }
  if (anyDuplicated(final$stock_id)) {
    ck_abort("Imported stock_id values are not unique.")
  }
  if (any(!final$ocean %in% c(
    "Northwest Atlantic", "Northeast Atlantic",
    "Northeast Pacific", "Northwest Pacific"
  ))) {
    ck_abort("Imported stocks contain an unsupported ocean label.")
  }

  mapped <- match(ids, all_matches$master_id)
  aliased <- match(ids, aliases$master_id)
  stock_id <- rep(NA_character_, length(ids))
  mapping <- rep("new metadata row", length(ids))
  has_match <- !is.na(mapped)
  has_alias <- !is.na(aliased)
  stock_id[has_match] <- all_matches$stock_id[mapped[has_match]]
  mapping[has_match] <- "matched existing stock"
  stock_id[has_alias] <- aliases$stock_id[aliased[has_alias]]
  mapping[has_alias] <- "documented alias"
  stock_id[!has_match & !has_alias] <- ck_master_slug(ids[!has_match & !has_alias])
  map <- data.frame(
    master_id = ids,
    stock_id = stock_id,
    mapping = mapping,
    stringsAsFactors = FALSE
  )
  list(
    stocks = final,
    mapping = map,
    matched = sum(has_match),
    aliased = sum(has_alias),
    added = sum(!has_match & !has_alias)
  )
}

ck_cache_master <- function(path = file.path("source_cache", "charbonneau_keith", "Master.csv"
)) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  if (!file.exists(path)) {
    utils::download.file(ck_master_url, path, mode = "wb", quiet = TRUE)
  }
  actual_md5 <- unname(tools::md5sum(path))
  if (!identical(tolower(actual_md5), ck_master_md5)) {
    ck_abort(paste0("Cached Master.csv checksum does not match pinned revision ", ck_master_revision, "."))
  }
  manifest_path <- file.path(dirname(path), "manifest.csv")
  manifest_row <- data.frame(
    file = basename(path),
    url = ck_master_url,
    retrieved = as.character(Sys.Date()),
    md5 = actual_md5,
    revision = ck_master_revision,
    status = "downloaded",
    stringsAsFactors = FALSE
  )
  if (file.exists(manifest_path)) {
    manifest <- utils::read.csv(manifest_path, stringsAsFactors = FALSE)
    at <- which(manifest$file == basename(path))
    if (length(at)) {
      if (manifest$md5[at[1]] != actual_md5 || manifest$revision[at[1]] != ck_master_revision) {
        ck_abort("Cached Master.csv and its manifest disagree.")
      }
      return(path)
    }
    manifest <- rbind(manifest, manifest_row)
  } else {
    manifest <- manifest_row
  }
  utils::write.csv(manifest, manifest_path, row.names = FALSE, na = "")
  path
}

ck_import_master <- function(
  master_path = file.path("source_cache", "charbonneau_keith", "Master.csv"
  ),
  stocks_path = file.path("database", "stocks.csv")
) {
  ck_cache_master(master_path)
  master <- utils::read.csv(
    master_path, stringsAsFactors = FALSE, check.names = FALSE,
    na.strings = c("", "NA")
  )
  stocks <- utils::read.csv(
    stocks_path, stringsAsFactors = FALSE, check.names = FALSE,
    na.strings = c("", "NA")
  )
  result <- ck_prepare_master_import(master, stocks)
  utils::write.csv(result$stocks, stocks_path, row.names = FALSE, na = "")
  message(sprintf(
    "Imported %s Charbonneau-Keith Master entries: %s linked to existing stock rows, %s documented aliases, and %s added as metadata-only stock rows.",
    nrow(master), result$matched, result$aliased, result$added
  ))
  invisible(result)
}

if (sys.nframe() == 0L) {
  ck_import_master()
}




