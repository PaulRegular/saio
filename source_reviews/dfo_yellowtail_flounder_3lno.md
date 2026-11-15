# DFO inventory Yellowtail Flounder - NAFO 3LNO

## Stock identity and assessment

The DFO Sustainability Survey entry refers to the single yellowtail flounder stock managed in NAFO Divisions 3LNO. NAFO identifies `Limanda ferruginea` as one stock in that area. The canonical database has no 3LNO yellowtail stock; its existing Georges Bank and Southern New England/Mid-Atlantic yellowtail records are different assessment units.

The latest detailed production assessment located is the 2025 NAFO assessment, using data through 2024. The 2025 advice applies for 2026-2027. The model is a Bayesian Schaefer surplus-production model, not an age-structured population model.

## Inputs and assumptions

- **Catch:** The assessment model uses nominal catch in thousands of tonnes from 1965-2024. The report provides a single annual catch series; it does not provide catch numbers-at-age.
- **Survey indices:** The assessment uses annual survey series for Canadian spring and fall surveys, the U.S. Yankee survey, the EU-Spain 3NO survey, and the Russian survey. The report provides biomass and abundance summaries, including Canadian spring (1984-2024) and fall (1990-2024) series, in modified Campelen units; missing and incomplete years are flagged. The model observation equation links survey indices to proportional exploitable biomass. No age-specific survey-abundance likelihood is used.
- **Age data:** The report states that age distribution is unavailable because the stock has not been aged since 2001. Commercial and survey length compositions are described; the assessment uses survey biomass indices and a length-based recruitment proxy rather than age compositions.
- **Biology:** Maturity-at-size and annual length-weight relationships from Canadian spring survey sampling (maturity 1984-2024) support a female SSB index. The assessment does not use weights-at-age or maturity-at-age as model inputs.
- **Mortality and timing:** The production model estimates biomass dynamics, not age-specific natural mortality or an age-specific fishing-mortality surface. It reports aggregate F/FMSY. Survey timing is identified seasonally in the series names, but the annual production model does not specify within-year observation fractions.

## Outputs

The 2025 report gives aggregate Bayesian posterior estimates and 95% credible intervals for BMSY, MSY, FMSY, carrying capacity, intrinsic growth, survey catchabilities and error parameters. For 2024 it reports B/BMSY = 1.50 (95% interval 1.13-1.93) and F/FMSY = 0.11 (0.08-0.16). It also plots an aggregate stock trajectory and a survey-based female SSB index. It does not report annual abundance-at-age, F-at-age, M-at-age, or an age-structured SSB series.

## Screening decision

The current official assessment has no catch-at-age or age-specific survey index, and its available maturity and weight information is by length. The official 3LNO identity is distinct from the yellowtail units already in the database. No canonical assessment values were added because this inventory audit records discovery and screening only.

The 2025 assessment uses modified Campelen survey units, and its table of model inputs and report provides aggregate model results. These do not supply the age-disaggregated observations and biology required by the screening criteria. The report notes aging has not occurred since 2001, which does not establish that no historical age data exist; it does establish that a current age-disaggregated assessment was not used.

## Sources

- [NAFO 2025 Assessment of Yellowtail Flounder in Divisions 3LNO, SCR Doc. 25/026](https://www.nafo.int/Portals/0/PDFs/sc/2025/scr25-026.pdf)
- [NAFO Yellowtail Flounder in Divisions 3LNO Advice, June 2025 for 2026-2027](https://www.nafo.int/Portals/0/PDFs/Advice/2025/yel3lno.pdf)
- [NAFO species and management-area description](https://www.nafo.int/Science/Science-Advice/Species)

The two PDFs and their retrieval URLs, retrieval date and SHA-256 checksums are recorded in the gitignored local cache `source_cache/discovery_dfo_yellowtail_3lno_2025/sources.csv`.
