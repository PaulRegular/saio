# NOAA Pacific Coast Longspine Thornyhead

## Stock identity and assessment history

NOAA Stock SMART ID 10460 is the U.S. Pacific Coast longspine thornyhead stock (*Sebastolobus altivelis*), assessed coastwide off California, Oregon and Washington. No canonical database assessment or same-unit inventory match was found. DFO also has a Pacific longspine thornyhead inventory entry, but it refers to Canadian waters and has no official stock identifier or more precise assessment area in the discovery row; it is not treated as the same U.S. stock unit.

The latest full assessment located is the 2013 length-based Stock Synthesis model. The 2019 Stock SMART year refers to a later catch-only update rather than a new full assessment. That update was circulated as a pre-dissemination draft and was used to inform harvest specifications; the 2025 Groundfish SAFE still identifies 2013 as the most recent full stock assessment. The 2013 assessment, 2019 catch-only update and 2025 SAFE are cached under `source_cache/discovery_noaa_longspine_pacific_2019/`; the ignored `sources.csv` manifest records dates, URLs and checksums.

## Inputs, assumptions and outputs

The 2013 assessment uses fishery catch and length-composition information, survey abundance indices and length data. It states that no age data are available for the assessment other than age-length observations used to estimate growth; no age-composition likelihood or annual age-specific abundance observations are reported. The model's age-structured quantities, where produced from the length-based population model, are therefore derived estimates rather than observed age inputs. The 2019 update is catch-only and adds no age-composition or survey-age observations.

The 2013 assessment fixes natural mortality at 0.1113 per year, the mean of a prior based on an assumed maximum age of 100 years. Growth uses external age-length observations; maturity and size biology are represented in the length-based model. Exact source age-specific weight and maturity vectors and within-year timing were not recovered in this screen. Reported outputs include spawning biomass/depletion, recruitment, harvest-rate and reference-point information; the 2019 update reports catch-based status and projections. Run-matched numerical N-at-age and F-at-age outputs were not verified from the public sources reviewed here.

## Decision

Screening decision: provisionally new as a distinct U.S. Pacific Coast unit, but ineligible for the age-disaggregated input set. The latest full assessment does not use age compositions or report an observed age-specific survey series, and the later 2019 run is catch-only. Age-length observations used to estimate growth and age-based quantities derived inside the model do not provide the age-indexed likelihood inputs required for this screen. The older assessment history is not substituted for the current 2013 assessment plus later catch-only update.

## References

- [2013 Stock Assessment and Status of Longspine Thornyhead](https://www.pcouncil.org/documents/2014/02/stock-assessment-and-status-of-longspine-thornyhead-sebastolobus-altivelis-off-california-oregon-and-washington-in-2013-published-january-5-2014.pdf/)
- [2019 Catch Only Update: Longspine Thornyhead](https://apps-st.fisheries.noaa.gov/sis/docServlet?fileAction=download&fileId=5969)
- [2025 Pacific Coast Groundfish SAFE](https://www.pcouncil.org/documents/2024/08/status-of-the-pacific-coast-groundfish-fishery-stock-assessment-and-fishery-evaluation-july-2025.pdf/)
