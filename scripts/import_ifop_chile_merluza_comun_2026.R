assessment_id <- "ifop_merluza_comun_2026"
stock_id <- "ifop_merluza_comun_up"
candidate_id <- "IFOP:merluza_comun_UP"
source_review_path <- file.path(
  "discovery", "source_reviews", "ifop_chile_merluza_comun_2026.md"
)
report_path <- file.path(
  "source_cache", "chile_merluza_comun_2026", "ifop_2026_link_01.pdf"
)
revision_path <- file.path(
  "source_cache", "chile_merluza_comun_2026", "ifop_2026_link_02.pdf"
)
if (!file.exists(report_path) || !file.exists(revision_path)) {
  stop("The reviewed IFOP assessment reports must be cached.")
}
expected_hashes <- c(
  report = "088F743681E023CC35BB0795CD42C3C6F291D5B031A83F67A9276E3E2652F105",
  revision = "5C31C6D10ADA568AA04790514474BF14E83AC9CF1A3D7E680072E5E49756FD9E"
)
actual_hashes <- toupper(c(
  report = unname(tools::sha256sum(report_path)),
  revision = unname(tools::sha256sum(revision_path))
))
if (!identical(actual_hashes, expected_hashes)) {
  stop("The cached assessment files do not match the reviewed sources.")
}

catch_components <- data.frame(
  year = 2019:2024,
  industrial_t = c(17640, 20601, 21058, 23889, 22637, 24895),
  industrial_discard_factor = c(1.05, 1.00, 1.00, 1.01, 1.01, 1.01),
  artisanal_t = c(8342, 8933, 8768, 8536, 7506, 6293),
  artisanal_underreport_factor = c(3.5, 3.2, 3.0, 2.0, 2.3, 2.1),
  official_total_t = c(47719, 49187, 47362, 41200, 40127, 38359)
)
reconstructed_total <- round(
  catch_components$industrial_t * catch_components$industrial_discard_factor +
    catch_components$artisanal_t * catch_components$artisanal_underreport_factor
)
if (!identical(reconstructed_total, catch_components$official_total_t)) {
  stop("Corrected catch totals do not reproduce the revision minute.")
}

annual <- data.frame(
  year = 1999:2025,
  total_biomass = c(
    1117, 1104, 997, 737, 620, 405, 364, 330, 318, 333, 310, 304, 273, 262,
    257, 269, 274, 328, 328, 357, 383, 404, 404, 437, 406, 362, 364
  ),
  spawning_biomass = c(
    539, 524, 463, 381, 244, 144, 103, 103, 113, 125, 135, 121, 117, 106,
    91, 99, 102, 118, 133, 155, 178, 190, 192, 191, 184, 152, 152
  ),
  exploitable_biomass = c(
    412, 415, 350, 282, 187, 243, 200, 195, 218, 215, 231, 200, 184, 176,
    158, 178, 187, 205, 241, 256, 286, 303, 289, 292, 297, 231, 224
  ),
  recruitment = c(
    1092, 890, 642, 449, 623, 896, 638, 669, 547, 541, 461, 348, 366, 400,
    430, 437, 397, 609, 415, 448, 459, 344, 357, 545, 399, 347, 457
  ),
  fishing_mortality = c(
    0.32, 0.34, 0.40, 0.58, 0.82, 0.40, 0.30, 0.30, 0.26, 0.28, 0.28, 0.30,
    0.31, 0.31, 0.33, 0.18, 0.20, 0.18, 0.17, 0.18, 0.17, 0.16, 0.16, 0.14,
    0.13, 0.16, 0.15
  ),
  exploitation_rate = c(
    0.24, 0.25, 0.28, 0.38, 0.46, 0.25, 0.21, 0.22, 0.19, 0.20, 0.21, 0.22,
    0.23, 0.22, 0.24, 0.14, 0.15, 0.14, 0.13, 0.14, 0.13, 0.13, 0.13, 0.11,
    0.11, 0.13, 0.12
  )
)
if (nrow(annual) != 27L || !identical(annual$year, 1999:2025)) {
  stop("Revision Table 3 transcription has invalid years.")
}

