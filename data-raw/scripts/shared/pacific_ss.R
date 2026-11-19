pacific_ss_section <- function(path, label, skip = 1L) {
  lines <- readLines(path, warn = FALSE)
  at <- which(startsWith(lines, label))[1L]
  if (is.na(at)) cli::cli_abort("Missing Stock Synthesis section: {label}.")
  first <- at + skip
  last <- which(seq_along(lines) > first & !nzchar(trimws(lines)))[1L] - 1L
  utils::read.table(text = paste(lines[first:last], collapse = "\n"),
    header = TRUE, fill = TRUE, check.names = FALSE, quote = "", comment.char = "")
}

pacific_ss_compositions <- function(dat, component, id, reference, region) {
  age <- component == "age"
  x <- if (age) dat$agecomp else dat$lencomp
  bins <- if (age) dat$agebin_vector else dat$lbin_vector
  if (is.null(x) || !nrow(x)) return(NULL)
  begin <- if (age) 10L else 7L
  count <- length(bins)
  out <- list()
  for (i in seq_len(nrow(x))) {
    v <- x[i, ]
    fleet <- abs(v$FltSvy)
    fishery <- dat$fleetinfo$type[fleet] %in% c(1, 2)
    if (v$Gender != 3L) cli::cli_abort("This importer expects joint female/male compositions.")
    joint <- as.numeric(v[begin:(begin + 2L * count - 1L)])
    if (abs(sum(joint) - 1) > 1e-5) {
      cli::cli_abort("Source composition is not a joint number proportion; retain its native frequency scale explicitly.")
    }
    for (sex in 1:2) {
      values <- joint[(sex - 1L) * count + seq_len(count)]
      out[[length(out) + 1L]] <- pacific_database_row("inputs",
        assessment_id = id, type = if (fishery) "catch" else "index",
        measure = if (age) "proportion_at_age" else "proportion_at_length",
        basis = "proportion_numbers", value = values, unit = "proportion",
        fleet = if (fishery) dat$fleetnames[fleet] else "",
        survey = if (fishery) "" else dat$fleetnames[fleet],
        sex = c("female", "male")[sex], region = region,
        year = v$Yr, year_basis = "calendar_year",
        age = if (age) bins else NA_integer_,
        length_bin = if (age) NA_real_ else bins,
        observation_id = paste(component, i, sep = ":"), sample_size = v$Nsamp,
        age_error = if (age) v$Ageerr else NA_real_, partition = v$Part,
        sampling_time = if (fishery) NA_real_ else (v$Seas - 1) / 12,
        source_type = "native_model", source_reference = reference,
        notes = paste("Joint-sex number proportions; female and male cells sum together to one.",
          "sample_size is the supplied row N before the separately recorded control multiplier.",
          if (v$FltSvy < 0) "Negative fleet code: inactive likelihood row." else "Active source row.",
          "Month", v$Seas, "; fishery timing -1 uses annual catch, not an instantaneous sample."))
    }
  }
  do.call(rbind, out)
}
