root <- "."
assessment_id <- "afsc_cod_goa_2026"
report <- paste0(
  "https://meetings.npfmc.org/CommentReview/DownloadFile?",
  "fileName=C1+GOA+Pcod+Assessment.pdf&p=f00593eb-12f5-458c-842e-a5cdd45306bb.pdf"
)

table_2_9 <- read.csv(text = paste(c(
  "year,apical_F,sd_F",
  "1977,0.012,0.003",
  "1978,0.059,0.013",
  "1979,0.078,0.018",
  "1980,0.194,0.046",
  "1981,0.124,0.027",
  "1982,0.091,0.019",
  "1983,0.117,0.025",
  "1984,0.076,0.017",
  "1985,0.066,0.016",
  "1986,0.096,0.023",
  "1987,0.067,0.016",
  "1988,0.064,0.009",
  "1989,0.080,0.012",
  "1990,0.187,0.022",
  "1991,0.217,0.024",
  "1992,0.253,0.028",
  "1993,0.189,0.020",
  "1994,0.157,0.015",
  "1995,0.234,0.021",
  "1996,0.255,0.022",
  "1997,0.348,0.029",
  "1998,0.404,0.035",
  "1999,0.546,0.050",
  "2000,0.488,0.047",
  "2001,0.395,0.038",
  "2002,0.446,0.042",
  "2003,0.429,0.040",
  "2004,0.439,0.039",
  "2005,0.400,0.041",
  "2006,0.431,0.040",
  "2007,0.493,0.042",
  "2008,0.613,0.055",
  "2009,0.515,0.048",
  "2010,0.608,0.056",
  "2011,0.591,0.057",
  "2012,0.477,0.048",
  "2013,0.390,0.041",
  "2014,0.578,0.060",
  "2015,0.788,0.075",
  "2016,0.815,0.073",
  "2017,0.799,0.085",
  "2018,0.248,0.027",
  "2019,0.255,0.027",
  "2020,0.101,0.010",
  "2021,0.253,0.024",
  "2022,0.313,0.029",
  "2023,0.257,0.024",
  "2024,0.311,0.030",
  "2025,0.399,0.043"
), collapse = "\n"), stringsAsFactors = FALSE)

stopifnot(
  nrow(table_2_9) == 49L,
  identical(table_2_9$year, 1977:2025),
  all(is.finite(table_2_9$apical_F)),
  all(is.finite(table_2_9$sd_F) & table_2_9$sd_F > 0)
)

outputs_path <- file.path(root, "database", "outputs.csv")
outputs <- read.csv(outputs_path, stringsAsFactors = FALSE, check.names = FALSE)
if (any(outputs$assessment_id == assessment_id & outputs$measure == "apical_F")) {
  stop("GOA apical-F outputs are already present in outputs.csv.", call. = FALSE)
}

output_rows <- data.frame(
  assessment_id = assessment_id,
  type = "mortality",
  measure = "apical_F",
  fleet = "", survey = "", sex = "", region = "", season = "",
  year = table_2_9$year, age = NA_real_, age_group = "",
  value = table_2_9$apical_F, se = table_2_9$sd_F,
  lwr = NA_real_, upr = NA_real_, unit = "per year",
  source_type = "official_table",
  source_reference = paste(report, "Table 2.9", sep = "; "),
  notes = paste(
    "Source-reported annual Sum Apical F and SD[F], rounded to three decimals.",
    "This aggregate is not F-at-age or age-averaged Fbar; no interval reconstructed."
  ),
  stringsAsFactors = FALSE
)
utils::write.table(
  output_rows[names(outputs)], outputs_path,
  sep = ",", quote = TRUE, row.names = FALSE, col.names = FALSE,
  append = TRUE, na = ""
)

check_outputs <- read.csv(outputs_path, stringsAsFactors = FALSE, check.names = FALSE)
added <- check_outputs[
  check_outputs$assessment_id == assessment_id &
    check_outputs$measure == "apical_F",
]
stopifnot(
  nrow(added) == 49L,
  identical(sort(added$year), 1977:2025),
  all(added$type == "mortality"),
  all(added$unit == "per year"),
  all(added$source_type == "official_table"),
  all(is.finite(added$value)),
  all(is.finite(added$se) & added$se > 0)
)
cat("Recorded 49 official annual sum apical-F estimates and reported SDs.\n")