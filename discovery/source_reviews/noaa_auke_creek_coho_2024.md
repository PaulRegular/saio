# NOAA Auke Creek coho salmon (2024 assessment)

## Assessment and sources

NOAA Stock SMART ID 10580 is the Auke Creek coho indicator stock in Southeast
Alaska. The latest record in the cached NOAA Stock SMART snapshot is assessment
13939: a 2024 operational assessment using data through 2024, marked Full
acceptance. Stock SMART labels its method “Slanted Hockey Stock Model” (model
version 2023) and reports 2024 natural adult spawners of 2,439 and an exploitation
rate of 0.154.

The NOAA 2024 Southeast Alaska status report describes Auke Creek, Berners River,
and Hugh Smith Lake as indicator stocks. Coded-wire-tagging, fishery harvest
sampling, and adult escapement counts at weirs are combined to estimate total run.
Fishing mortality status is evaluated from four-year averages of exploitation and
the maximum fishing rate implied by run size and escapement goals. The 2024 report
gives Auke Creek productive-capacity estimates for 1983–2024 and reports that the
2024 value was 2,439 natural adult spawners.

ADF&G's 2024 escapement-goal review says age composition has been estimated through
coded-wire-tag studies since 1980 and describes the escapement goal as based on a
stock–recruit analysis. NOAA's Auke Creek Research Station report also contains
age-specific smolt observations, including ages 1 and 2. These are real age data,
but the reviewed production assessment is an indicator-stock status and
stock–recruit analysis; the available sources do not show those samples entering a
multi-age population assessment or provide annual N-at-age, F-at-age, M-at-age, or
age-structured SSB outputs. Stock SMART classifies composition input as level 0
for the 2024 run. This field concerns composition used for the assessment; it does
not mean that independent Auke Creek research has never collected ages.

The detailed 2024 NOAA status report, ADF&G escapement-goal review, and Stock
SMART dictionary are cached locally in
`source_cache/noaa_auke_creek_coho_2024/`; checksums and retrieval dates are in
its `sources.csv`. The NOAA research-station report is publicly readable, but its
repository download returned HTTP 403 during this review, so it is linked below
and was not represented as locally cached.

## Screening decision

This is a distinct, current U.S. indicator-stock unit, not a match to the DFO
coho candidates or the separate NOAA West Coast coho management units. It is
screened **ineligible** for the multi-age comparison set: the latest accepted run
does not provide the age-indexed assessment inputs and population outputs needed
for a tinyAM comparison. The existence of age samples in the research program
does not by itself make this assessment age structured. No canonical numerical
assessment data were added.

## Sources

- [NOAA 2024 Southeast Alaska coho status report](https://apps-st.fisheries.noaa.gov/sis/docServlet?fileAction=download&fileId=10339), especially the indicator-stock methods and Table 6.
- [ADF&G 2024 review of Southeast Alaska salmon escapement goals](https://www.adfg.alaska.gov/static/regulations/regprocess/fisheriesboard/pdfs/2024-2025/se/fms24-04.pdf), Appendix C4.
- [NOAA Auke Creek Research Station report, data through 2024](https://repository.library.noaa.gov/view/noaa/72414/noaa_72414_DS1.pdf).
- [NOAA Stock SMART data dictionary](https://apps-st.fisheries.noaa.gov/stocksmart/StockSMART_DataDictionary.pdf).
- [NOAA Stock SMART](https://apps-st.fisheries.noaa.gov/stocksmart/?app=browse_by_stock&stockid=10580).
