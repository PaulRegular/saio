# B.C. coastwide Sablefish

## Identity and assessment run

The DFO Pacific inventory entry is the British Columbia coastwide Sablefish
unit (*Anoplopoma fimbria*). No canonical record exists. The NOAA West Coast
and Alaska Sablefish entries are separate U.S. management units, not aliases
for this DFO unit. The inventory supplies no official assessment code, so none
is assigned here.

The latest management advice located is the 2025–26 application of the
Sablefish management procedure. That procedure uses an aggregate state-space
production model to estimate biomass for catch advice. It is not a new
age-structured assessment. The latest detailed age-structured operating model
is the 2022 update, fitted to data through 2021 and reviewed in DFO Science
Advisory Report 2023/010. Its detailed methods and outputs are in Research
Document 2024/072, published in 2025. The report represents an operating model
within the stock's management-strategy-evaluation process, rather than a new
annual age-structured fit.

## Inputs and assumptions in the 2022 operating model

- Retained catches are reported by trap, longline-hook, and trawl gear in
  tonnes for 1965–2021. At-sea releases are included by gear from 1996/2006
  onward, with different coverage by gear. These are biomass observations,
  not catch numbers-at-age.
- Age-composition likelihoods are separate from the catch likelihood. The
  model uses trap-fishery age samples from 1982–2016 with missing years,
  standardized-survey ages from 1990–2009, and stratified-random trap survey
  (StRS) ages from 2003–2014. The longline-hook and trawl fisheries have no
  age-composition data; the trawl model instead uses length compositions.
  Published commercial age compositions are shown as figures, and the raw
  numeric trap-fishery composition arrays were not located.
- Total-biomass indices include trap CPUE (1979–2009), the standardized trap
  survey (1990–2009), and StRS (2003–2021). The 2022 report uses timing
  fractions 0.5 for trap CPUE and 0.75 for the October–November surveys.
- Sex-specific length-at-age, weight-at-age, and maturity-at-age are fixed
  biological inputs carried forward from the 2016/2019 model cycle. Research
  Document 2023/023 documents the earlier operating-model biology. The 2026
  technical report updates life-history analyses through 2024; those newer
  estimates must not be substituted for the 2022 fit without evidence that
  the production model adopted them.
- Male and female natural mortality are estimated independently with the
  same Normal prior, mean 0.1 and standard deviation 0.1 per year.

## Public data and outputs recovered

DFO's Open Data StRS archive includes effort, catch, and biological sample
records. The English data bundle was cached locally. In the current snapshot,
Sablefish biological rows have non-missing ages for every survey year from
2003 through 2021, as well as later years. The Open Data page reports temporal
coverage through 2022, while the retrieved English CSV bundle contains rows
through 2025. Preserve that metadata/data discrepancy and use only the
model-matched years for this assessment. The 2022 fit uses StRS age
compositions only through 2014, so any extraction for that fit must use the
model-matched period and definitions. Survey years after 2021 are not part of
the 2022 operating-model run.

The 2024/072 document reports posterior spawning-biomass and age-1 recruitment
time series, reference points, mortality estimates, and model fits. Numeric
annual N-at-age or F-at-age output matrices and a fitted model object were not
found in the reviewed public sources. The 2026 biology report contains updated
age-composition and life-history analyses, not the model-matched 2022 input
matrices. Its official PDF was accessible through the publication viewer but
the local download endpoint returned archived HTML; this is recorded in the
local source manifest.

## Screening decision

Identity and source review are complete, but age-based import eligibility is
unresolved. The StRS age observations and model-matched survey indices provide
a useful recoverable stream. However, the complete commercial catch-at-age
input cannot be reconstructed from the public numeric sources located: catch
totals are available, but commercial trap age proportions are graphical, and
hook/trawl age compositions are not fitted. The 2022 report provides
aggregate population outputs but not numeric age-specific fitted surfaces.
Do not infer missing age allocations from fitted states or the later data
release. Continue looking for run-matched commercial sample arrays or model
files before import.

## Sources and cache

The local, gitignored source cache is
`source_cache/dfo_bc_sablefish_20261029/`; its
`sources.csv` records URLs, retrieval date, file sizes, and SHA-256 checksums.
It contains the 2022 Science Advisory Report, the 2024/072 research document,
the 2025/018 management-procedure science response, the 2025/013 age-sampling
response, the 2016 operating-model research document, and the DFO Open Data
StRS bundle, index, dictionary, and reference information.

- [2022 operating-model Science Advisory Report 2023/010](https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41102587.pdf)
- [Detailed 2022 operating-model Research Document 2024/072](https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41279281.pdf)
- [2025–26 management-procedure Science Response 2025/018](https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41293903.pdf)
- [Age-sampling Science Response 2025/013](https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41316149.pdf)
- [2016 operating-model Research Document 2023/023](https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41110961.pdf)
- [DFO Offshore Stratified Random Trap Survey Open Data](https://open.canada.ca/data/en/dataset/813ff561-b38d-4241-b370-0a17c60976af)
- [2025 biological data and life-history report](https://publications.gc.ca/site/eng/9.961676/publication.html)
- [2026 Pacific Groundfish IFMP](https://www.pac.dfo-mpo.gc.ca/fm-gp/mplans/ground-fond-ifmp-pgip-sm-eng.html)
