root <- "."
p <- file.path(root, "database/assumptions.csv")
a <- read.csv(p, stringsAsFactors = FALSE, check.names = FALSE)
id <- "afsc_cod_goa_2026"
setting <- "missing_environmental_year"
a <- a[!(a$assessment_id == id & a$setting == setting), ]
r <- as.list(setNames(rep("", ncol(a)), names(a)))
r$assessment_id <- id
r$component <- "q"
r$setting <- setting
r$survey <- "NMFS longline survey"
r$value <- "2025 missing covariate uses SS3 zero-effect default"
r$notes <- "CFSR temperature index discontinued; unavailable for 2025. Report states SS3 sets missing environmental index to zero, using the mean parameter effect. This is a model default, not a measured zero anomaly; supplied numerical observations remain 1979–2024."
r$source_reference <- "https://meetings.npfmc.org/CommentReview/DownloadFile?fileName=C1+GOA+Pcod+Assessment.pdf&p=f00593eb-12f5-458c-842e-a5cdd45306bb.pdf; Environmental indices, page 7"
a <- rbind(a, as.data.frame(r, stringsAsFactors = FALSE))
write.csv(a, p, row.names = FALSE, na = "")
x <- read.csv(file.path(root, "database/inputs.csv"), stringsAsFactors = FALSE)
z <- x[x$assessment_id == id & x$type == "covariate", ]
stopifnot(nrow(z) == 46, max(z$year) == 2024, !any(z$year == 2025))
cat("\nThe current report explicitly states that CFSR was discontinued and no 2025 value was available. SS3 uses a zero environmental effect in that year; this model rule is now an assumption, not an observed-zero input. The 46 supplied covariates remain 1979–2024. Physical anomaly units remain unresolved.\n", file = file.path(root, "source_reviews/afsc_cod_goa.md"), append = TRUE)
message("Missing environmental-year treatment recorded without manufacturing an observation.")
