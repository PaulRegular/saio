root <- file.path("database")
inputs <- read.csv(file.path(root, "inputs.csv"), stringsAsFactors = FALSE,
  na.strings = c("", "NA"))
outputs <- read.csv(file.path(root, "outputs.csv"), stringsAsFactors = FALSE,
  na.strings = c("", "NA"))
id <- "afsc_pollock_goa_2024"
n <- outputs[outputs$assessment_id == id & outputs$measure == "numbers_at_age", ]
m <- inputs[inputs$assessment_id == id & inputs$type == "M" &
  inputs$measure == "natural_mortality_at_age", ]
f <- outputs[outputs$assessment_id == id &
  outputs$measure == "fishing_mortality_at_age" &
  outputs$source_type == "derived_source_output", ]

n_value <- setNames(n$value, paste(n$year, n$age, sep = ":"))
m_value <- setNames(m$value, m$age)
candidate <- n[n$age <= 8 & n$year < 2024, ]
next_n <- unname(n_value[paste(candidate$year + 1, candidate$age + 1, sep = ":")])
rounding_lower <- log((candidate$value - 0.5) / (next_n + 0.5)) -
  unname(m_value[as.character(candidate$age)])
candidate <- candidate[is.finite(rounding_lower) & rounding_lower > 0, ]
expected <- log(
  candidate$value / unname(n_value[paste(candidate$year + 1, candidate$age + 1, sep = ":")])
) - unname(m_value[as.character(candidate$age)])

f <- f[order(f$year, f$age), ]
candidate <- candidate[order(candidate$year, candidate$age), ]
stopifnot(
  nrow(f) == 371L,
  identical(f$year, candidate$year),
  identical(f$age, candidate$age),
  isTRUE(all.equal(f$value, expected, tolerance = 1e-12)),
  all(f$value > 0),
  all(f$year %in% 1970:2023),
  all(f$age %in% 1:8),
  all(f$unit == "per year"),
  all(is.na(f$se)), all(is.na(f$lwr)), all(is.na(f$upr)),
  all(f$source_type == "derived_source_output"),
  all(grepl("Table 1.22, pp. 50-51", f$source_reference, fixed = TRUE)),
  all(grepl("goa_pk.cpp#L676-L691", f$source_reference, fixed = TRUE)),
  all(grepl("rounded to the nearest million fish", f$notes, fixed = TRUE))
)

cat("GOA pollock derived F-at-age coverage, source equation, and rounding filter passed.\n")
