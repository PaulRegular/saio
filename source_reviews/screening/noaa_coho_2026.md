# NOAA West Coast coho candidates, 2026

## Screen result

Reviewed 18 NOAA Stock SMART units (IDs 10581–10593 and 10596–10600). Each is
listed as a 2026 operational assessment using data through 2025 with full
acceptance. The units are U.S. management populations. They are not one-to-one
matches to the DFO Interior Fraser or North Coast coho candidates, which remain
separate in the register.

These units are screened **ineligible for the multi-age assessment set**. The
current PFMC report publishes forecast adult run sizes, escapement and fishery
impacts. The joint Coho FRAM documentation describes one adult age class (age
3) and seasonal fishery accounting, rather than a fitted population surface
across multiple ages. This is not evidence that age samples do not exist.

Stock SMART's metadata require careful interpretation. All 18 entries have
assessment model labels such as “Cohort Analysis” or “Index Method.” Thirteen
have Model Category 4, four have Category 2 and one has Category 3. Sixteen
entries have Composition Input Data level 3, while IDs 10581 and 10582 have
level 0. NOAA's dictionary says these ratings describe assessment inputs used;
they do not supply the underlying observation vectors or ages. The current
Coho FRAM description says that only age-3 fish are represented. The report
and model documentation therefore do not support treating the scores as a
multi-age catch-at-age assessment.

## Current assessment and source coverage

The latest Stock SMART records are 2026 operational entries, data through
2025. The 2026 PFMC *Preseason Report I* is the current production forecast
document; the *Review of 2025 Ocean Salmon Fisheries* supplies the latest
post-season review. Report sections cover the Oregon Production Index (3.1),
Washington Coast (3.2) and Puget Sound (3.3). Depending on the stock, the
report presents adult ocean age-3 forecasts, adult returns, escapement and
fishery exploitation or mortality. The OPI hatchery total is partitioned into
components using recent proportions. These quantities are management forecasts
and fishery-accounting outputs, not annual N-at-age, F-at-age, M-at-age or SSB
surfaces from a multi-age population assessment.

The Coho FRAM documentation states that the model uses only age-3 fish, has
five within-year periods (January–June, July, August, September, and
October–December), and uses coded-wire-tag recoveries and a historical base
period to derive fishery exploitation parameters. Natural mortality is
time-period-specific but common among stocks and years. Its documented
abundance unit is January age-3 fish; common forecast outputs are ocean age-3
adult abundance. The model is used for preseason fishery planning and
postseason accounting, not as a likelihood-based multi-age population
assessment.

The model inputs, annual run records and outputs are stored in an Access
database. FRAM documentation says the supporting files are hosted in a
password-protected NWIFC area and require access from the FRAM team. No public
2026 run database or model transfer file was located. The publicly accessible
PFMC reports were reviewed instead; they report the results needed for fishery
management but not a multi-age observation set. No source data were imported
into the canonical database.

## Candidate coverage

