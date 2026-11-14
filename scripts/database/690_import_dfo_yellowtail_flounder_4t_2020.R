root <- "."
source(file.path(root, "scripts", "database", "pacific_tables.R"))
assessment_id <- "dfo_yellowtail_flounder_4t_2020"
stock_id <- "dfo_yellowtail_flounder_4t"
report <- "https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41063533.pdf"
advice <- "https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/40979805.pdf"
dry_run <- identical(Sys.getenv("SAIO_IMPORT_DRY_RUN"), "1")
years <- 1985:2020
landings_t <- c(215, 396, 404, 198, 43, 15, 53.6, 119.4, 87.5, 62.4, 208.1, 209.3, 813.4, 182.2, 304.8, 294.5, 317.4, 215.3, 157.7, 192, 175.5, 182.2, 141.9, 91.6, 101.4, 185.8, 180.8, 110.9, 82.4, 85.9, 101.5, 80.7, 135.1, 100.2, 120.5, 136.2)
small_kg_tow <- c(0.174, 0.255, 0.253, 0.31, 0.351, 0.612, 0.489, 0.602, 1.05, 0.715, 0.658, 0.446, 0.62, 0.724, 1.107, 0.931, 0.94, 0.78, 0.531, 1.201, 0.962, 1.414, 0.998, 1.148, 0.913, 1.154, 0.841, 1.031, 1.397, 0.908, 0.927, 0.456, 0.609, 0.481, 0.68, 0.515)
large_kg_tow <- c(2.69, 4.022, 2.328, 3.85, 1.567, 2.054, 3.077, 1.786, 2.565, 1.711, 3.258, 2.284, 1.071, 1.18, 1.912, 2.008, 2.16, 1.222, 0.968, 1.499, 1.015, 1.046, 0.731, 0.649, 0.407, 0.42, 0.25, 0.236, 0.475, 0.431, 0.648, 0.195, 0.282, 0.146, 0.276, 0.32)
stopifnot(length(landings_t)==36L,length(small_kg_tow)==36L,length(large_kg_tow)==36L)

assessment <- pacific_database_row("assessments", assessment_id=assessment_id,
  stock_id=stock_id, assessment_year=2021L, terminal_year=2020L,
  estimate_terminal_year=2020L, assessment_type="full_assessment",
  model_family="length-based age-structured model",
  model_version="2021 full assessment; Research Document 2022/041",
  is_current=FALSE, is_applied=TRUE, framework_year=NA_integer_,
  assessment_url=advice, framework_url=NA_character_, data_url=NA_character_,
  model_url=report, repository_url=NA_character_,
  assumptions_status="partial", inputs_status="partial", outputs_status="partial",
  notes=paste("Historical full assessment used for 2021 advice, with data through 2020.",
    "Detailed companion published in 2022. Separate from the current 2025 assessment;",
    "no values are transferred between the two records."))

assumption <- function(component, setting, value, notes="", reference=report) {
  pacific_database_row("assumptions", assessment_id=assessment_id,
    component=component, setting=setting, value=value,
    source_reference=reference, notes=notes)
}
assumptions <- do.call(rbind, list(
  assumption("assessment","approach","Length-based age-structured model fit by penalized maximum likelihood.",
    "Implemented in AD Model Builder; MCMC used for uncertainty.",paste0(report,"; sections 5.1-5.2")),
  assumption("assessment","advice_cycle","Full assessment used for advice in February 2021.",
    "Detailed Research Document 2022/041 published in June 2022.",advice),
  assumption("population","model_years","1985-2020","Earlier years omitted because reliable fishery catch data were unavailable."),
  assumption("population","model_ages","1-8+","Age 8 is the plus group."),
  assumption("population","initial_state","Eight initial recruitment deviations and initial F determine abundance at age in 1985.",
    "Structure only; fitted state values were not recovered."),
  assumption("recruitment","process","Age-1 recruitment equals average recruitment plus annual log-scale deviations.",
    "Normal deviations have mean zero and SD 0.2; annual deviations estimated for 1986-2020.",paste0(report,"; section 5.1")),
  assumption("F","age_year_structure","F at age is separable into year-specific fully recruited F and age selectivity.",
    "Logistic fishery selectivity differs across 1985-2008, 2009-2012 and 2013-2020.",paste0(report,"; section 5.1")),
  assumption("M","age_year_structure","M estimated for age groups 1-3 and 5-8+ in six six-year periods from 1985-1990 through 2015-2020.",
    "Age-4 M is the average of the two group values in the same period.",paste0(report,"; section 5.1")),
  assumption("M","first_period_prior","Prior means are 0.8 for ages 1-3 and 0.3 for ages 5+.",
    "Prior SDs are 0.05 and 0.025, respectively.",paste0(report,"; section 5.1")),
  assumption("q","survey_catchability","Age-specific survey q is logistic selectivity times fully recruited q.",
    "Log-q prior mean -0.3566 (q=0.7), SD 0.15.",paste0(report,"; section 5.1")),
  assumption("survey","timing","September research vessel bottom-trawl survey.",
    "The report gives the season but no fractional-year time.",paste0(report,"; section 4.1")),
  assumption("biology","length_group_mapping","Ages 1-3 map to <25 cm; ages 5+ to >=25 cm; age 4 is split evenly.",
    "Mapping based on length-at-age observations in 2000, 2007, 2013, 2015 and 2017.",paste0(report,"; section 5.1")),
  assumption("index","likelihood_weights","Small index 1.5; large index 1.65; fishery catch proportions 0.85.",
    "Weights were chosen to obtain reasonable fits to the indices.",paste0(report,"; section 5.1")),
  assumption("input","reported_data_types","Annual landings; survey indices by two length groups; landings proportions by length group; length-group weights for catch and survey; mean weight-at-age; and maturity-at-age.",
    "Only landings and the two survey-index series were numerically recovered. Numerical proportions, weights and maturity are not imported.",paste0(report,"; section 5.1")),
  assumption("survey","companion_indices","Table 8 also reports 4T and Magdalen Islands abundance indices in numbers per tow.",
    "These companion series are not represented as model likelihood inputs; the fitted model uses the two length-group indices.",paste0(report,"; Table 8")),
  assumption("output","reported_point_estimates","The report provides rounded median group estimates in prose rather than annual numerical tables.",
    "No annual uncertainty intervals or trajectories are inferred from figures.",paste0(report,"; section 5.2")),
  assumption("reference_points","biomass_definition","Bmsy proxy, USR and LRP refer to model-estimated >=25 cm biomass.",
    "The 2020 biomass is adjusted to mid-September; these are not SSB reference points.",paste0(report,"; section 6"))
))

