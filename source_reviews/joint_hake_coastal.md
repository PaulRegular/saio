# Joint U.S.–Canada coastal Pacific hake

## Assessment selection and authoritative sources

`joint_hake_coastal_2025` represents the 2025 official base model, Stock
Synthesis 3.30.23.1, historical years 1966–2024. This offshore/coastal treaty
stock is an agreed catalogue exception, not Strait of Georgia or Puget Sound
resident hake. No Charbonneau–Keith identifier is invented.

The [detailed 2025 assessment](https://repository.library.noaa.gov/view/noaa/67186/noaa_67186_DS1.pdf),
[official model archive](https://www.pcouncil.org/documents/2026/08/hake-2025-model-files-zip-file.zip/)
and [2026 update](https://www.fisheries.noaa.gov/s3/2026-02/hake-assessment-2026.pdf)
are cached with dates and checksums. The native archive identifies these as
the 2025 base files. The newer 2026 report is a catch-only/projection update
retaining the fitted 2025 model; its native data still end in 2024. Newer
forecast removals and advice are not mixed into the 2025 historical fit.

The archive deliberately omits the 8000 posterior report files. A separately
cached, pinned [NOAA extraction](https://github.com/NOAA-FIMS/case-studies/tree/04aadf2748945371ad7d3e26847035da7801543f/content/data_files)
preserves official SS3 summaries. Its `ss3_results` are the reference model,
not the simplified FIMS fit shown on that project's website. The extracted
2024 and 2025 SSB medians, 1189495 and 1223070 t, exactly match the detailed
report's prose; M and steepness also match the rounded production estimates.
This corroboration permits retaining more precise native medians, with the
report's rounded credible intervals clearly distinguished.

## Inputs, units and processes

The model has combined-sex ages 0–20+, a single combined national fishery and
one acoustic age-2+ biomass survey. Observed ages use 1–15+. Catch is tonnes,
survey biomass tonnes, and supplied empirical weights kg/fish. The survey
uses month 7, fraction 0.5. Only positive-index survey records are active;
negative-index placeholder rows are not observed one-tonne survey values.
The 2025 model excludes the age-1 index.

Age compositions are supplied as **percentages**, with row sums 99.98–100.02.
The database preserves these values, sample sizes, partition and ageing-error
keys as native frequencies, rather than silently replacing them by proportions.
The source normalizes each row and fits separate Dirichlet-multinomial
fishery/survey likelihoods. Fixed catch log SD is 0.01. Survey log SD combines
sampling SD with an estimated additional component in quadrature; that extra
component is not a native per-age precision weight.

`wtatage.ss` supplies empirical annual population, fishery and survey weights,
plus a **maturity-times-fecundity weight**, not a maturity proportion. The
beginning- and mid-year population weights are equal in this run. The negative
year -1940 is a fill instruction before annual weights begin in 1975; it is
preserved as a blank-year source vector with its meaning documented. Explicit
future mean weights remain dated future inputs. The fixed female fraction is
0.5, the first mature age is 2, and spawning is at the beginning of the year.
Maturity controls in the control file are disabled because the supplied
fecundity product is used; its external temperature dependence is not an
internally estimated maturity likelihood.

M is estimated as a single constant with a lognormal prior (log median
-1.60944, log SD 0.1) and bounds 0.05–0.4. Its posterior median is 0.233454;
it is not a supplied fixed input. Recruitment follows Beverton–Holt, with
estimated R0 and steepness under a beta prior, and fixed log SD 1.4. Early
deviations begin in 1946; main deviations end in 2022. Later recruitment uses
the stock–recruit mean and source bias rules. Cohort survival is deterministic.

Fishery age selectivity is nonparametric, with deviations at ages 2–6 from
1991 under fixed SD 1.4 and zero autocorrelation. Survey selectivity is
nonparametric and time-invariant, with estimated increments at ages 3–6 and
older increments fixed to zero. It need not be a logistic or monotone curve.
Survey q is **analytically profiled** (`Q_setup float=1`). An inactive LnQ
parameter phase therefore does not fix q to one. The reported scalar q median
is 0.894; age selectivity is a separate part of the observation equation.

## Outputs and comparison limits

Tables 17–19 give historical marginal posterior medians of N-at-age (million
fish), biomass-at-age (thousand tonnes) and exploitation-at-age (percent).
They retain ages 0–20+. Table 23 gives native aggregate biomass; Table 24 gives
95% equal-tail credible intervals, not SEs. The NOAA extraction supplies more
precise SSB (tonnes), age-0 recruitment (thousand fish), M and annual log-F
summaries from the same base model. Back-transformed log-median F intensity
is retained under its own definition; it is not Fbar or F-at-age. Its
finite-sample median convention can differ slightly from a median computed
after exponentiating every draw.

No instantaneous F-at-age posterior is recovered. Neither the median
exploitation fraction nor products of marginal selectivity/F medians can be
substituted for it. Likewise, sums of marginal N or biomass medians are not
necessarily posterior medians of their totals. Derived common-age sums must
be labelled approximate and cannot inherit an interval without joint draws.
Native aggregate SSB and its intervals remain separate from such calculations.

Completeness is partial: joint posterior draws, age-specific uncertainty and
the full 52-key ageing-error inventory are not yet exported. All recovered
quantities refer to the 2025 production base, not a FIMS demonstration or the
2026 projection update.

## Observation and comparison definitions

The translation uses 1975–2024 and ages 2–15+. Native percentages are
normalized outside the database, as in the source, and converted using
original totals and weights before age restriction. All supplied weights
and fecundity products are identical across ages 15–20+, so the observed
15+ grouping does not require an invented biological tail. The supplied
fecundity product divided by population weight gives maturity; first mature
age 2, female fraction 0.5 and January 1 timing are applied separately.

The local dashboard retains native posterior SSB and explicitly approximate
common-age sums of marginal medians. F-at-age and Fbar comparisons remain
unavailable. Available credible intervals are retained only on their native
quantities; no uncertainty is attached to sums or pooled posterior medians.
