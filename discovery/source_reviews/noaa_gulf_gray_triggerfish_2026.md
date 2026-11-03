# Gulf gray triggerfish, SEDAR 100 (2026)

## Unit and current assessment

NOAA Stock SMART row 10062 identifies Gulf of Mexico gray triggerfish
(*Balistes capriscus*), separate from the Southern Atlantic Coast unit. The
inventory's 2020 assessment year is stale. The latest detailed assessment
located is SEDAR 100, completed in September 2026, with data through 2024. It
models a single Gulf-wide stock with sexes combined in Stock Synthesis
3.30.21.00, beginning in 1945. The population is modeled at ages 0-15, while
composition bins group ages 10 and older. The report assumes continuous
fishing through the year and settlement on July 1.

The final SEDAR report contains the assessment-process configuration and the
Review Panel's revised-base analyses. The panel's revised base fixes target M
at 0.36 and estimates stock-recruitment steepness at about 0.422; the CIE
review supports that historical model revision but cautions against using the
estimated stock-recruitment relationship as the main basis for projections
and catch advice. SEDAR marks the assessment complete, but NOAA's peer-review
listing has no actual dissemination date, and formal management adoption was
not confirmed in the sources reviewed. Treat the reviewed SEDAR run as the
latest detailed assessment, not as confirmed adopted catch advice.

## Inputs and biology

The assessment uses fleet-level landings and discards, not observed catch
numbers-at-age. It fits conditional age-at-length data for commercial
vertical-line, commercial longline, and recreational landed fish, with
year-fishery strata varying according to sample-size cutoffs. SEDAR 100 DW-04
and DW-07 document the fishery length and age data. The released age data span
1999-2024, with no age samples in 2001. Reconstructing catch-at-age for a
different model would require an explicit conversion using the fishery
compositions and growth; it must not be represented as a native catch-age
series.

The fitted model uses aggregate abundance indices. The SEAMAP summer-fall
trawl series is split into an early index (1987-2008) and a late index
(2009-2024). Trawl age and length samples were available for 2008-2024
(`N = 519`), but the assessment fitted survey length compositions rather than
an age-composition likelihood. The G-FISHER video index has associated length
compositions, not empirical age observations. A tinyAM age-specific index
would therefore need an explicit age-composition reconstruction and would be
an approximation to the likelihood used by SEDAR.

Growth is estimated internally using age-at-length information. Weight and
maturity are modeled as functions of length rather than supplied as
weight-at-age and maturity-at-age vectors. Deriving age-specific biology would
require the model growth relationship. Natural mortality is fixed at a target
of 0.36 per year and scaled by age with a Lorenzen relationship through age
15. Survey timing fractions suitable for tinyAM were not found; the
assessment's continuous-fishing assumption and July 1 settlement do not
specify those fractions.

## Outputs and screening decision

The Review Panel revised-base tables report annual total and exploited
biomass, SSB in metric tons, exploited abundance ages 1+, age-0 recruitment,
and SSB ratio for 1945-2024. The annual quantity labeled F is a harvest rate
(biomass killed divided by age-1+ biomass), not instantaneous F-at-age. The
report does not provide numerical annual N-at-age or F-at-age arrays. The
reported series are point estimates.

This unit is eligible for source curation because the public assessment and
supporting data papers provide removals, fishery age-at-length data,
aggregate abundance indices, trawl survey age samples, biology, mortality
assumptions, and comparable annual population outputs. This is a source
curation decision, not a finding that the observations can be translated
faithfully to tinyAM: catch-at-age, age-specific survey indices, weight-at-age,
and maturity-at-age all require documented reconstruction. No canonical
assessment data were imported, and the unit has not been selected for an
import batch.

## Sources

- [SEDAR 100 assessment page and process status](https://sedarweb.org/assessments/sedar-100-gulf-triggerfish/)
- [SEDAR 100 final Stock Assessment Report](https://sedarweb.org/documents/sedar-100-gulf-gray-triggerfish-final-stock-assessment-report/)
- [DW-04 recreational length and age compositions](https://sedarweb.org/documents/sedar-100-dw-04-gulf-of-america-gray-triggerfish-balistes-capriscus-length-and-age-compositions-from-the-recreational-fishery/)
- [DW-05 commercial landings](https://sedarweb.org/documents/sedar-100-dw-05-commercial-landings-of-gulf-of-america-gray-triggerfish-balistes-capriscus-from-1949-2024/)
- [DW-07 commercial handline and longline length and age compositions](https://sedarweb.org/documents/sedar-100-dw-07-gulf-of-america-gray-triggerfish-balistes-capriscus-length-and-age-compositions-for-the-commercial-handline-and-longline-fisheries/)
- [DW-13 fishery-dependent length and age data](https://sedarweb.org/documents/sedar-100-dw-13-length-and-age-compositions-of-gulf-gray-triggerfish-balistes-capriscus-collected-in-association-with-fishery-dependent-projects/)
- [DW-14 age-length data review, 1999-2024](https://sedarweb.org/documents/sedar-100-dw-14-a-review-of-gray-triggerfish-balistes-capriscus-age-length-data-in-the-gulf-of-america-1999-2024/)
- [DW-16 SEAMAP groundfish indices and survey age samples](https://sedarweb.org/documents/sedar-100-dw-16-gray-triggerfish-abundance-indices-from-seamap-groundfish-surveys-in-the-northern-gulf-of-america/)
- [CIE review report, Nicholas Fisch](https://sedarweb.org/documents/sedar-100-cie-review-report-fisch/)
- [NOAA peer-review listing](https://www.noaa.gov/information-technology/sedar-100-gulf-gray-triggerfish)
- [NOAA Stock SMART row 10062](https://apps-st.fisheries.noaa.gov/stocksmart/?stockid=10062)

The final report and supporting PDFs are cached locally in
`source_cache/discovery_noaa_gulf_gray_triggerfish_2026/`. Their retrieval
dates, URLs, checksums, and descriptions are in the ignored `sources.csv`
manifest.
