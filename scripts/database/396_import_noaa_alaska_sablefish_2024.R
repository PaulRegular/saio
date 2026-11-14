root <- "."
assessment_id <- "noaa_alaska_sablefish_2024"
stock_id <- "noaa_alaska_sablefish"
cache <- file.path(root, "source_cache", "discovery_noaa_alaska_sablefish_2024_2025")
revision <- "d080576086110b6dcfca2c37918bab3101fff44a"
data_file <- file.path(cache, "alaska_sablefish_2024_input.dat")
output_file <- file.path(cache, "alaska_sablefish_2024_output.rdat")
source_url <- paste0(
  "https://raw.githubusercontent.com/dgoethel-noaa/2024-Sablefish-SAFE/",
  revision
)

if (!file.exists(data_file) || !file.exists(output_file)) {
  stop("The pinned NOAA Alaska sablefish input and output files are required.", call. = FALSE)
}

data_lines <- readLines(data_file, warn = FALSE)
model_output <- dget(output_file)
model_years <- seq.int(1960L, 2024L)
ages <- 2:31

section <- function(label) {
  start <- which(grepl(label, data_lines, fixed = TRUE))
  if (length(start) != 1L) {
    stop("Expected one input section labelled: ", label, call. = FALSE)
  }
  end <- which(seq_along(data_lines) > start & grepl("^#:\\s*#!", data_lines))[[1L]]
  data_lines[seq.int(start, end - 1L)]
}

values_after <- function(lines, marker, n, occurrence = 1L) {
  hit <- which(grepl(marker, lines, fixed = TRUE))
  if (length(hit) < occurrence) {
    stop("Expected one input marker labelled: ", marker, call. = FALSE)
  }
  hit <- hit[[occurrence]]
  values <- numeric()
  for (line in lines[seq.int(hit + 1L, length(lines))]) {
    line <- trimws(line)
    if (!nzchar(line) || startsWith(line, "#")) next
    line <- sub("\\s+#.*$", "", line)
    tokens <- strsplit(line, "[[:space:]]+")[[1L]]
    parsed <- suppressWarnings(as.numeric(tokens))
    if (anyNA(parsed)) {
      stop("Non-numeric value after input marker: ", marker, call. = FALSE)
    }
    values <- c(values, parsed)
    if (length(values) >= n) break
  }
  if (length(values) != n || any(!is.finite(values))) {
    stop("Unexpected value count after input marker: ", marker, call. = FALSE)
  }
  values
}

matrix_after <- function(lines, marker, nrow, ncol, occurrence = 1L) {
  matrix(values_after(lines, marker, nrow * ncol, occurrence = occurrence), nrow = nrow,
    ncol = ncol, byrow = TRUE)
}

bio_lines <- section("# Model input parameters/vectors")
catch_lines <- section("# Fixed gear fishery catch (mt): #-")
years_and_ages <- values_after(bio_lines,
  "# Start and end years, recruit_age, number of age and length bins", 2L)
inline_number <- function(marker) {
  hit <- which(grepl(marker, data_lines, fixed = TRUE))
  if (length(hit) != 1L) stop("Expected one input scalar labelled ", marker, call. = FALSE)
  value <- sub("^\\s*([0-9]+)\\s+#.*$", "\\1", data_lines[[hit]])
  as.integer(value)
}
recruit_age <- inline_number("# recage")
age_count <- inline_number("# nages")
length_count <- inline_number("# nlenbins")
length_bins <- values_after(bio_lines, "# length bins", length_count)
if (!identical(as.integer(years_and_ages), c(1960L, 2024L)) || recruit_age != 2L ||
  age_count != 30L || length_count != 30L ||
  !identical(length_bins, seq(41, 99, by = 2))) {
  stop("Unexpected model years, age count, or length bins in the input file.", call. = FALSE)
}
ages <- seq_len(age_count) + 1L
length_bins <- as.integer(length_bins)

new_input <- function(type, measure, basis, year = NA_integer_, age = NA_integer_,
                      value, unit, fleet = NA_character_, survey = NA_character_,
                      sex = NA_character_, partition = NA_character_,
                      sample_size = NA_real_, observation_id = NA_character_,
                      length_bin = NA_real_, source_type = "native_model",
                      source_reference, transformation = "Extracted without scaling.",
                      notes = "") {
  n <- length(value)
  repeat_n <- function(x) rep(x, length.out = n)
  year <- repeat_n(year)
  data.frame(
    assessment_id = assessment_id, type = type, measure = measure,
    basis = repeat_n(basis), fleet = repeat_n(fleet), survey = repeat_n(survey),
    sex = repeat_n(sex), region = NA_character_, season = NA_character_,
    year = year, year_basis = ifelse(is.na(year), NA_character_, "calendar_year"),
    age = repeat_n(age), value = value, unit = repeat_n(unit),
    sampling_time = NA_real_, source_type = source_type,
    source_reference = repeat_n(source_reference),
    transformation = repeat_n(transformation), notes = repeat_n(notes),
    observation_id = repeat_n(observation_id), length_bin = repeat_n(length_bin),
    length_bin_lower = NA_real_, length_bin_upper = NA_real_,
    sample_size = repeat_n(sample_size), age_error = NA_character_,
    partition = repeat_n(partition), weight_bin = NA_real_,
    stringsAsFactors = FALSE, check.names = FALSE
  )
}

new_assumption <- function(component, setting, value, source_reference, notes = "") {
  data.frame(
    assessment_id = assessment_id, component = component,
    fleet = NA_character_, survey = NA_character_, sex = NA_character_,
    region = NA_character_, season = NA_character_, setting = setting,
    value = as.character(value), source_reference = source_reference,
    notes = notes, stringsAsFactors = FALSE
  )
}

new_output <- function(type, measure, year, value, unit, sex = NA_character_,
                       age = NA_integer_, age_group = NA_character_, se = NA_real_,
                       lwr = NA_real_, upr = NA_real_, source_type = "native_model",
                       source_reference, notes = "") {
  n <- length(value)
  repeat_n <- function(x) rep(x, length.out = n)
  data.frame(
    assessment_id = assessment_id, type = type, measure = measure,
    fleet = NA_character_, survey = NA_character_, sex = repeat_n(sex),
    region = NA_character_, season = NA_character_, year = year,
    age = repeat_n(age), age_group = repeat_n(age_group), value = value,
    se = repeat_n(se), lwr = repeat_n(lwr), upr = repeat_n(upr),
    unit = repeat_n(unit), source_type = source_type,
    source_reference = source_reference, notes = notes, scenario = NA_character_,
    stringsAsFactors = FALSE
  )
}

