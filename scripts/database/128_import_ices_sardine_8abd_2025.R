root <- "."
database_dir <- file.path(root, "database")
cache_dir <- file.path(root, "source_cache", "ck_ices_wghansa_pilchardus_sp8abd_2025")
assessment_id <- "ices_sardine_bay_biscay_8abd_2025_summary"
stock_id <- "ck_ices_wghansa_pilchardus_sp8abd"
report_url <- "https://ices-library.figshare.com/articles/report/Working_Group_on_Southern_Horse_Mackerel_Anchovy_and_Sardine_WGHANSA_/29335520"
data_url <- "https://standardgraphs.ices.dk/ViewSourceData.aspx?key=21258"
repository_url <- "https://github.com/ices-advice/2025_pil.27.8abd/tree/242f57e7a04cd78f30402d7c2c97fa98c197b4bc"

sag_path <- file.path(cache_dir, "ICES_SAG_2025_key_21258.xml")
if (!requireNamespace("xml2", quietly = TRUE) || !file.exists(sag_path)) {
  stop("The cached ICES SAG XML and xml2 are required.", call. = FALSE)
}
sag <- xml2::read_xml(sag_path)
xml_value <- function(node, name) {
  value <- xml2::xml_text(xml2::xml_find_first(node, paste0("./", name)))
  if (!length(value) || !nzchar(trimws(value))) NA_character_ else trimws(value)
}
as_number <- function(x) suppressWarnings(as.numeric(x))

if (xml_value(sag, "./StockCode") != "pil.27.8abd" ||
    as.integer(xml_value(sag, "./AssessmentYear")) != 2025L ||
    as.integer(xml_value(sag, "./RecruitmentAge")) != 0L) {
  stop("The cached SAG XML is not the 2025 pil.27.8abd source.", call. = FALSE)
}
interval_definition <- xml_value(sag, "ConfidenceIntervalDefinition")
if (!identical(interval_definition, "95%")) {
  stop("The cached SAG XML does not identify 95% bounds.", call. = FALSE)
}
fish_data <- xml2::xml_find_all(sag, ".//Fish_Data")
source_values <- do.call(rbind, lapply(fish_data, function(node) {
  data.frame(
    year = as.integer(as_number(xml_value(node, "Year"))),
    recruitment = as_number(xml_value(node, "Recruitment")),
    recruitment_lwr = as_number(xml_value(node, "Low_Recruitment")),
    recruitment_upr = as_number(xml_value(node, "High_Recruitment")),
    ssb = as_number(xml_value(node, "StockSize")),
    ssb_lwr = as_number(xml_value(node, "Low_StockSize")),
    ssb_upr = as_number(xml_value(node, "High_StockSize")),
    catch = as_number(xml_value(node, "Catches")),
    fbar = as_number(xml_value(node, "FishingPressure")),
    fbar_lwr = as_number(xml_value(node, "Low_FishingPressure")),
    fbar_upr = as_number(xml_value(node, "High_FishingPressure")),
    stringsAsFactors = FALSE
  )
}))
source_values <- source_values[order(source_values$year), , drop = FALSE]
if (!identical(source_values$year, 2000:2025) ||
    any(!is.finite(source_values$recruitment)) ||
    any(!is.finite(source_values$ssb)) ||
    any(!is.finite(source_values$catch)) ||
    any(!is.finite(source_values$fbar)) ||
    any(source_values$ssb_lwr > source_values$ssb | source_values$ssb > source_values$ssb_upr,
      na.rm = TRUE)) {
  stop("The SAG output series failed identity, coverage, or range checks.", call. = FALSE)
}
# SAG reports recruitment as fish; the assessment table reports thousand fish.
source_values$recruitment <- source_values$recruitment / 1000
source_values$recruitment_lwr <- source_values$recruitment_lwr / 1000
source_values$recruitment_upr <- source_values$recruitment_upr / 1000

read_table <- function(file) utils::read.csv(file, check.names = FALSE,
  stringsAsFactors = FALSE, na.strings = c("", "NA"))
