# Eastern Bering Sea yellowfin sole

## Official run and provenance

`afsc_yellowfin_sole_ebs_2024` represents the final 2024 Model 23.0,
`m23_0_2024`, not the incremental sensitivity fits in its SAFE report.
Charbonneau–Keith identifies this stock as `AFSC_EEBSAI_Limanda_aspera`.
It is one BSAI management-stock case, with an EBS+NBS survey extent and
female/male states retained separately. No 2025 replacement fit was produced
during the funding lapse.

The [2024 report](https://files.npfmc.org/SAFE/2024/BSAIyfin.pdf) and
[native production files](https://github.com/afsc-assessments/BSAI_YFS/tree/a86ab6f861163c24d4514f6c9fec4e74367ed911/m23_0_2024)
are cached with checksums and a pinned revision. The production run matches
the published 2024 SSB of 751023 t and biomass of 2412520 t. Older source
comments saying 2021 do not change the actual 1954–2024 input years.

## Inputs and equations

The model covers ages 1–20+, two sexes, one fishery and one EBS+NBS VAST
survey. Catch and survey biomass are in **thousand tonnes**, weights in
**grams**, and modeled numbers in **billions**. These scales independently
reproduce native biomass. Catch biomass is fitted on the log scale with
weight 300. Survey biomass uses supplied natural-scale SE, transformed as
sqrt(log(1 + (SE/observation)^2)). The source survey month is July, time 0.5.

Joint-sex fishery age compositions cover 1975–2023, with combined-sex rows
for 1964–1974. Joint survey compositions cover 1979–2023 intermittently.
Source composition likelihood sample sizes are retained; fishery split-sex
N is 21.5 and survey sizes are Francis-weighted haul counts, not the original
haul counts or fitted effective N. The source uses 0.001 offsets in its
multinomial terms. Some public data-file composition tokens are malformed
(multiple decimal points). Rather than guess repairs, the importer uses the
normalized **observed `oac`** input echoes from the production report, checking
joint row totals. The adjacent predicted `eac` arrays are never used as data.
This recovery and its printed precision remain explicit.

`Growth_Option = 1` uses supplied empirical population, survey and catch
weights. The inactive growth options in the code are not attributed to this
run. Source zero weights are preserved. Female maturity is supplied annually;
spawning biomass uses female N and survival to May 1 (4/12), without a second
half-sex multiplier. Female M is fixed at 0.12. Male M is estimated at
0.127699, with lognormal prior mean 0.12 and log width 0.8.

Survival is deterministic; recruitment has equal sexes and a fitted Ricker
relationship with lag one over 1978–2018, fixed log SD 0.6, and additional
IID recruitment deviations. Initial-age parameters are active. Annual F
multiplies logistic age selectivity with time deviations; male selectivity
offsets are inactive and ages 17+ share fishery selectivity. Survey scalar
log q has an estimated intercept and three estimated coefficients for supplied
temperature, survey start-date and interaction columns. Each supplied column
is centered over index years; the interaction must not be recomputed from
already-centered main effects.

A source observation-model difference is retained explicitly: survey biomass
is predicted at mid-year, but survey age proportions use begin-year N without
survival to the survey date.

## Outputs and remaining gaps

Native sex-specific N and F, female SSB, combined recruitment and biomass,
estimated male M and annual scalar q are recovered. SSB, recruitment, biomass
and q retain natural-scale SE and the native approximate lognormal limits,
which use **plus/minus two**, not 1.96, log SDs. Native marginal N/F SEs and
their covariance are unavailable; none are invented. The reported biomass is
called age 2+ in the SAFE table, while the source code sums all modeled ages
with their supplied weights; both facts are recorded.

Completeness remains partial: the full ageing-error and control inventory,
all biological sampling support and state covariance have not been exported.
This does not imply that absent stochastic survival or inactive growth effects
are unknown.
