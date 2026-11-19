.saio_table_types <- function(table) {
  switch(table,
    stocks = character(),
    assessments = c(assessment_year = "integer", terminal_year = "integer",
      estimate_terminal_year = "integer", framework_year = "integer",
      is_current = "logical", is_applied = "logical"),
    assumptions = character(),
    inputs = c(year = "integer", age = "numeric", value = "numeric",
      sampling_time = "numeric", length_bin_lower = "numeric",
      length_bin_upper = "numeric", sample_size = "numeric"),
    outputs = c(year = "integer", age = "integer", value = "numeric",
      se = "numeric", lwr = "numeric", upr = "numeric"),
    stop("Unknown SAIO table: ", table, call. = FALSE)
  )
}

.saio_table_frame <- function(columns, types, table) {
  for (column in intersect(names(types), names(columns))) {
    values <- columns[[column]]
    type <- types[[column]]
    parsed <- if (type == "logical") as.logical(values) else
      suppressWarnings(as.numeric(values))
    invalid <- !is.na(values) & is.na(parsed)

    if (type == "integer") {
      integers <- suppressWarnings(as.integer(parsed))
      invalid <- invalid | (!is.na(parsed) & (is.na(integers) | parsed != integers))
      parsed <- integers
    }

    if (any(invalid)) {
      stop("Invalid ", type, " value in ", table, " column '", column,
        "': ", values[which(invalid)[1L]], call. = FALSE)
    }
    columns[[column]] <- parsed
  }
  as.data.frame(columns, optional = TRUE, stringsAsFactors = FALSE)
}

.saio_read_table <- function(path, table, ids = NULL, id_column = NULL) {
  types <- .saio_table_types(table)
  connection <- if (endsWith(path, ".gz")) gzfile(path, "rt") else file(path, "rt")
  on.exit(close(connection))

  header <- scan(connection, what = "", nlines = 1L, sep = ",", quote = '"',
    quiet = TRUE, encoding = "UTF-8")
  if (!length(header) || anyNA(header) || any(!nzchar(header)) ||
      anyDuplicated(header)) {
    stop("Invalid header in SAIO table: ", path, call. = FALSE)
  }
  if (length(ids) && (length(id_column) != 1L || !id_column %in% header)) {
    stop("Cannot filter SAIO table ", table, " without a matching identifier column.",
      call. = FALSE)
  }

  # Scan as text so quoted numeric fields and numeric-looking IDs are preserved.
  prototype <- rep(list(character()), length(header))
  names(prototype) <- header
  if (!is.null(ids) && !length(ids)) {
    return(.saio_table_frame(prototype, types, table))
  }

  chunks <- list()
  repeat {
    columns <- scan(connection, what = prototype, nmax = 50000L, sep = ",",
      quote = '"', na.strings = c("", "NA"), fill = TRUE, multi.line = FALSE,
      quiet = TRUE, encoding = "UTF-8")
    if (!length(columns[[1L]])) break
    if (!is.null(ids)) {
      keep <- columns[[id_column]] %in% ids
      if (!any(keep)) next
      columns <- lapply(columns, `[`, keep)
    }
    chunks[[length(chunks) + 1L]] <- .saio_table_frame(columns, types, table)
  }

  if (!length(chunks)) return(.saio_table_frame(prototype, types, table))
  if (length(chunks) == 1L) return(chunks[[1L]])
  do.call(rbind, chunks)
}
