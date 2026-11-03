# BSAI Alaska skate (NOAA:10736)

**Review date:** 2026-10-31

**Scientific name:** *Bathyraja parmifera*

**Assessment unit:** Bering Sea and Aleutian Islands, Tier 3 Alaska skate component
**Assessment used for advice:** 2023 operational update, Stock Synthesis Model 14.2d

## Unit and assessment identity

NOAA Stock SMART identifies Alaska skate in the Bering Sea/Aleutian Islands.
The 2023 SAFE treats it as a Tier 3 component of the BSAI skate complex. The
Other Skates Tier 5 complex is assessed separately. The NOAA Stock SMART Gulf
of Alaska Skate Complex (NOAA:11005) is a different geographic entry and is
not matched to Alaska skate.

Model 14.2d is the 2023 operational update recommended for the 2024 harvest
specifications. The 2024 SAFE document is a harvest projection using that
assessment. Model alternatives discussed in 2025 were proposed alternatives,
not a newly accepted production assessment. The June 2026 NPFMC review plan
scheduled the final BSAI skates assessment for December 2026, after this review
date, so the current 2026 model files are not treated as final accepted results.

The archived 2023 Stock Synthesis input file is under the repository's
`2023/Tier3/Model_Runs/M14_2_update` directory and sets `_EndYr=2023`; its
header comment still says “new data thru 2020.” The official SAFE report names
Model 14.2d as the recommended model, and the matching 2023 output tables are
provided alongside the input. The stale comment is a provenance caveat, not a
basis for silently changing the run identity.

## Inputs and age-data screen

| Input | Verified source information | Age-disaggregated status |
|---|---|---|
| Fishery catch | Reconstructed annual aggregate catch by longline and trawl, with catch-accounting estimates. The SS3 fleets use biomass catch units. | No catch-at-age or fishery age-composition observations. |
| Survey | EBS shelf survey biomass index and survey length compositions; observations are recorded in July in the one-season SS3 model. | No survey age composition or age-specific abundance index in the production likelihood. |
| Paired length and age | Survey length-at-age samples in 2003, 2007–2009, and 2015, used to estimate growth. The report says there are no fishery ages and no new survey age data since the prior full assessment. | Sparse growth observations only; they do not provide population age compositions or an age-specific abundance index. |
| Weight | Combined-sex length-weight relationship, weight in kg and total length in cm: `W = 9.0e-6 * TL^2.9617`. | No observed weight-at-age vector; deriving one would require the fitted growth curve. |
| Maturity | Length-based maturity ogive with `L50 = 93.28 cm` total length and slope `-0.548`. | No observed maturity-at-age vector; deriving one would require the fitted growth curve. |
| Natural mortality | Fixed at `M = 0.13` per year for Alaska skate. The separate Other Skates Tier 5 model uses `M = 0.10`. | Fixed scalar assumption, not an estimated M-at-age series. |

The assessment is explicitly age- and size-structured, but its observations
are aggregate catch, survey biomass and length compositions. The few paired
survey length-at-age observations inform the growth curve. An age-structured
model and its fitted age-specific population outputs do not establish that
age-disaggregated observations were used.

## Reported outputs

The 2023 Model 14.2d output archive includes annual N-at-age columns 0–25
(age 25 is the accumulator group) over 1948–2028. The CSV does not state the
N-at-age unit, and years after the 2023 terminal data year are projected rather
than historical fitted years. The SAFE reports
total and spawning biomass in metric tonnes, age-0 recruitment in thousands
of fish with CV, and exploitation as catch divided by total biomass. The
archived output tables and report do not provide a comparable F-at-age or
M-at-age summary table. These fitted population outputs remain useful for a
future comparison if the age-input eligibility policy changes, but they do
not supply the missing age-disaggregated observations.

## Screening decision

This is a **new, screened, ineligible candidate** for the age-disaggregated
source set. The completed 2023 assessment does not use catch-at-age, fishery
age compositions, survey age compositions or an age-specific abundance index.
Its sparse survey length-at-age samples are used for growth, not as population
age-composition observations. No canonical stock, assessment, input or output
records were added was attempted.

The reviewed source files are cached locally in the gitignored directory
`source_cache/discovery_noaa_bsai_alaska_skate_2026/`; `sources.csv` records
the URLs, retrieval date, pinned AFSC revision where available, sizes and
SHA-256 checksums.

## Sources

- [2023 BSAI Skates SAFE, Model 14.2d](https://apps-afsc.fisheries.noaa.gov/Plan_Team/2023/BSAIskate.pdf)
- [AFSC 2023 Model 14.2d input and output repository](https://github.com/afsc-assessments/AFSC_BSAI_SKATE_Assessment/tree/main/2023/Tier3)
- [2024 BSAI SAFE introduction and harvest projection](https://www.npfmc.org/wp-content/PDFdocuments/SAFE/2024/BSAIintro.pdf)
- [2025 BSAI skates Plan Team assessment alternatives](https://meetings.npfmc.org/CommentReview/DownloadFile?fileName=2025_BSAIskates_SeptPT.pdf&p=018bc1f8-77d9-4e80-b825-2213af5f0d08.pdf)
- [June 2026 SSC review schedule](https://meetings.npfmc.org/CommentReview/DownloadFile?fileName=F+2026+Groundfish+Stock+Assessment+SSC+Review.pdf&p=2aa31081-76e1-4025-af01-e17fd99ba0d6.pdf)
