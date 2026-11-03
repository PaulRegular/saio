root <- "."
read_table <- function(file) {
  read.csv(file.path(root, "database", file), na.strings = c("", "NA"),
    stringsAsFactors = FALSE, check.names = FALSE)
}

assessments <- read_table("assessments.csv")
inputs <- read_table("inputs.csv")
outputs <- read_table("outputs.csv")
a24 <- assessments[assessments$assessment_id == "dfo_cod_3ps_2024", ]
a25 <- assessments[assessments$assessment_id == "dfo_cod_3ps_2025", ]
i <- inputs[inputs$assessment_id == "dfo_cod_3ps_2025", ]
o <- outputs[outputs$assessment_id == "dfo_cod_3ps_2025", ]

stopifnot(
  nrow(a24) == 1L, a24$is_current, a24$is_applied,
  nrow(a25) == 1L, a25$assessment_year == 2025,
  a25$terminal_year == 2025, a25$estimate_terminal_year == 2026,
  a25$assessment_type == "annual", a25$model_family == "HYBRID",
  !a25$is_current, a25$is_applied,
  a25$assumptions_status == "partial", a25$inputs_status == "partial",
  a25$outputs_status == "partial",
  sum(assessments$stock_id == "ck_dfo_morhua_3ps" & assessments$is_current) == 1L,
  nrow(i) == 40L,
  all(i$type == "catch" & i$measure == "numbers_at_age" & i$unit == "fish"),
  all(i$source_type == "official_table"),
  all(i$year[i$year == 2023] == 2023),
  identical(sort(unique(i$age[i$year == 2023])), 1:20),
  identical(sort(unique(i$age[i$year == 2024])), 1:20),
  i$value[i$year == 2023 & i$age == 2] == 1007,
  i$value[i$year == 2023 & i$age == 14] == 1,
  i$value[i$year == 2024 & i$age == 3] == 7812,
  i$value[i$year == 2024 & i$age == 14] == 1733,
  all(grepl("2026/047, Table", i$source_reference, fixed = TRUE)),
  all(grepl("Canadian and French landings", i$notes, fixed = TRUE)),
  nrow(o) == 21L,
  identical(o$value[o$measure == "SSB" & o$year %in% 2021:2026],
    c(20.7, 20.2, 19.4, 19.3, 22.0, 26.7)),
  identical(o$lwr[o$measure == "SSB" & o$year %in% 2021:2026],
    c(17.5, 17.2, 16.4, 16.3, 17.5, 20.7)),
  identical(o$upr[o$measure == "SSB" & o$year %in% 2021:2026],
    c(24.5, 23.8, 22.9, 22.9, 27.5, 34.3)),
  identical(o$value[o$measure == "recruitment" & o$year %in% 2021:2025],
    c(17.9, 29.3, 30.0, 30.5, 29.7)),
  all(o$age[o$measure == "recruitment"] == 2),
  identical(o$value[o$measure == "Mbar" & o$year %in% 2021:2025],
    c(0.35, 0.35, 0.35, 0.33, 0.31)),
  o$lwr[o$measure == "Mbar" & o$year == 2025] == 0.31,
  o$upr[o$measure == "Mbar" & o$year == 2025] == 0.32,
  identical(o$value[o$measure == "Fbar" & o$year %in% 2021:2025],
    c(0.02, 0.03, 0.03, 0.02, 0.03)),
  all(o$age_group[o$measure %in% c("Mbar", "Fbar")] == "5-8"),
  all(o$source_type == "official_table"),
  all(grepl("Science Advisory Report 2026/004, Table 1", o$source_reference, fixed = TRUE)),
  grepl("projected", o$notes[o$measure == "SSB" & o$year == 2026], ignore.case = TRUE),
  !any(o$measure %in% c("numbers_at_age", "fishing_mortality_at_age", "natural_mortality_at_age"))
)

cat("3Ps 2025 source inputs, official summary outputs, and separation from the detailed 2024 record passed.\n")