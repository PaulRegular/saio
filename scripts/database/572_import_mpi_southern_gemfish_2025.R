root <- "."
args <- commandArgs(trailingOnly = TRUE)
write_mode <- "--write" %in% args
candidate_only <- "--candidate-only" %in% args

stock_id <- "mpi_gemfish_southern_ski3_ski7"
assessment_id <- "mpi_gemfish_ski3_ski7_2025"
candidate_id <- "MPI:SKI3+SKI7"

source_files <- c(
  "source_cache/mpi_gemfish_ski3_ski7_2025/FAR-2026-39-southern-gemfish-SKI3-SKI7.pdf",
  "source_cache/mpi_gemfish_ski3_ski7_2025/FAR-2023-22-southern-gemfish-catch-at-age-2020-21.pdf",
  "source_cache/mpi_gemfish_ski3_ski7_2025/FAR-2024-01-southern-gemfish-catch-at-age-2021-22.pdf",
  "source_cache/mpi_gemfish_ski3_ski7_2025/FAR-2025-05-southern-gemfish-catch-at-age-2022-23.pdf"
)
source_urls <- c(
  "https://fs.fish.govt.nz/Doc/26272/FAR-2026-39-2025-stock-assessment-gemfish-in-SKI3-and-SKI7.pdf.ashx",
  "https://webstatic.niwa.co.nz/library/FAR2023-22.pdf",
  "https://webstatic.niwa.co.nz/library/FAR2024-01.pdf",
  "https://fs.fish.govt.nz/Doc/25855/FAR-2025-05-Catch-at-age-for-BAR5-and-SKI3-and-SKI7-for-the-2022-23-fishing-year.pdf.ashx"
)
expected_hash <- c(
  "449E200CB92A548C42F61B464CBD334E5E21F95378B5515B6262658CF7986580",
  "CB31AA23FEF22E2A69F6D2857B3CA2FB527316F6739C5D980BF24870C4F997B2",
  "2ED123CB2B13B135DCDB59A9826CD3DF37704F74DD4544A9085721C2654FE015",
  "E977D5C7CD869F232E0AB4693ADDF49CE0363C099EC842B7D0F89C16664F1ED4"
)

if (!all(file.exists(source_files))) {
  stop("Cache the reviewed assessment and catch-age reports before importing.", call. = FALSE)
}
actual_hash <- unname(toupper(tools::sha256sum(source_files)))
if (!identical(actual_hash, expected_hash)) {
  stop("A cached Fisheries New Zealand source differs from the reviewed file.", call. = FALSE)
}

manifest <- data.frame(
  local_file = source_files,
  source_url = source_urls,
  retrieved_on = "2026-11-05",
  sha256 = expected_hash,
  stringsAsFactors = FALSE
)

