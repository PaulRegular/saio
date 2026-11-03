# Southern Gulf cod (4T–4VN) source review

For Southern Gulf cod, the 2024 Science Advisory Report is the latest official
assessment used for advice, applying the SCA model through 2023. DFO identifies
the 2019 run as the last full assessment and says the same population model was
used again in 2024. The 2019 assessment is therefore the current detailed record
in the canonical database: it is the most recent official run with recoverable
detailed inputs, assumptions, and outputs, though some of those records remain
partial. The 2024 assessment remains a separate summary-only record and is
marked as applied for advice, but not current. Its reported outputs stay under
the 2024 assessment ID; no 2019 observations or estimated outputs are copied to
the 2024 record. Structural settings are cross-referenced to the 2019 detailed
report only where the 2024 summary confirms the same population model was used.
An official DFO dataset was found for annual SSB medians and the 2.5th, 25th,
75th, and 97.5th percentiles from the assessment to 2023, in thousands of
tonnes. Its [SSB CSV](https://api-proxy.edh-cde.dfo-mpo.gc.ca/catalogue/records/fe51e3da-0e0b-11ef-90aa-8b219c568296/attachments/NAFO-4T4VN-Atlantic-Cod-spawning-stock-biomass-estimates-1950-2023.csv)
and [data dictionary](https://api-proxy.edh-cde.dfo-mpo.gc.ca/catalogue/records/fe51e3da-0e0b-11ef-90aa-8b219c568296/attachments/Atlantic-Cod-biomass-estimates-data-dictionary.csv)
are cached locally; the dataset page reports an update date of 2026-04-17.
The annual series has been added as machine-readable SSB medians, with the
2.5th and 97.5th percentiles in `lwr` and `upr`; the 25th and 75th percentiles
remain in the cached CSV. The 2023 median (11.88645 kt) rounds to the report's
12 kt. However, the CSV's 2023 2.5th/97.5th percentiles (7.84041 and 16.53004
kt) differ from the report's stated 95% interval (10.5–21.6 kt). No conversion
or reconciliation is assumed; the database uses the consistent percentile
series and records the report discrepancy in the 2023 output note.

The detailed 2019 SCA assessment remains as a historical record under the 2012
framework. It contains 54 annual stock-catch values for 1965-2018
(tonnes), plus 480 source-reported landed numbers-at-age values for 1971-2018
(ages 3-12+, in thousand fish). These age counts do not recover the full fitted
catch-composition series, which the model describes as ages 2-12+. It also
retains 759 annual maturity rows carried forward between source-listed change
years. Its survey records keep the model's aggregate index separate from its
age-composition input. Both are explicitly marked reconstructions from
published age-specific source tables, and no derived age-specific abundance
series is entered. The reconstructed RV aggregate biomass series has 46 years because
weights-at-age are not tabulated for 1980 and 1985; the mobile-sentinel series
covers 2003-2018; and the longline index covers 1995-2017. These inputs remain
partial because the report does not publish all original composition samples,
all RV biomass-index years, or every input over the model's 1950-2018 span. The
recorded population outputs are maximum-likelihood estimates from Tables
21-23; the report's other population summaries are generally posterior
medians. The report also states terminal estimates for M at ages 5-8 and 9+
and fully recruited q for the RV and mobile-sentinel surveys; these are stored
as grouped or time-invariant outputs with their source identified as report
text.

The DFO [4T September RV survey dataset](https://open.canada.ca/data/en/dataset/1989de32-bc5d-c696-879c-54d422438e64)
and its data dictionary were also checked and cached. The public table gives
tow-level total numbers and weights by species, not the age composition or
age-specific biological matrices used by the assessment. DFO cautions that
these catches cannot be used directly as ecological catch rates without
accounting for vessel, gear, and time-of-day effects. They therefore do not
replace the assessment's calibrated RV index or close the remaining input
gaps.

DFO's [age-estimation structures inventory](https://open.canada.ca/data/en/dataset/98913402-688c-1615-9895-ec96b214be5a)
was also checked and cached. Its 648 cod rows summarize numbers of structures
by source, year, and month (1948–2025); they do not contain individual age
readings or proportions-at-age. The portal says specimen-level age and
biological details may be available upon request, but they are not in this
public file. This inventory therefore does not recover the official run's
catch compositions or survey age compositions.

The official assessment estimates log-M random walks for ages 2–4, 5–8, and
9+. Each group's initial M level is held constant through 1971 and has a
normal prior on the natural M scale (means 0.65, 0.15, and 0.15; SD 0.05);
log-M innovations begin in 1972 and have a fixed SD of 0.075. The tinyAM
translation now includes 1971 as the free first process state, so the first
penalized change is from 1971 to 1972. The prior means are used only to
initialize the tinyAM states: tinyAM cannot apply the source's initial-M prior
or fix the innovation SD, so it estimates that SD and leaves the first M state
unpenalized. Because the direct random-walk fit was numerically unstable from
default starting values, the stock script first fits an IID-M approximation and uses
its estimates only to initialize the random-walk fit. The official assessment
reports terminal M of 0.81 for ages 5-8 and 0.85 for ages 9+.

The source models age-2 recruitment as lagged SSB times an AR1 recruitment
rate. The retained tinyAM age-3 entry follows a RW; it is not the same
stock–recruit relationship.
