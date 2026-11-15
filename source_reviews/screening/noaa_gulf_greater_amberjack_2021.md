# Gulf of Mexico greater amberjack, SEDAR 70 (2020)

## Unit and assessment status

NOAA Stock SMART row 10207 identifies the Gulf of Mexico greater amberjack
(*Seriola dumerili*) unit. No matching stock record was found in the canonical
database, so this is a provisional new unit. The latest detailed operational
assessment located is SEDAR 70, completed in 2020, with a terminal data year of
2018. The SEDAR executive summary states that the Gulf Council Scientific and
Statistical Committee accepted the operational model as the best scientific
information available and appropriate for management advice. NOAA's 2023
framework action still cites SEDAR 70 as the current assessment informing its
management response. Stock SMART's 2021 metadata year is not the model's
terminal year.

## Inputs and outputs

The Stock Synthesis model covers ages 0-10+ and four fleets: commercial
vertical line/handline, commercial longline, recreational charter/private,
and headboat. Commercial landings are in weight and recreational landings are
in numbers; discard series are included. The assessment fits commercial age
compositions for handline in 2001-2017 and longline in 2009, 2011, and
2013-2014, and recreational compositions for charter/private in 2002-2018 and
headboat in 1994-2016. SEDAR70-WP-13 describes fleet-specific reweighting of
age samples to the final length compositions. The available PDF gives sample
information and plotted compositions, but not the numerical year-by-fleet-by-
age matrices required to reconstruct exact catch-at-age.

The model uses commercial longline, recreational headboat and charter/private
CPUE indices, plus a combined fishery-independent video index for 1995-1997,
2002, and 2004-2018. The Panama City laboratory video series is an aggregate
MaxN-based abundance index. Its documented age-based index is for other reef
fish, and no greater-amberjack survey age-composition likelihood was verified.
The survey does age selected trap-caught fish for life-history work, but those
samples are not a continuous annual survey age-composition series. The Panama
City survey samples May-November, primarily June-August; an exact annual timing
fraction for the combined index was not established.

A fixed weight-length relationship is used to convert lengths to biomass, with
weight-at-age generated inside the model using growth. SSB is mature-female
biomass. The model uses a fixed maturity schedule based on a logistic
length-at-50%-maturity of 82.7 cm, excludes age-0 fish from SSB, and applies an
age-specific Lorenzen M schedule scaled to 0.28 per year at ages 3+. The base
model does not estimate M.

The report provides annual total abundance, total biomass, and SSB for
1950-2018 with 95% confidence intervals, together with recruitment and F
summaries. Its reported F is a harvest rate (biomass killed among ages 1+ over
exploitable biomass ages 1+), not instantaneous F-at-age. Numeric annual
population N-at-age and F-at-age arrays were not verified.

## Screening decision

The official report supplies comparable aggregate population outputs, but
exact age-composition inputs were not recovered from the public report files,
and there is no greater-amberjack survey age-composition series to construct an
age-specific index. Eligibility therefore remains unresolved pending recovery
of numeric composition matrices or a run-matched native input archive. Do not
use the report's age-composition plots as exact observations. No canonical
assessment records or numerical values were added.

## Sources

- [SEDAR 70 assessment page](https://sedarweb.org/assessments/sedar-70/)
- [Final operational assessment report](https://sedarweb.org/documents/sedar-70-gulf-of-mexico-greater-amberjack-final-stock-assessment-report/)
- [Executive summary and SSC acceptance](https://sedarweb.org/documents/sedar-70-gulf-of-mexico-greater-amberjack-executive-summary-report/)
- [WP-07 combined video survey indices](https://sedarweb.org/documents/sedar-70-wp-07-indices-of-abundance-for-greater-amberjack-seriola-dumerili-using-combined-data-from-three-independent-video-surveys/)
- [WP-10 growth model](https://sedarweb.org/documents/sedar-70-wp-10-gulf-of-mexico-greater-amberjack-seriola-dumerili-growth-model-for-sedar-70-operational-assessment/)
- [WP-11 fishery CPUE indices](https://sedarweb.org/documents/sedar-70-wp-11-standardized-catch-rate-indices-for-greater-amberjack-seriola-dumerili-during-1990-2018-by-the-u-s-gulf-of-mexico-vertical-line-and-longline-fisheries/)
- [WP-12 Panama City camera/trap survey](https://sedarweb.org/documents/sedar-70-wp-12-greater-amberjack-seriola-dumerili-findings-from-the-nmfs-panama-city-laboratory-camera-trap-fishery-independent-survey-2006-2018/)
- [WP-13 commercial and recreational length/age compositions](https://sedarweb.org/documents/sedar-70-wp-13-gulf-of-mexico-greater-amberjack-seriola-dumerili-commercial-and-recreational-length-and-age-compositions/)
- [2023 Gulf framework action](https://www.fisheries.noaa.gov/s3/2024-01/GAJ-Framework-Action-508-FINAL.pdf)
- [NOAA Stock SMART row 10207](https://apps-st.fisheries.noaa.gov/stocksmart/?stockid=10207)

The reviewed PDFs are cached in the ignored local source cache under
`source_cache/discovery_noaa_gom_greater_amberjack_2021/`; its `sources.csv`
manifest records the source URLs, retrieval date and SHA-256 checksums.