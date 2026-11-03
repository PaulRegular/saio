root <- "."
cache <- file.path(root, "source_cache/afsc_pollock_ebs_2024")
m <- as.matrix(read.table(file.path(cache, "cov_2024.dat")))
d <- trimws(readLines(file.path(cache, "pm_24.dat"), warn = FALSE))
i <- which(d == "#yrs_bts_data")
years <- as.integer(strsplit(d[i + 1], "[[:space:]]+")[[1]])
stopifnot(
  identical(dim(m), c(42L, 42L)), identical(years, c(1982:2019, 2021:2024)),
  max(abs(m - t(m))) < 1e-7, all(diag(m) > 0), min(eigen(m, symmetric = TRUE, only.values = TRUE)$values) > 0
)
p <- file.path(root, "database/assumptions.csv")
a <- read.csv(p, stringsAsFactors = FALSE, check.names = FALSE)
id <- "afsc_pollock_ebs_2024"
prefix <- "BTS_biomass_covariance_row_"
a <- a[!(a$assessment_id == id & startsWith(a$setting, prefix)), ]
for (j in seq_along(years)) {
  r <- as.list(setNames(rep("", ncol(a)), names(a)))
  r$assessment_id <- id
  r$component <- "index"
  r$setting <- paste0(prefix, years[j])
  r$survey <- "NMFS bottom-trawl VAST"
  r$value <- paste(format(m[j, ], digits = 17, trim = TRUE, scientific = FALSE), collapse = ", ")
  r$notes <- paste0("Native cov_2024.dat row; columns in calendar-year order: ", paste(years, collapse = ", "), ". Covariance of unlogged biomass-index residuals on the native index scale squared; no rescaling. Objective uses 0.5*r^T*inverse(cov)*r with r=observed-predicted biomass after q normalization.")
  r$source_reference <- "https://github.com/noaa-afsc/EBS_pollock; official data/cov_2024.dat, pm_24.dat yrs_bts_data; source/pm.tpl Survey_Likelihood"
  a <- rbind(a, as.data.frame(r, stringsAsFactors = FALSE))
}
i <- a$assessment_id == id & a$setting == "BTS_likelihood"
a$notes[i] <- "DoCovBTS=1 and do_bts_bio=1. All 42x42 native covariance cells represented as year-labeled numerical assumption rows; unlogged biomass residuals, not log-index SDs."
write.csv(a, p, row.names = FALSE, na = "")
z <- a[a$assessment_id == id & startsWith(a$setting, prefix), ]
recovered <- do.call(rbind, lapply(z$value, function(v) as.numeric(strsplit(v, ",", fixed = TRUE)[[1]])))
stopifnot(identical(unname(recovered), unname(m)))
cat("\n## Bottom-trawl covariance recovered\n\nAll 1,764 cells of the 42-by-42 supplied covariance matrix are now preserved as year-labeled numerical assumption rows, with explicit column years 1982–2019 and 2021–2024. Native-source checks confirm symmetry, positive definiteness and exact numerical round-trip. The likelihood uses unlogged biomass residuals after q normalization, not log-index errors. This matrix must not be replaced by independent observation SDs when describing the official assessment.\n", file = file.path(root, "source_reviews/afsc_pollock_ebs.md"), append = TRUE)
message("Native 42x42 BTS covariance represented and exactly verified.")
