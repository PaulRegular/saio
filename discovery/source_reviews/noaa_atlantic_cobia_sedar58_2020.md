# NOAA Atlantic cobia — SEDAR 58 (2020)

## Stock unit and assessment

NOAA Stock SMART unit 12149 is the Atlantic migratory cobia stock north of the Georgia-Florida border. It is distinct from Gulf of Mexico cobia (NOAA:10390). SEDAR 58 is the latest completed production assessment identified as the basis for current Atlantic cobia status. The September 2020 revised final report incorporates review changes; the CIE review identifies run co23 as the definitive base run. The assessment covers 1986–2017.

The ongoing SEDAR 107 benchmark is not a completed assessment and does not replace the SEDAR 58 production record. Its workshop material is retained as a status cross-check only.

## Sources

The revised SEDAR 58 Stock Assessment Report and the NOAA-hosted CIE review are cached locally in source_cache/discovery_noaa_sedar_current_assessments_2026/. Their URLs, retrieval dates, sizes, and checksums are recorded in the tracked provenance manifest. A local text extraction of the pinned report supports table transcription.

## Inputs captured

- Table 1 reports length and whole weight at age, female maturity, proportion female, and fixed age-varying natural mortality. The length CV is identified as estimated by the assessment.
- Table 2 reports annual commercial removals in 1,000 lb whole weight and general-recreational removals in 1,000 fish. These totals include landings and dead discards.
- Table 3 reports landings, discard components and their CVs. Commercial handline/gillnet components and general-recreational values are retained separately. The model-scale totals in Table 2 are retained as a distinct reported series; they are not treated as independent of the components in Table 3.
- Table 4 reports standardized aggregate headboat CPUE and its CV for 1991–2015. The model predicts this index from mid-year abundance; a separate fractional observation time is not stated.
- Table 5 reports sampled-fish counts for commercial length and general-recreational age compositions. Numerical composition cells are not tabulated in the report and have not been digitized or inferred.

The assessment uses commercial length compositions, general-recreational age compositions, a headboat index, and a Dirichlet-multinomial composition likelihood with estimated variance-inflation factors. Commercial age compositions were not used because the samples were not considered representative. Table 1 provides the numerical age-specific biological schedules. The report describes natural mortality as fixed over time and age-varying using the Charnov et al. (2013) relationship.

## Outputs captured

Tables 6–8 and 10–16 provide total abundance and biomass, abundance and biomass at age, recruitment represented by age-1 abundance, SSB, apical and age-specific fishing mortality, landings, and status/reference-point summaries. SSB is mature female biomass at peak spawning, reported as end of March. Table 16 provides a base-run estimate, an ensemble median, and an ensemble standard deviation for summary metrics; the SD is retained as a separate quantity and is not labeled a standard error.

Tables 6–7 include a 2018 start-of-year population state used to initialize projections. It is labeled as projection initialization; the assessment terminal year remains 2017. Age-specific uncertainty is not tabulated.

## Remaining source gaps

The report text describes model ages 1–12+, while Tables 1 and 6–13 print ages 1–16. The source does not reconcile the age-grid difference; canonical age labels are retained as printed, with the discrepancy recorded in assumptions.

The annual composition sample counts are available, but the numeric age- and length-composition likelihood cells are not published in the reviewed report. Detailed native model data files were not located. No values have been inferred from figures. Time-series uncertainty for age-specific N and F is unavailable; Table 16 is the only reviewed source of numeric ensemble SD summaries.

