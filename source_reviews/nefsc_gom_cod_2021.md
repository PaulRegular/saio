# Gulf of Maine cod, 2021 M=0.2 management-track update

## Assessment represented

This record preserves the official 2021 M=0.2 (M02) model for the legacy combined Gulf of Maine Atlantic cod management unit. The model used years 1982–2019 and ages 1–9+, with recruitment at age 1. The 2021 peer review found the update technically sufficient for status and advice. The model is marked historical and applied; the 2023 research track later replaced this combined unit with four stock units. Its data are not assigned to those successor units.

The cached NOAA 2021 assessment archive contains the report, data supplement, and M02 model supplement. The cache manifest records the retrieval URL, date, and checksums. The source tables preserve catch-at-age, NEFSC spring and fall abundance-at-age, catch weights, stock weights, fixed M, and a female maturity curve. The report provides SSB, age-1 recruitment, and fully selected F for 2012–2019 only.

## Source review

- Catch-at-age is transcribed from Data Supplement Table 8.1 in fish. It represents the assessment's total removals after commercial gear-specific discard mortality and 15% recreational release mortality.
- NEFSC spring and fall abundance-at-age are transcribed from Tables 2.6 and 2.7 in thousands of fish. They are calibrated survey estimates; they are not the underlying aggregate-index plus composition likelihood inputs. The tinyAM recipe uses them as age-specific index approximations.
- Catch weights (Table 8.2) and January 1 / stock weights (Table 8.3) are retained in kg. The assessment's stock weights were derived using the Rivard method.
- The selected M02 variant fixes M at 0.2 per year for ages 1–9+. It is not an estimated M series.
- M02 uses a female age-based maturity input represented in the supplement by Figure 1.9 as a 1982–2019 time-series average. The numeric M02 vector is not published. The database values are rounded digitizations of the female curve and are explicitly approximate.
- The assessment also used a spring MADMF survey, but its numerical age-specific observations were not recovered from the official archive. It is recorded as a source feature and omitted from the tinyAM fit.
- The report's Table 1 provides only SSB, age-1 recruitment, and fully selected F for 2012–2019. These are retained as printed, without uncertainty. The table states that terminal SSB and F are not retro-adjusted; the separate retro-adjusted 2019 estimates are not substituted. No numerical fitted N-at-age or F-at-age surface was recovered.

The model supplement reports catch CV 0.05, selectivity blocks 1982–1988, 1989–2004, and 2005–2019, survey CV reweighting of +0.2 for NEFSC spring, +0.1 for NEFSC fall and +0.3 for MADMF spring, and time-constant catchability by survey. The tinyAM approximation does not reproduce the separate source likelihoods or block-specific selectivity structure.

## Sources

- [NOAA 2021 assessment archive](https://apps-nefsc.fisheries.noaa.gov/saw/sasi_files.php?year=2021&species_id=4&stock_id=2&review_type_id=3&filename=2021_COD_GM.zip)
- [NEFSC Reference Document 22-07, peer review](https://repository.library.noaa.gov/view/noaa/39403/noaa_39403_DS1.pdf)
- [2023 Atlantic cod research track](https://www.nefmc.org/library/2023-atlantic-cod-research-track-assessment)
- [2024 peer review panel report](https://www.fisheries.noaa.gov/s3/2024-07/2024-June-Management-Track-Peer-Review-Panel-Report-508-7-18-24.pdf)
