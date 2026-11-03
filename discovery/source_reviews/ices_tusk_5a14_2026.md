# Tusk in ICES Division 5.a and Subarea 14 (`usk.27.5a14`)

Review date: 2026-10-30

## Unit and current assessment

The 2026 ICES inventory, advice record 7219, and Standard Graphs key 22530
identify one current unit covering Icelandic Division 5.a and East Greenland
Subarea 14. The latest detailed assessment report located is MFRI's 2026 tusk
report. It describes the 2026 production assessment as SAM and reports model
estimates through 2025; 2026 is a forecast. The 2022 ICES benchmark and MFRI's
2023 report are useful method context, but are not substitutes for current
run-matched input files.

## Screening decision

The candidate is **screened with eligibility unresolved** for the current
combined 5.a+14 unit. Public sources clearly document age-structured inputs and
outputs for Icelandic waters, but the accessible evidence does not establish a
complete age-specific data set or the model's treatment of Subarea 14.

| Component | Verified evidence | Limitation for the combined unit |
|---|---|---|
| Commercial catch-at-age | The 2026 report says commercial otolith ages are used in SAM and shows catch numbers-at-age and biomass-at-age for 5.a. Aged otoliths are reported for 1981–1983, 1985, 1987, and 1991–2025. | The report discusses 14-area landings separately and says no catch weight-at-age data are available from area 14. The current report and inaccessible annex do not show whether or how 14-area catches enter the SAM age structure. |
| Survey age information | The report presents age-disaggregated SMB spring-survey indices from 1985 and SMH autumn-survey indices from 1996. | These are Icelandic 5.a data. Exact age ranges, annual matrices, and use in the current SAM fit need the current annex or native inputs. No age-specific Subarea 14 index was verified. |
| Catch weights | The 2026 report presents commercial catch weight-at-age for 5.a. | No matching area-14 catch weight-at-age data are reported. |
| Stock weights | The 2026 report presents SMB spring-survey stock weight-at-age for 5.a since 1985. | Full-unit coverage, exact annual values, and representation of area 14 are not established. |
| Maturity | The 2026 report says maturity-at-age is calculated from SMH maturity-at-length and age-length distributions and is used to calculate spawning biomass. | This documents Icelandic 5.a biology; matching Subarea 14 inputs were not found. |
| Natural mortality | MFRI's 2023 report documents an assumed M of 0.15 per year for the age groups in its assessment. | The 2026 report refers to the 2023 stock annex for model settings, but the annex metadata has no attached file. The exact 2026 setting and its application to Subarea 14 remain unverified. |
| Timing | SMB is conducted in March, SMH in autumn, and the inshore gillnet survey in April. | Exact fractional-year timing in the current SAM inputs and any Subarea 14 timing were not recovered. |
| Official outputs | The 2026 report/ICES sources provide SSB, total stock biomass, recruitment at age 1, catch, and Fbar ages 7–10 with uncertainty. | The reviewed current sources do not provide machine-readable N-at-age or F-at-age arrays. Available reported quantities are aggregate. |

The 2023 MFRI report describes sparse historical age sampling and limited
5.a catch weight-at-age coverage; it states that no catch weight-at-age data
are available for area 14. The 2022 benchmark describes the earlier SAM
configuration and its age-specific inputs, but those numeric matrices must not
be reused as if they were the 2026 production run. The 2023 stock-annex API
record reports no attached file, and no current native input object was
recovered. This is therefore not yet source-ready as a complete 5.a+14
assessment. If current run-matched files become available, reassess the full
unit; do not silently narrow it to 5.a or extrapolate Icelandic inputs to 14.

No canonical stock, assessment, input, or output records were added.

## Sources

- [MFRI 2026 technical report](https://www.hafogvatn.is/static/extras/images/08_usk_2026_1_techreport_en.html)
- [MFRI 2026 advice](https://www.hafogvatn.is/static/extras/images/08_usk_2026_1_advice_en.html)
- [ICES 2026 Standard Graphs, key 22530](https://standardgraphs.ices.dk/ViewCharts.aspx?key=22530)
- [ICES 2026 source data](https://standardgraphs.ices.dk/ViewSourceData.aspx?key=22530)
- [ICES 2026 advice record 7219](https://asd.ices.dk/viewAdvice/7219)
- [MFRI 2023 technical report](https://www.hafogvatn.is/static/extras/images/19-tusk_tr1388162.pdf)
- [ICES WKICEMP 2022 benchmark](https://doi.org/10.17895/ices.pub.19663971.v1)
- [ICES 2023 stock-annex metadata](https://doi.org/10.17895/ices.pub.23599668.v1)

The source files, revisions, retrieval date, sizes, and SHA-256 hashes are
recorded in the gitignored local cache at
`source_cache/discovery_ices_tusk_5a14_2026/sources.csv`.
