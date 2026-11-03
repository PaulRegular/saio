# Eastern Georges Bank haddock cross-inventory screen

## Stock identity

DFO identifies Eastern Georges Bank haddock as the transboundary stock in NAFO
Division 5Zjm, covering unit areas 5Zj and 5Zm. NOAA Stock SMART has a separate
Eastern Georges Bank haddock entry, ID 12806. Its cached metadata lists accepted
operational WHAM assessments through 2023, with the latest assessment using data
through 2022. These records refer to the same management unit and are linked by
candidate_unit_id = haddock_eastern_georges_bank; neither is currently matched
to a canonical DFO Eastern Georges Bank haddock record.

NOAA Stock SMART ID 10520 is the broader U.S. Georges Bank haddock assessment,
already represented by nefsc_haddock_georges_bank. It is not substituted for
the Eastern Georges Bank unit. DFO's Groundfish 4VWX5 management plan identifies EGB as 5Zjm and states it is
jointly managed with the United States. DFO and NOAA have used separate
domestic assessment processes since the 2024 review, so their run-specific input
and output records must remain separate.

## Assessment runs and source access

The most recent DFO assessment located is through 2024, reported in Science
Advisory Report 2025/040. It reports 2024 SSB of 27,343 mt, age-1 recruitment
of 90 million for the 2020 year class and 69 million for 2021, fully selected
F of 0.31 in 2024, a five-year average F of 0.48, and mean M of 0.502 for
2010-2024. These are aggregate outputs; numerical annual N/F/M-at-age arrays
are not reported there.

The official catalogue lists Research Document 2026/048 as the detailed report
for the 2024 DFO assessment. The catalogue HTML is cached, but its linked PDF
redirected to the Government of Canada archived-page notice when requested on
2026-10-29. The older direct CSAS PDF route also returned HTML rather than a PDF. The report
must not be treated as reviewed until its content can be retrieved. DFO Science
Advisory Report 2024/056, the accessible report for the earlier assessment
through 2023, is cached and used only to describe model structure and historical
input coverage.

For NOAA, the pinned Stock SMART snapshot identifies stock 12806's latest
assessment as a full-acceptance operational WHAM run in 2023 (assessment ID
12830; last data year 2022). The official 2023 TRAC status report is available
at the NOAA repository landing page, but its PDF endpoint returned HTTP 403
during this review. The cached Stock SMART metadata contains model labels and
input-category counts, not numerical observation arrays or age-specific output
surfaces.

## Age-input and output screen

DFO's 2024/056 Table A1 describes the assessment through 2023 as a statistical
catch-at-age model with one aggregate fleet. Inputs include aggregate catch
biomass, annual fishery age compositions in numbers for ages 1-9+ (1969-2023),
and effective sample size 70. Catch numbers-at-age are not tabulated and would
require the source age-composition values and fishery weights.

The same table identifies three survey series: NMFS spring (1969-1972 and
1982-2022), NMFS fall (1969-2023), and DFO spring (1987-2023). Their inputs are
annual aggregate mean-number-per-tow indices plus survey age compositions for
ages 1-9+, with effective sample size 40. The report gives survey months 3, 9,
and 2, respectively, and spawning time 0.25. The composition and index arrays
are not provided as numerical tables in this report. The latest DFO update adds
the 5Z9 stratum to the winter survey, so the older observation matrices cannot
be assumed to match the 2024 run.

Table A1 identifies annual fishery weights-at-age, spawning-stock weights-at-age,
and maturity-at-age for 1969-2023. Table A3 gives selected 2021-2023 projection
vectors in kg and maturity proportions, not the complete historical arrays for
the latest assessment. The older base model fixed age- and time-invariant M at
0.2 for 1969-2009 and estimated a common age-invariant M for 2010-2023. The
2024 update reports mean M=0.502 for 2010-2024, but its detailed age/time
configuration remains to be checked in Research Document 2026/048.

The source materials verify that both assessment programmes use age-structured
WHAM models for this unit and report comparable aggregate SSB, recruitment, and
F. They do not currently verify numerical input arrays or age-specific population
outputs for the latest run. The unit is therefore screened, eligibility
unresolved. It is not excluded: the limiting issue is access to run-matched
source arrays, not evidence that the model lacks age structure.

## Sources and cached files

- DFO, 2025, Science Advisory Report 2025/040, assessment through 2024:
  https://publications.gc.ca/collections/collection_2025/mpo-dfo/fs70-6/Fs70-6-2025-040-eng.pdf
- DFO, 2024, Science Advisory Report 2024/056, assessment through 2023:
  https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41266122.pdf
- DFO Research Document 2026/048 catalogue record:
  https://publications.gc.ca/site/eng/9.963875/publication.html
- NOAA Eastern Georges Bank Haddock TRAC Status Report 2023/01:
  https://repository.library.noaa.gov/view/noaa/55818
- NOAA Stock SMART metadata: pinned snapshot documented in discovery/README.md.

Local DFO reports and the catalogue page, retrieval URLs, and SHA-256 checksums
are recorded in the gitignored source cache manifest. The management-plan page
is cached with the earlier DFO 5Zjm identity review.
NOAA's repository PDF could not be cached because the endpoint returned HTTP 403.
