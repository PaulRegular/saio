# Source documentation can describe official model methods and diagnostics.
# Secondary recipes and their artifacts belong to the consuming analysis.
reviews <- unlist(lapply(c('source_reviews', 'discovery/source_reviews'),
  list.files, pattern = '[.]md$', full.names = TRUE))
stopifnot(length(reviews) > 0L)
secondary <- 'scripts/translation/|results/cache/|^#{1,6} .*([Tt]ranslation|[Ss]econdary fit|[Mm]odel agreement)'
misplaced <- reviews[vapply(reviews, function(path) {
  any(grepl(secondary, readLines(path, warn = FALSE, encoding = 'UTF-8'),
    ignore.case = TRUE, perl = TRUE))
}, logical(1))]
if (length(misplaced)) stop('Secondary analysis material in: ', paste(misplaced, collapse = ', '))

readme <- readLines('README.md', warn = FALSE, encoding = 'UTF-8')
stopifnot(!any(grepl('\\bfit(?:s|ted|ting)?\\b', readme,
  ignore.case = TRUE, perl = TRUE)))
cat('Source-review ownership and README scope checks passed.\n')
