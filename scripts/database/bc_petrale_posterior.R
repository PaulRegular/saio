summarize_bc_petrale_posterior <- function(draws, years = 1938:2024) {
  columns <- c("iter", "year", "b", "bmsy")
  if (!is.data.frame(draws) || !all(columns %in% names(draws)) || !nrow(draws)) {
    cli::cli_abort("BC petrale posterior data require iter, year, b and bmsy columns.")
  }
  if (anyNA(draws[columns]) || any(!vapply(draws[columns], is.numeric, logical(1))) ||
      any(!is.finite(as.matrix(draws[columns]))) || any(draws$b <= 0 | draws$bmsy <= 0)) {
    cli::cli_abort("BC petrale posterior draws must have finite identifiers and positive biomass.")
  }
  if (!setequal(draws$year, years) || anyDuplicated(draws[c("iter", "year")]) ||
      any(table(draws$iter) != length(years))) {
    cli::cli_abort("BC petrale posterior draws must contain one complete year grid per iteration.")
  }
  if (any(vapply(split(draws$bmsy, draws$iter), function(x) length(unique(x)) != 1L, logical(1)))) {
    cli::cli_abort("BC petrale BMSY must be constant across years within each iteration.")
  }
  intervals <- t(vapply(years, function(year) {
    unname(stats::quantile(draws$b[draws$year == year], c(.025, .5, .975)))
  }, numeric(3)))
  data.frame(year = years, value = intervals[, 2], lwr = intervals[, 1], upr = intervals[, 3])
}
