cache <- commandArgs(TRUE)[1]
env <- new.env()
load(file.path(cache, "run_model.RData"), env)
fit <- env$fit
dat <- fit$data
fleet <- attr(dat, "fleetNames")
obs <- data.frame(dat$aux, value = exp(dat$logobs))
obs$fleet_name <- fleet[obs$fleet]
obs$sampling_time <- dat$sampleTimes[obs$fleet]
obs$weight <- dat$weight
obs$prediction <- exp(fit[["rep"]]$predObs)
write.csv(obs, file.path(cache, "native_observations.csv"), row.names = FALSE)
for (name in c("logN", "logF")) {
  x <- fit$pl[[name]]
  ages <- seq.int(fit$conf$minAge, fit$conf$maxAge)
  if (name == "logF") x <- x[fit$conf$keyLogFsta[1, ] + 1, , drop = FALSE]
  grid <- expand.grid(age = ages, year = dat$years)
  grid$value <- c(exp(x))
  write.csv(grid, file.path(cache, paste0("native_", name, ".csv")), row.names = FALSE)
}
for (name in c("propMat", "stockMeanWeight", "catchMeanWeight", "natMor", "landFrac", "disMeanWeight", "landMeanWeight", "propF", "propM")) {
  x <- dat[[name]]
  grid <- expand.grid(dimnames(x), stringsAsFactors = FALSE)
  names(grid) <- c("year", "age", "fleet")[seq_len(ncol(grid))]
  grid$value <- c(x)
  write.csv(grid, file.path(cache, paste0("native_", name, ".csv")), row.names = FALSE)
}
write.csv(data.frame(year = dat$years, recruitment = exp(fit$pl$logN[1, ])), file.path(cache, "native_recruitment.csv"), row.names = FALSE)
v <- fit$sdrep$value
s <- fit$sdrep$sd
summary <- do.call(rbind, lapply(c("logssb", "logfbar", "logtsb", "logR"), function(name) {
  take <- which(names(v) == name)
  if (length(take) != length(dat$years)) {
    return(NULL)
  }
  data.frame(metric = name, year = dat$years, value = exp(v[take]), log_se = s[take], lwr = exp(v[take] - 2 * s[take]), upr = exp(v[take] + 2 * s[take]))
}))
write.csv(summary, file.path(cache, "native_summary.csv"), row.names = FALSE)
capture.output(
  {
    cat("SAM version", attr(fit, "Version"), "revision", attr(fit, "RemoteSha"), "\n")
    print(aggregate(year ~ fleet_name + sampling_time, obs, range))
    print(aggregate(value ~ fleet_name, obs, length))
    print(tail(summary, 6))
    print(fit$opt[c("objective", "convergence", "message")])
    print(fit$sdrep$pdHess)
    print(fit$conf)
  },
  file = file.path(cache, "native_inventory.txt")
)
print(summary[summary$year >= 2025, ])




p <- fit$sdrep$par.fixed
s <- sqrt(diag(fit$sdrep$cov.fixed))
q_tables <- list()
for (measure in c("q", "q_power")) {
  parameter <- if (measure == "q") "logFpar" else "logQpow"
  keys <- if (measure == "q") fit$conf$keyLogFpar else fit$conf$keyQpow
  vals <- p[names(p) == parameter]
  ses <- s[names(p) == parameter]
  stopifnot(length(vals) == length(fit$pl[[parameter]]), all(abs(vals - fit$pl[[parameter]]) < 1e-10))
  ages <- fit$conf$minAge:fit$conf$maxAge
  for (f in 2:3) {
    for (a in seq_along(ages)) {
      key <- keys[f, a]
      if (key < 0) next
      k <- key + 1
      q_tables[[length(q_tables) + 1]] <- data.frame(
        measure = measure, survey = fleet[f], age = ages[a], key = key,
        value = exp(vals[k]), se = exp(vals[k]) * ses[k],
        lwr = exp(vals[k] - qnorm(.975) * ses[k]), upr = exp(vals[k] + qnorm(.975) * ses[k]),
        log_estimate = vals[k], log_se = ses[k]
      )
    }
  }
}
write.csv(do.call(rbind, q_tables), file.path(cache, "native_catchability.csv"), row.names = FALSE)
