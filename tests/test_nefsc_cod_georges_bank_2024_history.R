source("R/read_database.R")
x <- read_assessment("nefsc_cod_georges_bank_2024")
history <- x$outputs[x$outputs$source_type == "official_machine_readable", ]
ssb <- history[history$measure == "SSB", ]
recruitment <- history[history$measure == "recruitment", ]
f <- history[history$measure == "fishing_mortality_at_age", ]

stopifnot(
  nrow(history) == 108L,
  all(table(history$measure) == 36L),
  identical(sort(ssb$year), 1978:2013),
  identical(sort(recruitment$year), 1978:2013),
  identical(sort(f$year), 1978:2013),
  ssb$value[ssb$year == 1978] == 32294,
  ssb$value[ssb$year == 2013] == 4093,
  recruitment$value[recruitment$year == 1978] == 7511,
  recruitment$value[recruitment$year == 2013] == 110,
  f$value[f$year == 1978] == .372,
  f$value[f$year == 2013] == .211,
  all(f$age == 9L),
  all(f$age_group == "9+"),
  all(history$unit[history$measure == "SSB"] == "tonnes"),
  all(history$unit[history$measure == "recruitment"] == "thousand fish"),
  all(f$unit == "year^-1"),
  all(grepl("assessment_id=13596", history$notes, fixed = TRUE)),
  all(grepl("2014-2023 checked against the assessment report Table 1",
    history$notes, fixed = TRUE)),
  all(is.na(history$se)),
  all(is.na(history$lwr)),
  all(is.na(history$upr)),
  !anyDuplicated(x$outputs[c("measure", "year")])
)

cat("Georges Bank cod Stock SMART historical output coverage passed.\n")
