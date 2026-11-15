# Pacific halibut (iphc_pacific_halibut)

## IPHC Pacific halibut, 2025 assessment

SAIO stock `iphc_pacific_halibut`. Assessment `iphc_pacific_halibut_2025`.

### Stock unit and assessment

The International Pacific Halibut Commission assesses one aggregate Convention Area stock, extending from California to the northern Bering Sea. The 2025 assessment is the latest completed official production assessment as of 9 November 2026. It is a full assessment using Stock Synthesis 3.30.23.1 and four equally weighted models: Coastwide long, Areas-As-Fleets (AAF) long, Coastwide short, and AAF short. The two long models reconstruct historical dynamics from 1888; the short models begin in 1992. AAF fits spatial datasets separately but retains one aggregate population.

The assessment data cutoff was 31 October 2025. Some 2025 commercial WPUE and age-composition data were incomplete, and mortality for fisheries still operating after the cutoff was projected. The assessment reports population estimates through the beginning of 2026.

### Sources and provenance

The assessment report, data-source report, time-series workbooks, and supporting biological documents are cached locally under the ignored `source_cache/hippoglossus_stenolepis/iphc_pacific_halibut/` directory. Retrieval dates, source URLs, pinned revisions, file sizes, and SHA-256 checksums are recorded in `provenance/discovery_iphc_pacific_halibut/sources.csv`.

