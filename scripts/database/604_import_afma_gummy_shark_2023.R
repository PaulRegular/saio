root <- "."
report_url <- "https://www.afma.gov.au/sites/default/files/2024-02/Gummy_assessment_report_Dec2023_v3.pdf"
species_url <- "https://www.afma.gov.au/species/gummy-shark"
report_path <- file.path(root, "source_cache/afma_gummy_shark_2023/Gummy_assessment_report_Dec2023_v3.pdf")
expected_hash <- "3AA1245146CEE94FB36C89F9E8FB1FC134D647360896E401E5762D9E7CD467DC"
stock_id <- "afma_gummy_shark_sessf"
assessment_id <- paste0(stock_id, "_2023")
candidate_id <- "AFMA:SESSF_GUMMY_SHARK_2023"
retrieved_on <- "2026-11-07"
write_mode <- "--write" %in% commandArgs(trailingOnly = TRUE)

sha256_file <- function(path) {
  if (.Platform$OS.type == "windows") {
    result <- system2("certutil.exe", c("-hashfile", shQuote(path), "SHA256"),
      stdout = TRUE, stderr = FALSE)
    hash <- toupper(trimws(grep("^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$",
      result, value = TRUE)))
  } else {
    result <- system2("sha256sum", shQuote(path), stdout = TRUE, stderr = FALSE)
    hash <- toupper(strsplit(result, "[[:space:]]+")[[1]][1])
  }
  if (length(hash) != 1L) stop("Could not calculate SHA-256 for ", path, call. = FALSE)
  hash
}

if (!file.exists(report_path) || !identical(sha256_file(report_path), expected_hash)) {
  stop("The cached AFMA report differs from the reviewed source.", call. = FALSE)
}
if (!requireNamespace("pdftools", quietly = TRUE)) {
  stop("Install pdftools to extract the cached AFMA assessment tables.", call. = FALSE)
}

pages <- pdftools::pdf_text(report_path)
find_page <- function(pattern) {
  page <- which(grepl(pattern, pages, ignore.case = TRUE))
  if (length(page) != 1L) stop("Could not uniquely locate ", pattern, " in the cached report.", call. = FALSE)
  page
}
table_starts <- c(
  "Bass Strait" = find_page("Table 14: Bass Strait Gummy Shark catches as input"),
  "South Australia" = find_page("Table 15: South Australia Gummy Shark catches as input"),
  "Tasmania" = find_page("Table 16: Tasmania Gummy Shark catches as input")
)
appendix_b <- which(seq_along(pages) > table_starts[["Tasmania"]] &
  grepl("Appendix B: Base case model fits", pages, ignore.case = TRUE))
if (length(appendix_b) != 1L) stop("Could not locate Appendix B after Table 16.", call. = FALSE)
table_ends <- c(table_starts[-1L] - 1L, appendix_b - 1L)
names(table_ends) <- names(table_starts)
source_gears <- c("LS", "GN6", "GN5", "GN7", "GN8", "TW", "LD", "DS")
model_gears <- source_gears[source_gears != "DS"]
gear_names <- c(
  LS = "Shallow line", GN6 = "Gillnet 6 inch", GN5 = "Gillnet 6.5 inch",
  GN7 = "Gillnet 7 inch", GN8 = "Gillnet 8 inch", TW = "Trawl", LD = "Deep line"
)

read_catch_table <- function(start, end, region) {
  lines <- unlist(strsplit(paste(pages[start:end], collapse = "\n"), "\n"), use.names = FALSE)
  year_lines <- lines[grepl("^[[:space:]]*(19|20)[0-9]{2}[[:space:]]+", lines)]
  tokens <- strsplit(trimws(year_lines), "[[:space:]]+")
  years <- suppressWarnings(as.integer(vapply(tokens, `[`, character(1), 1L)))
  keep <- years >= 1927L & years <= 2022L
  tokens <- tokens[keep]
  years <- years[keep]
  if (length(years) != 96L || !identical(years, 1927:2022) ||
      any(lengths(tokens) != length(source_gears) + 1L)) {
    stop("The source catch table did not parse as one row per year from 1927 through 2022 for ", region, ".",
      call. = FALSE)
  }
  values <- lapply(tokens, function(x) suppressWarnings(as.numeric(x[-1L])))
  if (any(lengths(values) != length(source_gears)) || any(!is.finite(unlist(values))) ||
      any(unlist(values) < 0)) {
    stop("The source catch table has an invalid value for ", region, ".", call. = FALSE)
  }
  out <- as.data.frame(do.call(rbind, values), stringsAsFactors = FALSE)
  names(out) <- source_gears
  out$year <- years
  out$region <- region
  out
}

