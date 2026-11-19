root <- "."
source(file.path(root, "R", "read_database.R"))
database <- read_database()
assessment_id <- "ices_plaice_irish_sea_7a_2026"
source <- read_assessment(assessment_id, database)
inputs <- source$inputs
outputs <- source$outputs

stopifnot(
  nrow(source$assessment) == 1L,
  source$assessment$stock_id == "ck_ices_wgcse_platessa_is27_7a",
  source$assessment$terminal_year == 2025L,
  source$assessment$estimate_terminal_year == 2026L,
  source$assessment$assumptions_status == "complete",
  source$assessment$inputs_status == "complete",
  source$assessment$outputs_status == "complete",
  source$stock$authority_stock_id == "ple.27.7a",
  source$stock$common_name == "Irish Sea plaice"
)

catch <- subset(inputs, type == "catch" & measure == "numbers_at_age")
catch$value <- as.numeric(catch$value)
catch_key <- paste(catch$year, catch$age, sep = ":")
expected_catch_key <- as.vector(outer(1981:2025, 1:8, paste, sep = ":"))
stopifnot(
  nrow(catch) == 360L,
  !anyDuplicated(catch_key),
  setequal(catch_key, expected_catch_key),
  sum(is.na(catch$value)) == 2L,
  all(catch$unit == "thousand fish")
)

uk_bts <- subset(inputs, type == "index" & survey == "UK BTS-Q3")
nigfs_q1 <- subset(inputs, type == "index" & survey == "NIGFS-WIBTS-Q1")
nigfs_q4 <- subset(inputs, type == "index" & survey == "NIGFS-WIBTS-Q4")
stopifnot(
  nrow(uk_bts) == 224L,
  setequal(as.integer(uk_bts$age), 1:7),
  all(as.numeric(uk_bts$sampling_time) == 0.8),
  nrow(nigfs_q1) == 34L, nrow(nigfs_q4) == 33L,
  all(is.na(nigfs_q1$age)), all(is.na(nigfs_q4$age)),
  all(nigfs_q1$unit == "kg per 3 miles"),
  all(nigfs_q4$unit == "kg per 3 miles"),
  all(as.numeric(nigfs_q1$sampling_time) == 0),
  all(as.numeric(nigfs_q4$sampling_time) == 0)
)

for (measure in c("natural_mortality_at_age", "maturity_at_age",
                  "fraction_F_before_spawning", "fraction_M_before_spawning")) {
  rows <- inputs[inputs$measure == measure, , drop = FALSE]
  stopifnot(nrow(rows) == 8L, setequal(as.integer(rows$age), 1:8))
}
for (type_measure in list(
  c("weight", "weight_at_age"),
  c("catch_weight", "weight_at_age"),
  c("catch_weight", "landings_weight_at_age"),
  c("catch_weight", "discard_weight_at_age")
)) {
  rows <- inputs[inputs$type == type_measure[[1L]] &
    inputs$measure == type_measure[[2L]], , drop = FALSE]
  stopifnot(nrow(rows) == 360L, setequal(as.integer(rows$age), 1:8),
    setequal(as.integer(rows$year), 1981:2025))
}

n_at_age <- subset(outputs, measure == "numbers_at_age")
f_at_age <- subset(outputs, measure == "fishing_mortality_at_age")
total_n <- subset(outputs, measure == "total_abundance")
stopifnot(
  nrow(n_at_age) == 360L,
  nrow(f_at_age) == 360L,
  all(n_at_age$unit == "thousand fish"),
  all(f_at_age$unit == "per year"),
  nrow(total_n) == 45L,
  all(is.na(total_n$se)),
  isTRUE(all.equal(
    as.numeric(total_n$value[order(as.integer(total_n$year))]),
    unname(vapply(split(as.numeric(n_at_age$value), n_at_age$year), sum, numeric(1))),
    tolerance = 1e-12
  ))
)

