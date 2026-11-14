# South Atlantic greater amberjack: SEDAR 59

- **Review date:** 2026-11-10
- **NOAA Stock SMART ID:** `10208`
- **Scientific name:** *Seriola dumerili*
- **Assessment unit:** South Atlantic U.S. EEZ within South Atlantic Fishery Management Council jurisdiction
- **Assessment year:** 2020
- **Terminal data year:** 2017
- **Population estimates reported through:** 2018

## Unit and assessment

NOAA identifies South Atlantic greater amberjack as a distinct unit from Gulf
of Mexico greater amberjack (Stock SMART `10207`). The NOAA species page still
identifies the 2020 assessment as the basis for the South Atlantic stock's
status. SEDAR 59 is the latest completed detailed production assessment found
in this review. The accepted operational model is the Beaufort Assessment
Model (BAM).

## Data captured

The canonical database now contains the source-reported data recoverable from
SEDAR 59 Tables 1-4 and 6-8 and 11, plus the numeric commercial handline age
compositions in SEDAR59-WP05 Table 3:

- Table 1: mid-year total length and whole weight, female maturity, proportion
  female, and fixed age-specific natural mortality for model ages 1-10+. The
  source reports length in mm and weight in kg; those units are retained.
- Table 2: annual commercial landings in 1000 lb whole weight, general
  recreational landings in 1000 fish, and commercial and recreational discards
  in 1000 fish for 1980-2017. The 1980-1991 commercial-discard cells are not
  reported and remain absent.
- Table 3: the 1980-2017 landings/discard CVs reported for the assessment
  ensemble. It provides CVs for general-recreational landings, commercial
  handline landings, and general-recreational discards; no commercial-discard
  CV is provided.
- Table 4: annual aggregate headboat abundance indices (1980-2017), commercial
  handline indices (1993-2017), and SERFS video indices (2011-2017), with
  source-reported CVs. The annual table does not provide one within-year timing
  fraction for these series.
- WP05 Table 3: weighted commercial handline age proportions for 1998-2004
  and 2007-2017, source ages 1-15, with fish and trip counts. Printed zero
  proportions are retained. The assessment report states that the panel kept
  the terminal-year compositions for 2016 and 2017 despite their not meeting
  the usual sample-size thresholds.
- Tables 6, 7, 8, and 11: abundance-at-age (1000 fish), total abundance,
  age-1 recruitment, biomass-at-age (1000 lb), total biomass and mature-female
  SSB (metric tons), apical F and F-at-age (per year), plus the reported
  biomass/status ratios. Population tables extend through 2018 although fitted
  observations end in 2017. The source defines age 10 as the 10+ accumulation
  group.

The import contains 714 input rows, 14 assumptions, and 1,545 point-output
rows. Output standard errors and confidence limits are unavailable in these
tables and are left blank. Recruitment is stored as Table 6 age-1 abundance at
the start of year, consistent with the assessment's age-1 recruitment
definition.

The WP05 proportions remain in their published ages 1-15. The assessment's
age-10-plus grouping is not applied to these source observations in the
canonical database. The reported `n.fish` count is stored as the sample size;
`n.trips` is retained in the row notes. These counts document sampling and are
not presented as effective likelihood sample sizes.

## Source gaps

- SEDAR59-WP11 and the final report show recreational age compositions in
  figures, but the reviewed sources do not tabulate their numeric vectors.
  They were not digitized or inferred.
- The reports do not provide age-specific discard compositions.
- No native fitted BAM object or complete machine-readable input package was
  found.
- The aggregate index table does not establish a single observation timing
  fraction.
- The source tables provide point estimates but no annual output uncertainty
  values in the imported tables.

Accordingly, assumptions, inputs, and outputs are all marked partial. This
record preserves the current assessment's verified information without using
an older unit or assessment to fill its gaps.

## Sources

- NOAA Fisheries, [Greater Amberjack resources](https://www.fisheries.noaa.gov/species/greater-amberjack/resources).
- SEDAR, [SEDAR 59 project page](https://sedarweb.org/assessments/sedar-59/).
- NOAA InPort, [SEDAR 59 final assessment report](https://apps-st.fisheries.noaa.gov/sis/docServlet?fileAction=download&fileId=5755).
- SEDAR, [SEDAR59-WP05: commercial age and length composition weighting](https://sedarweb.org/documents/s59wp05-commercial-age-and-length-composition-weighting-for-u-s-greater-amberjack-seriola-dumerili/).
- SEDAR, [SEDAR59-WP11: recreational age and length composition](https://sedarweb.org/documents/s59wp11-south-atlantic-u-s-greater-amberjack-seriola-dumerili-age-and-length-composition-from-the-recreational-fisheries/).
- SEDAR, [SEDAR59-WP01: SERFS video index](https://sedarweb.org/documents/s59wp01-standardized-video-counts-of-southeast-u-s-atlantic-greater-amberjack-seriola-dumerili-from-the-southeast-reef-fish-survey/), [SEDAR59-WP03: headboat index](https://sedarweb.org/documents/s59wp03-standardized-catch-rates-of-greater-amberjack-seriola-dumerili-in-the-southeast-u-s-from-headboat-logbook-data/), and [SEDAR59-WP04: commercial handline index](https://sedarweb.org/documents/s59wp04-standardized-catch-rates-of-greater-amberjack-seriola-dumerili-in-the-southeast-u-s-from-commercial-logbook-data/).
- Cached files, retrieval dates, URLs, and SHA-256 checksums are recorded in `provenance/discovery_noaa_greater_amberjack_south_atlantic_2020/sources.csv`; local PDFs and text extracts are under the gitignored source cache.
