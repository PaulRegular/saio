# Western and Central Pacific bigeye tuna

**Reviewed:** 2026-11-13
**Discovery cross-reference:** NOAA Stock SMART 11684
**Assessment unit:** WCPFC Western and Central Pacific bigeye tuna (*Thunnus obesus*)
**Curation:** Partial source import for the 2023 assessment; no age-specific catch reconstruction was added.

## Identity and current assessment

Stock SMART lists the unit as Western and Central Pacific bigeye tuna and its latest row is assessment 13363 (2023, data through 2021; SWFSC/PIFSC). No matching canonical stock is present. It is distinct from the Atlantic bigeye candidate NOAA:10169 and the Eastern Pacific bigeye assessment NOAA:11685. The unit is linked internally as `wcpfc_wcpo_bigeye`.

The 2023 WCPFC assessment is the latest assessment accepted for stock-status advice: SC19 accepted its nine-region structure and unweighted 54-model uncertainty grid. The full report covers 1952–2021 and describes 41 fisheries (32 extraction and nine index fisheries), quarterly time steps, and 40 quarterly age classes including a plus group. A more recent 2026 assessment was reviewed at SC22, but the Committee did not reach consensus on its uncertainty grid. The 2026 report and data papers are retained as newer source material; they do not replace the 2023 assessment as the last accepted basis for advice.

## Inputs and outputs located

- **Catch and effort:** The native MFCL input has 6,335 extraction catch records across 32 fisheries, quarterly from 1952–2021. The assessment report identifies longline catch in fish numbers and other extraction catch in metric tonnes. Non-negative effort values are retained with fleet-specific units; negative `-1` codes are omitted.
- **Size compositions:** The pinned SPC TAF input has 96,235 length-frequency rows from 1965–2021 and 707,200 weight-frequency rows from 1952–2021, covering 18 and 24 fisheries respectively. Length classes are 95 two-centimetre bins (10–12 through 198–200 cm); weight classes are 200 one-kilogram bins (0–1 through 199–200 kg). Extraction frequencies are weighted by catch and index-fishery frequencies by standardized CPUE. The TAF exports do not provide a separate unweighted sample size, so the native frequency values are preserved without normalization and sample size is left blank.
- **Age data:** The native `bet.age_length` input and TAF `otoliths.csv` expose 1,010 conditional age-at-length observations. They span 14 sampled years from 1990–2018, four quarters, and eight of nine regions. These samples inform growth; they are not marginal catch-at-age or abundance observations. No catch-at-age reconstruction or pooling across unsampled strata was added.
- **Abundance indices:** The assessment provides 2,520 quarterly standardized longline CPUE observations (nine regions, 1952–2021). They are aggregate relative-abundance indices, not age-specific indices. TAF stores the index as catch divided by effort and 1e6. The native `cpue_penalty` field is preserved as an unresolved observation weight; it is not labelled a CV or standard error.
- **Tagging and biology:** TAF exposes 11,210 tag-release length-frequency rows and 2,892 recapture records. The report describes a negative-binomial tagging likelihood. The fitted biology output provides length, weight, maturity and Lorenzen natural mortality at age; these are model-derived surfaces, not independent observed biological inputs. The reported spawning-potential biomass is retained as a distinct metric and not relabelled conventional SSB.
- **Outputs:** The pinned diagnostic output provides 100,800 numbers-at-age rows, 28,000 annual F-at-age rows, fitted age-specific M and biology, regional spawning-potential biomass, annual recruitment/biomass/catch summaries, predicted extraction catches, and fitted CPUE indices. Point estimates have no standard errors or confidence intervals in the export. The official advice was based on a 54-model grid; these diagnostic outputs are not a substitute for its distribution or uncertainty.

## Screen decision

**Eligible for source curation.** The available assessment sources support import of the native catch, effort, size-frequency, conditional age-at-length, CPUE, tagging, and diagnostic output tables. They do not provide an observed marginal catch-at-age series or age-specific abundance index. Conditional age-at-length samples are retained in their original role and have not been converted into catch-at-age.

The canonical assessment is marked partial because model-specific likelihood settings and ensemble uncertainty are not fully represented, and the fitted output is from one diagnostic reference fit rather than the advice grid.

## Sources and cache

The gitignored local cache is `source_cache/discovery_noaa_wcpfc_bigeye_2026/`. `sources.csv` records retrieval dates, URLs, byte counts, SHA-256 hashes, and the SPC repository revision. The pinned SPC diagnostic repository is `81fc412ad1f36416f78f84ef6bd2d5dff68d14c8`.

- [2023 WCPFC assessment report](https://meetings.wcpfc.int/node/19353) and [SC19 outcomes](https://meetings.wcpfc.int/system/files/2024-07/SC19%20Outcomes%20Document%20%2828Nov2923%29-Att%201%2C7%20fixed_0.pdf)
- [SPC 2023 diagnostic model and TAF data](https://github.com/PacificCommunity/ofp-sam-bet-2023-diagnostic/tree/81fc412ad1f36416f78f84ef6bd2d5dff68d14c8)
- [2026 WCPFC assessment report](https://meetings.wcpfc.int/node/33590), [background inputs](https://meetings.wcpfc.int/taxonomy/term/2845?order=field_doc_symbol&sort=desc), [age-at-length data paper](https://meetings.wcpfc.int/file/21268/download), and [SC22 outcome summary](https://www.wcpfc.int/node/244)