catch_tables <- Map(read_catch_table, table_starts, table_ends, names(table_starts))
names(catch_tables) <- names(table_starts)
source_catch <- do.call(rbind, catch_tables)
catch_rows <- do.call(rbind, lapply(names(catch_tables), function(region) {
  tab <- catch_tables[[region]]
  cells <- expand.grid(row = seq_len(nrow(tab)), gear = model_gears,
    stringsAsFactors = FALSE, KEEP.OUT.ATTRS = FALSE)
  data.frame(
    region = region,
    year = tab$year[cells$row],
    fleet = unname(gear_names[cells$gear]),
    value = vapply(seq_len(nrow(cells)), function(i) tab[[cells$gear[i]]][cells$row[i]], numeric(1)),
    stringsAsFactors = FALSE
  )
}))
if (nrow(catch_rows) != 96L * 3L * length(model_gears) || any(catch_rows$fleet == "Danish seine")) {
  stop("Unexpected catch coverage or a fleet not used by Bridge 17 entered the import.", call. = FALSE)
}

stock_fields <- names(utils::read.csv(file.path(root, "database/stocks.csv"), nrows = 0L,
  stringsAsFactors = FALSE, check.names = FALSE))
assessment_fields <- names(utils::read.csv(file.path(root, "database/assessments.csv"), nrows = 0L,
  stringsAsFactors = FALSE, check.names = FALSE))
input_fields <- names(utils::read.csv(file.path(root, "database/inputs.csv"), nrows = 0L,
  stringsAsFactors = FALSE, check.names = FALSE))
output_fields <- names(utils::read.csv(file.path(root, "database/outputs.csv"), nrows = 0L,
  stringsAsFactors = FALSE, check.names = FALSE))
assumption_fields <- names(utils::read.csv(file.path(root, "database/assumptions.csv"), nrows = 0L,
  stringsAsFactors = FALSE, check.names = FALSE))

rows <- function(columns, values) {
  n <- max(c(1L, lengths(values)))
  out <- lapply(columns, function(name) {
    value <- values[[name]]
    if (is.null(value)) return(rep("", n))
    value <- rep_len(as.character(value), n)
    value[is.na(value)] <- ""
    value
  })
  names(out) <- columns
  as.data.frame(out, stringsAsFactors = FALSE, check.names = FALSE)
}

read_csv <- function(path) utils::read.csv(path, stringsAsFactors = FALSE,
  check.names = FALSE, na.strings = c("", "NA"))
read_character_csv <- function(path) utils::read.csv(path, stringsAsFactors = FALSE,
  check.names = FALSE, na.strings = c("", "NA"), colClasses = "character")
stocks_path <- file.path(root, "database/stocks.csv")
assessments_path <- file.path(root, "database/assessments.csv")
assumptions_path <- file.path(root, "database/assumptions.csv")
inputs_path <- file.path(root, "database/inputs.csv")
outputs_path <- file.path(root, "database/outputs.csv")
candidates_path <- file.path(root, "discovery/candidates.csv")
selected_path <- file.path(root, "discovery/selected_batch_14_2026.csv")

stocks_existing <- read_csv(stocks_path)
assessments_existing <- read_csv(assessments_path)
candidates <- read_character_csv(candidates_path)
selected <- read_character_csv(selected_path)
candidate_row <- which(candidates$candidate_id == candidate_id)
selected_row <- which(selected$candidate_id == candidate_id)
stock_exists <- any(stocks_existing$stock_id == stock_id)
assessment_exists <- any(assessments_existing$assessment_id == assessment_id)
if (length(candidate_row) != 1L || length(selected_row) != 1L ||
    candidates$candidate_unit_id[candidate_row] != stock_id ||
    candidates$eligibility[candidate_row] != "unresolved" ||
    !candidates$import_status[candidate_row] %in% c("not_started", "partial") ||
    !selected$curation_status[selected_row] %in% c("selected_for_source_curation", "partial_source_import") ||
    stock_exists != assessment_exists) {
  stop("The candidate or canonical database differs from the reviewed source screen.", call. = FALSE)
}

