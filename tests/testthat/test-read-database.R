test_that("catalogue searches retain UTF-8 text and leading zeroes in IDs", {
  fixture <- release_fixture()
  expect_identical(list_stocks(database_dir = fixture$assets)$stock_id,
    c("001", "002", "003"))
  expect_identical(list_stocks("COD", fixture$assets)$stock_id, c("001", "003"))
  expect_identical(list_stocks("qu\u00e9bec", fixture$assets)$stock_id, "003")
  expect_identical(list_assessments("001", fixture$assets)$assessment_id,
    c("001_2025", "001_2024"))
})

test_that("compressed queries retain values, types, and release provenance", {
  fixture <- release_fixture(chunked = TRUE)
  tmp_before <- list.files(tempdir(), all.files = TRUE)
  full <- read_database(fixture$assets)
  stock <- read_database(fixture$assets, stock_id = "001")
  selected <- read_database(fixture$assets, assessment_id = "001_2025")

  expect_identical(stock$assessments$assessment_id, c("001_2025", "001_2024"))
  expect_identical(selected$assessments$assessment_id, "001_2025")
  expect_identical(selected$stocks$stock_id, "001")
  expect_identical(selected$inputs$age, 2.5)
  expect_identical(selected$inputs$year, 2025L)
  expect_identical(selected$assumptions$value, "0.2")
  expect_identical(selected$assumptions$notes, fixture$data$assumptions$notes[1L])
  expect_identical(selected$database_release, fixture$tag)
  expect_identical(selected$database_source, "release")
  expect_identical(selected$commit, NA_character_)

  plain <- read_database(fixture$plain, stock_id = "001")
  expect_identical(plain$database_source, "working_tree")
  expect_false("database_release" %in% names(plain))
  for (table in c("assumptions", "inputs", "outputs")) {
    rows <- full[[table]][full[[table]]$assessment_id %in% c("001_2025", "001_2024"),
      , drop = FALSE]
    rownames(rows) <- NULL
    expect_identical(stock[[table]], rows)
    expect_identical(plain[[table]], rows)
  }

  expect_identical(list.files(tempdir(), all.files = TRUE), tmp_before)
  expect_setequal(list.files(fixture$assets), c("manifest.csv", fixture$manifest$asset))
})

test_that("catalogue browsing and selected tables only need relevant files", {
  fixture <- release_fixture()
  result <- read_database(fixture$assets, stock_id = "001", tables = "outputs")
  expect_identical(names(result), c("outputs", "database_source", "commit",
    "database_release"))

  catalogue_only <- read_database(fixture$assets, stock_id = "003")
  expect_equal(nrow(catalogue_only$assessments), 0L)
  expect_equal(nrow(catalogue_only$inputs), 0L)
  expect_identical(catalogue_only$inputs$age, numeric())

  inputs <- file.path(fixture$assets, "inputs.csv.gz")
  expect_true(file.rename(inputs, paste0(inputs, ".saved")))
  expect_equal(nrow(list_stocks(database_dir = fixture$assets)), 3L)
  expect_equal(nrow(list_assessments(database_dir = fixture$assets)), 3L)
  expect_equal(nrow(read_database(fixture$assets, assessment_id = "001_2025",
    tables = "outputs")$outputs), 1L)
  expect_error(read_database(fixture$assets, assessment_id = "001_2025"),
    "inputs.csv.gz", fixed = TRUE)
})

test_that("queries report invalid IDs and choices clearly", {
  fixture <- release_fixture()
  expect_error(read_database(fixture$assets, stock_id = "004"),
    "list_stocks()", fixed = TRUE)
  expect_error(read_database(fixture$assets, assessment_id = "004_2025"),
    "list_assessments()", fixed = TRUE)
  expect_error(read_database(fixture$assets, stock_id = "001", assessment_id = "001_2025"),
    "either stock_id or assessment_id")
  expect_error(read_database(fixture$assets, tables = "unknown"),
    "Choose from these SAIO tables")
})
