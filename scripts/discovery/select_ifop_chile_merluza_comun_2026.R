candidate_id <- "IFOP:merluza_comun_UP"
candidate_unit_id <- "ifop_merluza_comun_up"
review_date <- "2026-11-09"
candidate_path <- "discovery/candidates.csv"
batch_path <- "discovery/selected_batch_20_2026.csv"
manifest_path <- "provenance/ifop_merluza_comun_2026_sources.csv"
write_mode <- "--write" %in% commandArgs(trailingOnly = TRUE)

report_url <- "https://institutofomentop-my.sharepoint.com/:b:/g/personal/renzo_tascheri_ifop_cl/IQC_X34AxJbOQIkPB8eik1CnAW7V0EJWugOWbApDQOCjT1A?e=khmkN4"
minute_url <- "https://institutofomentop-my.sharepoint.com/:b:/g/personal/renzo_tascheri_ifop_cl/IQD_ilIM34epS4C8dTjqhD70AfxdZzc8A39Vbqwjl6ZknIc?e=PqFwiV"
status_url <- "https://www.ifop.cl/wp-content/contenidos/uploads/RepositorioIfop/InformeFinal/2026/P-483306.pdf"
acoustic_url <- "https://www.ifop.cl/wp-content/contenidos/uploads/RepositorioIfop/InformeFinal/2026/P-682128.pdf"
annex_url <- "https://www.ifop.cl/wp-content/contenidos/uploads/RepositorioIfop/InformeFinal/2026/P-682128_anexos.zip"
quota_url <- "https://www.subpesca.cl/portal/615/articles-123749_documento.pdf"
cct_url <- "https://www.subpesca.cl/portal/615/articles-128066_documento.pdf"
catalogue_url <- "https://www.ifop.cl/buscador-2026/"
projects_url <- "https://www.ifop.cl/nuestro-que-hacer/la-investigacion-pesquera/planificacion-estrategica/"

sources <- data.frame(
  file = c(
    "source_cache/chile_merluza_comun_2026/ifop_2026_link_01.pdf",
    "source_cache/chile_merluza_comun_2026/ifop_2026_link_02.pdf",
    "source_cache/discovery_chile_merluza_comun_2026/ifop_2026_status.pdf",
    "source_cache/chile_merluza_comun_2026/ifop_acoustic_2025.pdf",
    "source_cache/chile_merluza_comun_2026/ifop_acoustic_2025_annexes.zip",
    "source_cache/chile_merluza_comun_2026/subpesca_2025_quota_decree_202400159.pdf"
  ),
  url = c(report_url, minute_url, status_url, acoustic_url, annex_url, quota_url),
  retrieved_date = rep(review_date, 6L),
  sha256 = c(
    "088F743681E023CC35BB0795CD42C3C6F291D5B031A83F67A9276E3E2652F105",
    "5C31C6D10ADA568AA04790514474BF14E83AC9CF1A3D7E680072E5E49756FD9E",
    "EA2DA4ADCEECEE73CA06293751051687279741542E4683B2A180952E4E28EA21",
    "8AB92BD655A1DBCA76E564B40BB451FB53695B97E53409D9BA9E87900327CB5F",
    "06CF636F98F4C9E78DC3E7E49C6DF13F1AD3DFF374752DD5C5CBCCFE40C1DFD4",
    "C17AC02E11B73A3C1928DFB0137D8E7BD91BEFF3CA6A3BA48B4DAC5B8F31087E"
  ),
  bytes = c(12780396, 2666351, 862668, 25933696, 614131, 839344),
  notes = c(
    "Detailed 2025 stock-assessment report for 2026 advice; describes model, input coverage, and outputs.",
    "15 December 2025 revision minute; reruns the 2025 assessment with corrected artisanal under-reporting from five landing sites.",
    "2026 technical advisory report; project/reporting summary, not a new stock-assessment run.",
    "Final 2025 acoustic survey report published after the 2025 stock assessment; reviewed as a cross-check, not substituted as a fitted input.",
    "Annex archive for the 2025 direct acoustic survey; not used as a stock-assessment age-input source.",
    "2025 legal quota decree; Article 29 identifies the current IV-41 deg 28.6 min S unit and its 34,920 t quota."
  ),
  stringsAsFactors = FALSE
)

