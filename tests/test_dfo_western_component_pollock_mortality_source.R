root <- "."
read_table <- function(name) {
  utils::read.csv(file.path(root, "database", paste0(name, ".csv")),
    stringsAsFactors = FALSE, check.names = FALSE)
}
read_assessment_inputs <- function(path, id) {
  header <- readLines(path, n = 1L, warn = FALSE)
  con <- file(path, open = "r")
  on.exit(close(con))
  readLines(con, n = 1L, warn = FALSE)
  selected <- character()
  repeat {
    chunk <- readLines(con, n = 50000L, warn = FALSE)
    if (!length(chunk)) break
    selected <- c(selected, chunk[startsWith(chunk, paste0("\"", id, "\","))])
  }
  if (!length(selected)) return(utils::read.csv(text = header, check.names = FALSE))
  utils::read.csv(text = paste(c(header, selected), collapse = "\n"),
    stringsAsFactors = FALSE, check.names = FALSE,
    na.strings = c("", "NA"))
}

assessment_id <- "dfo_western_component_pollock_2022_j_m4b"
inputs <- read_assessment_inputs(file.path(root, "database", "inputs.csv"), assessment_id)
m <- subset(inputs, type == "M" & measure == "natural_mortality_at_age")
assessments <- read_table("assessments")
assessment <- assessments[assessments$assessment_id == assessment_id, , drop = FALSE]
candidate <- utils::read.csv(file.path(root, "discovery", "candidates.csv"),
  stringsAsFactors = FALSE, check.names = FALSE)
candidate <- candidate[candidate$candidate_id ==
  "DFO:Maritimes:Pollock - NAFO 4X5 (Western Component)", , drop = FALSE]
review <- paste(readLines(file.path(root, "discovery", "source_reviews",
  "dfo_western_component_pollock_2022.md")), collapse = " ")

stopifnot(
  nrow(assessment) == 1L,
  assessment$inputs_status == "partial",
  nrow(m) == 468L,
  !anyDuplicated(m[c("year", "age")]),
  identical(sort(unique(m$year)), 1982:2020),
  identical(sort(unique(m$age)), 2:13),
  all(m$basis == "per_year", m$unit == "per year",
    m$source_type == "official_table", m$value > 0,
    grepl("Table 12, printed p. 44", m$source_reference, fixed = TRUE)),
  all(m$value[m$year < 1994] == 0.2),
  all(m$value[m$age <= 4] == 0.2),
  all(m$value[m$year >= 1994 & m$year <= 2000 & m$age >= 5] == 0.661),
  all(m$value[m$year >= 2001 & m$year <= 2010 & m$age >= 5] == 0.587),
  all(m$value[m$year >= 2011 & m$year <= 2020 & m$age >= 5] == 0.341),
  grepl("relative error=0.184", m$notes[m$year == 1994 & m$age == 5], fixed = TRUE),
  grepl("relative bias=-0.013", m$notes[m$year == 1994 & m$age == 5], fixed = TRUE),
  grepl("Model J_M4B", assessment$notes, fixed = TRUE),
  grepl("38,061 mt", assessment$notes, fixed = TRUE),
  grepl("38,408 mt", assessment$notes, fixed = TRUE),
  nrow(candidate) == 1L,
  candidate$import_status == "partial",
  grepl("0.661", candidate$mortality_evidence, fixed = TRUE),
  grepl("same M matrix", candidate$mortality_evidence, fixed = TRUE),
  grepl("38,061 mt", review, fixed = TRUE),
  grepl("38,408 mt", review, fixed = TRUE),
  grepl("same M matrix", review, fixed = TRUE)
)

cat("DFO Western Component Pollock mortality-input checks passed.\n")