catch_history <- read.table(text = "
year ski3 ski7
1975 206 44
1976 10 43
1977 5 89
1978 492 1284
1979 2524 754
1980 2279 1109
1981 1643 2003
1982 1166 810
1983 2400 1200
1984 4177 2089
1985 3040 1789
1986 6535 1762
1987 2250 1176
1988 1830 1180
1989 1239 1191
1990 1280 1025
1991 678 358
1992 316 642
1993 408 516
1994 83 353
1995 176 113
1996 54 89
1997 64 262
1998 30 48
1999 19 65
2000 68 118
2001 52 96
2002 79 135
2003 127 295
2004 86 596
2005 79 699
2006 30 273
2007 29 230
2008 20 197
2009 12 234
2010 22 158
2011 36 331
2012 12 286
2013 25 257
2014 43 295
2015 23 254
2016 88 205
2017 273 474
2018 512 641
2019 634.7 1030.7
2020 565.4 1031.8
2021 1169.3 1113.2
2022 969.1 864.6
2023 1449.8 1185.8
2024 2068.0 1532.0
2025 1414 1173
", header = TRUE)

survey_index <- read.table(text = "
SKI3|Shinkai Maru|SHI8102|1981|Feb|4170|19
SKI3|Shinkai Maru|SHI8201|1982|Mar-Apr|3635|32
SKI3|Shinkai Maru|SHI8303|1983|Apr|6056|33
SKI3|Tangaroa|TAN9301|1993|Feb-Mar|901|19
SKI3|Tangaroa|TAN9402|1994|Feb-Mar|327|22
SKI3|Tangaroa|TAN9502|1995|Feb-Mar|508|25
SKI3|Tangaroa|TAN9604|1996|Feb-Mar|454|27
SKI7|Kaharoa|KAH9204|1992|Mar-Apr|144|18
SKI7|Kaharoa|KAH9404|1994|Mar-Apr|67|29
SKI7|Kaharoa|KAH9504|1995|Mar-Apr|21|55
SKI7|Kaharoa|KAH9701|1997|Mar-Apr|704|83
SKI7|Kaharoa|KAH0004|2000|Mar-Apr|120|30
SKI7|Kaharoa|KAH0304|2003|Mar-Apr|137|23
SKI7|Kaharoa|KAH0503|2005|Mar-Apr|474|49
SKI7|Kaharoa|KAH0704|2007|Mar-Apr|101|19
SKI7|Kaharoa|KAH0904|2009|Mar-Apr|143|29
SKI7|Kaharoa|KAH1104|2011|Mar-Apr|101|34
SKI7|Kaharoa|KAH1305|2013|Mar-Apr|113|28
SKI7|Kaharoa|KAH1503|2015|Mar-Apr|186|17
SKI7|Kaharoa|KAH1703|2017|Mar-Apr|545|28
SKI7|Kaharoa|KAH1902|2019|Mar-Apr|559|22
SKI7|Kaharoa|KAH2103|2021|Mar-Apr|433|26
SKI7|Kaharoa|KAH2303|2023|Mar-Apr|758|26
SKI7|Tangaroa|TAN1210|2012|Jul-Aug|14|32
SKI7|Tangaroa|TAN1308|2013|Aug|11|43
SKI7|Tangaroa|TAN1609|2016|Aug|127|23
SKI7|Tangaroa|TAN1807|2018|Jul-Aug|702|33
SKI7|Tangaroa|TAN2107|2021|Jul-Aug|754|18
SKI7|Tangaroa|TAN2407|2024|Jul-Aug|755|21
", sep = "|", header = FALSE, col.names = c(
  "region", "vessel", "trip", "year", "season", "biomass", "cv_percent"
), stringsAsFactors = FALSE)
survey_index$year <- as.integer(survey_index$year)
survey_index$biomass <- as.numeric(survey_index$biomass)
survey_index$cv_percent <- as.numeric(survey_index$cv_percent)
survey_index$survey <- paste(survey_index$region, survey_index$vessel)

input <- function(type, measure, basis, value, unit, year, year_basis = "model_year",
                  fleet = "", survey = "", region = "", season = "",
                  source_reference, transformation = "", notes = "",
                  observation_id = "", sampling_time = NA_real_) {
  data.frame(
    assessment_id, type, measure, basis, fleet, survey, sex = "", region, season,
    year = as.integer(year), year_basis, age = NA_real_, value = as.numeric(value),
    unit, sampling_time, source_type = "official_table", source_reference,
    transformation, notes, observation_id, length_bin = NA_real_,
    length_bin_lower = NA_real_, length_bin_upper = NA_real_, sample_size = NA_real_,
    age_error = NA_real_, partition = "", stringsAsFactors = FALSE
  )
}

catch_inputs <- do.call(rbind, lapply(seq_len(nrow(catch_history)), function(i) {
  do.call(rbind, lapply(c("SKI 3", "SKI 7"), function(region) {
    fleet <- paste(region, "commercial bottom-trawl fishery")
    value <- catch_history[[tolower(gsub(" ", "", region))]][i]
    is_projection <- catch_history$year[i] == 2025L
    input(
      "catch", "total_biomass", "biomass", value, "tonnes",
      catch_history$year[i], fleet = fleet, region = region,
      source_reference = "Fisheries New Zealand FAR 2026/39, Appendix 15, p. 92",
      transformation = "Reported model catch; source adjustments are already applied.",
      notes = if (is_projection) {
        "The report states the 2024-25 model catch was assigned as the average of the five most recent fishing years. The reported Appendix 15 value is retained; the averaging calculation is not reconstructed from the rounded displayed series."
      } else {
        "The model series includes the report's 20% catch uplift before the 1986 QMS introduction and 10% from 1986 onward. Fishing years are October-September and labelled by the ending calendar year."
      },
      observation_id = paste0("catch_", tolower(gsub(" ", "", region)), "_", catch_history$year[i])
    )
  }))
}))