write_table <- function(x, file) utils::write.csv(x, file, row.names = FALSE, na = "")
inputs_file <- file.path(database_dir, "inputs.csv")
outputs_file <- file.path(database_dir, "outputs.csv")
assumptions_file <- file.path(database_dir, "assumptions.csv")
stocks_file <- file.path(database_dir, "stocks.csv")
assessments_file <- file.path(database_dir, "assessments.csv")
inputs <- read_table(inputs_file)
outputs <- read_table(outputs_file)
assumptions <- read_table(assumptions_file)
stocks <- read_table(stocks_file)
assessments <- read_table(assessments_file)

align_columns <- function(x, template) {
  missing <- setdiff(names(template), names(x))
  for (name in missing) x[[name]] <- NA
  x[names(template)]
}

stock_index <- match(stock_id, stocks$stock_id)
if (is.na(stock_index) || sum(stocks$stock_id == stock_id) != 1L) {
  stop("Expected one existing Charbonneau-Keith stock record.", call. = FALSE)
}
stocks$authority_stock_id[stock_index] <- "pil.27.8abd"
stocks$common_name[stock_index] <- "Bay of Biscay sardine"
stocks$area[stock_index] <- "ICES divisions 8.a, 8.b, and 8.d"
stocks$region[stock_index] <- "Bay of Biscay"
stocks$notes[stock_index] <- paste(
  "ICES stock pil.27.8abd, sardine in divisions 8.a, 8.b, and 8.d (Bay of Biscay).",
  "Charbonneau-Keith Master identity is retained; see the stock source review for assessment coverage and gaps."
)

assessment <- data.frame(
  assessment_id = assessment_id, stock_id = stock_id,
  assessment_year = 2025L, terminal_year = 2024L,
  estimate_terminal_year = 2025L, assessment_type = "annual",
  model_family = "Stock Synthesis", model_version = "SS3 3.24",
  is_current = FALSE, is_applied = TRUE, framework_year = 2017L,
  assessment_url = report_url, framework_url = "", data_url = data_url,
  model_url = "", repository_url = repository_url,
  assumptions_status = "partial", inputs_status = "partial",
  outputs_status = "partial",
  notes = paste(
    "Summary-only record: the 2025 report provides aggregate outputs through 2025; fitted model data end in 2024.",
    "The 2025 row uses geometric-mean recruitment and preliminary catch, with resultant F.",
    "Native age-composition, acoustic/egg survey, biological, and N/F-at-age files remain unavailable; this is not the current detailed record."
  ), stringsAsFactors = FALSE
)

assumption_rows <- data.frame(
  assessment_id = assessment_id,
  component = c("population", "data", "recruitment", "fishing_mortality"),
  fleet = "", survey = "", sex = "", region = "Bay of Biscay", season = "",
  setting = c("model", "likelihood_data", "2025_recruitment", "Fbar_age_range"),
  value = c(
    "Age-based Stock Synthesis 3 (SS3); exact 2025 control settings not recovered",
    "Commercial catches and data from acoustic and egg surveys",
    "Geometric mean for 2002-2023; 2025 is a forecast, not a fitted-year recruitment estimate",
    "F(2-5)"
  ),
  source_reference = c(
    "ICES WGHANSA 2025, section 6.3.1, report page 247",
    "ICES WGHANSA 2025, section 6.3.1, report pages 247-248",
    "ICES WGHANSA 2025, Table 6.3.2.1, report page 249",
    "ICES WGHANSA 2025, Table 6.3.2.1, report pages 248-249"
  ),
  notes = c(
    "The TAF software bibliography identifies Stock Synthesis 3.24; the report describes SS3 use since 2019, following the WKPELA benchmark (2017) and 2019 inter-benchmark. The production control file was not recovered.",
    "Original catch-at-age, survey series, likelihood weights, and biological inputs are not present in the available repository checkout.",
    "The table states the geometric-mean recruitment and preliminary catch qualifications for 2025.",
    "The report labels the F output as F(2-5); 2025 F is resultant from preliminary catches."
  ), stringsAsFactors = FALSE
)

