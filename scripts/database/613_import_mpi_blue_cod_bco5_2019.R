root <- "."
stock_id <- "mpi_blue_cod_bco5"
assessment_id <- "mpi_blue_cod_bco5_2019"
candidate_id <- "MPI:BCO5"
report_path <- "source_cache/mpi_bco5/FAR-2020-14.pdf"
report_url <- "https://www.mpi.govt.nz/dmsdocument/41406-FAR-202014-Stock-assessment-of-blue-cod-Parapercis-colias-in-BCO-5-using-data-to-2019/sitemap"
manifest_path <- "provenance/mpi_blue_cod_bco5_sources.csv"
write_mode <- "--write" %in% commandArgs(trailingOnly = TRUE)

.libPaths(c(file.path(root, "source_cache", "R-library"), .libPaths()))
if (!requireNamespace("pdftools", quietly = TRUE)) {
  stop("Install pdftools to read the cached BCO 5 assessment report.", call. = FALSE)
}

manifest <- read.csv(manifest_path, stringsAsFactors = FALSE,
  colClasses = "character", check.names = FALSE)
source_row <- which(basename(manifest$local_file) == basename(report_path))
if (length(source_row) != 1L || !file.exists(report_path) ||
    toupper(unname(tools::sha256sum(report_path))) != manifest$sha256[source_row]) {
  stop("The cached BCO 5 assessment report does not match its provenance record.", call. = FALSE)
}

pages <- pdftools::pdf_text(report_path)
report_lines <- unlist(strsplit(pages, "\n", fixed = TRUE), use.names = FALSE)
report_lines <- trimws(gsub("\r", "", report_lines, fixed = TRUE))

table_section <- function(start_pattern, end_pattern) {
  start <- grep(start_pattern, report_lines, perl = TRUE)[1L]
  ends <- grep(end_pattern, report_lines, perl = TRUE)
  ends <- ends[ends > start]
  if (is.na(start) || !length(ends)) {
    stop("Could not isolate BCO 5 report section: ", start_pattern, call. = FALSE)
  }
  report_lines[seq.int(start, ends[1L] - 1L)]
}

numeric_tokens <- function(line) {
  values <- suppressWarnings(as.numeric(strsplit(trimws(line), "\\s+")[[1L]]))
  values[!is.na(values)]
}

parse_annual_table <- function(section, group_width, years, label) {
  row_lines <- section[grepl("^\\s*(19|20)[0-9]{2}\\s+", section, perl = TRUE)]
  rows <- list()
  for (line in row_lines) {
    values <- numeric_tokens(line)
    markers <- which(values == as.integer(values) & values %in% years)
    for (i in markers) {
      if (i + group_width - 1L > length(values) ||
          any(values[seq.int(i + 1L, i + group_width - 1L)] %in% years)) {
        stop(label, " contains an incomplete year group: ", line, call. = FALSE)
      }
      rows[[length(rows) + 1L]] <- values[seq.int(i, i + group_width - 1L)]
    }
  }
  result <- as.data.frame(do.call(rbind, rows), stringsAsFactors = FALSE)
  names(result) <- c("year", paste0("value", seq_len(group_width - 1L)))
  result$year <- as.integer(result$year)
  if (anyDuplicated(result$year) || !identical(sort(result$year), as.integer(years))) {
    stop(label, " year coverage differs from the published table.", call. = FALSE)
  }
  result[order(result$year), , drop = FALSE]
}

parse_fixed_rows <- function(section, first_values, width, label) {
  row_lines <- section[grepl("^\\s*[0-9]+\\s+", section, perl = TRUE)]
  rows <- list()
  for (line in row_lines) {
    values <- numeric_tokens(line)
    if (!length(values) || !values[1L] %in% first_values) next
    if (length(values) != width) {
      numeric_row <- grepl("^\\s*[0-9]+\\s+[-+]?(?:[0-9]+(?:\\.[0-9]*)?|\\.[0-9]+)(?:\\s+|$)",
        line, perl = TRUE)
      if (!numeric_row) next
      stop(label, " has an unexpected number of cells: ", line, call. = FALSE)
    }
    rows[[length(rows) + 1L]] <- values
  }
  if (!length(rows)) stop(label, " contains no numeric rows.", call. = FALSE)
  result <- as.data.frame(do.call(rbind, rows), stringsAsFactors = FALSE)
  if (anyDuplicated(result[[1L]]) || !identical(result[[1L]], as.numeric(first_values))) {
    stop(label, " bins differ from the reviewed source table.", call. = FALSE)
  }
  result
}