index_inputs <- do.call(rbind, lapply(seq_len(nrow(survey_index)), function(i) {
  common <- list(
    year = survey_index$year[i], survey = survey_index$survey[i],
    region = survey_index$region[i], season = survey_index$season[i],
    source_reference = "Fisheries New Zealand FAR 2026/39, Table 9, p. 36",
    observation_id = survey_index$trip[i]
  )
  rbind(
    do.call(input, c(list(
      type = "index", measure = "total_biomass", basis = "biomass",
      value = survey_index$biomass[i], unit = "tonnes",
      notes = "Survey biomass index used as abundance information; source calculation assumes area availability, vertical availability, and vulnerability are all 1. The assessment uses estimated survey catchability. Survey date is recorded as month or month range; the assessment is an annual-step model and gives no within-year fraction."
    ), common)),
    do.call(input, c(list(
      type = "index", measure = "biomass_index_cv", basis = "relative_scale",
      value = survey_index$cv_percent[i] / 100, unit = "ratio",
      transformation = "Source-reported percent CV divided by 100.",
      notes = "Source reports the CV as a percentage. The ratio is preserved separately from the biomass index."
    ), common))
  )
}))

inputs <- rbind(catch_inputs, index_inputs)

assumption <- function(component, setting, value, source_reference, notes = "") {
  data.frame(
    assessment_id, component, fleet = "", survey = "", sex = "", region = "",
    season = "", setting, value, source_reference, notes,
    stringsAsFactors = FALSE
  )
}

assumptions <- rbind(
  assumption("assessment", "selected_base_case", "Survey-abundance growth model",
    "Fisheries New Zealand FAR 2026/39, sections 4.6.1-4.7",
    "The working group rejected the CPUE-abundance alternatives as biologically implausible and accepted the survey-abundance growth model as the base model."),
  assumption("model", "software", "Casal2; package version not stated for this run",
    "Fisheries New Zealand FAR 2026/39, section 4.1 and references",
    "The report cites the Casal2 v22.04 manual but does not identify the exact software build used for this assessment."),
  assumption("population", "model_dimensions", "Fishing years 1975-2025; ages 1-15+; recruitment age 1; male and female; one annual timestep",
    "Fisheries New Zealand FAR 2026/39, section 4.1",
    "The 1975 state is treated as relatively unexploited (B1975 approximately B0)."),
  assumption("population", "spatial_distribution", "One homogeneous SKI 3 and SKI 7 stock complex",
    "Fisheries New Zealand FAR 2026/39, section 4.1",
    "The assessment does not model spatial subpopulations; different observation series have separate selectivity."),
  assumption("timing", "model_year", "October-September fishing year labelled by ending calendar year",
    "Fisheries New Zealand FAR 2026/39, section 4.1",
    "The model has one annual time step and assumes homogeneous distribution within the year."),
  assumption("catch", "catch_adjustment", "20% uplift before 1986; 10% uplift from 1986; 2024-25 model catch assigned from a five-year average",
    "Fisheries New Zealand FAR 2026/39, section 4.2 and Appendix 15",
    "The exact average for 2025 is not reproducible from the rounded values displayed in Appendix 15; the report's catch values are retained as printed."),
  assumption("index", "selected_abundance_data", "Four trawl-survey biomass series; abundance-only model excludes commercial CPUE indices",
    "Fisheries New Zealand FAR 2026/39, sections 4.3.2 and 4.6",
    "Survey series are SKI 3 Shinkai Maru, SKI 3 Tangaroa, SKI 7 Kaharoa, and SKI 7 Tangaroa. Each has a separate catchability parameter."),
  assumption("mortality", "natural_mortality", "M = 0.25 per year for both sexes; sensitivities at 0.20 and 0.30",
    "Fisheries New Zealand FAR 2026/39, section 4.4.2 and Table 13",
    "Natural mortality is fixed in the base model."),
  assumption("recruitment", "stock_recruitment", "Beverton-Holt; steepness h = 0.85; sensitivities at 0.75 and 0.95; recruitment deviations 1975-2023; sigmaR = 1.8",
    "Fisheries New Zealand FAR 2026/39, sections 4.4.3 and 4.5.2, Table 14",
    "The report identifies 49 estimable year-class strengths; no annual numerical recruitment output series is tabulated."),
  assumption("maturity", "maturity_at_age", "(0.1, 0.4, 0.8, 1.0) for ages 1-5; both sexes",
    "Fisheries New Zealand FAR 2026/39, section 4.4.4 and Table 13",
    "The report lists four values for five ages without specifying which ages share a value. The original statement is preserved; no age-specific vector is inferred."),
  assumption("growth", "von_bertalanffy", "Male Linf 88.5 cm, K 0.242, t0 -0.68; female Linf 104.2 cm, K 0.178, t0 -0.86",
    "Fisheries New Zealand FAR 2026/39, Table 13",
    "Table 14 also lists growth parameters as estimated in the base model; final fitted growth values are not tabulated numerically in the report."),
  assumption("biology", "length_weight", "Mean weight (tonnes) = a * length(cm)^b; male a=1.2e-9, b=3.41; female a=9.5e-10, b=3.47",
    "Fisheries New Zealand FAR 2026/39, Table 13",
    "The assessment report does not provide a direct weight-at-age matrix."),
  assumption("composition", "age_data_coverage", "Four SKI 3 Tangaroa surveys (1993-1996); recent observer fishery age compositions reported for 2021-22 through 2023-24",
    "Fisheries New Zealand FAR 2026/39, section 4.3.3 and Tables 10-11",
    "The assessment report gives sample counts and coverage but not the fitted numerical vectors. Its cited companion reports cover 2020-21, 2021-22, and 2022-23; the year mismatch is unresolved, so those values are not represented as selected-run likelihood inputs."),
  assumption("uncertainty", "model_uncertainty", "MCMC attempts did not achieve statistically acceptable convergence",
    "Fisheries New Zealand FAR 2026/39, section 4.10 and Executive Summary",
    "The published MPD outputs have no uncertainty intervals; the report says the assessment could not provide uncertainty measures on predictive outcomes.")
)