stock_row <- data.frame(
  stock_id = stock_id,
  charbonneau_id = NA_character_,
  authority = "IFOP",
  authority_stock_id = NA_character_,
  scientific_name = "Merluccius gayi",
  common_name = "Chilean common hake",
  area = "Unidad de Pesquería IV–41°28.6′ S: Coquimbo Region to 41°28.6′ S",
  region = "Central Chile",
  ocean = "Southeast Pacific",
  notes = paste(
    "Current management unit. No numeric IFOP stock identifier was located;",
    "internal candidate key is IFOP:merluza_comun_UP."
  )
)
assessment_row <- data.frame(
  assessment_id = assessment_id,
  stock_id = stock_id,
  assessment_year = 2026L,
  terminal_year = 2024L,
  estimate_terminal_year = 2025L,
  assessment_type = "full_assessment",
  model_family = "integrated age-structured model",
  model_version = "2025 run; AD Model Builder 13.2",
  is_current = TRUE,
  is_applied = TRUE,
  framework_year = 2017L,
  assessment_url = "https://institutofomentop-my.sharepoint.com/:b:/g/personal/renzo_tascheri_ifop_cl/IQC_X34AxJbOQIkPB8eik1CnAW7V0EJWugOWbApDQOCjT1A?e=khmkN4",
  framework_url = NA_character_,
  data_url = "https://www.ifop.cl/wp-content/contenidos/uploads/RepositorioIfop/InformeFinal/2026/P-682128.pdf",
  model_url = NA_character_,
  repository_url = NA_character_,
  assumptions_status = "partial",
  inputs_status = "partial",
  outputs_status = "partial",
  notes = paste(
    "The December 15, 2025 revision minute reruns the 2025 assessment after",
    "correcting artisanal under-reporting with five landing sites. Its Table 3",
    "is used for revised annual outputs. Catch inputs extend through 2024;",
    "the 2025 estimate is reported as the estimate terminal year."
  )
)

assumption <- function(component, setting, value, source_reference, notes = "") {
  data.frame(
    assessment_id = assessment_id, component = component,
    fleet = NA_character_, survey = NA_character_, sex = NA_character_,
    region = NA_character_, season = NA_character_, setting = setting,
    value = value, source_reference = source_reference, notes = notes
  )
}
assumptions <- rbind(
  assumption("population", "age_groups", "ages 2–13+ (12 groups)",
    "IFOP detailed assessment report (2026), Section 3.2.3, p. 15"),
  assumption("recruitment", "recruitment_age", "age 2",
    "IFOP detailed assessment report (2026), Section 3.2.3, p. 15"),
  assumption("recruitment", "stock_recruitment_relationship", "Ricker",
    "IFOP detailed assessment report (2026), Section 3.2.3, p. 15"),
  assumption("recruitment", "recruitment_error", "Lognormal annual recruitment error",
    "IFOP detailed assessment report (2026), Section 3.2.3, p. 15"),
  assumption("M", "natural_mortality", "M0 = 0.33 per year plus a time-varying component proportional to squid CPUA from 1999",
    "IFOP detailed assessment report (2026), Section 3.2.3, p. 15; Annex 2, Section 3",
    "The fitted squid series and coefficient are not reported in the reviewed sources."),
  assumption("catch", "catch_likelihood_cv", "0.05",
    "IFOP detailed assessment report (2026), Table 1, p. 16",
    "The report provides the same CV for both estimation stages."),
  assumption("catch", "age_composition_effective_sample_size", "Stage 1 = 100; Stage 2 = 31",
    "IFOP detailed assessment report (2026), Table 1, p. 16"),
  assumption("index", "acoustic_biomass_cv", "Stage 1 = 0.20; Stage 2 = 0.15",
    "IFOP detailed assessment report (2026), Table 1, p. 16",
    "Table 1 labels two stages but does not identify which value was retained in the final fitted run."),
  assumption("index", "acoustic_age_composition_effective_sample_size", "Stage 1 = 50; Stage 2 = 2",
    "IFOP detailed assessment report (2026), Table 1, p. 16",
    "Table 1 labels two stages but does not identify which value was retained in the final fitted run."),
  assumption("population", "spawning_fraction", "0.5833",
    "IFOP detailed assessment report (2026), Appendix 2, Section 2",
    "This is a reported fraction of the annual cycle before spawning; the exact timing convention is not elaborated."),
  assumption("index", "acoustic_survey_timing", "Late winter to early spring, usually July–September",
    "IFOP detailed assessment report (2026), Section 7, p. 17",
    "The 2025 direct-survey report describes the cruise in July–August. The model's exact within-year fraction is not reported."),
  assumption("index", "acoustic_model_year_coverage", "1995, 1997, 1999–2002, 2004–2025 (2025 preliminary)",
    "IFOP detailed assessment report (2026), Table 1, p. 16",
    "Section 7 explicitly excludes 1993 and 2002 from the indirect assessment, although Table 1 lists 2002; retain this source conflict unresolved."),
  assumption("catch", "commercial_model_year_coverage", "Total catch 1940–2024; age composition 1968–2024",
    "IFOP detailed assessment report (2026), Section 3.2.4, p. 16"),
  assumption("index", "acoustic_model_age_input_coverage", "Age composition and mean weight 1995, 1997, 1999–2002, 2004–2024, with preliminary 2025",
    "IFOP detailed assessment report (2026), Section 3.2.4, p. 16",
    "The report describes the input coverage but does not publish the annual numerical fitted matrices.")
)

