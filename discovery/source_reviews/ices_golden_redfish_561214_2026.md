# ICES golden redfish, subareas 5, 6, 12 and 14

Review date: 2026-11-02

## Unit and current assessment

ICES stock reg.27.561214 is the golden redfish (Sebastes norvegicus) unit in
subareas 5, 6, 12 and 14. It is distinct from the Northeast Arctic unit
reg.27.1-2, which is already represented in the database.

The latest detailed production assessment used for advice is the 2026 SAM
assessment, with input data through 2025. The MFRI technical report and tables
are run-specific; ICES Stock Assessment Graphs source data provide the annual
summary outputs. The model structure follows the 2023 WKBNORTH benchmark. A
run-matched fitted SAM object or complete native input archive was not found.

## Curated inputs and assumptions

| Series | Imported coverage and units | Source treatment and limitations |
|---|---|---|
| Total landings | 1966–2025; tonnes | The MFRI landings table is split by reporting country and area. Annual values were summed across the reported areas and countries. The sums exactly match the assessment-summary landings for all 60 years. This is the model's total landings input, not its model-estimated total catch. |
| Catch-at-age | Ages 6–25+, 1995–2025; thousands of fish | The report says only catch-at-age from 1995 onward is used. The source table also contains earlier rows, which are not included in the canonical input series. The published catch-at-age values represent the age allocation scaled to total landings across the stock sectors. |
| Icelandic autumn survey age index (IS-SMH) | Ages 6–25+, 1996–2025; index numbers on the reported scale | Values are transcribed as published. The report says no October survey was conducted in 2011 and that the missing index was replaced using 2010 and 2012. The table nevertheless contains a 2011 age-specific row. Those published values do not equal the simple cellwise arithmetic mean of the 2010 and 2012 age values. The row is retained with an explicit imputation note; its age-level construction remains unresolved and it is not described as a direct survey observation. |
| Catch weights | Ages 6–25+, 1966–2025; grams per fish | Values from the 2026 catch-weight table; retained in the published units. |
| Stock weights | Ages 6–25+, 1966–2025; grams per fish | The report says missing values are supplemented from an alternative source and stock weights are smoothed using a two-year moving average. The published final table is stored without additional smoothing. |
| Maturity | Ages 6–25+, 1986–2025; proportion mature | The source table does not identify a sex-specific maturity vector. |
| Natural mortality | Fixed M=0.05 for ages 6–24 and M=0.10 for age 25+ | M is an assumption, not an estimated output. Age 25 is the plus group. |

The model has two whole-stock survey indices. Its spring index is a single
total-biomass series, while the public tables provide an age-disaggregated
IS-SMB series. The IS-SMB age table was not imported as if it were the fitted
SAM observation. The numerical spring biomass series remains unavailable.
The report identifies spring and autumn sampling as March and October, but
does not provide exact within-year timing fractions; no timing values were
invented.

The assessment uses an age range of 6–25+, with recruitment at age 6. The
assessment also combines regional survey information in its whole-stock
indices. The complete fitted survey series and likelihood settings were not
recovered, so the input record remains partial.

## Curated outputs

- N-at-age: ages 6–25+, 1966–2026, in thousands of fish. The 2026 row is the
  reported state/forecast beyond the 2025 input terminal year.
- F-at-age: ages 6–25+, 1966–2025, per year.
- Annual SSB and total biomass: 1966–2026, tonnes.
- Recruitment: age 6, 1966–2026, thousands of fish.
- Fbar: ages 9–19, 1966–2026, per year.
- The annual ICES source-data table also reports total catches and discards;
  these are stored separately from observed landings.

Reported low/high bounds for aggregate outputs are retained. The source table
does not identify their confidence level, so no standard errors or interval
interpretation are inferred. No age-specific standard errors are provided in
the recovered tables. Outputs completeness therefore remains partial.

## Import status and remaining gaps

The canonical database now includes the 2026 current-unit stock and assessment
records, 4,479 input rows, 2,784 output rows and 19 assumption rows. The
assessment is marked current and applied. Input and output completeness remain
partial because the spring total-biomass index, exact timing fractions, full
native SAM configuration and age-specific uncertainty were not recovered.
No tinyAM translation has been attempted.

All source values remain separate from downstream transformations. The cached
HTML sources, source URLs, retrieval date, assessment identifiers, revisions
and SHA-256 checksums are recorded in the gitignored local cache
source_cache/discovery_ices_golden_redfish_561214_2026/.

## Sources

- ICES 2026 advice record 5102: https://asd.ices.dk/viewAdvice/5102
- ICES Stock Assessment Graphs source data, key 22441: https://standardgraphs.ices.dk/ViewSourceData.aspx?key=22441
- MFRI 2026 golden redfish technical report: https://www.hafogvatn.is/static/extras/images/5_red_2026_1_techreport_en.html
- MFRI 2026 assessment tables: https://www.hafogvatn.is/static/extras/images/5_red_2026_1_tables_en_v2.html
- ICES WKBNORTH 2023 benchmark report: https://doi.org/10.17895/ices.pub.22304638
