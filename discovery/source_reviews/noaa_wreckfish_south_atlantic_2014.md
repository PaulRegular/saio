# South Atlantic wreckfish, latest accepted assessment (2014) and preliminary update (2026)

## Assessment status and unit

NOAA Stock SMART identifies stock 10369, *Polyprion americanus*, for the
Southern Atlantic Coast. Its latest accepted production assessment is the 2014
assessment, with data through 2010; NOAA continues to cite that assessment for
current stock status. The 2014 Scientific and Statistical Committee (SSC)
review accepted the assessment for management advice.

SAFMC released a preliminary update in April 2026, using landings through 2024
and a fishery-dependent landings-per-unit-effort index. The April 2026 SSC report
describes this as an assessment under development and discusses candidate
models and unresolved data questions. It is not a completed replacement for the
accepted 2014 production assessment.

## What the assessment observes

The 2014 reference model is an age-structured statistical catch-at-age/length
model, but its reported observation likelihoods are an aggregate commercial
CPUE series and commercial catch-at-length proportions. The report describes
landings from 1967–2010 and catch-at-length grouped over sampled periods in
length bins from 30 inches (minus group) to 50 inches (plus group). The model's
age states and age-specific selectivity are generated through its age-length
and growth structure; that does not make the fitted catch observations
catch-at-age.

The 2026 preliminary update uses commercial landings from 1987–2024, an
aggregate fishery-dependent LPUE index from 1991–2024, and length compositions
from 1987–2023. It says wreckfish are not regularly caught in NOAA surveys, so
there is no fishery-independent survey index. The base model is length-only.
The update also documents port-sampled otoliths for age work from 1991–2012
(1,588 otoliths across years and states). The report proposes first treating
age compositions as marginal data for comparison and only adding them to the
likelihood if they are shown to represent the fishery. It says this work will
be done in a later phase. The numeric annual age-frequency observations and a
run-ready age-composition file were not located in the preliminary report or
linked public materials reviewed.

## Biology, mortality, timing, and outputs

The 2014 assessment derives weight-at-age from a growth curve and a
length-weight relationship. Maturity is specified at length and converted to
age through the model's age-length distribution. Its reference case estimates
age-independent natural mortality (0.0366 per year). The report supplies
aggregate CPUE and length compositions but no fractional-year survey timing.

The 2026 preliminary report gives growth, length-weight, and length-based
maturity parameters. It uses M = 0.037 per year with SD = 0.00407 as life-history
information; the SSC report notes that M is not estimable from the available
data. The fishery runs from April 15 to January 15, but that fishing-year
definition is not an observation-time fraction for a survey likelihood.

The accepted 2014 assessment reports biomass, recruitment, fishing mortality,
and reference-point results. The preliminary 2026 length-only model reports
spawning biomass with 95% confidence intervals and aggregate F and recruitment
trends. Neither source reviewed here provides an age-specific survey index or
a numerically recoverable annual catch-at-age likelihood series. The preliminary
run is not a final production output.

## Screening decision

This candidate remains **eligibility-unresolved** for the age-disaggregated
expansion. The 2014 accepted run does not fit catch-at-age or an age-specific
abundance index. The 2026 preliminary work shows that port-sampled ages exist,
but their representativeness and inclusion in the model likelihood remain
pending, and the numerical annual age compositions were not recovered. Do not
count the age-structured model label or its model-estimated age states as
observed age inputs. Revisit if the age frequencies or final 2026 model files
become public. No canonical stock, assessment, input, or output values were
imported.

## Sources

- [NOAA Wreckfish species page](https://www.fisheries.noaa.gov/species/wreckfish) — current status still cites the 2014 assessment; cached 2026-10-31.
- [2014 South Atlantic wreckfish assessment](https://safmc.net/documents/12c_wreckfish_sar_april2014_final-pdf/) — data through 2010, CPUE and catch-at-length likelihoods, age-based population model.
- [2014 SSC review report](https://safmc.net/documents/12d_ssc_apr2014_report_final_rev1-pdf/) — accepted production assessment review.
- [April 2026 preliminary wreckfish assessment](https://safmc.net/documents/8b_wreckfish-stock-assessment-update-april-2026-pdf/) — landings, LPUE, length compositions, and proposed future age-composition work.
- [April 2026 SAFMC SSC report](https://safmc.net/documents/ssc_apr2026_report_final/) — confirms the new model is under development and identifies data and identifiability questions.
- Local file sizes, retrieval dates, URLs, and SHA-256 hashes are recorded in `source_cache/discovery_noaa_wreckfish_2014/sources.csv`.
