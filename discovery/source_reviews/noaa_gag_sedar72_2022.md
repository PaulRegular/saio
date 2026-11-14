# NOAA Gulf Gag Grouper: SEDAR 72 SRFS run

Reviewed 2026-10-30. NOAA Stock SMART row 10348 identifies Gulf of Mexico Gag Grouper (*Mycteroperca microlepis*). It is a separate management unit from South Atlantic Gag, listed in Stock SMART row 10349.

SEDAR 105 is the current Gulf Gag assessment project and remains underway in 2026. The most recent completed production model used for advice is the SEDAR 72 amendment run incorporating Florida's State Reef Fish Survey (SRFS), completed in September 2022 with data through 2019. The Gulf SSC reviewed the run in July 2022 and found it consistent with best scientific information; NOAA's 2024 Amendment 56 rule used its projections for revised reference points and catch advice. NOAA still identifies SEDAR 72 as the most recent population assessment in its 2026 season notice. The 2022 run updates the 2021 base model by replacing Florida private-mode MRIP-FES catches and discards with calibrated SRFS estimates and correcting the recreational headboat data series.

The accepted assessment is a Stock Synthesis age-structured model with one Gulf area and age bins 0 through 20+, using a plus group for older fish. The September 2022 report contains annual landings and discard inputs by fleet in numbers and biomass, standardized commercial and recreational CPUE indices, and age-0 and video-survey indices with uncertainty. Commercial and recreational age-composition inputs are documented in the final report and SEDAR72-WP-17. The report supplies annual sample counts and age-composition plots, not complete machine-readable age-proportion arrays. A later source import can recover approximate proportions by digitizing the official figures and should label that reconstruction and its precision explicitly.

The original report supplies the fixed sex-combined length-weight relationship, fitted growth curve, a fixed age-specific Lorenzen M vector scaled to the Then et al. (2015) estimate of 0.159 per year, and fixed logistic female maturity (about 3.9 years at 50% maturity, slope 2.513). Males and transitioning fish are treated as mature. The annual assessment assumes fishing and data collection are continuous and homogeneous through the year and does not include a seasonal removal component. It does not provide a single within-year survey timing fraction.

The SRFS report provides annual total and exploitable biomass, SSB, exploitable abundance, recruitment, fleet exploitation and model fit outputs for 1963–2019. Complete annual N-at-age and F-at-age output arrays were not found in the recovered tables. Numeric annual age-composition vectors and native run-matched model files also remain unavailable. Nonetheless, the source set meets the source-curation screen: the age compositions can be reconstructed from official figures and paired with tabulated catches, indices, biology and comparable outputs. This is a source-based reconstruction route, not a claim that the original Stock Synthesis likelihood is fully reproducible.

## Data captured so far

The database contains the SEDAR 72 SRFS assessment record and the point estimates in Tables 6–9 of the September 2022 amendment. Tables 6–7 provide the annual exploitation rate used as a proxy for fishing mortality and fleet-specific biomass-killed fractions, including red-tide mortality. These are retained as exploitation rates and are not labelled as instantaneous F.

Tables 8–9 provide annual total and exploitable biomass, SSB, exploitable abundance, age-0 recruitment, SSB/SSB0, and sex-specific SSB, biomass and abundance for 1963–2019. Units and age-3+ definitions are preserved. Values are rounded to the precision printed in the report; the tables provide no annual output intervals. These tables do not provide total abundance or N-at-age, and no F-at-age series was recovered.

Tables 1-4 of the SRFS amendment provide 522 recreational input rows: landings numbers for 1963-2019, discards before discard mortality for 1981-2019, and the matching log-scale standard errors for both partitions in 1981-2019. The Private + Shore Total is the model fleet input; its Private SRFS and Non-SRFS components are not separate fleets. The corrected 1983 Private SRFS subcomponent is marked in the source, while the reported Private + Shore total is retained. Counts remain in fish and source-reported log-scale errors are retained without conversion.

Tables 10-11 provide 98 commercial landings biomass observations and matching log-scale standard errors, in million pounds gutted weight, plus expected numbers, biomass and mean weights. Tables 15-16 provide 54 commercial discard-number observations and their log-scale standard errors. The same tables report fitted total and dead discard numbers and biomass, and mean discard weights. Tables 12-14 and 17-19 report fitted recreational landings and discard quantities; their observed input values duplicate Tables 1-4 and are not imported again.

Tables 20-21 provide observed and fitted standardized indices and the reported log-scale standard errors. The 161 index observations cover four fishery-dependent CPUE series, the age-0 index, SEAMAP video and Panama City video. The age-0 series is stored at age 0. Index values retain the source scale, normalized to a mean of one.

Tables 1-4 and 10-21 now contribute 1,148 input rows and 2,313 fitted catch/index outputs. Together with Tables 6-9, the database contains 3,510 outputs for this assessment. Values are transcribed from the cached 2022 amendment at printed precision; no recreational input series are duplicated.

SEDAR72-WP-17 Table 7 also provides age-sampling counts by fleet for 1991-2019; 144 fish counts and 144 trip counts are now imported as sampling metadata. They do not supply the age-composition vectors or effective sample sizes.

SEDAR72-WP-17 Table 7 also provides age-sampling counts by fleet for 1991-2019; 144 fish counts and 144 trip counts are now imported as sampling metadata. They do not supply the age-composition vectors or effective sample sizes. Remaining gaps: numeric age-composition arrays, numeric age-specific weight and maturity surfaces, N-at-age and F-at-age output arrays, and uncertainty for the reported point estimates remain unavailable. The annual age-composition values in SEDAR72-WP-17 are shown in figures; any later digitization must be labelled as a reconstruction and retain its precision. No Table 3 landings error series is reported before 1981. Inputs, outputs, and assumptions therefore remain partial.

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

The five cited SEDAR PDFs are cached in the ignored `source_cache/noaa_gag_sedar72_2022/` directory with retrieval date, document revision, byte size and SHA-256 checksum recorded in `provenance/noaa_gag_sedar72_2022/manifest.csv`.
