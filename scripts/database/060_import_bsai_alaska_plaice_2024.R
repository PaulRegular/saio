source("scripts/database/pacific_tables.R")
source("scripts/database/pacific_ss.R")
id <- "afsc_alaska_plaice_bsai_2024"
cache <- "source_cache/afsc_alaska_plaice_bsai"
revision <- jsonlite::fromJSON(file.path(cache, "repository_revision.json"))$sha
repository <- "https://github.com/afsc-assessments/BSAI_Alaska_plaice"
reference <- paste0(repository, "/tree/", revision, "/2024/Models/Model_24.1b")
report <- "https://files.npfmc.org/SAFE/2024/BSAIplaice.pdf"
dat <- r4ss::SS_readdat(file.path(cache, "native/data_echo.ss_new"), verbose = FALSE)
path <- file.path(cache, "native/Report.sso")
times <- pacific_ss_section(path, "TIME_SERIES ")
n <- pacific_ss_section(path, "NUMBERS_AT_AGE report:")
n <- n[n$Era == "TIME" & n$`Beg/Mid` == "B" & n$Seas == 1, ]
f <- pacific_ss_section(path, "F_AT_AGE report:")
f <- f[f$Era == "TIME", ]
biology <- pacific_ss_section(path, "Biology_at_age_in_endyr ", 2)
derived <- pacific_ss_section(path, "DERIVED_QUANTITIES ", 4)
times <- times[times$Era == "TIME", ]
ages <- 0:25
years <- 1975:2024
stopifnot(dat$Ngenders == 2, dat$Nages == 25, dat$N_areas == 1,
  nrow(n) == 100, nrow(f) == 100,
  times$Bio_all[times$Yr == 2024] == 394455,
  times$SpawnBio[times$Yr == 2024] == 147511)

