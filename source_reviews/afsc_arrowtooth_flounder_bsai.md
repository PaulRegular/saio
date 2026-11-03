# Bering Sea and Aleutian Islands arrowtooth flounder

## Production source

Charbonneau–Keith identity `AFSC_BSAI_Atheresthes_stomais` retains the
catalogue's spelling; the species is *Atheresthes stomias*. This is not
Kamchatka flounder, a Gulf of Alaska stock, or the CEATTLE multispecies model.
The December 2022 SSC selected **Model 18.9 (2022)**. The 2024 document updates
catches/projections without rerunning the assessment and scheduled the next
full assessment for 2026 at that time. The newer 2026 off-cycle report now
lists 2027; neither projection report replaces the detailed 2022 fit.

The detailed 2022 SAFE and the 2024 off-cycle projection report are cached
under `source_cache/afsc_arrowtooth_flounder_bsai_2022/` with URLs, retrieval
dates and SHA-256 checksums. Searches covered AFSC assessment/code repositories,
the cited NOAA/NPFMC portals and the authors' public repositories. No matching
production native input/object was recovered. The old framework archive URLs
returned 404; the retained 2022 detailed methods describe the unchanged 2018
generalized model. Unresolved settings are not called absent.

The September 2026 [off-cycle projection report](https://meetings.npfmc.org/CommentReview/DownloadFile?fileName=6.+BSAI+Arrowtooth+Flounder.pdf&p=41b6de60-46cb-436c-a828-e5cfb4e47ffd.pdf)
is also cached locally with its retrieval details and checksum. It is explicitly
labelled as pre-dissemination peer review and not formally disseminated. The
report says the off-cycle update did not rerun the assessment or change its
inputs: it uses the 2018 Model 18.9 as updated in the 2022 full assessment and
updates catch information for projections. It schedules the next full
assessment for 2027; the 2024 report's earlier schedule of 2026 has therefore
been superseded. This draft does not replace the 2022 detailed production run
or resolve the missing numerical likelihood inputs, so none of its projected
values are imported into the canonical assessment record.

## Inputs and activation

The model covers 1976–2022, female/male ages 1–21+. Tables 6.2a/b distinguish
arrowtooth-only catch from the combined arrowtooth/Kamchatka total. Import the
source's **ATF estimate**, not the combined total, through complete 2021.
Do not recompute the source species allocation from rounded proportions.
The 2022 reported 7,107 t is partial through October 14; the full-year model
catch was not verified, so it is not substituted as a complete input.

Table 6.10 supplies original fixed sex-specific kg/fish weights and female
maturity, with age 21 a plus group. M is fixed at **0.2 female, 0.35 male**.
These are inputs, not estimated-M successes. The model has deterministic
cohort survival, average log recruitment plus annual deviations, final
recruitment at its mean, annual F intensity and sex-specific age selectivity.
Older fishery selectivities are shared. The source mean/median/mode point
convention is not fully established; do not infer it solely from MCMC limits.

Table 6.6's underlining identifies active survey data, verified visually:
EBS shelf 1992–2022 (2020 missing), slope 2002–2016, and Aleutian Islands
1991–2022. Keep earlier un-underlined estimates as explicitly inactive source
context. Preserve each series and its CV; do not interpret CV as log SD.
Within-year timing fractions were not verified and remain missing.
Regional q shares are externally derived from random-effects survey biomasses:
0.825 shelf, 0.08 slope and 0.095 AI, with an additional bottom-temperature
effect on shelf q. Their full activation/covariance is unresolved; they are
not silently replaced by free tinyAM q coefficients.

Fishery likelihood inputs are length compositions. The report describes few
fishery otoliths, no accepted fishery age-composition likelihood, survey ages
in some years and survey lengths otherwise. The numerical composition arrays
and original 2018 age–length conversion matrix were not recovered. Sample
counts and fitted age-selectivity curves are not substitutes for those data.

## Recovered outputs and validation

Table 6.16 supplies all 47 historical years × 21 ages × two sexes of
beginning-year N, in **thousands of fish**. Preserve the plus group and sex
distinctions. Derived biomass-at-age is N-thousands × kg = tonnes. Its sums
reproduce Table 6.13 aggregate biomass within the rounding expected from
reported N. Total abundance is derived by summing the full sex/age surface,
without invented aggregate uncertainty. In 2022 biomass is **933,466 t** and
female SSB **507,275 t**; source 95% limits are retained as printed.
Recruitment at age 1 is taken from Table 6.14 through 2021, with its original
95% credible limits. The 2022 point is the sum of reported sex-specific age-1
N, with no reconstructed interval.

F-at-age for 1976–2021 can be recovered independently of rounded selectivity:
F[y,a] = log(N[y,a]/N[y+1,a+1]) − fixed sex-specific M. For ages 20/21+,
the shared old-age selectivity permits
F = log((N[y,20]+N[y,21])/N[y+1,21]) − M. Omit unresolved nonpositive
cells only after verifying zero lies within the N-printing bounds. Do not clip
them or invent an SE. Final-year 2022 F-at-age remains unavailable without
2023 N or native output. Table 6.15 full-selection F is retained separately,
not called population-weighted Fbar. SSB is not reconstructed at an assumed
spawning time.

## Translation blocker

The source record is useful, but not model-ready. A tinyAM fit requires
verified catch-at-age (or numerical catch lengths with a defensible observed
age–length key), survey age inputs and timing. Generating catch or survey
observations from the fitted N/F surface would fit the source estimates rather
than its data. No such reconstruction or default timing is used.

This is one partial curated case, **not a completed runnable translation or
actual fitting attempt**. No starting-value retry or model rescue was tried.
The missing inputs remain an explicit shortfall against the twelve-translation
target; they are separate from tinyAM's unsupported catch-length likelihood.
