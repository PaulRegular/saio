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