input_rows <- rows(input_fields, list(
  assessment_id = assessment_id,
  type = "catch",
  measure = "catch_biomass",
  basis = "biomass",
  region = catch_rows$region,
  fleet = catch_rows$fleet,
  year = catch_rows$year,
  year_basis = "model_year",
  value = format(catch_rows$value, scientific = FALSE, trim = TRUE),
  unit = "tonnes",
  source_type = "official_table",
  source_reference = paste0("AFMA 2023 Gummy Shark assessment report, Appendix A, Table ",
    match(catch_rows$region, names(catch_tables)) + 13L, ", printed pp. ",
    vapply(catch_rows$region, function(region) {
      paste(range(table_starts[[region]]:table_ends[[region]]), collapse = "-")
    }, character(1))),
  transformation = "",
  notes = paste(
    "Total removals (landed catches plus discards); values are transcribed in tonnes.",
    "The source gives annual model-year labels but does not specify calendar-year versus fleet-specific fishing-year boundaries.",
    "The Danish seine column in the source tables is omitted because the official Bridge 17 base case does not use that fleet."
  )
))

bridge17 <- data.frame(
  region = c("Bass Strait", "South Australia", "Tasmania"),
  B0 = c(9709, 5986, 1914),
  MSYR = c(0.21, 0.23, 0.21),
  Pem73 = c(59, 69, 87),
  PemFinal = c(50, 63, 69),
  Satn = c(0.70, 0.91, 0.70),
  stringsAsFactors = FALSE
)
output_rows <- rbind(
  rows(output_fields, list(
    assessment_id = assessment_id, type = "mortality",
    measure = "natural_mortality_average_parameter", value = 0.18,
    unit = "yr-1", source_type = "official_table",
    source_reference = "AFMA 2023 Gummy Shark assessment report, Table 5, printed p. 25",
    notes = "Bridge 17 adult natural mortality estimate shared among the three model components. Juvenile M is calculated to give equilibrium in the absence of fishing; no uncertainty is reported."
  )),
  rows(output_fields, list(
    assessment_id = assessment_id, type = "biomass", measure = "unfished_biomass",
    region = bridge17$region, value = bridge17$B0, unit = "not stated",
    source_type = "official_table",
    source_reference = "AFMA 2023 Gummy Shark assessment report, Tables 1 and 5, printed pp. 18, 25",
    notes = "Source-reported B0, described as unfished biomass. The report does not state the numeric unit or clarify the biological basis of this B0 value; it is retained on the source scale without conversion."
  )),
  rows(output_fields, list(
    assessment_id = assessment_id, type = "parameter", measure = "maximum_sustainable_yield_rate",
    region = bridge17$region, value = bridge17$MSYR, unit = "ratio",
    source_type = "official_table",
    source_reference = "AFMA 2023 Gummy Shark assessment report, Tables 1 and 5, printed pp. 18, 25",
    notes = "Source defines MSYR as MSY divided by BMSY. Point estimate only; no uncertainty is reported."
  )),
  rows(output_fields, list(
    assessment_id = assessment_id, type = "biomass", measure = "pup_production_depletion",
    region = rep(bridge17$region, 2L), year = c(rep(1973L, 3L), rep(2022L, 3L)),
    value = c(bridge17$Pem73, bridge17$PemFinal), unit = "percent",
    source_type = "official_table",
    source_reference = "AFMA 2023 Gummy Shark assessment report, Tables 1 and 5, printed pp. 18, 25",
    notes = "Source-reported pup production relative to unfished pup production, shown as a percentage. AFMA uses pup production as a proxy for spawning biomass; these are not SSB estimates. No uncertainty is reported."
  )),
  rows(output_fields, list(
    assessment_id = assessment_id, type = "parameter", measure = "effort_saturation_parameter",
    region = bridge17$region, value = bridge17$Satn, unit = "not stated",
    source_type = "official_table",
    source_reference = "AFMA 2023 Gummy Shark assessment report, Tables 1 and 5, printed pp. 18, 25",
    notes = "Source-reported Satn parameter for the effort-saturation relationship. Its scale depends on the effort units in the CPUE model; the report does not give a unit or uncertainty interval."
  )),
  rows(output_fields, list(
    assessment_id = assessment_id, type = "diagnostic", measure = "negative_log_likelihood",
    value = c(1757, 175, 680, 162, 381, 305, 53),
    scenario = c("Total", "CPUE", "Length", "Age composition", "Conditional age-at-length", "Tagging", "Recruitment prior"),
    unit = "source objective scale", source_type = "official_table",
    source_reference = "AFMA 2023 Gummy Shark assessment report, Table 5, printed p. 25",
    notes = "Bridge 17 negative log-likelihood values as rounded in Table 5. Rounded component values sum to 1,756 while the independently rounded total is 1,757."
  ))
)