area_tables <- list(
  "Statistical Area 027" = table_section("^Table 1\\.1: Statistical Area 027", "^Table 1\\.2:"),
  "Statistical Area 025" = table_section("^Table 1\\.2: Statistical Area 025", "^Table 1\\.3:"),
  "Statistical Area 030" = table_section("^Table 1\\.3: Statistical Area 030", "^APPENDIX 2:")
)
catch_tables <- lapply(area_tables, parse_annual_table, group_width = 4L,
  years = 1900:2018, label = "Landings table")

cpue_table <- parse_annual_table(
  table_section("^Table 3\\.1:", "^Table 3\\.2:"), 5L, 1990:2018, "CPUE table")
survey_lines <- table_section("^Table 1: Blue cod abundance", "^Fisheries data")
survey_rows <- parse_fixed_rows(survey_lines, c(2010, 2014, 2018), 3L,
  "Foveaux pot survey abundance table")

survey_age_table <- parse_fixed_rows(
  table_section("^Table 2\\.1:", "^Table 3\\.1:"), 3:15, 7L,
  "Foveaux pot survey age composition")
commercial_age_tables <- list(
  "Statistical Area 025" = parse_fixed_rows(
    table_section("^Table 3\\.5:", "^Table 3\\.6:"), 3:15, 5L,
    "Statistical Area 025 commercial age composition"),
  "Statistical Area 027" = parse_fixed_rows(
    table_section("^Table 3\\.6:", "^Table 3\\.7:"), 3:15, 3L,
    "Statistical Area 027 commercial age composition"),
  "Statistical Area 030" = parse_fixed_rows(
    table_section("^Table 3\\.7:", "^Table 3\\.8:"), 3:15, 3L,
    "Statistical Area 030 commercial age composition"),
  "Whole BCO 5" = parse_fixed_rows(
    table_section("^Table 3\\.8:", "^Table 3\\.9:"), 3:15, 3L,
    "Whole-area commercial age composition")
)

mesh_1986 <- parse_fixed_rows(
  table_section("^Table 3\\.2:", "^Table 3\\.3:"), 13:32, 2L,
  "1986 pot mesh experiment length composition")
logbook_length <- parse_fixed_rows(
  table_section("^Table 3\\.3:", "^Table 3\\.4:"), 13:58, 5L,
  "Commercial logbook length composition")
shed_lines <- table_section("^Table 3\\.4:", "^Table 3\\.5:")
shed_rows <- shed_lines[grepl("^\\s*(2[7-9]|[3-4][0-9])\\s+", shed_lines, perl = TRUE)]
shed_tokens <- lapply(shed_rows, numeric_tokens)
shed_tokens <- shed_tokens[lengths(shed_tokens) == 6L]
if (length(shed_tokens) != 16L) stop("Shed length table does not have 16 paired rows.", call. = FALSE)
shed_length <- do.call(rbind, shed_tokens)
recreational_lines <- table_section("^Table 3\\.9:", "^Pot mesh experiment, 2015")
recreational_rows <- recreational_lines[grepl("^\\s*[0-9]+\\s+", recreational_lines, perl = TRUE)]
recreational_tokens <- lapply(recreational_rows, numeric_tokens)
recreational_tokens <- recreational_tokens[lengths(recreational_tokens) == 4L]
if (length(recreational_tokens) != 22L) stop("Recreational length table changed from 22 printed rows.", call. = FALSE)
recreational_length <- do.call(rbind, recreational_tokens)
mesh_2015 <- parse_fixed_rows(
  table_section("^Table 3\\.11:", "^APPENDIX 4:"), 29:37, 2L,
  "2015 Pot 2 mesh experiment length composition")

