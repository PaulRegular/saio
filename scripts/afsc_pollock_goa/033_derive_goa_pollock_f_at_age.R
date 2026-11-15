root <- "."
id <- "afsc_pollock_goa_2024"
outputs_path <- file.path(root, "database", "outputs.csv")
inputs_path <- file.path(root, "database", "inputs.csv")

outputs <- read.csv(outputs_path, stringsAsFactors = FALSE, na.strings = c("", "NA"))
inputs <- read.csv(inputs_path, stringsAsFactors = FALSE, na.strings = c("", "NA"))
n <- outputs[outputs$assessment_id == id & outputs$measure == "numbers_at_age", ]
m <- inputs[inputs$assessment_id == id & inputs$type == "M" &
  inputs$measure == "natural_mortality_at_age", ]

stopifnot(
  nrow(n) == 550L,
  setequal(unique(n$year), 1970:2024),
  setequal(unique(n$age), 1:10),
  nrow(m) == 10L,
  setequal(m$age, 1:10),
  all(m$unit == "per year")
)

n_by_year_age <- setNames(n$value, paste(n$year, n$age, sep = ":"))
candidate <- n[n$age <= 8 & n$year < 2024, c("year", "age", "value")]
next_n <- unname(n_by_year_age[paste(candidate$year + 1, candidate$age + 1, sep = ":")])
m_at_age <- m$value[match(candidate$age, m$age)]

candidate$f <- log(candidate$value / next_n) - m_at_age
candidate$rounding_lower <- log((candidate$value - 0.5) / (next_n + 0.5)) - m_at_age
candidate <- candidate[is.finite(candidate$rounding_lower) & candidate$rounding_lower > 0, ]

model_reference <- paste0(
  "https://github.com/afsc-assessments/GOApollock/blob/",
  "aefe1692520510d55fd25db60121b292a53840a3/data/2024/goa_pk.cpp#L676-L691"
)
table_reference <- "https://files.npfmc.org/SAFE/2024/GOApollock.pdf; Table 1.22, pp. 50-51"
notes <- paste(
  "Approximate total F-at-age reconstructed from the source cohort equation",
  "N[y+1,a+1] = N[y,a] * exp(-Z[y,a]), with Z = F-at-age + M[a].",
  "The published N values are rounded to the nearest million fish; a value is",
  "retained only when F remains positive across the +/-0.5-million rounding",
  "bounds. This is a derived source output, not a reported F estimate, and has",
  "no available SE or interval. Near-zero cells are omitted. Coverage is ages",
  "1-8 in 1970-2023; transitions into the age-10+ plus group are excluded."
)

derived <- data.frame(
  assessment_id = id,
  type = "mortality",
  measure = "fishing_mortality_at_age",
  fleet = NA_character_,
  survey = NA_character_,
  sex = NA_character_,
  region = NA_character_,
  season = NA_character_,
  year = candidate$year,
  age = candidate$age,
  age_group = NA_character_,
  value = candidate$f,
  se = NA_real_,
  lwr = NA_real_,
  upr = NA_real_,
  unit = "per year",
  source_type = "derived_source_output",
  source_reference = paste(table_reference, model_reference, sep = "; "),
  notes = notes,
  stringsAsFactors = FALSE
)

existing <- outputs[outputs$assessment_id == id &
  outputs$measure == "fishing_mortality_at_age" &
  outputs$source_type == "derived_source_output", ]
if (nrow(existing)) {
  key <- function(x) paste(x$year, x$age, sep = ":")
  existing <- existing[order(existing$year, existing$age), names(derived)]
  expected <- derived[order(derived$year, derived$age), ]
  stopifnot(
    nrow(existing) == nrow(expected),
    identical(key(existing), key(expected)),
    isTRUE(all.equal(existing$value, expected$value, tolerance = 1e-12)),
    all(existing$source_reference == expected$source_reference),
    all(existing$notes == expected$notes)
  )
} else {
  write.table(
    derived, outputs_path, sep = ",", row.names = FALSE, col.names = FALSE,
    append = TRUE, na = "", qmethod = "double"
  )
}

assessment_path <- file.path(root, "database", "assessments.csv")
assessment_raw <- readBin(assessment_path, what = "raw", n = file.info(assessment_path)$size)
assessment_text <- rawToChar(assessment_raw)
old_note <- "F-at-age and further outputs missing."
new_note <- paste(
  "Partial rounded-output F-at-age values are derived for ages 1-8 in 1970-2023;",
  "direct official estimates and their uncertainty remain unavailable."
)
if (grepl(old_note, assessment_text, fixed = TRUE)) {
  assessment_text <- sub(old_note, new_note, assessment_text, fixed = TRUE)
  writeBin(charToRaw(assessment_text), assessment_path)
} else {
  stopifnot(grepl(new_note, assessment_text, fixed = TRUE))
}

cat("Derived", nrow(derived), "rounded-output F-at-age values for", id, "\n")
