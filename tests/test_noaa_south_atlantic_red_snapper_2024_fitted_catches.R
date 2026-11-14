assessment_id <- "noaa_south_atlantic_red_snapper_2024"
output_path <- "database/outputs.csv"
marker <- assessment_id
lines <- suppressWarnings(system2("rg", c(
  "--color", "never", "--no-filename", "--no-heading", "--no-line-number",
  "--fixed-strings", marker, output_path
), stdout = TRUE, stderr = FALSE))
status <- attr(lines, "status")
if (is.null(status)) status <- 0L
stopifnot(status == 0L, length(lines) > 0L)

outputs <- utils::read.csv(
  text = paste(lines, collapse = "\n"),
  header = FALSE,
  col.names = c(
    "assessment_id", "type", "measure", "fleet", "survey", "sex", "region",
    "season", "year", "age", "age_group", "value", "se", "lwr", "upr",
    "unit", "source_type", "source_reference", "notes", "scenario"
  ),
  stringsAsFactors = FALSE,
  na.strings = c("", "NA"),
  check.names = FALSE
)
outputs <- outputs[outputs$type == "catch", , drop = FALSE]
tables <- lapply(11:18, function(number) {
  outputs[grepl(paste0("Table ", number, ","), outputs$source_reference, fixed = TRUE), , drop = FALSE]
})
names(tables) <- as.character(11:18)

stopifnot(
  sum(vapply(tables, nrow, integer(1))) == 6806L,
  nrow(tables[["11"]]) == 296L,
  nrow(tables[["12"]]) == 296L,
  nrow(tables[["13"]]) == 147L,
  nrow(tables[["14"]]) == 147L,
  all(vapply(tables[c("15", "16", "17", "18")], nrow, integer(1)) == 1480L),
  all(vapply(tables, function(x) all(x$source_type == "official_table"), logical(1))),
  all(vapply(tables, function(x) all(x$type == "catch"), logical(1)))
)

at_year <- function(x, year, measure = NULL, fleet = NULL) {
  keep <- x$year == year
  if (!is.null(measure)) keep <- keep & x$measure == measure
  if (!is.null(fleet)) keep <- keep & x$fleet == fleet
  x[keep, , drop = FALSE]
}

stopifnot(
  at_year(tables[["11"]], 2023L, fleet = "cH")$value == 13.08,
  at_year(tables[["11"]], 2023L, fleet = "Total")$value == 135.63,
  at_year(tables[["12"]], 2023L, fleet = "Total")$value == 1521.27,
  at_year(tables[["13"]], 2023L, fleet = "Total")$value == 496.37,
  at_year(tables[["14"]], 2023L, fleet = "Total")$value == 2931.70,
  !nrow(at_year(tables[["13"]], 1981L, fleet = "cH")),
  at_year(tables[["13"]], 1981L, fleet = "GR")$value == 2.70
)

age_totals <- function(x, year) sum(x$value[x$year == year])
stopifnot(
  abs(age_totals(tables[["15"]], 2023L) - 135.64) < 0.05,
  abs(age_totals(tables[["16"]], 2023L) - 1521.27) < 0.05,
  abs(age_totals(tables[["17"]], 2023L) - 496.35) < 0.05,
  abs(age_totals(tables[["18"]], 2023L) - 2931.70) < 0.05,
  all(sort(unique(tables[["16"]]$age)) == 1:20),
  all(tables[["16"]]$age_group[tables[["16"]]$age == 20L] == "20+"),
  all(grepl("match Table 11 landings", tables[["15"]]$notes, fixed = TRUE))
)

assessment <- utils::read.csv("database/assessments.csv", stringsAsFactors = FALSE, check.names = FALSE)
assessment <- assessment[assessment$assessment_id == assessment_id, , drop = FALSE]
stopifnot(
  nrow(assessment) == 1L,
  assessment$inputs_status == "partial",
  assessment$outputs_status == "partial"
)

cat("South Atlantic red snapper fitted catch outputs and source caveat passed.\n")
