# ICES Atlantic salmon — Northeast Atlantic complex

Review date: 2026-11-13. Official stock key: sal.neac.all. The latest detailed assessment located is the joint 2026 ICES Working Group on North Atlantic Salmon (WGNAS) assessment, covering data through 2025. The report and online tables are cached under the gitignored source_cache/discovery_ices_wgnas_2026/; URLs, retrieval date, file sizes and SHA-256 checksums are recorded in provenance/ices_wgnas_2026/sources.csv.

## Source and identity

The WGNAS 2026 report covers separate North American (sal.nac.all) and Northeast Atlantic (sal.neac.all) assessment units. This review covers the NEAC key; the companion NAC record is ices_salmo_salar_nac. The West Greenland (sal.wgc.all) fishery is mixed-stock and is not treated as a separate biological stock.

- Assessment: WGNAS 2026; terminal data year 2025.
- Model: run reconstruction and Bayesian life-cycle model, with smolt, post-smolt, 1SW/MSW, return and spawning stages.
- Source: [WGNAS 2026 report and online tables](https://iceslibrary.figshare.com/articles/report/Working_Group_on_North_Atlantic_Salmon_WGNAS_/32034120), DOI 10.17895/ices.pub.32034120.v1.

## Imported data

- Reported catches: online Table 2.1.1.3 includes the NEAC reporting countries other than Greenland: Denmark, Faroes, Finland, France, Germany, Iceland, Ireland, Norway, Portugal, Russia, Spain, Sweden and the UK reporting areas. Values are nominal numbers of fish and tonnes round fresh weight by country and reported sea-age class (1SW–5SW, MSW, PS, and total). The table covers 1980–2025 across all reporting areas, with country-specific gaps. Greenland is excluded because its fishery is mixed-stock and belongs to the separate WGC reporting context. The canonical input schema has numeric age but no sea-age-group field, so source class is retained in observation_id and notes; age is left blank. These reported catch series are not claimed to be independent fitted likelihood rows, and the total column must not be added to its component groups.
- Population outputs: Tables 3.3.4.1–3.3.4.8 provide 1SW/MSW returns and spawners for N-NEAC and S-NEAC country groupings and their reported complex totals through 2025. Tables 3.3.5.1–3.3.5.4 provide maturing and non-maturing 1SW PFA for N-NEAC and S-NEAC through 2029, including forecasts.
- Output estimates are medians. lwr/upr retain the source 5th and 95th percentile quantiles (a 90% interval); no standard errors are reported in these tables.

## Gaps and use

The reviewed online tables do not provide a complete native run input set, a conventional survey age-specific index series, a complete numeric weight-at-sea-age or maturity-at-age input, or annual N-at-age, F-at-age, M-at-age, SSB and recruitment surfaces. The reported life-cycle stages and PFA/return outputs do not map directly to tinyAM's annual age-structured state model. No tinyAM translation is attempted from these tables alone.

Completeness remains partial for inputs, assumptions and outputs. This is a source-curation record, not evidence that the full WGNAS likelihood data have been recovered.
