# Bank rockfish, California: 2010 DB-SRA screen

**Screened:** 2026-10-31  
**Unit:** NOAA Stock SMART 10448, Bank rockfish - California  
**Scope:** Source discovery only; no canonical records were added.

## Assessment identity and history

NOAA Stock SMART identifies assessment 11866 as a full-acceptance 2010 DB-SRA
run, with data through 2009. PFMC's detailed 2022 data inventory also calls
2010 the most recent data-limited assessment. NOAA's 2026 Amendment 37 analysis
separately cites a 2000 California-only bank-rockfish stock assessment. These
references appear to distinguish the 2010 harvest-limit DB-SRA from the older
species-specific stock assessment, but the full 2000 report could not be
retrieved: the cited Pacific Council URL returned 404 on 2026-10-31. The
screening decision is based on the fully documented 2010 DB-SRA and does not
assume that its age data represent the older model's inputs.

## Inputs and biology

The 2010 DB-SRA uses aggregate catch history and prior distributions for
life-history and stock-status quantities. It does not fit catch numbers-at-age,
age compositions, weights-at-age, maturity-at-age, or survey abundance-at-age.
The 2022 PFMC data inventory reports 5,064 commercial age readings across all
available years, but reports zero California commercial age readings since
2000. Those biological samples are not annual age-specific observations in the
2010 harvest model.

The DB-SRA uses maximum age 73 and a point natural-mortality estimate of 0.080
per year to define its mortality prior. It uses age at maturity 13 years as a
life-history input to time-lagged productivity. These scalar prior inputs do not
constitute age-specific M or maturity surfaces. The report presents catch and
OFL quantities in metric tonnes; the assessment has no survey observation
timing.

## Outputs and screening decision

The 2010 report gives average catch in 2008-2009 of 94.3 mt, median OFL for
2010 of 585.0 mt, and a 0.09 probability that recent catch would exceed the OFL.
These are harvest-analysis outputs, not population trajectories from an
age-structured fit. No annual N-at-age, F-at-age, recruitment or spawning
biomass series was located for the 2010 DB-SRA.

**Screening decision:** Ineligible for the age-disaggregated source set. The
latest NOAA Stock SMART run is a catch-based DB-SRA with life-history priors,
not an age-structured assessment with age-specific observations. The age
readings described in the data inventory were not used as annual age-series
inputs to this run. Keep the 2000-versus-2010 assessment-history discrepancy
visible; do not substitute inaccessible historical details for the documented
2010 run.

## Sources

- [NOAA Stock SMART](https://apps-st.fisheries.noaa.gov/stocksmart) — candidate 10448, assessment 11866, year 2010, data through 2009, DB-SRA, full acceptance; snapshot is cached under `source_cache/discovery_noaa_stocksmart/`.
- [NOAA Technical Memorandum SWFSC-460 (2010)](https://www.pcouncil.org/documents/2010/06/estimates-of-sustainable-yield-for-50-data-poor-stocks-in-the-pacific-coast-groundfish-fishery-management-plan-noaa-technical-memorandum-noaa-tm-nmfs-swfsc-460-june-2010.pdf/) — DB-SRA methods, life-history priors, catch histories and 2010 OFL results.
- [PFMC 2022 detailed data summary for 2023 assessments](https://www.pcouncil.org/documents/2022/05/f-3-attachment-4-detailed-summary-of-available-data-to-support-west-coast-groundfish-stock-assessments-in-2023-electronic-only.pdf/) — most recent assessment label and age-sample counts.
- [NOAA Amendment 37 Phase 2 analysis (2026)](https://www.fisheries.noaa.gov/s3/2026-02/am-37-fpa-analysis-01-2026.pdf) — identifies the 2000 California-only assessment in its assessment history.
- [Bank Rockfish 2000 assessment](http://www.pcouncil.org/wp-content/uploads/Bank_Rockfish_2000_Assessment.pdf) — cited by NOAA/PFMC sources but unavailable at that URL on 2026-10-31.

The three retrieved PDFs are cached locally under
`source_cache/discovery_noaa_bank_rockfish_california/`; `sources.csv` records
their revisions, retrieval date, byte counts and SHA-256 checksums. The source
cache is gitignored.
