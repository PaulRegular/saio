# NOAA Scamp inventory units: SEDAR 68OA

Reviewed 2026-10-30. NOAA Stock SMART rows 10324 (Gulf of Mexico) and 10326 (South Atlantic) represent separate regional management units. SEDAR 68 operational assessments model Scamp (*Mycteroperca phenax*) jointly with Yellowmouth Grouper (*M. interstitialis*) because species identification in catches is uncertain.

## Gulf of Mexico unit

The latest full fit located is the SEDAR 68OA Gulf operational assessment, published August 2022 and fitted through 2020. NOAA’s FY2025 Q4 stock-status appendix identifies the last assessment year as 2022. The April 2025 SEDAR projection report updates advice projections using the existing model, rather than reporting a new fitted assessment.

The Stock Synthesis model fits annual nominal age compositions for commercial vertical-line and longline, recreational charter/private, and headboat fleets. The 2022 working paper documents age sampling, age-composition construction and annual sample counts (1977–2020); annual age proportions are presented as figures rather than numeric vectors. The report also includes aggregate abundance indices, age-specific natural mortality, and age/length life-history inputs. Survey indices are aggregate, not age-stratified. Numeric sex-specific expected numbers-at-age are reported in thousands of fish (Tables 15A/16A and companion biomass tables), with recruitment, biomass and SSB outputs. The exact observed age vectors and run-matched numerical biological arrays remain to be recovered; a full F-at-age output was not verified in this pass.

The Gulf unit remains eligibility-unresolved. Official assessment evidence confirms age-composition likelihoods and age-specific population outputs, but does not expose the complete numeric composition matrices as tables or machine-readable files in the reviewed sources.

## South Atlantic unit

The latest detailed fit located is the SEDAR 68OA South Atlantic operational assessment, published December 2022 and fitted through 2021. The South Atlantic SSC reviewed it in January 2023, with July 2023 advice output; the model remains the most recent full assessment identified in the current source review.

The assessment fits commercial, recreational and SERFS age compositions, with oldest ages pooled at 15+ and coverage varying across fleets and years. Numeric age proportions are shown in figures, while the working paper provides sample descriptions and counts. The final report provides annual total abundance-at-age in thousands of fish (Table 6) and instantaneous fishing mortality-at-age in yr-1 (Table 12), as well as SSB and recruitment. The reviewed PDFs do not provide a complete numeric input matrix or the run-matched weight, maturity and mortality arrays needed for direct reconstruction.

The South Atlantic unit also remains eligibility-unresolved pending recovery of numerical age-composition inputs and exact biological arrays. The Gulf and South Atlantic units must not be merged: they have separate regional assessment histories and management units, even though their fitted models include both species.

## Sources and local cache

- [SEDAR 68 assessment page](https://sedarweb.org/assessments/sedar-68/) lists the separate Gulf and South Atlantic operational assessment tracks and working papers.
- [Gulf operational assessment report](https://sedarweb.org/documents/sedar-68oa-gulf-of-mexico-scamp-operational-assessment-final-stock-assessment-report/).
- [Gulf age-composition working paper, SEDAR68OA-WP-05](https://sedarweb.org/documents/sedar-68oa-wp-05-gulf-of-mexico-scamp-mycteroperca-phenax-and-yellowmouth-grouper-mycteroperca-interstitialis-commercial-and-recreational-length-and-age-compositions/).
- [Gulf ageing-error working paper, SEDAR68OA-WP-04](https://sedarweb.org/documents/sedar-68oa-wp-04-age-and-ageing-error-of-scamp-from-the-northern-gulf-of-mexico/).
- [Gulf additional projections, April 2025](https://gulf-council-media.s3.amazonaws.com/uploads/2025/04/06d.-SEDAR68-OA-Gulf-Scamp-Projection-Report_April2025.pdf).
- [NOAA FY2025 Q4 stock-status Appendix E](https://www.fisheries.noaa.gov/s3/2026-03/Appendix-E.pdf).
- [South Atlantic operational assessment report](https://sedarweb.org/documents/sedar-68oa-south-atlantic-scamp-operational-assessment-final-stock-assessment-report/).
- [South Atlantic age-composition working paper, SEDAR68OA-WP-05](https://sedarweb.org/documents/sedar68oa-wp05south-atlantic-u-s-scamp-mycteroperca-phenax-age-and-length-composition-from-the-recreational-fisheries/).
- [South Atlantic SSC meeting output, July 2023](https://sedarweb.org/documents/sedar-68oa-south-atlantic-scamp-july-2023-ssc-meeting-output/).

All eight PDFs are cached locally under the ignored `source_cache/noaa_scamp_sedar68oa/` directory. Its `manifest.csv` records source URLs, document revisions, retrieval time, byte size and SHA-256 checksums. These are discovery records only; no canonical stock, assessment, input or output data were added.
