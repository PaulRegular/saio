# Chilean common hake (IFOP, 2026 advice)

Review date: 2026-11-09

## Stock unit and current run

The current management unit is the Unidad de Pesquería IV–41°28.6′ S, from the Coquimbo Region to 41°28.6′ S. Subpesca's 2025 quota decree identifies this unit and sets its 2025 quota at 34,920 t. No separate numeric stock identifier was located; the candidate key is an internal stable identifier.

The latest completed detailed assessment located is the 2025 run used for 2026 advice. IFOP's March 2026 technical report describes the model and source coverage. The December 15, 2025 revision minute reruns the same assessment configuration after correcting the artisanal under-reporting factor to include five landing sites, including Curanipe. Use this revised run for current outputs; the November estimates are superseded. IFOP lists the 2027 status assessment as in progress.

The assessment is an integrated age-structured ADMB model with 12 age groups (ages 2–13+), age-2 recruitment, and a Ricker stock-recruit relationship. Recruitment deviations are lognormal. Natural mortality has a baseline M0 of 0.33 per year plus a time-varying component proportional to squid CPUA from 1999. The fitted squid series and mortality coefficient are not reported. Fishery and acoustic age compositions use effective sample sizes reported separately for two estimation stages; the report does not establish which stage-specific values were retained for the final fit.

## Recoverable source data

| Component | Verified source information | Coverage and remaining gaps |
|---|---|---|
| Commercial catch | The December revision minute Table 2 reports corrected combined catch totals for 2019–2024. Its industrial and artisanal amounts and correction factors reproduce each printed total. The authorized 2025 quota of 34,920 t is used as a final-year projection catch assumption, not observed catch. | Numerical aggregate catch values for 1940–2018 and catch-at-age likelihood matrices are not recovered. |
| Acoustic survey | The detailed assessment describes biomass, age-composition, and mean-weight inputs, including preliminary 2025 observations. The final 2025 acoustic report Table 10 reports biomass, total abundance, mean weight, and zone shares for 2001, 2002, and 2004–2025. Table 17 reports estimated abundance by age and sex (millions of fish) for 2025, ages 0–14+. | The final survey report is not confirmed to match the preliminary 2025 fitted observations. Its Table 17 includes a blank age-13 cell; it remains blank. The assessment report also lists 2002 in Table 1 but explicitly excludes it from the indirect assessment in Section 7. Historical fitted age-composition matrices remain unavailable. |
| Acoustic source files | The survey-report annex includes an Access database with 1,340 acoustic records, 619 age-read fish, 2,631 biological samples, and associated length, catch, and oceanographic tables. The field dictionary identifies age, length, date, weight, maturity stage, and sex fields. | These are survey data, not a ready-to-use fitted age-composition matrix. Survey-design weighting and the exact transformation to the model input are not established by the database alone. |
| Biology | The assessment uses empirical age-specific fishery and survey weights and age-specific maturity. The final acoustic report provides a 2025 length-weight relationship and individual biological samples. | Historical age-weight matrices and the fitted maturity-at-age vector are not recovered. The final survey samples are not substituted for the model's historical biological inputs. |
| Mortality and timing | The report documents baseline M0 = 0.33 per year plus a squid-CPUA-related time-varying component from 1999, and a spawning fraction of 0.5833. | The squid series/coefficient and the model's exact survey timing fraction remain unavailable. Cruises generally occur July–September; the final 2025 cruise was July–August. |
| Annual outputs | The December revision minute Table 3 reports total biomass 2+, spawning biomass, exploitable biomass, age-2 recruitment, scalar F, and exploitation rate for 1999–2025. | No confidence intervals are tabulated. The table does not define the point-estimator convention or whether scalar F is apical or age-averaged. No numerical N-at-age, F-at-age, or M-at-age output series is reported. |
| Advice | The revision minute reports a 2026 CBA of 29,767 t. CCT-RDZCS report 02/2025 gives a maximum of 29,703 t after a 1.01 discard adjustment to its 30,000 t recommendation. | These advice values use different discard/advice bases and are not interchangeable. |

## Import decision and source gaps

This is a partial source import, not a translation-ready assessment. The canonical record contains only verified revised catch totals, the distinct 2025 projection-quota input, documented model assumptions, and annual outputs from the revised run. Outputs are preserved as published with no intervals and no inferred estimator.

The final acoustic report and its Access annex are now cached and documented. They establish direct survey estimates and biological sample data, including a 2025 abundance-by-age table. The assessment report identifies its 2025 acoustic inputs as preliminary, so the final survey estimates are retained as source evidence but are not substituted for the fitted observations without a direct reconciliation. The historical age-specific model input matrices, empirical weights, maturity vector, and squid covariate remain source gaps.

The 2026 IFOP status report is a project/reporting summary, not a newer completed model run. IFOP lists the 2027 status assessment as ongoing.

## Sources and local cache

- IFOP, 2025 detailed assessment for 2026 advice: <https://institutofomentop-my.sharepoint.com/:b:/g/personal/renzo_tascheri_ifop_cl/IQC_X34AxJbOQIkPB8eik1CnAW7V0EJWugOWbApDQOCjT1A?e=khmkN4>
- IFOP, 15 December 2025 revised assessment minute: <https://institutofomentop-my.sharepoint.com/:b:/g/personal/renzo_tascheri_ifop_cl/IQD_ilIM34epS4C8dTjqhD70AfxdZzc8A39Vbqwjl6ZknIc?e=PqFwiV>
- CCT-RDZCS, Informe Técnico 02/2025: <https://www.subpesca.cl/portal/615/articles-128066_documento.pdf>
- Subpesca, 2025 quota decree: <https://www.subpesca.cl/portal/615/articles-123749_documento.pdf>
- IFOP, final 2025 acoustic survey report: <https://www.ifop.cl/wp-content/contenidos/uploads/RepositorioIfop/InformeFinal/2026/P-682128.pdf>
- IFOP, 2026 report catalogue: <https://www.ifop.cl/buscador-2026/>
- IFOP, current projects: <https://www.ifop.cl/nuestro-que-hacer/la-investigacion-pesquera/planificacion-estrategica/>

Assessment reports, the direct survey report, and the annex archive are cached under source_cache/chile_merluza_comun_2026/ and source_cache/discovery_chile_merluza_comun_2026/. Retrieval dates, URLs, file sizes, and SHA-256 checksums are recorded in provenance/ifop_merluza_comun_2026_sources.csv.
