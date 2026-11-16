# NOAA Atlantic menhaden, 2025 single-species assessment update

## Stock and run

NOAA Stock SMART ID `11089` is the Atlantic coastwide unit of Atlantic menhaden (*Brevoortia tyrannus*). The latest detailed English production assessment located is the ASMFC 2025 single-species Beaufort Assessment Model (BAM) update, with data through 2023. The concurrent SEDAR 102 ecological reference point benchmark is a separate assessment and was not used to fill gaps in the single-species run.

The partial canonical import contains 2,434 input rows, two output rows and 41 assumptions. The north/south regions are assessment data components, not separate stocks.

## Imported information

- **Landings:** Table A1 reports reduction and bait landings for 1955–2023 and recreational landings for 1981–2023 in 1,000 metric tons. Bait landings before 1985 are identified as incomplete. Recreational harvest is added to the assessment's bait fleet; the database retains it as a separate source partition within that fleet.
- **Catch age compositions:** Tables A2–A5 report numbers-based proportions at ages 0–6+ and the raw fish sample counts for north/south reduction and bait components. The database contains 1,505 reported proportion cells and 216 sample-count rows. The count is not treated as an effective likelihood sample size, so `sample_size` is blank. Table A2 has no north reduction composition in 2020 (sample count zero); the 2020 south bait values are retained as printed with a note that the report says this composition was censored from the base run.
- **No catch numbers-at-age:** The report's age proportions are not annual numbers-at-age. Multiplying a number proportion by biomass landings does not produce numbers of fish; matching catch weights-at-age would be needed to scale the proportions. The 2025 update does not provide the required current-run weight arrays, so no catch numbers-at-age are derived.
- **Abundance indices:** Table A6 contributes 172 aggregate Conn YOY, NAD, MAD and SAD index values and 172 matching CVs. The source scale has no stated physical unit or scaling multiplier, and a single fractional survey time for each combined annual index is not reported. The base run uses aggregate indices and survey length compositions, not observed survey numbers-at-age.
- **Mortality and index assumptions:** Table 2 supplies fixed M at ages 0–6+ (1.39, 1.03, 0.82, 0.71, 0.64, 0.60 and 0.57 yr-1). Table A7 supplies 24 component-survey `sigma_p` process-error SDs. The report does not state a physical unit for these component SDs. It prints “CT Long Island Sound Trawl” twice in the Age 1+ section without explaining the difference; both reported values are retained and labelled by table order.
- **Reported outputs:** Table 4 supplies terminal 2023 full F (0.26 yr-1) and total egg production (1,240,272 billion eggs). Egg production is not spawning-stock biomass. No numeric SSB, N-at-age or annual F-at-age table or fitted BAM object was found; the time series are shown mainly as figures and no uncertainty intervals accompany the two imported values.

## Remaining gaps

The current run's numeric weight-at-age, maturity-at-age and fecundity-at-age arrays for 2018–2023 were not located. Older SEDAR 69 arrays were not substituted. Updated survey length compositions, exact annual survey timing fractions, catch numbers-at-age, age-specific population outputs and uncertainty are also unavailable in the reviewed English material. The import therefore remains partial and eligibility for an age-disaggregated comparison remains unresolved.

## Sources and provenance

- [ASMFC 2025 Atlantic Menhaden Stock Assessment Update](https://asmfc.org/wp-content/uploads/2025/11/2025AtlMenhadenSingleSpeciesAssmtUpdate_October2025.pdf), especially Table 2 and Appendix Tables A1–A7.
- [SEDAR 102 final report](https://sedarweb.org/documents/sedar-102-atlantic-menhaden-and-erp-final-stock-assessment-report/), used to distinguish the concurrent ERP assessment from the single-species BAM update.
- [SEDAR 69 benchmark report reissued as SEDAR 102 RD03](https://sedarweb.org/documents/sedar102-rd-03-sedar-69-benchmark-stock-assessment-report/), reviewed for context but not used to replace missing 2025 inputs.

The reports are cached under `source_cache/noaa_atlantic_menhaden/noaa_atlantic_menhaden_2025/`. Their source URLs, revisions, retrieval dates, sizes and checksums are listed in [`provenance/noaa_atlantic_menhaden_2025/sources.csv`](../provenance/noaa_atlantic_menhaden_2025/sources.csv).
