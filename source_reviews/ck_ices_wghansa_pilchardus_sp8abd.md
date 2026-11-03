# Bay of Biscay sardine source review

## Assessment and stock identity

The metadata record is ICES stock `pil.27.8abd`, sardine in divisions 8.a, 8.b, and 8.d (Bay of Biscay). The latest official assessment located is the 2025 WGHANSA assessment used for advice on 2026 catches. The official advice database identifies assessment year 2025 and an active advice value of 21,128 tonnes for catches in 2026. Because its detailed input files and age-specific outputs were not recovered, the database records the 2025 material as a separate summary-only event, not as the current detailed assessment.

The 2025 WGHANSA report describes an age-based Stock Synthesis 3 model, with commercial catches and acoustic and egg survey data. The model has been used since 2019, following the WKPELA benchmark in 2017 and the 2019 IBPSardine update. The TAF software bibliography identifies SS3 version 3.24. The report's fitted historical series ends in 2024. The 2025 row is a forecast: recruitment is set to the geometric mean for 2002–2023, the catch is preliminary, and the reported F is resultant from that catch.

Sources: [2025 WGHANSA report (version 3)](https://ices-library.figshare.com/articles/report/Working_Group_on_Southern_Horse_Mackerel_Anchovy_and_Sardine_WGHANSA_/29335520), [ICES Advice Database entry](https://asd.ices.dk/viewAdvice/4007?handler=SubComm), and [ICES 2025 standard-graphs source data, key 21258](https://standardgraphs.ices.dk/ViewSourceData.aspx?key=21258).

## Recovered numerical records

The report's Table 6.3.2.1 gives annual recruitment, SSB, total catch, and F(2–5) for 2000–2025. The 2025 table row is explicitly forecast/preliminary. The matching ICES SAG XML supplies machine-readable point estimates and low/high bounds for recruitment, SSB, and F through 2024; 2025 SSB bounds are also present, while 2025 recruitment and F have no bounds. SAG identifies the bounds as 95%, but neither the interval method nor whether they are confidence or credible intervals is specified. Recruitment in the XML is in fish and is divided by 1,000 to match the report's thousand-fish units. No SEs are reported.

The aggregate catch series is not catch-at-age. The report and SAG outputs do not provide the complete historical age-structured likelihood inputs or age-specific population outputs required for a defensible tinyAM comparison.

## Native assessment files and unresolved inputs

The public [ICES TAF repository](https://github.com/ices-advice/2025_pil.27.8abd/tree/242f57e7a04cd78f30402d7c2c97fa98c197b4bc) was inspected at pinned commit `242f57e7a04cd78f30402d7c2c97fa98c197b4bc` (2026-04-30). Its `boot/data.bib` lists the 2025 `sardine.dat`, `sardine.ctl`, `wtatage.ss`, `starter.ss`, and `forecast.ss` as public assessment files. The actual files are absent from the pinned Git tree and its available history, and none were found in the local cache. The repository's `02_data.R` confirms the needed model streams: catch-at-age, acoustic index and age composition, DEPM and egg indices, natural mortality, and age-specific weights, fecundity, and maturity.

Consequently, the following remain unavailable: numerical catch-at-age and age compositions; acoustic and egg survey observations with their fitted likelihood details; the full biological and mortality inputs; exact 2025 control settings; fitted N-at-age and F-at-age; and parameter uncertainty beyond the SAG aggregate bounds. Assessment inputs, assumptions, and outputs therefore remain partial. Do not reconstruct the missing series from report figures or substitute the 2024 assessment's inputs.

The summary-only database record includes aggregate annual catch and aggregate reported outputs, but no tinyAM translation or fit is possible until the original age-structured model files or equivalent official numerical tables are recovered. The cached 2024 report is retained only as historical context and is not mixed into the 2025 record.