- [2025 assessment, IPHC-2026-SA-01](https://www.iphc.int/uploads/2025/12/IPHC-2026-SA-01.pdf)
- [Assessment data sources, IPHC-2026-SA-02](https://www.iphc.int/uploads/2025/12/IPHC-2026-SA-02.pdf)
- [IPHC stock assessment page and input-file access information](https://www.iphc.int/research/stock-assessment/)
- [Modelled FISS NPUE by regulatory area, TSD-001](https://www.iphc.int/uploads/2026/01/iphc-2026-tsd-001.xlsx)
- [Directed commercial landings by regulatory area, TSD-007](https://www.iphc.int/uploads/2026/01/iphc-2026-tsd-007.xlsx)
- [Mortality by source, TSD-009](https://www.iphc.int/uploads/2026/01/iphc-2026-tsd-009.xlsx)
- [Commercial fishery WPUE by regulatory area, TSD-010](https://www.iphc.int/uploads/2026/01/iphc-2026-tsd-010.xlsx)
- [Female spawning biomass from four assessment models, TSD-029](https://www.iphc.int/uploads/2026/01/iphc-2026-tsd-029.xlsx)

The official assessment page says the native model input files are available by permission from the IPHC Secretariat. No request was sent; the database uses public reports and tables only.

### Inputs captured

TSD-001 reports modelled FISS NPUE and CVs for eight regulatory-area series and a Coastwide series over 1993-2025. The 2025 assessment report states that the models fit directly to modelled FISS NPUE. The 297 point estimates and 297 CVs are imported. CV percentages are divided by 100 and stored as ratios; source-reported 95% index intervals are retained in row notes because the input schema has no interval columns. These area and Coastwide series are alternative spatial representations across the four-model ensemble and must not be summed as independent indices. TSD-001 was last revised on 6 November 2025, after the assessment cutoff, so the public workbook cannot be confirmed row-by-row against the exact run file.

TSD-007 reports directed commercial landings by IPHC regulatory area in tonnes for 1888-2025. Values are retained as published, including the workbook's conversion from net pounds and whole-tonne rounding. The Total column is not imported alongside its components. The 2025 values are marked preliminary. The historical `4` area label and later `4A`, `4B`, and `4CDE` labels are preserved as reported rather than redistributed.

TSD-009 reports annual mortality by source for 1888-2025. Directed commercial discards, recreational mortality, subsistence mortality, and non-directed commercial discard mortality are imported in tonnes. Its commercial-landings column and total are not imported as additional components: the directed landings are retained by area from TSD-007, and the roll-up values are not independent observations. The 2025 source values are preliminary; the assessment report states that the remaining season's mortality was projected.

TSD-010 reports directed commercial fishery WPUE by area and Coastwide, in kilograms per skate, for 1907-2025. These values are imported as a published fishery catch-rate series. This workbook contains no CVs, and the public materials do not provide a run-matched file that confirms its exact likelihood weighting. The 2025 values were incomplete at the cutoff.

The public TSD-002 and TSD-003 FISS WPUE workbooks were reviewed but not imported as additional likelihood indices. The assessment data-source report identifies FISS NPUE as the directly fitted survey series and describes FISS WPUE as supporting information for stock distribution and size-at-age. TSD-008 area mortality totals were also reviewed but not imported because the source-specific series are retained from TSD-009 and the totals are redundant.

### Assumptions and outputs captured

The assessment uses an updated histology-based maturity ogive. Female natural mortality is estimated in three models and fixed at 0.15 per year in the Coastwide short model; male natural mortality is estimated in all four. The source reports describe weight-at-age inputs assembled and smoothed from FISS, commercial-fishery, and NOAA Bering Sea trawl data. The complete run-specific numeric maturity and weight-at-age surfaces were not available in the public files reviewed.

TSD-029 reports model-specific female SSB in tonnes with lower and upper intervals for 1888-2026 in the long models and 1992-2026 in the short models. Its values are rounded to tonnes; the assessment report describes model series as maximum-likelihood estimates and approximate 95% credible intervals. This workbook was revised on 14 January 2026, after the assessment report was published, so it is retained as the published model-specific output series rather than treated as the native run file.

Table 1 of the assessment report separately provides the ensemble SSB median and approximate 95% credible interval for 1992-2026, SPR-based Fxx% fishing-intensity estimates through 2025, model-specific age-0 recruitment through 2020, and model-specific age-8+ biomass through 2026. These are imported in the units printed in the report: million pounds for SSB and age-8+ biomass, and million fish for age-0 recruitment. Fxx% is an SPR-based fishing-intensity measure; smaller percentages indicate greater intensity. It is not instantaneous F or F-at-age. No SE is reported for these table values.

### Remaining source gaps and discrepancies

- Exact catch-at-age numbers, age-composition likelihood vectors and effective sample sizes were not recovered.
- The public TSD-031 age-statistics workbook was revised on 18 June 2026, after the 2025 assessment cutoff. It includes later commercial age data and is not treated as the run-matched input for this assessment.
- Numeric run-specific weight-at-age and maturity-at-age inputs, age-specific survey abundance indices, and annual numerical N-at-age, F-at-age, and estimated M-at-age outputs were not found.
- The public age information and biology descriptions cannot establish the exact model ages, age-error likelihood inputs, or model-specific observation weights.
- TSD-009 reports 2023 total mortality of 15,690 tonnes while TSD-008 reports 15,685 tonnes. These source totals are left unreconciled. TSD-009's commercial-landings series also includes FISS-related mortality and should not be silently substituted for the area landings series in TSD-007.
- TSD-001 and TSD-029 were revised after the assessment cutoff/publication. The imported rows are attributed to those exact public workbook revisions; they are not claimed to be byte-for-byte the data consumed by the fitted model.

The canonical assessment is therefore partial. Public aggregate time series and assessment outputs are preserved, but the exact age-structured input files and numerical age-specific population outputs remain unavailable.

## Pacific halibut: NOAA and DFO inventory crosswalk

### Identity and current assessment

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

### Age-disaggregated data evidence

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

### Outputs, limitations, and screen

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

### Sources

- [IPHC 2025 stock assessment (IPHC-2026-SA-01)](https://www.iphc.int/uploads/2025/12/IPHC-2026-SA-01.pdf)
- [IPHC assessment data overview (IPHC-2026-SA-02)](https://www.iphc.int/uploads/2025/12/IPHC-2026-SA-02.pdf)
- [IPHC time-series datasets](https://www.iphc.int/data/time-series-datasets/)
- [IPHC FISS Pacific halibut raw data](https://www.iphc.int/data/fiss-pacific-halibut-data/)
- [IPHC directed-commercial length and age statistics](https://www.iphc.int/data/directed-commercial-pacific-halibut-length-and-age-statistics/)
- [IPHC commercial landings by regulatory area](https://www.iphc.int/data/fishery-landings-by-iphc-regulatory-area/)

The assessment PDFs, public FISS file, and relevant IPHC spreadsheets are
cached under `source_cache/hippoglossus_stenolepis/iphc_pacific_halibut/`, with checksums,
retrieval date and pinned source identifiers recorded in `sources.csv`.