catch_input <- function(year, value, reference, transform = "", note = "") {
  data.frame(
    assessment_id = assessment_id, type = "catch",
    measure = "catch_biomass", basis = "biomass",
    fleet = "Commercial fishery (industrial and artisanal)",
    survey = NA_character_, sex = NA_character_, region = NA_character_,
    season = NA_character_, year = as.integer(year),
    year_basis = "calendar_year", age = NA_integer_, value = as.numeric(value),
    unit = "t", sampling_time = NA_real_,
    source_type = "reconstructed_source_input",
    source_reference = reference, transformation = transform,
    notes = note, observation_id = NA_character_,
    length_bin = NA_real_, length_bin_lower = NA_real_,
    length_bin_upper = NA_real_, sample_size = NA_real_,
    age_error = NA_character_, partition = NA_character_,
    weight_bin = NA_real_
  )
}
catch_inputs <- lapply(seq_len(nrow(catch_components)), function(i) {
  row <- catch_components[i, ]
  catch_input(
    row$year, row$official_total_t,
    "IFOP revised assessment minute (15 Dec 2025), Table 2, p. 5",
    "round(industrial catch × discard factor + artisanal catch × five-caleta under-reporting factor)",
    "Combined corrected catch in tonnes, using the total printed in the source. Source components and factors reproduce the reported total."
  )
})
catch_inputs[[length(catch_inputs) + 1L]] <- catch_input(
  2025, 34920,
  "Subpesca 2025 quota decree, Article 29",
  "",
  "Authorized quota used as the final-year projection catch assumption; not an observed catch."
)
inputs <- do.call(rbind, catch_inputs)

