.saio_tables <- c("stocks", "assessments", "assumptions", "inputs", "outputs")
.assessment_database_files <- paste0(.saio_tables, ".csv")

.database_head <- function() {
  repo <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
  commit <- suppressWarnings(tryCatch(
    system2("git", c(
      "-c", paste0("safe.directory=", repo),
      "rev-parse", "--verify", "HEAD^{commit}"
    ),
    stdout = TRUE, stderr = TRUE
    ),
    error = function(e) character()
  ))
  if (!length(commit) || !grepl("^[[:xdigit:]]{40}$", commit[[1]])) {
    return(NA_character_)
  }
  commit[[1]]
}

.saio_database_location <- function(database_dir) {
  if (is.null(database_dir)) {
    # Keep the default used by curation scripts run from an SAIO checkout.
    working <- file.exists("DATABASE_STRUCTURE.md") &&
      file.exists("database/candidates.csv") &&
      any(file.exists(file.path("database", .assessment_database_files)))
    return(if (working) "database" else .saio_user_data_dir())
  }
  .saio_argument(database_dir, "database_dir")
  path.expand(database_dir)
}

.saio_argument <- function(value, name) {
  if (!is.character(value) || length(value) != 1L ||
      is.na(value) || !nzchar(value)) {
    stop(name, " must be one non-empty string.", call. = FALSE)
  }
}

.saio_local_tables <- function(directory) {
  compressed <- any(file.exists(file.path(directory, paste0(.assessment_database_files, ".gz")))) ||
    file.exists(file.path(directory, "manifest.csv"))
  plain <- any(file.exists(file.path(directory, .assessment_database_files)))
  if (compressed && plain) {
    stop("Choose a folder containing either the compressed release or the plain CSV tables: ",
      directory, call. = FALSE)
  }
  if (!compressed && !plain) {
    stop("No SAIO tables found in ", directory,
      ". Run download_database() or set database_dir to your data folder.",
      call. = FALSE)
  }

  if (plain) {
    read <- function(table, ids = NULL, id_column = NULL) {
      path <- file.path(directory, paste0(table, ".csv"))
      if (!file.exists(path)) {
        stop("Database table does not exist: ", path, call. = FALSE)
      }
      if (!is.null(ids)) return(.saio_read_table(path, table, ids, id_column))
      read.csv(path, stringsAsFactors = FALSE, na.strings = c("", "NA"),
        check.names = FALSE)
    }
    return(list(read = read, release = NULL))
  }

  manifest <- .saio_release_manifest(directory)
  read <- function(table, ids = NULL, id_column = NULL) {
    row <- match(table, manifest$table)
    path <- file.path(directory, manifest$asset[row])
    .saio_verify_asset(path, manifest$asset_bytes[row], manifest$asset_sha256[row])
    .saio_read_table(path, table, ids, id_column)
  }
  list(read = read, release = manifest$release[[1L]])
}

