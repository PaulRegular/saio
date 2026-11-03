# NOAA Stock SMART 10413: Southern Pacific Coast bocaccio, 2017 fit / 2025 projection

Reviewed 2026-10-29. NOAA Stock SMART 10413 is the Southern Pacific Coast bocaccio stock, *Sebastes paucispinis*. the DFO British Columbia bocaccio unit is geographically distinct.

## Current unit and latest assessment

NOAA currently reports three bocaccio management units: Southern Pacific Coast, a northern Pacific Coast complex, and a Gulf of Alaska complex. The 2017 NOAA/PFMC update assessed the southern unit from south of 43°N to the U.S.–Mexico border, in the Conception, Monterey and Eureka INPFC areas. NOAA's 2025 document is a revised catch-only projection, not a new population-model fit: it updates observed catches for 2017–2024, uses management-team removals for 2025–2026, then projects to 2036 using the 2017 model's relative fishing mortality. NOAA's current stock page still reports the Southern Pacific Coast unit separately. Amendment 37 proposed a coastwide definition in 2026, but it remains under NMFS review; do not treat that proposal as an implemented unit change.

## Age-specific inputs and model assumptions

The 2017 update carries forward the 2015 assessment's age information; no new fish were aged for the 2017 update. The 2015 assessment aged more than 8,000 fish, including nearly 3,000 from the NWFSC bottom-trawl survey. The age data were fitted as conditional age-at-length (CAAL), not as direct marginal catch-at-age counts. The population model has two sexes and ages 0–21, six fishery fleets, and ten abundance indices. Commercial fishery and NWFSC bottom-trawl age-at-length records provide age-specific information. Catch totals and length compositions are also present, so a catch-at-age series may be reconstructed only after the conditional age-at-length and expansion denominators in the native model data are verified.

The 2017 update retained fixed length-weight, maturity and fecundity relationships from 2015. Growth was estimated as in 2015. Natural mortality was estimated with a lognormal prior, without age, time or sex variation. The 2025 projection reuses the fitted 2017 population model and does not add age observations or refit biological parameters. The model is annual; observation timing for the individual indices should be read from the native input during source curation.

The 2017 assessment reports spawning output, recruitment and exploitation/status trajectories. The 2025 catch-only projection gives spawning output and stock-status estimates for the updated catch/projection path through 2036. Its outputs are projections from the 2017 fit, not new estimated population states. The published reports do not provide numeric annual N-at-age and F-at-age tables; the 2017 model archive includes the native data and control files but no fitted output files.

This unit is eligible for source curation because the current official age-structured fit contains observed CAAL data, aggregate abundance indices, biological inputs, mortality assumptions and official population outputs. no catch-age reconstruction has been imported or presumed complete.

## Sources and cache

- [PFMC 2017 bocaccio assessment update](https://www.pcouncil.org/documents/2017/02/stock-assessment-update-status-of-bocaccio-sebastes-paucispinis-in-the-conception-monterey-and-eureka-inpfc-areas-for-2017.pdf)
- [PFMC 2017 bocaccio model files](https://www.pcouncil.org/documents/2017-bocaccio-model-files-zip-file-47-kb/)
- [NOAA 2025 revised catch-only projection](https://www.pcouncil.org/documents/2025/08/g-3-attachment-18-catch-only-projection-for-bocaccio-in-2025.pdf/)
- [NOAA bocaccio stock information](https://www.fisheries.noaa.gov/species/bocaccio)
- [NOAA Amendment 37 stock-definition action](https://www.fisheries.noaa.gov/action/amendment-37-pacific-coast-groundfish-fishery-management-plan-stock-definitions)

The 2017 report, 2017 model archive and 2025 projection are cached under the gitignored `source_cache/discovery_noaa_bocaccio_southern_pacific_2017/`; `sources.csv` records their retrieval dates, URLs and SHA-256 checksums. The model archive contains `boc1.ctl`, `boc1.dat`, `forecast.ss`, and `starter.SS`.
