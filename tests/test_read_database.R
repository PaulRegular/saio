reader <- new.env(parent = globalenv())
sys.source("R/read_database.R", reader)

local({
  original_wd <- getwd()
  fixture <- tempfile("saio_reader_")
  dir.create(file.path(fixture, "database"), recursive = TRUE)
  stopifnot(startsWith(normalizePath(fixture, winslash = "/"),
    paste0(normalizePath(tempdir(), winslash = "/"), "/")))
  on.exit({setwd(original_wd); unlink(fixture, recursive = TRUE)}, add = TRUE)
  tables <- list(
    stocks = data.frame(stock_id = "stock", scientific_name = "Source species"),
    assessments = data.frame(assessment_id = c("first", "second"), stock_id = "stock"),
    assumptions = data.frame(assessment_id = c("first", "second"), value = c("fixed M", "estimated M")),
    inputs = data.frame(assessment_id = c("first", "second"), value = c(10, 20)),
    outputs = data.frame(assessment_id = c("first", "second"), value = c(100, 200))
  )
  for (name in names(tables)) write.csv(tables[[name]],
    file.path(fixture, "database", paste0(name, ".csv")), row.names = FALSE)
  setwd(fixture)
  git <- function(...) {
    result <- system2("git", c(...), stdout = TRUE, stderr = TRUE)
    if (!is.null(attr(result, "status"))) stop(paste(result, collapse = "\n"))
    result
  }
  git("init", "-b", "main")
  git("add", "database")
  git("-c", "user.name=SourceReaderTest", "-c", "user.email=reader@example.invalid",
    "-c", "commit.gpgsign=false", "commit", "-m", "fixture")
  revision <- git("rev-parse", "HEAD")[[1L]]
  working <- reader$read_database()
  first <- reader$read_assessment("first", working)
  stopifnot(identical(working$commit, revision), first$inputs$value == 10,
    first$outputs$value == 100, nrow(first$assumptions) == 1L)
  tables$inputs$value[1L] <- 99
  write.csv(tables$inputs, "database/inputs.csv", row.names = FALSE)
  committed <- reader$read_committed_database()
  stopifnot(committed$inputs$value[1L] == 10,
    reader$read_database()$inputs$value[1L] == 99,
    reader$read_committed_assessment("first", committed)$outputs$value == 100,
    identical(committed$commit, revision))
})

cat("Standalone working-tree and committed source readers passed.\n")
