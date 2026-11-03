# British Columbia Canary Rockfish

## Official assessment and identity

`dfo_canary_bc_2022` represents the coastwide Canadian stock of
*Sebastes pinniger* in 3CD and 5ABCDE, excluding Strait of Georgia 4B.
The basin is Northeast Pacific. It is a documented Canadian exception to the
Charbonneau–Keith sampling frame: no matching BC stock occurs in the pinned
Master/PLOS catalogue snapshots; no identifier is invented.

The official assessment was reviewed in September 2022. Its detailed source is
[Starr and Haigh, Research Document 2023/070](https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41218875.pdf),
published November 2023, with [Science Advisory Report 2023/002](https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41097312.pdf).
The selected production run is **Run24, reweighted 24.01**, SS3 v3.30.18,
not one of the sensitivity runs. The report and
[native base-run description](https://github.com/pbs-software/pbs-synth/blob/16f1d4368ad7d3e854219ca1c2d9d6353252c861/models/input/2022/CAR/CST/Base/00ReadMe.txt)
agree on stock, years, ages, fleets, likelihoods and active parameters. No
newer detailed official assessment was located in the source search.

## Model and input inventory

The model covers 1935–2022, two sexes, one area, age-0 recruitment and a
60+ accumulator. Observed age compositions use ages 1–60+. The starting
population is an unfished equilibrium modified by early recruitment deviations.
Recruitment follows Beverton–Holt with estimated steepness and log R0,
fixed log-recruitment SD 0.9, early/main/recent deviations and a time-varying
bias adjustment. Main deviations run 1950–2012. Cohort survival is deterministic.

Both biomass catch fleets are retained: `TRAWL_FISHERY` and
`OTHER_FISHERY`. Their 176 historical rows include a provisional 2022 total
of 780 t, estimated with industry advice and allocated by the 2017–2021 fleet
shares (766.6636648 t trawl, 13.33633516 t other). This does not repeat 2021
catch. Equilibrium zero catches are initial settings, not observed
years. F uses the source Pope approximation. Trawl selectivity has an estimated
ascending double-normal limb forced to a plateau; non-trawl selectivity is
fixed at prior means. These curves are not identical fitted states. Male peak
offsets and all fixed/estimated distinctions remain documented.

All seven index streams are canonical: bottom-trawl CPUE and six surveys
(QCS Synoptic, WCVI Synoptic, NMFS Triennial, HS Synoptic, WCHG Synoptic,
GIG Historical). There are 78 index rows with their final supplied log SDs.
Survey indices are biomass in tonnes; CPUE is a standardized relative biomass
index. All observations use native month 6, fraction **5/12**. A profiled
constant scalar q is distinct from survey age selectivity.

There are 59 joint-sex age-composition samples, represented by 7,080 cells:
36 trawl years in 1977–2017, and 23 sample years across QCS, WCVI and NMFS.
Female and male cells sum jointly to one. Supplied sample sizes and ageing-error
keys are retained. The source uses a Dirichlet-multinomial, not independent
age-specific lognormal observations. No non-trawl, HS, WCHG, GIG or CPUE
age compositions were invented. Missing composition years remain missing.

## Biological inputs and spawning definition

Sex-specific growth, length variability and weight-length parameters are fixed
in the source. No empirical weight matrix is supplied. The matching public
SS3 v3.30.18 executable was evaluated with `-maxfn 0 -nohess -nox` to recover
fixed biological functions, including length variation. Only these weights
are imported as **reconstructed source inputs**. Generated N, F, M, SSB and
other population values are not official estimates and are not imported.

Constant beginning-year and mid-year population weights, catch weights for
both fleets, survey weights and effective maturity-fecundity weights are stored
separately by sex. They are in kg/fish, with no manufactured annual replication.
The weights generated for the fleets equal the mid-year population weights.

The original maturity vector is positive at female ages 4–9, but the executable
applies a **first-mature-age cutoff of 10**, from configured value 10.6.
Consequently its reproductive-weight vector is zero below age 10, and equals
beginning-year weight times supplied maturity thereafter (within printed
precision). Both the original vector and effective reproductive weights are
preserved. This source behavior must not be silently replaced by the unmodified
ogive. Fecundity option 1, coefficients 1 and 0, gives mature female biomass;
spawning is January 1, with no pre-spawning mortality adjustment.

M is estimated separately for each sex, constant across age and year, with
natural-scale normal prior mean 0.06, SD 0.018, bounds 0.02–0.2. It is not a
fixed input; initial parameter values are not used as supplied M observations.

## Outputs and uncertainty

The public [gftrends output](https://github.com/pbs-assess/gftrends/blob/7f1c59b8cc3895a3477204ac16da6cf15e2466c6/data-raw/canary-bc-mcmc.rds)
contains 500 complete female SSB trajectories for 1935–2023, randomly
downsampled from 2,000 official posterior draws. Medians and equal-tail 95%
credible limits are calculated per year with R quantile type 7. These are
subset summaries, not exact full-posterior published quantiles. No scaling,
reweighting or standard error is inferred.

For example, beginning-2023 subset median SSB is 10,516.1 t. Published Table 2
reports 10,761 t with **90%** limits 7,275–17,637 t; that value is retained
separately as `published_terminal_SSB`. The published BMSY reference point
and Table 1 sex-specific estimated M are also retained with their native 90%
limits. The known constant M parameter is expanded over its modeled age/year
grid by sex; its repeated values and limits are not independent annual
estimates. January 2023 is the boundary after 2022 catches.

No numerical official N-at-age, F-at-age or annual recruitment series was
recovered. Their report figures are not invented as precise output tables.
The full SSB posterior and numeric ageing-error definition transcription remain
missing. All completeness fields remain **partial**; the current detailed
record and its applied-production status are distinct from those fields.

## Cache and validation

Sources are cached under gitignored `source_cache/dfo_canary_bc/`, with URLs,
dates, checksums and pinned revisions. Input files use PBSsynth commit
`16f1d4368ad7d3e854219ca1c2d9d6353252c861`; posterior data use gftrends
commit `7f1c59b8cc3895a3477204ac16da6cf15e2466c6`.
`070_import_bc_canary_2022.R` curates the sources; the separate
`bc_canary_fixed_biology.R` reproduces the fixed-biology evaluation.
Routine fitting reads canonical records and never invokes either script.

Source tests check fleet and survey coverage, composition normalization, sex
dimensions, timing, units, the effective maturity cutoff, provisional catches,
subset/published uncertainty and absence of fabricated population outputs.

## Observation translation

The current stock recipe models **female abundance** from 1977–2022 with fitted
ages **1–40+**, retaining source biology and source observations through age
**60+** for tinyAM's internally partitioned older-age group. It uses one
one-year reporting projection. The accepted SS3 model instead carries separate
ages 0–60+ and both sexes over 1935–2022. January spawning and the original
female weight/reproductive-weight functions are preserved, including the
first-mature-age cutoff at 10. Age 0 is immature. There is **no additional 0.5
female fraction**, since female numbers are the model's population states.

`.canary_female_numbers()` calculates each female catch- or index-at-age value
using the **joint-sex** age-composition denominator and the matching original
sex-specific weights before selecting female cells. Neither official fitted
abundance nor fishing mortality is used to construct the observation data.
The sampled age compositions and biology are retained through source age 60;
model ages 40–60+ are aggregated into the model's 40+ population state, with
older-age biology retained internally rather than replacing it by the age-40
weight and maturity.

Pooled catch biomass is allocated using the joint-sex trawl age profile in
each available sampled year (36 samples, 1977–2017). This explicitly assumes
the unsampled non-trawl fleet shares the trawl profile; its total biomass is
about 4% of removals during the modeled period. No missing age samples are
filled. Consequently total catch information in years without trawl age
samples—especially **2018–2022**—does not directly constrain the tinyAM F
likelihood, although the accepted SS3 model conditions its fleet fishing
intensities on the reported catches for those years.

The three surveys with source age compositions (QCS, WCVI, NMFS) are retained.
Commercial CPUE and the HS, WCHG and GIG surveys have no corresponding source
age compositions, so their aggregate index values are not fitted. They remain
available in the canonical assessment inputs. Unlike the SS3 likelihood, the
tinyAM translation fits reconstructed female numbers-at-age as independent
lognormal observations rather than separately fitting aggregate index and
joint-sex Dirichlet-multinomial age-composition likelihoods.

### Source index uncertainty: retained but not fitted as offsets

The translation brings the accepted run's final year-specific `log_index_sd`
rows into the reconstructed input table. The database converter matches those
values to age-specific index observations by survey and year as
`obs$index$relative_sd`; the recipe checks that the values are positive and
finite. **However, the current fitted `index_settings` omit `sd_supplied`.**
Instead `sd_form = ~ 0 + survey` estimates one lognormal observation SD per
retained survey. Therefore source reweighted SDs are **not used as offsets or
multiplicative SD baselines** in this candidate's likelihood. The source SD
belongs to a whole annual aggregate survey biomass observation, rather than
independent age cells; using it as an age-specific offset would not by itself
recover the native observation covariance.

## Current tinyAM model specification

The exact fitted structure in the accompanying `dfo_canary_bc_2022.R` is:

```r
N_settings = list(process = "off", init = "exp")
rec_settings = list(process = "iid", mu_form = ~ 1, sd = 0.9)
F_settings = list(process = "ar1", mu_form = ~ logistic(age))
M_settings = list(
  process = "off",
  mu_form = ~ 0 + iid(M_prior_group, sd = 0.3),
  mu_supplied = ~ I(0.06)
)
catch_settings = list(sd_form = ~ 1)
index_settings = list(
  q_form = ~ 0 + survey + logistic(age, by = survey),
  q_link = "log",
  sd_form = ~ 0 + survey
)
```

The fitted F surface combines a **static rising logistic mean by age** with a
**correlated residual process across age and year** (`ar1`). This is not the
superseded specification with a year-specific mean RW plus IID residuals; nor
is it simply `logistic(age) + factor(year)` with deterministic F. Unlike the
accepted assessment's two separately catch-conditioned F surfaces, tinyAM
fits one aggregate F surface using Baranov removals. The AR1 departures permit
the effective F-at-age pattern to change over time around its persistent mean.

The possibility that such flexibility approximates **changing relative
contributions of fleets with different fixed selectivity-at-age curves** is
scientifically plausible, but it has not been verified for this case. The
accepted source's trawl and other-fishery curves differ, but the other fleet
accounts for a comparatively small fraction of the total biomass removals;
changes in fleet mixing alone should not be asserted to explain the latest
SSB discrepancy. Distinguishing the effects of fleet mixture, recruitment,
missing terminal catch constraints, and observation likelihood differences
would require targeted sensitivity tests.

The fixed recruitment SD 0.9 approximates source log-recruitment variability
but not Beverton–Holt recruitment, recruitment constraints or bias correction.
The single estimated female log-M effect approximates the source natural-scale
Normal prior (mean 0.06, SD 0.018) with log SD 0.3. No official fitted M value
is substituted as an input or used to tune observations. Survey effective q
has **separate rising logistic age curves** on the **log link**, not a logit
restriction, and is **time invariant**. The base assessment's profiled scalar
q and fixed double-normal selectivity are not reproduced exactly. The
explicitly dome-shaped female selectivities shown in its S09/Run33 sensitivity
are **not the selected asymptotic Run24/24.01 base configuration**.

## Interpretation of the latest fit

The user-provided SSB dashboard shows a materially improved **broad agreement
in absolute magnitude and long-term decline** relative to the previously
reported 60+ candidate. The trajectories nevertheless diverge after roughly
the early 2000s: the official female SSB recovers into the terminal years,
while tinyAM declines further to approximately the mid-2010s and rebounds only
modestly. The user also reports a substantially improved match for **female M**.
These are **qualitative** descriptions of the provided dashboard and user
report, not re-estimated percentage differences, confirmation of convergence
criteria, or independent comparison statistics. The shaded tinyAM interval
is not interchangeable with the official SSB posterior credible interval.

A complete interpretation will require numerical summary statistics and fit
checks from the **current** 40+ AR1 candidate. The official female M posterior
median is approximately 0.09329 (90% limits 0.08094–0.1063); exact current
tinyAM M estimates and confidence intervals have not been provided here.
Official numerical N/F-at-age and annual recruitment series remain unavailable;
missing comparisons are not treated as evidence of agreement.

### Superseded fit: historical record only

The earlier **60+** translation with free older-age initial states, a different
F process/mean, and source-informed retry was previously reported to converge
after the default initialization failed. Its objective was 1,726.629,
maximum gradient 0.000333, and Hessian positive definite. Historical
comparison statistics were:

| Metric | Superseded comparison | Mean absolute % difference | Median absolute % difference | Terminal % difference | Trend correlation |
|---|---|---:|---:|---:|---:|
| Female SSB | Approximate, 1977–2022 | 27.91 | 23.98 | -59.09 | 0.295 |
| Female M | Shared constant M | 36.51 | 36.51 | -36.51 | Not defined for a constant series |

**None of these numbers describe the current 40+ AR1 model.** They should not
be displayed as current results or reused to support claims about its fit.
Repeated source M-at-age rows correspond to one shared source parameter, not
independent age/year validation.

## Remaining limitations and next diagnostics

The largest structural differences are: omission of catch constraints for
years lacking age samples (notably 2018–2022); omission of aggregate-only
survey and CPUE observations; collapsing the two-fleet, two-sex system into one
female F surface; replacement of native composition/covariance likelihoods
with independent lognormal age-specific observations; shorter initialization
history; and approximate recruitment and M prior models. There is currently
**no identified unique cause** of the residual recent SSB disagreement.

Useful diagnostics, without changing the candidate reported here, would be to
inspect age-specific F deviations and survey residuals over the years when
the curves separate; compare modelled and official annual fleet catch totals;
examine recruitment-cohort contributions to spawning biomass; and run a
well-labelled sensitivity on the F process or original 60+ age boundary.
These are suggestions, not analyses already completed. New quantitative
metrics should be generated from the current fit before replacing any
historical result tables. The canonical source files and observation
transformation are not altered in this documentation update.
