pacific_database_row <- function(table, ..., n = NULL) {
  header <- readLines(file.path(
    "database", paste0(table, ".csv")
  ), n = 1L)
  columns <- names(utils::read.csv(text = header, nrows = 0L, check.names = FALSE))
  values <- list(...)
  if (is.null(n)) n <- max(lengths(values))
  out <- as.data.frame(setNames(rep(list(rep(NA, n)), length(columns)), columns))
  for (name in names(values)) {
    if (!name %in% columns) cli::cli_abort("Unknown {table} column: {name}.")
    out[[name]] <- rep_len(values[[name]], n)
  }
  out
}

append_pacific_case <- function(stocks, assessments, assumptions, inputs, outputs) {
  additions <- list(stocks = stocks, assessments = assessments,
                    assumptions = assumptions, inputs = inputs, outputs = outputs)
  root <- "database"
  ids <- utils::read.csv(file.path(root, "assessments.csv"))$assessment_id
  if (any(assessments$assessment_id %in% ids)) {
    cli::cli_abort("The assessment already exists; do not append it twice.")
  }
  if (any(!is.finite(inputs$value)) || any(!is.finite(outputs$value))) {
    cli::cli_abort("Source additions contain non-finite numerical values.")
  }
  for (name in names(additions)) {
    utils::write.table(additions[[name]], file.path(root, paste0(name, ".csv")),
      sep = ",", row.names = FALSE, col.names = FALSE, append = TRUE, na = "")
  }
}

pacific_matrix_long <- function(x) {
  data.frame(year = rep(as.integer(rownames(x)), times = ncol(x)),
             age = rep(as.integer(colnames(x)), each = nrow(x)),
             value = as.vector(x))
}