input_rows <- list()
add_input <- function(type, measure, basis, value, unit, fleet = "", survey = "",
    sex = "", region = "", season = "", year = NA_integer_, year_basis = "",
    age = NA_integer_, sampling_time = NA_real_, source_reference, notes = "",
    observation_id = "", length_bin = NA_real_, sample_size = NA_real_) {
  input_rows[[length(input_rows) + 1L]] <<- data.frame(
    assessment_id = assessment_id, type = type, measure = measure, basis = basis,
    fleet = fleet, survey = survey, sex = sex, region = region, season = season,
    year = as.integer(year), year_basis = year_basis, age = as.integer(age),
    value = as.numeric(value), unit = unit, sampling_time = as.numeric(sampling_time),
    source_type = "official_table", source_reference = source_reference,
    transformation = "", notes = notes, observation_id = observation_id,
    length_bin = as.numeric(length_bin), length_bin_lower = NA_real_,
    length_bin_upper = NA_real_, sample_size = as.numeric(sample_size),
    age_error = "", partition = "", weight_bin = "", stringsAsFactors = FALSE)
}

add_likelihood_weight <- function(type, observation_id, value, fleet = "",
    survey = "", region = "", year = NA_integer_, year_basis = "model_year",
    source_reference = "FAR 2020/14, Table 3, p. 12", notes = "") {
  add_input(type = type, measure = "observation_likelihood_weight",
    basis = "relative_scale", value = value, unit = "effective multinomial N",
    fleet = fleet, survey = survey, region = region, year = year,
    year_basis = year_basis, source_reference = source_reference,
    notes = paste("Effective likelihood sample size, not raw sampled fish.", notes),
    observation_id = observation_id)
}

for (region in names(catch_tables)) {
  x <- catch_tables[[region]]
  fleets <- c("Commercial line", "Commercial pot", "Recreational")
  for (j in seq_along(fleets)) {
    for (i in seq_len(nrow(x))) {
      add_input("catch", "catch_biomass", "biomass", x[i, j + 1L], "tonnes",
        fleet = fleets[j], region = region, year = x$year[i], year_basis = "model_year",
        source_reference = paste0("FAR 2020/14, Appendix 1, Table ",
          c("1.2", "1.1", "1.3")[match(region, c("Statistical Area 025", "Statistical Area 027", "Statistical Area 030"))],
          ", pp. 27-31"),
        notes = "Reconstructed landing/catch history as printed; annual model-year labels are preserved without shifting.")
    }
  }
}

cpue_regions <- c("Statistical Area 025", "Statistical Area 027",
  "Statistical Area 030", "Combined Areas 025+027+030")
for (j in seq_along(cpue_regions)) {
  for (i in seq_len(nrow(cpue_table))) {
    add_input("index", "relative_abundance_index", "index_scale", cpue_table[i, j + 1L],
      "standardized CPUE index", fleet = "Commercial pot fishery",
      survey = "Standardized pot CPUE", region = cpue_regions[j],
      year = cpue_table$year[i], year_basis = "model_year",
      source_reference = "FAR 2020/14, Appendix 3, Table 3.1, pp. 32-33",
      notes = if (j == 4L) "Combined-area CPUE is a sensitivity input; it is not fitted simultaneously with the three area-specific series." else "Area-specific base-model standardized CPUE series.")
  }
}

for (i in seq_len(nrow(survey_rows))) {
  add_input("index", "relative_abundance_index", "index_scale", survey_rows[i, 2L],
    "fish pot-1", survey = "Foveaux Strait random-stratified pot survey",
    region = "Statistical Area 025", year = survey_rows[i, 1L],
    year_basis = "calendar_year", source_reference = "FAR 2020/14, Table 1, p. 4",
    notes = "February survey; the annual model does not state a numerical within-year sampling fraction.")
  add_input("index", "abundance_index_cv", "relative_scale", survey_rows[i, 3L] / 100,
    "ratio", survey = "Foveaux Strait random-stratified pot survey",
    region = "Statistical Area 025", year = survey_rows[i, 1L],
    year_basis = "calendar_year", source_reference = "FAR 2020/14, Table 1, p. 4",
    notes = "Source-reported CV; the assessment used a fixed 20% likelihood CV.")
}

add_age_composition <- function(table, years, columns, type, fleet, survey, region,
    observation_prefix, effective_n = 100, source_reference, notes) {
  for (i in seq_along(years)) {
    observation_id <- paste0(observation_prefix, "_", years[i])
    for (j in seq_len(nrow(table))) {
      for (sex in c("male", "female")) {
        value_column <- columns[[sex]][i]
        add_input(type, "proportion_at_age", "proportion_numbers", table[j, value_column],
          "proportion", fleet = fleet, survey = survey, sex = sex, region = region,
          year = years[i], year_basis = if (type == "index") "calendar_year" else "model_year",
          age = table[j, 1L], source_reference = source_reference,
          notes = paste(notes, "sample_size is left blank because raw sampled fish counts are not published; age 15 is the 15+ group."),
          observation_id = observation_id)
      }
    }
    add_likelihood_weight(type, observation_id, effective_n[i], fleet, survey, region,
      years[i], if (type == "index") "calendar_year" else "model_year",
      source_reference = "FAR 2020/14, Table 3, p. 12",
      notes = "The listed N is an effective multinomial likelihood weight.")
  }
}