assumptions <- do.call(rbind, list(
  rows(assumption_fields, list(assessment_id = assessment_id, component = "assessment",
    setting = "production_run", value = "Bridge 17, selected as the official 2023 base-case assessment model",
    source_reference = "AFMA 2023 Gummy Shark assessment report, pp. 1, 19",
    notes = "The assessment uses data through 2022.")),
  rows(assumption_fields, list(assessment_id = assessment_id, component = "model",
    setting = "model_components", value = "Three components: Bass Strait, South Australia, and Tasmania",
    source_reference = "AFMA 2023 Gummy Shark assessment report, p. 1",
    notes = "The components are retained as regions within one stock assessment.")),
  rows(assumption_fields, list(assessment_id = assessment_id, component = "model",
    setting = "sex_and_growth_structure", value = "Sexes modeled separately with fixed sex-specific growth rates",
    source_reference = "AFMA 2023 Gummy Shark assessment report, p. 1",
    notes = "The report states that growth is not estimated within the model.")),
  rows(assumption_fields, list(assessment_id = assessment_id, component = "mortality",
    setting = "adult_natural_mortality", value = "Estimated jointly and shared across the three model components",
    source_reference = "AFMA 2023 Gummy Shark assessment report, pp. 1, 19, Table 5",
    notes = "Bridge 17 point estimate is stored in outputs.csv.")),
  rows(assumption_fields, list(assessment_id = assessment_id, component = "mortality",
    setting = "juvenile_natural_mortality", value = "Calculated to give equilibrium in the absence of fishing",
    source_reference = "AFMA 2023 Gummy Shark assessment report, p. 1")),
  rows(assumption_fields, list(assessment_id = assessment_id, component = "productivity",
    setting = "productivity_sharing", value = "Stock-specific recruitment and CPUE power parameters; shared productivity and density-dependence structure",
    source_reference = "AFMA 2023 Gummy Shark assessment report, p. 1")),
  rows(assumption_fields, list(assessment_id = assessment_id, component = "catch",
    setting = "catch_history", value = "Annual total removals (landed catches plus discards) by seven fleets and three components, 1927-2022",
    source_reference = "AFMA 2023 Gummy Shark assessment report, Appendix A, Tables 14-16, printed pp. 66-72",
    notes = "The report tables also show Danish seine catches for some runs; that fleet is not used in Bridge 17 and is not imported as an input.")),
  rows(assumption_fields, list(assessment_id = assessment_id, component = "catch",
    setting = "catch_year_convention", value = "Annual source/model-year labels; calendar-year or fleet-specific fishing-year boundaries are not stated",
    source_reference = "AFMA 2023 Gummy Shark assessment report, Appendix A, Tables 14-16, printed pp. 66-72")),
  rows(assumption_fields, list(assessment_id = assessment_id, component = "catchability",
    setting = "cpue_inputs", value = "Standardized gillnet, trawl, and shallow-line CPUE; gillnet effort saturation is modeled",
    source_reference = "AFMA 2023 Gummy Shark assessment report, pp. 1, 16-17",
    notes = "Numerical CPUE series and effort vectors are not tabulated in the reviewed report.")),
  rows(assumption_fields, list(assessment_id = assessment_id, component = "composition",
    setting = "age_composition", value = "Gear-, sex-, and component-specific age compositions for selected 6-inch and 7-inch gillnets, 1986-2008; plus group age 10",
    source_reference = "AFMA 2023 Gummy Shark assessment report, p. 1",
    notes = "The numeric composition arrays are not tabulated.")),
  rows(assumption_fields, list(assessment_id = assessment_id, component = "composition",
    setting = "conditional_age_at_length", value = "Conditional age-at-length data for 1995-2022; plus group age 20",
    source_reference = "AFMA 2023 Gummy Shark assessment report, p. 1",
    notes = "The numeric conditional age-at-length arrays are not tabulated.")),
  rows(assumption_fields, list(assessment_id = assessment_id, component = "biology",
    setting = "spawning_biomass_proxy", value = "Pup production is used as a proxy for spawning biomass",
    source_reference = "AFMA 2023 Gummy Shark assessment report, pp. 1-2",
    notes = "No numerical maturity/fecundity-at-age or pup-production weighting schedule is provided in the reviewed report.")),
  rows(assumption_fields, list(assessment_id = assessment_id, component = "uncertainty",
    setting = "reported_output_uncertainty", value = "Table 5 point estimates are reported without uncertainty intervals",
    source_reference = "AFMA 2023 Gummy Shark assessment report, Table 5, printed p. 25"))
))

