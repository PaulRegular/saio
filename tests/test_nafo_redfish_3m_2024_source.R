root <- "."
read_selected <- function(path, columns) {
  fields <- names(read.csv(path, nrows = 0L, check.names = FALSE))
  classes <- rep("NULL", length(fields)); names(classes) <- fields
  classes[columns] <- "character"
  read.csv(path, stringsAsFactors = FALSE, check.names = FALSE,
    na.strings = c("", "NA"), colClasses = classes)
}
read_small <- function(path) read.csv(path, stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
stock <- read_small("database/stocks.csv")
assessments <- read_small("database/assessments.csv")
assumptions <- read_selected("database/assumptions.csv", c("assessment_id", "component", "setting", "value", "source_reference", "notes"))
inputs <- read_selected("database/inputs.csv", c("assessment_id", "type", "measure", "basis", "year", "age", "value", "unit", "source_type", "source_reference", "notes"))
outputs <- read_selected("database/outputs.csv", c("assessment_id", "type", "measure", "year", "value", "lwr", "upr", "unit", "source_type", "source_reference", "notes", "scenario"))
candidates <- read_small("discovery/candidates.csv")
id <- "nafo_redfish_3m_2024"
stock_id <- "nafo_redfish_3m"

s <- stock[stock$stock_id == stock_id, , drop = FALSE]
a <- assessments[assessments$assessment_id == id, , drop = FALSE]
i <- inputs[inputs$assessment_id == id, , drop = FALSE]
o <- outputs[outputs$assessment_id == id, , drop = FALSE]
as <- assumptions[assumptions$assessment_id == id, , drop = FALSE]
c <- candidates[candidates$candidate_id == "NAFO:redfish.3M", , drop = FALSE]

stopifnot(nrow(s) == 1L, s$authority == "NAFO", s$authority_stock_id == "redfish.3M",
  s$scientific_name == "Sebastes mentella; Sebastes fasciatus",
  s$ocean == "Northwest Atlantic", nrow(a) == 1L,
  a$assessment_year == 2024L, a$terminal_year == 2023L,
  a$estimate_terminal_year == 2027L, a$model_family == "XSA",
  is.na(a$framework_url),
  a$is_current, a$is_applied, a$inputs_status == "partial",
  a$assumptions_status == "partial", a$outputs_status == "partial",
  nrow(i) == 9L, all(i$type == "catch" & i$measure == "total_biomass"),
  identical(as.integer(i$year), 2015:2023),
  identical(as.numeric(i$value), c(5.2, 6.2, 6.9, 10.3, 10.2, 8.7, 8.3, 9.4, 9.4)),
  all(i$unit == "1000 tonnes"), all(i$source_type == "official_table"),
  nrow(as) == 18L, any(as$setting == "natural_mortality_history"),
  any(as$setting == "age_length_key_2023" & grepl("2020–2022", as$value, fixed = TRUE)),
  any(as$setting == "maturity_ogive_2023" & grepl("2020–2022", as$value, fixed = TRUE)),
  any(as$setting == "scenario_outputs_recorded" & as$value == "All seven scenarios"),
  any(as$setting == "species_definition" & grepl("Sebastes fasciatus", as$value, fixed = TRUE)),
  nrow(o) == 46L, sum(o$type == "biomass" & o$measure == "SSB") == 16L,
  sum(o$type == "catch" & o$measure == "yield") == 15L,
  sum(o$type == "catch" & o$measure == "catch_advice") == 15L,
  all(o$source_type == "official_table"),
  all(is.na(o$scenario[o$year == "2024"])),
  all(is.na(o$scenario[o$type == "biomass" & o$measure == "SSB" & o$year == "2025"])),
  identical(sort(unique(o$scenario[!is.na(o$scenario)])),
    sort(c("F=0", "F0.1=0.0675", "F=M=0.1", "Fstatusquo=0.0585",
      "1.25 TAC", "TAC", "0.75 TAC"))),
  all(table(o$scenario[!is.na(o$scenario)]) == 6L),
  all(o$lwr[o$measure == "SSB" & !is.na(o$lwr)] <= o$upr[o$measure == "SSB" & !is.na(o$upr)]),
  o$value[o$measure == "SSB" & as.integer(o$year) == 2026L & o$scenario == "Fstatusquo=0.0585"] == 45409,
  o$lwr[o$measure == "SSB" & as.integer(o$year) == 2026L & o$scenario == "Fstatusquo=0.0585"] == 40641,
  o$upr[o$measure == "SSB" & as.integer(o$year) == 2026L & o$scenario == "Fstatusquo=0.0585"] == 52891,
  o$value[o$measure == "catch_advice" & as.integer(o$year) == 2024L] == 17503,
  grepl("all three redfish species", o$notes[o$measure == "catch_advice" & as.integer(o$year) == 2024L], fixed = TRUE),
  nrow(c) == 1L, c$matched_stock_id == stock_id, c$match_status == "matched",
  c$import_status == "partial", c$inventory_assessment_year == 2024L)
stopifnot(grepl("SCR 24/024 confirms the selected 2020–2022", c$notes, fixed = TRUE))

manifest <- read_small("provenance/nafo_redfish_3m_2024/manifest.csv")
review <- paste(readLines("source_reviews/nafo_redfish_3m_2024.md"), collapse = "\n")
stopifnot(nrow(manifest) == 9L, all(nchar(manifest$sha256) == 64L),
  any(manifest$cached_file == "nafo_scr26_010_blim_reference_point.pdf"),
  any(manifest$source_url == "https://www.nafo.int/Portals/0/PDFs/sc/2026/scr26-010.pdf"),
  any(grepl("scr24-032.pdf", review, fixed = TRUE)),
  grepl("selected a species-combined age-length key and maturity ogive pooled from 2020–2022", review, fixed = TRUE),
  grepl("26/027", review, fixed = TRUE), grepl("returned 404", review, fixed = TRUE),
  grepl("1988–2017", review, fixed = TRUE), grepl("1990–2007 and 2009–2018", review, fixed = TRUE),
  grepl("not a new production XSA", review, fixed = TRUE))




