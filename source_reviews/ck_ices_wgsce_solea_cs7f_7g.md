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

## tinyAM translation

The recipe will fit 1971–2025 and ages 1–10. It retains source catch and stock weights and maturity, fixes M at the source value, uses an AR(1) F process, and uses the age-specific UK(E&W)-BTS-Q3 index at ages 1–5. The source's Q3 survey timing is represented by 0.625, the midpoint of the quarter; this is a translation assumption because exact within-quarter timing is not specified. The age-specific q and observation-error structures are simplified to forms tinyAM can express.

The five commercial biomass indices remain in the database but are omitted from the fit because tinyAM's current direct survey likelihood expects age-specific abundance information. Fitting only the age-specific BTS index is an explicit simplification, not a claim that the source model used no commercial indices. Source configuration also specifies a random walk on log age-1 recruitment, an AR(1) F state, and Fbar ages 3–8. tinyAM's abundance and observation-error structures do not reproduce the complete SAM likelihood or covariance specification.

Normal tinyAM starting values are tried first. If numerical checks fail, at most one retry may use the report's N-at-age and F-at-age values as optimizer starting values only. The observations, settings, and estimand remain unchanged; source estimates do not constrain tinyAM parameters.

## Numerical review

The default fit failed numerical checks; the permitted source-N/F-start retry
passed them (optimizer code 0, objective 429.111, maximum gradient 0.000099,
positive-definite Hessian, and successful uncertainty estimation). Despite that
pass, its absolute population scale is not credible. In 2025 the tinyAM age-1
estimate is 30,021,906,910 thousand fish versus 3,780 thousand in the report;
the age-10+ estimates are 485,819,524,786 versus 1,214 thousand. The model
matches recent catch-at-age predictions, but fitted F is only about
6e-11–2e-8 per year and age-specific q about 1e-13–4e-12. This is a strong
practical scale-confounding signal between N, low F and freely estimated q;
the numerical convergence checks do not certify a meaningful abundance scale.

A source-closer sensitivity turned off the IID cohort-survival process while
keeping the recruitment random walk and all observations and other settings.
It also passed the numerical checks (objective 437.337, gradient 0.000116 and
positive-definite Hessian), but its median percent differences remained
extreme: about 21 billion percent for N and total abundance and 51 billion
percent for SSB. Removing IID N deviations therefore does not resolve the
scale problem. Neither fit should be presented as a close assessment
replication or used to interpret tinyAM absolute N, F, q or derived biomass.
The current translation is retained only as a diagnostic experiment; the
five commercial biomass indices and their model likelihoods remain
unrepresented, and no unsupported q prior or fixed scaling was introduced.

## Discovery inventory screening

The ICES 2026 inventory entry sol.27.7fg matches this existing divisions 7.f-g stock and is screened eligible. Report tables supply age-based catch and survey inputs, age weights, fixed biology and mortality, and fitted N/F and annual outputs. The native 7.f-g fit object was not located; source-based report tables are the detailed production record.