sources <- rbind(sources, data.frame(
  file = "source_cache/chile_merluza_comun_2026/subpesca_cct_session5_2025_advice.pdf",
  url = cct_url,
  retrieved_date = review_date,
  sha256 = "AF0AA881D6F6A0086EEE9EB79D76F877838323204C30DBAB46340F7B291F359E",
  bytes = 3674457,
  notes = "CCT-RDZCS 02/2025: verifies the age-structured model inputs and 2026 catch advice after discard adjustment.",
  stringsAsFactors = FALSE
))

if (!all(file.exists(sources$file)) ||
    !identical(toupper(unname(tools::sha256sum(sources$file))), sources$sha256) ||
    !identical(as.numeric(file.info(sources$file)$size), sources$bytes)) {
  stop("A cached IFOP or Subpesca source is missing or differs from the reviewed revision.", call. = FALSE)
}

if (!requireNamespace("pdftools", quietly = TRUE)) {
  stop("Install pdftools to verify the pinned IFOP source documents.", call. = FALSE)
}
report_text <- paste(pdftools::pdf_text(sources$file[1L]), collapse = "\n")
minute_text <- paste(pdftools::pdf_text(sources$file[2L]), collapse = "\n")
quota_text <- paste(pdftools::pdf_text(sources$file[6L]), collapse = "\n")
cct_text <- paste(pdftools::pdf_text(sources$file[7L]), collapse = "\n")
source_checks <- c(
  age_groups = grepl("12 grupos de edad (2 a 13+)", report_text, fixed = TRUE),
  model_code = grepl("AD Model Builder", report_text, fixed = TRUE),
  revision_location = grepl("Curanipe", minute_text, fixed = TRUE),
  revision_sites = grepl("cinco caletas", minute_text, fixed = TRUE),
  quota = grepl("34.920", quota_text, fixed = TRUE),
  cct_discard_adjustment = grepl("29.703", cct_text, fixed = TRUE),
  cct_age_lag = grepl("con un a", cct_text, fixed = TRUE)
)
if (!all(source_checks)) {
  stop("Pinned IFOP source is missing: ",
    paste(names(source_checks)[!source_checks], collapse = ", "), call. = FALSE)
}

