# NOAA Northern anchovy central subpopulation (2021 assessment; adopted 2022)

## Identity and latest assessment

NOAA Stock SMART ID 10574 is listed as “Northern anchovy - Southern Pacific Coast” and carries assessment year 2022. The latest detailed production assessment located is the 2021 benchmark for the Northern anchovy central subpopulation (CSNA), adopted by the Pacific Fishery Management Council in June 2022. The assessment uses observations from Ensenada, southern California and central California and describes the CSNA as extending from California to northern Baja California. The official assessment year, species and geography support treating this as the run represented by Stock SMART 10574, while retaining both labels in the register notes.

The current NOAA species page says the southern stock was assessed in 2022 and that formal assessments are not conducted routinely; the PFMC coastal-pelagic SAFE listing still points to the 2021 CSNA report and model archive. No later detailed production run was found. NOAA’s “southern stock” summary wording and the assessment’s “central subpopulation” name are not identical; the crosswalk follows the identified 2022 run rather than assuming those labels are interchangeable everywhere.

No canonical *Engraulis mordax* stock record exists. The historical Charbonneau–Keith record named *E. mordax* is an erroneous species label for Iberian anchovy, *E. encrasicolus*, and is unrelated. No separate DFO northern anchovy age-structured assessment was identified.

## Inputs and model structure

The public Stock Synthesis input archive contains the control, data, forecast, starter and empirical weight-at-age files. The run models 2015–2021 in two biological semesters per year. Semester 1 covers June–December (seven months) and semester 2 January–May (five months); the assumed birth date is June 1. It uses one sex, one area and four age bins: 0, 1, 2 and 3+.

The data file includes seasonal fishery catches for two pooled MexCal fleets, in metric tonnes, with rows extending from 2000 through the 2021 model year and 2021 catch carried forward from 2020 for forecasting. Fishery age-composition proportions and sample sizes are also present for the two fleets. These are not direct catch numbers-at-age. The report documents a source-supported reconstruction: combine monthly landings, catch-weighted age proportions and mean weights-at-age, then aggregate numbers-at-age to the model semesters. The final empirical weights-at-age by fleet, year and semester are in the native weight-at-age file; the report documents averaging and cohort interpolation for missing fishery values.

The only fishery-independent likelihood data in the base model are the acoustic-trawl summer and spring biomass indices. In the native file these are biomass-unit observations with lognormal errors; the summer series covers 2015–2021 and spring surveys are available in 2017 and 2021 (mapped to the corresponding biological semesters). Survey-specific age compositions and weights-at-age are supplied. The report explains that age compositions were derived from abundance-at-length using survey-specific age-length keys, with composition sample sizes weighted by positive trawl clusters. Therefore, age-specific abundance indices can be reconstructed from the aggregate biomass index, age composition and weight-at-age, but this is a documented derivation rather than a direct age-specific index likelihood. Other index data in the archive are alternatives or supporting series and were not used in the base model.

Maturity is fixed at approximately 0.726, 0.931, 0.985 and 0.997 for ages 0, 1, 2 and 3+, respectively; fecundity is fixed at one gram of eggs per gram of body weight. The base model estimates one uniform natural-mortality parameter; the reported estimate is 0.414 per year. Steepness is fixed at 0.6 and equilibrium recruitment is estimated.

## Official outputs

The report gives numbers-at-age for the modeled year-semesters in Table 11 (thousands of fish; ages 0, 1, 2 and 3+), biomass-at-age and age-0+/age-1+ biomass in Table 12, and annual biomass summaries in Table 14 (metric tonnes). Table 13 reports SSB in metric tonnes and age-0 recruitment in thousands of fish, with asymptotic standard errors. The base-run natural mortality estimate is 0.414 per year. Apical fishing mortality by fishery is plotted, but a numerical age-specific F output table was not located.

The report states that the base model converged with total likelihood 54.444 and final gradient 4.403e-06, and that the Hessian was inverted successfully for variability estimates. Reported point estimates include the 2021 age-1+ biomass of 2,090,640 mt and projected June 2022 age-1+ biomass of 2,879,010 mt.

## Screening decision

Mark the unit new and source-curation eligible, with import still not started. The official native archive provides the age compositions, seasonal catches, weights and fixed maturity inputs, and the report gives age-structured population outputs. Catch-at-age and age-specific survey abundance require documented reconstruction from those native quantities; preserve the official likelihood inputs if the database import proceeds.

## Sources

- PFMC, [2021 Northern Anchovy central-subpopulation assessment (June 2022)](https://www.pcouncil.org/documents/2022/07/assessment-of-the-northern-anchovy-engraulis-mordax-central-subpopulation-in-2021-for-u-s-management-june-2022.pdf/).
- PFMC, [Coastal Pelagic Species SAFE and assessment listing](https://www.pcouncil.org/stock-assessments-and-fishery-evaluation-safe-documents/) and [Anchovy 2021 model-file listing](https://www.pcouncil.org/documents/anchovy-2021-model-files/).
- PFMC, [June 2022 decision summary](https://www.pcouncil.org/june-2022-decision-summary-document/).
- NOAA Fisheries, [Northern anchovy status and stock information](https://www.fisheries.noaa.gov/species/northern-anchovy).
- Cached report, native input archive and NOAA species-page copy are in the ignored `source_cache/discovery_noaa_anchovy_2021/`; file URLs, retrieval date and SHA-256 checksums are recorded in its `sources.csv` manifest.