status <- data.frame(
  scenario = c("Base", "baseH75", "baseH95", "baseM20", "baseM30"),
  B0 = c(41103, 39852, 42110, 30930, 50898),
  ratio_2025 = c(1.76, 1.55, 1.91, 1.03, 2.12),
  U40 = c(0.18, 0.17, 0.19, 0.15, 0.22),
  U2025 = c(0.036, 0.042, 0.032, 0.081, 0.024),
  Uratio = c(0.200, 0.221, 0.168, 0.540, 0.109),
  stringsAsFactors = FALSE
)
output_rows <- lapply(seq_len(nrow(status)), function(i) {
  measures <- data.frame(
    type = c("biomass", "biomass", "mortality", "mortality", "mortality"),
    measure = c("unfished_spawning_biomass", "SSB_ratio_to_B0",
      "exploitation_rate_reference_at_SB40", "exploitation_rate",
      "exploitation_rate_ratio_to_SB40_reference"),
    year = c(NA_integer_, 2025L, NA_integer_, 2025L, 2025L),
    value = c(status$B0[i], status$ratio_2025[i], status$U40[i],
      status$U2025[i], status$Uratio[i]),
    unit = c("tonnes", "ratio", "ratio", "ratio", "ratio"),
    notes = c(
      "B0 is the model's unfished mature-biomass estimate.",
      "Source-reported 2025 SSB as a proportion of B0; the absolute SSB trajectory is not tabulated.",
      "Annual proportional-removal rate producing 40% B0 under deterministic projection; not instantaneous F.",
      "Source-reported annual exploitation rate U for 2025; not instantaneous F.",
      "Source-reported U2025 divided by the UB040% reference."
    ),
    stringsAsFactors = FALSE
  )
  data.frame(
    assessment_id, measures, fleet = "", survey = "", sex = "", region = "",
    season = "", age = NA_real_, age_group = "", se = NA_real_, lwr = NA_real_,
    upr = NA_real_, source_type = "official_table",
    source_reference = "Fisheries New Zealand FAR 2026/39, Table 17, p. 50",
    scenario = status$scenario[i], stringsAsFactors = FALSE
  )
})
outputs <- do.call(rbind, output_rows)
outputs <- outputs[c(
  "assessment_id", "type", "measure", "fleet", "survey", "sex", "region",
  "season", "year", "age", "age_group", "value", "se", "lwr", "upr",
  "unit", "source_type", "source_reference", "notes", "scenario"
)]

