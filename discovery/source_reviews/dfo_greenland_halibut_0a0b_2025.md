# DFO Greenland halibut, NAFO Subarea 0

## Unit and latest assessment

The DFO Sustainability Survey lists Greenland halibut in NAFO Subarea 0
(Divisions 0A and 0B). The latest full assessment identified for the shared
offshore stock is the 2025 NAFO assessment of Greenland halibut in Subareas
0+1, which provides advice for 2026–2027. The 2026 NAFO data review states
that this was the full assessment completed in 2025 and that the next full
assessment is planned for 2027. DFO's 0A/0B entry is therefore linked
provisionally to the wider 0+1 offshore assessment unit; it is not a separate
0A/0B fitted model. Inshore Cumberland Sound fisheries in Division 0B are
managed separately and must not be folded into that offshore unit.

No matching Northwest Atlantic Greenland halibut stock is in the canonical
database. NOAA's Bering Sea/Aleutian Islands Greenland turbot, DFO's 4RST and
2+3KLMNO units, and the ICES Greenland halibut areas are separate assessment
units.

## Inputs and model structure

The accepted production method is a Stochastic Surplus Production in
Continuous Time (SPiCT) model, adopted by NAFO in 2024 and used for the 2025
full assessment. It fits aggregate commercial catch and a standardized
exploitable-biomass index, not an age-structured population model.

- **Catch:** The assessment uses aggregate commercial harvest, reported in
  metric tonnes. The 2026 data review gives annual catch by area and country
  through 2025. It describes product-to-round-weight adjustments for Canadian
  catch. These are not catch numbers-at-age.
- **Survey index:** The combined assessment index is estimated with a
  delta-GAM for exploitable biomass above 35 cm fork length, combining the
  shallow survey in Divisions 1A–F and deep surveys in 0A/B and 1C/D. The
  available annual series is interrupted and the survey vessel/gear changes
  in 2022 started a new series. This is an aggregate biomass index, not an
  age-specific abundance surface.
- **Age-1 indicator:** A separate age-1 abundance index from the shallow
  Greenland Shrimp and Fish Survey in Divisions 1A–F is shown for 1991–2025,
  with no survey in 2021 and a gear-calibration factor for 1988–2004. It is a
  recruitment indicator, not a catch-at-age series or a population-at-age
  likelihood in the SPiCT assessment. Its area also extends beyond the DFO
  Subarea 0 inventory label.
- **Weights, maturity and mortality:** The detailed reports show supporting
  growth curves and historical length-at-maturity information, but these are
  not run-matched age-specific biological inputs to the production model.
  SPiCT does not require an age-specific natural-mortality surface, and the
  reviewed reports do not specify an age-structured mortality process.
- **Timing:** A within-year survey fraction is not part of the reviewed
  aggregate production-model input description.

## Reported outputs and screening

The 2025 assessment reports aggregate biomass and fishing-mortality status
relative to reference points, with uncertainty intervals, and catch
projections. It does not report fitted N-at-age or F-at-age population
surfaces. The age-1 survey index is an observed indicator, not an estimated
population recruitment trajectory. The 2025 advice gives 2024 B/Bmsy = 1.20
and F/Fmsy = 0.91.

This unit is screened **ineligible for the age-disaggregated candidate set**:
the current production model uses aggregate catch and biomass observations,
and the single-age recruitment indicator does not make it an age-structured
assessment. NAFO reports ongoing otolith ageing to support future age-based
models, so this is not a claim that age data will remain unavailable. The
screen does not rule out curating its aggregate assessment data under a
broader database scope.

## Sources and cache

- DFO, [Greenland Halibut (Turbot) in NAFO Subarea 0 (Divisions 0A and 0B)](https://www.dfo-mpo.gc.ca/fisheries-peches/commercial-commerciale/atl-arc/0a0b-eng.html), inventory identity and fishery notices.
- Hedges and Christiansen (2026), [Data available for the Greenland Halibut Stock Component in NAFO Subarea 0 + 1 (offshore)](https://www.nafo.int/Portals/0/PDFs/sc/2026/scr26-029.pdf), current data coverage, survey indicators, biological information, and assessment timing.
- NAFO (2025), [Scientific Council Report, SCS Doc. 25/13](https://www.nafo.int/Portals/0/PDFs/sc/2025/scs25-13.pdf), 2025 assessment and advice.
- Nogueira and Hedges (2024), [Assessment of the Greenland Halibut Stock Component in NAFO Subarea 0 + 1 (Offshore), SCR Doc. 24/022REV](https://www.nafo.int/Portals/0/PDFs/sc/2024/scr24-022REV.pdf), assessment method and data sources.
- NAFO, [2025 advice for Greenland halibut in Subarea 0+1 offshore](https://www.nafo.int/Portals/0/PDFs/Advice/2025/ghl01off.pdf).

The four PDFs are cached under
`source_cache/discovery_dfo_greenland_halibut_0a0b_2025/`; `sources.csv`
records retrieval dates, URLs and SHA-256 checksums. No canonical assessment,
input or output records were added.