survey_years <- c(2010L, 2014L, 2018L)
add_age_composition(survey_age_table, survey_years,
  columns = list(male = 2:4, female = 5:7), type = "index", fleet = "",
  survey = "Foveaux Strait random-stratified pot survey",
  region = "Statistical Area 025", observation_prefix = "pot_survey_age",
  effective_n = rep(100, 3L), source_reference = "FAR 2020/14, Appendix 2, Table 2.1, p. 32",
  notes = "Joint male/female age composition. Ages 1 and 2 were excluded by the assessment.")

add_age_composition(commercial_age_tables[["Statistical Area 025"]], c(2018L, 2019L),
  columns = list(male = c(2L, 4L), female = c(3L, 5L)), type = "catch",
  fleet = "Commercial catch sample", survey = "", region = "Statistical Area 025",
  observation_prefix = "commercial_age_area025", effective_n = c(100, 5),
  source_reference = "FAR 2020/14, Appendix 3, Table 3.5, p. 35",
  notes = "Scaled commercial catch age composition; 2019 was down-weighted because it covered only three months.")
for (area in c("Statistical Area 027", "Statistical Area 030", "Whole BCO 5")) {
  area_number <- sub("[^0-9]", "", area)
  table_number <- if (area == "Whole BCO 5") "3.8" else if (area_number == "027") "3.6" else "3.7"
  add_age_composition(commercial_age_tables[[area]], 2018L,
    columns = list(male = 2L, female = 3L), type = "catch",
    fleet = "Commercial catch sample", survey = "", region = area,
    observation_prefix = if (area == "Whole BCO 5") "commercial_age_bco5" else
      paste0("commercial_age_", gsub("[^0-9]", "", area)),
    effective_n = 100, source_reference = paste0("FAR 2020/14, Appendix 3, Table ", table_number, ", pp. 35-36"),
    notes = if (area == "Whole BCO 5") "Whole-area age composition used in the single-stock sensitivity; not an additional independent observation alongside the area-specific samples." else "Scaled commercial catch age composition.")
}

add_length_composition <- function(observation_id, bins, values, fleet, region = "",
    year, source_reference, effective_n, notes, sexes = NULL) {
  if (is.null(sexes)) sexes <- rep("", length(bins))
  for (i in seq_along(bins)) {
    add_input("catch", "proportion_at_length", "proportion_numbers", values[i],
      "proportion", fleet = fleet, sex = sexes[i], region = region,
      year = year, year_basis = "model_year", source_reference = source_reference,
      notes = paste("sample_size is left blank because raw sampled fish counts are not published; 1-cm lower length-bin labels.", notes),
      observation_id = observation_id, length_bin = bins[i])
  }
  add_likelihood_weight("catch", observation_id, effective_n, fleet, region = region,
    year = year, source_reference = "FAR 2020/14, Table 3, p. 12", notes = notes)
}

add_length_composition("pot_mesh_1986", mesh_1986[[1L]], mesh_1986[[2L]],
  "Commercial pot fishery", year = 1986L,
  source_reference = "FAR 2020/14, Appendix 3, Table 3.2, p. 33", effective_n = 20,
  notes = "Pre-1994 pot-mesh experiment; bins above 32 cm were excluded because observations past 33 cm were outside the fitted selection signal.")

logbook_regions <- c("Statistical Area 025", "Statistical Area 027",
  "Statistical Area 030", "Whole BCO 5")
for (j in seq_along(logbook_regions)) {
  add_length_composition(paste0("logbook_length_", j), logbook_length[[1L]],
    logbook_length[[j + 1L]], "Commercial logbook sample", logbook_regions[j],
    year = 2010L, source_reference = "FAR 2020/14, Appendix 3, Table 3.3, pp. 33-34",
    effective_n = 100,
    notes = if (j == 4L) "Whole-area composition is a sensitivity input; no line/pot fleet split is reported." else "Logbook data collected in 2009-2011 and assigned to 2010; no line/pot fleet split is reported.")
}

