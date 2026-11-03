# Northeast Arctic golden redfish (`Sebastes norvegicus`)

## Source review status

The latest detailed official assessment is the 2026 AFWG run for `reg.27.1-2`. It changed from the age-based GADGET assessment to a SPiCT surplus-production model after the February 2026 WKBWNG benchmark. This is a verified source-based blocker for the current age-structured tinyAM comparison: the accepted assessment does not estimate N, F, M, or recruitment by age. The catalogue stock remains without a tinyAM translation; the older GADGET outputs are not substituted as though they were current.

## Sources

- [AFWG 2026 report, chapter 7](https://doi.org/10.17895/ices.pub.32134696.v1): current assessment, inputs, outputs, and advice basis. The chapter PDF is cached locally with retrieval date and SHA-256 in `source_cache/ck_ices_afwg_norvegicus_deep1_2/manifest.csv`.
- [WKBWNG benchmark report (ICES Scientific Reports 8:27)](https://doi.org/10.17895/ices.pub.32019630.v1): method review and benchmark decision. The report and Golden Redfish data working document are cached in the same folder.
- [AFWG 2024 report (ICES Scientific Reports 6:61)](https://doi.org/10.17895/ices.pub.25970272.v1): describes the superseded age-based GADGET assessment. The report is cached locally for historical reference.
- [ICES advice for 2026 assessment year](https://asd.ices.dk/viewAdvice/7190): confirms the current advice for 2027.

## Verified current assessment

The 2026 assessment fits annual total catches from 1908–2025 and a bottom-trawl biomass index for fish larger than 30 cm from 1991–2025. The index was produced with a spatiotemporal model and is intended to represent adult, fishable biomass. The accepted SPiCT benchmark configuration uses the complete catch series, the greater-than-30-cm index, fixes the production-shape parameter at 2, and applies priors to productivity, initial biomass, and catch observation error.

The report presents relative biomass (`B/BMSY`) and relative fishing mortality (`F/FMSY`), with uncertainty plots and short-term advice scenarios. It does not report age-specific population numbers or mortality surfaces, and it does not present a stock–recruitment relationship. These outputs are not equivalent to tinyAM's age-specific N/F/M or SSB. The public reports and benchmark working document describe the series and model but do not provide a fitted tinyAM-compatible age-state object.

## Historical assessment and decision

The 2024 AFWG assessment used an age–length GADGET model and reported age-specific N and F tables. The 2026 benchmark replaced that model because of concerns about retrospective SSB revisions, species misidentification, a survey index that did not represent mature biomass, and multiple golden-redfish morphs with differing life histories. The benchmark report does not recommend the former GADGET model as the current basis for advice.

Do not import the 2024 GADGET outputs as the current assessment or fit tinyAM to the 2026 SPiCT inputs as if they were age-based observations. Revisit only if a separate historical-model comparison is intended, or tinyAM gains a compatible surplus-production workflow.
