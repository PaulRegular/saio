database <- "database"
assessment_id <- "dfo_cod_4t4vn_2024"
assessments <- read.csv(file.path(database, "assessments.csv"),
  stringsAsFactors = FALSE, na.strings = "", check.names = FALSE
)
outputs <- read.csv(file.path(database, "outputs.csv"),
  stringsAsFactors = FALSE, na.strings = "", check.names = FALSE
)
assessment <- assessments[assessments$assessment_id == assessment_id, , drop = FALSE]
source_outputs <- outputs[outputs$assessment_id == assessment_id &
  outputs$source_type == "official_document" &
  grepl("rebuilding plan, Figure 3 data table", outputs$source_reference,
    fixed = TRUE
  ), , drop = FALSE]

f <- source_outputs[source_outputs$measure == "fishing_mortality_summary", ]
m58 <- source_outputs[source_outputs$measure == "Mbar" &
  source_outputs$age_group == "5-8", ]
m9 <- source_outputs[source_outputs$measure == "Mbar" &
  source_outputs$age_group == "9+", ]

stopifnot(
  nrow(assessment) == 1L,
  assessment$assessment_year == 2024L,
  assessment$terminal_year == 2023L,
  assessment$outputs_status == "partial",
  nrow(source_outputs) == 222L,
  nrow(f) == 74L,
  nrow(m58) == 74L,
  nrow(m9) == 74L,
  identical(as.integer(f$year), 1950:2023),
  identical(as.integer(m58$year), 1950:2023),
  identical(as.integer(m9$year), 1950:2023),
  all(is.na(f$age_group)),
  all(f$unit == "yr-1"),
  all(m58$unit == "yr-1"),
  all(m9$unit == "yr-1"),
  all(is.na(f$se) & is.na(m58$se) & is.na(m9$se)),
  all(as.numeric(f$lwr) <= as.numeric(f$value) &
    as.numeric(f$value) <= as.numeric(f$upr)),
  all(as.numeric(m58$lwr) <= as.numeric(m58$value) &
    as.numeric(m58$value) <= as.numeric(m58$upr)),
  all(as.numeric(m9$lwr) <= as.numeric(m9$value) &
    as.numeric(m9$value) <= as.numeric(m9$upr)),
  all(grepl("95% confidence interval", f$notes, fixed = TRUE)),
  all(grepl("95% confidence interval", m58$notes, fixed = TRUE)),
  all(grepl("95% confidence interval", m9$notes, fixed = TRUE)),
  grepl("does not specify its age range", f$notes[1], fixed = TRUE),
  as.numeric(f$value[f$year == 1950]) == 0.094,
  as.numeric(f$lwr[f$year == 1950]) == 0.073,
  as.numeric(f$upr[f$year == 1950]) == 0.115,
  as.numeric(f$value[f$year == 2023]) == 0.003,
  as.numeric(m58$value[m58$year == 2023]) == 1.017,
  as.numeric(m9$value[m9$year == 2023]) == 1.222,
  all(grepl("cod-4TVn-morue-eng.html", source_outputs$source_reference,
    fixed = TRUE
  ))
)

cat("Southern Gulf cod F and grouped M outputs validated for 1950-2023.\n")
