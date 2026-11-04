# Dusky rockfish in the Gulf of Alaska

## Identity and latest assessment

NOAA Stock SMART identifier 10559 is the Gulf of Alaska dusky rockfish (*Sebastes variabilis*) unit. It is geographically and biologically distinct from dusky rockfish outside the Gulf of Alaska.

The latest full assessment located is the November 2024 SAFE assessment, recommended model m22.5a. The September 2026 SAFE chapter is a pre-dissemination peer-review harvest projection; its cover says it has not been formally disseminated by NMFS. It states that no new assessment model was run, uses updated catches to project from the 2024 assessment, and schedules the next assessment for 2027. The 2026 projection is therefore a current advice/output supplement, not a replacement for the 2024 assessment inputs or fitted time series.

The 2024 full SAFE and 2026 projection are cached locally under `source_cache/discovery_noaa_dusky_rockfish_2024/`. Its `sources.csv` records source URLs, retrieval date, byte sizes (available from local files), and SHA-256 checksums.

## Inputs and assumptions

The 2024 model fits total catch biomass in metric tonnes for 1977–2024, with fishery age compositions and fishery length compositions. The data summary lists fishery age-composition years 1998–2002, 2004–2006, 2008–2020 (biennially), and 2022. The narrative says sampled fish aged 4–66 were represented by raw age distributions from 2000–2022. This apparent difference in the age-composition year coverage needs reconciliation during source curation; it should not be silently harmonized.

The model uses bottom-trawl survey biomass from the VAST geostatistical model for 1990–2023 (tonnes, with standard errors and confidence intervals) and survey age compositions for the same years. The survey age proportions are reported for ages 4–29 and a pooled 30+ group, with input and effective sample sizes and haul counts. The model fits these components as a biomass index and composition, not as an observed age-specific biomass index.

Mean weight-at-age is derived outside the assessment model from combined-sex survey size-at-age data. The report supplies the weight-growth equation in grams with parameters W∞ = 1928 g, κ = 0.190, t0 = 0.607, and b = 3.0. The assessment fits female maturity-at-age conditionally with a logistic curve and binomial likelihood, using combined female observations cited to Lunsford (1997, personal communication) and Chilton (2010). The reported age at 50% maturity is 10.3. The SAFE shows the fitted curve in Figure 12-9 but does not tabulate the combined raw observations or the full coefficient pair.

Natural mortality is fixed at M = 0.07 per year. The report does not specify a fractional within-year survey timing, so that remains unresolved.

## Outputs and screening decision

The 2024 SAFE provides annual maximum-likelihood estimates for female spawning biomass, total age-4+ biomass, fully selected fishing mortality, and age-4 recruitment, plus MCMC means and 95% credible intervals for those quantities. It does not provide numerical N-at-age or F-at-age output surfaces. The pre-dissemination 2026 projection supplies updated catch and projected total and spawning biomass through 2031, without refitting the assessment.

**Eligible for source curation.** The official full assessment provides catch biomass, fishery and survey age compositions, survey biomass with uncertainty, weight-at-age and maturity-at-age bases, fixed natural mortality, and comparable population outputs. Before importing values, reconcile the reported fishery-age years, retrieve or document a defensible maturity source, and continue searching for the survey timing. No canonical values were added in this discovery screen.

## Sources

- [2024 GOA Dusky Rockfish SAFE chapter](https://www.npfmc.org/wp-content/PDFdocuments/SAFE/2024/GOAdusky.pdf), especially the data summary and Tables 12-7–12-14.
- [2026 GOA Dusky Rockfish harvest projection](https://meetings.npfmc.org/CommentReview/DownloadFile?fileName=12.+GOA+Dusky+Rockfish.pdf&p=ed574dbd-35fa-43dc-99f0-a80909caf4d5.pdf).
- [NOAA 2024 North Pacific Groundfish Stock Assessments](https://www.fisheries.noaa.gov/alaska/population-assessments/2024-north-pacific-groundfish-stock-assessments).
- [NOAA Stock SMART](https://apps-st.fisheries.noaa.gov/stocksmart/?app=browse_by_stock&stockid=10559).