stock <- data.frame(
  stock_id, charbonneau_id = "", authority = "Fisheries New Zealand",
  authority_stock_id = "SKI 3 + SKI 7", scientific_name = "Rexea solandri",
  common_name = "Southern gemfish",
  area = "Southern biological stock complex (SKI 3 and SKI 7)",
  region = "South Island, New Zealand waters", ocean = "Southwest Pacific",
  notes = "Fisheries New Zealand treats SKI 3 and SKI 7 as one southern biological stock complex.",
  stringsAsFactors = FALSE
)
assessment <- data.frame(
  assessment_id, stock_id, assessment_year = 2025L, terminal_year = 2025L,
  estimate_terminal_year = 2025L, assessment_type = "full_assessment",
  model_family = "Casal2",
  model_version = "2025 survey-abundance growth base model; exact build not stated",
  is_current = TRUE, is_applied = TRUE, framework_year = 2025L,
  assessment_url = source_urls[1L],
  framework_url = "https://fs.fish.govt.nz/Doc/26039/gemfish-ski-fisheries-assessment-plenary-may-2025-volume-1.pdf.ashx",
  data_url = source_urls[4L], model_url = "", repository_url = "",
  assumptions_status = "partial", inputs_status = "partial", outputs_status = "partial",
  notes = paste(
    "Latest detailed official assessment located for the current southern biological stock complex (SKI 3 + SKI 7).",
    "The selected survey-abundance growth model reports MPD point estimates; attempted MCMC did not achieve acceptable convergence, so no uncertainty measures were available.",
    "The source assessment's numeric catch history and survey biomass indices are imported. Exact recent fishery and survey age-composition vectors, direct age weights, and an unambiguous numeric maturity schedule were not recovered."
  ),
  stringsAsFactors = FALSE
)

