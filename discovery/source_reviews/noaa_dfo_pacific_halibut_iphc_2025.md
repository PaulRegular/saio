# Pacific halibut: NOAA and DFO inventory crosswalk

## Identity and current assessment

NOAA Stock SMART 11082 and the DFO Pacific halibut sustainability-survey entry
refer to the single Pacific halibut resource assessed by the International
Pacific Halibut Commission (IPHC). The Convention Area spans Canada and the
United States, from California to the northern Bering Sea. They are crosswalked to one
provisional discovery unit, `iphc_pacific_halibut`, and count as one stock unit,
not two.

The current detailed official assessment is IPHC-2026-SA-01, the 2025
assessment, which updates data through 31 October 2025. It is a full Stock
Synthesis assessment with four equally weighted models: long and short time
series, each in coastwide and Areas-as-Fleets forms. Natural mortality and
spatial structure differ among the component models. The NOAA inventory says
2024 and the DFO survey row is not an assessment-run identifier; neither should
be used to date the current assessment.

## Age-disaggregated data evidence

The official IPHC time-series catalogue provides modelled FISS NPUE by
regulatory area for 1993-2025. The downloadable TSD-001 table reports numbers
per standardized skate, CVs and 95% intervals. The public FISS individual-fish
file covers 1998-2025 and includes year, station, sex, maturity, fork length
and age. It contains 2,273,521 records, of which 365,576 have resolved ages
(ages 3-55 in the downloaded file). These age samples can support age
proportions for sampled area-years and a documented age split of the aggregate
NPUE index. IPHC does not extrapolate age samples to areas not surveyed in a
given year.

The IPHC-2026-TSD-031 workbook provides directed-commercial age-frequency
counts by year, regulatory area, age and sex for 1993-2025 (412,218 specimen
counts across table rows). The data overview states that port otoliths are
sampled in proportion to landings within area and year. IPHC-2026-TSD-007
provides commercial landings by regulatory area in net weight for 1888-2025;
the 2025 landing values are marked preliminary. Together, these sources support
a source-based catch-at-age reconstruction, with a documented weight
conversion needed to express the catch in numbers. Regulatory areas are sampled
at different rates by weight, so the TSD-031 age frequencies must not be
combined coastwide without the IPHC expansion method.

The 2025 assessment overview also documents age-specific weights, weight-at-age
smoothing, age distributions, and maturity. The 2025 female maturity ogive was
updated from histology collected in 2022-2024 and is shown in the report. The
public FISS file contains fork length rather than a direct weight field; IPHC's
published length-weight relationship supports documented weight reconstruction.
The numerical run-specific weight and maturity vectors were not located in the
public files reviewed.

The FISS is an annual summer survey, conducted over late May-September. Sources
establish a seasonal timing window but not one single common within-year
fraction. The age structure and observation rows also require care around the IPHC's
age-reading conventions: age groups are combined differently before and after
2002.

## Outputs, limitations, and screen

The 2025 assessment reports female spawning biomass with approximate 95%
credible intervals, recruitment, age-8+ biomass, and fishing-intensity
estimates. The downloadable TSD-029 table gives annual spawning-biomass
estimates and intervals separately for all four assessment models, from 1888
through 2026. Public numeric historical N-at-age and F-at-age arrays were not
located.

The four native Stock Synthesis input files are listed on the official
assessment page, which asks users to contact the IPHC Secretariat for their
contents and permission to use them. The public sources support an eligible
source-curation candidate and documented age-based reconstructions, but not an
exact reproduction of the four-model likelihood. TSD-031 was revised on
2026-06-18, after the 2025 assessment cutoff; its 2025 values are preliminary,
and earlier revisions may also differ from the pinned run. These later values
must be compared with the assessment-vintage evidence before importing them as
2025 run inputs.

No canonical assessment or numerical input/output records have been added by
this discovery screen. The NOAA and DFO candidate rows are marked as one
provisional new unit, eligible for source curation, with import status still
not started.

## Sources

- [IPHC 2025 stock assessment (IPHC-2026-SA-01)](https://www.iphc.int/uploads/2025/12/IPHC-2026-SA-01.pdf)
- [IPHC assessment data overview (IPHC-2026-SA-02)](https://www.iphc.int/uploads/2025/12/IPHC-2026-SA-02.pdf)
- [IPHC time-series datasets](https://www.iphc.int/data/time-series-datasets/)
- [IPHC FISS Pacific halibut raw data](https://www.iphc.int/data/fiss-pacific-halibut-data/)
- [IPHC directed-commercial length and age statistics](https://www.iphc.int/data/directed-commercial-pacific-halibut-length-and-age-statistics/)
- [IPHC commercial landings by regulatory area](https://www.iphc.int/data/fishery-landings-by-iphc-regulatory-area/)

The assessment PDFs, public FISS file, and relevant IPHC spreadsheets are
cached under `source_cache/discovery_iphc_pacific_halibut/`, with checksums,
retrieval date and pinned source identifiers recorded in `sources.csv`.
