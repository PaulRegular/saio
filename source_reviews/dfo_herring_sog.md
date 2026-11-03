# Strait of Georgia Pacific herring

## Production source

This Canadian-managed case is a documented catalogue exception, with no
invented Charbonneau identifier. The 2025 stock update (Science Response
2026/003) reports the five-model SISCAH density-dependent-mortality (DDM)
ensemble used in the full management-strategy evaluation. Public native fits
end in **2023**, matching the report's operating-model table. The same report
also describes a separate interim density-independent (DIM) fit through 2025.
The public `fit_maxTHR0.14` object ends in 2024 and is not that 2025 fit.
Neither its states nor the interim 2025 summary replace the detailed DDM record.

The report, five native objects, control, production DDM code, summary tables
and public reporting code are cached in `source_cache/dfo_herring_sog/`, with
checksums and revision `806896bf596b7f5799fd3d723b2fa631a3b210a5`.
The framework Research Document is still cited as in preparation by the stock
update; source code and production controls supply the recoverable details.

## Inputs and definitions

Historical model years are 1951–2023, ages **1–10+**, combined sex. The model
year is not January–December: native fleet timings are 0.54 for reduction,
0.766 for seine roe, 0.774 for gillnet and 0.79 for spawning/surveys. Preserve
these native fractions and annual labels; do not silently treat them as
calendar fractions. The publication describes the annual cycle ending June 30.

Retain each fishery's catch in thousand tonnes, raw biological age-sample
counts and original empirical kg/fish weights. A sample count is not an
abundance observation. Missing native −1 samples are omitted, while genuine
zero counts remain zero. The source pools rare age bins and uses correlated
composition errors. Its three catch fleets occur at different times, which a
single annual Baranov catch is only an approximation to.

The original combined surface/dive index measures **total spawning biomass**
in thousand tonnes. All native survey age samples are missing (−1), and both
survey age-likelihood weights are zero. No age-specific survey abundance was
recovered. The era-specific surface/dive shares and q blending in the source
prediction must not be confused with two observed abundance-at-age series.

The fixed maturity vector is 0, 0.24974, 0.9, then 1 through the plus group.
SSB is **both-sex mature biomass**: the production SB equation has no factor
0.5. That factor occurs in egg conversion only. Natural mortality is estimated,
density-dependent and time-varying, with distinct juvenile age-1 mortality;
it is not a supplied fixed-M series. Recruitment is age 1 with a Beverton–Holt
relationship and stochastic deviations.

## Ensemble reference

OM1 is `fit_parBatSOG_OMgrid_h.70_3`, the central Mb=0.562, h=0.70 hypothesis,
weight 0.34. The other four have weight 0.165. Filename suffixes are not the
published OM order. The reconstructed weighted posterior mean SSB rounds to
84.33 kt in 2023. Preserve the published machine-readable terminal summary
84.33375 kt separately: it differs by about 0.0013 kt from the weighted native
posterior means. This small discrepancy remains unresolved; no rescaling is
applied. The public reporting text calls some summaries weighted posterior
medians although component Table 1 values agree with native means, so the
reconstructed series explicitly states its mean convention.

Historical posterior mean SSB, recruitment and M, with 95% equal-tail limits
from the weighted empirical posterior mixture, are recoverable. Limits are
not averages of component limits. The resampled `wtPosts` mean differs through
Monte Carlo sampling and is not substituted for the deterministic mixture.
Component MPD N is retained under separate OM-specific measures. The native
posterior files omit N draws; component modes are not averaged and called
posterior ensemble N. Exploitation fractions are not instantaneous F-at-age.

## Translation blocker

tinyAM currently predicts an index at each age. It cannot fit the observed
aggregate spawning-biomass survey without a different observation equation.
Allocating it across ages using fitted source N would change observations
using estimated parameters. Borrowing fishery compositions would impose
unverified survey selectivity and would not recover missing survey data.
Neither is done. A catch-only fit would omit the official model's abundance
information, so it is not presented as the requested translation.

This is one curated source case, **not a completed runnable translation or
actual fitting attempt**. No starting values or model adjustments were tried.
The source and observation-model limitations are explicit shortfalls against
the twelve-translation target; no tinyAM mathematics is changed to hide them.
