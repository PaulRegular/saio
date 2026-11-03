source("R/read_database.R")

database <- read_database()
latest <- read_assessment("dfo_herring_4tvn_spring_2026", database)
outputs <- latest$outputs
ssb <- outputs[outputs$measure == "SSB", , drop = FALSE]
recruitment <- outputs[outputs$measure == "recruitment", , drop = FALSE]
natural_mortality <- outputs[
  outputs$measure == "natural_mortality_at_age", , drop = FALSE
]
assumptions <- latest$assumptions[
  latest$assumptions$setting == "natural_mortality_age_groups", ,
  drop = FALSE
]

stopifnot(
  nrow(outputs) == 6L,
  identical(sort(ssb$year), c(2024L, 2025L)),
  identical(ssb$value[match(c(2024L, 2025L), ssb$year)], c(11816, 17412)),
  identical(ssb$lwr[match(c(2024L, 2025L), ssb$year)], c(8035, 9990)),
  identical(ssb$upr[match(c(2024L, 2025L), ssb$year)], c(17377, 30349)),
  all(ssb$unit == "tonnes"),
  all(grepl("April 1", ssb$notes, fixed = TRUE)),
  identical(recruitment$value[match(c(2024L, 2025L), recruitment$year)],
    c(65970950, 84872640)),
  all(recruitment$age == 2L),
  all(recruitment$unit == "fish"),
  all(is.na(recruitment$se)),
  identical(natural_mortality$value[
    match(c(2024L, 2025L), natural_mortality$year)
  ], c(0.43, 0.44)),
  all(natural_mortality$age_group == "8-11+"),
  all(natural_mortality$unit == "per year"),
  nrow(assumptions) == 1L,
  grepl("Ages 2-7 fixed at M=0.3", assumptions$value, fixed = TRUE),
  all(outputs$source_type == "official_table"),
  all(grepl("2026/028", outputs$source_reference, fixed = TRUE))
)

prior <- read_assessment("dfo_herring_4tvn_spring_2024", database)$outputs
stopifnot(
  max(prior$year, na.rm = TRUE) == 2023L,
  !any(prior$year %in% c(2024L, 2025L))
)

cat("Southern Gulf herring 2026 summary-output tests passed.\n")
