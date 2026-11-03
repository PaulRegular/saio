source("scripts/database/002_validate_database.R")
id <- "nefsc_haddock_georges_bank_2026"
x <- inputs[inputs$assessment_id == id, ]
y <- outputs[outputs$assessment_id == id, ]
a <- assessments[assessments$assessment_id == id, ]
settings <- assumptions[assumptions$assessment_id == id, ]
cache <- "source_cache/nefsc_haddock_georges_bank_2026"
text <- readLines(file.path(cache, "2026_assessment_text.txt"), encoding = "UTF-8", warn = FALSE)
review <- paste(readLines(file.path(cache, "2026_peer_review_text.txt"), encoding = "UTF-8", warn = FALSE), collapse = "\n")
source_values <- function(label) {
  line <- text[startsWith(text, label)]
  stopifnot(length(line) == 1)
  line <- substring(line, nchar(label) + 1)
  values <- regmatches(line, gregexpr("[0-9][0-9,]*(\\.[0-9]+)?", line))[[1]]
  values <- as.numeric(gsub(",", "", values, fixed = TRUE))
  stopifnot(length(values) == 8)
  values
}
stopifnot(
  nrow(x) == 17, nrow(y) == 42, nrow(a) == 1,
  a$terminal_year == 2025, a$estimate_terminal_year == 2031,
  a$assessment_year == 2026,
  a$model_family == "WHAM", a$framework_year == 2022,
  a$inputs_status == "partial", a$outputs_status == "partial", a$assumptions_status == "partial"
)
setting_value <- function(component, setting) {
  value <- settings$value[settings$component == component & settings$setting == setting]
  stopifnot(length(value) == 1)
  value
}
stopifnot(
  setting_value("assessment", "diagnostic_run") == "mt26_redo.no.fall2025_osa",
  setting_value("catch", "composition_likelihood") == "Logistic-normal; zero proportions treated as missing",
  setting_value("index", "composition_likelihood") == "Logistic-normal; zero proportions treated as missing",
  setting_value("recruitment", "model") == "Random about mean",
  setting_value("environment", "covariates") == "None",
  setting_value("F", "selectivity_structure") == "Five blocks: fleet 1 uses logistic blocks 1–2; indices 1–3 use age-specific blocks 3–5",
  all(grepl("summary_text.png", settings$source_reference[settings$setting %in% c("diagnostic_run", "composition_likelihood", "model", "covariates", "selectivity_structure")], fixed = TRUE))
)
catch <- x[x$type == "catch", ]
stopifnot(
  identical(catch$year, 2018:2025),
  identical(catch$value, source_values("Catch for Assessment")),
  all(catch$measure == "total_biomass"), all(catch$unit == "t")
)
for (measure in c("SSB", "recruitment")) {
  z <- y[y$measure == measure & y$year <= a$terminal_year, ]
  label <- if (measure == "SSB") "Spawning Stock Biomass" else "Recruits (age 1)"
  stopifnot(identical(z$year, 2018:2025), identical(z$value, source_values(label)))
}
f <- y[y$measure == "Fbar" & y$year <= a$terminal_year, ]
line <- text[grepl("^F", text) & grepl("0.24 0.33 0.42", text, fixed = TRUE)]
stopifnot(length(line) == 1)
values <- as.numeric(regmatches(line, gregexpr("0\\.[0-9]+", line))[[1]])
stopifnot(
  identical(f$value, values), all(f$age_group == "5–7"),
  all(y$age[y$measure == "recruitment"] == 1),
  grepl("29,037", review, fixed = TRUE), grepl("2DAR1", review, fixed = TRUE)
)

projection <- y[y$year %in% 2026:2031, ]
ssb_projection <- projection[projection$measure == "SSB", ]
f_projection <- projection[projection$measure == "Fbar", ]
catch_projection <- projection[projection$measure == "predicted_catch", ]
stopifnot(
  nrow(projection) == 18L,
  identical(ssb_projection$year, 2026:2031),
  identical(ssb_projection$value, c(25281, 21828, 19804, 19818, 20956, 22157)),
  identical(ssb_projection$lwr, c(9775, 6359, 5174, 4053, 3246, 2772)),
  identical(ssb_projection$upr, c(65382, 74926, 75810, 96904, 135301, 177110)),
  identical(f_projection$year, 2026:2031),
  all(f_projection$age_group == "5–7"),
  identical(f_projection$value, c(.247, rep(.27, 5))),
  f_projection$lwr[1L] == .09, f_projection$upr[1L] == .675,
  all(is.na(f_projection$lwr[-1L])), all(is.na(f_projection$upr[-1L])),
  identical(catch_projection$year, 2026:2031),
  identical(catch_projection$value, c(5768, 5277, 4640, 4498, 4659, 4888)),
  is.na(catch_projection$lwr[1L]), is.na(catch_projection$upr[1L]),
  identical(catch_projection$lwr[-1L], c(1524, 1230, 973, 769, 645)),
  identical(catch_projection$upr[-1L], c(18271, 17511, 20785, 28245, 37014)),
  all(projection$source_type == "official_table"),
  !anyDuplicated(paste(projection$measure, projection$year, sep = "\034"))
)
m <- x[x$type == "M", ]
stopifnot(
  identical(m$age, 1:9), all(m$value == .2), all(m$year == 1931),
  !any(x$type == "index"), !any(x$measure == "numbers_at_age"),
  all(is.na(y$se))
)
message("Georges Bank haddock summaries, projections, fixed M, and diagnostic run settings verified; missing numerical age-structured streams remain explicit.")