composition_inputs <- function(block_label, year_marker, sample_marker,
                               composition_markers, years_count, bins,
                               type, source_name, fleet = NA_character_,
                               survey = NA_character_, raw_sample_column = NULL,
                               raw_samples = NULL, marker_occurrences = NULL) {
  block <- section(block_label)
  years <- as.integer(values_after(block, year_marker, years_count))
  model_sample <- values_after(block, sample_marker, years_count)
  if (!identical(years, sort(unique(years))) || any(model_sample <= 0)) {
    stop("Unexpected years or likelihood sample weights in ", block_label, call. = FALSE)
  }
  fleet <- if (is.null(fleet)) NA_character_ else fleet
  survey <- if (is.null(survey)) NA_character_ else survey
  sample_weight_note <- paste0(
    "Supplied model likelihood sample-size weight(s): ",
    paste(sort(unique(model_sample)), collapse = ", "),
    "; these are relative weights, not raw fish counts."
  )
  rows <- lapply(names(composition_markers), function(sex) {
    occurrence <- if (is.null(marker_occurrences)) 1L else marker_occurrences[[sex]]
    observed <- matrix_after(block, composition_markers[[sex]], years_count,
      length(bins), occurrence = occurrence)
    if (any(observed < 0 | observed > 1)) {
      stop("Composition proportions are outside [0, 1] in ", block_label, call. = FALSE)
    }
    grid <- expand.grid(bin = bins, year = years)
    observation_id <- paste0(source_name, "_", grid$year)
    if (grepl("age", source_name, fixed = TRUE)) {
      new_input(
        type, "proportion_at_age", "proportion_numbers", grid$year, grid$bin,
        as.vector(t(observed)), "proportion", fleet = fleet, survey = survey,
        sex = if (sex == "unsexed") NA_character_ else sex,
        sample_size = rep(model_sample, each = length(bins)),
        observation_id = observation_id, source_reference = paste0(
          "tem_2024_na_wh.dat ", composition_markers[[sex]]
        ),
        notes = paste(
          "Native observed age composition; age 31 is the 31+ group.",
          "The input vector is retained as supplied; the model normalizes each composition internally.",
          sample_weight_note
        )
      )
    } else {
      new_input(
        type, "proportion_at_length", "proportion_numbers", grid$year,
        value = as.vector(t(observed)), unit = "proportion", fleet = fleet,
        survey = survey, sex = if (sex == "unsexed") NA_character_ else sex,
        sample_size = rep(model_sample, each = length(bins)),
        observation_id = observation_id, length_bin = grid$bin,
        source_reference = paste0("tem_2024_na_wh.dat ", composition_markers[[sex]]),
        notes = paste(
          "Native observed length composition; length bins are in cm.",
          sample_weight_note
        )
      )
    }
  })
  out <- do.call(rbind, rows)
  if (!is.null(raw_samples) && !is.null(raw_sample_column)) {
    count_rows <- raw_samples[raw_samples$year %in% years &
      !is.na(raw_samples[[raw_sample_column]]), , drop = FALSE]
    count_rows <- count_rows[match(years[years %in% count_rows$year], count_rows$year), , drop = FALSE]
    if (nrow(count_rows)) {
      count_inputs <- new_input(
        type, "composition_sample_count", "numbers", count_rows$year,
        value = count_rows[[raw_sample_column]], unit = "fish",
        fleet = fleet, survey = survey,
        observation_id = paste0(source_name, "_", count_rows$year),
        source_type = "official_table",
        source_reference = "Sablefish SAFE 2024 Table 3.4 sample-size workbook, age/length data tab",
        notes = paste(
          "Raw fish measured or aged, distinct from the model's supplied relative likelihood sample-size weight.",
          "The workbook's embedded table number differs from its repository filename; source review records the discrepancy."
        )
      )
      out <- rbind(out, count_inputs)
    }
  }
  out
}

read_xlsx_sheet <- function(path) {
  temp <- tempfile("sablefish_xlsx_")
  dir.create(temp)
  on.exit(unlink(temp, recursive = TRUE), add = TRUE)
  utils::unzip(path, exdir = temp)
  shared_path <- file.path(temp, "xl", "sharedStrings.xml")
  sheet_path <- file.path(temp, "xl", "worksheets", "sheet1.xml")
  if (!file.exists(sheet_path)) stop("Expected first worksheet in ", basename(path), call. = FALSE)
  xml_nodes <- function(text, tag) {
    matches <- gregexpr(paste0("<", tag, "\\b[^>]*>.*?</", tag, ">"), text, perl = TRUE)
    if (matches[[1L]][1L] < 0L) return(character())
    regmatches(text, matches)[[1L]]
  }
  inner_text <- function(node) {
    node <- gsub("<[^>]+>", "", node, perl = TRUE)
    node <- gsub("&quot;", "\"", node, fixed = TRUE)
    node <- gsub("&apos;", "'", node, fixed = TRUE)
    node <- gsub("&lt;", "<", node, fixed = TRUE)
    node <- gsub("&gt;", ">", node, fixed = TRUE)
    gsub("&amp;", "&", node, fixed = TRUE)
  }
  shared <- character()
  if (file.exists(shared_path)) {
    shared_xml <- paste(readLines(shared_path, warn = FALSE), collapse = "")
    shared_nodes <- xml_nodes(shared_xml, "si")
    shared <- vapply(shared_nodes, function(node) {
      paste(vapply(xml_nodes(node, "t"), inner_text, character(1L)), collapse = "")
    }, character(1L))
  }
  sheet_xml <- paste(readLines(sheet_path, warn = FALSE), collapse = "")
  row_nodes <- xml_nodes(sheet_xml, "row")
  cell_index <- function(reference) {
    letters <- strsplit(gsub("[0-9]", "", reference), "")[[1L]]
    sum(match(letters, LETTERS) * 26^(rev(seq_along(letters)) - 1L))
  }
  parsed <- lapply(row_nodes, function(row_node) {
    row_num <- as.integer(sub(".*\\br=\"([0-9]+)\".*", "\\1", row_node))
    cells <- xml_nodes(row_node, "c")
    lapply(cells, function(cell) {
      reference <- sub(".*\\br=\"([A-Z]+[0-9]+)\".*", "\\1", cell)
      col <- cell_index(reference)
      type <- if (grepl("\\bt=\"s\"", cell)) "s" else
        if (grepl("\\bt=\"inlineStr\"", cell)) "inlineStr" else ""
      value_node <- xml_nodes(cell, "v")
      value <- if (length(value_node)) inner_text(value_node[[1L]]) else ""
      if (type == "s" && nzchar(value)) value <- shared[[as.integer(value) + 1L]]
      if (type == "inlineStr") {
        value <- paste(vapply(xml_nodes(cell, "t"), inner_text, character(1L)), collapse = "")
      }
      c(row = row_num, col = col, value = value)
    })
  })
  cells <- unlist(parsed, recursive = FALSE)
  if (!length(cells)) stop("No worksheet cells were read from ", basename(path), call. = FALSE)
  cell_table <- do.call(rbind, cells)
  nr <- max(as.integer(cell_table[, "row"]))
  nc <- max(as.integer(cell_table[, "col"]))
  result <- matrix("", nr, nc)
  result[cbind(as.integer(cell_table[, "row"]), as.integer(cell_table[, "col"]))] <- cell_table[, "value"]
  as.data.frame(result, stringsAsFactors = FALSE, check.names = FALSE)
}

