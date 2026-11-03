source("R/read_database.R")
source_data <- read_assessment("dfo_herring_4tvn_spring_2024", read_database())
outputs <- source_data$outputs
derived <- outputs[outputs$source_type == "derived_source_output", ]
stopifnot(
  nrow(derived) == 598L,
  all(is.na(derived$se)), all(is.na(derived$lwr)), all(is.na(derived$upr)),
  all(grepl("January 1", derived$notes, fixed = TRUE)),
  all(grepl("2024/058", derived$source_reference, fixed = TRUE))
)
for (year in 1978:2023) {
  x <- outputs[outputs$year == year, ]
  n <- x[x$measure == "numbers_at_age", ]
  b <- x[x$measure == "biomass_at_age", ]
  m <- x[x$measure == "mature_biomass_at_age", ]
  total <- x[x$measure == "total_numbers" & x$source_type == "derived_source_output", ]
  biomass <- x[x$measure == "total_biomass" & x$source_type == "derived_source_output", ]
  ssb <- x[x$measure == "SSB", ]
  stopifnot(
    identical(sort(n$age), 2:11), identical(sort(b$age), 2:11),
    nrow(total) == 1L, nrow(biomass) == 1L, nrow(ssb) == 1L,
    isTRUE(all.equal(total$value, sum(n$value))),
    isTRUE(all.equal(biomass$value, sum(b$value))),
    isTRUE(all.equal(ssb$value, sum(b$value[b$age >= 4]))),
    isTRUE(all.equal(ssb$value, sum(m$value))),
    all(m$value[m$age <= 3] == 0),
    all(ssb$unit == "tonnes"), all(total$unit == "thousand fish"),
    grepl("not the assessment's April 1 SSB", ssb$notes, fixed = TRUE),
    nrow(x[x$measure == "total_numbers" & x$age_group == "4+" & !is.na(x$age_group), ]) == 1L
  )
}
cat("Southern Gulf herring derived-output tests passed.\n")
