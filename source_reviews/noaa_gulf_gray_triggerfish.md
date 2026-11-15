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
compositions, not empirical age observations.

Growth is estimated internally using age-at-length information. Weight and
maturity are modeled as functions of length rather than supplied as
weight-at-age and maturity-at-age vectors. Deriving age-specific biology would
require the model growth relationship. Natural mortality is fixed at a target
of 0.36 per year and scaled by age with a Lorenzen relationship through age
15. The assessment's continuous-fishing assumption and July 1 settlement do not
specify those fractions.

## Outputs and screening decision

The Review Panel revised-base tables report annual total and exploited
biomass, SSB in metric tons, exploited abundance ages 1+, age-0 recruitment,
and SSB ratio for 1945-2024. The annual quantity labeled F is a harvest rate
(biomass killed divided by age-1+ biomass), not instantaneous F-at-age. The
report does not provide numerical annual N-at-age or F-at-age arrays. The
reported series are point estimates.

The unit was selected for source curation on 2026-11-11 because the public
assessment and supporting data papers provide removals, aggregate abundance
indices, fishery age-at-length samples, survey age samples, biology, mortality
assumptions, and comparable annual population outputs.

## Canonical import coverage

The partial import records 217 numerical landings cells for 1949-2024, with
gear and East/West subregion retained. Blank cells and confidential asterisks
are not treated as zero. It also records 75 discard estimates in numbers and
75 in pounds across the separately reported East, West and Gulf-wide series
for 2000-2024. The 150 source-reported natural-scale standard errors are
stored as numeric `catch_se` rows. Regional and Gulf-wide estimates are not
additive and are not treated as independent observations.

Table 5.8.2 contributes 64 mean-scaled index values and 64 matching CV rows:
the old SEAMAP summer/fall series (1987-2008), the new SEAMAP summer/fall
series (2009-2024), and G-FISHER video (1993-2023, with gaps). The Headboat
series is omitted because Table RW29 does not show it in the selected Review
Panel model. Survey timing fractions are not reported, so `sampling_time` is
left blank.

The import records 80 annual Review Panel revised-base values for each of
total biomass, 1+ biomass, SSB, 1+ abundance, age-0 recruitment, SSB/SSB0 and
exploitation rate for 1945-2024. Total 0+ abundance is also derived by adding
reported age-0 recruitment to reported 1+ abundance; it is marked as derived
and has no uncertainty. All annual outputs are point estimates. The
exploitation rate is a biomass ratio used as an F proxy, not instantaneous F.

The source report provides fishery and survey age samples and length-based
biology, but annual age-composition distributions have not yet been
transcribed. No catch-at-age, annual N-at-age or F-at-age arrays, weight-at-age
or maturity-at-age are imported. The Assessment Process M-at-age recommendation
is retained in assumptions with a note that it is not the Review Panel
revised-base model's final M surface. The numerical age-specific M surface for
the Review Panel model is not tabulated. Input, assumption and output
completeness therefore remain partial.

The annual age-sample counts are now preserved separately from the plotted
composition distributions: DW-04 Table 3 contributes 286 year-by-source
counts for 2003-2024, and DW-07 Table A.4 contributes 22 handline and 21
longline year counts. These are sampling metadata, not age proportions,
catch-at-age, or effective likelihood sample sizes. The DW-04 Table 3 cells
sum to 9,289, five more than the paper's prose summary of 9,284; the printed
cells are retained as reported without reconciliation. DW-07's longline age
count is blank for 2020 and is left missing. The annual age-composition values
remain available only as figures and are not inferred from the plots.

## Sources

- [SEDAR 100 assessment page and process status](https://sedarweb.org/assessments/sedar-100-gulf-triggerfish/)
- [SEDAR 100 final Stock Assessment Report](https://sedarweb.org/documents/sedar-100-gulf-gray-triggerfish-final-stock-assessment-report/)
- [DW-04 recreational length and age compositions](https://sedarweb.org/documents/sedar-100-dw-04-gulf-of-america-gray-triggerfish-balistes-capriscus-length-and-age-compositions-from-the-recreational-fishery/)
- [DW-05 commercial landings](https://sedarweb.org/documents/sedar-100-dw-05-commercial-landings-of-gulf-of-america-gray-triggerfish-balistes-capriscus-from-1949-2024/)
- [DW-06 commercial discard estimates](https://sedarweb.org/documents/sedar-100-dw-06-cpue-expansion-estimation-for-commercial-discards-of-gulf-of-america-gray-triggerfish)
- [DW-07 commercial handline and longline length and age compositions](https://sedarweb.org/documents/sedar-100-dw-07-gulf-of-america-gray-triggerfish-balistes-capriscus-length-and-age-compositions-for-the-commercial-handline-and-longline-fisheries/)
- [DW-13 fishery-dependent length and age data](https://sedarweb.org/documents/sedar-100-dw-13-length-and-age-compositions-of-gulf-gray-triggerfish-balistes-capriscus-collected-in-association-with-fishery-dependent-projects/)
- [DW-14 age-length data review, 1999-2024](https://sedarweb.org/documents/sedar-100-dw-14-a-review-of-gray-triggerfish-balistes-capriscus-age-length-data-in-the-gulf-of-america-1999-2024/)
- [DW-16 SEAMAP groundfish indices and survey age samples](https://sedarweb.org/documents/sedar-100-dw-16-gray-triggerfish-abundance-indices-from-seamap-groundfish-surveys-in-the-northern-gulf-of-america/)
- [DW-19 SEAMAP fall plankton indices](https://sedarweb.org/documents/sedar-100-dw-19-gray-triggerfish-balistes-capriscus-indices-of-relative-abundance-from-seamap-fall-plankton-surveys-1986-to-2023/)
- [CIE review report, Nicholas Fisch](https://sedarweb.org/documents/sedar-100-cie-review-report-fisch/)
- [NOAA peer-review listing](https://www.noaa.gov/information-technology/sedar-100-gulf-gray-triggerfish)
- [NOAA Stock SMART row 10062](https://apps-st.fisheries.noaa.gov/stocksmart/?stockid=10062)

The final report and supporting PDFs are cached locally in
`source_cache/noaa_gray_triggerfish_gulf_sedar100_20261111/`. The tracked
manifest at `provenance/discovery_noaa_gulf_gray_triggerfish_2026/sources.csv`
records each source URL, retrieval date, checksum, local cache filename, and byte size.
