outputs <- read.csv(
  "database/outputs.csv",
  colClasses = "character", na.strings = c("", "NA"),
  stringsAsFactors = FALSE, check.names = FALSE
)
assessment_id <- "ices_herring_north_sea_2026"
q <- outputs[
  outputs$assessment_id == assessment_id & outputs$type == "catchability" &
    outputs$measure == "q", , drop = FALSE
]
expected <- data.frame(
  survey = c(
    rep("HERAS", 8), "IBTS-Q1", "IBTS0", rep("IBTS-Q3", 6),
    "LAI-ORSH", "LAI-BUN", "LAI-CNS", "LAI-SNS"
  ),
  age = c(1:8, 1, 0, 0:5, 0, 0, 0, 0),
  value = c(
    0.9514, 0.9514, rep(1.067, 6), 0.1101, 3.693e-06,
    0.1135, 0.04981, 0.03912, 0.03559, 0.03028, 0.0232,
    rep(0.01516, 4)
  ),
  cv = c(
    rep(0.06503, 2), rep(0.05494, 6), 0.08044, 0.08755,
    0.1194, 0.1159, 0.07968, 0.07864, 0.07987, 0.08095,
    rep(0.1011, 4)
  ),
  lwr = c(
    rep(0.8375, 2), rep(0.9584, 6), 0.09405, 3.111e-06,
    0.08982, 0.03969, 0.03346, 0.03051, 0.02589, 0.01979,
    rep(0.01244, 4)
  ),
  upr = c(
    rep(1.081, 2), rep(1.189, 6), 0.1289, 4.385e-06,
    0.1434, 0.06251, 0.04573, 0.04152, 0.03541, 0.02718,
    rep(0.01849, 4)
  ),
  stringsAsFactors = FALSE
)
row_key <- function(x) paste(x$survey, x$age, sep = "|")
q <- q[order(q$survey, as.integer(q$age)), ]
expected <- expected[order(expected$survey, expected$age), ]
stopifnot(
  nrow(q) == 20L,
  !anyDuplicated(row_key(q)),
  identical(row_key(q), row_key(expected)),
  isTRUE(all.equal(as.numeric(q$value), expected$value, tolerance = 1e-12)),
  isTRUE(all.equal(as.numeric(q$se), expected$value * expected$cv, tolerance = 1e-12)),
  isTRUE(all.equal(as.numeric(q$lwr), expected$lwr, tolerance = 1e-12)),
  isTRUE(all.equal(as.numeric(q$upr), expected$upr, tolerance = 1e-12)),
  all(q$source_type == "official_table"),
  all(grepl("Table 2.6.2.2", q$source_reference, fixed = TRUE)),
  all(grepl("Reported CV=", q$notes, fixed = TRUE)),
  all(grepl("confidence level or construction", q$notes, fixed = TRUE)),
  all(q$unit == "native model q scale (physical index unit unresolved)")
)
assessments <- read.csv(
  "database/assessments.csv",
  colClasses = "character", na.strings = c("", "NA"),
  stringsAsFactors = FALSE, check.names = FALSE
)
a <- assessments[assessments$assessment_id == assessment_id, ]
stopifnot(a$outputs_status == "partial")
message("North Sea herring official q outputs match Table 2.6.2.2.")
