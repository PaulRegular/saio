# Northern rockfish in the Gulf of Alaska

## Unit and current assessment

NOAA Stock SMART ID 10417 is the Western/Central Gulf of Alaska (GOA) northern rockfish unit (*Sebastes polyspinis*), distinct from BSAI Stock SMART ID 10416. Neither unit appears in the canonical stock table, and no matching ICES or DFO candidate was found.

The latest detailed full assessment available at the review date (2026-10-29) is the 2024 SAFE chapter, with author-preferred model m24 and data through 2024. The 2025 catch report says no assessment was conducted in 2025 and rolled the previous model forward for specifications. The June 2026 SSC review plan schedules a GOA Northern Rockfish update assessment for December 2026; that future update was not yet available on the review date. The 2026 chapter listing and fall review materials do not identify a newer completed GOA Northern Rockfish model.

The 2024 full SAFE chapter, 2025 GOA catch report and June 2026 SSC review plan are cached under `source_cache/noaa_northern_rockfish_20261029/`; `sources.csv` records retrieval dates, URLs and checksums.

## Inputs and source screen

The m24 assessment reports commercial catch biomass in tonnes for 1961–2024. Fishery age compositions are available for 1998–2002, 2004–2006, every other year from 2008–2020, and 2022. The model also uses fishery length compositions. Catch-at-age is not supplied as a direct observed series; a composition-year reconstruction from total catch biomass and age proportions is possible but must document the chosen catch and weight bases.

Survey biomass is available for 1990–1999 (triennial), 2001–2021 (biennial) and 2023. Survey age compositions are available for 1990–1999 (triennial), 2003–2021 (biennial) and 2023. An age-specific survey index can be reconstructed from the aggregate biomass and corresponding age compositions; it is not the native aggregate-index likelihood. The m24 model uses updated survey biomass treatment and age-specific biological schedules. Weight-at-age is derived from survey growth and length-weight information for combined sexes. Maturity is an updated age ogive based on Conrath (2019) and earlier studies; the 2024 report describes the model's biological inputs. Exact age vectors and age-grid endpoint should be verified during extraction.

Natural mortality is estimated; the preferred m24 estimate is approximately 0.0595 and the report includes an M prior. Exact within-year timing remains unresolved; a fractional-year value has not been recovered.

## Outputs and eligibility

The 2024 m24 assessment reports age-specific population abundance, age-2 recruitment, age-2+ total biomass, female spawning biomass and mortality estimates. Key population time series include uncertainty intervals. These outputs and the input structure make the GOA unit provisionally eligible for source curation, with catch-at-age and age-specific survey index marked as documented reconstructions. No values have been imported into the canonical database.

Sources:

- [2024 GOA full assessment](https://files.npfmc.org/SAFE/2024/GOAnork.pdf)
- [2025 GOA catch report](https://meetings.npfmc.org/CommentReview/DownloadFile?fileName=C4+GOA+2025+Catch+Reports.pdf&p=f6b9ff85-9a04-46e3-a7ce-0c2a09b6ccee.pdf)
- [2026 SSC assessment review plan](https://meetings.npfmc.org/CommentReview/DownloadFile?fileName=F+2026+Groundfish+Stock+Assessment+SSC+Review.pdf&p=2aa31081-76e1-4025-af01-e17fd99ba0d6.pdf)
