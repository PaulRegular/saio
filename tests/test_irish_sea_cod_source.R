root <- "."
stocks <- read.csv(file.path(root, "database/stocks.csv"), stringsAsFactors = FALSE)
assessments <- read.csv(file.path(root, "database/assessments.csv"), stringsAsFactors = FALSE)
inputs <- read.csv(file.path(root, "database/inputs.csv"), stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
outputs <- read.csv(file.path(root, "database/outputs.csv"), stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)

stock_id <- "ck_ices_wgcse_morhua_is7a"
assessment_id <- "ices_cod_irish_sea_2026"
stock <- stocks[stocks$stock_id == stock_id, ]
assessment <- assessments[assessments$assessment_id == assessment_id, ]
x <- inputs[inputs$assessment_id == assessment_id, ]
y <- outputs[outputs$assessment_id == assessment_id, ]

catch <- x[x$type == "catch" & x$measure == "numbers_at_age", ]
discards <- x[x$measure == "discard_numbers_at_age", ]
weights <- x[x$type == "weight" & x$measure == "weight_at_age", ]
maturity <- x[x$measure == "maturity_at_age", ]
mortality <- x[x$type == "M" & x$measure == "natural_mortality_at_age", ]
q1 <- x[!is.na(x$survey) & x$survey == "NIGFS-WIBTS-Q1 (G7144)" & x$measure == "numbers_at_age", ]
q1_cv <- x[!is.na(x$survey) & x$survey == "NIGFS-WIBTS-Q1 (G7144)" & x$measure == "relative_standard_error", ]
q4 <- x[!is.na(x$survey) & x$survey == "NIGFS-WIBTS-Q4 (G7655)" & x$measure == "numbers_at_age", ]
fsp <- x[!is.na(x$survey) & x$survey == "UK FSP (B7897)" & x$measure == "numbers_at_age", ]

stopifnot(
  nrow(stock) == 1L,
  stock$authority_stock_id == "cod.27.7a",
  stock$ocean == "Northeast Atlantic",
  nrow(assessment) == 1L,
  assessment$assessment_year == 2026,
  assessment$terminal_year == 2025,
  assessment$estimate_terminal_year == 2026,
  assessment$assumptions_status == "partial",
  assessment$inputs_status == "partial",
  assessment$outputs_status == "partial",
  nrow(catch) == 58L * 7L,
  setequal(unique(catch$year), 1968:2025),
  setequal(unique(catch$age), 0:6),
  all(grepl("excluded from the assessment", catch$notes[catch$year %in% c(2003:2005, 2020)])),
  nrow(discards) == 398L,
  !2020 %in% discards$year,
  !any(discards$year == 2023 & discards$age == 0),
  nrow(weights) == 405L,
  !any(weights$year == 2019 & weights$age == 0),
  nrow(weights[weights$age %in% 1:6, ]) == 58L * 6L,
  !anyNA(weights$value[weights$age %in% 1:6]),
  nrow(maturity) == 58L * 7L,
  maturity$value[maturity$year == 1995 & maturity$age == 2] == 0.27,
  maturity$value[maturity$year == 1996 & maturity$age == 2] == 0.292,
  maturity$value[maturity$year == 2025 & maturity$age == 2] == 0.875,
  all(maturity$value[maturity$age %in% c(0, 1)] == 0),
  all(maturity$value[maturity$age >= 3] == 1),
  nrow(mortality) == 7L,
  all(is.na(mortality$year)),
  mortality$value[mortality$age == 0] == 1.7,
  mortality$value[mortality$age == 1] == 0.714,
  mortality$value[mortality$age == 2] == 0.68,
  all(mortality$value[mortality$age >= 3] == 0.65),
  nrow(q1) == 31L * 4L,
  nrow(q1_cv) == 31L * 4L,
  nrow(q4) == 30L,
  nrow(fsp) == 20L * 5L,
  all(q1$basis == "index_scale"),
  all(q1$unit == "native survey index (unit unresolved)"),
  sum(y$measure == "SSB") == 59L,
  sum(y$measure == "recruitment") == 59L,
  sum(y$measure == "Fbar") == 58L,
  all(y$source_type == "official_table"),
  all(is.na(y$se)),
  all(grepl("95%", y$notes[!is.na(y$year) & y$year <= 2025]))
)

review <- readLines(file.path(root, "source_reviews/ices_cod_irish_sea.md"), warn = FALSE)
stopifnot(
  any(grepl("2019 age 0", review, fixed = TRUE)),
  any(grepl("over 1968–2018", review, fixed = TRUE)),
  any(grepl("mean absolute percent difference 36.5%", review, fixed = TRUE))
)

cat("Irish Sea cod source coverage, provenance and 1968-2018 readiness passed.\n")
