# Fraser River Chum Salmon

## Identity and current assessment product

The DFO 2026 Pacific Salmon Outlook describes the Fraser Chum Stock Management
Unit (SMU) as dominated by the Lower Fraser Chum Conservation Unit (CU). The
2026/2027 Southern B.C. Salmon Integrated Fisheries Management Plan (IFMP)
covers the Fraser River watershed, but DFO says the complete plan is available
on request; the public summary is available online. The DFO inventory's
“Fraser Chum Salmon” row is therefore retained as the Fraser Chum SMU, distinct
from the Lower Fraser CU and from the broad “Inner South Coast Chum” row.

The latest public current-season result located is the final 2026 in-season
Fraser Chum run-size notice (October 22, 2026). It estimates 1,521,000 fish
(median), with an 80% interval of 748,000–3,051,000. The estimate combines
current Albion test-fishery catch information with historical run-size and
migration-timing information in a Bayesian nonlinear regression. This is an
aggregate seasonal run-size estimator, not an age-structured population
assessment.

## Inputs and output coverage

- **Catch:** the current notice describes total Albion test-fishery catch. It
  does not describe a catch-numbers-at-age likelihood.
- **Abundance index:** Albion test-fishery information supports aggregate
  terminal run size. The 2026 Outlook separately refers to post-season
  escapement estimates that include age data; it does not identify these as an
  age-specific abundance-index likelihood in the run-size model.
- **Weights and maturity:** no current production-model age-specific weight or
  maturity inputs were identified for the aggregate run-size estimator.
- **Mortality and timing:** the public notice describes estimating aggregate
  abundance and migration timing; it does not provide annual F-at-age or
  M-at-age. The Albion test fishery operates seasonally, normally every other
  day from September 1 through October 20 and daily later in the season. This
  calendar schedule is not a within-year timing fraction for an age-specific
  survey likelihood.
- **Outputs:** the 2026 median and 80% run-size interval are comparable only as
  aggregate seasonal abundance. No annual N-at-age, F-at-age or M-at-age series
  from a production model was identified.

The Fraser Chum SMU is ineligible for the age-disaggregated candidate set.
This finding concerns the current publicly described assessment product; it
does not claim that DFO has no age-composition monitoring data.

## Related inventory row

The separate “Inner South Coast Chum” inventory row does not resolve to one
current unit. DFO material distinguishes Fraser and non-Fraser chum components.
The generic row is screened as identity-ambiguous, with eligibility unresolved;
it is not assigned the Fraser estimate or counted as another stock. No
canonical stock, assessment, input or output records were added.

## Sources and cache

- [2026/2027 Southern B.C. Salmon IFMP summary](https://www.pac.dfo-mpo.gc.ca/fm-gp/mplans/smon-sc-cs-ifmp-pgip-sm-eng.html)
- [2026 Pacific Salmon Outlook](https://publications.gc.ca/collections/collection_2026/mpo-dfo/Fs141-9-2026-eng.pdf)
- [DFO Fraser Chum in-season notice, October 22, 2026](https://www-ops2.pac.dfo-mpo.gc.ca/fns-sap/index-eng.cfm?DOC_ID=371699&ID=all&pg=view_notice)
- [Albion test fishery information](https://www.pac.dfo-mpo.gc.ca/fm-gp/fraser/albion-eng.html)

The ignored local cache contains the 2026/2027 IFMP summary and the final 2026
run-size notice. The current Outlook PDF was reviewed through its public
publication page, but its direct download returned a Government of Canada
archived-publication landing page instead of a PDF, so that response was not
stored or labeled as the source document. The locally cached file sizes,
retrieval date and SHA-256 hashes are recorded in
`source_cache/discovery_dfo_fraser_chum_2026/sources.csv`.
