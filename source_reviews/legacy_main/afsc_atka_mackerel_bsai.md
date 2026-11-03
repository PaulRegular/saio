# Bering Sea/Aleutian Islands Atka mackerel

## Official run and sources

`afsc_atka_mackerel_bsai_2024` represents the 2024 operational update of
Model 16.0b. The December 2024 SSC report retains that model. The 2026 NOAA
harvest-specifications review confirms that the 2025 funding lapse did not
produce a replacement fitted assessment. It is one combined-sex BSAI stock,
not three Aleutian area cases. The Charbonneau–Keith starting identity is
`AFSC_BSAI_Pleurogrammus_monopterygius`.

The [2024 SAFE report](https://files.npfmc.org/SAFE/2024/BSAIatka.pdf) is cached
with a checksum. Earlier framework inputs and code are pinned to
[`atkawham` revision a65171a](https://github.com/JaneSullivan-NOAA/atkawham/tree/a65171af2c6c90cdc31a5d575e3eb6c95f299455/mod22/base).
They clarify unchanged maturity and timing, not the 2024 observations or fits.
The report refers to the AMAK production implementation as available on request;
the accessible framework run ends in 2022 and is not relabelled as a 2024 fit.

## Inputs and likelihood

The model covers 1977–2024 and ages 1–11+. It fits total catch biomass with
CV 5%, survey biomass with year-specific supplied CVs, and separate
multinomial fishery and survey age compositions. The database keeps totals
and compositions separately. Compositions are recovered by normalizing the
report's expanded numbers, retaining report rounding. Table 17.8 is observed
expanded catch-at-age, not fitted predicted catch. Table 17.10 is design-expanded
survey abundance, not raw age-sample counts; its `n` column is retained separately.
Missing early catch cells (`---`) are not converted to zero or normalized as a
complete composition. Only complete reported rows enter the recovered composition.

Original population, catch and survey weights remain distinct, in kg/fish.
The population vector averages the latest three surveys with ages. The terminal
catch input is the assumed full-year 2024 TAC, 72,987 t, rather than the in-year
64,439 t observation. The supplied female maturity ogive is unchanged from
the framework. AMAK halves this ogive internally for combined-sex N.
Its month 7.5 survey and month 8 spawning become 6.5/12 and 7/12 of the year.

Natural mortality is fixed at 0.3. Survival is deterministic given mortality;
recruitment follows Beverton–Holt with fixed steepness 0.8 and an estimated
lognormal recruitment SD. F is annual intensity times flexible, penalized
age selectivity, with temporal variation; ages 10+ share selectivity.
Survey selectivity is time-invariant and nonparametric. Its scalar q is estimated
under a prior with mean 1 and log variance 0.2². Ages 4–10 define the q/selectivity
normalization. This does not imply fixing q to one.

Exact 2024 supplied composition sizes and the unrounded index CVs are not
available in the recovered report tables. Published rounded index CVs are
retained as aggregate relative standard errors. Neither raw otolith counts
nor fitted effective sample sizes are substituted for supplied likelihood weights.

## Outputs and verification

The report supplies begin-year N in millions, normalized selectivity,
fully-selected F, native female SSB and biomass with approximate 95% confidence
bounds, and age-1 recruitment with natural-scale SE. N and selectivity are
embedded tables, visually transcribed into the importer and checked against
recruitment and biomass. F-at-age is explicitly derived as normalized
selectivity times fully-selected F. It has no invented uncertainty. Values from
the adjacent 2022 comparison columns are excluded.

Completeness remains partial because original unrounded inputs, full composition
weights and state covariance were not recovered. This is distinct from the
confirmed absence of a fitted length likelihood or a stochastic N process.

## Current tinyAM translation (revised October 2026)

The working translation continues to cover **1990–2023 and ages 2–11+**. The
original early catch-at-age rows are incomplete, and catch age 1 is not reported.
Although the database retains the 2024 catch and survey biomass inputs, the
age-index reconstruction cannot include those aggregate-only observations
without additional assumptions about age composition. No missing ages are
manufactured or sourced from official fitted population states.

Biological inputs and observational conversions are unchanged: original population,
catch and survey weights; deterministic cohort survival; fixed M = 0.3;
source survey time 6.5/12; female maturity multiplied by 0.5; and August 1
spawning time 7/12. Initial abundances at older ages are free. Age-2
recruitment is IID around a constant estimated mean with **estimated process SD**,
not the source's age-1 Beverton–Holt relationship with fixed steepness 0.8.

### Fishing mortality: logistic mean and separable AR1 residuals

The current working fit uses:

```r
F_settings = list(process = "ar1", mu_form = ~ logistic(age))
```

This is **not** the previous `cor_rw` candidate and not a fixed
`logistic(age) + factor(year)` model. The rising logistic function describes
the **mean F-at-age on the log scale**. A stationary Gaussian AR1 residual
surface, correlated across both ages and calendar years, permits realized F to
depart from that mean, including shifting age-specific vulnerabilities.

The accepted AMAK model instead uses annual fishery intensity and penalized,
time-varying nonparametric selectivity, shared across ages 10+. The current
tinyAM approximation does not separately normalize fishery intensity and
selectivity, does not impose source age-10+ equality in F and does not recreate
the accepted penalties. AR1 flexibility is a pragmatic representation of
age/time variation; it is not evidence that any particular source selectivity
change was recovered.

### Survey q: monotone age curve shared from age 7

The fitted survey observation setup is:

```r
obs$index$q_age <- pmin(obs$index$age, 7)   # Retained but not used in current q_form
obs$index$q_block <- factor(pmin(obs$index$age, 7))

index_settings = list(
  q_form = ~ 1 + mono(q_block),
  q_link = "log",
  sd_form = ~ 0,
  sd_supplied = ~ relative_sd
)
```

`mono(q_block)` adds **non-negative successive increments on the log-q scale**.
Consequently, effective survey q is **non-decreasing across ages 2–7** and is
**identical at ages 7–11+**. This differs substantively from the previous
`rw(q_age)` candidate: there is no age random-walk q process in the current
fit, and the curve cannot turn downward. There is also **no calendar-year q
effect**. The unused `q_age` column is retained in the current uploaded script
but does not drive fitted q; `q_block` does.

The earlier use of shared q at ages 10+ was closer to the accepted assessment's
age-sharing convention but allowed extreme q estimates in this approximation.
The decision to couple from **age 7** was made to stabilize high-age q; it is
an explicit translation choice, **not** a statement that the accepted model
assumes selectivity flattens at age 7. The source survey selectivity is
nonparametric and can be dome-shaped; its scalar q has a prior and is
normalized jointly with selectivity over ages 4–10. The tinyAM monotone
curve cannot reproduce descending source selectivity or identify a directly
comparable normalized scalar q. `q_link = "log"` does not bound q below 1.

### Observation uncertainty and fitting

Published rounded annual survey CVs are converted to lognormal observation SDs:
`sqrt(log1p(CV^2))`. The `sd_supplied` offset is used **without estimating a
common multiplier** (`sd_form = ~ 0`). The source CV describes the annual
**aggregate survey biomass**, however, and is repeated across reconstructed
age-specific indices. The independent lognormal age likelihood does not
reproduce the source's separate aggregate survey/index and multinomial age
composition likelihoods, their effective sample sizes, or within-year
covariance. Catch-at-age uses an estimated common lognormal SD.

The present R script calls **one** `tinyAM::fit_tam()` model directly. It has
no fallback fit and does not initialize from official N-at-age or F-at-age.
The fitted M = 0.3 is externally fixed, so agreement in M is an input check.

### Performance and comparison boundaries

The user reports that the current specification reaches a reasonable practical
match and that coupling q at **age 7** prevents extremely high estimates.
No optimizer diagnostic table, current parameter estimates or recalculated
agreement statistics accompanied these two revised files, so this assessment
of the current fit is **qualitative**, not a newly quantified validation.

The previous fit's convergence (objective **511.565**, maximum gradient
**0.000267**, positive-definite Hessian), and historical comparisons (modeled-age
SSB MAPD **25.7%**, terminal difference **−23.6%**, correlation **0.966**)
refer to a **superseded independent-F-RW / independent age-q translation with
source-informed retry**. They do **not** describe the present AR1-F,
monotone-q fit. Additional previously reported differences for N and F also
belong only to that earlier translation.

The dashboard retains native age-1+ SSB and a separate **approximate modeled-age
August 1 female SSB** derived from rounded official N-at-age, F-at-age,
fixed M and recorded biology, with no reconstructed uncertainty. Native
SSB intervals must not be applied to these derived sums. The original
source estimates of N and F are used for comparisons only, never as
observations or as current-fit initialization.

The key remaining structural limitations are the different catch/survey
likelihood, unavailable historical and 2024 aggregate-only age information,
missing native composition effective sample sizes and ageing error, lack of
a separately normalized scalar survey q, the inability of monotone q to
represent dome-shaped survey selectivity, and a simpler recruitment process.
Further fine-tuning can be assessed case by case; the current translation is
presented as a practical approximation rather than a reconstruction of the
accepted AMAK likelihood.
