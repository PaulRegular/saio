# Gulf of Mexico red grouper, SEDAR 88

Reviewed 2026-10-30. NOAA Stock SMART 10331 is the Gulf of Mexico management
unit. It is distinct from South Atlantic red grouper (Stock SMART 10332).

The most recent full production assessment is SEDAR 88, completed in 2025 with
data through 2022 and assessed using Stock Synthesis 3.30.21.0. Stock SMART
assessment 13943 records full acceptance. The 2026 Stock SMART monitoring
update (assessment 14350) has the review result “Remand” and the same terminal
data year, so it is not treated as a replacement production run. Use the SEDAR
88 final report revision dated December 10, 2025: its document history says
Tables 5, 7, 8 and 19 were corrected after the February release.

SEDAR 88 fits commercial and recreational landings, discards, weighted landing
age compositions, fishery-dependent CPUE and three fishery-independent indices.
The commercial handline landing age compositions cover 1991-2022, longline
1993-2022, and trap 1991-2006; trap years are pooled as one super-period because
of low sample sizes. Recreational landing age compositions cover 1991-2022.
Compositions use annual age bins with a 20+ plus group. Their figures and
working papers document the series and weighting methods, but the annual
proportions must be digitized; the sources reviewed do not expose the full
run-matched matrices as machine-readable inputs. Commercial and recreational
catch totals are reported separately, in metric tons gutted weight for
commercial fleets and thousands of fish for recreational landings. Catch
totals and compositions must remain separate in the canonical records.

The assessment's three fishery-independent indices are Combined Video Survey
(1993-2022), SEAMAP Summer Groundfish Survey (2009-2022), and NMFS Bottom
Longline Survey (2001-2022). It also uses commercial handline and longline
indices from 1993-2009 and a recreational headboat index from 1986-2007. The
survey likelihoods use aggregate indices and length compositions; the report's
input inventory does not include survey age compositions or age-specific survey
indices. Do not turn fitted selectivity, abundance, or catch compositions into
survey observations. Timing is described by season and, for the NMFS Bottom Longline index, by
area-specific August sampling in the eastern Gulf and September sampling in the
central and western Gulf; a small number of early October 2022 stations were
retained. SEAMAP uses its summer series, while the combined video index pools
surveys with different sampling months. These sources establish seasonal windows
but not one run-level fractional timing for each pooled index.

Stock Synthesis begins at age 0 and extends the population age range to 29.
Growth uses a von Bertalanffy relationship and a fixed length-weight conversion.
Maturity and sex-transition schedules are carried forward from SEDAR 42.
Natural mortality is a time-invariant, age-dependent Lorenzen schedule using
the Hamel-Cope point estimate Mtarget = 5.4/29 = 0.186; sensitivities use
maximum ages 24 and 34. Reproductive output is modeled as relative egg
production, so reported SSB is not directly comparable to biomass-based SSB.

The corrected report provides annual age-0 recruitment, total and exploitable
biomass, exploitable abundance, egg-production SSB and the SSB ratio for
1986-2022. It also reports exploitation rates. Numerical N-at-age and F-at-age
surfaces appear only in figures, and annual uncertainty for the population
time series was not found in the reviewed tables. No SEDAR-linked Stock
Synthesis input/control/output bundle or fitted model object was located.

## Curation decision

This current unit is eligible for partial source curation. The corrected report
contains run-specific catch, weighted fishery age-composition, aggregate index,
age-specific natural-mortality and population-output information. The age
composition matrices are figure-only, survey indices are not age-specific, and
some biological and timing details remain unavailable. These limits are retained
as source gaps; eligibility does not mean that all model inputs are recoverable.

The age-composition and aggregate-index inputs are valuable
for source curation, but the assessment does not fit age-specific survey indices,
and the pooled indices lack a single documented fractional sampling time. Its
distinct SSB definition and
figure-based age inputs also limit direct comparison. Preserve the corrected
production report and supporting working papers in the ignored local cache at
`source_cache/discovery_noaa_red_grouper_gom_2025/`; `sources.csv` records each
URL, retrieval date, revision, size and SHA-256.

The partial import records 1,083 source input rows, 12 assessment assumptions,
and 444 output rows from Tables 4-10 and 13-15 of the corrected report. It
includes reported commercial and recreational catches, aggregate CPUE indices,
female natural mortality at ages 0-29, exploitation rates, and annual population
summaries. Figure-only age compositions, age-specific survey indices, numerical
N-at-age and F-at-age, and output uncertainty remain unavailable and were not
transcribed or inferred.

Sources:

- [SEDAR 88 Gulf of Mexico Red Grouper project](https://sedarweb.org/assessments/sedar-88-gulf-of-mexico-red-grouper/)
- [SEDAR 88 final assessment report, updated December 2025](https://sedarweb.org/documents/sedar-88-gulf-of-mexico-red-grouper-final-stock-assessment-report-updated-december-2025/)
- [SEDAR 88 WP-03: Commercial landings, 1986-2022](https://sedarweb.org/documents/sedar-88-wp-03-commercial-landings-of-gulf-of-mexico-red-grouper-epinephelus-morio-from-1986-2022/)
- [SEDAR 88 WP-06: Recreational length and age compositions](https://sedarweb.org/documents/sedar-88-wp-06-gulf-of-mexico-red-grouper-epinephelus-morio-length-and-age-compositions-from-the-recreational-fishery/)
- [SEDAR 88 WP-09: Commercial length and age compositions](https://sedarweb.org/documents/sedar-88-wp-09-gulf-of-mexico-red-grouper-epinephelus-morio-commercial-landings-length-and-age-compositions/)
- [SEDAR 88 WP-10: Headboat CPUE index](https://sedarweb.org/documents/sedar-88-wp-10-standardized-catch-per-unit-effort-for-gulf-of-mexico-red-grouper-from-the-southeast-region-headboat-survey/)
- [SEDAR 88 WP-11: Age-length data, 1978-2022](https://sedarweb.org/documents/sedar-88-wp-11-a-review-of-the-gulf-of-mexico-red-grouper-epinephelus-morio-age-length-data-1978-2022/)
- [SEDAR 88 WP-12: NMFS Bottom Longline index](https://sedarweb.org/documents/sedar-88-wp-12-an-index-of-relative-abundance-for-red-grouper-captured-during-the-nmfs-bottom-longline-survey-in-the-northern-gulf-of-mexico/)
- [SEDAR 88 WP-13: SEAMAP Groundfish indices](https://sedarweb.org/documents/sedar-88-wp-13-red-grouper-abundance-indices-from-seamap-groundfish-surveys-in-the-northern-gulf-of-mexico/)
- [SEDAR 88 WP-16: Combined video index](https://sedarweb.org/documents/sedar-88-wp-16-combined-indices-of-abundance-for-red-grouper-epinephelus-morio-in-the-eastern-gulf-of-mexico-using-data-from-three-historic-video-surveys-and-unified-g-fisher-program/)
