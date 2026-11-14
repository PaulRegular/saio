# Snapper (SNA 1), 2023 assessment

## Stock unit and assessment

SNA 1 is one Fisheries New Zealand management unit with three modeled areas: East Northland (ENLD), Hauraki Gulf (HAGU), and Bay of Plenty (BPLE). The 2023 assessment used a single-area East Northland model and a separate Hauraki Gulf/Bay of Plenty model. The selected 1968 Hauraki Gulf/Bay of Plenty base model fixed movement between the two areas at zero after movement estimates caused difficulty estimating B0 and initial fishing mortality. The three modeled areas are not separate management units.

The detailed assessment is FAR 2024/47, for work completed in 2022 and 2023. The May 2025 Fisheries Assessment Plenary identifies 2023 as the latest assessment. The assessment uses Casal2, ages 1-30 with age 30 as the plus group, two annual time steps, and a terminal fishing year of 2021-22.

## Sources and provenance

The reviewed PDFs are cached under the ignored source_cache/mpi_snapper_sna1_2023/ directory. Their URLs, retrieval date, and SHA-256 checksums are recorded in provenance/mpi_snapper_sna1_2023_sources.csv.

- [FAR 2024/47, assessment of SNA 1 in 2022 and 2023](https://fs.fish.govt.nz/Doc/25775/FAR-2024-47-Assessment-of-SNA1-stocks%20in-2022-and-2023.pdf.ashx) documents catch histories, model inputs, assumptions, and outputs.
- [FAR 2022/24, SNA 1 and SNA 2 age composition in 2019-20](https://fs.fish.govt.nz/Doc/25280/FAR-2022-24-Snapper-Age-Composition-SNA1-SNA2-201920-4267.pdf.ashx) provides age composition, bootstrap CV, sample count, and weight-at-age tables.
- [FAR 2023/41, bottom-trawl CPUE to 2020-21](https://fs.fish.govt.nz/Doc/25557/FAR-2023-41-Snapper-CPUE-For-Hauraki-Gulf-And-East-Northland-Trawl-Fisheries-To-202021-4414.pdf.ashx), [FAR 2021/08, 2019-20 trawl surveys](https://fs.fish.govt.nz/Doc/24856/FAR-2021-08-Hauraki-Gulf-2019-Bay-Of-Plenty-2020-Trawl-Surveys-4125.pdf.ashx), and [FAR 2022/10, 2020-21 trawl surveys](https://webstatic.niwa.co.nz/library/FAR2022-10.pdf) describe the CPUE and survey series.
- The [May 2025 SNA 1 Fisheries Assessment Plenary](https://fs.fish.govt.nz/Doc/26109/snapper-sna-1-fisheries-assessment-plenary-may-2025-volume-3.pdf.ashx) confirms the assessment year and summarizes stock status.
- FAR 2024/69 contains 2022-23 age samples published after the represented assessment; it is retained as later context and is not imported as an input to the 2023 run.

## Imported inputs

FAR 2024/47 Tables Appendix 14-16 provide catch mass by year and fleet for East Northland, Hauraki Gulf, and Bay of Plenty. The database preserves 1,845 rows for source years 1900-2022, in tonnes, with the source fleet codes and regional distinctions. The report describes the terminal assessment period as 2021-22. These are catch-mass histories, not catch numbers-at-age. The source values include its stated catch adjustments and apportioned foreign longline catches; recreational catch remains a separate fleet.

Four spring-winter 2019-20 composition series were imported from FAR 2022/24 Appendix 10: Bay of Plenty bottom trawl, Hauraki Gulf Danish seine, Bay of Plenty Danish seine, and Bay of Plenty modular harvest system. Each series retains proportions by age 1-29 and the source >29 group stored at age 30, plus the source bootstrap CV and number aged by age. The printed proportions are retained without renormalization. Table 40 of FAR 2024/47 lists these fleets and model year 2020. These composition observations are not catch-at-age numbers or abundance indices.

Five Petersen-tag population estimates for fish 25-40 cm were imported where values are reported: East Northland model years 1985 and 1994; Hauraki Gulf model years 1984 and 1995; and Bay of Plenty model year 1995. The model-year mapping follows Tables 33 and 40; source tagging years are retained in notes. The East Northland and Hauraki Gulf 1985 new-boundary estimates were reallocated in the report using the 1994 area ratio. The source lognormal CVs are 0.3 for the 1985 tagging estimates and 0.2 for the 1994 estimates. The Bay of Plenty 1983 absolute-biomass tagging input listed in Table 40 has not been numerically recovered and is not inferred.

The fixed age-1-30 natural mortality vector is 0.075 per year. The fixed maturity vector is 0 at ages 1-3, 0.5 at age 4, and 1 at ages above 4.

## Assumptions documented in the assessment

The assessment fixes stock-recruit steepness at 0.85. It uses area-specific length-weight functions and mean length-at-age matrices for 1989-2021, applying mean growth rates outside that range. The complete annual model weight-at-age matrices are not tabulated in the reviewed material.

East Northland bottom-trawl CPUE is assigned a fixed CV of 0.31, carried forward from the 2022 assessment. Research-trawl indices have an additional process CV of 0.1. Composition observations use a multinomial likelihood based on analytical CVs and Francis TA1.8 reweighting. Strong penalties prevent predicted fishery-available biomass from falling below the catch history.

## Reported outputs

For the East Northland 1968 base model, Table 36 reports median B0 of 55,873 tonnes (95% interval 50,953-61,892) and median 2021-22 SSB/B0 of 0.38 (95% interval 0.29-0.46). Table 37 reports median fishing-pressure U of 0.057 (95% interval 0.039-0.085), compared with a U reference of 0.052.

For the Hauraki Gulf/Bay of Plenty 1968 base model, Table 43 reports B0 of 449,476 tonnes and 2021-22 SSB of 143,832 tonnes (SSB/B0 0.32) for Hauraki Gulf; and B0 of 222,603 tonnes and SSB of 31,164 tonnes (SSB/B0 0.14) for Bay of Plenty. Tables 44 and 46 report median U of 0.031 (95% interval 0.027-0.036) for Hauraki Gulf and 0.08 (95% interval 0.07-0.11) for Bay of Plenty. The report does not tabulate intervals for the Table 43 biomass values.

Tables 45 and 47 list Hauraki Gulf and Bay of Plenty base-case SSB values of 142,878 and 31,685 tonnes, respectively. These differ from the Table 43 values. Both published table values are retained under separate scenario labels; the reviewed report does not explain the difference.

Table 48 separately reports combined Hauraki Gulf/Bay of Plenty fishing-pressure U of 0.041 (95% interval 0.036-0.046), with a U reference of 0.050. Annual numerical N-at-age, F-at-age, M-at-age, and recruitment series were not found in the reviewed tables.

## Remaining source gaps

The numeric fitted CPUE series and age-specific research-survey abundance indices are not present in the reviewed assessment tables. Only one recent year of four commercial age-composition series has been transcribed; the full composition histories, including survey and recreational samples, remain unavailable. The complete annual area-specific weight-at-age matrices and the Bay of Plenty 1983 tagging biomass observation remain unresolved. Most annual age-specific population outputs are shown in figures rather than numerical tables, and their underlying values and uncertainty are unavailable.