output_row <- function(type, measure, year, value, unit, age = NA_integer_,
                       note = "") {
  data.frame(
    assessment_id = assessment_id, type = type, measure = measure,
    fleet = NA_character_, survey = NA_character_, sex = NA_character_,
    region = NA_character_, season = NA_character_, year = as.integer(year),
    age = age, age_group = NA_character_, scenario = NA_character_,
    value = as.numeric(value), se = NA_real_, lwr = NA_real_, upr = NA_real_,
    unit = unit, source_type = "official_table",
    source_reference = "IFOP revised assessment minute (15 Dec 2025), Table 3, p. 7; units cross-checked against IFOP detailed assessment report (2026), Table 4, p. 30",
    notes = note
  )
}
outputs <- do.call(rbind, lapply(seq_len(nrow(annual)), function(i) {
  row <- annual[i, ]
  shared_note <- paste(
    "December 2025 revised-run value as printed. The table provides no",
    "uncertainty interval and does not state its point-estimator convention."
  )
  rbind(
    output_row("biomass", "total_biomass", row$year, row$total_biomass,
      "thousand t", note = paste(shared_note, "Total biomass age 2+.")),
    output_row("biomass", "SSB", row$year, row$spawning_biomass,
      "thousand t", note = paste(shared_note, "Spawning biomass.")),
    output_row("biomass", "exploitable_biomass", row$year, row$exploitable_biomass,
      "thousand t", note = paste(shared_note, "Exploitable biomass.")),
    output_row("recruitment", "recruitment", row$year, row$recruitment,
      "million fish", age = 2L,
      note = paste(shared_note, "Recruitment is reported at age 2.")),
    output_row("mortality", "fishing_mortality_summary", row$year, row$fishing_mortality,
      "per year",
      note = paste(shared_note, "Scalar F as labelled in Table 3; the table does not define it as apical or age-averaged F.")),
    output_row("mortality", "exploitation_rate", row$year, row$exploitation_rate,
      "proportion",
      note = paste(shared_note, "The source's u rate; kept distinct from instantaneous fishing mortality."))
  )
}))