sample_file <- file.path(cache, "alaska_sablefish_table_3_4_age_length_sample_sizes.xlsx")
sample_table <- read_xlsx_sheet(sample_file)
header_row <- which(apply(sample_table, 1L, function(row) "Year" %in% row))[[1L]]
header <- as.character(unlist(sample_table[header_row, ], use.names = FALSE))
expected_sample_headers <- c(
  "Year", "Japanese Coop LL Survey", "NOAA LL Survey", "US Fixed Gear Fishery",
  "Japanese Coop LL Survey", "NOAA LL Survey", "NOAA GOA Trawl Survey",
  "US Fixed Gear Fishery", "US Trawl Gear Fishery"
)
header_cols <- which(nzchar(header))
if (!identical(header[header_cols], expected_sample_headers)) {
  stop("The sablefish age/length sample-size table headers have changed.", call. = FALSE)
}
year_col <- header_cols[[1L]]
sample_rows <- seq.int(header_row + 1L, nrow(sample_table))
sample_years <- suppressWarnings(as.integer(as.numeric(sample_table[[year_col]][sample_rows])))
valid_year <- !is.na(sample_years) & sample_years >= 1900L & sample_years <= 2100L
sample_rows <- sample_rows[valid_year]
raw_samples <- data.frame(
  year = sample_years[valid_year],
  japan_age = suppressWarnings(as.numeric(sample_table[[header_cols[[2L]]]][sample_rows])),
  domestic_age = suppressWarnings(as.numeric(sample_table[[header_cols[[3L]]]][sample_rows])),
  fixed_age = suppressWarnings(as.numeric(sample_table[[header_cols[[4L]]]][sample_rows])),
  japan_length = suppressWarnings(as.numeric(sample_table[[header_cols[[5L]]]][sample_rows])),
  domestic_length = suppressWarnings(as.numeric(sample_table[[header_cols[[6L]]]][sample_rows])),
  goa_length = suppressWarnings(as.numeric(sample_table[[header_cols[[7L]]]][sample_rows])),
  fixed_length = suppressWarnings(as.numeric(sample_table[[header_cols[[8L]]]][sample_rows])),
  trawl_length = suppressWarnings(as.numeric(sample_table[[header_cols[[9L]]]][sample_rows]))
)

report_series_table <- read_xlsx_sheet(file.path(cache,
  "alaska_sablefish_table_3_8_recruitment_ssb_biomass.xlsx"))
summary_header_row <- which(apply(report_series_table, 1L,
  function(row) "Year" %in% row))[[1L]]
summary_header <- as.character(unlist(report_series_table[summary_header_row, ], use.names = FALSE))
summary_columns <- c(
  year = "Year", recruits = "Recruits (millions)", recruit_lwr = "2.5% CI",
  recruit_upr = "97.5% CI", ssb = "SSB (kt)", ssb_lwr = "2.5% CI",
  ssb_upr = "97.5% CI", biomass = "Biomass (kt)",
  biomass_lwr = "2.5% CI", biomass_upr = "97.5% CI"
)
summary_positions <- c(4L, 5L, 6L, 7L, 8L, 9L, 10L, 11L, 12L, 13L)
if (!identical(summary_header[summary_positions], unname(summary_columns))) {
  stop("The Table 3.8 annual output table headers have changed.", call. = FALSE)
}
summary_year <- suppressWarnings(as.integer(as.numeric(report_series_table[[4L]])))
summary_rows <- which(!is.na(summary_year) & summary_year %in% model_years)
summary_value <- function(column) suppressWarnings(as.numeric(report_series_table[[column]][summary_rows]))
report_summary <- data.frame(
  year = summary_year[summary_rows],
  recruits = summary_value(5L),
  recruit_lwr = summary_value(6L),
  recruit_upr = summary_value(7L),
  ssb = summary_value(8L),
  ssb_lwr = summary_value(9L),
  ssb_upr = summary_value(10L),
  biomass = summary_value(11L),
  biomass_lwr = summary_value(12L),
  biomass_upr = summary_value(13L)
)
report_matches_output <- function(report_values, model_values) {
  observed <- !is.na(report_values)
  any(observed) && all(round(model_values[match(report_summary$year[observed], model_years)], 1) ==
    report_values[observed])
}
if (anyDuplicated(report_summary$year) || !identical(report_summary$year, model_years) ||
  !report_matches_output(report_summary$recruits, model_output$t.series$Recr) ||
  !report_matches_output(report_summary$ssb, model_output$t.series$spbiom) ||
  !report_matches_output(report_summary$biomass, model_output$t.series$totbiom) ||
  any(is.na(report_summary$ssb_lwr) | is.na(report_summary$ssb_upr)) ||
  any(is.na(report_summary$biomass_lwr) | is.na(report_summary$biomass_upr)) ||
  any(is.na(report_summary$recruit_lwr) != is.na(report_summary$recruits)) ||
  any(is.na(report_summary$recruit_upr) != is.na(report_summary$recruits))) {
  stop("The Table 3.8 annual means do not match the selected native model output.", call. = FALSE)
}

