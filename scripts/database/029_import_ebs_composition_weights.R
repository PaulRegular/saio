root <- "."
cache <- file.path(root, "source_cache/afsc_pollock_ebs_2024")
d <- trimws(readLines(file.path(cache, "pm_24.dat"), warn = FALSE))
read_block <- function(label, n) {
  i <- which(d == paste0("#", label))
  stopifnot(length(i) == 1)
  x <- as.numeric(strsplit(d[i + 1], "[[:space:]]+")[[1]])
  stopifnot(length(x) == n)
  x
}
series <- list(
  fsh = list(years = read_block("yrs_fsh_data", 60), values = read_block("sam_fsh", 60)),
  bts = list(years = read_block("yrs_bts_data", 42), values = read_block("sam_bts", 42)),
  ats = list(years = read_block("yrs_ats_data", 19), values = read_block("sam_ats", 19))
)
p <- file.path(root, "database/assumptions.csv")
a <- read.csv(p, stringsAsFactors = FALSE, check.names = FALSE)
id <- "afsc_pollock_ebs_2024"
prefix <- "composition_effective_weight_"
a <- a[!(a$assessment_id == id & startsWith(a$setting, prefix)), ]
for (fleet in names(series)) {
  for (j in seq_along(series[[fleet]]$years)) {
    r <- as.list(setNames(rep("", ncol(a)), names(a)))
    r$assessment_id <- id
    r$component <- "observation"
    r$setting <- paste0(prefix, fleet, "_", series[[fleet]]$years[j])
    r$value <- format(series[[fleet]]$values[j], digits = 17, trim = TRUE, scientific = FALSE)
    r$fleet <- if (fleet == "fsh") "Combined fishery" else ""
    r$survey <- switch(fleet,
      bts = "NMFS bottom-trawl VAST",
      ats = "NMFS acoustic-trawl",
      fsh = ""
    )
    r$notes <- "Native sam vector likelihood weight for this composition year, as supplied to robust_p; stored separately from raw composition counts and the optional sample_size field."
    r$source_reference <- "https://github.com/noaa-afsc/EBS_pollock; official data/pm_24.dat sam_fsh/sam_bts/sam_ats; source/pm.tpl robust_p"
    a <- rbind(a, as.data.frame(r, stringsAsFactors = FALSE))
  }
}
write.csv(a, p, row.names = FALSE, na = "")
controls <- trimws(readLines(file.path(cache, "control.dat"), warn = FALSE))
value <- function(key) {
  i <- which(controls == paste0("#", key))
  stopifnot(length(i) == 1)
  as.numeric(controls[i + 1])
}
stopifnot(value("DoCovBTS") == 1, value("use_age1_ats") == 1, value("do_bts_bio") == 1, value("do_ats_bio") == 1)
prefix2 <- c("BTS_likelihood", "ATS_likelihood")
for (k in prefix2) {
  i <- a$assessment_id == id & a$setting == k
  stopifnot(sum(i) == 1)
}
cat("\n## Composition weights and active observation likelihoods\n\nThe 60 fishery, 42 BTS and 19 ATS sam values have been captured by year as native composition likelihood weights. These are the values passed to robust_p and remain distinct from raw age frequencies. Control flags also verify BTS full-covariance biomass likelihood, ATS biomass likelihood and separate ATS age-1 treatment. Numerical BTS covariance is independently stored by calendar-year rows. The no-age-error switch is zero, so the official fit uses an identity ageing-error treatment.\n", file = file.path(root, "source_reviews/afsc_pollock_ebs.md"), append = TRUE)
message("Recorded 121 annual composition weights and confirmed active observation likelihood controls.")
