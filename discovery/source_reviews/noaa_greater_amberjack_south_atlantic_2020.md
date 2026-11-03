# South Atlantic greater amberjack: SEDAR 59

- **Review date:** 2026-10-31
- **NOAA Stock SMART ID:** `10208`
- **Scientific name:** *Seriola dumerili*
- **Assessment unit:** South Atlantic U.S. EEZ within South Atlantic Fishery Management Council jurisdiction
- **Assessment year:** 2020
- **Terminal data year:** 2017

## Unit and assessment

NOAA lists South Atlantic greater amberjack as a distinct unit from Gulf of
Mexico greater amberjack (Stock SMART `10207`). The NOAA resource page still
describes the South Atlantic stock's status as based on the 2020 assessment.
The SEDAR project page identifies SEDAR 59 as the final South Atlantic
assessment report located in this review. Its integrated Beaufort Assessment
Model (BAM) run covers 1980–2017. No later completed production assessment was
found in the reviewed NOAA and SEDAR sources; current catch-based status updates
are not a new assessment run.

## Inputs and outputs found

The final report includes annual commercial and recreational landings and
discards for 1980–2017, three annual abundance-index series with CVs, and
age-specific biological inputs. Its Table 1 reports whole weight at age,
female maturity proportion at age, sex ratio, and age-dependent natural
mortality. Natural mortality is an input based on the Charnov curve and updated
growth information. Table 4 provides the headboat index (1980–2017), commercial
handline index (1993–2017), and SERFS video index (2011–2017). The indices are
aggregate, not age-specific; the assessment combines these series with
fishery age compositions.

The commercial handline paper, SEDAR59-WP05, provides numeric weighted age
compositions for 1998–2017. The recreational paper, SEDAR59-WP11, reports
annual age-sample counts and presents weighted age compositions in figures,
but does not tabulate the proportions. Those figure values can be recovered
only approximately by digitization unless the underlying numeric data are
located. Age-specific discards are not reported. SEDAR 59 Table 6 reports
estimated numbers at age (1000 fish, ages 1–10 with the terminal age grouping)
for 1980–2017; Table 7 reports biomass at age (1000 lb); Table 8 and the report
figures provide recruitment, SSB and fishing-mortality outputs.

The published sources therefore contain enough age-structured material to
proceed with source curation, while preserving explicit gaps in the recreational
composition vectors and discard ages. This is a source-curation eligibility
decision, not a claim that the inputs are already ready for a tinyAM fit.

## Timing and other extraction limits

The three indices enter the assessment as year-level annual observations; the
final report does not specify one within-year observation fraction. The index
methods retain different seasonal structures: the headboat method excludes
November–April for the terminal closure period, commercial handline
standardization uses May–June and July–September seasons, and the SERFS video
index models season from Julian-day quartiles. Any later tinyAM timing value
must be treated as an explicit approximation informed by those methods, rather
than copied from a reported common timing parameter.

The final report lists separate discard series, but an age composition for
discarded fish was not found in the reviewed sources. The recreational age
composition is figure-based; source digitization would retain that limitation
and must be recorded as a derived series. No native BAM model object or complete
machine-readable input package was identified in the reviewed project files.

## Screening decision

This is a **new, eligible** unit for age-structured source curation. It has
catch totals, commercial age compositions, plotted recreational age
compositions, abundance indices, age-specific biology and mortality, and
comparable age-specific and aggregate assessment outputs. The exact recreational
composition vectors, age-specific discards, and a single within-year index
timing remain unresolved source or translation details and should not be
fabricated. No canonical stock, assessment, input, output, or tinyAM translation
records were added during this screen.

## Sources

- NOAA Fisheries, [Greater Amberjack resources](https://www.fisheries.noaa.gov/species/greater-amberjack/resources).
- SEDAR, [SEDAR 59 project page](https://sedarweb.org/assessments/sedar-59/).
- NOAA InPort, [SEDAR 59 final assessment report](https://apps-st.fisheries.noaa.gov/sis/docServlet?fileAction=download&fileId=5755).
- SEDAR, [SEDAR59-WP05: commercial age and length composition weighting](https://sedarweb.org/documents/s59wp05-commercial-age-and-length-composition-weighting-for-u-s-greater-amberjack-seriola-dumerili/).
- SEDAR, [SEDAR59-WP11: recreational age and length composition](https://sedarweb.org/documents/s59wp11-south-atlantic-u-s-greater-amberjack-seriola-dummerili-age-and-length-composition-from-the-recreational-fisheries/).
- SEDAR, [SEDAR59-WP01: SERFS video index](https://sedarweb.org/documents/s59wp01-standardized-video-counts-of-southeast-u-s-atlantic-greater-amberjack-seriola-dumerili-from-the-southeast-reef-fish-survey/), [SEDAR59-WP03: headboat index](https://sedarweb.org/documents/s59wp03-standardized-catch-rates-of-greater-amberjack-seriola-dumerili-in-the-southeast-u-s-from-headboat-logbook-data/), and [SEDAR59-WP04: commercial handline index](https://sedarweb.org/documents/s59wp04-standardized-catch-rates-of-greater-amberjack-seriola-dumerili-in-the-southeast-u-s-from-commercial-logbook-data/).
- Cached source files and SHA-256 provenance are recorded in the gitignored `source_cache/discovery_noaa_south_atlantic_greater_amberjack_2020/sources.csv`.