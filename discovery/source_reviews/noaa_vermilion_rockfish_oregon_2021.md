# NOAA Oregon vermilion rockfish, 2021

## Assessment unit and sources

Stock SMART ID 15338 is the Oregon component of the current Vermilion rockfish
(OR/WA) managed stock. The 2021 report treats Oregon as a separate modeled
population from Washington and California based on the species' sedentary
nature, habitat separation and different exploitation history. The Pacific
Fishery Management Council adopted the 2021 assessment for management. Its
June 2025 meeting record retains the current managed stock as Vermilion
rockfish (OR/WA); the state assessment components remain separate and must not
be represented as one pooled model. The council's assessment index reviewed
on 2026-10-31 lists no later Oregon-specific assessment.

The source report and model archive were cached locally under
`source_cache/discovery_noaa_oregon_vermilion_2021/`. The ignored
`sources.csv` manifest records source URLs, retrieval date, byte counts and
SHA-256 checksums. The ZIP archive contains the Stock Synthesis data and control
files, parameter estimates, report outputs and age-specific biology output.

| Source | Use |
|---|---|
| [Oregon vermilion rockfish 2021 assessment](https://www.pcouncil.org/documents/2021/10/status-of-vermilion-rockfish-sebastes-miniatus-along-the-us-west-oregon-coast-in-2021.pdf/) | Data, assumptions, diagnostics and population outputs |
| [Oregon 2021 model files](https://www.pcouncil.org/documents/vermillion-rockfish-2021-model-files-or-zip-file/) | Accepted Stock Synthesis input and output files |
| [Vermilion/Sunset 2021 STAR panel report](https://www.pcouncil.org/documents/2021/10/vermilion-and-sunset-rockfishes-stock-assessment-review-star-panel-report.pdf/) | Peer-review context and adoption recommendations |
| [Pacific Council September 2021 meeting record](https://www.pcouncil.org/documents/2021/12/september-2021-meeting-record.pdf/) | Confirms the Council adopted the 2021 Oregon assessment for management |
| [Pacific Council groundfish assessment documents](https://www.pcouncil.org/stock-assessments-star-reports-stat-reports-rebuilding-analyses-terms-of-reference/groundfish-stock-assessment-documents/) | Assessment and model-file index; checked for later Oregon updates |

## Inputs and biological assumptions

The assessment is a single-area, annual Stock Synthesis model spanning
1892–2020, with ages 0–65 and commercial and recreational removal fleets.
Commercial removals are reported in metric tons; recreational removals combine
landings and estimated discard mortality. The model archive preserves the
accepted data and control files.

The model uses annual length compositions and conditional age-at-length data.
The report records 896 commercial aged fish from 2004 and 2007–2020 and 1,180
recreational aged fish from 2005–2020. These samples support a documented
catch-at-age reconstruction during supported periods, but do not directly
provide annual catch numbers-at-age across the full 1892–2020 catch history.
Extending age compositions outside sampled years would require a visible
age-length-key assumption. Fitted population states must not be used to invent
observed catch-at-age.

The abundance series is an aggregate Oregon Recreational Boat Survey dockside
CPUE index for 2001–2020, expressed as fish per angler-hour and standardized
from summer trips (May–September) in southern Oregon. Recreational age samples
cover 2005–2020, but the report does not show that these samples exactly match
the standardized index sample. An age-specific index constructed from them
would be approximate, and age-specific index observations could not be
reconstructed for 2001–2004. The report identifies the survey inputs as a
summer-period index; the model input archive encodes month 7, but does not
document a fractional-year conversion. Do not assume an exact survey timing
fraction without checking the Stock Synthesis convention.

Sex-specific growth, maturity-at-length and length–weight relationships are
documented. Age-specific biological surfaces can be derived from the growth
inputs and are also available in the model output. Female and male natural
mortality are estimated separately with lognormal priors; reference estimates
are 0.080 and 0.073 per year.

## Official outputs and screening decision

The archived `Report.sso` includes machine-readable numbers-at-age,
catch-at-age and F-at-age output, alongside fitted biological surfaces. The
assessment report also tabulates the ORBS index and population reference
quantities. The current OR/WA stock candidate is **new and eligible for source
curation**; this screen covers its Oregon component and does not create a
canonical stock or import numerical values.

Translation would require retaining the incomplete age-sample coverage, the
recreational CPUE index's fishery-dependent basis and approximate index-at-age
construction as explicit limitations. The source archive and report are
sufficient to continue source curation without using estimated population
states as observations.
