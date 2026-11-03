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

## Recovered survey and weight inputs

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

## Biological limitation and translation decision

Annual beginning-of-year stock weights and female maturity ogives are also
required for the assessment's biomass calculations. The report describes the
weight and maturity models but does not publish their full numeric age-year
matrices. The revised maturity model has cohort effects in a beta-binomial
likelihood; it is not simply the proportion mature among sampled fish.
The [2025 maturity technical report](https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41287332.pdf)
(Technical Report 3671; [DOI](https://doi.org/10.60825/z5m6-hx38)) is now cached
through the catalogue's working full-text link. Figures 5 and 7 show the annual
fitted ogives; Tables B1–B6 document changing maturity codes. Table 4 points to
older published maturity estimates, which are not the revised inputs used in
this assessment. No values have been digitized from figures or substituted
from an older assessment.

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

A Sentinel-only simplified fit could omit the other surveys, but still needs
complete stock weights and maturity for its chosen year/age grid. Conversion
for 1995–2024, ages 2–11, is explicitly checked and stops at the missing stock
weights. No model fit or dashboard is generated until these biology inputs
are recovered or a defensible alternative is explicitly specified. The main
report, framework and supporting biology/survey reports have all been checked;
this is a remaining data gap, not a catchability restriction. No output
estimates have been reused as observations or biological inputs.

The revisit found no additional numerical assessment-input surfaces in these
sources. The recoverable inputs remain the 330 Sentinel mobile index cells
and 503 commercial catch-weight cells, alongside catch-at-age and fixed M.
Catch weights do not supply the missing stock-weight surface. The readiness
test now checks the maturity gap independently using complete test-only
weights; these fixtures are never written to the database or used in a fit.
To proceed without inventing biology, the needed source products are annual
beginning-of-year stock weights and the revised female maturity proportions
for the selected model years and ages. Additional survey indices would be
useful but are not required for a clearly labelled Sentinel-only model.

The cached source files and checksums are listed in
`source_cache/dfo_cod_3pn4rs_2025/manifest.csv`.
`scripts/database/038_import_dfo_cod_3pn4rs_2025.R` reproduces the canonical
table imports; `039_validate_dfo_cod_3pn4rs_2025.R` checks every imported value
against the cached tables. `057_cache_dfo_cod_3pn4rs_sources.R` retrieves the
additional public survey archives and maturity report and records their URLs
and checksums. The source-input test also prevents catch weights from being
mistaken for sufficient stock biology. This stock remains partial and is not
counted as a completed database-to-tinyAM analysis.
