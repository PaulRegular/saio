base <- "database"
read_table <- function(file) data.table::fread(file.path(base, file), na.strings = c("", "NA"), blank.lines.skip = TRUE, data.table = FALSE)
id <- "ices_sole_celtic_south_7hk_2026"
s <- subset(read_table("stocks.csv"), stock_id == "ices_sole_celtic_south_7hk")
a <- subset(read_table("assessments.csv"), assessment_id == id)
z <- subset(read_table("inputs.csv"), assessment_id == id)
o <- subset(read_table("outputs.csv"), assessment_id == id)
stopifnot(nrow(s) == 1L, s$authority_stock_id == "sol.27.7h-k",
  is.na(s$charbonneau_id) || s$charbonneau_id == "", nrow(a) == 1L,
  a$is_current, a$is_applied, a$assessment_year == 2026, a$terminal_year == 2025,
  a$outputs_status == "partial", nrow(o) == 3L, nrow(z) == 97L,
  all(z$unit == "tonnes"), all(z$source_type == "official_machine_readable"))
land <- subset(z, measure == "landings_biomass"); disc <- subset(z, measure == "discard_biomass")
stopifnot(identical(land$year, 1951:2025), identical(disc$year, 2004:2025),
  land$value[land$year == 1995] == 915, land$value[land$year == 1996] == 443,
  land$value[land$year == 2025] == 205, disc$value[disc$year == 2025] == .26,
  identical(o$year, 2027:2029), all(o$type == "catch"),
  all(o$measure == "catch_advice"), all(o$value == 136),
  all(o$unit == "tonnes"), all(o$source_type == "official_document"),
  all(grepl("catches", o$notes, fixed = TRUE)),
  grepl("official reported landings through 1995", land$notes[1], fixed = TRUE),
  !any(z$measure == "numbers_at_age"))
cat("Southern Celtic sole identity, source vintage, units and advice limitations passed.\n")
