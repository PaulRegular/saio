# West Coast of Vancouver Island natural-origin Chinook (2024 assessment)

The DFO Pacific inventory row `DFO:Pacific:Chinook Salmon - West Coast of Vancouver Island` identifies the natural-origin WCVI Chinook Stock Management Unit (SMU), *Oncorhynchus tshawytscha*. No matching canonical tinyAM stock is present. The latest detailed public assessment located is the 2024 assessment, documented in Research Document 2026/020 (published April 2026); the earlier 2025 Science Response 2025/021 is also retained locally.

The detailed report describes three Conservation Units within the SMU and a mixture of enumeration, catch, escapement, and biological sampling programmes. Age, sex, origin, stock, and body-size data are collected from fisheries, hatcheries, and rivers. The run-reconstruction approach combines catch and escapement totals with time- and area-specific biological samples to apportion fish among ages and populations. Supporting data and R code are published in the assessment repository.

The available information does not yet establish a complete, aligned age-structured input set for the natural-origin SMU. The report says robust CU-specific catch and exploitation histories are unavailable, and that recruitment series based on a common exploitation history from Robertson Creek Hatchery should be treated cautiously and were not used to derive the assessment's benchmarks. The cohort age-specific exploitation series are based on this hatchery indicator, not the natural-origin SMU. The report therefore does not provide a conventional annual natural-origin N-at-age/F-at-age assessment surface. The stock is recorded as a new, distinct unit, with age-input eligibility unresolved pending a direct audit of sample expansion, age/origin coverage, and the supporting run-reconstruction outputs.

## Sources and local cache

The official 2026 Research Document was reviewed through its indexed full text. The direct Government of Canada PDF URL redirected to an archived-page notice during local retrieval, so it could not be cached in this environment. The 2025 Science Response and selected supporting workbooks are cached in the gitignored local source cache; their source URLs, retrieval date, file sizes, checksums, and pinned supporting-repository revision are recorded in `source_cache/discovery_dfo_wcvi_chinook_2024/sources.csv`.

- [DFO Research Document 2026/020: West Coast of Vancouver Island Natural-Origin Chinook Salmon Stock Assessment in 2024](https://publications.gc.ca/collections/collection_2026/mpo-dfo/fs70-5/Fs70-5-2026-020-eng.pdf)
- [DFO Science Response 2025/021](https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41293964.pdf)
- [Supporting data and R code, pinned repository revision `f6b643e5672374cb34bc7a99d6ff9151b69ce325`](https://github.com/SCA-stock-assess/WCVI-CN-ResDoc/tree/f6b643e5672374cb34bc7a99d6ff9151b69ce325)
- [Terminal run-reconstruction repository, current revision `20053469c8c8416b5bb56cd7a858e4928f7fec16`](https://github.com/SCA-stock-assess/WCVI_CN_TermRunRecon/tree/20053469c8c8416b5bb56cd7a858e4928f7fec16)
