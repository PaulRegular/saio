# Curation commands run from the SAIO checkout root.
source("R/download_database.R", local = TRUE)
source("R/stream_tables.R", local = TRUE)
source("R/read_database.R", local = TRUE)

.assessment_database <- function(read_table, source, commit = NA_character_) {
  tables <- lapply(.assessment_database_files, read_table)
  names(tables) <- c("stocks", "assessments", "assumptions", "inputs", "outputs")
  tables$database_source <- source
  tables$commit <- commit
  tables
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
