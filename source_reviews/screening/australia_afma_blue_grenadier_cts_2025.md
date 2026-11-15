# Blue grenadier, Commonwealth Trawl Sector: 2025 assessment

## Assessment unit and run

The canonical stock is the Commonwealth Trawl Sector (CTS) blue grenadier stock. It is a single assessment stock with spawning and non-spawning sub-fisheries. The separate Great Australian Bight Trawl Sector stock is not part of this assessment; the 2023 Australian stock-status report states that the CTS and GABTS are distinct biological stocks and that GABTS has no quantitative assessment. The AFMA CTS map labels the area around southern Australia and Tasmania with the Southern Ocean and Tasman Sea; the database uses the multi-basin label `Southwest Pacific and Southern Ocean` for this stock.

The 2026 AFMA SESSF species summary identifies the 2025 run as the latest assessment update and the 2022 run as the last full technical assessment. The 2025 run was used for the 2026–27 recommended biological catch (RBC). Meeting minutes report catch and age data through 2024, and CPUE, discard-mass, and length-composition data through 2023. The available current-run material does not identify the assessment software version or provide native input, output, or model files; the canonical model family is therefore recorded as unknown. The 2022 assessment is represented by its own historical record and is not used to fill any 2025 input or output gaps.

The 2026 summary is inconsistent about the management tier: its page 114 stock-status table labels the 2025 assessment Tier 1, while the detailed page 115 discussion says SERAG recommended Tier 2 after noting retrospective patterns and applies a 5% discount to the RBC. The source records preserve the reported recommendation and discount, while the source review flags the unresolved label difference.

## Inputs and assumptions recovered

- The 2025 assessment includes catch and age information through 2024; CPUE, discard mass, and length-composition data extend through 2023. The numerical series and sample-level inputs are not published in the sources recovered here.
- SESSFRAG recommended that the 2025 acoustic base case use historical biomass estimates from 2003–2010 and the modern series from 2019–2024, excluding 2019 and 2022. Thus the retained modern years are 2020, 2021, 2023, and 2024. The meeting record describes 2019 and 2022 as affected by poor timing and unstable aggregations.
- The 2026 summary describes a two-sex age-structured base case, fixed steepness of 0.75, estimated recruitment from 1974–2019, female 50% maturity at 63.7 cm, and estimated natural mortality of 0.238 per year for females and 0.248 for males. It does not give uncertainty or a complete age-specific biology surface.
- The current sources do not report numerical catch and age arrays, weights-at-age, a complete maturity schedule, within-year survey timing, or software version. Predecessor values from 2022 were not copied into the 2025 record.

## Outputs imported

The AFMA 2026 species summary reports revised current-assessment spawning biomass at 107% of B0 for 2022 and 112% for 2023. SERAG's October 2025 minutes give projected 2026 spawning biomass at 99.5% of virgin female spawning biomass; the 2026 summary rounds this to 100%. The same summary reports 2025-base-case virgin female spawning biomass of 42,626 tonnes and sex-specific M estimates of 0.238 and 0.248 per year.

The 2026 summary also reports annual RBC projections of 17,744, 15,459, and 13,727 tonnes for 2026–2028, a three-year mean of 15,643 tonnes, a 782-tonne Tier 2 discount, estimated discards of 218, 209, and 205 tonnes, and a provisional 2026–27 TAC of 14,650 tonnes. It describes the long-term RBC as approximately 8,300 tonnes, including 185 tonnes of discards. The database records these separately as assessment or management outputs and preserves the source's approximation. None has an uncertainty interval in the recovered source.

The sources do not provide numerical annual age-specific abundance, fishing mortality, or natural mortality surfaces. No intervals or standard errors have been inferred.

The 2025 assessment row remains current and partial. The source record does not substitute 2022 inputs or model outputs for missing current-run data.

## Source files cached locally

The following files are in the gitignored `source_cache/australia_afma_blue_grenadier_2025/` folder. SHA-256 values were calculated after download on 2026-11-05.

| File | Use | SHA-256 |
|---|---|---|
| `afma_sessf_species_summaries_2026.pdf` | Latest assessment year, current biomass ratio table, stock structure | `17427157044D117DB608886DAAC102F037CD414A1E297B51E7C2D2239A54ADB3` |
| `afma_serag1_october_2025_minutes.pdf` | Current run's supported base case and projected 2026 biomass | `126CD9990509FD044F3D789AF27C3FDA8529B9A05331DE756E51FB2234C91971` |
| `afma_sessfrag_data_meeting_2025_minutes.pdf` | Acoustic survey years retained and excluded in the base case | `804F5E045FD66F69FF6000128D1B075D51AD6ED40B26893E28FC8BC86E4EE304` |
| `afma_blue_grenadier_2022_detailed_assessment.pdf` | Prior detailed assessment, retained for historical reference only | `D5D2614F5C6C73BCD2AD971E4D44C13FE189FE6DED71379A59F24BA5F033557A` |
| `afma_commonwealth_trawl_sector_map_2021_25.pdf` | CTS geographic extent and basin context | `7F5CFB7F7F665BE6FBFA85EE1A6422D270578F34D2F43CA23F3E1C959C198AB8` |

## Sources

- AFMA, [2026 SESSF Species Summaries](https://www.afma.gov.au/sites/default/files/2026-01/SESSF-Species-Summaries-2026.pdf), Blue Grenadier section, p. 114.
- AFMA, [SERAG 1 Meeting 2025 minutes](https://www.afma.gov.au/sites/default/files/2026-01/SERAG-1-Meeting-2025-minutes.pdf), Item 5.
- AFMA, [SESSFRAG Data Meeting 2025 minutes](https://www.afma.gov.au/sites/default/files/2026-02/SESSFRAG-Data-meeting-2025-minutes.pdf), Item 5, Recommendation 3.
- AFMA, [Stock Assessment for Blue Grenadier 2022](https://www.afma.gov.au/sites/default/files/2025-02/stock-assessment-for-blue-grenadier-2022.pdf), previous detailed assessment; not used as the source of 2025 values.
- AFMA, [Commonwealth Trawl Sector 2021–25 Bycatch and Discard Workplan](https://www.afma.gov.au/sites/default/files/2023-02/Commonwealth%20Trawl%20Sector%202021-25%20Bycatch%20and%20Discard%20Workplan.pdf), Appendix A map.
- ABARES, [Blue Grenadier 2023 stock status report](https://fish.gov.au/report/314-Blue-Grenadier-2023?jurisdictionId=1), stock-unit cross-check.
