assessment_id <- "noaa_gulf_gray_triggerfish_sedar100_2026"
lines <- system2("rg", c("--color", "never", "--no-heading",
  "--no-line-number", "-F", assessment_id, "database/inputs.csv"),
  stdout = TRUE, stderr = FALSE)
status <- attr(lines, "status")
if (is.null(status)) status <- 0L
stopifnot(status == 0L)
inputs <- read.csv(text = paste(c(readLines("database/inputs.csv", n = 1L), lines),
  collapse = "\n"), stringsAsFactors = FALSE, na.strings = c("", "NA"),
  check.names = FALSE)
inputs <- inputs[inputs$type == "biology" &
  inputs$measure == "composition_sample_count", , drop = FALSE]

dw04 <- inputs[inputs$source_reference == "SEDAR 100-DW-04, Table 3", , drop = FALSE]
dw07 <- inputs[grepl("SEDAR 100-DW-07, Table A.4", inputs$source_reference,
  fixed = TRUE), , drop = FALSE]
handline <- dw07[dw07$fleet == "Commercial handline", , drop = FALSE]
longline <- dw07[dw07$fleet == "Commercial longline", , drop = FALSE]

stopifnot(
  nrow(inputs) == 329L,
  all(inputs$type == "biology"),
  all(inputs$measure == "composition_sample_count"),
  all(inputs$basis == "numbers"),
  all(inputs$unit == "fish"),
  all(inputs$year_basis == "calendar_year"),
  all(inputs$source_type == "official_table"),
  all(inputs$assessment_id == assessment_id),
  all(!is.na(inputs$observation_id) & nzchar(inputs$observation_id)),
  nrow(dw04) == 286L,
  length(unique(dw04$observation_id)) == 13L,
  all(vapply(split(dw04$year, dw04$observation_id), function(x)
    identical(sort(as.integer(x)), 2003:2024), logical(1))),
  sum(dw04$value) == 9289,
  any(dw04$value == 0),
  nrow(dw07) == 43L,
  nrow(handline) == 22L,
  nrow(longline) == 21L,
  sum(handline$value) == 5130,
  sum(longline$value) == 900,
  handline$value[handline$year == 2020] == 224,
  !any(longline$year == 2020),
  !any(grepl("proportion_at_age|numbers_at_age", inputs$measure))
)