landings <- pacific_database_row("inputs",n=36L,assessment_id=assessment_id,
  type="catch",measure="landings_biomass",basis="biomass",
  fleet="Combined 4T fishery",region="4T",year=years,year_basis="calendar_year",
  value=landings_t,unit="t",source_type="official_table",
  source_reference=paste0(report,"; Table 2, printed p. 18"),
  transformation="None; values transcribed in tonnes.",partition="landings",
  notes=paste("Recorded Yellowtail Flounder landings. The separate unspecified-flatfish",
    "series is excluded. 2019 and 2020 values are preliminary."))

survey_rows <- function(values, length_group, lower, upper) {
  pacific_database_row("inputs",n=36L,assessment_id=assessment_id,type="index",
    measure="total_biomass",basis="biomass",
    survey="September RV bottom-trawl survey",region="4T",season="September",
    year=years,year_basis="calendar_year",value=values,unit="kg/tow",
    source_type="official_table",
    source_reference=paste0(report,"; Table 8, printed pp. 28-29"),
    transformation="None; values transcribed in kg per tow.",
    notes=paste0("Per-tow survey biomass index for the ",length_group,
      " fish length group; not stock biomass."),
    length_bin=length_group,length_bin_lower=lower,length_bin_upper=upper)
}
inputs <- rbind(landings,survey_rows(small_kg_tow,"<25 cm",NA_real_,25),
  survey_rows(large_kg_tow,">=25 cm",25,NA_real_))

outputs <- pacific_database_row("outputs",n=9L,assessment_id=assessment_id,
  type=c(rep("population",4L),"biomass","biomass",rep("management",3L)),
  measure=c(rep("numbers_at_age",4L),"biomass_length_group","biomass_ratio_to_LRP","Bmsy","USR","LRP"),
  year=c(2020L,2019:2020,2020L,2020L,2020L,rep(NA_integer_,3L)),
  age_group=c("1-3","4-5","4-5","6+",rep("",5L)),
  value=c(520,95,95,3,2230,0.39,14.28,11.42,5.71),
  lwr=c(rep(NA_real_,6L),10.04,8.03,4.02),
  upr=c(rep(NA_real_,6L),20.18,16.14,8.07),
  unit=c(rep("million fish",4L),"t","ratio",rep("kt",3L)),
  source_type="official_document",
  source_reference=c(rep(paste0(report,"; section 5.2, printed p. 10"),5L),
    rep(paste0(report,"; section 6, printed p. 12"),4L)),
  notes=c(
    "Approximate reported median for ages 1-3 in 2020; no interval stated in the text.",
    "Approximate reported median; about 95 million ages 4-5 in 2019 and 2020.",
    "Approximate reported median; about 95 million ages 4-5 in 2019 and 2020.",
    "Approximate reported median for ages 6+ in 2020; no interval stated in the text.",
    "Median >=25 cm biomass in 2020, adjusted to mid-September.",
    "Source-reported >=25 cm biomass relative to its LRP; not SSB or an SSB ratio.",
    "Bmsy proxy for >=25 cm biomass; reported 95% interval.",
    "Upper stock reference for >=25 cm biomass; reported 95% interval.",
    "Limit reference point for >=25 cm biomass; reported 95% interval."
  ))

empty_stocks <- pacific_database_row("stocks",n=0L)
assessments <- utils::read.csv(file.path(root,"database","assessments.csv"),
  stringsAsFactors=FALSE,check.names=FALSE)$assessment_id
stocks <- utils::read.csv(file.path(root,"database","stocks.csv"),
  stringsAsFactors=FALSE,check.names=FALSE)$stock_id
if(assessment_id %in% assessments) stop("Historical assessment already exists; do not append twice.")
if(!stock_id %in% stocks) stop("Canonical 4T stock is missing; do not create a duplicate stock.")

if(dry_run) {
  cat(sprintf("Dry run validated one historical assessment, %d assumptions, %d inputs and %d outputs.\n",
    nrow(assumptions),nrow(inputs),nrow(outputs)))
} else {
  append_pacific_case(empty_stocks,assessment,assumptions,inputs,outputs)
  cat(sprintf("Imported the 2021 4T yellowtail flounder assessment to 2020: %d assumptions, %d inputs and %d outputs.\n",
    nrow(assumptions),nrow(inputs),nrow(outputs)))
}
