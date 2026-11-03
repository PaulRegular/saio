# Record verified catchability controls from the official native configuration.
root <- "."
cache <- file.path(root, "source_cache/afsc_cod_goa_2026")
control <- readLines(file.path(cache, "2025_mgmt_24.0_Model24_0.ctl"), warn = FALSE)
parameter <- function(label) {
  line <- control[endsWith(trimws(control), paste0("#_", label))]
  stopifnot(length(line) == 1)
  as.numeric(strsplit(trimws(strsplit(line, "#", fixed = TRUE)[[1]][1]), "[[:space:]]+")[[1]])
}
bts <- parameter("LnQ_base_Srv(4)")
ll <- parameter("LnQ_base_LLSrv(5)")
env <- parameter("LnQ_base_LLSrv(5)_ENV_add")
stopifnot(
  length(bts) == 14, length(ll) == 14, length(env) == 7,
  bts[7] == 1, ll[7] == 1, bts[8] == 0, ll[8] == 101,
  all(bts[9:14] == 0), all(ll[9:14] == 0), env[7] == 5
)
p <- file.path(root, "database/assumptions.csv")
a <- read.csv(p, stringsAsFactors = FALSE, check.names = FALSE)
id <- "afsc_cod_goa_2026"
setting <- "native_catchability_controls"
a <- a[!(a$assessment_id == id & a$setting == setting), ]
source <- "https://github.com/pete-hulson/goa_pcod/blob/facf41573f9a0b609d0096611bc9302aaab43abe/2025/mgmt/24.0/Model24_0.ctl"
for (survey in c("NMFS bottom-trawl survey", "NMFS longline survey")) {
  row <- as.list(setNames(rep("", ncol(a)), names(a)))
  row$assessment_id <- id
  row$component <- "q"
  row$setting <- setting
  row$survey <- survey
  row$source_reference <- source
  row$value <- if (survey == "NMFS bottom-trawl survey") "Estimated baseline log q; no annual deviations or blocks" else "Estimated baseline log q and environmental coefficient; no annual deviations or blocks"
  row$notes <- if (survey == "NMFS bottom-trawl survey") "Baseline phase 1; env-var 0, use_dev 0, Block 0. Starting value is not a fitted catchability estimate." else "Baseline phase 1; env-var/link 101; environmental coefficient phase 5. use_dev 0 and Block 0. Supplied environmental observations are recorded separately. Starting values are not fitted estimates."
  a <- rbind(a, as.data.frame(row, stringsAsFactors = FALSE))
}
write.csv(a, p, row.names = FALSE, na = "")
message("Verified and recorded baseline/environmental q controls for both active Pacific cod surveys.")
