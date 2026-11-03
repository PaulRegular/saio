root <- "."
cache <- file.path(root, "source_cache", "afsc_pollock_ebs_2024")
id <- "afsc_pollock_ebs_2024"
input_path <- file.path(root, "database", "inputs.csv")
review_path <- file.path(root, "source_reviews", "afsc_pollock_ebs.md")

ctl <- trimws(readLines(file.path(cache, "control.dat"), warn = FALSE))
read_control <- function(label, n = 1L) {
  i <- which(ctl == paste0("#", label))
  stopifnot(length(i) == 1L)
  as.numeric(ctl[i + seq_len(n)])
}
m <- read_control("natmort_in", 15L)
stopifnot(
  identical(m, c(0.9, 0.45, rep(0.3, 13L))),
  read_control("phase_natmort") == -6,
  read_control("switch_pred_mort") == 0
)
report <- paste(readLines(file.path(cache, "2024_SAFE_text.txt"), warn = FALSE),
  collapse = "\n"
)
stopifnot(grepl("constant natural mortality rates at age", report, fixed = TRUE))

source_rows <- read.csv(input_path,
  stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE
)
lines <- readLines(input_path, warn = FALSE)
stopifnot(length(lines) == nrow(source_rows) + 1L)
keep <- !(source_rows$assessment_id == id & source_rows$type == "M")
rows <- lapply(seq_along(m), function(age) {
  x <- as.list(setNames(
    rep(NA_character_, ncol(source_rows)),
    names(source_rows)
  ))
  x$assessment_id <- id
  x$type <- "M"
  x$measure <- "natural_mortality_at_age"
  x$basis <- "per_year"
  x$age <- as.character(age)
  x$value <- as.character(m[[age]])
  x$unit <- "per year"
  x$source_type <- "native_model"
  x$source_reference <- "https://github.com/noaa-afsc/EBS_pollock; official 2024 control.dat, natmort_in; SAFE section 5.3.1"
  x$notes <- "Time-invariant age vector (blank year dimension), valid throughout 1964-2024; age 15 is 15+. phase_natmort=-6 and switch_pred_mort=0. Official report explicitly confirms age-constant-through-time M; predation extensions are not active."
  unlist(x, use.names = TRUE)
})
csv_field <- function(x) {
  if (is.na(x)) {
    return("")
  }
  x <- as.character(x)
  if (grepl('[,"\r\n]', x)) paste0('"', gsub('"', '""', x, fixed = TRUE), '"') else x
}
new_lines <- vapply(rows, function(x) {
  paste(vapply(x, csv_field, character(1)), collapse = ",")
}, character(1))
writeLines(c(lines[1], lines[-1][keep], new_lines), input_path, useBytes = TRUE)

review <- readLines(review_path, warn = FALSE)
heading <- "## Fixed natural mortality resolved"
if (!any(trimws(review) == heading)) {
  cat("\n\n", heading, "\n\nSAFE section 5.3.1 explicitly states constant natural mortality rates at age for M23. Native control.dat supplies 0.9 at age 1, 0.45 at age 2 and 0.3 at ages 3-15, fixes the mortality-scaling parameter at phase -6, and sets switch_pred_mort=0. The implementation copies this vector into annual M when optional alternative mortality switches are inactive. Store the fixed age vector once with no year dimension; it applies throughout 1964-2024, with age 15 as the plus group. It is not a fitted output or an annual predation estimate.\n",
    file = review_path, append = TRUE, sep = ""
  )
}
message("Fixed 15-age EBS pollock mortality input verified from the official controls and report.")
