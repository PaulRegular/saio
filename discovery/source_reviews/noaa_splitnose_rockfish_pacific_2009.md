# U.S. Pacific Coast Splitnose Rockfish (NOAA Stock SMART 10564)

## Stock unit and latest assessment

NOAA Stock SMART identifies splitnose rockfish (*Sebastes diploproa*) as a Pacific Coast stock, ID 10564. The final 2009 assessment modeled a single coastwide U.S. stock. PFMC's current stock-definition material continues to identify one coastwide assessment unit; north/south management apportionments do not establish separate biological units.

Stock SMART records a fully accepted 2009 Stock Synthesis 3.02E assessment using data through 2008. The PFMC 2025 stock-structure review identifies the 2009 coastwide run as the benchmark, and the 2025 Groundfish SAFE and September 2025 SSC minutes still list 2009 as the latest assessment. No later full production run was located. The 2009 STAR review concluded that the assessment represented the best available information at that time.

## Inputs and outputs available

The base model uses reconstructed removals from domestic trawl, foreign trawl, and domestic non-trawl fisheries, with fishery length compositions and discard assumptions. California trawl age samples from 1980–1981 and 1983–1985 were used to form conditional age-at-length data, but double-read comparisons showed highly inconsistent age readings. The assessment excluded those fishery age data from its base model and retained them only for sensitivity analysis. They cannot be treated as accepted-run catch-at-age inputs.

The assessment includes four aggregate biomass-index series: AFSC shelf triennial (1977–2004), AFSC slope (1997 and 1999–2001), NWFSC shelf-slope (2003–2008), and NWFSC slope (1999–2002). NWFSC shelf-slope conditional age-at-length data by sex and year were included for 2003–2008. AFSC triennial ages from 1977, 1980, and 1989 were generated but excluded from the base model because age precision and ageing-error information were inadequate. The report does not provide direct age-specific abundance indices; the NWFSC age-at-length observations are composition data paired with an aggregate index.

The assessment estimates sex-specific growth and uses weight-length relationships derived from NWFSC survey samples: female weight is `0.00002 * fork_length^3.0139` and male weight is `0.00002 * fork_length^2.9684`, with weight in kg and fork length in cm. Female maturity-at-length is estimated logistically from fishery and AFSC slope-survey observations, with L50 = 21.84 cm and slope coefficient -0.5683. Natural mortality is fixed at 0.048 per year for both sexes. These relationships support derived biological surfaces but are not observed annual weight-at-age or maturity-at-age matrices. The report does not establish fractional within-year timing for the three fisheries and four survey series.

The assessment report provides annual fitted numbers-at-age by sex and aggregate spawning output, recruitment, depletion, and fishing/exploitation results. These are model outputs, not substitutes for the fishery age inputs that the accepted base model did not use. The report contains age-specific output tables but no accepted-run catch-at-age input series.

## Screening decision

The assessment has useful survey age-at-length inputs and fitted numbers-at-age, but the fishery age data were excluded from the accepted base model and only used in a sensitivity run. The report's reconstructed catches and fishery length compositions do not support an accepted-run catch-at-age reconstruction. No canonical stock, assessment, input, or output records were added was attempted.

## Sources and local cache

- [NOAA Stock SMART record 10564](https://apps-st.fisheries.noaa.gov/stocksmart/?app=browse_by_stock&stockid=10564)
- [PFMC 2009 assessment report](https://www.pcouncil.org/documents/2009/10/status-of-the-u-s-splitnose-rockfish-sebastes-diploproa-resource-in-2009-october-28-2009.pdf)
- [PFMC 2009 STAR panel report](https://www.pcouncil.org/documents/2009/05/splitnose-rockfish-star-panel-report-may-2009.pdf)
- [PFMC 2025 stock-structure literature review](https://www.pcouncil.org/documents/2025/02/h-6-attachment-3-stock-structure-literature-review.pdf)
- [PFMC 2025 Pacific Coast Groundfish SAFE](https://www.pcouncil.org/documents/2024/08/status-of-the-pacific-coast-groundfish-fishery-stock-assessment-and-fishery-evaluation-july-2025.pdf/)
- [PFMC SSC adopted September 2025 minutes](https://www.pcouncil.org/documents/2025/12/ssc-sept-2025-minutes-adopted-final.pdf/)
- [PFMC Amendment 37 stock-definition page](https://www.pcouncil.org/actions/phase-2-identification-of-groundfish-in-need-of-conservation-and-management-and-defining-their-stocks/)

The locally cached assessment and supporting PDFs, source revisions, URLs, retrieval dates, sizes, and SHA-256 checksums are recorded in the gitignored directory `source_cache/discovery_noaa_splitnose_rockfish_2009/sources.csv`.