input <- function(type, measure, basis, value, unit, year = NA_integer_, age = NA_integer_,
                  sex = "combined", fleet = "", survey = "", ...) {
  pacific_database_row("inputs", assessment_id = id, type = type, measure = measure,
    basis = basis, value = value, unit = unit, year = year, age = age, sex = sex,
    region = "BSAI", fleet = fleet, survey = survey,
    year_basis = ifelse(is.na(year), "", "calendar_year"), source_type = "native_model",
    source_reference = reference, ...)
}
catch <- dat$catch[dat$catch$year %in% years, ]
index <- dat$CPUE[dat$CPUE$year %in% years, ]
inputs <- rbind(
  input("catch", "total_biomass", "biomass", catch$catch, "t", catch$year,
    fleet = "Fishery", notes = "Annual total dead catch; native log-SD is retained in assumptions."),
  input("index", "total_biomass", "biomass", index$obs, "t", index$year,
    survey = "Survey", sampling_time = (index$seas - 1) / 12,
    notes = "Combined-sex EBS bottom-trawl biomass; fixed herding-adjusted q=1.2."),
  input("index", "log_index_sd", "log_scale", index$se_log, "log SD", index$year,
    survey = "Survey", notes = "Supplied lognormal survey SD; no extra observation-SD parameter activated."),
  pacific_ss_compositions(dat, "age", id, reference, "BSAI"),
  pacific_ss_compositions(dat, "length", id, reference, "BSAI"),
  input("M", "natural_mortality_at_age", "per_year", .13, "per year", age = rep(ages,2),
    sex = rep(c("female","male"),each=26), notes = "Fixed in both sexes, phase -3."),
  input("maturity", "maturity_at_age", "proportion",
    c(rep(0,6),.02,.06,.16,.37,.63,.84,.94,.98,.99,rep(1,11)), "proportion",
    age = ages, sex = "female", notes = "Supplied empirical female age-maturity vector, control maturity option 3. Spawning month 1.")
)
output <- function(type, measure, value, unit, year = NA_integer_, age = NA_integer_,
                   sex = "combined", se = NA_real_, ...) {
  pacific_database_row("outputs", assessment_id = id, type = type, measure = measure,
    value = value, unit = unit, year = year, age = age, sex = sex, se = se, region = "BSAI",
    source_type = "native_model", source_reference = reference, ...)
}
surface <- function(x, type, measure, unit, notes) {
  do.call(rbind,lapply(1:2,function(sex) {
    z <- x[x$Sex == sex, ]
    m <- as.matrix(z[as.character(ages)])
    output(type, measure, as.vector(m), unit, rep(z$Yr,26), rep(ages,each=nrow(z)),
      sex = c("female","male")[sex], age_group = rep(c(rep("",25),"25+"),each=nrow(z)), notes = notes)
  }))
}
std <- function(label, year) derived$StdDev[match(paste0(label,"_",year), derived$Label)]
outputs <- rbind(
  surface(n, "population", "numbers_at_age", "million fish", "Begin-year MPD, separate sexes. Native weights are grams: million fish times grams yields tonnes; verified against Bio_all."),
  surface(f, "mortality", "fishing_mortality_at_age", "per year", "Native total F by sex/age/year. No state SEs supplied."),
  output("biomass", "total_biomass", times$Bio_all, "t", times$Yr,
    notes = "Native all-age Bio_all, not Bio_smry age 3+. MPD."),
  output("biomass", "biomass_by_age_group", times$Bio_smry, "t", times$Yr,
    age_group = "3+", notes = "Native Bio_smry; retain separately from Bio_all."),
  output("biomass", "SSB", times$SpawnBio, "t", times$Yr,
    sex = "female", se = std("SSB",times$Yr), notes = "Female January 1 MPD spawning biomass; natural-scale marginal ADMB SE; no intervals invented."),
  output("recruitment", "recruitment", times$Recruit_0, "million fish", times$Yr, 0,
    se = std("Recr",times$Yr), notes = "Age-0 MPD recruitment; natural-scale SE when reported. Main recruitment deviations end in 2019; later years follow source forecast/bias rules.")
)
for (sex in 1:2) {
  z <- biology[biology$Sex == sex, ]
  for (metric in c(weight_at_age="Wt_Beg",catch_weight_at_age="Wt_Mid")) {
    measure <- names(c(weight_at_age="Wt_Beg",catch_weight_at_age="Wt_Mid"))[match(metric,c("Wt_Beg","Wt_Mid"))]
    outputs <- rbind(outputs, output("biology",measure,z[[metric]],"g/fish",year=2024,age=z$int_Age,
      sex=c("female","male")[sex],
      notes="Computed from estimated growth and fixed weight-length parameters, not an original supplied weight vector. Time-invariant in this run; beginning-year population versus mid-year catch/survey weights."))
  }
}
assume <- function(component, setting, value, sex = "", fleet = "", survey = "", notes = "") {
  pacific_database_row("assumptions", assessment_id=id, component=component,
    setting=setting,value=value,sex=sex,fleet=fleet,survey=survey,
    source_reference=reference,notes=notes)
}
assumptions <- do.call(rbind,list(
  assume("assessment","official_model","2024 Model 24.1b, SS 3.30.22; final December 2024 SSC selection"),
  assume("population","dimensions","1975-2024, ages 0-25+, female/male, one BSAI area; fixed recruitment sex ratio 0.5"),
  assume("N","process","Deterministic survival; initial abundance informed by early recruitment deviations back to 1950; equilibrium historical F=0"),
  assume("recruitment","process","Beverton-Holt steepness fixed at 1 (constant recruitment mean); sigmaR fixed 0.4243 after tuning; IID log deviations 1975-2019; later forecast/bias-adjustment rules"),
  assume("F","process","Unpenalized annual F intensity; sex-specific age selectivity, time-invariant ascending double-normal family; no F random-walk likelihood"),
  assume("M","process","Fixed 0.13 for both sexes; phase -3"),
  assume("q","process","Fixed ln q=0.182322 (q approximately 1.2), phase -2; no time variation",survey="Survey"),
  assume("catch","observation_model","Annual biomass lognormal likelihood; separate joint-sex length and age multinomial compositions",fleet="Fishery"),
  assume("index","observation_model","Biomass lognormal with supplied SD; joint-sex multinomial length/age compositions",survey="Survey"),
  assume("biology","growth","Six estimated von Bertalanffy parameters; linear below age 3; sex-specific length CVs fixed (female .13/.071, male .048/.069). read body-weight input=0."),
  assume("biology","weight_length","grams = a * length_cm^b; female a=.008007,b=3.13574; male a=.0146952,b=2.93648; fixed phases -3"),
  assume("biology","SSB_definition","January 1 female biomass times empirical maturity; spawning month 1"),
  assume("observation","sample_size_multipliers","Length: fishery 1, survey .14693; age: fishery 1, survey .2749; all active composition likelihood lambdas=1"),
  assume("outputs","units","Native numbers are million fish; computed weights are g/fish; biomass and catch tonnes",notes="Independent sum of sex-specific N times beginning-year weights agrees with Bio_all at native print precision.")
))
stock <- pacific_database_row("stocks",stock_id="afsc_alaska_plaice_bsai",
  charbonneau_id="AFSC_BSAI_Pleuronectes_quadrituberculatus",authority="NOAA-AFSC",
  authority_stock_id="BSAI Alaska plaice",scientific_name="Pleuronectes quadrituberculatus",
  common_name="Bering Sea/Aleutian Islands Alaska plaice",area="Eastern Bering Sea assessment area",
  region="Alaska",ocean="Northeast Pacific",notes="One BSAI management-stock case, preserving its EBS assessment extent and both sexes.")
assessment <- pacific_database_row("assessments",assessment_id=id,stock_id="afsc_alaska_plaice_bsai",
  assessment_year=2024,terminal_year=2024,estimate_terminal_year=2024,
  assessment_type="full",model_family="Stock Synthesis",model_version="3.30.22, Model 24.1b",
  is_current=TRUE,is_applied=TRUE,assessment_url=report,framework_url=report,
  data_url=reference,model_url=reference,repository_url=repository,
  assumptions_status="partial",inputs_status="partial",outputs_status="partial",
  notes="Final SSC-selected Model 24.1b. Both sexes and native joint compositions retained. Growth is estimated internally; computed weights are outputs. Full state covariance and some control details remain unexported.")
append_pacific_case(stock,assessment,assumptions,inputs,outputs)
