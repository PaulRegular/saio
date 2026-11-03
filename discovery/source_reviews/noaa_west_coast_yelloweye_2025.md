# NOAA West Coast Yelloweye Rockfish — 2025 assessment

## Stock and assessment

NOAA Stock SMART ID 10426 is the U.S. West Coast Yelloweye Rockfish unit. It
is distinct from the Gulf of Alaska unit (ID 10425) and the Canadian inside
and outside Yelloweye units. The 2025 update is the adopted assessment used
for advice, fitted through 2024, and is represented by the pinned Stock
Synthesis 3.30.23.2 output bundle. The model has one sex, two areas
(California and Oregon/Washington), one annual season, and ages 0-100. It
spawns in January and reports projections through 2036.

## Source inputs and transformations

- The native data file supplies annual catch observations for 1889-2024 in
  seven fishery fleets. Fleets 1-6 use biomass; fleet 7 uses numbers. The
  native number multiplier is not specified, so those catch values retain
  the native scale. The `catch_se` field is 0.01 throughout and is recorded
  as a native setting without converting its error scale.
- Eight aggregate lognormal index series are present for 1980-2024. Their
  unit codes identify number or biomass scale, but the physical multipliers
  are not stated. The observation month and `sampling_time = (month - 1)/12`
  are preserved. The source does not contain age-specific abundance indices.
- Raw length compositions contain 354 samples from 1978-2024, with 2 cm bins
  from 10 to 74 cm. Raw age compositions contain 2,213 samples from
  1978-2024 and source bins 0-65. Marginal age samples and conditional
  age-at-length samples are both retained with their length intervals, sample
  sizes, age-error codes, months, partitions, and signed fleet codes. These
  samples are not recast as annual catch-at-age or an age-specific index.
- The source control file fixes natural mortality at 0.0439034 per year; the
  report surface is constant across age, area, and year. The model uses a
  fixed length-logistic maturity schedule (first mature age 2; 50% maturity
  at 42.0705 cm) and a fitted growth curve. The available age weights are
  model-generated outputs, not observed weight-at-age inputs. No standalone
  observed maturity-at-age or weight-at-age vector was found.

## Imported data and limits

The importer records 158,992 native input rows, 30 assumptions, and 345,284
output rows. It includes area-specific beginning-of-year N-at-age,
biomass-at-age, fixed M-at-age, fleet F-at-age and fitted catch-at-age through
2036, plus model-generated weights-at-age and annual biomass, recruitment,
and spawning output. Catch-at-age is a fitted output, not an observation.

Coastwide age surfaces and annual totals are derived by summing the two model
areas. No uncertainty is calculated for these derived values. Native
area-specific outputs are retained alongside them. The 2025 coastwide
spawning-output estimate sums to 477.63 billion eggs in the pinned model
output; the assessment report rounds this to 478 and gives a 95% interval of
384-571 billion eggs in Table 20. Spawning output is not relabelled as SSB.
Age-specific uncertainty is unavailable.

The native composition likelihood cannot be treated
as a set of independent age-index observations without additional
reconstruction. No such reconstruction is included in
this database import.

## Sources and local cache

The report and native archive were retrieved on 2026-10-29 and are cached in
the ignored `source_cache/discovery_noaa_yelloweye_2025/` directory. Their
URLs, retrieval dates, sizes, and SHA-256 checksums are recorded in its
`sources.csv` manifest. The imported source files are pinned to repository
revision `9356e8267c23a1a5d33bb76f261fcd5622db062c`.

- [2025 West Coast Yelloweye Rockfish assessment report](https://www.pcouncil.org/documents/2026/01/status-of-yelloweye-rockfish-off-the-u-s-west-coast-in-2025.pdf/)
- [2025 Yelloweye Rockfish native model files](https://www.pcouncil.org/documents/yelloweye-rockfish-update-assessment-2025-model-files/)
- [Pinned PFMC model repository revision](https://github.com/pfmc-assessments/Sebastes_ruberrimus_2025/commit/9356e8267c23a1a5d33bb76f261fcd5622db062c)
