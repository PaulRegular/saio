# IPHC Pacific halibut, 2025 assessment

## Stock unit and assessment

The International Pacific Halibut Commission assesses one aggregate Convention Area stock, extending from California to the northern Bering Sea. The 2025 assessment is the latest completed official production assessment as of 9 November 2026. It is a full assessment using Stock Synthesis 3.30.23.1 and four equally weighted models: Coastwide long, Areas-As-Fleets (AAF) long, Coastwide short, and AAF short. The two long models reconstruct historical dynamics from 1888; the short models begin in 1992. AAF fits spatial datasets separately but retains one aggregate population.

The assessment data cutoff was 31 October 2025. Some 2025 commercial WPUE and age-composition data were incomplete, and mortality for fisheries still operating after the cutoff was projected. The assessment reports population estimates through the beginning of 2026.

## Sources and provenance

The assessment report, data-source report, time-series workbooks, and supporting biological documents are cached locally under the ignored `source_cache/discovery_iphc_pacific_halibut/` directory. Retrieval dates, source URLs, pinned revisions, file sizes, and SHA-256 checksums are recorded in `provenance/discovery_iphc_pacific_halibut/sources.csv`.

- [2025 assessment, IPHC-2026-SA-01](https://www.iphc.int/uploads/2025/12/IPHC-2026-SA-01.pdf)
- [Assessment data sources, IPHC-2026-SA-02](https://www.iphc.int/uploads/2025/12/IPHC-2026-SA-02.pdf)
- [IPHC stock assessment page and input-file access information](https://www.iphc.int/research/stock-assessment/)
- [Modelled FISS NPUE by regulatory area, TSD-001](https://www.iphc.int/uploads/2026/01/iphc-2026-tsd-001.xlsx)
- [Directed commercial landings by regulatory area, TSD-007](https://www.iphc.int/uploads/2026/01/iphc-2026-tsd-007.xlsx)
- [Mortality by source, TSD-009](https://www.iphc.int/uploads/2026/01/iphc-2026-tsd-009.xlsx)
- [Commercial fishery WPUE by regulatory area, TSD-010](https://www.iphc.int/uploads/2026/01/iphc-2026-tsd-010.xlsx)
- [Female spawning biomass from four assessment models, TSD-029](https://www.iphc.int/uploads/2026/01/iphc-2026-tsd-029.xlsx)

The official assessment page says the native model input files are available by permission from the IPHC Secretariat. No request was sent; the database uses public reports and tables only.

## Inputs captured

TSD-001 reports modelled FISS NPUE and CVs for eight regulatory-area series and a Coastwide series over 1993-2025. The 2025 assessment report states that the models fit directly to modelled FISS NPUE. The 297 point estimates and 297 CVs are imported. CV percentages are divided by 100 and stored as ratios; source-reported 95% index intervals are retained in row notes because the input schema has no interval columns. These area and Coastwide series are alternative spatial representations across the four-model ensemble and must not be summed as independent indices. TSD-001 was last revised on 6 November 2025, after the assessment cutoff, so the public workbook cannot be confirmed row-by-row against the exact run file.

TSD-007 reports directed commercial landings by IPHC regulatory area in tonnes for 1888-2025. Values are retained as published, including the workbook's conversion from net pounds and whole-tonne rounding. The Total column is not imported alongside its components. The 2025 values are marked preliminary. The historical `4` area label and later `4A`, `4B`, and `4CDE` labels are preserved as reported rather than redistributed.

TSD-009 reports annual mortality by source for 1888-2025. Directed commercial discards, recreational mortality, subsistence mortality, and non-directed commercial discard mortality are imported in tonnes. Its commercial-landings column and total are not imported as additional components: the directed landings are retained by area from TSD-007, and the roll-up values are not independent observations. The 2025 source values are preliminary; the assessment report states that the remaining season's mortality was projected.

TSD-010 reports directed commercial fishery WPUE by area and Coastwide, in kilograms per skate, for 1907-2025. These values are imported as a published fishery catch-rate series. This workbook contains no CVs, and the public materials do not provide a run-matched file that confirms its exact likelihood weighting. The 2025 values were incomplete at the cutoff.

The public TSD-002 and TSD-003 FISS WPUE workbooks were reviewed but not imported as additional likelihood indices. The assessment data-source report identifies FISS NPUE as the directly fitted survey series and describes FISS WPUE as supporting information for stock distribution and size-at-age. TSD-008 area mortality totals were also reviewed but not imported because the source-specific series are retained from TSD-009 and the totals are redundant.

## Assumptions and outputs captured

The assessment uses an updated histology-based maturity ogive. Female natural mortality is estimated in three models and fixed at 0.15 per year in the Coastwide short model; male natural mortality is estimated in all four. The source reports describe weight-at-age inputs assembled and smoothed from FISS, commercial-fishery, and NOAA Bering Sea trawl data. The complete run-specific numeric maturity and weight-at-age surfaces were not available in the public files reviewed.

TSD-029 reports model-specific female SSB in tonnes with lower and upper intervals for 1888-2026 in the long models and 1992-2026 in the short models. Its values are rounded to tonnes; the assessment report describes model series as maximum-likelihood estimates and approximate 95% credible intervals. This workbook was revised on 14 January 2026, after the assessment report was published, so it is retained as the published model-specific output series rather than treated as the native run file.

Table 1 of the assessment report separately provides the ensemble SSB median and approximate 95% credible interval for 1992-2026, SPR-based Fxx% fishing-intensity estimates through 2025, model-specific age-0 recruitment through 2020, and model-specific age-8+ biomass through 2026. These are imported in the units printed in the report: million pounds for SSB and age-8+ biomass, and million fish for age-0 recruitment. Fxx% is an SPR-based fishing-intensity measure; smaller percentages indicate greater intensity. It is not instantaneous F or F-at-age. No SE is reported for these table values.

## Remaining source gaps and discrepancies

- Exact catch-at-age numbers, age-composition likelihood vectors and effective sample sizes were not recovered.
- The public TSD-031 age-statistics workbook was revised on 18 June 2026, after the 2025 assessment cutoff. It includes later commercial age data and is not treated as the run-matched input for this assessment.
- Numeric run-specific weight-at-age and maturity-at-age inputs, age-specific survey abundance indices, and annual numerical N-at-age, F-at-age, and estimated M-at-age outputs were not found.
- The public age information and biology descriptions cannot establish the exact model ages, age-error likelihood inputs, or model-specific observation weights.
- TSD-009 reports 2023 total mortality of 15,690 tonnes while TSD-008 reports 15,685 tonnes. These source totals are left unreconciled. TSD-009's commercial-landings series also includes FISS-related mortality and should not be silently substituted for the area landings series in TSD-007.
- TSD-001 and TSD-029 were revised after the assessment cutoff/publication. The imported rows are attributed to those exact public workbook revisions; they are not claimed to be byte-for-byte the data consumed by the fitted model.

The canonical assessment is therefore partial. Public aggregate time series and assessment outputs are preserved, but the exact age-structured input files and numerical age-specific population outputs remain unavailable.
