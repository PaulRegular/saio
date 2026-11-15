# NOAA South Atlantic red porgy (Stock SMART 10100)

## Unit and assessment

The NOAA Stock SMART row is therefore provisionally new, under `noaa_south_atlantic_red_porgy`.

The latest completed full assessment located is SEDAR 60, completed in April 2020 with data through 2017. The assessment used the Beaufort Assessment Model (BAM), a statistical catch-age model, over ages 1–14+ and years 1972–2017. The 2026 South Atlantic council schedule and 2027–2028 statements of work still identify SEDAR 60 as the preceding assessment and plan a later update; no completed successor assessment was located by the review date, 2026-10-29.

## Data available in the detailed report

- **Catch:** The assessment fits annual landings for commercial handline and trawl, headboat, and MRIP fleets, plus dead discards for handline, headboat, and MRIP. Table 10 reports commercial landings in 1,000 lb whole weight and recreational landings and all discards in 1,000 fish. Fishery age compositions are used for handline and headboat; trawl uses a pooled length composition because ages were unavailable. The report presents age and length composition proportions in figures rather than complete machine-readable matrices.
- **Survey:** The model fits the Southeast Regional Headboat Survey index for 1973–1998 and the combined SERFS chevron trap/video index for 1990–2017. Table 14 reports index values and CVs. SERFS chevron trap age compositions inform selectivity.
- **Biology:** Table 15 provides fixed age-specific length, mid-year weight, female proportion, maturity by sex, spawning weight, and natural mortality for ages 1–14+, with age 14 as the plus group.
- **Mortality:** Natural mortality is fixed and decreases with age using a growth-based Charnov form. It is scaled to the same survival from age 3 through age 25 as a constant M of 0.22 per year.
- **Timing:** The model is annual, and its indices are predicted from beginning-of-year abundance. Spawning is represented at February 1 (year fraction 0.167). The final assessment report does not specify a single effective within-year timing for either abundance index. The assessment also reports annual SSB, total biomass, apical fishing mortality, recruitment, age-specific fishing-mortality results, and survey/fishery fits.

## Data now recorded

The canonical database now contains the SEDAR 60 assessment and 11 assumptions. It preserves 806 source input rows: annual fleet landings and dead discards from Table 10, the fitted fixed 0.05 catch CVs, the trip and fish sample counts from Tables 12–13, aggregate survey indices and their CVs from Table 14, and the fixed age-specific biological inputs from Table 15. Table 11's year-specific CVs are not treated as fitted catch errors because the report says they were used only for the Monte Carlo/Bootstrap ensemble analysis.

The database contains 5,554 reported output rows from Tables 16–29: abundance and biomass at age, total abundance, annual SSB and status indicators, selectivity, fleet F summaries, F-at-age, fitted landings and dead discards, and selected reference quantities. Table 29 estimates, Monte Carlo/Bootstrap medians and reported SEs are kept distinct. Annual age-surface uncertainty is not supplied in these tables. Tables 30–34 (sensitivity and projection results) are not included in this historical fitted-output import.

## Remaining source gaps

Numeric age- and length-composition proportions are shown in figures and have not been digitized. The report does not give one effective within-year sampling fraction for either abundance index. Trawl age compositions were unavailable in the assessment; the trawl likelihood used length compositions. Accordingly, the source record remains partial for both inputs and outputs. No composition proportions, age-specific survey index, or survey timing are inferred.

This stock remains **eligible for source curation**. The database row links NOAA Stock SMART 10100 to SEDAR 60 and is marked partial because the report does not provide machine-readable composition proportions or annual uncertainty for population surfaces. No fishery composition or age-specific survey observations were reconstructed from fitted states.

## Cached sources

The ignored local cache is `source_cache/noaa_south_atlantic_red_porgy_sedar60_2020/`. Its SHA-256, retrieval date, size, URL and pinned report revision are recorded in `provenance/noaa_south_atlantic_red_porgy_sedar60_2020/manifest.csv`.

Sources: [SEDAR 60 Stock Assessment Report](https://sedarweb.org/documents/sedar-60-stock-assessment-report-south-atlantic-red-porgy/), [SEDAR 60 project record](https://sedarweb.org/assessments/sedar-60/), [SAFMC 2026 assessment schedule](https://safmc.net/documents/a3_species_for_2026_stock_assessments-pdf/), and [SAFMC 2027–2028 SEDAR statements of work](https://safmc.net/documents/sedar_a3_statements-of-work-for-2027-2028-sedar-stock-assessments-pdf/).