source_review <- paste(
  "# Chilean common hake (IFOP, 2026 advice)",
  "",
  "Review date: 2026-11-09",
  "",
  "## Stock unit and current run",
  "",
  "The current management unit is the Unidad de Pesquería IV–41°28.6′ S, from the Coquimbo Region to 41°28.6′ S. Subpesca's 2025 quota decree identifies this unit and sets its 2025 quota at 34,920 t. No separate numeric stock identifier was located; the candidate key is an internal stable identifier.",
  "",
  "The latest completed detailed assessment located is the 2025 run used for 2026 advice. IFOP's March 2026 technical report describes the model and source coverage. The December 15, 2025 revision minute reruns the same assessment configuration after correcting the artisanal under-reporting factor to include five landing sites, including Curanipe. Use this revised run for current outputs; the November estimates are superseded. IFOP lists the 2027 status assessment as in progress.",
  "",
  "The assessment is an integrated age-structured ADMB model with 12 age groups (ages 2–13+), age-2 recruitment, and a Ricker stock-recruit relationship. Recruitment deviations are lognormal. Natural mortality has a baseline M0 of 0.33 per year plus a time-varying component proportional to squid CPUA from 1999. The fitted squid series and mortality coefficient are not reported. Fishery and acoustic age compositions use effective sample sizes reported separately for two estimation stages; the report does not establish which stage-specific values were retained for the final fit.",
  "",
  "## Recoverable source data",
  "",
  "| Component | Verified source information | Coverage and remaining gaps |",
  "|---|---|---|",
  "| Commercial catch | The December revision minute Table 2 reports corrected combined catch totals for 2019–2024. Its industrial and artisanal amounts and correction factors reproduce each printed total. The authorized 2025 quota of 34,920 t is used as a final-year projection catch assumption, not observed catch. | Numerical aggregate catch values for 1940–2018 and catch-at-age likelihood matrices are not recovered. |",
  "| Acoustic survey | The detailed assessment describes biomass, age-composition, and mean-weight inputs, including preliminary 2025 observations. The final 2025 acoustic report Table 10 reports biomass, total abundance, mean weight, and zone shares for 2001, 2002, and 2004–2025. Table 17 reports estimated abundance by age and sex (millions of fish) for 2025, ages 0–14+. | The final survey report is not confirmed to match the preliminary 2025 fitted observations. Its Table 17 includes a blank age-13 cell; it remains blank. The assessment report also lists 2002 in Table 1 but explicitly excludes it from the indirect assessment in Section 7. Historical fitted age-composition matrices remain unavailable. |",
  "| Acoustic source files | The survey-report annex includes an Access database with 1,340 acoustic records, 619 age-read fish, 2,631 biological samples, and associated length, catch, and oceanographic tables. The field dictionary identifies age, length, date, weight, maturity stage, and sex fields. | These are survey data, not a ready-to-use fitted age-composition matrix. Survey-design weighting and the exact transformation to the model input are not established by the database alone. |",
  "| Biology | The assessment uses empirical age-specific fishery and survey weights and age-specific maturity. The final acoustic report provides a 2025 length-weight relationship and individual biological samples. | Historical age-weight matrices and the fitted maturity-at-age vector are not recovered. The final survey samples are not substituted for the model's historical biological inputs. |",
  "| Mortality and timing | The report documents baseline M0 = 0.33 per year plus a squid-CPUA-related time-varying component from 1999, and a spawning fraction of 0.5833. | The squid series/coefficient and the model's exact survey timing fraction remain unavailable. Cruises generally occur July–September; the final 2025 cruise was July–August. |",
  "| Annual outputs | The December revision minute Table 3 reports total biomass 2+, spawning biomass, exploitable biomass, age-2 recruitment, scalar F, and exploitation rate for 1999–2025. | No confidence intervals are tabulated. The table does not define the point-estimator convention or whether scalar F is apical or age-averaged. No numerical N-at-age, F-at-age, or M-at-age output series is reported. |",
  "| Advice | The revision minute reports a 2026 CBA of 29,767 t. CCT-RDZCS report 02/2025 gives a maximum of 29,703 t after a 1.01 discard adjustment to its 30,000 t recommendation. | These advice values use different discard/advice bases and are not interchangeable. |",
  "",
  "## Import decision and source gaps",
  "",
  "This is a partial source import, not a translation-ready assessment. The canonical record contains only verified revised catch totals, the distinct 2025 projection-quota input, documented model assumptions, and annual outputs from the revised run. Outputs are preserved as published with no intervals and no inferred estimator.",
  "",
  "The final acoustic report and its Access annex are now cached and documented. They establish direct survey estimates and biological sample data, including a 2025 abundance-by-age table. The assessment report identifies its 2025 acoustic inputs as preliminary, so the final survey estimates are retained as source evidence but are not substituted for the fitted observations without a direct reconciliation. The historical age-specific model input matrices, empirical weights, maturity vector, and squid covariate remain source gaps.",
  "",
  "The 2026 IFOP status report is a project/reporting summary, not a newer completed model run. IFOP lists the 2027 status assessment as ongoing.",
  "",
  "## Sources and local cache",
  "",
  "- IFOP, 2025 detailed assessment for 2026 advice: <https://institutofomentop-my.sharepoint.com/:b:/g/personal/renzo_tascheri_ifop_cl/IQC_X34AxJbOQIkPB8eik1CnAW7V0EJWugOWbApDQOCjT1A?e=khmkN4>",
  "- IFOP, 15 December 2025 revised assessment minute: <https://institutofomentop-my.sharepoint.com/:b:/g/personal/renzo_tascheri_ifop_cl/IQD_ilIM34epS4C8dTjqhD70AfxdZzc8A39Vbqwjl6ZknIc?e=PqFwiV>",
  "- CCT-RDZCS, Informe Técnico 02/2025: <https://www.subpesca.cl/portal/615/articles-128066_documento.pdf>",
  "- Subpesca, 2025 quota decree: <https://www.subpesca.cl/portal/615/articles-123749_documento.pdf>",
  "- IFOP, final 2025 acoustic survey report: <https://www.ifop.cl/wp-content/contenidos/uploads/RepositorioIfop/InformeFinal/2026/P-682128.pdf>",
  "- IFOP, 2026 report catalogue: <https://www.ifop.cl/buscador-2026/>",
  "- IFOP, current projects: <https://www.ifop.cl/nuestro-que-hacer/la-investigacion-pesquera/planificacion-estrategica/>",
  "",
  "Assessment reports, the direct survey report, and the annex archive are cached under source_cache/chile_merluza_comun_2026/ and source_cache/discovery_chile_merluza_comun_2026/. Retrieval dates, URLs, file sizes, and SHA-256 checksums are recorded in provenance/ifop_merluza_comun_2026_sources.csv.",
  sep = "\n"
)

