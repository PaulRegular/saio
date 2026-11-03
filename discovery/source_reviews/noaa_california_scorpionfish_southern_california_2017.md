# NOAA California Scorpionfish: Southern California

## Stock identity and latest assessment

NOAA Stock SMART ID 10461 is the California scorpionfish (*Scorpaena guttata*) assessment unit south of Point Conception (34°27′ N) to the U.S.–Mexico border. No matching stock unit or assessment was found in the canonical database. The 2017 benchmark assessment is the latest full model located, with assessment data through 2016. The July 2025 Groundfish SAFE continues to report the stock using the 2017 assessment; newer catch and management documents do not provide a new fitted assessment. The official report, native Stock Synthesis archive and SAFE are cached locally under `source_cache/discovery_noaa_california_scorpionfish_2017/`. Its ignored `sources.csv` records retrieval details and SHA-256 checksums.

## Inputs and assumptions

The native Stock Synthesis 3.30.05.03 archive contains biomass catches for six commercial and recreational fleets, with historical catch beginning in 1916 and data through 2016. The 2017 report gives 2016 landings of 74 metric tonnes. Fishery composition inputs are length compositions; the archive contains no fishery catch-at-age observations or fishery age compositions.

The age observations are conditional age-at-length (CAAL) samples from the NWFSC bottom-trawl survey in 2005–2016, represented by sex and length bins. The model's internal age grid and reported age outputs span ages 0–21, with age 21 as the plus group. Survey biomass indices and length compositions are available for the NWFSC survey; the archive also includes the Southern California Bight trawl survey and other relative-abundance series. Index and CAAL observations are recorded in July (month 7; model year fraction 0.5).

The archive can support documented age-index reconstructions over the overlapping years by combining the NWFSC CAAL samples with its length compositions and biomass index. A catch-at-age reconstruction would require applying an age-length key estimated from survey fish to fishery length compositions and scaling by fleet catches. That is not a direct observation and assumes the survey age-length relationship represents fishery catches. Coverage and sex aggregation would need to be checked before importing the reconstructed series; no age-composition likelihood is available for the fisheries themselves.

The model derives age-specific weights from sex-specific growth and length-weight relationships, and maturity from a length-based logistic schedule. These are biological functions, not supplied independent age-specific vectors. Natural mortality is fixed at 0.235 per year for both sexes in the base model. The assessment also evaluates a lower-M state of nature (0.164); this is a sensitivity model, not the base-case M estimate.

## Outputs and screening decision

The official report and native `Report.sso` provide spawning biomass/output, recruitment, depletion, and model-derived numbers-at-age, catch-at-age and Z-at-age. With base M fixed at 0.235, F-at-age can be derived as Z minus M. These fitted age surfaces are outputs, not observed catch-at-age inputs.

Screening decision: provisionally new and eligible for source curation with explicit, limited reconstructions. Unlike an assessment with length compositions alone, this run has observed CAAL data that can be combined with matching length and index series. The source does not provide direct catch-at-age or an unconditional age-specific survey index. Any must identify the reconstructed series as approximate, state the survey-to-fishery age-length assumption, and restrict comparisons to the supported period; it must not treat the fitted age outputs as observations.

## References

- [2017 Status of California Scorpionfish off Southern California](https://www.pcouncil.org/documents/2017/01/status-of-california-scorpionfish-scorpaena-guttata-off-southern-california-in-2017.pdf)
- [2017 California Scorpionfish Stock Synthesis model files](https://www.pcouncil.org/documents/2017-california-scorpionfish-model-files-zip-file/)
- [Pacific Coast Groundfish SAFE, July 2025](https://www.pcouncil.org/documents/2024/08/status-of-the-pacific-coast-groundfish-fishery-stock-assessment-and-fishery-evaluation-july-2025.pdf/)