shed_bins <- rep(c(shed_length[, 1L], shed_length[, 4L]), 2L)
shed_sexes <- c(rep("male", 32L), rep("female", 32L))
shed_values <- c(c(shed_length[, 2L], shed_length[, 5L]),
  c(shed_length[, 3L], shed_length[, 6L]))
shed_order <- order(shed_sexes, shed_bins)
add_length_composition("shed_length_area025_2010", shed_bins[shed_order],
  shed_values[shed_order], "Commercial shed sample", "Statistical Area 025",
  year = 2010L, source_reference = "FAR 2020/14, Appendix 3, Table 3.4, p. 35",
  effective_n = 100, notes = "Sensitivity input replacing logbook length composition; male and female proportions are joint composition cells.",
  sexes = shed_sexes[shed_order])

recreational_bins <- c(recreational_length[, 1L], recreational_length[, 3L])
recreational_values <- c(recreational_length[, 2L], recreational_length[, 4L])
recreational_order <- order(recreational_bins)
add_length_composition("recreational_length_2010", recreational_bins[recreational_order],
  recreational_values[recreational_order], "Recreational fishery", "All assessed areas",
  year = 2010L, source_reference = "FAR 2020/14, Appendix 3, Table 3.9, p. 37",
  effective_n = 100,
  notes = "Source table omits length bin 35; the reported proportions sum to 0.927152 and are preserved without renormalization.")

add_length_composition("pot_mesh_2015_pot2", mesh_2015[[1L]], mesh_2015[[2L]],
  "Commercial pot fishery", year = 2015L,
  source_reference = "FAR 2020/14, Appendix 3, Table 3.11, p. 38", effective_n = 20,
  notes = "Pot 2 mesh experiment; the report excludes length bins from 38 cm onward.")

input_rows <- do.call(rbind, input_rows)
if (nrow(input_rows) != 1738L || anyNA(input_rows$assessment_id) ||
    any(!is.finite(input_rows$value))) {
  stop("BCO 5 input extraction did not produce the expected finite source rows.", call. = FALSE)
}
composition_rows <- input_rows[input_rows$measure %in% c("proportion_at_age", "proportion_at_length"), , drop = FALSE]
composition_sums <- vapply(split(composition_rows$value, composition_rows$observation_id), sum, numeric(1L))
if (any(abs(composition_sums[names(composition_sums) != "recreational_length_2010"] - 1) > 0.0002) ||
    abs(composition_sums[["recreational_length_2010"]] - 0.927152) > 1e-6) {
  stop("A BCO 5 composition differs from the source table totals.", call. = FALSE)
}

