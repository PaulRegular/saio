# First source-curation batch

Selected 2026-11-02 from the screened NOAA, ICES and DFO register. The
selection uses the 90 distinct candidate units classified `new` and `eligible`
in `inventory_units.csv`; mixed-status units are held out until their
eligibility is resolved. The selection prioritizes verified age-specific input
and official-output sources. Regional and species-group coverage break ties;
there are no organization quotas. This is a source-curation batch, not a
translation-readiness ranking.

| Priority | Organization | Candidate unit | Stock | Inventory assessment year |
|---:|---|---|---|---:|
| 1 | DFO | `dfo_greenland_halibut_2_3klmno` | Greenland halibut, NAFO 2 + 3KLMNO | 2026 |
| 2 | NOAA | `noaa_stocksmart_11056` | Pacific ocean perch, Gulf of Alaska | 2024 |
| 3 | DFO | `dfo_sff_2024_gulf_yellowtail_flounder_nafo_4t` | Yellowtail flounder, NAFO 4T | 2025 |
| 4 | DFO | `dfo_western_component_pollock_4xopqrs5` | Pollock, western component | 2024 |
| 5 | DFO | `dfo_yellowmouth_bc` | Yellowmouth rockfish, coastwide BC | 2021 |
| 6 | DFO | `dfo_sgsl_winter_flounder_4t` | Winter flounder, NAFO 4T | Unspecified in inventory |
| 7 | ICES | `ices_atlantic_wolffish_iceland_5a` | Atlantic wolffish, Iceland | 2026 |
| 8 | ICES | `ices_cod_west_greenland_inshore` | West Greenland inshore cod | 2026 |
| 9 | ICES | `ices_cod_west_greenland_offshore` | West Greenland offshore cod | 2026 |
| 10 | ICES | `ices_ling_faroe_5b` | Ling, division 5.b (Faroes) | 2026 |
| 11 | ICES | `ices_her_27_nirs` | Herring, division 7.a north of 52°30′N | 2026 |
| 12 | ICES | `ices_her_27_irls` | Herring, Irish and Celtic Seas | 2026 |
| 13 | ICES | `ices_seabass_8ab` | Seabass, divisions 8.a and 8.b | 2026 |
| 14 | ICES | `ices_whg_27_7b-ce-k` | Whiting, divisions 7.b, 7.c and 7.e-k | 2026 |
| 15 | NOAA | `noaa_acadian_redfish_gom_gb` | Acadian redfish, Gulf of Maine / Georges Bank | 2025 |
| 16 | NOAA | `noaa_stocksmart_10466` | Sablefish, Pacific Coast | 2025 |
| 17 | NOAA | `noaa_stocksmart_10022` | Dover sole, Pacific Coast | 2021 |
| 18 | NOAA | `noaa_stocksmart_10426` | Yelloweye rockfish, Pacific Coast | 2025 |
| 19 | NOAA | `noaa_stocksmart_10415` | Canary rockfish, Pacific Coast | 2025 |
| 20 | NOAA | `noaa_black_rockfish_oregon_2023` | Black rockfish, Oregon | 2023 |

The initial priority 17 entry for widow rockfish was removed after confirming that its current assessment was already in the canonical database; eligible NOAA Pacific Coast Dover sole (Stock SMART 10022) replaces it. The two West Greenland cod units are separate current ICES assessment units,
not separate model variants. The selection was checked against the canonical
database after synchronization with `main`; White hake, golden redfish, and
greater silver smelt already had assessment records, so those duplicate
candidates were replaced by the three units above. Candidate screening has identified public
age-composition or age-specific inputs, biology, mortality/timing evidence,
and official outputs for each selected unit. Before each import, verify the
latest assessment used for advice, the detailed run and terminal year, the
native observation basis, units, source coverage, and whether the source files
are recoverable. The year shown above is the inventory's assessment year; it
does not replace that run-level verification. Preserve partial latest-unit
records when a series cannot be recovered. Do not substitute an older stock
definition to fill a gap.

The selected batch is recorded in `selected_batch_01_2026.csv`. Candidate
years are being refreshed against current official advice before each source
import. The Greenland halibut and GOA Pacific ocean perch source reviews and
partial database imports are recorded separately. The Greenland halibut's
2023 age-structured source is not represented as the model used for the 2026
management-procedure advice. GOA Pacific ocean perch uses the latest completed
detailed fit located for that unit, the 2023 operational update, because its
2024 estimates were projections and the scheduled 2025 full assessment was
cancelled.

Yellowtail flounder in NAFO 4T has a partial source import from DFO's 2025
assessment. The accessible 2026/022 summary supports the age-5+ biomass estimate
and recent zero-F statement, but the linked detailed Research Document 2026/054
PDF currently redirects to an archive notice. Numerical input series and
historical trajectories remain unavailable, so this case is not ready for
translation.

Yellowmouth Rockfish has a partial source import from the 2021 production assessment. It includes catch, aggregate survey biomass indices, commercial CPUE, maturity, fixed biological parameter values and composite-base reference-point quantiles. The report specifies midyear timing. Numerical age compositions and annual age-specific population outputs remain unavailable; see source_reviews/dfo_yellowmouth_2021.md.

Canary Rockfish has a partial source import from NOAA's 2023 production assessment. The native archive provides catch totals, aggregate indices, age and length composition samples, fitted age-specific outputs, and recent recruitment and spawning-output intervals. It does not provide observed catch-at-age or direct survey indices-at-age; these were not fabricated from model outputs. See `source_reviews/noaa_canary_rockfish_pacific_coast.md`.

The 2026 Celtic Sea whiting source import is partial. It includes age-specific catch, catch and stock weights, the combined Q4 VAST age-index, French commercial index, fixed M and maturity, F/N-at-age, and aggregate SSB/recruitment/Fbar with 95% endpoints. The production chapter's biology is kept distinct from alternate Stock Annex summaries. See `source_reviews/ices_whiting_7b_ce_k_2026.md`.
