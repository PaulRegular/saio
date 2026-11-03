# NOAA Pacific Coast Darkblotched Rockfish

## Stock identity and assessment selection

NOAA Stock SMART ID 10562 is the U.S. Pacific Coast darkblotched rockfish unit, *Sebastes crameri*, managed coastwide from Washington through California. No matching canonical tinyAM stock or other inventory candidate was found. This U.S. unit is not the same management record as Canadian waters occupied by the species.

Stock SMART's latest metadata row is assessment year 2025. The PFMC identifies the 2025 activity as a catch-only projection; the latest detailed full age-structured assessment remains the 2017 update of the 2015 model. It uses data through 2016 and was accepted for management advice. The 2019 catch update and later catch-only projections retain the 2017 assessment assumptions and do not constitute newer fitted age-structured assessments. The full 2017 report and the run-matched model archive are cached in `source_cache/discovery_noaa_darkblotched_2017/`; the ignored `sources.csv` manifest records retrieval dates and hashes.

## Inputs and outputs in the selected run

The official Stock Synthesis 3.30.01.12 archive contains the data, control, forecast and fitted `Report.sso` files. The model spans 1915–2016, has one annual season, two sexes and population ages 0–45 (age 45 is the accumulator). The supplied age-composition bins are 0–35. The model uses three catch fleets whose catches are biomass observations, and a table of four survey fleets. Three survey index series are active in the data file; the NWCBO fleet's 2003–2014 index rows are commented out. Active survey observations are recorded in July (month 7), while the fleet table specifies 0.5 timing; retain both source conventions pending a translation-specific timing review.

The run includes marginal fishery age compositions and survey conditional age-at-length data. Catch numbers at age and age-specific survey abundance are not stored as direct annual vectors in the data file; they can be reconstructed from the fleet catch totals or active aggregate biomass indices and run-matched composition information, with age-specific weights handled explicitly. The control file contains the biological relationships used to derive weight and maturity at age. The assessment fixes female natural mortality and estimates male natural mortality. These inputs support a source-curation eligibility classification, while any tinyAM-specific reconstruction remains downstream and must be documented.

The fitted `Report.sso` includes numbers-at-age, biomass-at-age, catch-at-age and Z-at-age output sections, along with the spawning-output and recruitment series. The assessment report gives depletion and management outputs. These are run-matched official outputs; the 2019 and 2025 catch-only projections should be retained separately if curated, not substituted into the 2017 fit record.

## Decision

Screening decision: provisionally new and eligible for source curation. The detailed 2017 run provides the original age-composition likelihood inputs, biology and comparable fitted age-specific outputs. No numerical assessment data have been imported into the canonical database yet; `import_status` remains `not_started`.

## References

- [2017 assessment report (update of the 2015 model)](https://www.pcouncil.org/documents/2018/01/status-of-the-darkblotched-rockfish-resource-off-the-continental-u-s-pacific-coast-in-2017-update-of-2015-assessment-model.pdf)
- [PFMC groundfish assessment and model-file archive](https://www.pcouncil.org/stock-assessments-star-reports-stat-reports-rebuilding-analyses-terms-of-reference/groundfish-stock-assessment-documents/)
- [2019 catch update, documenting the 2017 run and the update/projection distinction](https://www.pcouncil.org/documents/2019/09/agenda-item-h-5-attachment-20.pdf)
- [2025 Groundfish SAFE review table, listing Darkblotched Rockfish as a catch-only projection](https://www.pcouncil.org/documents/2025/08/ssc-groundfish-subcommittee-2025-groundfish-stock-assessment-report-2.pdf/)
- [2026 stock-definition analysis, retaining the coastwide stock and identifying 2017 as the assessment year](https://www.fisheries.noaa.gov/s3/2026-02/am-37-fpa-analysis-01-2026.pdf)
