# NOAA invertebrate inventory records (2026 snapshot)

**Review date:** 2026-10-30  
**Source:** NOAA Stock SMART  
**Scope:** identity reconciliation and taxonomic screening only

## Records

The pinned Stock SMART snapshot identifies the following distinct NOAA stock
units. The source stock IDs and taxonomic names are retained in
`candidates.csv`; stable candidate-unit keys link each inventory row to one
unit.

| NOAA stock ID | Stock | Area |
|---|---|---|
| `10080` | Brown shrimp | Southern Atlantic Coast |
| `10082` | Pink shrimp | Southern Atlantic Coast |
| `10084` | White shrimp | Southern Atlantic Coast |
| `10087` | Giant octopus | Bering Sea / Aleutian Islands |
| `10088` | Giant octopus | Gulf of Alaska |
| `10786` | Sea scallop | Northwestern Atlantic Coast |
| `10787` | Atlantic surfclam | Mid-Atlantic Coast |
| `10792` | Longfin inshore squid | Georges Bank / Cape Hatteras |
| `10798` | Northern shortfin squid | Northwestern Atlantic Coast |
| `10802` | Royal red shrimp | Gulf of Mexico |
| `10803` | Brown rock shrimp | Southern Atlantic Coast |
| `10809` | Red king crab | Bristol Bay |
| `10810` | Red king crab | Norton Sound |
| `10811` | Red king crab | Pribilof Islands |
| `10813` | Blue king crab | Pribilof Islands |
| `10814` | Blue king crab | Saint Matthew Island |
| `10816` | Golden king crab | Aleutian Islands |
| `10817` | Golden king crab | Pribilof Islands |
| `10820` | Snow crab | Bering Sea |
| `10821` | Southern Tanner crab | Bering Sea |
| `10933` | Red king crab | Western Aleutian Islands |
| `10958` | Red deepsea crab | Northwestern Atlantic |
| `11031` | Caribbean spiny lobster | Southern Atlantic Coast / Gulf of Mexico |
| `11201` | Weathervane scallop | Alaska |
| `11843` | Spanner crab | Main Hawaiian Islands |
| `12532` | Caribbean spiny lobster | Puerto Rico |
| `12533` | Caribbean spiny lobster | St. Thomas / St. John |
| `12534` | Caribbean spiny lobster | St. Croix |
| `14841` | Golden king crab | Western Aleutian Islands |
| `14842` | Golden king crab | Eastern Aleutian Islands |

## Screening decision

These shrimp, cephalopod, mollusc and crustacean units are outside the initial
marine-finfish scope. They remain screened ineligible without review of their
assessment inputs or outputs. This is a taxonomic scope decision, not a
finding that the underlying assessments lack age data. No canonical
assessment, input, or output records were added.

The metadata snapshot is cached at
`source_cache/discovery_noaa_stocksmart/stock_assessment_summary.rda`. Its
pinned repository revision, retrieval date, URL, and SHA-256 are listed in the
adjacent `sources.csv` manifest.

## Source

- [NOAA Stock SMART](https://www.fisheries.noaa.gov/resource/tool-app/stock-smart)
