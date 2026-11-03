# Charbonneau–Keith Master catalogue import

## Source and scope

The metadata snapshot is the `Master.csv` file from the [Age-structured marine fish database](https://github.com/JulieCharbonneau/Age-structured-marine-fish-database), pinned to revision `7e4daca3cbfc14ce7fa0b28ed824eebe7113249b`. It was retrieved on 2026-10-17 from the [revision-specific raw file](https://raw.githubusercontent.com/JulieCharbonneau/Age-structured-marine-fish-database/7e4daca3cbfc14ce7fa0b28ed824eebe7113249b/Master.csv). The local gitignored copy is `source_cache/charbonneau_keith/Master.csv`; its MD5 is `430d85ba1f4144fc87bca098c8090699` and SHA-256 is `52FA158B197574B45B92D485D738E1DC7D62A4904315AEEF90C0EDB526E449ED`. The manifest records the URL, retrieval date, checksum and revision.

The pinned file contains 102 rows and 102 unique `unique_ID` values. This differs from the 101-row count anticipated in the task plan; the import follows the source file and represents all 102 identifiers once. This is catalogue metadata only. The catalogue’s historical model flags and labels do not establish that any record is a current official production assessment.

## Import and crosswalk

The importer is `scripts/database/071_import_charbonneau_master.R`. It uses the source scientific name, assessor code, `unique_ID` area suffix and PDF label. It does not import the catalogue’s model flags, estimated quantities or status fields. All 102 source identifiers are now present exactly once in `stocks.csv`: 27 were linked to existing stock rows and 75 were added as metadata-only rows, increasing the stock table from 37 to 112 rows. The other four canonical database tables were not changed.

For the 27 existing records, the Master `unique_ID` is now the `charbonneau_id`; any previous identifier is retained in the stock note as an alias. The reviewed crosswalk is explicit in the importer and requires both scientific-name and regional-basin agreement. The importer rejects stale or duplicate matches rather than dropping them silently. Its focused test checks the crosswalk, area preservation, provenance notes, duplicate protection, rerun stability and that imports leave assessment, assumption, input and output tables unchanged.

New `stock_id` values are stable slugs of the Master `unique_ID`, prefixed with `ck_`. Common names and authority-specific stock codes are left blank when the catalogue does not provide them. Area is taken from the `unique_ID` suffix, retaining the source text. Regional basin is assigned from assessor family: AFSC to Northeast Pacific; ICES to Northeast Atlantic; and DFO/NEFSC families to Northwest Atlantic. AFSC rows use `Alaska` as region; other rows use the assigned basin as their broad region. These regional labels are a reproducible catalogue classification, not a claim that the Master file supplies a normalized basin field. No Northwest Pacific entries occur in this snapshot.

## Identity limitations retained

- The initial import flagged nine possible overlaps. Three non-sex-specific cases remain unresolved: NEFSC summer flounder area, NEFSC 5Y haddock variant and ICES western Baltic herring subdivisions 22–24. The six Alaska sex-specific entries have since received the relationship review below. They retain separate catalogue identifiers but are not additional current assessment cases.
- `ICES-WGCSE_merlangus_CS7a` has the source assessor code `ICES-WGSCE`. Both values are retained in its note rather than silently correcting the identifier.
- `AFSC_ macrocephalus_BSAI` is linked to the existing Eastern Bering Sea cod record based on its legacy identifier and PDF label, although the Master area suffix says `BSAI`. This discrepancy is explicitly recorded in the stock note; confirm it against an assessment source before using the catalogue row as assessment identity.
- `ICES-WGHANSA_mordax_SP9a` misnames the Iberian European anchovy stock as *Engraulis mordax*. The [southern anchovy review](ices_anchovy_gulf_cadiz.md) verifies *E. encrasicolus* and the 2024 split into western and southern stocks. The original ID and area remain on the historical combined row; the new southern stock does not inherit that Master ID. The importer permits this correction only for that exact identifier, without treating the two species as synonyms.

These exceptions are visible in `stocks.csv` and the importer crosswalk. They do not add assessments, assumptions, numerical inputs or outputs. Stock-specific production assessment curation remains governed by the corresponding stock source review.

The [2024 Georges Bank cod review](nefsc_cod_georges_bank.md) also distinguishes
`NEFSC-GARMIII_morhua_GB` from the revised 2023 GB unit. The latter excludes
statistical areas 521 and 526 and is now `nefsc_cod_georges_bank`; the older
Master ID remains on its historical wider unit. The US assessment combines
US/Canadian catch information but is separate from the Canadian Eastern GB
assessment. This boundary relationship does not copy data across stock rows.

## Reviewed historical and sex-specific relationships

`scripts/database/156_review_catalogue_stock_relationships.R` records ten
catalogue relationships to five already curated stocks. It updates only
stock names and explanatory notes, preserving original stock IDs, Master
identifiers, scientific names, area suffixes and basin labels. It does not
assign a combined stock's current authority code to a historical component,
copy observations or outputs, or create an assessment event.

| Master identifiers | Related current stock | Source evidence |
|---|---|---|
| `ICES-WGBFAS_harengus_BS 30`, `ICES-WGBFAS_harengus_BS 31` | `ices_herring_gulf_bothnia` | [WGBFAS 2026, section 4.3](https://literatur.thuenen.de/digbib_extern/dn071152.pdf) explicitly records the 2017 merger of the two herring assessment units. |
| `ICES-WGBFAS_platessa_BS 21-23`, `ICES-WGBFAS_platessa_BS 24-32` | `ices_plaice_baltic_21_32` | [WKBPLAICE](https://doi.org/10.17895/ices.pub.28400255), held in October 2024 and published in 2025, merges the two assessment units into subdivisions 21–32. |
| `AFSC_stomias_BSAI-Females`, `AFSC_stomias_BSAI-Males` | `afsc_arrowtooth_flounder_bsai` | [2022 SAFE](https://apps-afsc.fisheries.noaa.gov/Plan_Team/2022/BSAIatf.pdf), model description and Table 6.16: one BSAI stock with female/male states. |
| `AFSC_quadrituberculatus_BSAI-Females`, `AFSC_quadrituberculatus_BSAI-males` | `afsc_alaska_plaice_bsai` | [2024 SAFE](https://files.npfmc.org/SAFE/2024/BSAIplaice.pdf), Model 24.1b: one BSAI management stock assessed in the Eastern Bering Sea, with both sexes. |
| `AFSC_polyxystra_EEBSAI-Females`, `AFSC_polyxystra_EEBSAI-Males` | `afsc_northern_rock_sole_ebs` | [2024 SAFE](https://files.npfmc.org/SAFE/2024/BSAIrocksole.pdf), analytic approach and Tables 8.23–8.24: one BSAI management stock assessed in the Eastern Bering Sea, with both sexes. |

These are relationships between catalogue entries and current stock coverage,
not assertions that old and current model runs, boundaries or data are
identical. In particular, the Alaska assessment-area qualifications remain
explicit. The original catalogue rows still have no independently curated
historical assessment data. The combined Baltic stocks retain blank Master
IDs because neither is a one-to-one match to a single historical component.
Original authoritative PDFs are cached with retrieval details and checksums
under the corresponding current assessment directories; the plaice benchmark
is also cached under `source_cache/ck_ices_wgcse_platessa_is7e/`.

This review adds no completed translations or successful fits. Arrowtooth
flounder remains source-blocked, northern rock sole's translation has failed
numerical checks, and Alaska plaice's current translation remains an
approximation. The herring and Baltic plaice source reviews retain their
own limitations. Reviewed relationships prevent counting empty component
rows as ten additional distinct current assessments while leaving genuine
source gaps visible.