validate_numbers_at_age_table <- function(sex) {
  table_number <- if (sex == "female") "3" else "4"
  report_table <- read_xlsx_sheet(file.path(cache, paste0(
    "alaska_sablefish_table_3c_", table_number, "_", sex, "_numbers_at_age.xlsx"
  )))
  header_row <- which(apply(report_table, 1L, function(row) "Year" %in% row))[[1L]]
  header <- as.character(unlist(report_table[header_row, ], use.names = FALSE))
  year_column <- which(header == "Year")
  if (length(year_column) != 1L) {
    stop("Table 3C.", table_number, " must have one Year column.", call. = FALSE)
  }
  age_columns <- which(grepl("^[0-9]+\\+?$", header))
  report_ages <- as.integer(sub("\\+$", "", header[age_columns]))
  report_year <- suppressWarnings(as.integer(as.numeric(report_table[[year_column]])))
  report_rows <- which(!is.na(report_year) & report_year %in% model_years)
  report_year <- report_year[report_rows]
  reported <- sapply(age_columns, function(column) {
    suppressWarnings(as.numeric(report_table[[column]][report_rows]))
  })
  native <- model_output[[paste0("natage.", sex)]][as.character(report_year), , drop = FALSE]
  if (!identical(report_ages, ages) ||
    !identical(report_year, model_years) || !identical(dim(reported), dim(native)) ||
    !all(round(reported, 4) == round(native, 4))) {
    stop("Table 3C.", table_number, " numbers-at-age do not match the pinned native output for ", sex, ".",
      call. = FALSE)
  }
}
invisible(lapply(c("female", "male"), validate_numbers_at_age_table))

index_data <- list(
  list(label = "# Domestic longline survey RPW", year_marker = "# Domestic survey years",
    value_marker = "# Observed domestic RPW", se_marker = "# SE of observed  biomass",
    n_marker = "# Number of domestic longline years", n_measure = "relative_biomass_index",
    unit = "relative population weight index", type = "index", survey = "NOAA domestic longline survey",
    id = "noaa_domestic_longline_survey_rpw", likelihood_weight = 0),
  list(label = "# Japanese/coop longline survey RPW", year_marker = "# Japan survey years",
    value_marker = "# Observed Japan RPW", se_marker = "# SE of observed  biomass",
    n_marker = "# Number of japanese longline years", n_measure = "relative_biomass_index",
    unit = "relative population weight index", type = "index", survey = "Japanese cooperative longline survey",
    id = "japanese_cooperative_longline_survey_rpw", likelihood_weight = 0),
  list(label = "# Domestic longline survey RPN", year_marker = "# Domestic survey years",
    value_marker = "# Observed domestic RPN", se_marker = "# SE of observed  biomass",
    n_marker = "# Number of domestic longline years", n_measure = "relative_abundance_index",
    unit = "relative population number index", type = "index", survey = "NOAA domestic longline survey",
    id = "noaa_domestic_longline_survey_rpn", likelihood_weight = 0.448),
  list(label = "# Japanese/coop longline survey RPN", year_marker = "# Japan survey years",
    value_marker = "# Observed Japan RPN", se_marker = "# SE of observed  biomass",
    n_marker = "# Number of Japanese longline years", n_measure = "relative_abundance_index",
    unit = "relative population number index", type = "index", survey = "Japanese cooperative longline survey",
    id = "japanese_cooperative_longline_survey_rpn", likelihood_weight = 0.448),
  list(label = "# Domestic Longline Fishery CPUE", year_marker = "# Domestic fishery CPUE years",
    value_marker = "# Observed domestic RPW/CPUE", se_marker = "# SE of observed fishery CPUE",
    n_marker = "# Number of longline fishery CPUE years", n_measure = "relative_biomass_index",
    unit = "relative CPUE", type = "index", fleet = "U.S. fixed-gear longline fishery",
    id = "us_fixed_gear_longline_fishery_cpue", likelihood_weight = 0.448),
  list(label = "# Japanese longline fishery CPUE RPW", year_marker = "# Japanese longline fishery CPUE years",
    value_marker = "# Observed Japanese longline fishery CPUE RPW", se_marker = "# SE of observed  biomass",
    n_marker = "# Number of Japanese longline fishery CPUE years", n_measure = "relative_biomass_index",
    unit = "relative CPUE", type = "index", fleet = "Japanese longline fishery",
    id = "japanese_longline_fishery_cpue", likelihood_weight = 0.448),
  list(label = "# GOA Trawl Survey Biomass (<500 m depth)", year_marker = "# Trawl survey years",
    value_marker = "# Observed trawl biomass", se_marker = "# SE of observed  biomass",
    n_marker = "# Number of GOA trawl years", n_measure = "relative_biomass_index",
    unit = "kilotonnes", type = "index", survey = "Gulf of Alaska trawl survey",
    id = "goa_trawl_survey_biomass", likelihood_weight = 0.448)
)

index_inputs <- lapply(index_data, function(spec) {
  block <- section(spec$label)
  n <- as.integer(values_after(block, spec$n_marker, 1L))
  years <- as.integer(values_after(block, spec$year_marker, n))
  values <- values_after(block, spec$value_marker, n)
  errors <- values_after(block, spec$se_marker, n)
  ids <- paste0(spec$id, "_", years)
  fleet <- if (is.null(spec$fleet)) NA_character_ else spec$fleet
  survey <- if (is.null(spec$survey)) NA_character_ else spec$survey
  args <- list(
    type = spec$type, measure = spec$n_measure, basis = "index_scale",
    year = years, value = values, unit = spec$unit, fleet = fleet,
    survey = survey, observation_id = ids,
    source_reference = paste0("tem_2024_na_wh.dat ", spec$value_marker),
    notes = paste0("Native assessment input series; values and source scale are retained without rescaling. ",
      "The final run likelihood weight is ", spec$likelihood_weight,
      if (spec$likelihood_weight == 0) "; this series is not fitted in the likelihood." else ".")
  )
  value_rows <- do.call(new_input, args)
  se_args <- args
  se_args$measure <- "index_sd"
  se_args$value <- errors
  se_args$source_reference <- paste0("tem_2024_na_wh.dat ", spec$se_marker)
  se_args$notes <- "Standard error supplied in the native input on the corresponding index scale."
  se_rows <- do.call(new_input, se_args)
  rbind(value_rows, se_rows)
})
index_inputs <- do.call(rbind, index_inputs)

