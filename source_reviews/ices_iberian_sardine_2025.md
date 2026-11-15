# ICES Iberian sardine (pil.27.8c9a)

Reviewed 2026-10-30. The current ICES stock list identifies the latest assessment year as 2025. The corresponding ICES advice uses that Stock Synthesis assessment for the 2026 catch recommendation.

The March 2026 Stock Annex documents a single-area, single-season, combined-sex age-based Stock Synthesis model. It specifies catch numbers-at-age for 1978 onward, ages 0-6+, derived from raised Spanish and Portuguese figures. Cadiz catch compositions before 1998 are reconstructed using the South Portugal age composition. Commercial age compositions enter the likelihood. Annual numeric catch-at-age and composition input matrices are not in the recovered public sources. The annex does not specify the numeric scale for catch-at-age.

The model uses a spring acoustic abundance index and age compositions for ages 1-6+ across divisions 8.c and 9.a from 1997 onward, an autumn age-0 recruitment index from subdivision 9.a.c.n. from 1997 onward, and a triennial aggregate SSB index from DEPM surveys. The Stock Annex describes the acoustic survey series, but it does not give the model input arrays or numeric fractional-year survey timing.

Catch weights-at-age cover ages 0-6+; values for 1978-1990 are assumed from the 1991-1995 mean. Spawning-stock weights-at-age are interpolated between DEPM surveys, with the 1978-1998 values assumed from the 1999 and 2002 surveys. Maturity-at-age is also derived from DEPM, interpolated between survey years, held to the 1999-2014 mean in 1978-1998, and set to the latest estimate after the final survey. Fixed M-at-age is 0.98, 0.61, 0.47, 0.40, 0.36, 0.35, and 0.32 year-1 for ages 0, 1, 2, 3, 4, 5, and 6+.

The 2025 Standard Graphs output reports annual age-0 recruitment, B1+ biomass (the stock annex defines SSB as B1+), and F averaged over ages 2-5 through 2025, with 95% intervals. Historical annual N-at-age, F-at-age, and M-at-age outputs were not recovered. The public GitHub API returned 404 for the TAF repository named in the Stock Annex. Because the exact model input matrices and survey timing remain unavailable, eligibility is unresolved rather than confirmed.

This unit is distinct from the already curated Bay of Biscay sardine stock pil.27.8abd. No canonical current-area record was found.

Sources:

- [ICES WGHANSA 2025 report](https://doi.org/10.17895/ices.pub.29335520.v3).
- [ICES Stock Annex, March 2026](https://doi.org/10.17895/ices.pub.31305346.v1), especially Sections 2-3 and pp. 13-28.
- [ICES Advice 2025](https://doi.org/10.17895/ices.advice.27692337.v1), assessment year 2025.
- [ICES Standard Graphs data](https://standardgraphs.ices.dk/ViewSourceData.aspx?key=21259), stock assessment key 21259.
- [TAF assessment repository cited by the Stock Annex](https://github.com/ices-taf/2025_pil.27.8c9a_assessment); public GitHub metadata returned 404 during this review.

The report, Stock Annex, advice PDF, and Standard Graphs source page are cached in the gitignored source_cache/ices_iberian_sardine_2025/; the local manifest records URLs, pinned source revisions, retrieval time, file sizes, and SHA-256 checksums.
