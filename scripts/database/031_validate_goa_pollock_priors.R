root <- normalizePath(".", mustWork = TRUE)
id <- "afsc_pollock_goa_2024"
assumptions <- read.csv(file.path(root, "database/assumptions.csv"), stringsAsFactors = FALSE, check.names = FALSE, na.strings = character())
source <- readLines(file.path(root, "source_cache/afsc_pollock_goa_2024/data_2024_goa_pk.cpp"), warn = FALSE, encoding = "UTF-8")
active_source <- source[!grepl("^\\s*//", source)]
rows <- assumptions[assumptions$assessment_id == id, ]
expected <- data.frame(
  component = c("F", rep("index", 4), "composition"),
  fleet = c("Combined fishery", rep("", 5)),
  survey = c("", "Shelikof winter acoustic", "NMFS bottom trawl", "ADF&G crab/groundfish trawl", "Summer acoustic", ""),
  setting = c(rep("selectivity_parameter_priors", 5), "log_parameter_prior"),
  value = c(
    "log_slp1_fsh_mean ~ N(-1, 1.5); log_slp2_fsh_mean ~ N(-1, 1.5); inf1_fsh_mean ~ N(0, 3); inf2_fsh_mean ~ N(10, 3)",
    "log_slp2_srv1 ~ N(-1, 1.5); inf2_srv1 ~ N(10, 3)",
    "log_slp1_srv2 ~ N(-1, 1.5); log_slp2_srv2 ~ N(-1, 1.5); inf1_srv2 ~ N(0, 3); inf2_srv2 ~ N(10, 3)",
    "log_slp1_srv3 ~ N(-1, 1.5); inf1_srv3 ~ N(0, 3)",
    "log_slp1_srv6 ~ N(-1, 1.5); log_slp2_srv6 ~ N(-1, 1.5); inf1_srv6 ~ N(0, 3); inf2_srv6 ~ N(10, 3)",
    "Each of the five log_DM_pars parameters ~ N(0, 2)"
  ),
  stringsAsFactors = FALSE
)
for (i in seq_len(nrow(expected))) {
  hit <- rows[rows$component == expected$component[i] & rows$fleet == expected$fleet[i] & rows$survey == expected$survey[i] & rows$setting == expected$setting[i], ]
  stopifnot(nrow(hit) == 1L, hit$value == expected$value[i])
}
required_terms <- c("dnorm(log_slp1_fsh_mean, Type(-1.0),Type(1.5), true)", "dnorm(log_slp2_fsh_mean, Type(-1.0),Type(1.5), true)", "dnorm(inf1_fsh_mean, Type(0.0),Type(3.0), true)", "dnorm(inf2_fsh_mean, Type(10.0),Type(3.0), true)", "dnorm(log_DM_pars, Type(0.0), Type(2.0),true).sum()")
stopifnot(all(vapply(required_terms, function(term) any(grepl(term, active_source, fixed = TRUE)), logical(1))))
stopifnot(any(grepl("log_DM_pars(0)", source, fixed = TRUE)), any(grepl("DM_pars = exp(log_DM_pars)", source, fixed = TRUE)))
cat("GOA pollock active selectivity and composition priors match the pinned assessment source.\n")