catch_years <- model_years
catch_inputs <- rbind(
  new_input("catch", "catch_biomass", "biomass", catch_years,
    value = values_after(catch_lines, "# Fixed gear fishery catch", length(catch_years)),
    unit = "metric tons", fleet = "U.S. fixed-gear fishery",
    source_reference = "tem_2024_na_wh.dat Fixed gear fishery catch (mt)",
    notes = "Annual commercial catch biomass supplied to the 2024 assessment."),
  new_input("catch", "catch_biomass", "biomass", catch_years,
    value = values_after(catch_lines, "# Trawl gear fishery catch", length(catch_years)),
    unit = "metric tons", fleet = "U.S. trawl-gear fishery",
    source_reference = "tem_2024_na_wh.dat Trawl gear fishery catch (mt)",
    notes = "Annual commercial catch biomass supplied to the 2024 assessment."))

composition_specs <- list(
  list(label = "# Fixed Gear Fishery Age Composition", years = 25L, n_marker = "# Number of years fishery age comps",
    year = "# Fishery age comp years", sample = "# Number of samples",
    markers = c(unsexed = "# Observed fishery age compositions"), bins = ages,
    type = "catch", fleet = "U.S. fixed-gear fishery", source = "fixed_fishery_age",
    raw = "fixed_age"),
  list(label = "# Domestic LL survey Age Composition", years = 28L, n_marker = "# Number of years LL survey age comps",
    year = "# LL survey age comp years", sample = "# Number of samples",
    markers = c(unsexed = "# Observed age compositions"), bins = ages,
    type = "index", survey = "NOAA domestic longline survey", source = "domestic_longline_age",
    raw = "domestic_age"),
  list(label = "# Japanese LL survey Age Composition", years = 7L, n_marker = "# Number of years JPN LL survey ages",
    year = "# JPN LL Survey age comp years", sample = "# Number of samples",
    markers = c(unsexed = "# Observed JPN LL Survey age compositions"), bins = ages,
    type = "index", survey = "Japanese cooperative longline survey", source = "japanese_coop_age",
    raw = "japan_age"),
  list(label = "# GOA trawl survey historical age composition", years = 4L, n_marker = "# GOA trawl survey Number of years age comp",
    year = "# Years of GOA trawl survey age compositions", sample = "# Number of samples",
    markers = c(unsexed = "# Observed GOA trawl survey age comps"), bins = ages,
    type = "index", survey = "Gulf of Alaska trawl survey", source = "goa_trawl_age",
    raw = NULL)
)

age_composition_inputs <- lapply(composition_specs, function(spec) {
  block <- section(spec$label)
  actual_n <- as.integer(values_after(block, spec$n_marker, 1L))
  if (actual_n != spec$years) stop("Unexpected age-composition year count in ", spec$label, call. = FALSE)
  composition_inputs(
    spec$label, spec$year, spec$sample, spec$markers, actual_n, spec$bins,
    spec$type, spec$source, fleet = spec$fleet, survey = spec$survey,
    raw_sample_column = spec$raw, raw_samples = raw_samples
  )
})
age_composition_inputs <- do.call(rbind, age_composition_inputs)

length_specs <- list(
  list(label = "# U.S. Fixed gear fishery length compositions", years = 34L, n_marker = "# Number of years fixed gear fishery length comps",
    year = "# Fixed gear Fishery length comp years", sample = "# Number of samples",
    markers = c(male = "# Observed LL fishery size compositions MALE",
      female = "# Observed LL fishery size compositions Females"),
    type = "catch", fleet = "U.S. fixed-gear fishery", source = "fixed_fishery_length", raw = "fixed_length"),
  list(label = "# Japanese longline fishery unsexed lengths", years = NULL, n_marker = "# JPN LL fishery Number of years length comps",
    year = "# JPN LL Fishery size comp years", sample = "# Number of samples",
    markers = c(unsexed = "# Observed JPN LL fishery size compositions"),
    type = "catch", fleet = "Japanese longline fishery", source = "japanese_fishery_length", raw = "japan_length"),
  list(label = "# U.S. Trawl gear fishery length compositions", years = NULL, n_marker = "# Trawl fishery Number of years size comp",
    year = "# Trawl Fishery size comp years", sample = "# Number of samples",
    markers = c(male = "# Observed trawl fishery size compositions MALE",
      female = "# Observed trawl fishery size compositions Females"),
    type = "catch", fleet = "U.S. trawl-gear fishery", source = "trawl_fishery_length", raw = "trawl_length"),
  list(label = "# Japanese Trawl survey unsexed size Composition", years = NULL, n_marker = "# JPN Trawl Survey Number of years size comp",
    year = "# JPN trawl survey size comp years", sample = "# Number of samples",
    markers = c(unsexed = "# Observed JPN Trawl survey size compositions"),
    type = "index", survey = "Japanese trawl survey", source = "japanese_trawl_length", raw = NULL),
  list(label = "# U.S. Domestic LL Survey Size Composition", years = 34L, n_marker = "# LL Survey Number of years size comp",
    year = "# LL Survey size comp years", sample = "# Number of samples",
    markers = c(male = "# Observed LL survey size compositions MALE",
      female = "# Observed LL survey size compositions FEMALE"),
    type = "index", survey = "NOAA domestic longline survey", source = "domestic_longline_length", raw = "domestic_length"),
  list(label = "# Japanese LL survey size Composition", years = 16L, n_marker = "# JPN LL Survey Number of years size comps",
    year = "# JPN LL Survey size comp years", sample = "# Number of samples",
    markers = c(male = "# Observed JPN LL survey size compositions Male",
      female = "# Observed JPN LL survey size compositions Male"),
    occurrences = c(male = 1L, female = 2L),
    type = "index", survey = "Japanese cooperative longline survey", source = "japanese_coop_length", raw = "japan_length"),
  list(label = "# GOA trawl survey size composition", years = 15L, n_marker = "# GOA trawl Survey Number of years size comp",
    year = "# GOA Trawl survey size compositions", sample = "# Number of samples",
    markers = c(male = "# Observed Trawl Survey size comps Male",
      female = "# Observed Trawl Survey size comps Females"),
    type = "index", survey = "Gulf of Alaska trawl survey", source = "goa_trawl_length", raw = "goa_length")
)

