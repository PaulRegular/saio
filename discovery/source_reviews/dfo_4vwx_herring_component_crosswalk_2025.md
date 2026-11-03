# DFO Maritimes Atlantic herring component crosswalk

Reviewed 2026-10-29 against the latest 4VWX update, the 2022 assessment, the
2018 evaluation and the public framework-input reports. Source files and a
pinned operating-model archive are already cached under
`source_cache/ck_dfo_mar_harengus_4vwx/`; their URLs and checksums are listed in
that folder's `accessible_sources_manifest.csv`.

## Identity

The 2025 DFO update describes four 4VWX management components: Southwest Nova
Scotia/Bay of Fundy (SWNS/BoF), Coastal Nova Scotia, Offshore Scotian Shelf
banks, and Southwest New Brunswick migrant juveniles. The first three are
spawning components in the existing canonical `ck_dfo_mar_harengus_4vwx`
management-unit record, which already contains the 2025 component indicators.
These inventory rows are therefore crosswalked to that one existing record;
they are not three new stock records.

The Southwest New Brunswick weir fishery is different. Its ages 1–3 fish are a
mixed migrant aggregation, historically dominated by fish from NAFO Subarea 5,
and are excluded from the 4VWX quota. Mature age-4+ fish in the fishery are
considered to be 4WX origin. The inventory entry is a fishery component, not a
separate population unit. It is left identity-ambiguous and is not added as a
stock.

## Assessment and data evidence

The latest published source is DFO Science Response 2025/026, an interim index
update through 2024. It reports landings and component-level acoustic
indicators. The latest full assessment is the 2022 assessment: SWNS/BoF used a
management-strategy-evaluation framework, while the other components continued
to rely on indicators from the 2018 evaluation. The 2018 evaluation describes
the stock-wide advice as indicator-based rather than a single analytical
age-structured production fit.

The 2019 data-input report documents commercial catch and age data, acoustic
surveys and biology. Public operating-model conditioning material has
age-based inputs for SWNS/BoF only, with catch-at-age through 2018; DFO states
that production reference operating models were conditioned through 2020.
The public archive contains scripts and inputs but no saved fitted operating
model state surfaces. It is not a complete run-matched population assessment
for all 4VWX components. The 2025 update supplies no fitted age-specific
population or mortality outputs.

For SWNS/BoF, Coastal Nova Scotia and the Offshore Scotian Shelf, identity is
matched to the existing 4VWX canonical management record, but age-structured
eligibility remains unresolved: current component indicators and historical
age inputs are documented, while a current accepted production age-model input
set and comparable fitted outputs were not verified. The Offshore Scotian
Shelf had no systematic acoustic surveys after 1998 and the 2025 update reports
no new information for evaluating it.

The Southwest New Brunswick migrant-juvenile row is ineligible as a distinct
age-structured population assessment. Its reported landings are not an
abundance index and no separate assessed population or comparable population
outputs were found.

No new canonical stock or assessment was created. Existing 2025 component
indicator data remain attached to `ck_dfo_mar_harengus_4vwx`.

## Sources

- DFO. 2025. *4VWX Herring Stock Status Update to 2024*. Science Response
  2025/026. https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/4130293x.pdf
- DFO. 2022. *2022 Assessment of 4VWX Herring*. Science Advisory Report
  2022/050. https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41087719.pdf
- DFO. 2020. *2018 Evaluation of 4VWX Herring*. Research Document 2020/062.
  https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/40951686.pdf
- DFO. 2020. *2019 4VWX Herring Framework Data Inputs*. Research Document
  2020/028. https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/40946265.pdf
- DFO. 2023. *Framework for Conditioning SWNS/BoF Herring Operating Models*.
  Research Document 2023/022.
  https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41206903.pdf