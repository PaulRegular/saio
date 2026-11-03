# Western and Central Pacific yellowfin tuna (NOAA:11694)

**Reviewed:** 2026-11-02
**Inventory row:** NOAA:11694
**Assessment unit:** WCPFC Western and Central Pacific yellowfin tuna (*Thunnus albacares*)
**Screen:** Eligible for source curation, with an approximate age-reconstruction caveat. No canonical database records were added.

## Identity and assessment status

NOAA Stock SMART ID 11694 identifies the Western and Central Pacific yellowfin unit. Its latest Stock SMART row is assessment 13365 (2023, data through 2021; PIFSC), marked Full acceptance. It is distinct from yellowfin units in the Eastern Pacific and Indian Ocean. No matching canonical stock is present; this inventory row is linked as `wcpfc_wcpo_yellowfin`.

The latest detailed production run located is the 2026 WCPFC assessment, with data through 2024. Its revised report says it was **not reviewed at SC22 for management advice** and review was deferred to SC23. WCPFC's SC22 outcome notice confirms the deferral. The 2023 Stock SMART assessment therefore remains the latest accepted advice basis; this review uses the 2026 files to identify the most recent detailed inputs and outputs, while preserving that status distinction.

The assessment uses quarterly time steps, five model areas, and 40 quarterly age classes (the final age class is a plus group). The age index must not be interpreted as 40 annual ages.

## Inputs and outputs located

- **Catch and size data:** The pinned MFCL and TAF source package contains catch and length-composition inputs. The TAF length-composition table has 297,920 rows spanning 1956–2024, 36 fisheries and four quarters. These are length compositions, not catch-at-age observations.
- **Age data:** The TAF otolith table contains 1,873 individual conditional age-at-length records, sampled in 17 years from 2006–2024 across five areas, four quarters, ages 1–40, and lengths 14–174 cm. These data inform growth; they are not marginal age compositions. Pairing sampled age-length keys with length compositions can support approximate age-composition reconstruction in overlapping strata. Extending keys to unsampled years, fleets or areas requires explicit pooling and must be labelled as reconstruction.
- **Abundance indices:** Five regional longline CPUE series cover 1952–2024 at quarterly resolution. They are aggregate relative-abundance indices, not age-specific indices.
- **Biology and mortality:** The fitted TAF biology output contains length, weight, maturity and natural mortality for ages 1–40. These are model-derived surfaces, not independent observed annual weight-at-age or maturity-at-age series. The report describes an internally estimated age-dependent natural-mortality form.
- **Outputs:** Pinned TAF results provide numbers-at-age by year, quarter and area (1952–2024), annual fishing mortality-at-age, biology at age, and annual summaries including recruitment, biomass and F. The shortcut TAF output script copies archived full-model outputs; these are diagnostic fit outputs, not uncertainty-grid summaries.

## Screen decision

**Eligible for source curation.** The detailed run provides the age-length observations, length compositions, aggregate CPUE, biological surfaces and age-specific fitted outputs needed to assess a documented approximation. Catch-at-age is not a direct likelihood input: any age-composition reconstruction must retain the sampled-strata limits and visible pooling assumptions. The assessment's 2026 advice review is pending at SC23, so the outputs must not be presented as already adopted management advice.

This is a discovery screen only.

## Sources and cache

The gitignored local cache is `source_cache/discovery_noaa_wcpo_yellowfin_2026/`. Its `sources.csv` records retrieval dates, URLs, byte counts, SHA-256 hashes and the pinned SPC repository revision `b00a02f3537ef54520b219488f899188ea6eff3f`.

- [2026 WCPFC assessment report, WCPFC-SC22-2026-SA-WP05 Rev. 01](https://meetings.wcpfc.int/node/32678)
- [2026 assessment input paper, WCPFC-SC22-2026-SA-IP03 Rev. 01](https://meetings.wcpfc.int/file/21826/download)
- [WCPFC SC22 outcome notice](https://www.wcpfc.int/node/244)
- [Pinned SPC diagnostic repository](https://github.com/PacificCommunity/ofp-sam-yft-2026-diagnostic/tree/b00a02f3537ef54520b219488f899188ea6eff3f)
- [NOAA Stock SMART ID 11694](https://apps-st.fisheries.noaa.gov/stocksmart/?app=browse_by_stock&stockid=11694)