candidates <- read.csv(candidate_path, stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
if (candidate_id %in% candidates$candidate_id ||
    candidate_unit_id %in% candidates$candidate_unit_id ||
    file.exists(batch_path) ||
    grepl("Merluccius gayi", paste(readLines("database/stocks.csv", warn = FALSE), collapse = "\n"), fixed = TRUE)) {
  stop("The candidate, unit, batch, or stock identity already exists; reconcile before selecting.", call. = FALSE)
}

candidate <- data.frame(
  candidate_id = candidate_id,
  candidate_unit_id = candidate_unit_id,
  organization = "IFOP",
  official_stock_id = "",
  scientific_name = "Merluccius gayi",
  stock_name = "Chilean common hake - Unidad de Pesqueria",
  assessment_area = "Chile: maritime area from the Coquimbo Region to 41 deg 28.6 min S (Unidad de Pesqueria IV-41 deg 28.6 min S)",
  inventory_assessment_year = 2026L,
  inventory_url = catalogue_url,
  retrieved_on = review_date,
  matched_stock_id = "",
  match_status = "new",
  screening_status = "screened",
  eligibility = "unresolved",
  import_status = "not_started",
  catch_age_evidence = paste(
    "The detailed 2026-advice report describes commercial catch and age-composition",
    "inputs, with catch-age coverage reported for 1968-2024. CCT-RDZCS 02/2025 states",
    "commercial catch and age compositions enter the management-procedure inputs",
    "with a one-year lag. The numeric annual catch-age likelihood matrix remains unrecovered.",
    "The December revision table gives corrected aggregate catch biomass for 2019-2024; the 2025 quota is a projection assumption, not observed catch."
  ),
  survey_age_evidence = paste(
    "The model uses acoustic-survey biomass and age composition, with model coverage",
    "through the 2025 survey. The assessment report does not publish the numerical",
    "historical age-input matrix. The final 2025 direct-survey age data were published",
    "after the assessment and are not confirmed as the fitted preliminary inputs."
  ),
  weights_evidence = paste(
    "The model uses empirical age-specific weights for commercial catch and acoustic",
    "survey biomass. The annual numeric matrices were not recovered."
  ),
  maturity_evidence = paste(
    "Age-specific maturity is part of the assessment inputs, but the fitted numeric",
    "vector was not recovered from the detailed report."
  ),
  mortality_evidence = paste(
    "The report describes baseline M0 = 0.33 per year and time-varying natural",
    "mortality proportional to squid CPUA from 1999. The fitted coefficient and",
    "run-specific squid covariate series were not recovered."
  ),
  timing_evidence = paste(
    "Spawning fraction is reported as 0.5833. The acoustic survey is conducted in",
    "July-August; the model's exact within-year survey fraction is not published."
  ),
  output_evidence = paste(
    "The December 2025 revised assessment reports total biomass 2+, spawning biomass,",
    "exploitable biomass, recruitment, scalar F, and exploitation rate for 1999-2025.",
    "The annual table gives no uncertainty intervals and does not tabulate N-at-age,",
    "F-at-age, or M-at-age."
  ),
  detailed_source_url = paste(report_url, minute_url, status_url, acoustic_url, quota_url, cct_url, sep = "; "),
  review_date = review_date,
  decision_reason = paste(
    "The latest completed detailed assessment located is the 2025 common-hake run",
    "for 2026 advice, revised on 15 December 2025 after correcting artisanal catch",
    "under-reporting using five landing sites. IFOP lists the year-2027 assessment",
    "as in progress. Select for source curation because run-specific catch inputs",
    "and annual official outputs are recoverable, while age-specific inputs remain",
    "unresolved; this is not yet translation-ready."
  ),
  notes = paste(
    "No numeric official stock identifier was located; the candidate key is an",
    "internal stable key. Use the December five-caleta run for revised outputs, not",
    "the superseded November values. Do not treat final post-assessment acoustic",
    "survey values as fitted inputs. CCT advice gives 29,703 t after a 1.01 discard adjustment; the December minute reports 29,767 t. Keep these advice figures on their documented bases.",
    "provenance/ifop_merluza_comun_2026_sources.csv."
  ),
  stringsAsFactors = FALSE,
  check.names = FALSE
)
candidate <- candidate[names(candidates)]

batch <- data.frame(
  priority = "1",
  candidate_id = candidate_id,
  candidate_unit_id = candidate_unit_id,
  organization = "IFOP",
  official_stock_id = "",
  scientific_name = "Merluccius gayi",
  stock_name = "Chilean common hake - Unidad de Pesqueria",
  assessment_area = candidate$assessment_area,
  inventory_assessment_year = "2026",
  detailed_source_url = candidate$detailed_source_url,
  review_date = review_date,
  selection_basis = paste(
    "Current-unit 2025 assessment for 2026 advice has a December revision with",
    "recoverable corrected catch observations and annual state outputs. Select to",
    "preserve verified source data and resolve missing age-specific input matrices;",
    "source completeness and translation readiness remain unresolved."
  ),
  curation_status = "selected_for_source_curation",
  stringsAsFactors = FALSE,
  check.names = FALSE
)
batch_columns <- names(read.csv("discovery/selected_batch_19_2026.csv",
  stringsAsFactors = FALSE, check.names = FALSE))
if (!identical(names(batch), batch_columns)) {
  stop("The new selection row does not match the selected-batch schema.", call. = FALSE)
}

cat("Verified the current-unit assessment, December revision, quota source, and cached-file checksums.\n")
cat("Selected the Chilean common-hake unit for partial source curation; age-specific inputs remain unresolved.\n")
if (write_mode) {
  write.table(candidate, candidate_path, sep = ",", row.names = FALSE,
    col.names = FALSE, quote = TRUE, na = "", append = TRUE,
    qmethod = "double", eol = "\n")
  write.csv(batch, batch_path, row.names = FALSE, na = "", fileEncoding = "UTF-8")
  write.csv(sources, manifest_path, row.names = FALSE, na = "", fileEncoding = "UTF-8")
  cat("Wrote the candidate, selection checkpoint, and source manifest.\n")
}