assumption_rows <- data.frame(
  assessment_id = assessment_id,
  component = c(rep("model", 8L), rep("biology", 7L), "M",
    rep("recruitment", 4L), rep("CPUE", 2L), rep("pot_survey", 2L), rep("composition", 4L)),
  fleet = "", survey = "", sex = "", region = "", season = "",
  setting = c("method", "model_years", "age_range", "time_step", "fisheries",
    "fishery_timing", "sex_structure", "ageing_error", "maturity_ogive",
    "maturity_parameters", "female_growth", "male_growth", "growth_paths",
    "length_weight_relationship", "spawning_fraction", "fixed_M", "stock_recruitment",
    "steepness", "YCS_prior", "YCS_years", "likelihood", "nominal_CV",
    "likelihood", "likelihood_CV", "age_composition_likelihood", "fishery_2019_age_weight",
    "length_composition_weight", "mesh_experiment_weight"),
  value = c(
    "Bayesian age- and sex-structured statistical catch-at-age model (Casal2)",
    "1900-2019", "1-20 years, age 20 is a plus group", "One annual time step",
    "Commercial line, commercial pot, and recreational fisheries",
    "Fisheries operate year-round; fishing year is 1 October-30 September",
    "Male and female partitions; 1:1 recruitment sex ratio",
    "8.6% one-off ageing error",
    "Shared logistic maturity ogive for both sexes",
    "A50 = 4.1 years; Ato95 = 2.47 years",
    "Medium growth: Linf = 40.0 cm, K = 0.19, t0 = -0.62 years",
    "Medium growth: Linf = 48.0 cm, K = 0.20, t0 = -0.51 years; male Linf fixed after estimation",
    "Slow, medium, and fast paths; 25% in each extreme path; R1 = 0.637, R2 = 0.581; overall length-at-age CV 9%",
    "Weight_kg = 0.000007289 * length_cm^3.2055; shared by sex and year",
    "Spawning after 93% of annual natural mortality; 100% of mature fish spawn",
    "Fixed at 0.17 per year",
    "Beverton-Holt",
    "0.75",
    "Lognormal year-class-strength prior, CV 0.6; mean constrained to 1",
    "1980-2014",
    "Lognormal CPUE",
    "10%; reweighted following Francis (2011)",
    "Lognormal Foveaux pot survey abundance",
    "20% fixed likelihood CV; source CVs retained as input rows",
    "Multinomial effective N = 100 for pot survey and commercial age samples, except 2019 commercial sample N = 5",
    "2019 commercial age composition down-weighted because it covered three months",
    "Multinomial effective N = 100 for length compositions",
    "Multinomial effective N = 20 for 1986 and 2015 pot-mesh experiments"),
  source_reference = c(
    rep("FAR 2020/14, Section 2.2, pp. 10-12", 8L),
    rep("FAR 2020/14, Sections 2.1-2.2, pp. 6-12", 7L),
    "FAR 2020/14, Section 2.1, p. 10",
    rep("FAR 2020/14, Section 2.2, pp. 10-12", 4L),
    rep("FAR 2020/14, Table 3, p. 12", 2L),
    rep("FAR 2020/14, Tables 1 and 3, pp. 4 and 12", 2L),
    rep("FAR 2020/14, Table 3, p. 12", 4L)),
  notes = c(
    "Three independent area models (025, 027, 030) were summed for BCO 5 status.",
    "The report describes the model period but does not supply a native model file.",
    "Age compositions are truncated at age 3 for model fitting.",
    "Assessment outputs are labelled through 2019.",
    "The report does not specify a line/pot fleet split for the commercial logbook sample.",
    "No fractional within-year survey timing is stated.",
    "The assessment assumes equal sex ratio at recruitment.",
    "Ageing-error definition is described as one-off.",
    "Raw maturity observations are shown graphically; the selected shared curve parameters are reported in prose.",
    "The shared ogive uses the mean male/female A50 and the female Ato95 estimates.",
    "Source base growth estimates; fast/slow path Linf values are scaled around the medium path.",
    "The source reports an initial male Linf of 55.7 cm, then estimates and fixes 48.0 cm for subsequent runs.",
    "Growth paths are a modelling device to preserve length-selectivity effects.",
    "The model derives weight-at-age from length-at-age and this relationship; no complete age-weight table is printed.",
    "The spawning fraction is relative to annual natural mortality.",
    "M is fixed, not estimated, in the base case.",
    "The base case uses Beverton-Holt recruitment.",
    "Steepness is fixed in the base case.",
    "Relative year-class strength has mean one by definition.",
    "Year-class strengths were estimated for 1980-2014.",
    "The three area-specific CPUE series are base inputs; the combined series is a sensitivity input.",
    "Nominal CV before Francis reweighting.",
    "The pot survey index is used in the Statistical Area 025 model.",
    "The reported source CVs are not the fixed likelihood CV.",
    "Effective N is stored separately from raw sample_size, which is not reported.",
    "The source says the 2019 age composition covered only the first three months of the fishing year.",
    "Effective N is not the number of fish sampled.",
    "Effective N is not the number of fish sampled."),
  stringsAsFactors = FALSE)

output_rows <- list()
add_output <- function(type, measure, value, unit, region = "", year = NA_integer_,
    lwr = NA_real_, upr = NA_real_, source_type, source_reference, scenario, notes) {
  output_rows[[length(output_rows) + 1L]] <<- data.frame(
    assessment_id = assessment_id, type = type, measure = measure, fleet = "",
    survey = "", sex = "", region = region, season = "", year = as.integer(year),
    age = NA_integer_, age_group = "", value = as.numeric(value), se = NA_real_,
    lwr = as.numeric(lwr), upr = as.numeric(upr), unit = unit,
    source_type = source_type, source_reference = source_reference,
    notes = notes, scenario = scenario, stringsAsFactors = FALSE)
}