length_composition_inputs <- lapply(length_specs, function(spec) {
  block <- section(spec$label)
  actual_n <- as.integer(values_after(block, spec$n_marker, 1L))
  if (!is.null(spec$years) && actual_n != spec$years) stop("Unexpected length-composition year count in ", spec$label, call. = FALSE)
  composition_inputs(
    spec$label, spec$year, spec$sample, spec$markers, actual_n, length_bins,
    spec$type, spec$source, fleet = spec$fleet, survey = spec$survey,
    raw_sample_column = spec$raw, raw_samples = raw_samples,
    marker_occurrences = spec$occurrences
  )
})
length_composition_inputs <- do.call(rbind, length_composition_inputs)
cooperative_length_rows <- grepl("^japanese_coop_length_", length_composition_inputs$observation_id)
length_composition_inputs$notes[cooperative_length_rows] <- paste(
  length_composition_inputs$notes[cooperative_length_rows],
  "The source labels both vectors Male; fitted output-object labels verify the first as male and second as female."
)

biology_inputs <- list()
for (block in 1:3) {
  maturity <- values_after(bio_lines, paste0("#prop_mature ", block), length(ages))
  biology_inputs[[length(biology_inputs) + 1L]] <- new_input(
    "maturity", "maturity_at_age", "proportion", age = ages, value = maturity,
    unit = "proportion", partition = paste0("source block ", block),
    source_reference = paste0("tem_2024_na_wh.dat prop_mature block ", block),
    notes = if (block == 1L) {
      "Native fixed maturity-at-age vector; this is the single active block in the 2024 control file. The source also supplies two identical inactive blocks."
    } else {
      "Native source vector, identical to block 1; inactive because the 2024 control file specifies one maturity block."
    }
  )
}
for (block in 1:3) {
  for (sex in c("male", "female")) {
    weight <- values_after(bio_lines,
      paste0("#weight ", sex, "s ", block), length(ages))
    biology_inputs[[length(biology_inputs) + 1L]] <- new_input(
      "weight", "weight_at_age", "kg_per_fish", age = ages, value = weight,
      unit = "kg per fish", sex = sex, partition = paste0("source block ", block),
      source_reference = paste0("tem_2024_na_wh.dat weight ", sex, " block ", block),
      notes = if (block == 1L) {
        "Native sex-specific weight-at-age vector; this is the single active block in the 2024 control file."
      } else if (block == 3L) {
        "Native source vector; source labels this block as not used in the assessment."
      } else {
        "Native source vector; inactive because the 2024 control file specifies one weight block."
      }
    )
  }
}
biology_inputs <- do.call(rbind, biology_inputs)

composition_weights <- c(
  us_fixed_gear_age = 0.826107286513784,
  noaa_domestic_longline_age = 3.79224544725927,
  japanese_cooperative_longline_age = 1.31681114024037,
  goa_trawl_age = 0,
  us_fixed_gear_length_female = 4.26969350917589,
  us_fixed_gear_length_male = 4.1837057381917,
  japanese_longline_fishery_length = 0,
  us_trawl_fishery_length_female = 0.316485920691651,
  us_trawl_fishery_length_male = 0.229396580680981,
  noaa_domestic_longline_length_female = 1.43792019016567,
  noaa_domestic_longline_length_male = 1.07053763450712,
  japanese_cooperative_longline_length_female = 1.27772810174693,
  japanese_cooperative_longline_length_male = 0.857519546948587,
  goa_trawl_length_female = 0.670883273592302,
  goa_trawl_length_male = 0.465207132450763
)
composition_weight_assumptions <- do.call(rbind, lapply(names(composition_weights), function(name) {
  new_assumption("composition", paste0("final_likelihood_weight_", name),
    composition_weights[[name]], "tem.ctl; data_reweight_switch=1",
    if (composition_weights[[name]] == 0) "This composition is supplied in the source file but has zero likelihood weight in the final run." else
      "Final iterative likelihood weight used in the 2024 Model 23.5 run.")
}))

male_proportions <- lapply(1:2, function(block) {
  values_after(bio_lines, paste0("#proportion of males block ", block), length(model_years))
})
if (!all(vapply(male_proportions, function(x) all(x == x[[1L]]), logical(1L))) ||
  !all(vapply(male_proportions, function(x) all(x == 0.5), logical(1L)))) {
  stop("Unexpected male-proportion inputs; inspect the native sex-ratio vectors.", call. = FALSE)
}

inputs <- rbind(catch_inputs, index_inputs, age_composition_inputs,
  length_composition_inputs, biology_inputs)

output_years <- as.integer(rownames(model_output$natage.female))
output_ages <- as.integer(colnames(model_output$natage.female))
if (!identical(output_years, model_years) || !identical(output_ages, ages) ||
  !identical(dim(model_output$natage.male), c(length(model_years), length(ages))) ||
  !identical(dim(model_output$M), c(length(model_years), length(ages))) ||
  !identical(as.integer(model_output$t.series$year), model_years)) {
  stop("The selected 2024 model output has unexpected year or age dimensions.", call. = FALSE)
}

age_grid <- expand.grid(age = ages, year = model_years)
N_female <- as.vector(t(model_output$natage.female))
N_male <- as.vector(t(model_output$natage.male))
N_total <- rowSums(model_output$natage.female + model_output$natage.male)
age_group <- ifelse(age_grid$age == 31L, "31+", NA_character_)
age_outputs <- rbind(
  new_output("population", "numbers_at_age", age_grid$year, N_female,
    "million fish", sex = "female", age = age_grid$age, age_group = age_group,
    source_reference = "tem.rdat natage.female; 2024 Model 23.5, ages 2-31+",
    notes = "Native model-estimated number at age; age 31 is the 31+ group. No age-specific uncertainty array was located."),
  new_output("population", "numbers_at_age", age_grid$year, N_male,
    "million fish", sex = "male", age = age_grid$age, age_group = age_group,
    source_reference = "tem.rdat natage.male; 2024 Model 23.5, ages 2-31+",
    notes = "Native model-estimated number at age; age 31 is the 31+ group. No age-specific uncertainty array was located."),
  new_output("population", "total_abundance", model_years, N_total,
    "million fish", source_type = "derived_source_output",
    source_reference = "Derived from tem.rdat natage.female and natage.male",
    notes = "Sum of female and male numbers across ages 2-31+; uncertainty is unavailable.")
)