#' Read stock assessment data from SAIO
#'
#' Read the local SAIO tables for one stock, one assessment run, or the
#' whole database. Use either `stock_id` or `assessment_id`. Omit both to
#' read all rows of the requested tables.
#'
#' @param database_dir Folder containing the local tables. Omit it to use
#'   the default download location. When running from the root of an SAIO
#'   curation checkout, local plain CSV working tables take precedence
#'   when present.
#' @param stock_id One exact stock identifier. Selects all available
#'   assessment runs for the stock. Find stock IDs with [list_stocks()].
#' @param assessment_id One exact assessment identifier. Selects a single
#'   assessment run and its stock. Find assessment IDs with
#'   [list_assessments()].
#' @param tables Names of the tables to return. For example, use
#'   `c("inputs", "outputs")` to request those two tables.
#'
#' @details
#' The function reads compressed tables directly from disk. A stock or
#' assessment query keeps only the matching records in memory, though
#' scanning a large table takes time. Reading the complete input and
#' output tables can use substantial memory. Use [download_database()]
#' to obtain a data release before reading it locally.
#'
#' @returns A named list with a data frame for each requested table, plus
#'   `database_source` and `commit` provenance fields. For a compressed data
#'   release, the list also includes `database_release`, the release tag to
#'   record with your analysis. The `commit` field is `NA` for a compressed
#'   data release.
#' @seealso [download_database()], [list_stocks()], [list_assessments()]
#' @rdname saio-read
#' @export
read_database <- function(database_dir = NULL, stock_id = NULL,
                          assessment_id = NULL, tables = c("stocks", "assessments",
                            "assumptions", "inputs", "outputs")) {
  if (!is.null(stock_id)) .saio_argument(stock_id, "stock_id")
  if (!is.null(assessment_id)) .saio_argument(assessment_id, "assessment_id")
  if (!is.null(stock_id) && !is.null(assessment_id)) {
    stop("Supply either stock_id or assessment_id.", call. = FALSE)
  }
  if (!is.character(tables) || !length(tables) || anyDuplicated(tables) ||
      !all(tables %in% .saio_tables)) {
    stop("Choose from these SAIO tables: ", paste(.saio_tables, collapse = ", "),
      ".", call. = FALSE)
  }

  local <- .saio_local_tables(.saio_database_location(database_dir))
  stocks <- assessments <- assessment_ids <- NULL
  if (!is.null(assessment_id)) {
    assessments <- local$read("assessments", assessment_id, "assessment_id")
    if (nrow(assessments) != 1L) {
      stop("Could not find one assessment with ID '", assessment_id,
        "'. Use list_assessments() to find available IDs.", call. = FALSE)
    }
    stock_id <- assessments$stock_id[[1L]]
    assessment_ids <- assessment_id
  }
  if (!is.null(stock_id)) {
    stocks <- local$read("stocks", stock_id, "stock_id")
    if (nrow(stocks) != 1L) {
      stop("Could not find one stock with ID '", stock_id,
        "'. Use list_stocks() to find available IDs.", call. = FALSE)
    }
    if (is.null(assessment_id) && any(tables != "stocks")) {
      assessments <- local$read("assessments", stock_id, "stock_id")
      assessment_ids <- assessments$assessment_id
    }
  }

  result <- lapply(tables, function(table) {
    if (table == "stocks" && !is.null(stocks)) return(stocks)
    if (table == "assessments" && !is.null(assessments)) return(assessments)
    local$read(table, assessment_ids, if (!is.null(assessment_ids)) "assessment_id")
  })
  names(result) <- tables
  if (is.null(local$release)) {
    result$database_source <- "working_tree"
    result$commit <- .database_head()
  } else {
    result$database_source <- "release"
    result$commit <- NA_character_
    result$database_release <- local$release
  }
  result
}

#' Find stocks and assessment runs
#'
#' Search the stock catalogue and find the assessment runs associated with
#' each stock. These functions use the small local catalogue tables.
#'
#' @param search Text to look for in stock names or identifiers. The
#'   search ignores case. Omit it to list all stocks.
#' @param database_dir Folder containing the local tables. Omit it to use
#'   the default location, or pass the path returned by
#'   [download_database()] if you chose a custom folder.
#'
#' @details
#' Check the stock area and assessment year before selecting an assessment.
#' The assessment table includes source links and shows which inputs,
#' assumptions and outputs are available.
#'
#' @returns A data frame with one row per matching stock or assessment run.
#'   Use its `stock_id` or `assessment_id` with [read_database()].
#' @seealso [download_database()], [read_database()]
#' @rdname saio-catalogue
#' @export
list_stocks <- function(search = NULL, database_dir = NULL) {
  if (!is.null(search)) .saio_argument(search, "search")
  stocks <- read_database(database_dir, tables = "stocks")$stocks
  if (is.null(search)) return(stocks)
  fields <- intersect(c("common_name", "scientific_name", "stock_id",
    "authority_stock_id"), names(stocks))
  matches <- Reduce(`|`, lapply(stocks[fields], function(column) {
    grepl(tolower(search), tolower(column), fixed = TRUE)
  }))
  stocks <- stocks[which(matches), , drop = FALSE]
  rownames(stocks) <- NULL
  stocks
}

#' @param stock_id One exact stock identifier, as shown in the `stock_id`
#'   column of [list_stocks()]. Omit it to list all assessments.
#' @rdname saio-catalogue
#' @export
list_assessments <- function(stock_id = NULL, database_dir = NULL) {
  read_database(database_dir, stock_id = stock_id, tables = "assessments")$assessments
}
