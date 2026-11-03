# First source-curation batch: selection record

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
| 14 | ICES | `ices_whg_27_7b_ce_k` | Whiting, divisions 7.b, 7.c and 7.e-k | 2026 |
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
records when a series cannot be recovered. Follow PROTOCOL.md for latest-unit selection and any separately documented fallback; never fill one run with another run's values.

The selected batch and its recorded curation status are maintained in
`selected_batch_01_2026.csv`. Source coverage and remaining gaps are documented
in [discovery reviews](source_reviews/), [assessment reviews](../source_reviews/)
and canonical completeness fields. The inventory
years above describe the original selection, not a claim that each was the
latest recoverable production run. All 20 selected rows now record partial
source imports; none is thereby declared input-complete or translation-ready.