q <- subset(outputs, type == "catchability" & measure == "q")
q$age <- as.integer(q$age)
q$value <- as.numeric(q$value)
q$se <- as.numeric(q$se)
q$lwr <- as.numeric(q$lwr)
q$upr <- as.numeric(q$upr)
uk_bts_q <- subset(q, survey == "UK BTS-Q3")
nigfs_q <- subset(q, survey %in% c("NIGFS-WIBTS-Q1", "NIGFS-WIBTS-Q4"))
stopifnot(
  nrow(q) == 9L, nrow(uk_bts_q) == 7L, nrow(nigfs_q) == 2L,
  setequal(uk_bts_q$age, 1:7), all(is.na(nigfs_q$age)),
  all(is.finite(q$value)), all(is.finite(q$se)),
  all(q$value > 0), all(q$se > 0), all(q$lwr > 0), all(q$upr > q$lwr),
  all(uk_bts_q$unit == "native survey-index units per thousand fish"),
  all(nigfs_q$unit == "native survey-index units per tonne SSB"),
  isTRUE(all.equal(
    q$lwr,
    exp(log(q$value) - stats::qnorm(0.975) * q$se / q$value),
    tolerance = 1e-10
  )),
  isTRUE(all.equal(
    q$upr,
    exp(log(q$value) + stats::qnorm(0.975) * q$se / q$value),
    tolerance = 1e-10
  ))
)

predicted_catch <- subset(outputs, measure == "predicted_catch")
predicted_index <- subset(outputs, measure == "predicted_index")
stopifnot(
  nrow(predicted_catch) == 360L,
  setequal(as.integer(predicted_catch$year), 1981:2025),
  setequal(as.integer(predicted_catch$age), 1:8),
  all(predicted_catch$unit == "thousand fish"),
  nrow(subset(predicted_index, survey == "UK BTS-Q3")) == 231L,
  nrow(subset(predicted_index, survey == "NIGFS-WIBTS-Q1")) == 34L,
  nrow(subset(predicted_index, survey == "NIGFS-WIBTS-Q4")) == 34L,
  setequal(as.integer(subset(predicted_index, survey == "UK BTS-Q3")$age), 1:7),
  all(is.na(subset(predicted_index, survey != "UK BTS-Q3")$age)),
  nrow(subset(predicted_index, survey == "UK BTS-Q3")) - nrow(uk_bts) == 7L,
  nrow(subset(predicted_index, survey == "NIGFS-WIBTS-Q4")) - nrow(nigfs_q4) == 1L,
  all(is.finite(as.numeric(c(predicted_catch$value, predicted_index$value)))),
  !anyDuplicated(predicted_catch[c("year", "age")]),
  !anyDuplicated(predicted_index[c("survey", "year", "age")])
)

f_age7 <- f_at_age[f_at_age$age == "7", ]
f_age8 <- f_at_age[f_at_age$age == "8", ]
stopifnot(isTRUE(all.equal(as.numeric(f_age7$value), as.numeric(f_age8$value))))

for (measure in c("SSB", "recruitment")) {
  fitted <- outputs[outputs$measure == measure & as.integer(outputs$year) <= 2025L, ]
  forecast <- outputs[outputs$measure == measure & as.integer(outputs$year) == 2026L, ]
  stopifnot(nrow(fitted) == 45L, all(is.finite(as.numeric(fitted$se))),
    nrow(forecast) == 1L, all(is.finite(as.numeric(forecast$lwr))),
    all(is.finite(as.numeric(forecast$upr))))
}

assumptions <- source$assumptions
for (season in c("Q1", "Q4")) {
  survey <- paste0("NIGFS-WIBTS-", season)
  row <- assumptions[assumptions$setting == "sampling_time" &
    assumptions$survey == survey, , drop = FALSE]
  stopifnot(nrow(row) == 1L, row$season == season, row$value == "0")
}

cat("Irish Sea plaice source record validated.\n")
