# NOAA Northern anchovy central subpopulation — 2021 assessment

## Stock unit and assessment

NOAA Stock SMART ID 10574 is labelled “Northern anchovy - Southern Pacific Coast.” The latest detailed production assessment located is the PFMC 2021 benchmark for the Northern anchovy central subpopulation, adopted in June 2022. The assessment uses observations from Ensenada, southern California, and central California and describes the population as extending from California to northern Baja California. The stock record keeps the Stock SMART label and the assessment’s central-subpopulation identity together.

No later detailed production run was located. NOAA’s current species page says the southern stock was assessed in 2022, while the PFMC assessment listing continues to link to this 2021 benchmark and its native model files. The assessment is recorded as applied for advice. The historical Charbonneau–Keith Engraulis mordax label is Iberian anchovy (E. encrasicolus) and is not a match.

## Sources and provenance

The PFMC assessment report, model archive, and NOAA species-page snapshot are cached under the ignored source_cache/discovery_noaa_anchovy_2021/ folder. The tracked manifest at provenance/discovery_noaa_anchovy_2021/sources.csv gives retrieval dates, URLs, pinned source descriptions, and SHA-256 hashes for the report, archive, web snapshot, and each extracted native model file.

Sources:

- PFMC, [Assessment of the Northern Anchovy Central Subpopulation in 2021](https://www.pcouncil.org/documents/2022/07/assessment-of-the-northern-anchovy-engraulis-mordax-central-subpopulation-in-2021-for-u-s-management-june-2022.pdf/), adopted June 2022.
- PFMC, [Anchovy 2021 model files](https://www.pcouncil.org/documents/anchovy-2021-model-files/).
- NOAA Fisheries, [Northern anchovy species information](https://www.fisheries.noaa.gov/species/northern-anchovy).

## Inputs and assumptions recovered

The native Stock Synthesis files specify model years 2015–2021, two biological semesters, one modeled sex, one area, and ages 0, 1, 2, and 3+. Semester 1 covers June–December and semester 2 January–May; the birth date is June 1.

The import preserves the two pooled MexCal fleet catches and the native catch_se values for both semesters from 2000–2021, including four year -999 initialization placeholders kept separate from calendar observations. Catch units are metric tonnes. The model report documents reconstructing catch numbers-at-age from landings, age proportions, and weights-at-age; no reconstructed catch-at-age series is presented as a direct observation in the database.

All 64 native index observations and their log-scale standard deviations are retained across the seven index fleets. The base model’s likelihood uses the acoustic-trawl summer and spring indices; the other series in the native data file are alternative or supporting indices. Index unit codes and the raw source time codes are preserved in row notes. The report and native files do not establish an exact within-year sampling fraction, so the sampling_time field is blank. The aggregate indices, survey age compositions, and weights-at-age could support a documented age-specific index reconstruction, but no such derived series is represented as a directly observed index.

The native data file contains 21 age-composition records and 20 length-composition records. Their cell values, age-error codes, sample sizes, source month/part codes, and fleet identities are preserved. Age 3 is the 3+ group. The report says fishery age-composition sample sizes were divided by 25 and survey sample sizes were weighted by positive trawl clusters. Several supplied composition rows sum slightly below one; the original values are retained without normalization. Negative fleet codes on the length compositions are preserved and identified as excluded from the likelihood.

The 460 records in wtatage.ss provide 1,840 fleet-, year-, semester-, and age-specific input values, including beginning- and mid-season population weights, fleet-specific weights, and the maturity-times-fecundity series. The control file supplies fixed maturity of 0.726, 0.931, 0.985, and 0.997 for ages 0, 1, 2, and 3+. Six age-error definitions are preserved as paired mean-age and standard-deviation vectors. The base run estimates uniform natural mortality; Table 16 reports 0.414 per year at fixed steepness 0.6. The maturity-times-fecundity rows are not interpreted as maturity proportions.

## Outputs and remaining gaps

The import transcribes Tables 11–15 and base-run parameter estimates from Table 16:

- Table 11: numbers-at-age by model year and semester, in thousands of fish.
- Table 12: biomass-at-age and age-0+/age-1+ biomass by model year and semester. The biomass totals reconcile with Table 14 within printed rounding.
- Table 13: January SSB and June age-0 recruitment, with the source asymptotic standard errors. Model-year 2022 entries are projections beyond the 2021 data terminal year.
- Table 14: June 1 age-0+ and age-1+ biomass, in metric tonnes.
- Table 15: annual Mexico, USA, and total exploitation rates, defined as calendar-year landings divided by June total biomass. These are not instantaneous fishing mortality.
- Table 16: base-run M, log-q, log-R0, recruitment-regime deviation, and total negative log likelihood at steepness 0.6.

The assessment reports point estimates for abundance and biomass at age without annual uncertainty in Tables 11–14. SSB and recruitment have asymptotic standard errors in Table 13. A numeric age-specific F output table was not found; the report shows apical F by fishery graphically. No F-at-age values or uncertainty intervals have been inferred.

The source record remains partial. The missing numeric F-at-age output, exact survey timing fractions, and direct catch-at-age series are unresolved; the input source values and all recovered report outputs are retained without filling those gaps.
