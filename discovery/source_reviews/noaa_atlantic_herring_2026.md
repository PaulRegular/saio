# NOAA Atlantic herring, Gulf of Maine and Georges Bank

## Stock identity and latest assessment

NOAA Stock SMART lists Atlantic herring as stock 10572. The 2026 Management Track assessment is the latest assessment used for advice as of 2026-10-29. It is the first Management Track application of WHAM after the 2025 Research Track and uses data through 2025. The June 2026 peer review found the assessment technically sufficient and identified it as Best Scientific Information Available for management.

The assessment concerns the U.S. Gulf of Maine/Georges Bank stock complex. It is not a one-to-one match to a DFO 4VWX herring component. The U.S. model includes Canadian catches, and the peer review identifies uncertainty about the origins and mixing of U.S. and Canadian fish. Keep the NOAA candidate distinct unless further source evidence establishes a common assessment unit.

## Inputs

The run archive contains fixed- and mobile-fleet catch-age proportions for ages 1-8 in 1987-2025. These are proportions, not catch numbers-at-age. The archive does not provide the corresponding historical fleet catch totals needed to reconstruct the numerical catch-at-age series. The 2026 report gives U.S., Canadian, and combined catches only for 2018-2025.

The model uses spring and fall bottom-trawl surveys, a summer shrimp survey, and an acoustic survey. The archive plots age compositions and aggregate indices, but the numerical survey index series and survey age-composition vectors were not recovered. The acoustic index has no age-composition data in the assessment.

Annual spawning-stock and fleet weight-at-age surfaces and maturity-at-age are plotted in the run archive, but their complete numerical arrays are not supplied. The 2026 report says natural mortality is constant across ages and years without stating its value. The 2025 Research Track report gives its own model specification; that value is not substituted for an unverified 2026 input. Exact within-year survey timing was not found.

## Outputs

The 2026 report gives U.S., Canadian, and total catch, SSB, mobile-fleet mean F at ages 7-8, and age-1 recruitment for 2018-2025. It also provides annual SSB, F, and recruitment trend figures for 1987-2025 with approximate 90% intervals. Numeric N-at-age and F-at-age output matrices were not found.

The 2026 assessment report's terminal SSB value differs from the current ASMFC species page (35,258 versus 35,528 mt for 2025). Retain this source discrepancy for resolution before importing outputs.

## Screening decision

Identity is provisionally new, screening is complete, and eligibility for source curation remains unresolved. The current run archive verifies age-structured catch proportions, survey age-composition figures, biological surfaces, mortality structure, and population outputs, but key numerical input arrays and the exact mortality and timing settings are not available. Do not derive or digitize missing inputs from figures for the candidate screen. No canonical database stock, assessment, input, or output records were changed.

## Source cache

Files were retrieved on 2026-10-29 and are kept in the ignored local directory `source_cache/discovery_noaa_herring_2026/`.

| Source | Use | SHA-256 |
|---|---|---|
| [2026 NOAA SASINF archive](https://apps-nefsc.fisheries.noaa.gov/saw/sasi_files.php?year=2026&species_id=21&stock_id=6&review_type_id=6&filename=2026_HER_UNIT.zip) | Run report, input plots, compositions, results, parameter tables and diagnostics | `970F68ADA667DA8D7A9A74BA5495F8252E87AA9423143B042AF7EEBA99C99D73` |
| [June 2026 NOAA Management Track peer review](https://www.fisheries.noaa.gov/s3/2026-07/june-2026-management-track-peer-review-panel-report_508_20260710.pdf) | Official review and stock-unit context | `BA89DA5716C1F0E42AF7EAA08E0CFABEA16ED143BFD2742179875BE1CB9312BD` |
| `Atlantic_Herring_MT2026.pdf` inside the SASINF archive | Run-specific 2026 report | `17B2DF91AFC79A18A7AA4587FFCBB3F7634E108322BC696E01CB69EA061E22F6` |
| `All_inputdata.pdf` inside the SASINF archive | Input age compositions, indices, weights, and maturity plots | `682F704E637C8E26A8CC359840CDCFDC704BF8AA168DCEF173011931BE40C1BA` |
| `FixedCAA_Proportions_Table.csv` inside the SASINF archive | Fixed-fleet catch-age proportions, ages 1-8, 1987-2025 | `AE7DE1A6ECAD5CE642BB72FB25F6A4CF5B3B9ABBC7DCD98B832BD191B05316E5` |
| `MobileCAA_Proportions_Table.csv` inside the SASINF archive | Mobile-fleet catch-age proportions, ages 1-8, 1987-2025 | `D586BAABDDCC6B0C7B04267B5C908B0BFC5CE44D869ADF84A0BCD71ED4670FFD` |
| `NEFSC 2025 Herring RT Report.pdf` inside the SASINF archive | Prior research-track methods context only | `5E53FA8B4511640DD0EDB328601F837991E9083B06A69D9EE6EDE103CF7B6C18` |

The [2025 NOAA Research Track report](https://repository.library.noaa.gov/view/noaa/71350/noaa_71350_DS1.pdf) is included in the archive for model-development context only; its inputs and outputs are not substituted for the 2026 Management Track.