input_rows <- data.frame(
  assessment_id = assessment_id, type = "catch", measure = "total_biomass",
  basis = "biomass", fleet = "Commercial_vessels", survey = "", sex = "",
  region = "Bay of Biscay", season = "", year = source_values$year,
  year_basis = "calendar_year", age = NA_real_, age_group = "",
  value = source_values$catch, unit = "tonnes", sampling_time = NA_real_,
  source_type = "official_machine_readable",
  source_reference = "ICES SAG 2025 source data, assessment key 21258; cross-checked to WGHANSA 2025 Table 6.3.2.1",
  transformation = "", notes = ifelse(source_values$year == 2025,
    "Preliminary catch for the 2025 forecast; not a fitted historical-year catch.",
    "Annual commercial total catch; age composition and fleet allocation are not available in this source series."),
  stringsAsFactors = FALSE
)

output_rows <- do.call(rbind, lapply(seq_len(nrow(source_values)), function(i) {
  x <- source_values[i, , drop = FALSE]
  rec_note <- if (x$year == 2025) {
    "2025 is forecast recruitment set to the geometric mean for 2002-2023; no interval is reported."
  } else {
    "Recruitment is divided by 1,000 from the SAG fish count to match Table 6.3.2.1 thousand-fish units. SAG identifies 95% bounds, but the interval method and confidence/credible interpretation are unspecified."
  }
  ssb_note <- if (x$year == 2025) {
    "2025 is a forecast; SAG identifies 95% bounds, but the interval method and confidence/credible interpretation are unspecified."
  } else {
    "SAG identifies 95% bounds, but the interval method and confidence/credible interpretation are unspecified."
  }
  f_note <- if (x$year == 2025) {
    "2025 resultant F(2-5) is based on preliminary catches; no interval is reported."
  } else {
    "Fbar over ages 2-5, cross-checked against WGHANSA 2025 Table 6.3.2.1. SAG identifies 95% bounds, but the interval method and confidence/credible interpretation are unspecified."
  }
  data.frame(
    assessment_id = assessment_id,
    type = c("recruitment", "biomass", "mortality"),
    measure = c("recruitment", "SSB", "Fbar"),
    fleet = "", survey = "", sex = "", region = "Bay of Biscay", season = "",
    year = x$year, age = c(0, NA_real_, NA_real_),
    age_group = c("", "", "2-5"),
    value = c(x$recruitment, x$ssb, x$fbar), se = NA_real_,
    lwr = c(x$recruitment_lwr, x$ssb_lwr, x$fbar_lwr),
    upr = c(x$recruitment_upr, x$ssb_upr, x$fbar_upr),
    unit = c("thousand fish", "tonnes", "per year"),
    source_type = "official_machine_readable",
    source_reference = "ICES SAG 2025 source data, assessment key 21258; values cross-checked against WGHANSA 2025 Table 6.3.2.1",
    notes = c(rec_note, ssb_note, f_note), stringsAsFactors = FALSE
  )
}))

assessments <- assessments[assessments$assessment_id != assessment_id, , drop = FALSE]
assessments <- rbind(assessments, align_columns(assessment, assessments))
inputs <- inputs[inputs$assessment_id != assessment_id, , drop = FALSE]
inputs <- rbind(inputs, align_columns(input_rows, inputs))
outputs <- outputs[outputs$assessment_id != assessment_id, , drop = FALSE]
outputs <- rbind(outputs, align_columns(output_rows, outputs))
assumptions <- assumptions[assumptions$assessment_id != assessment_id, , drop = FALSE]
assumptions <- rbind(assumptions, align_columns(assumption_rows, assumptions))

write_table(stocks, stocks_file)
write_table(assessments, assessments_file)
write_table(assumptions, assumptions_file)
write_table(inputs, inputs_file)
write_table(outputs, outputs_file)
cat(sprintf("Imported %d catch-total rows and %d aggregate output rows for %s.\n",
  nrow(input_rows), nrow(output_rows), assessment_id))
