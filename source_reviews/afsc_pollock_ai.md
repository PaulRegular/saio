# Aleutian Islands walleye pollock

## Official run

`afsc_pollock_ai_2024` is the official Model 15.1 retained by the final December
2024 SSC report. The next operational assessment is scheduled for 2026; public
development files do not establish a replacement production run. The starting
catalogue identity is `AFSC_AI_Gadus_chalcogrammus`. The modeled Northern
Regulatory Area is 170°W–170°E. It is separate from EBS and Bogoslof pollock.

The [2024 SAFE report](https://files.npfmc.org/SAFE/2024/AIpollock.pdf) and
pinned files from the [assessment repository](https://github.com/afsc-assessments/AI_pollock)
and [AMAK examples](https://github.com/afsc-assessments/AMAK) are cached with
manifests. The accessible fitted repository files are older runs; they are used
only to investigate conventions, not as 2024 observations or output estimates.

## Source distinctions that affect replication

The current report supplies 1978–2024 catch totals, 18 fishery age compositions,
the NRA survey biomass from 1991 onward, 12 survey age compositions through
2018, and complete annual fishery/survey weights. The model fits biomass and
multinomial compositions separately. Canonical records preserve that structure.
The catch input is Table 1A.1's **Best Estimates** column, which differs from
the adjacent official blend values. The terminal fitted assumption is 5,106 t;
4,482 t is the incomplete September catch. Survey age data before 1991 are
deliberately excluded by the official 2024 model.

The supplied multinomial sizes are retained separately from raw sampling counts
and fitted effective sizes: survey N is 1 in 1991 and 100 thereafter; fishery
weights match the active years in the p.12 table. Published survey CVs are rounded.
The fixed 15×15 ageing-error matrix is retained as assumption rows.

Model 15.1 **estimates** one constant M under a prior with mean 0.2 and CV 0.2.
The reported estimate 0.206 (Table 1A.18) is an output; the Table 1A.15 value
0.21 is a coarser rounding, not a fixed input. Alternative Model 15.2 is excluded.
The adopted maturity schedule is the **GOA** row of Table 1A.14, not the BSAI
row printed above it. Female probabilities and the combined-sex fraction 0.5
are distinguished. The historical framework has March spawning. Exact current
survey timing remains unresolved; summer field timing does not establish an
exact configured fraction.

Recruitment has a Beverton–Holt mean with fixed steepness 0.7. The report's
description of recruitment variability as a variance of 0.6 is not enough to
establish whether that number is an SD in the current implementation; the
production control file has not been recovered. This uncertainty is explicit.
Survival is deterministic. Fishery selectivity is penalized, nonparametric and
time-blocked, with ages 8+ shared; survey selectivity is time-invariant. The q
scalar is fixed to one under normalization over ages 5–12, not independently
fixed at every age.

## Outputs and remaining gaps

Native N is in **billions** of fish, rounded to 0.001 billion. Recruitment has
more precision and natural-scale SEs in **millions**. SSB and biomass come from
the 2024 columns of Table 1A.19, with approximate 95% confidence limits. The
neighboring 2022 columns and 2025 projections are excluded.

Despite Table 1A.23's heading, its footnote defines F as the arithmetic average
across ages. It is retained as such. Only terminal fishery selectivity is
available, so terminal F-at-age is derived as mean F × selectivity / mean
selectivity. No historical F surface is invented from that terminal curve or
from rounded N. Derived F has no reconstructed uncertainty.

The separate constant population-weight vector for the current run was not
recovered. Annual survey weights remain original survey inputs; they are not
relabeled as native population weights. Input, assumption and output statuses
remain partial. These gaps differ from confirmed fixed q, an absent length
likelihood and deterministic older-age survival.

## tinyAM translation and numerical result

The translation uses 1978–2018 and ages 1–15+, ending at the latest matching
age observations. Aggregate-only survey/catch observations after 2018 cannot
enter this approximation. It retains original catch weights and uses the
recorded annual survey weights as an explicit population-weight approximation.
It fits deterministic survival, free initial abundance, a Beverton–Holt median
recruitment curve with estimated parameters and IID SD, independent F random
walks and one estimated M. The source fixed steepness, M prior, q normalization,
F penalties, composition likelihood and ageing error are not reproduced.
Survey time 0.5 approximates summer; March spawning and GOA maturity are retained.

Default initialization failed (code 1, objective 642.037, gradient 2.53e8 and
a non-positive-definite Hessian). The one permitted retry changed only starting N
and M. It reduced the objective to 625.738 and the gradient to 2.18e-5, but
still failed with code 1, a non-positive-definite Hessian and unavailable
fixed-parameter covariance. The SD-report object does not provide usable
uncertainty in this case. Both attempt records are retained; no further model
tuning or initialization retry was conducted.

A source-prior sensitivity approximated the reported M prior (mean 0.2, CV 0.2)
with a moment-matched lognormal penalty on log M, holding the observations and
other model settings fixed. The package-start attempt failed (code 1, objective
635.205, gradient 4,976 and non-positive-definite Hessian). A single aligned
source-start retry reached objective 628.863 and gradient 3.31e-5, but still
failed the fixed-parameter covariance check (code 1; no usable uncertainty).
The resulting N scale was orders of magnitude beyond the official estimate, so
its point comparisons are not interpretable. This prior approximation alone
does not resolve the q/N/M identifiability problem; it was not retained.

Usable predictions permit an **exploratory** dashboard with the numerical failure
visible. N rises to roughly 10^12–10^16 fish, F falls to 10^-12–10^-8 and survey
q to 10^-10–10^-8. Unit checks confirm this is an extreme fitted scale trade-off,
not confusion between the report's billions, recruitment millions and tinyAM's
individual fish. Removing the source's fixed-q normalization and M prior is an
important identifiability limitation of this approximation. It must not be
interpreted as a successful reproduction. Native SSB is labelled approximate
because population weights differ; historical F-at-age is unavailable and
arithmetic Fbar is non-equivalent. All available abundance/SSB comparisons and
estimated M are flagged for review; missing F comparisons are not passes.
