# Arrowtooth flounder off the US West Coast

## Stock unit and current assessment

NOAA Stock SMART candidate 10005 is the US West Coast management/assessment unit covering California, Oregon, and Washington. The 2017 assessment explicitly treats those states as one unit and distinguishes it from British Columbia, the Gulf of Alaska, and the Bering Sea/Aleutian Islands. No matching canonical US West Coast stock record was found. The assessment identifies the species as *Atheresthes stomias*; Stock SMART lists *Reinhardtius stomias*, which is inconsistent with the official report and must be treated as a catalogue name error.

The latest detailed fitted assessment located is the 2017 Stock Synthesis update (SS 3.30.03.03), fitted through 2016 with estimates reported through 2017. Later management advice uses catch-only projections based on that assessment. The 2021 projection informed 2027-2028 harvest specifications in the Council's 2026 analysis; this is a projection update, not a later age-structured refit. NOAA's public species page calls the coastwide status a 2021 assessment, while the PFMC sources clarify that the 2021 run is catch-only. The DFO British Columbia unit and its newer assessment are separate and are not substituted for this US unit.

The 2017 report and later advice documents are cached locally in `source_cache/noaa_west_coast_arrowtooth_20261029/`. The local `sources.csv` records retrieval dates, URLs, byte sizes, and SHA-256 checksums. The report names `arrowtooth_2017.ctl`, `arrowtooth_2017.dat`, `starter.ss`, `forecast.ss`, `plots-arrowtooth_2017-BASE.zip`, and `Arrowtooth_2017-Numbers_at_age.csv` as auxiliary files. The Council's assessment listing links the report but not these files. Direct attempts to retrieve the named files from the report's `/documents/2017/12/` directory returned 404; the R4SS output archive and N-at-age CSV remain a documented source gap.

## Inputs and assumptions found

The model spans the 1916-2016 historical catch series and uses three fisheries: mink-food, fillet, and discard. The report provides reconstructed state landings and describes how discards were estimated and included in catches, but those are biomass removals in tonnes, not annual catch-at-age. Fishery length and age sampling was expanded using PacFIN Utilities. Fishery age observations are available only in selected years (1986-1991, 1998, 2003-2005, and 2013), and California has no age samples; the assessment extends the Washington/Oregon compositions to California landings. The exact age-composition values in the native model data file were not recovered.

Four aggregate survey biomass indices are used: AFSC Triennial shelf, AFSC slope, NWFSC slope, and NWFSC shelf-slope. The last is updated with VAST/Delta-GLMM values for 2003-2016, with standard errors. NWFSC shelf-slope survey ages are conditional age-at-length distributions by sex, ages 1-28, with observations from 2003-2006 and 2013-2016. The likelihood uses conditional age-at-length, not an age-specific abundance index. Other surveys provide length compositions but not age input sufficient to recreate annual age-specific indices from the accessible report alone.

The assessment estimates sex-specific growth and an external length-weight relationship; it does not publish direct numeric weight-at-age vectors. Female maturity is a fixed logistic function of length, with slope 0.5 and inflection at 37.3 cm, carried forward from Rickey (1993). Natural mortality is fixed at 0.216 per year for females and 0.300 for males. Recruitment follows a Beverton-Holt relationship with fixed steepness 0.902 and fixed recruitment variability 0.8. The report notes that survey calendar-date effects were not investigated, so an exact sampling-time fraction is unavailable.

## Outputs and screen decision

The report publishes spawning biomass and age-0 recruitment series with associated standard deviations from 1916 through 2017, as well as total biomass, age-3+ biomass, depletion, and annual F rate. It explicitly names a sex-specific annual N-at-age CSV, but that file could not be located. The available report therefore supports aggregate comparisons, while age-specific population outputs remain unverified.

The inventory row is marked `screened` and `unresolved`, not eligible or excluded. This is a distinct new stock unit with a clearly age-informed assessment, but the key numerical age-composition matrices and age-specific output file are not accessible from the sources located. It is not yet established that annual catch-at-age or age-specific survey indices can be reconstructed for a defensible tinyAM model. Preserve the verified aggregate values and assumptions if source curation proceeds; do not fill the missing age data from fitted outputs or from the separate British Columbia assessment.

## Sources

- [2017 Assessment Update for the US West Coast Stock of Arrowtooth Flounder](https://www.pcouncil.org/documents/2017/12/2017-assessment-update-for-the-us-west-coast-stock-of-arrowtooth-flounder.pdf)
- [PFMC 2021 SSC review of catch-only projections](https://www.pcouncil.org/documents/2021/09/c-6-a-supplemental-ssc-report-1-2.pdf/)
- [2024 Pacific Coast Groundfish SAFE](https://www.pcouncil.org/documents/2024/08/status-of-the-pacific-coast-groundfish-fishery-stock-assessment-and-fishery-evaluation-july-2025.pdf/)
- [2026 analysis for 2027-2028 harvest specifications](https://www.pcouncil.org/documents/2026/03/c-4-attachment-1-harvest-specifications-impact-analysis-for-2027-28-biennium.pdf/)
- [NOAA Stock SMART ID 10005](https://apps-st.fisheries.noaa.gov/stocksmart/?app=browse_by_stock&stockid=10005)
- [NOAA Arrowtooth Flounder stock status](https://www.fisheries.noaa.gov/species/arrowtooth-flounder)