candidate_path <- "discovery/candidates.csv"
candidates <- read.csv(candidate_path, stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
candidate_row <- which(candidates$candidate_id == candidate_id)
if (length(candidate_row) != 1L) {
  stop("Expected exactly one screened southern gemfish candidate.", call. = FALSE)
}
candidates$matched_stock_id[candidate_row] <- stock_id
candidates$eligibility[candidate_row] <- "unresolved"
candidates$import_status[candidate_row] <- "partial"
candidates$catch_age_evidence[candidate_row] <- paste(
  "The assessment report lists recent observer age compositions but gives sample counts, not fitted vectors.",
  "Three companion reports publish calculated numbers-at-age and CVs for 2020-21, 2021-22, and 2022-23.",
  "The assessment describes fitted observer age data for 2021-22 through 2023-24; the year mapping differs and is unresolved, so companion values are not treated as exact fitted inputs."
)
candidates$survey_age_evidence[candidate_row] <- paste(
  "Imported all 29 survey biomass indices and source CVs from Table 9.",
  "The assessment lists survey age data for four SKI 3 Tangaroa trips in 1993-1996 but does not publish the numerical age vectors."
)
candidates$weights_evidence[candidate_row] <- paste(
  "The report provides sex-specific growth and length-weight parameter values, but no direct weight-at-age matrix.",
  "Table 14 identifies growth parameters as estimated; final fitted values are not tabulated."
)
candidates$maturity_evidence[candidate_row] <- paste(
  "Table 13 states (0.1, 0.4, 0.8, 1.0) for ages 1-5 and both sexes, but gives four values for five ages.",
  "No age-specific vector is inferred."
)
candidates$mortality_evidence[candidate_row] <- "Imported fixed natural mortality M = 0.25 per year for both sexes; sensitivities at 0.20 and 0.30 are reported."
candidates$timing_evidence[candidate_row] <- paste(
  "Fishing years are October-September and labelled by the ending calendar year; the model has one annual step.",
  "Survey trip months/ranges are recorded, but no within-year model fraction is specified."
)
candidates$output_evidence[candidate_row] <- paste(
  "Imported Table 17 MPD values for B0, 2025 SSB/B0, the UB040% removal reference, U2025, and U2025/UB040% across the base and four sensitivities.",
  "MCMC attempts failed; no uncertainty intervals or annual N/F/recruitment arrays are tabulated."
)
candidates$decision_reason[candidate_row] <- paste(
  "Partial source import completed for the latest detailed assessment of the current SKI 3 + SKI 7 biological stock complex.",
  "Eligibility remains unresolved because age-composition mapping, direct age weights, and the numeric maturity schedule are not verified for the selected run."
)
candidates$notes[candidate_row] <- paste(
  "One southern biological stock complex; do not create separate stock records for SKI 3 and SKI 7.",
  "The selected model's MPD status outputs are not accompanied by acceptable MCMC uncertainty estimates."
)

write_candidate_row <- function() {
  con <- textConnection("candidate_line", open = "w", local = TRUE)
  write.table(candidates[candidate_row, , drop = FALSE], con, sep = ",",
    quote = TRUE, row.names = FALSE, col.names = FALSE, na = "", qmethod = "double")
  close(con)
  source_bytes <- readBin(candidate_path, what = "raw", n = file.info(candidate_path)$size)
  source_text <- rawToChar(source_bytes)
  pattern <- '(?m)^"MPI:SKI3\\+SKI7",[^\r\n]*'
  location <- regexpr(pattern, source_text, perl = TRUE, useBytes = TRUE)
  if (location[1L] < 0L || attr(location, "match.length") <= 0L) {
    stop("Could not locate the existing southern gemfish candidate row.", call. = FALSE)
  }
  first <- as.integer(location[1L])
  last <- first + as.integer(attr(location, "match.length")) - 1L
  new_bytes <- c(
    if (first > 1L) source_bytes[seq_len(first - 1L)] else raw(),
    charToRaw(candidate_line[1L]),
    if (last < length(source_bytes)) source_bytes[seq.int(last + 1L, length(source_bytes))] else raw()
  )
  con <- file(candidate_path, open = "wb")
  writeBin(new_bytes, con)
  close(con)
}

cat("Extracted ", nrow(catch_inputs), " catches, ", nrow(index_inputs) / 2L,
  " survey biomass indices with CVs, ", nrow(assumptions), " assumptions and ",
  nrow(outputs), " reported output rows.\n", sep = "")

if (write_mode) {
  database_dir <- "database"
  id_in_file <- function(path, id) {
    con <- file(path, open = "r")
    on.exit(close(con))
    prefix <- paste0("\"", id, "\",")
    repeat {
      lines <- readLines(con, n = 20000L, warn = FALSE)
      if (!length(lines)) return(FALSE)
      if (any(startsWith(lines, prefix))) return(TRUE)
    }
  }
  checks <- c(
    stocks = id_in_file(file.path(database_dir, "stocks.csv"), stock_id),
    assessments = id_in_file(file.path(database_dir, "assessments.csv"), assessment_id),
    assumptions = id_in_file(file.path(database_dir, "assumptions.csv"), assessment_id),
    inputs = id_in_file(file.path(database_dir, "inputs.csv"), assessment_id),
    outputs = id_in_file(file.path(database_dir, "outputs.csv"), assessment_id)
  )
  if (any(checks)) stop("Refusing to duplicate a southern gemfish canonical record.", call. = FALSE)

  append_csv <- function(data, path) {
    write.table(data, path, sep = ",", quote = TRUE, row.names = FALSE,
      col.names = FALSE, append = TRUE, na = "", qmethod = "double")
  }
  append_csv(stock, file.path(database_dir, "stocks.csv"))
  append_csv(assessment, file.path(database_dir, "assessments.csv"))
  append_csv(assumptions, file.path(database_dir, "assumptions.csv"))
  append_csv(inputs, file.path(database_dir, "inputs.csv"))
  append_csv(outputs, file.path(database_dir, "outputs.csv"))
  write_candidate_row()
  write.csv(manifest, "provenance/mpi_gemfish_ski3_ski7_2025_sources.csv",
    row.names = FALSE, na = "")
}

if (candidate_only) write_candidate_row()
