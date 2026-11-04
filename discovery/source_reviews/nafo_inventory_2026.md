# NAFO stock inventory and screening

Inventory reviewed: 2026-11-04. This is a source-discovery review, not a canonical data import. It records current NAFO management/advice units found in the official stock lists, links exact overlaps to existing SAIO/DFO units, and screens their latest detailed assessment for public age-disaggregated inputs and comparable outputs.

## Inventory scope and sources

The 2026 NAFO stock-advice page distinguishes full assessments from interim monitoring. The broader Stocks and Advice table records stock units and advice history since 2017, including units without a new full assessment in 2026. The 2026 SCR index was used to identify the latest available detailed reports. Coastal requests are retained as separate units where NAFO identifies separate inshore areas.

Primary inventory sources:

- [NAFO 2026 Stock Advice](https://www.nafo.int/Science/Science-Advice/Stock-advice)
- [NAFO Stocks and Advice, 2017-2026](https://www.nafo.int/Science/Stocks-Advice)
- [NAFO species and management areas](https://www.nafo.int/Science/Science-Advice/Species)
- [NAFO 2026 SCR documents](https://www.nafo.int/Library/Science-Council/Scientific-Council-SC-SCR/ArtMID/1428/ArticleID/2233/2026-Scientific-Council-Research-SCR-Documents)

A stock code in official_stock_id is the NAFO area designation transcribed from the source (for example, cod.3M), not a numeric NAFO identifier. Source-list coverage is not treated as proof that an age-based likelihood was used. The current scope is marine finfish and elasmobranchs. Shrimp and squid entries are retained in the register as scope exclusions so the inventory accounting remains transparent.

The 27 register rows comprise 22 finfish management/advice units and five non-finfish entries. This is a source-list count, not a count of independent datasets or eligible translations. Four finfish candidates meet the current source-curation screen; one further eligible row is an exact match to an existing DFO canonical unit. No NAFO numeric inputs or outputs were imported in this inventory phase.

## Screened units

| NAFO unit | Latest detailed assessment located | Screen | Cross-inventory treatment and main limitation |
|---|---|---|---|
| Cod 3M | 2026 Bayesian SCAA; data through 2025 | Eligible | New source-curation candidate. Catch-at-age is missing in 2002-2005; age-length key and maturity ogive from 2020-2022 are carried forward for 2023-2025. Annual summer survey timing would require a documented within-year approximation. |
| Cod 3NO | 2021 ADAPT/VPA; population inputs through 2019 | Eligible | New candidate. No catch-at-age was estimated for 2020, and the assessment identifies commercial sampling as a continuing weakness. No newer full age-based run was found in the current NAFO advice inventory. |
| Beaked redfish 3M | 2023 XSA (accepted advice); 2024 source-data report | Eligible | New candidate. The accepted assessment combines S. mentella and S. fasciatus. Golden redfish is not a separate fitted model; its advice is based on its recent catch share. Verify the run-specific data cut and native files before import. |
| American plaice 3LNO | 2021 ADAPT/VPA; interim monitoring in 2026 | Eligible, with a major output caveat | New candidate. The assessment authors accepted the model for trends, not absolute population estimates, because of residual patterns, retrospective behavior, poor fit and instability. Keep this caveat attached to any later comparison. |
| American plaice 3M | 2026 update | Ineligible | No recent age-length keys; age-dependent data and analyses were not updated. The older assessment is not substituted for the current data cut. |
| Redfish 3LN | 2026 assessment | Ineligible | Index-based assessment with no analytical age-structured population model. Exact match to DFO candidate nafo_redfish_3ln. |
| Redfish 3O | 2025 assessment | Ineligible | Survey-index assessment without age-specific population outputs. Exact match to DFO candidate nafo_redfish_3o. |
| Yellowtail flounder 3LNO | 2025 assessment | Ineligible | Bayesian Schaefer biomass model; no current age-specific population inputs or outputs. Exact match to DFO candidate dfo_yellowtail_flounder_3lno. |
| Witch flounder 3NO | 2024 assessment | Ineligible | Bayesian Schaefer biomass model, not an age-structured population assessment. Exact match to DFO candidate dfo_witch_flounder_3no. |
| Capelin 3NO | Current monitoring | Ineligible | No current age-structured population model. The historic acoustic series ended in 1994; current bottom-trawl indices do not cover this pelagic stock fully. |
| Thorny skate 3LNO+3Ps | 2024 detailed report; 2026 advice cycle | Ineligible | Survey/index and length information only; no age-based population model. Exact match to DFO candidate nafo_thorny_skate_3lnops. |
| White hake 3NO+3Ps | 2023 detailed report; 2026 advice cycle | Ineligible | No current age-structured population model or age-specific output. Exact match to DFO candidate nafo_white_hake_3nops. |
| Witch flounder 2J+3KL | 2022 assessment, detailed report published as DFO ResDoc 2025/080 | Ineligible | Age data have been unavailable since 1994; current assessment relies on research-vessel survey and length indicators. NAFO references the Canadian assessment and does not provide a separate model. |
| Greenland halibut SA2+3KLMNO | NAFO management uses MSE/HCR; DFO age-based assessment is 2025 | Matched, eligible in the existing record | Exact match to canonical DFO unit dfo_greenland_halibut_2_3klmno. This is one assessment dataset, not a second NAFO dataset. |
| Greenland halibut SA0+1 offshore | Aggregate production/SPiCT assessment; 2026 data-availability report | Ineligible | No age-specific likelihood or N/F-at-age output verified. Exact match to existing DFO candidate greenland_halibut_sa0_1_offshore. |
| Greenland halibut 1A inshore, Disko Bay | 2026 monitoring | Ineligible | Separate inshore unit; survey and fishery indicators, no fitted age-structured population model. |
| Greenland halibut 1A inshore, Upernavik | 2026 monitoring | Ineligible | Separate inshore unit; survey and fishery indicators, no fitted age-structured population model. |
| Greenland halibut 1A inshore, Uummannaq | 2026 SPiCT evaluation | Ineligible | Aggregate surplus-production model, not an age-structured model. |
| Demersal/deep-sea redfish SA1 | 2026 assessment | Ineligible; identity remains ambiguous | Data-limited monitoring unit without an analytical age-based model. The combined Sebastes label overlaps species/areas in ICES and DFO records; no one-to-one crosswalk is claimed. |
| Wolffish SA1 | 2026 assessment | Ineligible | Survey-based monitoring without an analytical age-structured population model. The combined NAFO advice unit is retained as one row rather than split by species. |
| Roughhead grenadier SA2+3 | Current monitoring | Ineligible | No current age-structured population model or comparable age-specific output located. Older age samples alone do not establish current model inputs. |
| Splendid alfonsino 6G | 2025 advice/monitoring | Ineligible | No current age-structured population model or comparable age-specific output located. |
| Northern shrimp units (3M, 3LNO, SA0+1, Denmark Strait/East Greenland) | Current NAFO inventories | Outside finfish scope | Four invertebrate units retained as explicit scope exclusions. |
| Northern shortfin squid SA3+4 | Current NAFO inventory | Outside finfish scope | Cephalopod unit retained as an explicit scope exclusion. |

## Crosswalk decisions

The following NAFO entries crosswalk to existing DFO records and therefore do not create additional stock units: redfish 3LN; redfish 3O; yellowtail flounder 3LNO; witch flounder 3NO; thorny skate 3LNO+3Ps; white hake 3NO+3Ps; Greenland halibut SA0+1 offshore; and Greenland halibut SA2+3KLMNO. The last is linked to the canonical DFO record; the other seven share existing DFO candidate-unit keys and retain their current identity and screening status.

NAFO's witch flounder 2J+3KL entry refers to the Canadian DFO assessment rather than a separate NAFO model. The DFO report identifies age data as unavailable since 1994. NAFO's 2024 report records no new information. It is recorded as one source-discovery candidate, not as a separate NAFO assessment result.

The NAFO SA1 redfish row is deliberately left ambiguous. The official label combines demersal/deep-sea Sebastes over an area overlapping multiple other records. The 3M beaked-redfish assessment is a distinct unit and should not be merged with SA1. Golden redfish 3M is not entered separately because NAFO does not fit an independent golden-redfish model for that advice.

Cod 2J3KL appears in NAFO Council proceedings as a Canadian assessment requested for inclusion in an annex. It remains the existing DFO canonical unit dfo_cod_2j3kl, not a separate NAFO stock or assessment.

## Eligibility interpretation and next source-curation work

Eligibility here means that a detailed public source supports age-specific assessment inputs, biological quantities and comparable population outputs. It does not mean all arrays are machine-readable, that uncertainty is complete, or that a tinyAM translation is ready. Before curation, cache and checksum the relevant PDFs/native files, pin the assessment run, verify survey dates and units, and inspect the exact accepted model inputs.

The four new candidates to prioritize are Cod 3M, Cod 3NO, beaked redfish 3M and American plaice 3LNO. Cod 3M has the most recent and complete age-based assessment, with known catch-age and carried-forward biology gaps. Cod 3NO is older and lacks its terminal catch-age year. The 3M redfish XSA needs confirmation of accessible accepted-run inputs. American plaice 3LNO has extensive age-specific data but its accepted model is explicitly unsuitable for interpreting absolute population estimates. Do not rank their scientific usefulness until source files and model outputs are checked.
