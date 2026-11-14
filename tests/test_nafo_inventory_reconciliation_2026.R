candidates <- read.csv("discovery/candidates.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
nafo <- subset(candidates, organization == "NAFO")
eligible <- subset(nafo, eligibility == "eligible")
stocks <- read.csv("database/stocks.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
review <- readLines("discovery/source_reviews/nafo_inventory_2026.md",
  warn = FALSE)
review_text <- paste(review, collapse = " ")

expected_matches <- c(
  "NAFO:cod.3M" = "nafo_cod_3m",
  "NAFO:cod.3NO" = "nafo_cod_3no",
  "NAFO:redfish.3M" = "nafo_redfish_3m",
  "NAFO:american_plaice.3LNO" = "nafo_american_plaice_3lno",
  "NAFO:greenland_halibut.SA2-3KLMNO" = "dfo_greenland_halibut_2_3klmno"
)
eligible <- eligible[match(names(expected_matches), eligible$candidate_id), ]

witch <- subset(nafo, candidate_id == "NAFO:witch_flounder.3NO")
source_manifest <- read.csv(
  "provenance/discovery_dfo_witch_flounder_3no_2026/sources.csv",
  stringsAsFactors = FALSE
)
advice <- subset(source_manifest,
  url == "https://www.nafo.int/Portals/0/PDFs/Advice/2026/wf3no.pdf")

stopifnot(
  nrow(nafo) == 27L,
  nrow(eligible) == length(expected_matches),
  identical(setNames(eligible$matched_stock_id, eligible$candidate_id),
    expected_matches),
  all(eligible$match_status == "matched"),
  all(eligible$matched_stock_id %in% stocks$stock_id),
  !("nafo_greenland_halibut_sa2_3klmno" %in% stocks$stock_id),
  length(unique(eligible$matched_stock_id)) == 5L,
  nrow(witch) == 1L,
  witch$inventory_assessment_year == 2024L,
  witch$eligibility == "ineligible",
  witch$candidate_unit_id == "dfo_witch_flounder_3no",
  grepl("https://www.nafo.int/Portals/0/PDFs/Advice/2026/wf3no.pdf",
    witch$detailed_source_url, fixed = TRUE),
  grepl("2026 advice", witch$notes, fixed = TRUE),
  nrow(advice) == 1L,
  grepl("2024 detailed assessment; 2026 advice update", review_text, fixed = TRUE),
  grepl("next full assessment is planned for 2028", review_text, fixed = TRUE),
  grepl("no age-structured population assessment", tolower(review_text),
    fixed = TRUE),
  !grepl("tinyAM", review_text, ignore.case = TRUE)
)

cached_advice <- "source_cache/discovery_dfo_witch_flounder_3no_2026/nafo_wf3no_2026_advice.pdf"
if (file.exists(cached_advice)) {
  stopifnot(identical(toupper(unname(tools::sha256sum(cached_advice))),
    toupper(advice$sha256)))
}

cat("NAFO candidate reconciliation and 2026 advice checks passed.\n")
