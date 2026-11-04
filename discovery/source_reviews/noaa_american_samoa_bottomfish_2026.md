# NOAA American Samoa bottomfish assessment update (2026)

## Assessment and unit history

The NOAA Stock SMART snapshot retrieved 2026-10-28 lists the 2019 JABBA
multispecies-complex assessment (ID 11695, data through 2017) and nine 2023
species-specific Stock Synthesis assessments (IDs 11997-12215, data through
2021); all carry a `Full acceptance` review status in that source. The older
complex is a one-to-many predecessor and is not crosswalked to one current unit.

The latest detailed assessment is Oshima and Nadon's 2026 update (NOAA Technical
Memorandum NMFS-PIFSC-190), with data through 2025. The 2026 Western Pacific
Stock Assessment Review panel reviewed the update on May 18-19 and found it
complete, suitable for management decisions, and representative of the best
scientific information available. In 2025 the assessment focus changed from the
former 11-species BMUS list to six deep eteline snappers: *Aphareus rutilans*,
*Etelis boweni*, *E. carbunculus*, *E. coruscans*, *Pristipomoides flavipinnis*,
and *P. zonatus*. The update fits separate models for four species:

| NOAA Stock SMART ID | Species | 2026 treatment |
|---|---|---|
| 11998 | *Aphareus rutilans* | Separately assessed |
| 11997 | *Etelis coruscans* | Separately assessed; proposed indicator for the two confounded *Etelis* species |
| 12003 | *Pristipomoides flavipinnis* | Separately assessed |
| 12005 | *P. zonatus* | Separately assessed |
| no Stock SMART row in the pinned inventory | *Etelis boweni* | Not separately assessed; confounded with *E. carbunculus* |
| no Stock SMART row in the pinned inventory | *E. carbunculus* | Not separately assessed; confounded with *E. boweni* |

The five remaining 2023 Stock SMART species rows (*Aprion virescens*, *Caranx
lugubris*, *Variola louti*, *Lethrinus rubrioperculatus*, and *Lutjanus kasmira*)
are not part of the revised six-species list used by the 2026 update. Their 2023
outputs are retained as historical source evidence only and are not treated as
current assessment results. *P. filamentosus* is also removed from the current
list but is represented by the separate Main Hawaiian Islands deep-7 candidate
(Stock SMART ID 12442). That is a distinct assessment area and is not joined to
American Samoa.

## Data and model screen

The 2026 assessment is age-structured, but its documented data likelihoods are
aggregate annual catch, aggregate standardized CPUE, and length compositions.
The report describes historical catch from 1967-1985, boat- and shore-based
creel catch from 1986-2025, aggregate boat-based creel CPUE for bottomfishing
gear from 2016-2025, and length compositions from creel surveys plus
biosampling. It does not document catch-at-age, annual age compositions, or an
age-specific abundance index. Age-based population quantities are reconstructed
inside Stock Synthesis from growth, length data, catch, and aggregate CPUE; that
does not make the fitted observations age-disaggregated.

For the four assessed species, the model treats each population as a single
well-mixed American Samoa unit covering Tutuila, the Manu'a Islands, and nearby
banks. Growth and life history are time-invariant. Growth is sex-specific for
*E. coruscans* and *P. zonatus* and shared between sexes for the other two
assessed species. Natural mortality is fixed and constant with age, based on
longevity. Maturity is represented by length; SSB is female mature biomass.
The models use fixed steepness, Beverton-Holt recruitment without annual
recruitment deviations, and time-invariant selectivity. The report describes
spawning and recruitment in January. These are useful assumptions for source
context, but they do not supply the missing age-specific observations.

The species reports provide annual SSB, age-0 recruitment, and instantaneous
annual F through 2025 with CVs. They do not provide numeric N-at-age or
F-at-age time series. The 2023 report provides analogous aggregate annual
outputs through 2021 for its nine modeled species. No age-disaggregated
assessment-output series was located for this review.

## Candidate decisions

- NOAA 11997, 11998, 12003, and 12005 are new, distinct American Samoa stock
  units with a current official 2026 assessment. They are screened ineligible
  for the age-disaggregated candidate pool because the assessment uses length
  compositions and aggregate indices rather than age-specific input series;
  numeric age-specific outputs were not located.
- NOAA 11999, 12007, 12011, 12013, and 12215 remain distinct species-level
  identities but are legacy assessment entries outside the revised 2026
  assessment list. Their 2023 results are not substituted for current-unit
  assessments, so they are ineligible for the current candidate pool.
- NOAA 11695 is the superseded 2019 aggregate complex. Its one-to-many split
  across species makes a single candidate-unit crosswalk ambiguous; its
  aggregate model is ineligible for an age-disaggregated assessment set.
- The current 2026 report identifies *E. boweni* and *E. carbunculus* as two
  current management species that could not be modeled separately because the
  available data confound their identities. They have no separate fitted
  population outputs in this update. Neither appears as an independent row in
  the pinned Stock SMART inventory; they are documented here as part of the
  current unit review, not assigned invented NOAA identifiers.

No American Samoa stock, assessment, input, or output rows were added to the
canonical database. The 2026 update is a source-screening result, not a
complete age-disaggregated source record.

## Sources and cache

The 2023 NOAA report and 2026 WPSAR panel report are cached under the ignored
`source_cache/discovery_noaa_american_samoa_2026/` directory. Their retrieval
dates, URLs, and SHA-256 hashes are recorded in `sources.csv`. The latest 2026
PIFSC Technical Memorandum is publicly available at the NOAA repository URL
below; its online text and metadata were reviewed, but local download requests
returned HTTP 403. NOAA's repository record lists the source PDF SHA-512 as
`4618b48a4adc18886492b1ab5cb6352860caa6a15bc43ac61eab97c47a43b8bdebb731eda22fe36607cc193476d974287cb2223ab891c020170d954b374ed033`.
The 2019 PIFSC-86 report is cited for predecessor history; its PDF endpoint also
returned HTTP 403, so the official record was reviewed online instead. Neither
access-denied response was retained as if it were an assessment file.

- [2026 NOAA PIFSC report, NMFS-PIFSC-190](https://repository.library.noaa.gov/view/noaa/74402)
- [2026 WPSAR summary and individual reports](https://www.wpcouncil.org/wp-content/uploads/2026/04/09.E.21-WPSAR-for-AS-Bottomfish-stock-assessment-2026-update-Summary-Report-and-Individual-Reports.pdf)
- [2023 NOAA PIFSC report, NMFS-PIFSC-143](https://repository.library.noaa.gov/view/noaa/50907)
- [2019 NOAA PIFSC report, NMFS-PIFSC-86](https://repository.library.noaa.gov/view/noaa/21164)
- [Pinned NOAA Stock SMART snapshot](../../source_cache/discovery_noaa_stocksmart/stock_assessment_summary.rda)
