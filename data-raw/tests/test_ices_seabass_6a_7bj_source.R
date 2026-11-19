base <- "database"
read_table <- function(file) data.table::fread(file.path(base, file), na.strings = c("", "NA"), blank.lines.skip = TRUE, data.table = FALSE)
id <- "ices_seabass_6a_7bj_2026"
stock <- subset(read_table("stocks.csv"), stock_id == "ck_ices_wgsce_labrax_is6a_7b_7j")
a <- subset(read_table("assessments.csv"), assessment_id == id)
z <- subset(read_table("inputs.csv"), assessment_id == id)
o <- subset(read_table("outputs.csv"), assessment_id == id)
assumptions <- subset(read_table("assumptions.csv"), assessment_id == id)
stopifnot(nrow(stock) == 1L, stock$authority_stock_id == "bss.27.6a7bj",
  nrow(a) == 1L, a$assessment_year == 2026, a$terminal_year == 2025,
  a$is_current, a$is_applied, a$outputs_status == "partial",
  nrow(z) == 29L, identical(z$year, c(1996L, 1997L, 1999L, 2000:2025)),
  all(z$type == "catch"), all(z$measure == "landings_biomass"),
  all(z$unit == "tonnes"), all(z$source_type[z$year >= 2000] == "official_machine_readable"),
  all(z$value[z$year < 2000] == 0), all(z$source_type[z$year < 2000] == "official_table"),
  all(grepl("rounded", z$notes[z$year < 2000], fixed = TRUE)),
  z$value[z$year == 2023] == 5.297, z$value[z$year == 2024] == 6.5,
  z$value[z$year == 2025] == 2.37,
  identical(o$year, 2027:2029), all(o$type == "catch"),
  all(o$measure == "catch_advice"), all(o$value == 1.6),
  all(o$unit == "tonnes"), all(o$source_type == "official_document"),
  all(grepl("commercial landings", o$notes, fixed = TRUE)),
  any(assumptions$setting == "advice_rule" & grepl("0.8", assumptions$value, fixed = TRUE)),
  any(assumptions$setting == "available_data" & grepl("no survey index", assumptions$value, fixed = TRUE)))
cat("Seabass source identity, landings, advice and output limitations passed.\n")