| NOAA Stock SMART ID | Management unit | 2026 model label | Category | Composition level | Screen |
|---:|---|---|---:|---:|---|
| 10581 | Central California Coast | Cohort Analysis | 2 | 0 | Ineligible: no multi-age assessment series reported |
| 10582 | Southern Oregon/Northern California Coast | Escapement Index | 2 | 0 | Ineligible: age-3 adult management quantities only |
| 10583 | Oregon Coast Natural | Cohort Analysis | 4 | 3 | Ineligible: adult age-3 forecasts, not multi-age population surfaces |
| 10584 | Columbia River Late Hatchery | Cohort Analysis | 4 | 3 | Ineligible: component forecast from OPI total, not a multi-age assessment |
| 10585 | Columbia River Early Hatchery | Cohort Analysis | 4 | 3 | Ineligible: component forecast from OPI total, not a multi-age assessment |
| 10586 | Lower Columbia Natural | Index Method | 2 | 3 | Ineligible: adult-run forecasting, not a multi-age population assessment |
| 10587 | Willapa Bay Hatchery | Cohort Analysis | 4 | 3 | Ineligible: adult age-3 forecast and fishery accounting |
| 10588 | Grays Harbor | Cohort Analysis | 4 | 3 | Ineligible: adult-run forecast, not a multi-age population assessment |
| 10589 | Quinault Hatchery | Cohort Analysis | 2 | 3 | Ineligible: adult-run forecast, not a multi-age population assessment |
| 10590 | Queets | Cohort Analysis | 4 | 3 | Ineligible: adult-run forecast, not a multi-age population assessment |
| 10591 | Hoh | Cohort Analysis | 3 | 3 | Ineligible: adult age-3 forecast, not a multi-age population assessment |
| 10592 | Quillayute Fall | Cohort Analysis | 4 | 3 | Ineligible: adult age-3 forecast, not a multi-age population assessment |
| 10593 | Quillayute Summer Hatchery | Cohort Analysis | 4 | 3 | Ineligible: adult age-3 forecast, not a multi-age population assessment |
| 10596 | Hood Canal | Cohort Analysis | 4 | 3 | Ineligible: adult-run forecast, not a multi-age population assessment |
| 10597 | Skagit | Cohort Analysis | 4 | 3 | Ineligible: adult age-3 forecast, not a multi-age population assessment |
| 10598 | Stillaguamish | Cohort Analysis | 4 | 3 | Ineligible: adult age-3 forecast, not a multi-age population assessment |
| 10599 | Snohomish | Cohort Analysis | 4 | 3 | Ineligible: adult age-3 forecast, not a multi-age population assessment |
| 10600 | South Puget Sound Hatchery | Cohort Analysis | 4 | 3 | Ineligible: adult age-3 forecast, not a multi-age population assessment |

The same 2026 operational coho run also appears under NOAA Stock SMART IDs
11869 (Washington Coast: Strait of Juan de Fuca), 11874 (Oregon Coast
Hatchery), and 11875 (Willapa Bay Natural). All three are marked full
acceptance, use the 2025 data year, and have a Cohort Analysis model label.
The 2026 PFMC reports and Coho FRAM documentation show the same single-age-3
forecast and fishery-accounting structure. They are also ineligible for the
multi-age assessment set; Stock SMART's composition-input score is not the
underlying observation vector.

The independent NOAA stock IDs are retained as separate candidate units. Early
and late OPI hatchery forecasts, natural and hatchery populations, and separate
river or Puget Sound units remain distinct where NOAA reports them separately;
shared forecast methods do not make those units duplicates. Conversely, these
NOAA entries are not added as matches to the broader DFO coho units.

## Source cache

Authoritative source files and their SHA-256 checksums are listed in the ignored
local cache at `source_cache/discovery_noaa_coho_2026/sources.csv` (retrieved
2026-10-30). It contains the 2026 PFMC report, 2025 fisheries review, NOAA
Stock SMART data dictionary, PFMC-hosted FRAM technical documentation and the
joint FRAM documentation pages. The shared 2026 FRAM database itself was not
publicly accessible.

## Sources

- [PFMC 2026 Preseason Report I](https://www.pcouncil.org/documents/2026/03/preseason-report-1-stock-abundance-analysis-and-environmental-assessment-part-1-for-2026-ocean-salmon-fishery-regulations.pdf/), sections 3.1–3.3 and tables III-1–III-4.
- [PFMC Review of 2025 Ocean Salmon Fisheries](https://www.pcouncil.org/documents/2026/02/review-of-2025-ocean-salmon-fisheries.pdf/).
- [NOAA Stock SMART Data Dictionary](https://apps-st.fisheries.noaa.gov/stocksmart/StockSMART_DataDictionary.pdf), fields Model Category, Catch Input Data and Composition Input Data.
- [Coho FRAM Model Detail](https://framverse.github.io/fram_doc/calcs_data_coho.html).
- [Coho FRAM Applications](https://framverse.github.io/fram_doc/apps_coho.html).
- [Coho FRAM stock appendix](https://framverse.github.io/fram_doc/calcs_appendices.html).
- [FRAM file-access prerequisites](https://framverse.github.io/fram_doc/user_prereq.html).
- [PFMC FRAM technical documentation](https://www.pcouncil.org/documents/2021/05/fishery-regulation-assessment-model-fram-technical-documentation-for-chinook-and-coho-october-2008.pdf/).
