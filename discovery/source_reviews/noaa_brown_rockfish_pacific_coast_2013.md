# NOAA Brown rockfish - Pacific Coast (Stock SMART 10546)

## Screening decision

**Identity:** new NOAA/PFMC Pacific Coast candidate; no matching canonical tinyAM stock was found.

**Latest assessment:** the fully accepted 2013 benchmark assessment used data through 2012. NOAA Stock SMART retains a 2010 DB-SRA entry and a separate 2013 assessment; the 2025 Groundfish SAFE lists 2013 as the most recent assessment informing management. The 2013 assessment treated Brown rockfish as one coastwide U.S. stock. The Council's Amendment 37 action also defines the current Pacific Coast Groundfish FMP unit as coastwide; NMFS review was pending at the time of this screen.

**Age-input eligibility:** ineligible for the age-disaggregated assessment set. The selected model is XDB-SRA, not an age-structured assessment. It uses removals and aggregate fishery-dependent abundance indices, and its Appendix B Stock Synthesis data file has zero age-composition, length-composition and mean-size-at-age observations. Age bins or biological age information in a file do not create an age-based likelihood input. The report provides aggregate biomass, depletion, MSY and exploitation outputs, but no numeric N-at-age or F-at-age series.

## Assessment and data evidence

The report gives total removals in metric tons by year, 1916-2012. Its Brown rockfish XDB-SRA model uses four aggregate CPFV abundance indices: Central California onboard observer (1988-2011), Southern California onboard observer (1999-2011), and Central and Southern California RecFIN dockside observer series (1980-2003). These are fishery-dependent aggregate indices, not age-specific abundance observations.

The Appendix B model data file has 52 age bins but explicitly sets `N_Agecomp_obs = 0`, `N_Length_obs = 0`, and `N_MeanSize-at-Age_obs = 0`. The assessment's biology and life-history discussion therefore does not supply observed catch-at-age, survey age compositions or age-specific abundance for this run. No survey timing fraction applies to its four selected indices.

The report describes coastwide estimates of total and spawning biomass, depletion, exploitation, MSY and OFL. The 2025 SAFE repeats management quantities based on the 2013 assessment; it is not a new assessment run. The reviewed outputs do not include annual numeric N-at-age or F-at-age surfaces.

## Sources and local cache

The report and supporting official documents are cached in the gitignored `source_cache/discovery_noaa_data_moderate_2013_2026/` directory. Its `sources.csv` records URLs, revisions, retrieval date, byte size and SHA-256 checksums.

- NOAA Stock SMART record 10546: <https://apps-st.fisheries.noaa.gov/stocksmart/?app=browse_by_stock&stockid=10546>
- Accepted 2013 data-moderate assessment, published January 2015: <https://www.pcouncil.org/documents/2015/01/data-moderate-stock-assessments-for-brown-china-copper-sharpchin-stripetail-and-yellowtail-rockfishes-and-english-and-rex-soles-in-2013-published-january-2015.pdf>
- Pacific Coast Groundfish SAFE published July 2025: <https://www.pcouncil.org/documents/2024/08/status-of-the-pacific-coast-groundfish-fishery-stock-assessment-and-fishery-evaluation-july-2025.pdf/>
- NMFS preliminary 2027 assessment priorities (February 2026): <https://www.pcouncil.org/documents/2026/02/d-8-a-nmfs-report-1-preliminary-nmfs-recommendations-for-2027-groundfish-stock-assessments.pdf/>
- Amendment 37 stock definitions and review status: <https://www.pcouncil.org/actions/phase-2-identification-of-groundfish-in-need-of-conservation-and-defining-their-stocks/>
- NMFS proposed Amendment 37 notice: <https://www.federalregister.gov/d/2026-02291>

## Database action

No canonical stock, assessment, input or output records were added. This is an inventory-source screen only.