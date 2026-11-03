root <- "."
read_csv <- function(path) utils::read.csv(path, stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)

selected <- read_csv(file.path(root, "discovery", "selected_batch_01_2026.csv"))
candidates <- read_csv(file.path(root, "discovery", "candidates.csv"))
inventory <- read_csv(file.path(root, "discovery", "inventory_units.csv"))
stocks <- read_csv(file.path(root, "database", "stocks.csv"))
assessments <- read_csv(file.path(root, "database", "assessments.csv"))

candidate_counts <- vapply(selected$candidate_unit_id, function(id)
  sum(candidates$candidate_unit_id == id, na.rm = TRUE), integer(1))
inventory_counts <- vapply(selected$candidate_unit_id, function(id)
  sum(inventory$candidate_unit_id == id, na.rm = TRUE), integer(1))
candidate <- candidates[match(selected$candidate_unit_id,
  candidates$candidate_unit_id), , drop = FALSE]
unit <- inventory[match(selected$candidate_unit_id,
  inventory$candidate_unit_id), , drop = FALSE]
stock <- stocks[match(candidate$matched_stock_id, stocks$stock_id), , drop = FALSE]

stopifnot(
  nrow(selected) == 20L,
  !anyDuplicated(selected$candidate_unit_id),
  all(candidate_counts == 1L),
  all(inventory_counts == 1L),
  !anyDuplicated(candidate$matched_stock_id),
  !anyNA(candidate$matched_stock_id),
  !anyNA(unit$matched_stock_id),
  !anyDuplicated(unit$matched_stock_id),
  identical(candidate$matched_stock_id, unit$matched_stock_id),
  all(candidate$eligibility == "eligible"),
  all(unit$eligibility == "eligible"),
  all(stock$stock_id == candidate$matched_stock_id),
  all(stock$scientific_name == candidate$scientific_name),
  all(candidate$matched_stock_id %in% assessments$stock_id)
)

cat("Selected batch has 20 unique, eligible units linked one-to-one to distinct canonical stocks and assessments.\n")
