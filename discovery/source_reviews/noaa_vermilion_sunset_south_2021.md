# Vermilion and Sunset rockfishes, Southern California — 2021

## Assessment unit and run

The 2021 production assessment covers the combined Vermilion and Sunset rockfish complex in U.S. waters south of Point Conception. The post-STAR Stock Synthesis 3.30.17 model has one area, two sexes, one annual season, ages 0–70, data through 2020, and a 2021 forecast. Its starter file identifies Vermilion_SoCA_2021.dat and Vermilion_SoCA_2021.ctl as the run inputs. The 2025 Groundfish SAFE identifies the 2021 run as the latest detailed assessment for this unit. This is the Southern California assessment area; it is not the separate northern California or Oregon/Washington assessment.

The assessment report and native post-STAR model archive are cached locally. Their URLs, retrieval date, byte counts and SHA-256 checksums are listed in provenance/noaa_vermilion_sunset_south_2021_sources.csv.

## Inputs recovered

The model archive contains 510 annual catches from seven fleets. Commercial fleets 1–3 use biomass in metric tonnes; recreational fleets 4–7 use numbers in thousands of fish. Four aggregate relative-abundance index series contribute 71 observations in total. All index observations use month 7, represented as 0.5 of the annual interval, and retain their supplied log-scale standard deviations.

The model uses 180 length-composition rows and 631 age-composition rows. The length samples use 2 cm bins from 8 cm through an open 70 cm bin. Age data include 597 conditional age-at-length records and 34 marginal age-composition records. The source sex codes, female/male joint vectors, sample sizes, partitions, ageing-error code, conditional length intervals, and signed year/fleet inclusion codes are retained. The importer uses the original .dat/.ctl inputs named by starter.ss_new; generated data.ss_new files are not treated as the original model input.

The composition vectors are not catch-at-age or age-specific abundance indices. The assessment does not supply a direct annual catch-at-age series or an age-specific index series. Weight-at-length, maturity-at-length, fecundity-at-length, growth, and the age-error vectors are documented from the model files. No maturity-at-age observation vector is supplied.

Female natural mortality is estimated as a uniform parameter of 0.13023 per year (SE 0.01198); the fitted male surface equals the female surface. The report's M-at-age output has finite age columns for ages 13–69. The scalar parameter estimate is retained separately; other ages are not reconstructed in the M-at-age output table.

## Outputs and remaining gaps

The native report supplies beginning-of-year N-at-age and biomass-at-age, fishery-specific F-at-age, finite M-at-age cells, mid-season population weight-at-age, and annual total biomass, spawning output, and recruitment. Total abundance is derived by summing beginning-of-year N-at-age across both sexes and ages 0–70, including the plus group.

SpawnBio represents egg-based spawning output in millions of eggs, not SSB. Report Tables ii and iii provide approximate 95% asymptotic intervals for spawning output, fraction unfished, and recruitment for 2011–2021; these are retained on their native scales. Age-specific uncertainty and output intervals for earlier years were not found. No SSB is derived from the age surfaces because the official spawning metric is egg-based and maturity/fecundity are length-based.

The canonical source record is partial. It preserves the principal native model observations and fitted population/mortality surfaces, but does not transcribe every diagnostic, selectivity curve, or prediction in the archive.
