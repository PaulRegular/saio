root <- normalizePath(".", mustWork = TRUE)
id <- "afsc_pollock_goa_2024"
assumption_file <- file.path(root, "database/assumptions.csv")
source_file <- file.path(root, "source_cache/afsc_pollock_goa_2024/data_2024_goa_pk.cpp")
source <- readLines(source_file, warn = FALSE, encoding = "UTF-8")
active_source <- source[!grepl("^\\s*//", source)]
required_terms <- c("dnorm(log_slp1_fsh_mean, Type(-1.0),Type(1.5), true)", "dnorm(log_slp2_fsh_mean, Type(-1.0),Type(1.5), true)", "dnorm(inf1_fsh_mean, Type(0.0),Type(3.0), true)", "dnorm(inf2_fsh_mean, Type(10.0),Type(3.0), true)", "dnorm(log_DM_pars, Type(0.0), Type(2.0),true).sum()")
if (!all(vapply(required_terms, function(term) any(grepl(term, active_source, fixed = TRUE)), logical(1)))) stop("Cached official-model source does not match the expected prior terms.")
source_reference <- "https://github.com/afsc-assessments/GOApollock/blob/aefe1692520510d55fd25db60121b292a53840a3/data/2024/goa_pk.cpp"
new_rows <- data.frame(
  assessment_id = id,
  component = c("F", rep("index", 4), "composition"),
  fleet = c("Combined fishery", rep("", 5)),
  survey = c("", "Shelikof winter acoustic", "NMFS bottom trawl", "ADF&G crab/groundfish trawl", "Summer acoustic", ""),
  sex = "", region = "", season = "",
  setting = c(rep("selectivity_parameter_priors", 5), "log_parameter_prior"),
  value = c(
    "log_slp1_fsh_mean ~ N(-1, 1.5); log_slp2_fsh_mean ~ N(-1, 1.5); inf1_fsh_mean ~ N(0, 3); inf2_fsh_mean ~ N(10, 3)",
    "log_slp2_srv1 ~ N(-1, 1.5); inf2_srv1 ~ N(10, 3)",
    "log_slp1_srv2 ~ N(-1, 1.5); log_slp2_srv2 ~ N(-1, 1.5); inf1_srv2 ~ N(0, 3); inf2_srv2 ~ N(10, 3)",
    "log_slp1_srv3 ~ N(-1, 1.5); inf1_srv3 ~ N(0, 3)",
    "log_slp1_srv6 ~ N(-1, 1.5); log_slp2_srv6 ~ N(-1, 1.5); inf1_srv6 ~ N(0, 3); inf2_srv6 ~ N(10, 3)",
    "Each of the five log_DM_pars parameters ~ N(0, 2)"
  ),
  source_reference = c(rep(paste0(source_reference, "; loglik(22), lines 1155-1174"), 5), paste0(source_reference, "; parameter transform and loglik(22), lines 391-400 and 1175")),
  notes = c(
    "Normal prior means and SDs apply on the named parameter scales. These active terms regularize the fishery selectivity means.",
    "Only the descending slope and inflection priors are active for this survey; the ascending terms are commented out in the official source.",
    "Normal prior means and SDs apply on the named parameter scales. All four terms are active for this survey.",
    "Only the ascending slope and inflection priors are active for this survey; the descending terms are commented out in the official source.",
    "Normal prior means and SDs apply on the named parameter scales. All four terms are active for this survey.",
    "The five parameters enter the linear Dirichlet-multinomial composition likelihood. The source uses exp(log_DM_pars) for concentration and invlogit(log_DM_pars) in its derived effective-sample-size calculation."
  ),
  stringsAsFactors = FALSE, check.names = FALSE
)
assumptions <- read.csv(assumption_file, stringsAsFactors = FALSE, check.names = FALSE, na.strings = character())
new_rows <- new_rows[, names(assumptions), drop = FALSE]
key_columns <- c("assessment_id", "component", "fleet", "survey", "setting")
row_key <- function(x) apply(x[, key_columns, drop = FALSE], 1, paste, collapse = "\034")
existing_keys <- row_key(assumptions)
new_keys <- row_key(new_rows)
append_rows <- new_rows[FALSE, , drop = FALSE]
for (i in seq_len(nrow(new_rows))) {
  match_row <- which(existing_keys == new_keys[i])
  if (length(match_row)) {
    existing_values <- as.character(unlist(assumptions[match_row[1], names(new_rows), drop = FALSE]))
    expected_values <- as.character(unlist(new_rows[i, , drop = FALSE]))
    existing_values[is.na(existing_values)] <- ""
    expected_values[is.na(expected_values)] <- ""
    same <- identical(unname(existing_values), unname(expected_values))
    if (!same) stop("Existing GOA pollock assumption conflicts with the verified source row.")
  } else {
    append_rows <- rbind(append_rows, new_rows[i, , drop = FALSE])
  }
}
if (nrow(append_rows)) write.table(append_rows, file = assumption_file, sep = ",", quote = TRUE, row.names = FALSE, col.names = FALSE, append = TRUE, na = "")
cat("Added", nrow(append_rows), "verified GOA pollock prior assumptions.\n")