series <- model_output$t.series
summary_match <- match(model_years, report_summary$year)
report_interval <- function(column) report_summary[[column]][summary_match]
summary_outputs <- rbind(
  new_output("recruitment", "recruitment", model_years, series$Recr,
    "million age-2 fish", age = 2L, age_group = "age 2",
    lwr = report_interval("recruit_lwr"), upr = report_interval("recruit_upr"),
    source_reference = "tem.rdat t.series$Recr; Sablefish SAFE Table 3.8",
    notes = "Native annual age-2 recruitment point estimate; lower and upper values are 95% MCMC credible interval endpoints rounded in Table 3.8."),
  new_output("biomass", "SSB", model_years, series$spbiom,
    "kilotonnes", lwr = report_interval("ssb_lwr"), upr = report_interval("ssb_upr"),
    source_reference = "tem.rdat t.series$spbiom; Sablefish SAFE Table 3.8",
    notes = "Native spawning-biomass point estimate; lower and upper values are 95% MCMC credible interval endpoints rounded in Table 3.8."),
  new_output("biomass", "total_biomass", model_years, series$totbiom,
    "kilotonnes", lwr = report_interval("biomass_lwr"), upr = report_interval("biomass_upr"),
    source_reference = "tem.rdat t.series$totbiom; Sablefish SAFE Table 3.8",
    notes = "Native total-biomass point estimate; lower and upper values are 95% MCMC credible interval endpoints rounded in Table 3.8."),
  new_output("mortality", "natural_mortality_at_age", age_grid$year,
    as.vector(t(model_output$M)), "per year", age = age_grid$age,
    age_group = age_group,
    source_reference = "tem.rdat M; 2024 Model 23.5",
    notes = "Native M-at-age output is constant across ages and years in this model run; M was estimated as a single scalar.")
)
outputs <- rbind(age_outputs, summary_outputs)

assumptions <- rbind(
  new_assumption("model", "data_reweight_switch", "1", "tem.ctl",
    "Iterative likelihood weights are active in the final run."),
  new_assumption("assessment", "assessment_type", "Full production assessment",
    "2024 Sablefish SAFE, Model 23.5"),
  new_assumption("model", "model_version", "Model 23.5",
    "2024 Sablefish SAFE, author-recommended final model"),
  new_assumption("population", "modeled_years", "1960-2024",
    "tem_2024_na_wh.dat styr/endyr"),
  new_assumption("population", "modeled_ages", "2-31+",
    "tem_2024_na_wh.dat recage/nages", "Age 31 is the plus group."),
  new_assumption("population", "sex_structure", "Separate female and male populations",
    "tem.rdat natage.female/natage.male"),
  new_assumption("population", "proportion_male_input", "0.5 in both annual source vectors",
    "tem_2024_na_wh.dat proportion of males blocks 1 and 2",
    "Both 1960-2024 source vectors are constant at 0.5."),
  new_assumption("population", "assessment_areas", "Bering Sea, Aleutian Islands, Gulf of Alaska",
    "2024 Sablefish SAFE, assessment description", "These are management areas represented within one Alaska assessment population."),
  new_assumption("model", "growth_time_blocks", "2; second block begins in 1995",
    "tem.ctl growth block count and cutoffs"),
  new_assumption("biology", "active_weight_time_blocks", "1",
    "tem.ctl number of weight time blocks", "Only weight block 1 is active in this run."),
  new_assumption("biology", "active_maturity_time_blocks", "1",
    "tem.ctl number of maturity time blocks", "Only maturity block 1 is active in this run."),
  new_assumption("recruitment", "recruitment_age", "2",
    "tem_2024_na_wh.dat recage", "Recruitment output is reported as age-2 fish."),
  new_assumption("mortality", "natural_mortality_structure", "One estimated scalar shared across ages and years",
    "tem_2024_na_wh.dat; tem.rdat M", "The fitted native M surface is 0.114303 per year; no age- or sex-specific M was inferred."),
  new_assumption("mortality", "natural_mortality_prior", "Mean 0.10; CV 0.10",
    "tem.ctl prior mean for M / prior CV for M"),
  new_assumption("population", "spawning_month", "January",
    "tem_2024_na_wh.dat spawn month", "The source specifies the spawning month; it does not establish survey timing."),
  new_assumption("composition", "supplied_likelihood_sample_size", "20 for most series; 30 for Gulf of Alaska trawl age compositions",
    "tem_2024_na_wh.dat composition sample-size vectors", "These are relative multinomial sample-size weights, not raw counts of fish sampled."),
  new_assumption("composition", "composition_likelihood", "Multinomial-form cross-entropy with 0.001 offset and source likelihood weights",
    "tem.tpl age_like and composition likelihood code", "Raw observed proportions are retained; the model normalizes each vector internally."),
  new_assumption("survey", "within_year_timing", "Not reported",
    "2024 Sablefish SAFE; tem_2024_na_wh.dat", "Annual series are available, but no fractional within-year survey timing was located."),
  do.call(rbind, lapply(index_data, function(spec) new_assumption(
    "index", paste0("final_likelihood_weight_", spec$id), spec$likelihood_weight,
    "tem.ctl index weights", if (spec$likelihood_weight == 0) {
      "Series retained as a source input but not fitted in the final likelihood."
    } else {
      "Final assessment likelihood weight."
    }
  ))),
  composition_weight_assumptions,
  new_assumption("model", "regional_weighting", "Age compositions and survey indices use model-specific area aggregation and extrapolation",
    "2024 Sablefish SAFE, assessment methods and input documentation", "The source review distinguishes raw regional observations from the assessment's aggregated likelihood inputs.")
)

if (nrow(inputs) == 0L || nrow(outputs) == 0L) stop("No source rows were built.", call. = FALSE)
cat("Built NOAA Alaska sablefish source rows:\n")
cat("  inputs:", nrow(inputs), "\n")
cat("  outputs:", nrow(outputs), "\n")
cat("  age compositions:", sum(inputs$measure == "proportion_at_age"), "\n")
cat("  length compositions:", sum(inputs$measure == "proportion_at_length"), "\n")
cat("  raw composition sample counts:", sum(inputs$measure == "composition_sample_count"), "\n")

if (identical(Sys.getenv("TAM_SOURCE_DRY_RUN"), "1")) quit(save = "no", status = 0L)

read_table <- function(name) read.csv(file.path(root, "database", name),
  stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)
stocks <- read_table("stocks.csv")
assessments <- read_table("assessments.csv")
register <- read.csv(file.path(root, "discovery", "candidates.csv"),
  stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)
candidate <- match("NOAA:10956", register$candidate_id)
if (is.na(candidate) || stock_id %in% stocks$stock_id ||
  assessment_id %in% assessments$assessment_id ||
  !is.na(register$matched_stock_id[candidate]) || register$import_status[candidate] != "not_started") {
  stop("Expected one unimported NOAA:10956 candidate and no canonical sablefish records.", call. = FALSE)
}

