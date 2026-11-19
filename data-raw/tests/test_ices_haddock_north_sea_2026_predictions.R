root <- "."
source(file.path(root, "R", "read_database.R"))
database <- read_database()
source <- read_assessment("ices_haddock_north_sea_2026", database)
inputs <- source$inputs
outputs <- source$outputs

predicted_catch <- subset(outputs, measure == "predicted_catch")
predicted_index <- subset(outputs, measure == "predicted_index")
catch <- subset(inputs, type == "catch" & measure == "numbers_at_age")
index <- subset(inputs, type == "index" & measure == "numbers_at_age")

key <- function(x, fields) {
  values <- lapply(x[fields], function(value) {
    value <- as.character(value)
    value[is.na(value) | !nzchar(value)] <- ""
    value
  })
  do.call(paste, c(values, sep = "\r"))
}

stopifnot(
  nrow(predicted_catch) == 486L,
  nrow(predicted_index) == 667L,
  all(predicted_catch$fleet == "Residual catch"),
  all(predicted_catch$unit == "thousand fish"),
  all(predicted_index$unit == "native survey index"),
  all(is.na(predicted_catch$se)), all(is.na(predicted_catch$lwr)),
  all(is.na(predicted_catch$upr)), all(is.na(predicted_index$se)),
  all(is.na(predicted_index$lwr)), all(is.na(predicted_index$upr)),
  all(is.finite(as.numeric(c(predicted_catch$value, predicted_index$value)))),
  !anyDuplicated(predicted_catch[c("year", "age")]),
  !anyDuplicated(predicted_index[c("survey", "year", "age")]),
  setequal(key(predicted_catch, c("year", "age", "fleet")),
    key(catch, c("year", "age", "fleet")))
)

for (survey in c("delta-GAMNS-WCQ1", "delta-GAMNS-WCQ3+Q4")) {
  fitted <- predicted_index[predicted_index$survey == survey, , drop = FALSE]
  source_index <- index[index$survey == survey, , drop = FALSE]
  stopifnot(
    nrow(fitted) == if (survey == "delta-GAMNS-WCQ1") 352L else 315L,
    setequal(key(fitted, c("year", "age", "survey")),
      key(source_index, c("year", "age", "survey")))
  )
}

cat("North Sea haddock fitted predictions match all official catch and survey observation rows.\n")
