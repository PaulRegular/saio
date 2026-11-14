# Gulf of Mexico red snapper — SEDAR 98 (2026)

## Stock unit and assessment status

NOAA Stock SMART identifier 10230 refers to the Gulf of Mexico red snapper unit. The latest detailed assessment located is SEDAR 98, whose final Stock Assessment Report was released in October 2026 and uses data through 2023. The report states that Gulf Council SSC review was still pending. The database records it as the current detailed run but does not mark it as applied for advice. Stock SMART's assessment-year field remains 2021 and is stale for this run.

SEDAR 98 models West, Central and East areas within one Gulf management unit. They are not separate stocks. NOAA:10230 is distinct from NOAA:10231, the South Atlantic Coast unit.

## Sources reviewed

The final report and supporting data papers are cached locally in source_cache/discovery_noaa_gom_red_snapper_2026/. The tracked provenance manifest records retrieval dates, source URLs and SHA-256 checksums. The PDFs are authoritative; locally generated text extracts support table transcription.

Sources reviewed include the final Stock Assessment Report and data papers DW-02, DW-03, DW-05, DW-06, DW-07, DW-09, DW-13, DW-16, DW-17, DW-19, DW-24 and DW-26. DW-13 contains smooth age-length keys and age-sample summaries, but not the numerical final-model composition arrays. No run-matched native Stock Synthesis input/output package was located.

## Imported inputs and fitted quantities

The report's Appendix Tables 23–37 provide final-model landings observations, log-scale standard errors, expected landings in numbers and biomass, and mean landings weight. Tables 38–58 provide final-model discard observations and log-scale standard errors, expected total and dead discards in numbers and biomass, and mean discard weight. Values retain the table units: landings biomass in million pounds whole weight, catch numbers in thousand fish, discard biomass in thousand pounds whole weight, and mean weights in pounds per fish. Catch partitions distinguish landings and discards; closed-season discard outputs are identified separately.

Tables 59–75 provide the final-model standardized indices, their lognormal standard errors, and fitted expected indices. The import contains 315 annual observations across 17 area-by-series combinations. The series are labelled as SEDAR 98 final-model series so they remain distinct from the 332 candidate index observations in Section II Tables 5.8.1–5.8.3. Those Section II indices and CVs remain separately preserved; they are not substituted for the series used in the final model. Index values are normalized to a mean of one. Tables 67 and 68 repeat identical rows in their continued print layout; the import retains each year once.

Table 99 provides shrimp-trawl bycatch numbers in thousand fish for West, Central and East, 1983–2023. These 123 rows are aggregate catch inputs and are not split by age, landings or discards.

The source-data imports also retain commercial landings and discard estimates, recreational landings and discards, all 546 recreational discard CV rows reported by the source, candidate aggregate survey indices and CVs, and the fixed adjusted M-at-age vector. The Appendix-table update adds 3,909 final-model input rows and 6,295 fitted output rows. Source-native observations remain distinct from final-model-scale table values. In particular, DW-02 reports commercial landings by area and gear group in pounds whole weight from 1964–2023; recreational source tables cover 1981–2023. The final report now supplies model-scale catch values for earlier years in Tables 23–37, but the underlying source-native records for those earlier years were not recovered.

The report's Tables 20–22 provide expected total biomass, exploitable biomass (ages 1+), SSB, age-1+ abundance, age-0 recruitment and SSB ratio for each area in 1950–2023. The database also includes derived 0+ total abundance, calculated as reported age-1+ abundance plus age-0 recruitment for the same area and year. Both components are rounded to the nearest thousand fish, so the derived sum inherits that rounding. Tables 12–19 provide 2,072 annual exploitation-rate outputs: a Gulf-wide rate, commercial and recreational fleet rates by area, and shrimp-trawl bycatch rates by area. These are biomass exploitation ratios, not instantaneous F or F-at-age. All these reported outputs are point estimates; the tables do not provide standard errors or intervals.

## Remaining gaps and status

The final report describes weighted catch length compositions, nominal age compositions, conditional age-at-length data, and mean length-at-age observations. The reviewed public tables provide figures, sample counts and summaries, but not the full numerical likelihood arrays used by the final run. DW-13 age-length keys and sample summaries do not recover those arrays. Numeric maturity-at-age, stock weight-at-age, age-specific population outputs and F-at-age therefore remain unavailable. Fixed adjusted M-at-age values for ages 0–20+ are imported; numerical maturity and weight-at-age surfaces are not.

The SSB-ratio denominator remains unresolved: the captions state Gulf SSB0 = 392,218.6 metric tons, but the area ratios do not equal area SSB divided by that value. Do not interpret them as directly comparable area-level SSB/SSB0 without clarification.

One stock and one assessment record represent all three model areas. The assessment remains partial because age compositions, age-specific biological surfaces, age-specific N/F, and uncertainty for reported outputs are unavailable. No missing values or scaling factors have been invented.
