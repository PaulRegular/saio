root <- file.path("source_cache",
  "dfo_cod_3pn4rs_2025"
)
dir.create(root, recursive = TRUE, showWarnings = FALSE)

catalogues <- c(
  teleost = "40381c35-4849-4f17-a8f3-707aa6a53a9d",
  needler = "4eaac443-24a8-4b37-9178-d7cce4eb7c7b",
  cabot = "7001783a-4dc0-41bc-8932-1dae1e699d91",
  sentinel = "929fe07f-ab8e-4b3c-8ee3-1aa7a9ea0b1a"
)
manifest_path <- file.path(root, "manifest.csv")
manifest <- read.csv(manifest_path, stringsAsFactors = FALSE)

cache <- function(filename, url, type, notes) {
  path <- file.path(root, filename)
  if (!file.exists(path)) curl::curl_download(url, path, quiet = TRUE)
  row <- data.frame(
    assessment_id = "dfo_cod_3pn4rs_2025", source_file = filename,
    source_url = url, retrieved_on = as.character(Sys.Date()),
    source_type = type, sha256 = digest::digest(file = path, algo = "sha256"),
    notes = notes
  )
  existing <- manifest$source_file == filename
  if (any(existing)) row$retrieved_on <- manifest$retrieved_on[existing][1]
  manifest <<- rbind(manifest[!existing, ], row)
  path
}

for (name in names(catalogues)) {
  url <- paste0(
    "https://open.canada.ca/data/en/api/3/action/package_show?id=",
    catalogues[[name]]
  )
  path <- cache(
    paste0(name, "_catalogue.json"), url, "survey_catalogue",
    "Public DFO source survey metadata; not the fitted assessment inputs."
  )
  resources <- jsonlite::fromJSON(path)$result$resources
  dictionary <- resources$url[grepl("dictionary", resources$url, ignore.case = TRUE)]
  cache(
    paste0(name, "_dictionary.csv"), dictionary[[1]], "survey_dictionary",
    "Raw sample weights are grams, not the kg-per-fish assessment weight surface."
  )
  archives <- resources$url[grepl("\\.zip$", resources$url)]
  if (name == "sentinel") {
    archives <- archives[grepl("(estival_summer|CRP)\\.zip$", archives)]
  }
  for (archive in archives) {
    cache(
      paste0(name, "_", basename(archive)), archive, "raw_survey_data",
      paste(
        "Tow catches, biological samples and available length frequencies.",
        "Not annual assessment indices, stock weights or fitted maturity ogives."
      )
    )
  }
}
path <- cache(
  "rv-survey-2024.pdf",
  "https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41297039.pdf",
  "survey_methods_pdf",
  paste(
    "Research Document 2025/032, cited by the production assessment.",
    "Cod results in Figures 31-33; no numerical annual age-specific",
    "index, stock-weight or maturity matrix."
  )
)
if (!startsWith(readChar(path, 4, useBytes = TRUE), "%PDF")) {
  cli::cli_abort("The August survey download is not a PDF.")
}
writeLines(pdftools::pdf_text(path), file.path(root, "rv-survey-2024.txt"))
path <- cache(
  "maturity.pdf",
  "https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41287332.pdf",
  "maturity_methods_pdf",
  paste(
    "Technical Report 3671 (2025), DOI 10.60825/z5m6-hx38.",
    "Catalogue full-text alternative to the redirected publications.gc.ca URL.",
    "Annual fitted ogives are figures, not numerical tables."
  )
)
if (!startsWith(readChar(path, 4, useBytes = TRUE), "%PDF")) {
  cli::cli_abort("The maturity download is not a PDF.")
}
writeLines(pdftools::pdf_text(path), file.path(root, "maturity.txt"))
write.csv(manifest, manifest_path, row.names = FALSE, na = "")
cli::cli_inform("Cached Northern Gulf cod survey and maturity sources with checksums.")
