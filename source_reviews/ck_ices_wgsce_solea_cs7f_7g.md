# Celtic Sea common sole (ICES divisions 7.f-g)

## Assessment represented

The current detailed assessment is the 2026 ICES WGCSE assessment `sol.27.7fg`, with data through 2025. It is a category-1 age-structured SAM assessment. The database stock identity remains `ck_ices_wgsce_solea_cs7f_7g`; its authority stock code is `sol.27.7fg`. The source chapter, retrieval date, checksum, and file identifier are recorded in the local ignored source cache.

The detailed chapter reports the model inputs and outputs, so this stock is no longer metadata-only. The import does not use an older Charbonneau–Keith table as a substitute for the official 2026 tables. A native 7.f-g fit object was not located. The available `sol.27.7jk` object refers to another stock and was excluded.

## Source data recorded

The import preserves the reported age and year coverage:

- Catch numbers-at-age, catch weights-at-age, stock weights-at-age, fishing mortality-at-age, and stock numbers-at-age: 1971–2025, ages 1–10, with age 10 as the plus group. Catch numbers are in thousands of fish; the two weight series are in kg per fish; N is in thousands of fish and F is per year.
- UK (England and Wales) beam-trawl survey, Q3: abundance index by age for 1988–2025, ages 0–9, reported as numbers per 100 km. The assessment uses ages 1–5. Values are stored on the reported scale; no multiplier is applied. The model does not treat these as age-composition sample counts.
- Five commercial beam-trawl biomass tuning series are transcribed from Table 22.10 and retained as separate relative indices. The report does not identify their physical scale, so they are stored as native-scale indices and are not converted to biomass units.
- The assessment reports fixed natural mortality of 0.1 per year at all ages and years, and a maturity vector for ages 1–15. Both are retained as source inputs. The maturity vector is not expanded into annual observations.

The report's configuration excludes catch observations at ages 1 and 2 before 2004. The original table values remain in the canonical database; this exclusion is applied only by the tinyAM recipe. The age-specific survey table retains all reported ages even though tinyAM uses only the age range fitted by the source assessment.

## Outputs and uncertainty

The import records point estimates of N-at-age and F-at-age for the full 1971–2025 age grid. Table 22.15 also reports age-1 recruitment, total biomass, SSB, model-estimated catch, and Fbar for ages 3–8. The table's low/value/high values are retained. It does not identify the level or interval construction in the table, so the import does not label them as 95% intervals or derive standard errors. Age-specific uncertainty surfaces are not available in the report.

SSB is retained using the report's native aggregate value. The exact spawning-time convention is not established from the available report material. Any tinyAM SSB comparison is therefore approximate and should not be read as a definition-matched result. M is fixed in the source assessment, so comparing M is an input check rather than a comparison of independent estimates.

## Discovery inventory screening

The ICES 2026 inventory entry sol.27.7fg matches this existing divisions 7.f-g stock and is screened eligible. Report tables supply age-based catch and survey inputs, age weights, fixed biology and mortality, and fitted N/F and annual outputs. The native 7.f-g fit object was not located; source-based report tables are the detailed production record.

## Downstream modelling

The tinyAM settings and fitting results are maintained in [tinyAM translation notes](https://github.com/PaulRegular/tinyAM/blob/main/analysis/comp_assessments/translation_notes/ck_ices_wgsce_solea_cs7f_7g.md). They do not determine source completeness or official run selection.
