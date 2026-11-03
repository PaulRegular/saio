# NOAA Gulf Gag Grouper: SEDAR 72 SRFS run

Reviewed 2026-10-30. NOAA Stock SMART row 10348 identifies Gulf of Mexico Gag Grouper (*Mycteroperca microlepis*). It is a separate management unit from South Atlantic Gag, listed in Stock SMART row 10349.

SEDAR 105 is the current Gulf Gag assessment project and remains underway in 2026. The most recent completed production model used for advice is the SEDAR 72 amendment run incorporating Florida's State Reef Fish Survey (SRFS), completed in September 2022 with data through 2019. The Gulf SSC reviewed the run in July 2022 and found it consistent with best scientific information; NOAA's 2024 Amendment 56 rule used its projections for revised reference points and catch advice. NOAA still identifies SEDAR 72 as the most recent population assessment in its 2026 season notice. The 2022 run updates the 2021 base model by replacing Florida private-mode MRIP-FES catches and discards with calibrated SRFS estimates and correcting the recreational headboat data series.

The accepted assessment is a Stock Synthesis age-structured model with one Gulf area and age bins 0 through 20+, using a plus group for older fish. The September 2022 report contains annual landings and discard inputs by fleet in numbers and biomass, standardized commercial and recreational CPUE indices, and age-0 and video-survey indices with uncertainty. Commercial and recreational age-composition inputs are documented in the final report and SEDAR72-WP-17. The report supplies annual sample counts and age-composition plots, not complete machine-readable age-proportion arrays. A later source import can recover approximate proportions by digitizing the official figures and should label that reconstruction and its precision explicitly.

The original report supplies the fixed sex-combined length-weight relationship, fitted growth curve, a fixed age-specific Lorenzen M vector scaled to the Then et al. (2015) estimate of 0.159 per year, and fixed logistic female maturity (about 3.9 years at 50% maturity, slope 2.513). Males and transitioning fish are treated as mature. The annual assessment assumes fishing and data collection are continuous and homogeneous through the year and does not include a seasonal removal component. It does not provide a single within-year survey timing fraction; a translation requiring one would need to document its chosen approximation.

The SRFS report provides annual total and exploitable biomass, SSB, exploitable abundance, recruitment, fleet exploitation and model fit outputs for 1963–2019. Complete annual N-at-age and F-at-age output arrays were not found in the recovered tables. Numeric annual age-composition vectors and native run-matched model files also remain unavailable. Nonetheless, the source set meets the source-curation screen: the age compositions can be reconstructed from official figures and paired with tabulated catches, indices, biology and comparable outputs. This is a source-based reconstruction route, not a claim that the original Stock Synthesis likelihood is fully reproducible.

## Sources

- [SEDAR 72 assessment page](https://sedarweb.org/assessments/sedar-72/).
- [SEDAR 72 operational assessment report amendment: SRFS run, September 2022](https://sedarweb.org/documents/sedar-72-gulf-of-mexico-gag-grouper-operational-assessment-report-amendment-state-reef-fish-survey-srfs-run/).
- [SEDAR 72 final stock assessment report, revised October 2021](https://sedarweb.org/documents/sedar-72-gulf-of-mexico-gag-grouper-final-stock-assessment-report_october2021/).
- [SEDAR72-WP-17: Commercial and recreational length and age compositions](https://sedarweb.org/documents/sedar-72-wp-17-gulf-of-mexico-gag-grouper-mycteroperca-microlepis-commercial-and-recreational-length-and-age-compositions/).
- [SEDAR 72 operational assessment executive summary](https://sedarweb.org/documents/sedar-72-gulf-of-mexico-gag-grouper-operational-assessment-executive-summary-report/).
- [Gulf SSC review of the SEDAR 72 SRFS run](https://sedarweb.org/documents/gulf-ssc-review-of-sedar-72-gulf-gag-grouper/).
- [NOAA InPort record for the SEDAR 72 SRFS amendment](https://www.fisheries.noaa.gov/inport/item/73521/full-list).
- [Federal Register final rule implementing Amendment 56](https://www.federalregister.gov/documents/2024/05/10/2024-10208/fisheries-of-the-caribbean-gulf-of-mexico-and-south-atlantic-reef-fish-resources-of-the-gulf-of).
- [SEDAR 105 Gulf Gag assessment project](https://sedarweb.org/assessments/sedar-105-gulf-gag-grouper/).
- [NOAA 2026 Gulf Gag recreational season notice](https://www.fisheries.noaa.gov/bulletin/noaa-fisheries-announces-2026-gag-recreational-season-federal-waters-gulf).

The five cited SEDAR PDFs are cached in the ignored `source_cache/noaa_gag_sedar72_2022/` directory with retrieval time, document revision, byte size and SHA-256 checksum recorded in its manifest. This screen updates only the candidate register and discovery summaries; it does not add canonical assessment inputs or outputs.
