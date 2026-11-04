root <- "."
read_small <- function(path) read.csv(path, stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
read_selected <- function(path, columns) {
  fields <- names(read.csv(path, nrows = 0L, check.names = FALSE))
  classes <- rep("NULL", length(fields)); names(classes) <- fields
  classes[columns] <- "character"
  read.csv(path, stringsAsFactors = FALSE, check.names = FALSE,
    na.strings = c("", "NA"), colClasses = classes)
}
stock_id <- "nafo_american_plaice_3lno"
historical_id <- "nafo_american_plaice_3lno_2021"
monitoring_id <- "nafo_american_plaice_3lno_2026_monitoring"
stocks <- read_small("database/stocks.csv")
assessments <- read_small("database/assessments.csv")
assumptions <- read_selected("database/assumptions.csv", c("assessment_id", "setting", "value"))
inputs <- read_selected("database/inputs.csv", c("assessment_id", "type", "measure", "basis", "year", "age", "value", "unit", "survey", "season", "sampling_time", "source_type", "source_reference", "notes"))
outputs <- read_selected("database/outputs.csv", c("assessment_id", "type", "measure", "year", "age", "value", "se", "lwr", "upr", "unit", "source_type", "source_reference", "notes"))
candidates <- read_small("discovery/candidates.csv")
s <- stocks[stocks$stock_id == stock_id, , drop=FALSE]
a_hist <- assessments[assessments$assessment_id == historical_id, , drop=FALSE]
a_mon <- assessments[assessments$assessment_id == monitoring_id, , drop=FALSE]
i_hist <- inputs[inputs$assessment_id == historical_id, , drop=FALSE]
i_mon <- inputs[inputs$assessment_id == monitoring_id, , drop=FALSE]
o_hist <- outputs[outputs$assessment_id == historical_id, , drop=FALSE]
o_mon <- outputs[outputs$assessment_id == monitoring_id, , drop=FALSE]
as_hist <- assumptions[assumptions$assessment_id == historical_id, , drop=FALSE]
as_mon <- assumptions[assumptions$assessment_id == monitoring_id, , drop=FALSE]
c <- candidates[candidates$candidate_id == "NAFO:american_plaice.3LNO", , drop=FALSE]

val <- function(x, type, measure, year, age=NA_integer_, survey=NULL, basis=NULL) {
  take <- x$type == type & x$measure == measure & as.integer(x$year) == year
  if (!is.na(age)) take <- take & as.numeric(x$age) == age
  if (!is.null(survey)) take <- take & x$survey == survey
  if (!is.null(basis) && "basis" %in% names(x)) take <- take & x$basis == basis
  stopifnot(sum(take, na.rm=TRUE) == 1L)
  as.numeric(x$value[take])
}
stopifnot(nrow(s)==1L, s$authority=="NAFO", s$authority_stock_id=="american_plaice.3LNO",
  s$scientific_name=="Hippoglossoides platessoides", s$ocean=="Northwest Atlantic",
  nrow(a_hist)==1L, a_hist$assessment_year==2021L, a_hist$terminal_year==2020L,
  a_hist$estimate_terminal_year==2021L, a_hist$model_family=="ADAPT", !a_hist$is_current,
  a_hist$inputs_status=="complete", a_hist$outputs_status=="partial",
  nrow(a_mon)==1L, a_mon$assessment_year==2026L, a_mon$terminal_year==2025L,
  a_mon$assessment_type=="interim_monitoring", a_mon$is_current,
  a_mon$outputs_status=="not_applicable", nrow(as_hist)==6L, nrow(as_mon)==3L,
  nrow(i_hist)==3580L, sum(i_hist$type=="catch" & i_hist$measure=="numbers_at_age")==671L,
  sum(i_hist$type=="weight" & i_hist$measure=="weight_at_age")==682L,
  sum(i_hist$type=="maturity" & i_hist$measure=="maturity_at_age")==726L,
  sum(i_hist$type=="index" & i_hist$measure=="numbers_at_age")==830L,
  sum(i_hist$type=="M" & i_hist$measure=="natural_mortality_at_age")==671L,
  val(i_hist,"catch","numbers_at_age",1960L,5L)==44.7,
  val(i_hist,"catch","numbers_at_age",2020L,15L)==5.1,
  val(i_hist,"weight","weight_at_age",1960L,5L)==0.227,
  val(i_hist,"weight","weight_at_age",2021L,15L)==1.171,
  val(i_hist,"maturity","maturity_at_age",1960L,5L)==0,
  val(i_hist,"index","numbers_at_age",1990L,5L,"Canadian autumn RV bottom-trawl survey")==853.098,
  val(i_hist,"index","numbers_at_age",1985L,5L,"Canadian spring RV bottom-trawl survey")==263.811,
  val(i_hist,"index","numbers_at_age",1998L,5L,"EU-Spain Divisions 3NO spring bottom-trawl survey")==8.58,
  val(i_hist,"M","natural_mortality_at_age",1989L,5L)==0.53,
  val(i_hist,"M","natural_mortality_at_age",1997L,15L)==0.2,
  all(is.na(i_hist$sampling_time)), nrow(i_mon)==34L,
  sum(i_mon$type=="catch" & i_mon$measure=="total_biomass")==9L,
  val(i_mon,"index","total_biomass",2025L,survey="EU-Spain spring bottom-trawl survey, NAFO Divisions 3NO")==35664,
  val(i_mon,"index","index_sd",2025L,survey="EU-Spain spring bottom-trawl survey, NAFO Divisions 3NO",basis="biomass")==6700,
  val(i_mon,"index","total_numbers",2025L,survey="EU-Spain spring bottom-trawl survey, NAFO Divisions 3NO")==142349,
  val(i_mon,"index","index_sd",2025L,survey="EU-Spain spring bottom-trawl survey, NAFO Divisions 3NO",basis="numbers")==17608,
  val(i_mon,"index","total_biomass",2025L,survey="EU-Spain bottom-trawl survey, NAFO Division 3L")==11459,
  !any(i_mon$measure=="index_sd" & i_mon$survey=="EU-Spain bottom-trawl survey, NAFO Division 3L"),
  nrow(o_hist)==10L, nrow(o_mon)==0L,
  val(o_hist,"population","survivors_at_age",2021L,6L)==19166.465,
  o_hist$se[o_hist$measure=="survivors_at_age" & as.numeric(o_hist$age)==6L]==15276.083,
  any(grepl("no directed fishing", as_mon$value, ignore.case=TRUE)),
  grepl("No numeric zero-catch output is inferred", a_mon$notes, fixed=TRUE),
  nrow(c)==1L, c$matched_stock_id==stock_id, c$match_status=="matched",
  c$import_status=="partial", c$inventory_assessment_year==2026L)
manifest <- read_small("provenance/nafo_american_plaice_3lno/manifest.csv")
stopifnot(nrow(manifest)==8L, all(nchar(manifest$sha256)==64L))


