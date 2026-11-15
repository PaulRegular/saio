# B.C. coastwide Bocaccio

## Identity and current assessment

DFO assesses one Bocaccio stock across British Columbia, combining PMFC areas
3CD and 5ABCDE. No canonical DFO stock row is present. NOAA's Southern Pacific
Coast Bocaccio is a separate U.S. management unit; it is not an alias for the
Canadian coastwide stock. The DFO inventory provides no stable assessment code,
so none is assigned here.

The latest advice located is the 2024 Science Response update. It reran the
Awatea model used in the 2019 full assessment and 2021 update with updated
catches and survey indices through 2023. The model remained an annual,
two-sex, age-structured catch-at-age model. The update did not use new age
compositions: the 2021 Queen Charlotte Sound age readings were rejected because
the readings were inaccurate and imprecise. The 2019 Research Document is the
most detailed source for the age-composition and biological inputs retained by
the 2024 update.

## Inputs and assumptions

- **Catch:** The model fits annual catch biomass in tonnes for two streams:
  combined bottom/midwater trawl and an “other” fishery combining several
  hook-and-line, trap and troll fisheries. The catch reconstruction runs from
  1935; the 2024 update uses reported catches through 2023. Commercial age
  frequencies are available only for the combined trawl fishery. The report
  says the other fishery has no age-composition observations.
- **Age compositions:** The 2019 fit uses five composition series: commercial
  trawl and four of the six surveys (Queen Charlotte Sound, west coast Vancouver
  Island, west coast Haida Gwaii and Hecate Strait). The 2021 update confirms
  age frequencies were available for four of six survey series. The 2024
  response's opening context says “six surveys,” but its detailed methods say
  the age frequencies were not updated; the 2019 and 2021 documents give the
  more specific account. The maximum modeled age is
  50, with older fish accumulated there. Commercial sampling years are
  intermittent (2001–2018); survey samples span 2003–2019. The report gives
  sample counts and stratum densities in tables, but displays the age
  proportions in figures rather than publishing numeric year-by-age arrays.
  The assessment adjusts several young survey-age groups for known ageing
  problems and excludes WCVI 2016 age frequencies. These adjustments are part
  of the accepted model inputs and should be preserved if the arrays are ever
  digitized.
- **Indices:** Six fishery-independent biomass series are used: QCS, WCVI,
  WCHG, Hecate Strait, the NMFS Triennial survey and the Goose Island Gully
  historical survey. Four newer synoptic observations were added in 2022/2023
  for the 2024 update. A commercial bottom-trawl CPUE series is also used but
  ends in 2012 because of fleet avoidance behaviour. Only the four synoptic
  series have age compositions. The assessment places annual indices and
  composition samples at mid-year (fraction 0.5).
- **Biology:** Sex-specific growth and length-weight relationships are
  reported in the 2019 Research Document. The model derives weight-at-age from
  these inputs. Female maturity-at-age is tabulated in Appendix D, Table D.8;
  spawning biomass tracks mature females only. The 2024 update retains the
  model's fixed biological treatment.
- **Natural mortality:** M is fixed in three component runs at 0.07, 0.08 and
  0.09 per year. The 2024 update pools 1,000 MCMC samples from each run; it
  does not estimate M.

## Outputs and source limits

The 2024 Science Response reports B2024 as 23,789 tonnes, with 5th and 95th
percentiles of 13,549 and 48,165 tonnes (Table 7). It also reports annual
spawning-biomass and age-1 recruitment trajectories in figures. Numeric annual
N-at-age and F-at-age matrices were not located. This is sufficient for a
point-estimate comparison of terminal SSB, but not for age-specific output
comparisons from the official run.

The 2019 report contains detailed catch, survey and biological appendices, but
not machine-readable stock-specific input arrays. The public PBSawatea
repository was inspected at commit
[`57e8e9775bf9fdd8b965a07ba434f3fc40675c93`](https://github.com/pbs-software/pbs-awatea/commit/57e8e9775bf9fdd8b965a07ba434f3fc40675c93);
its tree contains no Bocaccio run files. The numeric age-composition values
would therefore need to be recovered from the report figures or another
run-specific source. Assigning the trawl proportions to this other catch would be an unsupported
allocation, while omitting it would leave part of the official removals
unrepresented.

## Screening decision

Identity and source review are complete. Keep eligibility **unresolved** rather
than calling this stock either eligible or ineligible: DFO confirms that the
official model is age structured and the report provides age compositions,
biology and comparable SSB outputs, but public numeric age arrays and a
run-specific input bundle were not found, and the other-fishery removals lack
age compositions. Do not create a complete catch-at-age table by applying the
trawl composition to other-fishery catches. Reopen the screen if the exact
Awatea input files or other-fishery age data become public.

## Sources and local cache

The source documents and checksums are recorded in the gitignored local
manifest at `source_cache/dfo_bc_bocaccio_20261029/sources.csv`.

- [2024 Bocaccio update, Science Response 2024/033](https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41260284.pdf)
- [2021 Bocaccio update, Science Response 2022/001](https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41041835.pdf)
- [2019 Bocaccio assessment, Research Document 2022/001](https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41058185.pdf)
- [PBSawatea source repository](https://github.com/pbs-software/pbs-awatea)
