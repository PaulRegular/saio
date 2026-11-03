# South Pacific albacore (NOAA:11688), 2024

## Assessment identity and current run

NOAA Stock SMART lists the South Pacific albacore stock (Thunnus alalunga,
ID 11688) with a 2024 full assessment through 2022. This is the joint
South-Pacific-wide assessment led by SPC with IATTC participation, covering
the WCPFC Convention Area and the eastern Pacific model region. It is distinct
from the North Pacific albacore unit already in the inventory. No matching
canonical South Pacific stock record was found.

The 2024 diagnostic model is publicly reproducible. The SPC repository contains
the MULTIFAN-CL model files, fitted diagnostic outputs, and TAF exports. The
diagnostic run is the reference case underlying the assessment report; the
management advice is based on an ensemble of 100 models.

## Inputs, assumptions, and outputs

The assessment does not use observed catch-at-age as a likelihood input. Its
public files contain fishery catches and catch-reweighted length compositions,
plus 654 otolith age-length observations compiled as conditional age-at-length
data. The model has 17 extraction fisheries and three index fisheries. The
length compositions span 1965–2022, while the CPUE input contains three
aggregate fishery-index series. These are not age-specific survey indices.

This would be a downstream transformation, not a recovered
native catch-at-age input or a reproduction of the MULTIFAN-CL likelihood. The age observations span 2006–2013 and ages 1–10; the diagnostic population
outputs use 12 age classes. Any reconstruction must preserve the native
fishery/time structure and state clearly how the sampled age-length
relationship is applied beyond its observed strata. The fitted MFCL
numbers-at-age must remain an output, never be used as an observation.

The assessment uses a quarterly model. The public input files retain seasonal
CPUE codes, catches, and size compositions. The report describes an updated
fork-length/weight relationship and age-specific weight surfaces derived from
estimated growth. For spawning biomass, it specifies reproductive potential
at length from sex ratio and maturity at length, converted internally to an
age surface using the growth model. This should not be relabelled as a plain
mature-proportion ogive without preserving its reproductive-potential meaning.

Diagnostic natural mortality follows an age-dependent Lorenzen relationship,
scaled to average M = 0.36 per year for mature ages 4–12+ under a maximum-age
assumption of 15. The 100-model ensemble varies average M, so ensemble
uncertainty is separate from the single diagnostic output.

The public TAF outputs include annual recruitment, biomass and spawning
biomass, numbers-at-age for ages 1–12 in two areas, and fishing
mortality-at-age through 2022. These are model outputs and are available for
comparison. The source report and files provide sufficient original quantities
for a documented, approximate age-input reconstruction, so the candidate is
eligible for source curation.

No canonical stock, assessment, input, or output rows were added.

## Sources and local cache

- [WCPFC 2024 South Pacific albacore assessment (SC20-SA-WP-02 Rev.03)](https://meetings.wcpfc.int/node/23119)
- [WCPFC background analyses and data inputs (SC20-SA-IP-05)](https://meetings.wcpfc.int/node/23128)
- [WCPFC longline size-frequency analysis (SC20-SA-IP-03)](https://meetings.wcpfc.int/node/23127)
- [SPC 2024 diagnostic model repository](https://github.com/PacificCommunity/ofp-sam-alb-2024-diagnostic/tree/e9640087a9831dece824062a338c21bf81414044)
- [NOAA Stock SMART changelog](https://noaa-edab.github.io/stocksmart/news/index.html)

The PDFs, pinned MULTIFAN-CL and TAF input/output files, retrieval dates, source
URLs, and SHA-256 checksums are cached locally under
source_cache/discovery_noaa_south_pacific_albacore_2024/. The repository files
are pinned to commit e9640087a9831dece824062a338c21bf81414044.
