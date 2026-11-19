root <- "."
inputs <- read.csv(file.path(root, "database", "inputs.csv"), stringsAsFactors = FALSE)
outputs <- read.csv(file.path(root, "database", "outputs.csv"), stringsAsFactors = FALSE)
assumptions <- read.csv(file.path(root, "database", "assumptions.csv"), stringsAsFactors = FALSE)
assessments <- read.csv(file.path(root, "database", "assessments.csv"), stringsAsFactors = FALSE)

id <- "nefsc_atlantic_mackerel_2025"
i <- inputs[inputs$assessment_id == id, ]
o <- outputs[outputs$assessment_id == id, ]
a <- assumptions[assumptions$assessment_id == id, ]
record <- assessments[assessments$assessment_id == id, ]
catch <- i[i$type == "catch" & i$measure == "total_biomass", ]
projected_catch <- o[o$measure == "predicted_catch", ]
projected_ssb <- o[o$measure == "SSB" & o$year >= 2025, ]
projected_f <- o[o$measure == "Fbar" & o$year >= 2025, ]

stopifnot(
  nrow(record) == 1L, record$inputs_status == "partial",
  record$outputs_status == "partial", record$assumptions_status == "partial",
  nrow(catch) == 10L, identical(catch$year, 2015:2024),
  identical(catch$value, c(14176, 18319, 20971, 22195, 16445, 18188, 12538, 3557, 5699, 3610)),
  all(catch$basis == "biomass"), all(catch$unit == "metric tons"),
  all(grepl("not age-specific", catch$notes, fixed = TRUE)),
  nrow(projected_catch) == 4L, identical(projected_catch$year, 2025:2028),
  identical(projected_catch$value, c(3625, 50376, 50029, 48760)),
  nrow(projected_ssb) == 4L, identical(projected_ssb$value, c(240626, 286004, 278154, 268913)),
  identical(projected_ssb$lwr, c(120779, 149527, 150198, 149049)),
  identical(projected_ssb$upr, c(464698, 542599, 516437, 490049)),
  nrow(projected_f) == 4L, identical(projected_f$value, c(.019, .2, .2, .2)),
  o$value[o$measure == "Fmsy"] == .2,
  o$value[o$measure == "Bmsy"] == 169139,
  o$lwr[o$measure == "Bmsy"] == 91371,
  o$upr[o$measure == "Bmsy"] == 352116,
  o$value[o$measure == "msy"] == 31216,
  o$value[o$measure == "median_recruitment"] == 176521,
  o$age[o$measure == "median_recruitment"] == 1,
  nrow(a) == 6L,
  any(grepl("does not state the 2025 run's numerical value", a$value, fixed = TRUE))
)

cat("Atlantic mackerel 2025 aggregate inputs, reference points, projections, and unresolved model details passed.\n")
