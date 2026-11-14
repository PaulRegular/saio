# Northern rockfish in the Gulf of Alaska — 2024 m24

## Stock unit and selected assessment

NOAA Stock SMART 10417 is the Western/Central Gulf of Alaska unit of northern rockfish (*Sebastes polyspinis*), distinct from the Bering Sea/Aleutian Islands unit 10416. The canonical database did not previously contain this stock.

The 2024 GOA SAFE chapter's preferred model is m24, with estimates through 2024. As of 2026-11-11, this is the latest finalized production assessment located. A 2026 update draft was posted on 2026-11-06 for the NPFMC Joint Groundfish Plan Team meeting scheduled for 2026-11-16 to 2026-11-20. It is cached for review but is not treated as a finalized assessment or mixed into the 2024 record. Recheck the current unit after that review.

The official 2025 GOA catch report and AFSC source repository support the selection of the 2024 assessment. The repository is pinned to revision `dcf94241c58ad5ccd0056bc7c50c4db338ba61d8`. Download URLs, retrieval dates, byte counts, checksums and the pinned revision are in `provenance/noaa_northern_rockfish_goa_2024/sources.csv`; local source files are in the ignored `source_cache/noaa_northern_rockfish_goa_20261111/` folder.

## Imported inputs

- **Catch:** 64 annual total commercial catch biomass values, 1961–2024, in tonnes, from Table 10-3. The table caption says “dusky rockfish,” but the surrounding Northern Rockfish chapter identifies the data as northern-rockfish catch. The 1961–1992 values exactly match the AFSC repository's GOA northern-rockfish catch file. Later values are transcribed from the report table, whose 2024 entry is through 2024-10-16. The source's foreign, joint-venture and domestic columns were not treated as independent fleets because the preferred model uses a combined catch series.
- **Fishery age composition:** 704 proportions for ages 2–45 in 16 years from 1998–2022. Values are retained as printed and are not renormalized. Model-supplied likelihood sample sizes are stored separately from the proportions and are not described as raw fish counts.
- **Fishery length composition:** 527 proportions for bins 15–45 cm in 17 years from 1991–2023. The endpoint bins include the source's pooled tails. The exact 1996 model-code sample size is 46.4495; the report rounds it to 46.5.
- **Preferred survey biomass index:** 16 VAST estimates and their source-reported natural-scale standard errors, in tonnes, for 1990–2023. The m24 model uses these values with a 0.25 likelihood weight.
- **Survey age composition:** 704 proportions for ages 2–45 in 16 years from 1990–2023. Exact m24 likelihood sample sizes and the 0.5 composition weight are preserved.
- **Biology:** Table 10-16 provides the age-specific weight schedule (g/fish) and female maturity schedule for ages 2–51. Maturity percentages are converted to proportions. The same table reports 2024 terminal abundance and model selectivity curves.
- **Likelihood settings:** annual catch weights (5 for 1961–1977; 50 for 1978–2024), fishery age and length composition weights (0.5), survey age-composition weight (0.5), and preferred VAST survey biomass weight (0.25) are recorded from the pinned m24 model script.

Composition rows are retained at the report's printed precision. Year-specific totals are within 0.006 of one. Catch-at-age numbers are not reconstructed: total catch biomass and age proportions alone do not provide the year-specific weight schedule needed for a faithful reconstruction.

Table 10-12 also reports a design-based survey biomass series. It is not imported as a second model observation because the preferred m24 fit uses the VAST series in Table 10-11. The design-based estimates remain in the local transcription for source review. Likewise, an age-specific abundance index is not separately reported; it is not inferred from aggregate biomass and age composition.

## Imported outputs

- Table 10-19 annual age-2 recruitment, total biomass and female spawning biomass for 1977–2024, reported as MCMC means with 2.5% and 97.5% bounds. The source calls these 95% confidence bounds; no standard errors are tabulated.
- Table 10-16 2024 abundance at ages 2–51 and fishery and survey selectivity at ages 2–51. A derived 2024 total abundance is the sum of the printed age-specific values; it has no uncertainty estimate.
- Table 10-18 point estimates, MCMC means, medians and 95% Bayesian credible intervals for F40, scalar M and survey q. The reported MCMC standard deviations are retained in notes, not in the standard-error column. The year represented by `spawn_bio` and `ABC` is not clear from the table, so those rows were not imported.

The assessment reports an estimated constant scalar M, not M-at-age. It does not publish full annual N-at-age or F-at-age surfaces. SSB is not recalculated from the rounded terminal N, weight and maturity rows; the official annual SSB series is available and a rounded-surface calculation would not be directly comparable to its MCMC mean.

## Assumptions and remaining gaps

The preferred model is an RTMB age-structured model with age-2 recruitment, May spawning, one estimated scalar M with a lognormal prior (mean 0.06 per year, CV 0.05), and one estimated survey q with a lognormal prior (mean 1, CV 0.45). Recruitment-process SD is fixed at 1.5. The m24 script applies a 0.1 F-regularity penalty and a recruitment-process variance weight of 1. The published model code and report do not give a fractional within-year survey timing.

The public repository references `ae_model.csv` and `saa.csv`, but those age-error and length-age matrices are not present in the pinned files. The input schedule files used to create the preferred run are also absent; the reported Table 10-16 schedules are retained with their source definition. The database record remains partial for assumptions, inputs and outputs.

## Sources

- [2024 GOA Northern Rockfish SAFE](https://files.npfmc.org/SAFE/2024/GOAnork.pdf)
- [2025 GOA catch report](https://meetings.npfmc.org/CommentReview/DownloadFile?fileName=C4+GOA+2025+Catch+Reports.pdf&p=f6b9ff85-9a04-46e3-a7ce-0c2a09b6ccee.pdf)
- [NPFMC Joint Groundfish Plan Team meeting, November 16–20, 2026](https://meetings.npfmc.org/Meeting/Details/8165)
- [Pinned AFSC GOA northern-rockfish repository](https://github.com/noaa-afsc/goa_nork/tree/dcf94241c58ad5ccd0056bc7c50c4db338ba61d8)
