# Northern Gulf cod (3Pn4RS) source review

The canonical record represents [DFO Research Document 2026/010](https://publications.gc.ca/site/eng/9.958344/publication.html),
the detailed assessment peer-reviewed in February 2025 and published in
February 2026. Its data and reported estimates run through 2024, although the
English title calls it the assessment in 2025. The [2026/012 Science Advisory
Report](https://publications.gc.ca/collections/collection_2026/mpo-dfo/fs70-7/Fs70-7-2026-012-eng.pdf)
is a newer summary update and does not replace this detailed assessment record.

The [2025/074 framework report](https://publications.gc.ca/collections/collection_2025/mpo-dfo/fs70-5/Fs70-5-2025-074-eng.pdf),
[2022/033 catch and removals report](https://publications.gc.ca/collections/collection_2022/mpo-dfo/fs70-5/Fs70-5-2022-033-eng.pdf),
[2022/049 survey-input report](https://publications.gc.ca/collections/collection_2022/mpo-dfo/fs70-5/Fs70-5-2022-049-eng.pdf),
and [2024/045 weight and model report](https://publications.gc.ca/collections/collection_2024/mpo-dfo/fs70-5/Fs70-5-2024-045-eng.pdf)
are cached with checksums in the local source manifest.
The production assessment also cites [2025/032, the 2024 August survey
report](https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41297039.pdf).
This report is now cached: its cod results are Figures 31–33, while its three
tables describe stations, taxa and specimen sampling. It does not supply a
numerical cod age-by-year index or biological input matrix.

The report provides catch-at-age in thousands of fish for ages 2–11+ in
1974–2024 and model outputs for abundance, biomass, fishing mortality, natural
mortality, recruitment, and two Fbar age ranges. Fixed M values for ages 2–11+
through 1983 are also reported. From 1984 onward, M is estimated for ages 4–11+;
ages 2 and 3 remain fixed. These values and the reported output series are
stored with their original units and age groups. The six survey series and
their year/age coverage are recorded as assumptions.

The assessment uses six age-specific abundance indices: DFO August (1985–2024,
ages 2–11+), Sentinel mobile (1995–2024, ages 2–11+), Sentinel gillnet
(1995–2024, ages 4–11+), Sentinel summer longline (1995–2024, ages 3–11+),
Sentinel fall longline (1995–2020, ages 3–11+), and the Minet bottom-trawl
series (1973–1976, ages 3–11+).

## Recovered survey and biological inputs

Table 28 **does** provide numerical Sentinel mobile mean numbers-at-age for
1995–2024, ages 1–11+. All 330 values are now stored, including the reported
age-1 zero in 1997. The official assessment uses only ages 2–11+. These are
relative indices in mean fish per standardized tow, not total stock abundance.
Section 2.1.3.3 describes the July survey and standardization to a 54-foot
horizontal opening and 1.25-nautical-mile tow. The database records 0.54 as a
mid-July timing approximation; the exact model-configured fraction is unresolved.
The published standardized series remains one survey. Splitting it by vessel
would undo the intent of the source standardization.

Table 24 supplies 503 commercial catch-weight values in kg per fish for
1974–2024, ages 2–11+. Seven cells printed as dashes are omitted; printed zeros
are retained. These weights describe fish in the commercial catch and are
stored as `catch_weight`, not as beginning-of-year stock weights. No interpolation
or conversion from fitted population outputs has been applied.

The assessment report's Figure 90 provides annual beginning-of-year stock
weights. The blue fitted curve is digitized for ages 2–11+ in 1985–2024; black
empirical observations are excluded. Figure 70 similarly provides annual female
maturity ogives from the upstream maturity model, digitized for ages 0–15 in
1983–2024; colored survey observations are excluded. Both are biological inputs
from models upstream of the population assessment, not population-model outputs.
Pixels between annual curve points are interpolated, and the values are labeled
`digitized` because the plotted curves do not provide table-level precision.

The framework specifies `m[2]=1.0`, `m[3]=0.65`, `m[4]=0.45`, and
`m[5+]=0.15` per year in `log(M[a,y]) = log(m[a]) + delta[a,y]`. These
age-specific means are stored separately from estimated M outputs. The fixed
M values reported for years before 1984 remain in the database as reported.

The numerical annual indices for the other five official streams remain
unrecovered. DFO's public [Teleost
survey](https://open.canada.ca/data/en/dataset/40381c35-4849-4f17-a8f3-707aa6a53a9d),
[Cabot survey](https://open.canada.ca/data/en/dataset/7001783a-4dc0-41bc-8932-1dae1e699d91),
[Alfred Needler survey](https://open.canada.ca/data/en/dataset/4eaac443-24a8-4b37-9178-d7cce4eb7c7b),
and [mobile Sentinel survey](https://open.canada.ca/data/en/dataset/929fe07f-ab8e-4b3c-8ee3-1aa7a9ea0b1a)
archives, dictionaries and catalogue metadata are now cached. They contain
station catches, individual biological samples and, for Needler and Sentinel,
separate length-frequency files. The downloaded Teleost and Cabot archives do
not provide a separate length-frequency file. The biological sampling-table
identifiers alone do not establish that measured specimens are an unbiased
sample of the catch. Counts of aged specimens therefore cannot be treated as
catch numbers-at-age.

For an **uncalibrated alternative**, logical survey labels would distinguish
Lady Hammond/Western IIA, Alfred Needler/URI, Teleost/Campelen and John
Cabot/modified Campelen. Section 2.1.3.1 describes their overlapping calibration
years; official published RV indices are on the John Cabot equivalent scale.
Separate age-specific q groups can handle vessel efficiency differences, but
cannot replace age-length expansion, tow-distance standardization or
area-weighted survey estimation. The August stock indices cover 4RS; 3Pn was
not visited after 2003. Reduced and uniform strata series must not be spliced
without accounting for their different coverage. The Sentinel program likewise
has an all-year series excluding shallow strata 101–103 and a 2003-onward series
including them. Table 28 does not identify that choice explicitly, so no
unverified spatial correction has been imposed.

The logical labels for any future reconstruction from the raw RV archives are:

| Vessel / gear label | Period described by the production report | Public age samples in 4RS within the assessment period |
|---|---|---|
| DFO August — Lady Hammond / Western IIA | 1984–1990 | No Lady Hammond archive recovered |
| DFO August — Alfred Needler / URI | 1990–2004 | 1990–2003 |
| DFO August — Teleost / Campelen | 2004–2022 | 2004–2022 |
| DFO August — John Cabot / modified Campelen | Comparative fishing in 2021–2022; regular survey from 2023 | 2023–2024; the cached 2022 samples have no ages |

These labels distinguish potential uncalibrated observation streams; they are
not additional numerical indices in the database. Comparative and regular
survey tows must be distinguished before constructing annual indices. The
published Sentinel mobile series already standardizes tow geometry, so it
retains its existing label rather than being split artificially.

## Biological source details and translation decision

The source report describes the weight and maturity models but does not publish
their numeric age-year matrices as tables. The plotted curves make a limited
translation possible. Figure 70 is the fitted annual maturity ogive, not simply
the proportion mature among sampled fish; the revised maturity model has cohort
effects in a beta-binomial likelihood.
The [2025 maturity technical report](https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41287332.pdf)
(Technical Report 3671; [DOI](https://doi.org/10.60825/z5m6-hx38)) is now cached
through the catalogue's working full-text link. Figures 5 and 7 show the annual
fitted ogives; Tables B1–B6 document changing maturity codes. Table 4 points to
older published maturity estimates, which are not the revised inputs used in
this assessment. The population-assessment Figure 70 is used for digitization;
no older assessment estimates or raw biological samples are substituted.

The public RV samples contain ages, individual weights and maturity stages.
Within the stock's 4RS survey region, aged Needler samples cover 1990–2003,
Teleost samples cover 2004–2022, and Cabot samples cover 2023–2024 within this
assessment period. Cabot's 2022 records have no ages. Some years lack maturity
stages or have ambiguous legacy codes; weights are in grams. Sentinel summer
samples have ages from 1999 onward, but no individual weights from 2018 onward
and almost no maturity records after 2000. These are raw biological samples,
not complete annual stock-weight or fitted maturity surfaces. Pooling them or
averaging length-stratified samples without the sampling weights would create
new biological assumptions, not recover authoritative assessment inputs.

A Sentinel-only simplified fit is prepared for 1995–2024, ages 2–11+, using
published catch-at-age, the Sentinel mobile index, digitized Figure 90 stock
weights and Figure 70 maturity, and the documented baseline M means. It excludes
the other five official survey streams and simplifies their combined observation
structure, the source's initial-state integration, and the source likelihoods.
Sentinel timing remains a mid-July approximation. These choices are explicit
in the translation script; no fitted population values are used as observations
or biological inputs.

The source record remains partial: numerical inputs for five official surveys,
exact configured timing, and some likelihood details are unresolved. The plotted
biological surfaces and framework M means are now stored with provenance and
digitization notes, allowing the limited Sentinel-only translation to be fit
and compared without inventing data.

## Initial tinyAM fit

The Sentinel-only translation converged with package-default starting values
and no source-based starts (optimizer code 0; objective 615.876; maximum
absolute gradient 0.000113; positive-definite Hessian and standard errors
available). The fit used 40 fixed and 509 random effects. The dashboard is
cached locally at `results/cache/dfo_cod_3pn4rs_2025/dashboard.html`. An
advisory reports a recruitment AR(1) correlation interval spanning more than
0.5, so recruitment persistence remains imprecise.

Numerical convergence did not imply close agreement with the official outputs.
Across 1995–2024, mean absolute percent differences were 104.9% for approximate
SSB (terminal difference −15.4%; trend correlation 0.295), 43.8% for approximate
recruitment (−47.4%; 0.898), and 27.8% for total abundance (+48.5%; 0.807).
For age-specific series they were 312.4% for N (terminal +48.5%; mean within-age
trend correlation 0.853), 62.2% for F (+55.3%; 0.743), and 57.0% for estimated
M (−16.7%; 0.738). Fbar differed by 52.1% on average and by +270.2% in 2024,
despite a 0.939 trend correlation. The limited index coverage and simplified
population processes remain substantial differences; retain the fit as a
numerically successful but weakly matching first translation.

The cached source files and checksums are listed in
`source_cache/dfo_cod_3pn4rs_2025/manifest.csv`.
`scripts/database/038_import_dfo_cod_3pn4rs_2025.R` reproduces table imports and
digitizes the fitted biological curves from the cached assessment PDF;
`039_validate_dfo_cod_3pn4rs_2025.R` checks coverage, units, provenance, values,
and biological constraints. `057_cache_dfo_cod_3pn4rs_sources.R` retrieves the
additional public survey archives and maturity report and records their URLs
and checksums. The source record remains partial because most official indices
and some exact likelihood settings have not been recovered.
