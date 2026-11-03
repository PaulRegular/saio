source("scripts/database/156_review_catalogue_stock_relationships.R")
source("R/read_database.R")
db <- read_database()
links <- ck_stock_relationships
reviewed <- ck_review_stock_relationships(db$stocks)
rerun <- ck_review_stock_relationships(reviewed)
children <- match(links$stock_id, reviewed$stock_id)
parents <- match(links$parent_id, reviewed$stock_id)
changed_ids <- c(links$stock_id, unique(links$parent_id))
unchanged <- !db$stocks$stock_id %in% changed_ids

stopifnot(
  nrow(links) == 10L, !anyDuplicated(links$stock_id),
  length(unique(links$parent_id)) == 5L,
  identical(reviewed, rerun),
  identical(reviewed[unchanged, ], db$stocks[unchanged, ]),
  identical(reviewed[setdiff(names(reviewed), c("notes", "common_name"))],
    db$stocks[setdiff(names(db$stocks), c("notes", "common_name"))]),
  identical(reviewed$charbonneau_id[children], links$charbonneau_id),
  identical(reviewed$area[children], links$area),
  identical(reviewed$scientific_name[children], reviewed$scientific_name[parents]),
  identical(reviewed$ocean[children], reviewed$ocean[parents]),
  all(grepl("not an identical assessment run", reviewed$notes[children], fixed = TRUE)),
  all(vapply(seq_len(nrow(links)), function(i) grepl(
    paste0("related current stock_id=", links$parent_id[i]), reviewed$notes[children[i]], fixed = TRUE), logical(1))),
  all(vapply(seq_len(nrow(links)), function(i) grepl(
    links$stock_id[i], reviewed$notes[parents[i]], fixed = TRUE), logical(1))),
  !any(links$stock_id %in% db$assessments$stock_id),
  all(unique(links$parent_id) %in% db$assessments$stock_id[db$assessments$is_current]),
  all(is.na(reviewed$charbonneau_id[parents[1:4]]))
)

for (field in c("charbonneau_id", "area", "scientific_name", "ocean", "authority")) {
  bad <- db$stocks
  bad[children[1], field] <- "unverified identity"
  error <- tryCatch({ ck_review_stock_relationships(bad); FALSE },
    error = function(e) grepl("disagrees with the reviewed source", conditionMessage(e), fixed = TRUE))
  stopifnot(error)
}
conflict <- db$stocks
conflict$notes[children[1]] <- "Reviewed catalogue relationship (earlier review): another stock."
stopifnot(tryCatch({ ck_review_stock_relationships(conflict); FALSE },
  error = function(e) grepl("Conflicting previous relationship", conditionMessage(e), fixed = TRUE)))

# Sex-specific official states remain under their own current assessment IDs.
for (stock_id in unique(links$parent_id[5:10])) {
  ids <- db$assessments$assessment_id[db$assessments$stock_id == stock_id & db$assessments$is_current]
  n <- db$outputs[db$outputs$assessment_id %in% ids & db$outputs$measure == "numbers_at_age", ]
  stopifnot(all(c("female", "male") %in% n$sex))
}

# Check the importer on copies; it must leave all four assessment tables untouched.
source_dir <- "source_cache"
if (file.exists(file.path(source_dir, "ices_herring_gulf_bothnia_2026/WGBFAS_2026_report.pdf"))) {
  local({
    tmp <- tempfile("catalogue-relationships-")
    dir.create(tmp)
    on.exit(unlink(tmp, recursive = TRUE))
    files <- c("stocks.csv", "assessments.csv", "assumptions.csv", "inputs.csv", "outputs.csv")
    stopifnot(all(file.copy(file.path("database", files), tmp)))
    before <- tools::md5sum(file.path(tmp, files[-1]))
    ck_import_stock_relationships(tmp, source_dir)
    first <- readBin(file.path(tmp, "stocks.csv"), "raw", n = file.info(file.path(tmp, "stocks.csv"))$size)
    ck_import_stock_relationships(tmp, source_dir)
    second <- readBin(file.path(tmp, "stocks.csv"), "raw", n = file.info(file.path(tmp, "stocks.csv"))$size)
    stopifnot(identical(first, second), identical(before, tools::md5sum(file.path(tmp, files[-1]))))
    updated <- read.csv(file.path(tmp, "stocks.csv"), na.strings = "", check.names = FALSE)
    stopifnot(identical(updated, reviewed))
  })
}
cat("Catalogue historical/sex relationships, identity safeguards, source pins and assessment-data preservation passed.\n")