stock <- rows(stock_fields, list(
  stock_id = stock_id,
  charbonneau_id = "",
  authority = "AFMA",
  authority_stock_id = "SESSF Gummy Shark",
  scientific_name = "Mustelus antarcticus",
  common_name = "Gummy Shark",
  area = "Southern and Eastern Scalefish and Shark Fishery; Bass Strait, South Australia, and Tasmania model components",
  region = "Southern and eastern Australia",
  ocean = "Southwest Pacific and Southern Ocean",
  notes = "One AFMA assessment stock with three model components (Bass Strait, South Australia, and Tasmania)."
))
assessment <- rows(assessment_fields, list(
  assessment_id = assessment_id,
  stock_id = stock_id,
  assessment_year = 2023L,
  terminal_year = 2022L,
  estimate_terminal_year = 2022L,
  assessment_type = "full_assessment",
  model_family = "Age-structured population model",
  model_version = "Bridge 17, official 2023 base case",
  is_current = TRUE,
  is_applied = TRUE,
  framework_year = NA_integer_,
  assessment_url = report_url,
  framework_url = "",
  data_url = species_url,
  model_url = "",
  repository_url = "",
  assumptions_status = "partial",
  inputs_status = "partial",
  outputs_status = "partial",
  notes = "The report provides removals and selected fitted summary values, but not numerical CPUE, age-composition, conditional age-at-length, or age-specific population output arrays. No model code or fitted object was located in the reviewed sources."
))

append_rows <- function(path, value) {
  connection <- file(path, open = "rb")
  first_bytes <- readBin(connection, what = "raw", n = 4096L)
  close(connection)
  newline <- if (any(first_bytes == as.raw(13L))) "\r\n" else "\n"
  utils::write.table(value, path, sep = ",", row.names = FALSE, col.names = FALSE,
    quote = TRUE, qmethod = "double", na = "", append = TRUE, eol = newline)
}
replace_row_text <- function(path, key_prefix, old_text, new_text) {
  lines <- readLines(path, warn = FALSE)
  row <- which(vapply(lines, function(line) any(startsWith(line, key_prefix)), logical(1)))
  if (length(row) != 1L) stop("Expected one matching row in ", path, call. = FALSE)
  if (grepl(new_text, lines[row], fixed = TRUE)) return(invisible(NULL))
  matches <- gregexpr(old_text, lines[row], fixed = TRUE)[[1]]
  if (length(matches) != 1L || matches[1] < 0L) {
    stop("Unexpected CSV row content in ", path, call. = FALSE)
  }
  lines[row] <- sub(old_text, new_text, lines[row], fixed = TRUE)
  connection <- file(path, open = "rb")
  first_bytes <- readBin(connection, what = "raw", n = 4096L)
  close(connection)
  newline <- if (any(first_bytes == as.raw(13L))) "\r\n" else "\n"
  writeLines(lines, path, sep = newline, useBytes = TRUE)
}

cat("Stock:", stock_id, "\n")
cat("Import rows:", nrow(input_rows), "catch;", nrow(output_rows), "outputs;",
  nrow(assumptions), "assumptions\n")
cat("Catch coverage:", min(catch_rows$year), "-", max(catch_rows$year),
  "across", length(unique(catch_rows$fleet)), "fleets and",
  length(unique(catch_rows$region)), "components\n")

if (write_mode) {
  if (!stock_exists) {
    append_rows(file.path(root, "database/stocks.csv"), stock)
    append_rows(file.path(root, "database/assessments.csv"), assessment)
    append_rows(file.path(root, "database/assumptions.csv"), assumptions)
    append_rows(file.path(root, "database/inputs.csv"), input_rows)
    append_rows(file.path(root, "database/outputs.csv"), output_rows)
  }
  replace_row_text(candidates_path, paste0("\"", candidate_id, "\","),
    paste0("\"", retrieved_on, "\",\"\",\"new\",\"screened\",\"unresolved\",\"not_started\","),
    paste0("\"", retrieved_on, "\",\"", stock_id, "\",\"matched\",\"screened\",\"unresolved\",\"partial\","))
  replace_row_text(candidates_path, paste0("\"", candidate_id, "\","),
    "excluded from the accepted Bridge 17 base case.",
    "excluded from the official Bridge 17 base case.")
  replace_row_text(selected_path, c(paste0("1,\"", candidate_id, "\","),
      paste0("\"1\",\"", candidate_id, "\",")),
    "\"selected_for_source_curation\"", "\"partial_source_import\"")
  source(file.path(root, "scripts/database/195_summarize_discovery.R"),
    local = new.env(parent = globalenv()))
  source(file.path(root, "scripts/database/196_summarize_inventory_units.R"),
    local = new.env(parent = globalenv()))
  cat("Imported the verified source tables and marked the assessment partial.\n")
}
