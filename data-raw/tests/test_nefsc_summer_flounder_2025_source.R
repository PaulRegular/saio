db <- "database"
read_db <- function(file) data.table::fread(file.path(db, file), na.strings = c("", "NA"), blank.lines.skip = TRUE, data.table = FALSE)
id <- "nefsc_summer_flounder_2025"
a <- subset(read_db("assessments.csv"), assessment_id == id)
i <- subset(read_db("inputs.csv"), assessment_id == id)
o <- subset(read_db("outputs.csv"), assessment_id == id)
stopifnot(nrow(a) == 1, a$is_applied, !a$is_current, a$terminal_year == 2024,
  nrow(i) == 87, nrow(o) == 129,
  sum(i$fleet == "All removals") == 43,
  all(table(o$measure) == 43),
  all(sort(unique(o$year)) == 1982:2024),
  o$value[o$measure == "SSB" & o$year == 2024] == 40516,
  o$value[o$measure == "Ffull" & o$year == 2024] == .35,
  o$value[o$measure == "recruitment" & o$year == 2024] == 49649,
  all(o$age[o$measure == "recruitment"] == 0),
  all(i$unit == "tonnes"), all(is.na(o$se)), all(is.na(o$lwr)), all(is.na(o$upr)))
cat("2025 summer flounder source coverage and units passed.\n")