manifest_path <- file.path(
  "provenance", "ifop_merluza_comun_2026_sources.csv"
)
manifest <- read.csv(
  manifest_path, stringsAsFactors = FALSE, check.names = FALSE,
  na.strings = c("", "NA")
)
accdb_path <- file.path(
  "source_cache", "chile_merluza_comun_2026", "acoustic_2025_annexes",
  "BASE DE DATOS MGAYI 2025-2026.accdb"
)
if (!file.exists(accdb_path)) {
  stop("The Access database extracted from the acoustic annex is missing.")
}
accdb_row <- data.frame(
  file = "source_cache/chile_merluza_comun_2026/acoustic_2025_annexes/BASE DE DATOS MGAYI 2025-2026.accdb",
  url = "https://www.ifop.cl/wp-content/contenidos/uploads/RepositorioIfop/InformeFinal/2026/P-682128_anexos.zip",
  retrieved_date = "2026-11-09",
  sha256 = toupper(unname(tools::sha256sum(accdb_path))),
  bytes = as.numeric(file.info(accdb_path)$size),
  notes = "Access database extracted from the final 2025 acoustic-report annex ZIP; contains cruise acoustic, age-read, and biological sample tables. Its final survey values are not assumed to equal the preliminary observations used by the assessment."
)
manifest <- manifest[manifest$file != accdb_row$file, , drop = FALSE]
manifest <- rbind(manifest, accdb_row)

candidate_register <- read.csv(
  file.path("discovery", "candidates.csv"),
  stringsAsFactors = FALSE, check.names = FALSE, na.strings = c("", "NA")
)
candidate_index <- which(candidate_register$candidate_id == candidate_id)
if (length(candidate_index) != 1L) {
  stop("Expected exactly one Chilean common hake candidate.")
}
candidate_register$matched_stock_id[candidate_index] <- stock_id
candidate_register$match_status[candidate_index] <- "matched"
candidate_register$eligibility[candidate_index] <- "unresolved"
candidate_register$import_status[candidate_index] <- "partial"
candidate_register$catch_age_evidence[candidate_index] <- paste(
  "The official model report describes catch-at-age input through 2024;",
  "the numeric likelihood matrix remains unrecovered. The December revision",
  "minute reports corrected aggregate catches for 2019–2024, imported as",
  "reconstructed source inputs. The 2025 quota is a projection assumption."
)
candidate_register$survey_age_evidence[candidate_index] <- paste(
  "The final 2025 acoustic report includes biomass, abundance, mean weight,",
  "and zone-share estimates for 2001, 2002, 2004–2025, plus abundance by age",
  "and sex for 2025. The annex includes raw acoustic and age-sample tables.",
  "The assessment report calls its 2025 observations preliminary; equivalence",
  "to the final survey values is not verified. Historical fitted age matrices",
  "remain unavailable."
)
candidate_register$weights_evidence[candidate_index] <- paste(
  "The assessment uses empirical age-specific fishery and survey weights.",
  "The final survey report provides aggregate mean weights and a 2025",
  "length-weight relationship, not the fitted historical age-weight matrices."
)
candidate_register$maturity_evidence[candidate_index] <- paste(
  "The final 2025 survey database contains individual maturity-stage",
  "observations, but the fitted historical maturity-at-age vector remains",
  "unrecovered."
)
candidate_register$timing_evidence[candidate_index] <- paste(
  "Spawning fraction is 0.5833. Acoustic surveys are generally July–September;",
  "the 2025 cruise was July–August. The fitted survey fraction is not stated."
)
if (!grepl(
  "The final 2025 acoustic report and extracted Access annex are now cached",
  candidate_register$notes[candidate_index], fixed = TRUE
)) {
  candidate_register$notes[candidate_index] <- paste(
    candidate_register$notes[candidate_index],
    "The final 2025 acoustic report and extracted Access annex are now cached;",
    "their final survey results are not substituted for preliminary model inputs",
    "without a direct reconciliation."
  )
}
selected_path <- file.path("discovery", "selected_batch_20_2026.csv")
selected <- read.csv(
  selected_path, stringsAsFactors = FALSE, check.names = FALSE,
  na.strings = c("", "NA")
)
selected_index <- which(selected$candidate_id == candidate_id)
if (length(selected_index) != 1L) {
  stop("Expected exactly one selected Chilean common hake row.")
}
selected$curation_status[selected_index] <- "partial_source_import"

