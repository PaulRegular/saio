.saio_tables <- c("stocks", "assessments", "assumptions", "inputs", "outputs")
.assessment_database_files <- paste0(.saio_tables, ".csv")

.assessment_database <- function(read_table, source, commit = NA_character_) {
  tables <- lapply(.assessment_database_files, read_table)
  names(tables) <- c("stocks", "assessments", "assumptions", "inputs", "outputs")
  tables$database_source <- source
  tables$commit <- commit
  tables
}

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

list_assessments <- function(stock_id = NULL, database_dir = NULL) {
  read_database(database_dir, stock_id = stock_id, tables = "assessments")$assessments
}

read_committed_database <- function() {
  repo <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
  git <- function(args, stdout = TRUE) {
    system2("git", c("-c", paste0("safe.directory=", repo), args),
      stdout = stdout, stderr = TRUE
    )
  }
  commit <- git(c("rev-parse", "--verify", "HEAD^{commit}"))
  if (!is.null(attr(commit, "status"))) {
    stop("Could not resolve the committed database revision.", call. = FALSE)
  }
  commit <- commit[[1]]

  .assessment_database(
    function(name) {
      path <- file.path("database", name)
      tempfile_path <- tempfile(
        pattern = "saio_committed_database_",
        fileext = ".csv"
      )
      on.exit(unlink(tempfile_path), add = TRUE)
      status <- git(c("show", paste0(commit, ":", path)), stdout = tempfile_path)
      exit_status <- if (is.numeric(status) && length(status) == 1L) {
        status
      } else {
        attr(status, "status")
      }
      if (!is.null(exit_status) && exit_status != 0L ||
        !file.exists(tempfile_path) || file.info(tempfile_path)$size == 0) {
        stop("Could not read committed database table: ", name, call. = FALSE)
      }
      read_path <- tempfile_path
      first_line <- readLines(tempfile_path, n = 1L, warn = FALSE)
      if (length(first_line) && grepl(
        "^version https://git-lfs.github.com/spec/v1$", first_line
      )) {
        hydrated_path <- tempfile(
          pattern = "saio_committed_database_lfs_",
          fileext = ".csv"
        )
        on.exit(unlink(hydrated_path), add = TRUE)
        hydrated <- system2(
          "git",
          c("-c", paste0("safe.directory=", repo), "lfs", "smudge", "--", path),
          stdin = tempfile_path, stdout = hydrated_path, stderr = TRUE
        )
        hydrated_status <- if (is.numeric(hydrated) && length(hydrated) == 1L) {
          hydrated
        } else {
          attr(hydrated, "status")
        }
        hydrated_first_line <- if (file.exists(hydrated_path)) {
          readLines(hydrated_path, n = 1L, warn = FALSE)
        } else {
          character()
        }
        if ((!is.null(hydrated_status) && hydrated_status != 0L) ||
          !length(hydrated_first_line) || grepl(
            "^version https://git-lfs.github.com/spec/v1$",
            hydrated_first_line
          )) {
          stop("Could not hydrate committed Git LFS table: ", name, call. = FALSE)
        }
        read_path <- hydrated_path
      }
      read.csv(read_path,
        stringsAsFactors = FALSE,
        na.strings = c("", "NA"), check.names = FALSE
      )
    },
    source = "committed",
    commit = commit
  )
}

read_assessment <- function(assessment_id, database = NULL) {
  if (length(assessment_id) != 1L || is.na(assessment_id) ||
    !nzchar(assessment_id)) {
    stop("assessment_id must be one non-empty value.", call. = FALSE)
  }
  if (is.null(database)) database <- read_database()
  required <- c("stocks", "assessments", "assumptions", "inputs", "outputs")
  if (!all(required %in% names(database))) {
    stop("database must contain stocks, assessments, assumptions, inputs, and outputs tables.",
      call. = FALSE
    )
  }
  assessment <- database$assessments[
    !is.na(database$assessments$assessment_id) &
      database$assessments$assessment_id == assessment_id, ,
    drop = FALSE
  ]
  if (nrow(assessment) != 1L) {
    stop("Database must contain exactly one assessment_id: ", assessment_id,
      call. = FALSE
    )
  }
  tables <- database
  stock_id <- assessment$stock_id[[1]]
  tables$stocks <- tables$stocks[
    tables$stocks$stock_id == stock_id, ,
    drop = FALSE
  ]
  for (table in c("assumptions", "inputs", "outputs")) {
    rows <- tables[[table]]$assessment_id == assessment_id
    rows[is.na(rows)] <- FALSE
    tables[[table]] <- tables[[table]][rows, , drop = FALSE]
  }
  tables$assessment <- assessment
  tables
}

read_committed_assessment <- function(assessment_id, database = NULL) {
  if (is.null(database)) database <- read_committed_database()
  read_assessment(assessment_id, database)
}
