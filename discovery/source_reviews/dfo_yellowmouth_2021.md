# Yellowmouth Rockfish

Reviewed 2026-11-03. The current DFO unit is the coastwide Yellowmouth Rockfish stock in PMFC areas 3CD and 5ABCDE; area 4B is excluded. No Charbonneau–Keith identifier was matched. The latest detailed production assessment located is the 2021 assessment, published as DFO Research Document 2022/010 with advice in Science Advisory Report 2022/001. The 2025/26 Groundfish IFMP anticipated an update in 2024, but the 2026/27 plan identifies other forthcoming advice and no later Yellowmouth assessment. The 2021 run remains the latest detailed run found in this review.

## Assessment and recovered source data

The assessment is an annual, two-sex Stock Synthesis 3.30.17.01 model with age classes 1–60 and age 60 as the accumulator. Its 1935–2021 catch history is treated as one fishery, Trawl+, combining five catch sources. The report states that catches are known without error and occur midyear. It estimates the population at the beginning of 2022.

The source import records 87 annual Trawl+ catch inputs for 1935–2021 from Table A.4. Values are rounded as printed in the report. Table A.4 gives a partial 2021 catch of 298 t through June, but explicitly says the model used the 2020 total of 1,057 t for 2021; that carry-forward is recorded as a documented reconstruction.

Four fishery-independent survey biomass series are imported in tonnes, with midyear timing:

- Goose Island Gully: 1967, 1969, 1971, 1973, 1976, 1977, 1984, 1994.
- Queen Charlotte Sound: 2003, 2004, 2005, 2007, 2009, 2011, 2013, 2015, 2017, 2019.
- West Coast Vancouver Island: 2004, 2006, 2008, 2010, 2012, 2014, 2016, 2018.
- West Coast Haida Gwaii: 2006, 2007, 2008, 2010, 2012, 2016, 2018, 2020.

The imported point estimates are the Table B estimates from Eq. B.4. The report also gives bootstrap means, 95% bootstrap intervals, bootstrap CVs from 1,000 resamples, and analytic CVs. The import keeps the bootstrap CV as the numeric precision record and preserves both CV values and interval bounds in the corresponding observation notes. The report does not establish which CV series was supplied to the production model. Table B.13 includes a 1997 WCHG estimate, but Table E.1 excludes 1997 from the model's biomass-index years, so it is not imported as a fitted index.

The combined delta-lognormal commercial bottom-trawl CPUE index is imported for 1996–2020. It is a relative index scaled to geometric mean 1.0, with midyear timing. Table C.9 reports bootstrap 95% intervals and standard errors from 100 replicates; the standard errors are preserved on the relative-index scale. The report says they were used as initial CVs in the assessment.

The time-invariant female maturity input is recorded for ages 1–60: zero at ages 1–4, the model values from Table D.6 for ages 5–16, and one from age 17 onward. The source also provides the fixed biological parameter values used to derive weights-at-age: coastwide survey length-weight parameters by sex from Table D.2, and von Bertalanffy growth parameters from Table D.4. The final numeric weight-at-age surface is not tabulated, so it is not presented as a direct source observation.

Table E.1 gives the years with age-composition observations for the commercial fishery and four surveys. Those year sets, the midyear timing, and the survey age-composition weight of 0.25 are recorded as assumptions. The report explains that survey age compositions were downweighted because they did not consistently track cohorts.

## Recovered official outputs

Table F.4 reports posterior quantiles for the composite base case, pooling 10,000 MCMC samples from five component runs with fixed M values 0.04, 0.045, 0.05, 0.055, and 0.06. The database records all 13 quantities in the table. For example, start-of-2022 female spawning biomass has a median of 18,001 t and 5th/95th percentiles of 10,070 and 42,533 t. The 5th and 95th percentiles form a central 90% posterior interval, not a 95% interval; no standard error is reported.

Annual SSB and age-0 recruitment trajectories are shown in figures but not tabulated numerically. Numerical N-at-age and instantaneous F-at-age series were not recovered. M is fixed in the five component runs and is not an estimated output; the report's fishing-pressure summaries are exploitation rates, not F-at-age.

## Remaining source gaps

No run-matched native Stock Synthesis input/output bundle or numeric age-composition matrices were located. Commercial and survey age compositions are shown in figures, but exact age vectors, effective sample sizes and the original annual catch vector are unavailable. The catch table is rounded. The survey tables report both bootstrap and analytic CVs without identifying the version used in the production run. The fixed weight-at-age surface can be reconstructed from the recorded biological parameters, but the report's age-class convention must be followed and the result verified before it is treated as a verified age-specific source surface. Exact numeric annual SSB/recruitment and age-specific N/F outputs remain unavailable.

This is a partial source record: it contains run-specific catch, index, biological, assumption and reference-point data, but does not recover the complete official likelihood inputs or output trajectories. The survey compositions are samples, not standardized age-specific abundance indices.

## Sources

- [DFO Research Document 2022/010](https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41091449.pdf), detailed 2021 assessment.
- [DFO Science Advisory Report 2022/001](https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/4103336x.pdf), assessment advice.
- [DFO CSAS publication record](https://csas-scas.dfo-mpo.gc.ca/publications/96b903ca-fd67-4275-8236-84df0597b400).
- [2025/26 Groundfish IFMP](https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/4127698x.pdf).
- [2026/27 Groundfish IFMP summary](https://www.pac.dfo-mpo.gc.ca/fm-gp/mplans/ground-fond-ifmp-pgip-sm-eng.html).

The detailed report, advice report, IFMP and current plan summary are cached under the gitignored source cache for this stock. The source manifest records the retrieval URL, date, size and SHA-256 checksum.
