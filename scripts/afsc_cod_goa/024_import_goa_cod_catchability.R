root <- "."
id <- "afsc_cod_goa_2026"
p <- file.path(root, "database/outputs.csv")
x <- read.csv(p, stringsAsFactors = FALSE, check.names = FALSE)
x <- x[!(x$assessment_id == id & x$measure == "q"), ]
source <- "https://meetings.npfmc.org/CommentReview/DownloadFile?fileName=C1+GOA+Pcod+Assessment.pdf&p=f00593eb-12f5-458c-842e-a5cdd45306bb.pdf; Table 2.6"
for (i in 1:2) {
  row <- as.list(setNames(rep("", ncol(x)), names(x)))
  row$assessment_id <- id
  row$type <- "catchability"
  row$measure <- "q"
  row$survey <- c("NMFS bottom-trawl survey", "NMFS longline survey")[i]
  row$value <- c(1.28, 1.17)[i]
  row$se <- c(.123, .108)[i]
  row$unit <- "native index coefficient"
  row$source_type <- "official_table"
  row$source_reference <- source
  row$notes <- "Rounded baseline q estimate and natural-scale delta-method SD from Table 2.6. Reporting code exponentiates log q and multiplies its log-scale SD by q. No confidence interval reconstructed. Longline annual q additionally depends on the environmental effect; this coefficient alone is not the annual surface."
  x <- rbind(x, as.data.frame(row, stringsAsFactors = FALSE))
}
write.csv(x, p, row.names = FALSE, na = "")
check <- read.csv(p, stringsAsFactors = FALSE)
z <- check[check$assessment_id == id & check$measure == "q", ]
stopifnot(nrow(z) == 2, identical(z$value, c(1.28, 1.17)), identical(z$se, c(.123, .108)), all(is.na(z$year)), all(is.na(z$lwr)), all(is.na(z$upr)))
message("Recorded two published baseline catchability estimates with natural-scale SDs.")