stock <- data.frame(
  stock_id = stock_id, charbonneau_id = NA_character_, authority = "NOAA",
  authority_stock_id = "10956", scientific_name = "Anoplopoma fimbria",
  common_name = "Alaska sablefish",
  area = "Alaska (Bering Sea, Aleutian Islands, Gulf of Alaska)",
  region = "Alaska", ocean = "Northeast Pacific",
  notes = "Single federal Alaska assessment population; separate from the U.S. West Coast sablefish stock.",
  stringsAsFactors = FALSE
)
assessment <- data.frame(
  assessment_id = assessment_id, stock_id = stock_id,
  assessment_year = 2024L, terminal_year = 2024L,
  estimate_terminal_year = 2024L, assessment_type = "annual",
  model_family = "Statistical catch-at-age (ADMB)", model_version = "Model 23.5",
  is_current = "TRUE", is_applied = "TRUE", framework_year = 2024L,
  assessment_url = paste0(source_url, "/Final%20Report/SAFE/Sablefish_SAFE_2024_final.pdf"),
  framework_url = NA_character_, data_url = paste0(source_url, "/Data/tem_2024_na_wh.dat"),
  model_url = paste0(source_url, "/Model/Base%20%2823.5%29_final%20model/tem.tpl"),
  repository_url = paste0("https://github.com/dgoethel-noaa/2024-Sablefish-SAFE/tree/", revision),
  assumptions_status = "partial", inputs_status = "partial", outputs_status = "partial",
  notes = "2024 Model 23.5 is the latest full production assessment located; the 2025 SAFE confirms no new assessment. Direct age/length compositions, catch and index inputs, biological vectors, annual N-at-age, scalar M, recruitment, SSB, and total biomass are captured. Survey timing and numerical F-at-age remain unavailable. See discovery/source_reviews/noaa_alaska_sablefish_2024.md.",
  stringsAsFactors = FALSE
)

append_csv_rows <- function(name, rows) {
  path <- file.path(root, "database", name)
  if (!file.exists(path) || !nrow(rows)) stop("Missing source table or rows: ", name, call. = FALSE)
  header <- names(read.csv(path, nrows = 0L, stringsAsFactors = FALSE, check.names = FALSE))
  if (!identical(header, names(rows))) stop("Unexpected database columns in ", name, call. = FALSE)
  size <- file.info(path)$size
  con <- file(path, open = "rb")
  on.exit(close(con), add = TRUE)
  seek(con, where = max(0, size - 2), origin = "start")
  ending <- readBin(con, what = "raw", n = min(2, size))
  close(con)
  on.exit(NULL, add = FALSE)
  eol <- if (length(ending) == 2L && identical(ending, as.raw(c(13L, 10L)))) "\r\n" else "\n"
  if (!length(ending) || tail(ending, 1L) != as.raw(10L)) {
    append_con <- file(path, open = "ab")
    writeBin(charToRaw(eol), append_con)
    close(append_con)
  }
  write.table(rows, file = path, sep = ",", row.names = FALSE, col.names = FALSE,
    quote = TRUE, na = "", qmethod = "double", eol = eol, append = TRUE)
}

append_csv_rows("stocks.csv", stock)
append_csv_rows("assessments.csv", assessment)
append_csv_rows("assumptions.csv", assumptions)
append_csv_rows("inputs.csv", inputs)
append_csv_rows("outputs.csv", outputs)

register$matched_stock_id[candidate] <- stock_id
register$match_status[candidate] <- "matched"
register$import_status[candidate] <- "imported"
register$catch_age_evidence[candidate] <- paste(
  "The model fits sex-aggregated U.S. fixed-gear fishery proportions-at-age for 1999-2023,",
  "with raw annual age-sample counts reported around 991-1,236. These are composition inputs,",
  "not catch numbers-at-age. Annual gear catches are supplied in tonnes; the trawl fishery",
  "contributes length, not age, compositions."
)
register$survey_age_evidence[candidate] <- paste(
  "Source inputs include NOAA domestic longline survey age compositions for 1996-2023,",
  "Japanese-U.S. cooperative longline age compositions in 1981, 1983, 1985, 1987, 1989, 1991",
  "and 1993, and Gulf of Alaska trawl survey age compositions in 1984, 1987, 1996 and 1999.",
  "The Gulf of Alaska trawl age-composition likelihood weight is zero in the final run.",
  "NOAA longline RPNs span 1979-2023; model-specific area weighting/extrapolation is used.",
  "No survey index exists for 2024."
)
register$weights_evidence[candidate] <- paste(
  "The source provides sex-specific weight-at-age and length-at-age for ages 2-31+;",
  "the 2024 control file specifies one active weight block (Table 3C.1 and model input)."
)
register$maturity_evidence[candidate] <- paste(
  "The source provides fixed female maturity-at-age for ages 2-31+; the 2024 control file",
  "specifies one active maturity block (Table 3C.1 and model input)."
)
register$timing_evidence[candidate] <- paste(
  "The assessment uses annual survey indices and compositions but does not provide a",
  "fractional within-year survey timing value; timing remains unresolved."
)
register$decision_reason[candidate] <- paste(
  "Stock SMART 10956 is the single federal Alaska sablefish assessment population, distinct from",
  "the NOAA Pacific Coast unit. The latest full production assessment located is the 2024 Model 23.5",
  "update; the 2025 SAFE chapter confirms no 2025 assessment and rolls forward the 2024 model.",
  "Direct fishery/survey age compositions, age-specific biology, public final model input/output files,",
  "and annual age-specific abundance and aggregate population outputs support source curation.",
  "Survey timing and the lack of direct catch numbers-at-age remain explicit translation limitations."
)
register$notes[candidate] <- paste(
  "Imported the 2024 Model 23.5 native catch, index, composition, biology, and output records.",
  "Raw sample counts remain separate from the supplied relative likelihood sample-size weights.",
  "The input contains age compositions rather than direct catch numbers-at-age. No numeric F-at-age",
  "or within-year survey timing was inferred. See discovery/source_reviews/noaa_alaska_sablefish_2024.md."
)
source(file.path(root, "scripts", "database", "candidate_register_io.R"))
replace_candidate_register_row(file.path(root, "discovery", "candidates.csv"),
  candidate, register[candidate, , drop = FALSE], "NOAA:10956")

cat("Imported NOAA Alaska sablefish 2024 Model 23.5 source data.\n")
