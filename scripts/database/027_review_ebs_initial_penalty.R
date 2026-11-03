p <- "database/assumptions.csv"
a <- read.csv(p, stringsAsFactors = FALSE, check.names = FALSE)
i <- a$assessment_id == "afsc_pollock_ebs_2024" & a$setting == "initial_abundance_parameterization"
stopifnot(sum(i) == 1)
a$notes[i] <- "natage(styr,2:nages)=exp(log_avginit+log_initdevs). Mean estimated from phase 1; age deviations bounded -15 to 15 from phase 3. Final objective includes 0.1*sum(log_initdevs^2), weighted by ctrl_flag(3)=1. The 10*(log_avginit-log_avgrec)^2 constraint applies only in optimization phases below 3 and is absent from the final objective. This is not an equilibrium initial age distribution."
write.csv(a, p, row.names = FALSE, na = "")
ctl <- trimws(readLines("source_cache/afsc_pollock_ebs_2024/control.dat", warn = FALSE))
j <- which(ctl == "#ctrl_flag")
stopifnot(length(j) == 1, as.numeric(ctl[j + 3]) == 1)
code <- paste(readLines("source_cache/afsc_pollock_ebs_2024/source_pm.tpl", warn = FALSE), collapse = "\n")
stopifnot(grepl("if (current_phase()<3)", code, fixed = TRUE), grepl("rec_like(4) =  .1*norm2(log_initdevs)", code, fixed = TRUE))
review_path <- "source_reviews/afsc_pollock_ebs.md"
review_note <- "The additional mean-initial-abundance constraint is optimization-phase conditioning only: 10*(log_avginit-log_avgrec)^2 applies below phase 3 and is removed from the final objective. The final initial-age penalty is 0.1*sum(log_initdevs^2), multiplied by ctrl_flag(3)=1. This distinction is now explicit in the assumptions record."
review <- paste(readLines(review_path, warn = FALSE), collapse = "\n")
if (!grepl(review_note, review, fixed = TRUE)) {
  cat("\n\n", review_note, "\n", file = review_path, append = TRUE)
}
