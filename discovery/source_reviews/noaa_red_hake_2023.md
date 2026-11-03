# NOAA red hake, northern and southern stocks, 2023

## Screen result

NOAA Stock SMART IDs 10516 (Gulf of Maine/northern Georges Bank) and 10517
(southern Georges Bank/Mid-Atlantic) are separate management units of
*Urophycis chuss*. The canonical database has no matching red hake stock or
assessment record, so these are new candidate units rather than aliases or
duplicates.

Both units are screened **ineligible for the age-disaggregated set**. NOAA
lists the latest accepted production assessments as the 2023 operational
updates, with model type “Empirical Approach.” The reports update catch and
survey biomass data through 2022 using a chain-sweep catchability study to
estimate swept-area biomass and catch-to-biomass exploitation rates. The
assessment provides spring and fall survey biomass indices and length
frequencies, but not a multi-age population assessment with catch-at-age,
age-specific survey abundance, N-at-age, F-at-age, recruitment, or SSB.

The 2023 management-track peer-review panel concluded that these updates met
the review requirements and represented the best scientific information
available. It also stated that annual fishing mortality, recruitment and stock
biomass were not estimated by the method. The reports do give annual
swept-area biomass, catch, exploitation-rate estimates, and survey biomass
indices. Those reported quantities should not be relabeled as SSB, F-at-age,
or N-at-age. The current method is therefore not suitable for the planned
age-structured comparison even though it reports abundance-related biomass.

The reports mention that mean length and weight at age have changed over time,
and the assessment materials include length-frequency plots. This indicates
biological age information may exist in supporting research data, but it does
not establish a current age-structured observation likelihood or the
age-specific population outputs required here. The assessment oversight
record likewise describes the method as empirical and focused on survey
biomass and catch. These units are excluded based on the latest production
assessment, not on a claim that red hake have never been assessed with
age-structured methods. Earlier AIM/index assessments are historical and are
not substituted for the current 2023 production method.

## Assessment data and output coverage

The northern update reports annual catch components (commercial landings,
commercial discards and recreational catch) in metric tonnes, estimated
swept-area biomass in metric tonnes, and exploitation rate as catch divided by
biomass in percent. It combines the fall survey index from year *t* with the
spring index from *t* + 1 to form a continuous annual biomass series. The
assessment uses spring and fall NEFSC bottom-trawl survey biomass indices in
kg/tow; approximate 90% lognormal confidence intervals are shown. The report
notes the 2020 survey observations were missing but the combined series had no
break.

The southern update reports the same kinds of aggregate catch, swept-area
biomass and exploitation-rate outputs, plus spring and fall NEFSC survey
biomass indices. The review identifies uncertainty in the southern stock's
small footprint relative to the survey area and the interpretation of its
declining biomass. Neither assessment estimates maturity-at-age, weight-at-age
as a model input, natural mortality, or within-year survey timing for a
multi-age population model.

Stock SMART's older 2017 records use an AIM model, but the 2023 assessment is
the latest accepted production update. The 2023 reports state they continue the
empirical method used in the 2020 updates. Accordingly, the historical AIM
results are not treated as current outputs for this screening audit.

## Source cache

The two NOAA assessment reports and the 2023 peer-review panel report are
cached locally under the ignored directory
`source_cache/discovery_noaa_red_hake_2023/`. Retrieval URLs, date, revision
notes and SHA-256 checksums are in its `sources.csv` manifest. No assessment
data have been imported into the canonical database.

## Sources

- [Northern red hake 2023 Management Track Assessment](https://apps-st.fisheries.noaa.gov/sis/docServlet?fileAction=download&fileId=9037), compiled October 17, 2023; data through 2022.
- [Southern red hake 2023 Management Track Assessment](https://apps-st.fisheries.noaa.gov/sis/docServlet?fileAction=download&fileId=9038), compiled October 17, 2023; data through 2022.
- [September 2023 Management Track Peer Review Panel Report](https://repository.library.noaa.gov/view/noaa/70900), NOAA Technical Memorandum NMFS-NE-313.
- [NOAA Stock SMART](https://apps-st.fisheries.noaa.gov/stocksmart/?app=browse_by_stock&stockid=10516), northern stock record.
- [NOAA Stock SMART](https://apps-st.fisheries.noaa.gov/stocksmart/?app=browse_by_stock&stockid=10517), southern stock record.