b0_mcmc <- data.frame(region = c("Statistical Area 025", "Statistical Area 027", "Statistical Area 030"),
  value = c(10670, 4599, 4403), lwr = c(10186, 4128, 4099), upr = c(11258, 5494, 4935))
for (i in seq_len(nrow(b0_mcmc))) {
  add_output("biomass", "unfished_spawning_biomass", b0_mcmc$value[i], "tonnes",
    region = b0_mcmc$region[i], lwr = b0_mcmc$lwr[i], upr = b0_mcmc$upr[i],
    source_type = "official_table", source_reference = paste0("FAR 2020/14, Table ",
      c("4.2", "4.3", "4.4")[i], ", pp. 40, 45, 47"), scenario = "MCMC base run",
    notes = "MCMC median and 95% credible interval for virgin biomass B0; area models are separate.")
}
add_output("biomass", "unfished_spawning_biomass", 20682, "tonnes", region = "BCO 5",
  source_type = "official_document", source_reference = "FAR 2020/14, Section 3.2, p. 18",
  scenario = "MPD base run", notes = "MPD estimate of B0 for the combined BCO 5 status calculation.")

depletion <- data.frame(region = c("BCO 5", "Statistical Area 025", "Statistical Area 027", "Statistical Area 030"),
  value = c(32.4, 31.2, 31.5, 38.0))
for (i in seq_len(nrow(depletion))) {
  add_output("biomass", "SSB_ratio_to_B0", depletion$value[i], "percent",
    region = depletion$region[i], year = 2019L, source_type = "official_document",
    source_reference = "FAR 2020/14, Section 3.2, p. 18",
    scenario = "MPD base run", notes = "Reported Bcurrent as a percentage of B0.")
}
add_output("biomass", "SSB_ratio_to_B0", 35.7, "percent", region = "BCO 5",
  year = 2019L, lwr = 31, upr = 41, source_type = "official_document",
  source_reference = "FAR 2020/14, Section 3.2, p. 20", scenario = "MCMC base run",
  notes = "MCMC median Bcurrent/B0 and 95% credible interval; not the MPD summary.")
add_output("biomass", "SSB", 6701, "tonnes", region = "BCO 5", year = 2019L,
  source_type = "derived_source_output", source_reference = "FAR 2020/14, Section 3.2, p. 18",
  scenario = "MPD base run", notes = "Approximate SSB derived from rounded MPD B0 (20,682 tonnes) multiplied by rounded Bcurrent/B0 (32.4%); rounded to the nearest tonne. No uncertainty is available.")
output_rows <- do.call(rbind, output_rows)

if (nrow(assumption_rows) != 28L || nrow(output_rows) != 10L) {
  stop("BCO 5 assumptions or outputs differ from the reviewed extraction.", call. = FALSE)
}

