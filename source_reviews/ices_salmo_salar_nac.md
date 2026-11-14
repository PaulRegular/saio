# ICES Atlantic salmon — North American complex

Review date: 2026-11-13. Official stock key: sal.nac.all. The latest detailed assessment located is the joint 2026 ICES Working Group on North Atlantic Salmon (WGNAS) assessment, covering data through 2025. The report and online tables are cached under the gitignored source_cache/discovery_ices_wgnas_2026/; URLs, retrieval date, file sizes and SHA-256 checksums are recorded in provenance/ices_wgnas_2026/sources.csv.

## Source and identity

The WGNAS 2026 report covers separate North American (sal.nac.all) and Northeast Atlantic (sal.neac.all) assessment units. This review covers the NAC key; the companion NEAC record is ices_salmo_salar_neac. The West Greenland (sal.wgc.all) fishery is mixed-stock and is not treated as a separate biological stock.

- Assessment: WGNAS 2026; terminal data year 2025.
- Model: run reconstruction and Bayesian life-cycle model, with smolt, post-smolt, 1SW/MSW, return and spawning stages.
- Source: [WGNAS 2026 report and online tables](https://iceslibrary.figshare.com/articles/report/Working_Group_on_North_Atlantic_Salmon_WGNAS_/32034120), DOI 10.17895/ices.pub.32034120.v1.

## Imported data

- Reported catches: online Table 2.1.1.3 includes Canada, Saint Pierre and Miquelon (SPM), and USA. Values are nominal numbers of fish and tonnes round fresh weight by country and reported sea-age class (1SW–5SW, MSW, PS, and total), for the years represented in the table (1982–2025 for NAC countries). The canonical input schema has numeric age but no sea-age-group field, so the source class is retained in observation_id and described in notes; age is left blank. These reported catch series are not claimed to be independent fitted likelihood rows, and the total column must not be added to its component groups.
- Biological summaries: Table 4.2.1.1 provides female proportions and eggs per female for 1SW/MSW by NAC stock unit and region. These are retained as assumptions, not presented as full maturity-at-age or weight-at-age vectors.
- Population outputs: Tables 4.3.3.1–4.3.3.3 provide returns for Small, Large and 2SW groups; Tables 4.3.4.1–4.3.4.3 provide corresponding spawners. Regional and NAC aggregate series are retained through 2025, with published return forecasts preserved through 2029 where available. Table 4.3.6.1 provides maturing, non-maturing and total pre-fishery abundance (PFA) through 2029.
- Output estimates are medians. lwr/upr retain the source 5th and 95th percentile quantiles (a 90% interval); no standard errors are reported in these tables.

## Gaps and use

The public tables do not provide a complete native run input set, a conventional survey age-specific index series, numeric weight-at-sea-age, a complete maturity-at-age vector, or annual N-at-age, F-at-age, M-at-age, SSB and recruitment surfaces. The reported life-cycle stages and PFA/return outputs do not map directly to tinyAM's annual age-structured state model. No tinyAM translation is attempted from these tables alone.

Completeness remains partial for inputs, assumptions and outputs. This is a source-curation record, not evidence that the full WGNAS likelihood data have been recovered.
