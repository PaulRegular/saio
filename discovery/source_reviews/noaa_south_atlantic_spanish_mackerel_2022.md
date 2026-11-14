# NOAA South Atlantic Spanish mackerel: SEDAR 78

- **Candidate:** NOAA:10174, Spanish mackerel (*Scomberomorus maculatus*)
- **Screened:** 2026-11-08
- **Decision:** Eligible; partial numerical source records were imported from the revised SEDAR 78 report.

## Stock unit and latest assessment

The selected unit is the Atlantic migratory group managed by the South Atlantic Fishery Management Council, from the New York/Connecticut/Rhode Island boundary south to the Miami-Dade/Monroe County boundary. It is distinct from the Gulf of Mexico Spanish mackerel unit and from Australian Spanish mackerel (*Scomberomorus commerson*).

The latest completed detailed assessment located for this unit is the SEDAR 78 operational Beaufort Assessment Model (BAM) run. The report was issued in May 2022 and revised in July 2022; the fitted assessment period is 1986–2020. Stock SMART has an administrative 2023 assessment listing for the stock, while the final SEDAR report documents the run as completed in 2022. In July 2023 the South Atlantic SSC found the assessment sufficient for stock-status determination and catch-level recommendations, but not for projections, and approved the equilibrium values used for those recommendations. The SSC retained concerns about natural mortality. SEDAR 110 is scheduled to begin in 2027 with a terminal year of 2026; it is not a completed replacement assessment.

The SEDAR 78 project document list and the reviewed SEDAR and NOAA catalog pages list the final report and working papers, but no fitted BAM input archive or model output object. The report itself prints extensive numeric input and output tables, so the source record can be populated from those tables while keeping the absence of native files explicit.

## Recoverable inputs

- **Landings and discards:** Table 2 reports annual series for 1986–2020. Commercial handline, gillnet, pound-net, and cast-net landings are in thousands of pounds whole weight. General recreational landings, shrimp-trawl bycatch, and general recreational discards are in thousands of fish. Commercial discard estimates were combined with their corresponding landings; general recreational discards were modeled separately with a 0.2 discard-mortality rate, and shrimp bycatch was assumed fully dead. These are the source model's catch and removal quantities, not catch-at-age observations.
- **Abundance indices:** Table 3 reports the Florida commercial handline and MRIP general-recreational indices for 1986–2020 and the SEAMAP-SA coastal-trawl age-0 index for 1989–2019, with CVs. The two fishery-dependent indices use a constant CV of 0.2 in the table; the SEAMAP CV varies by year. The assessment predicts the fishery-dependent indices from midyear abundance (biomass for handline) and the SEAMAP series as recruitment. The SEAMAP survey samples in spring, summer, and fall, so the sources do not support a single actual within-year sampling fraction.
- **Age compositions:** Tables 4–8 provide observed compositions for ages 0–10+, including trips and fish counts. Handline and cast-net compositions are pooled across years (the printed years are midpoints); gillnet, pound-net, and general-recreational compositions are reported by year. The gillnet composition is weighted using length composition; the other fitted compositions are nominal. The report describes a Dirichlet-multinomial likelihood and a minimum of more than 10 fish and at least 10 trips. These compositions are separate observations from the annual catch totals; they are not source catch numbers-at-age.
- **Biology:** Table 1 reports population, female-population, and fishery-dependent length- and weight-at-age for ages 0–10, female maturity-at-age, and fixed age-specific natural mortality. Length is in inches and whole weight is in pounds. The reported M-at-age values for ages 0–10 are 0.68, 0.46, 0.40, 0.37, 0.36, 0.35, 0.34, 0.34, 0.34, 0.34, and 0.34 per year. Natural mortality is constant through time and follows a Lorenzen schedule scaled to match survival under M = 0.35 per year from age 2 to the oldest age. The model assumes a 50:50 sex ratio and fixed steepness of 0.75.

## Recoverable outputs and interpretation limits

The report provides annual abundance-at-age (Table 9, thousands of fish), biomass-at-age (Table 10, thousands of pounds), aggregate biomass and SSB measures (Table 11), fleet fishing-mortality summaries (Table 13), age-specific instantaneous F and total mortality (Tables 14–15), total estimated landings-at-age in numbers and weight (Tables 16–17), annual landings and dead-discard totals by fleet (Tables 18–19), and total dead discards-at-age in numbers and weight (Tables 20–21). Tables 9 and 10 also print 2021 values outside the fitted 1986–2020 period; retain those only with an explicit interim/projection designation. The age-specific landings and discard series are assessment estimates, not observed catch-at-age likelihood inputs. The actual catch observations are the aggregate removals in Table 2, fitted with separate age-composition data in Tables 4–8.

Table 11 reports SSB in metric tonnes at the end of July, while the methods section describes peak spawning as June 1. Preserve this source inconsistency and do not resolve it by assumption. The report presents mixed Monte Carlo/bootstrap uncertainty for selected aggregate estimates and reference quantities, but no uncertainty arrays for the annual age surfaces. Retain only intervals and standard errors explicitly tabulated, with the report's point-estimate or ensemble-median convention recorded.

The source provides recoverable numerical inputs and comparable population, mortality, and catch outputs. Any conversion of source catches and compositions into analysis-specific catch-at-age must remain outside the canonical database; it cannot replace the official model's native input structure.

## Canonical database record

The partial record uses stock_id noaa_south_atlantic_spanish_mackerel and assessment_id noaa_south_atlantic_spanish_mackerel_2022. Inputs are transcribed from Tables 1-8: annual removals and aggregate indices with reported CVs (1986-2020, except SEAMAP YOY through 2019), observed age compositions with fish and trip sample counts, and age-specific length, weight, female maturity, and fixed M. Composition proportions remain distinct from catch numbers-at-age.

Outputs are transcribed from Tables 9-22, including annual numbers and biomass at age, F and Z at age, selectivity, aggregate status indicators, landings and dead-discard estimates, and reference quantities. The fitted period is 1986-2020; selected 2021 abundance, biomass, and status values remain labeled interim. Table 22 estimate and MCBE median/SE values are stored separately.

Assessment inputs, assumptions, and outputs are marked partial because the report does not provide the native fitted files or annual age-surface uncertainty, and source timing details remain unresolved. Age-specific landings and discards in Tables 16-21 are model outputs, not observed catch-at-age likelihood inputs.
## Sources

- [SEDAR 78 assessment page](https://sedarweb.org/assessments/sedar-78/)
- [SEDAR 78 final assessment report, revised July 2022](https://sedarweb.org/documents/sedar-78-stock-assessment-report-south-atlantic-spanish-mackerel-revised-july-2022/)
- SEDAR 78-WP01 survey methods; WP02 SEAMAP index; WP03 recreational data; WP04 shrimp bycatch; WP05 composition weighting; WP08 age-data review; WP09 MRIP index; WP11 commercial discards; and WP12 Florida trip-ticket index. Their URLs, retrieval dates, file sizes, and SHA-256 checksums are recorded in `provenance/noaa_south_atlantic_spanish_mackerel_2022_sources.csv`.
- [South Atlantic SSC July 2023 meeting output](https://sedarweb.org/documents/sedar-78-south-atlantic-spanish-mackerel-july-2023-ssc-meeting/)
- [SEDAR 110 project page](https://sedarweb.org/assessments/sedar-110-south-atlantic-spanish-mackerel/)

The cited PDFs are cached locally under the gitignored `source_cache/noaa_south_atlantic_spanish_mackerel_2022/` directory.