cat("BCO 5 2019 source extraction\n")
cat("  inputs: ", nrow(input_rows), " rows\n", sep = "")
cat("  assumptions: ", nrow(assumption_rows), " rows\n", sep = "")
cat("  outputs: ", nrow(output_rows), " rows\n", sep = "")
cat("  catch years: 1900-2018; CPUE years: 1990-2018; model terminal year: 2019\n")
cat("  recreational length table total: 0.927152; omitted source bin 35 preserved as missing\n")
if (!write_mode) {
  cat("Dry run only. Add --write to import the verified source rows.\n")
} else {
  read_csv <- function(path) read.csv(path, stringsAsFactors = FALSE,
    colClasses = "character", na.strings = c("", "NA"), check.names = FALSE)
  stream_has_id <- function(path, id) {
    con <- file(path, open = "r")
    on.exit(close(con))
    prefix <- paste0('"', id, '",')
    repeat {
      chunk <- readLines(con, n = 100000L, warn = FALSE)
      if (!length(chunk)) return(FALSE)
      if (any(startsWith(chunk, prefix))) return(TRUE)
    }
  }
  append_csv <- function(path, x) write.table(x, path, sep = ",", quote = TRUE,
    row.names = FALSE, col.names = FALSE, append = TRUE, na = "", qmethod = "double")
  replace_register_row <- function(path, key, id, values) {
    x <- read_csv(path)
    hit <- which(x[[key]] == id)
    if (length(hit) != 1L) stop("Expected one register row for ", id, ".", call. = FALSE)
    for (name in names(values)) x[[name]][hit] <- values[[name]]
    write.csv(x, path, row.names = FALSE, na = "")
  }

  for (file in c("stocks.csv", "assessments.csv", "inputs.csv", "assumptions.csv", "outputs.csv")) {
    path <- file.path("database", file)
    ids <- if (file == "stocks.csv") stock_id else assessment_id
    if (stream_has_id(path, ids)) stop("BCO 5 is already present in ", file, ".", call. = FALSE)
  }
  candidates <- read_csv("discovery/candidates.csv")
  candidate_row <- which(candidates$candidate_id == candidate_id)
  selected <- read_csv("discovery/selected_batch_21_2026.csv")
  selected_row <- which(selected$candidate_id == candidate_id)
  if (length(candidate_row) != 1L || length(selected_row) != 1L ||
      candidates$import_status[candidate_row] != "not_started" ||
      selected$curation_status[selected_row] != "selected_for_source_curation") {
    stop("BCO 5 discovery records are not in the expected pre-import state.", call. = FALSE)
  }

  stock <- data.frame(stock_id = stock_id, charbonneau_id = "",
    authority = "Fisheries New Zealand", authority_stock_id = "BCO 5",
    scientific_name = "Parapercis colias", common_name = "Blue cod",
    area = "BCO 5; Statistical Areas 025, 027, and 030 assessed",
    region = "New Zealand", ocean = "Southwest Pacific",
    notes = "The 2019 assessment fitted separate models for areas 025, 027, and 030; their estimates were combined for BCO 5 status.",
    stringsAsFactors = FALSE)
  assessment <- data.frame(assessment_id = assessment_id, stock_id = stock_id,
    assessment_year = 2019L, terminal_year = 2019L, estimate_terminal_year = 2019L,
    assessment_type = "full_assessment", model_family = "Casal2",
    model_version = "2019 age- and sex-based base case",
    is_current = TRUE, is_applied = TRUE, framework_year = NA_integer_,
    assessment_url = report_url, framework_url = "", data_url = report_url,
    model_url = "", repository_url = "", assumptions_status = "partial",
    inputs_status = "partial", outputs_status = "partial",
    notes = "The May 2026 Plenary confirms BCO 5 advice remains based on this 2019 assessment; the 2024 attempt was rejected. This import preserves the report's numerical catch, index, age-composition and length-composition tables, but the recreational length table omits bin 35 and underlying raw sample counts and a native model file were not recovered.",
    stringsAsFactors = FALSE)

  append_csv("database/stocks.csv", stock)
  append_csv("database/assessments.csv", assessment)
  append_csv("database/inputs.csv", input_rows)
  append_csv("database/assumptions.csv", assumption_rows)
  append_csv("database/outputs.csv", output_rows)
  replace_register_row("discovery/candidates.csv", "candidate_id", candidate_id,
    list(matched_stock_id = stock_id, match_status = "matched", import_status = "partial",
      catch_age_evidence = "Imported reconstructed fleet/area catch biomass and commercial age-composition vectors from the 2019 report. The assessment did not publish direct catch numbers-at-age.",
      survey_age_evidence = "Imported Foveaux pot-survey abundance/CVs and 2010, 2014, and 2018 age-composition vectors; the index applies to Statistical Area 025.",
      weights_evidence = "Imported growth and length-weight assumptions; a complete age-specific weight surface is not published.",
      maturity_evidence = "Imported the shared fixed logistic maturity ogive parameters A50 = 4.1 and Ato95 = 2.47; the report provides no numeric age-specific maturity vector.",
      output_evidence = "Imported MPD and MCMC B0/depletion summaries and derived approximate 2019 SSB. Annual numerical N-at-age, F-at-age, recruitment, and SSB trajectories are not tabulated."))
  replace_register_row("discovery/selected_batch_21_2026.csv", "candidate_id", candidate_id,
    list(curation_status = "source_curated_partial",
      selection_basis = "The 2019 assessment remains the advice basis. The source import preserves 1,738 numeric input rows, 28 assumptions, and 10 output rows; gaps remain in the source's recreational length composition, raw sample sizes, and annual population surfaces."))

  source(file.path(root, "scripts", "database", "195_summarize_discovery.R"),
    local = new.env(parent = globalenv()))
  source(file.path(root, "scripts", "database", "196_summarize_inventory_units.R"),
    local = new.env(parent = globalenv()))
  cat("Imported partial BCO 5 2019 source data.\n")
}
