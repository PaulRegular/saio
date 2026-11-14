root <- "."
assessment_id <- "noaa_gag_gulf_sedar72_srfs_2022"
rg <- Sys.which("rg")
stopifnot(nzchar(rg))
found <- suppressWarnings(system2(rg, c("--color", "never", "--no-heading",
  "--no-line-number", "-F", assessment_id,
  file.path(root, "database/inputs.csv")), stdout = TRUE, stderr = FALSE))
status <- attr(found, "status")
if (is.null(status)) status <- 0L
stopifnot(status == 0L)
found <- found[startsWith(found,
  paste0('"', assessment_id, '","biology","composition_sample_count",'))]
header <- readLines(file.path(root, "database/inputs.csv"), n = 1L, warn = FALSE)
rows <- read.csv(text = paste(c(header, found), collapse = "\n"),
  stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)
rows <- rows[rows$measure == "composition_sample_count", , drop = FALSE]
fish <- rows[rows$unit == "fish", , drop = FALSE]
trips <- rows[rows$unit == "trips", , drop = FALSE]
stopifnot(
  nrow(rows) == 288L,
  nrow(fish) == 144L,
  nrow(trips) == 144L,
  identical(sort(unique(rows$year)), 1991:2019),
  !anyDuplicated(rows[c("measure", "basis", "year", "fleet", "observation_id")]),
  all(rows$basis == "numbers"),
  all(rows$source_type == "official_table"),
  all(rows$source_reference == "SEDAR72-WP-17, Table 7 (printed pp. 14-15)"),
  all(is.na(rows$sample_size)),
  fish$value[fish$year == 1991L & fish$fleet == "Commercial vertical line"] == 210,
  trips$value[trips$year == 1991L & trips$fleet == "Commercial vertical line"] == 27,
  fish$value[fish$year == 2002L & fish$fleet == "Commercial longline"] == 1085,
  trips$value[trips$year == 2002L & trips$fleet == "Commercial longline"] == 155,
  fish$value[fish$year == 2019L & fish$fleet == "Recreational headboat"] == 107,
  trips$value[trips$year == 2019L & trips$fleet == "Recreational headboat"] == 58,
  !any(fish$year == 2000L & fish$fleet == "Recreational private"),
  all(grepl("not age proportions or effective likelihood sample sizes", rows$notes, fixed = TRUE))
)

review <- paste(readLines(file.path(root, "discovery/source_reviews/noaa_gag_sedar72_2022.md"),
  warn = FALSE), collapse = " ")
stopifnot(grepl("144 fish counts and 144 trip counts are now imported", review, fixed = TRUE))
cat("Gulf gag SEDAR 72 age-sample count source rows and limitations passed.\n")