database_path <- function(name) file.path("database", name)
csv_has_record <- function(path, id) {
  connection <- file(path, open = "r")
  on.exit(close(connection))
  readLines(connection, n = 1L, warn = FALSE)
  prefix <- paste0('"', id, '"')
  repeat {
    lines <- readLines(connection, n = 50000L, warn = FALSE)
    if (!length(lines)) return(FALSE)
    if (any(startsWith(lines, prefix))) return(TRUE)
  }
}
rows_as_table <- function(rows, path) {
  table <- do.call(rbind, rows)
  columns <- names(read.csv(
    path, nrows = 0L, stringsAsFactors = FALSE, check.names = FALSE
  ))
  missing_columns <- setdiff(columns, names(table))
  for (name in missing_columns) table[[name]] <- NA
  table[, columns, drop = FALSE]
}
append_table <- function(rows, filename) {
  path <- database_path(filename)
  table <- rows_as_table(rows, path)
  write.table(
    table, file = path, sep = ",", row.names = FALSE, col.names = FALSE,
    append = TRUE, quote = TRUE, qmethod = "double", na = ""
  )
}
to_rows <- function(x) lapply(seq_len(nrow(x)), function(i) x[i, , drop = FALSE])

update_csv_record <- function(path, key, row, key_column) {
  table <- read.csv(
    path, stringsAsFactors = FALSE, check.names = FALSE,
    na.strings = c("", "NA")
  )
  record <- which(table[[key_column]] == key)
  lines <- readLines(path, encoding = "UTF-8", warn = FALSE)
  if (length(record) != 1L || nrow(row) != 1L) {
    stop("Expected exactly one CSV record for ", key, " in ", path)
  }
  values <- vapply(row, function(value) {
    if (is.na(value[1L])) NA_character_ else as.character(value[1L])
  }, character(1))
  fields <- ifelse(
    is.na(values) | !nzchar(values), "",
    paste0('"', gsub('"', '""', values, fixed = TRUE), '"')
  )
  lines[record + 1L] <- paste(fields, collapse = ",")
  writeLines(lines, path, useBytes = TRUE)
}

if ("--apply" %in% commandArgs(trailingOnly = TRUE)) {
  if (csv_has_record(database_path("stocks.csv"), stock_id) ||
      csv_has_record(database_path("assessments.csv"), assessment_id) ||
      any(vapply(
        c("assumptions.csv", "inputs.csv", "outputs.csv"),
        function(name) csv_has_record(database_path(name), assessment_id),
        logical(1)
      ))) {
    stop("The stock or assessment is already present; refusing to append duplicates.")
  }
  append_table(list(stock_row), "stocks.csv")
  append_table(list(assessment_row), "assessments.csv")
  append_table(to_rows(assumptions), "assumptions.csv")
  append_table(to_rows(inputs), "inputs.csv")
  append_table(to_rows(outputs), "outputs.csv")
  update_csv_record(
    file.path("discovery", "candidates.csv"), candidate_id,
    candidate_register[candidate_index, , drop = FALSE], "candidate_id"
  )
  update_csv_record(selected_path, candidate_id,
    selected[selected_index, , drop = FALSE], "candidate_id"
  )
  write.csv(manifest, manifest_path, row.names = FALSE, na = "")
  writeLines(source_review, source_review_path, useBytes = TRUE)
}

cat(
  "Prepared", nrow(inputs), "verified catch/projection inputs,",
  nrow(assumptions), "assumptions and", nrow(outputs),
  "annual model outputs for", assessment_id, ".\n"
)
cat("The final acoustic survey series remains source evidence, not an assumed fitted input.\n")

