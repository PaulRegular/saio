# Greenspotted rockfish (NOAA Stock SMART 10437)

## Stock unit and assessment

Stock SMART lists one Pacific Coast entry. The latest detailed assessment found is the fully accepted 2011 Stock Synthesis assessment, using data through 2010. It fitted northern and southern California populations as separate, independent components divided at Point Conception. The 2026 Amendment 37 analysis says the Council adopted a coastwide stock definition, while the portion north of 42° N was not assessed with this model. This is a documented earlier-boundary fallback, not a coastwide assessment match; no newer detailed coastwide production fit was located.

## Inputs and outputs

The assessment is an age-structured catch-at-length model. Its native data files contain annual fishery catches in metric tonnes, fleet-specific length compositions, fishery indices, and fishery and survey age observations. The northern model includes recreational age observations from 1977–1982 and NWFSC trawl survey ages expanded by survey biomass for 2005, 2007, and 2009. The southern model includes NWFSC trawl and hook-and-line survey age data. These are composition observations, not annual catch numbers-at-age or age-specific abundance-index series. Reconstructing catch-at-age would require a documented model-based conversion; no direct catch-at-age likelihood was found.

Appendix K reports annual numbers-at-age for both modeled areas from 1916–2010, in thousands of fish, with columns 0–33. The report does not provide uncertainty for those tabulated values. No comparable annual F-at-age surface was located. The model fixes M at 0.065 per year in both areas; the STAR review identifies natural mortality as a major uncertainty. The model derives maturity from length-based logistic curves (about 26 cm in northern California and 22 cm in southern California) and uses growth and length-weight relationships, rather than supplying standalone maturity-at-age and weight-at-age input vectors. Its data files set every fishery and survey timing to 0.5 within the year; this is the assessment's model setting, not independently verified field timing.

## Screening decision

Keep this candidate's eligibility unresolved. It is a strong source for a historical two-component assessment, including age observations and reported N-at-age, but its assessment unit differs from the current coastwide definition and it does not fit catch-at-age directly. Before treating it as eligible, confirm the fallback representation for the current stock and whether a documented catch-at-age reconstruction can be made from the released compositions and fitted biological surfaces. Do not combine the two regional models or describe them as a fitted coastwide model without that review. No canonical database records were added.

## Sources and local cache

- [NOAA Stock SMART 10437](https://apps-st.fisheries.noaa.gov/stocksmart/?app=browse_by_stock&stockid=10437)
- [Dick, Pearson and Ralston (2011), assessment report](https://www.pcouncil.org/documents/2011/09/status-of-greenspotted-rockfish-sebastes-chlorostictus-in-u-s-waters-off-california-september-2011.pdf)
- [2011 STAR panel review](https://www.pcouncil.org/documents/2011/08/greenspotted-rockfish-star-panel-report-august-2011.pdf)
- [2026 Amendment 37 stock-definition analysis](https://www.fisheries.noaa.gov/s3/2026-02/am-37-fpa-analysis-01-2026.pdf)
- [Pacific Council groundfish assessment listing](https://www.pcouncil.org/stock-assessments-star-reports-stat-reports-rebuilding-analyses-terms-of-reference/groundfish-stock-assessment-documents/)

The assessment and STAR PDFs are cached in the gitignored `source_cache/discovery_noaa_greenspotted_2011/` directory. Its local `sources.csv` manifest records retrieval date, document revision, URL, size, and SHA-256. The Amendment 37 analysis is cached in the shared NOAA source folder with its own manifest.
