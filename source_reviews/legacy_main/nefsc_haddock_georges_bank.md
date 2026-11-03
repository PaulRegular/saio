# Georges Bank haddock source review

## Current official assessment

NOAA's June 2026 Management Track Peer Review Panel official the Georges Bank haddock WHAM assessment as Best Scientific Information Available. It updates the 2024 management track assessment under the 2021–2022 research track framework, with data through 2025. This is the full Georges Bank assessment, distinct from DFO's Eastern Georges Bank assessment.

The official input inventory includes US commercial landings/discards and Canadian catches, fishery catch-at-age and weights, three survey series (NEFSC fall, NEFSC spring and DFO), weight-at-age and maturity. The panel explicitly accepts excluding the spring 2023 survey and fall 2025 survey. A downloaded pre-review run must be checked against those exclusions before importing numerical results.

Official acceptance source:
https://www.fisheries.noaa.gov/s3/2026-07/june-2026-management-track-peer-review-panel-report_508_20260710.pdf

Official data portal:
https://apps-nefsc.fisheries.noaa.gov/saw/sasi.php

Public search parameters: species_id=5, stock_id=1, year=2026, review_type_id=6. Stock 8 is Eastern Georges Bank and must not be substituted.

## Cached source files

The gitignored source_cache/nefsc_haddock_georges_bank_2026 directory contains the 2026 assessment plan, peer-review report, detailed nine-page assessment report, portal HTML/search results and the official 2026_HAD_GB.zip download. The latter is a document bundle, not a native fitted-model archive. Its nested diagnostic archives contain 62 files in the principal diagnostics bundle but no RDS/RData/R/CSV/DAT files were found by filename extension. Further native-source searches are required before concluding that model files are unavailable.

Detailed report URL:
https://apps-nefsc.fisheries.noaa.gov/saw/sasi_files.php?year=2026&species_id=5&stock_id=1&review_type_id=6&info_type_id=-1&map_type_id=&filename=Georges_Bank_haddock_Update_2026_06_17_100805.801712.pdf

Bundle URL:
https://apps-nefsc.fisheries.noaa.gov/saw/sasi_files.php?year=2026&species_id=5&stock_id=1&review_type_id=6&filename=2026_HAD_GB.zip

## Numerical cross-check targets

The report gives 2025 SSB 29,037 t, Fbar (ages 5–7) 0.21 and age-1 recruitment 2,284 thousand fish, with no retrospective adjustment. These values agree with the canonical imported outputs and are checked by the validator below.

The existing candidate association to NEFSC-GARMIII_5Y_Melanogrammus_Aeglefinus denotes Gulf of Maine haddock, not Georges Bank haddock; do not carry that identity into this stock.

The scientist's official NOAA profile links to github.com/liz-brooks. Her public repository inventory and wham_devel recursive tree were cached and inspected; stock-specific 2026 Georges Bank files were not found there. Example/vignette RData objects are not official assessment objects and were not used. Search continues through the framework and other authority repositories.

## Charbonneau identity verified

The checked PLOS_2026_analysis/metadata_no_age_corection.csv has one NEFSC haddock record: NEFSC-GARMIII_5Y_Melanogrammus_Aeglefinus. Its notes explicitly identify Gulf of Maine haddock. No Georges Bank haddock record was found. The erroneous Georges Bank association has therefore been removed from the candidate seed script; this stock will be added from authoritative NOAA sources with the absence from the curated catalogue documented, rather than borrowing another stock's ID.

## Detailed framework source

The NOAA portal's 2022 Research Track search (species 5, stock 1, review type 5) provides the full assessment text and GBHaddock_Benchmark21_WHAM_BASE_Rcode.zip, both cached. The framework script reads BASE2_FORWHAM_DROPY41_2019.DAT and configures NAA_re=list(cor='2dar1', sigma='rec+1') in the base run. This establishes a framework source trail, but neither its 2019 numerical data nor its example fitted RDS references replace the 2026 official inputs. The current annual control settings still require verification.
## Initial canonical import

The 2026 assessment record now contains eight published Catch for Assessment totals (2018–2025), the constant nine-age M vector stored once, 24 historical outputs (SSB, Fbar and age-1 recruitment for 2018–2025), and 16 documented assumptions. Terminal SSB/F match the final peer-review report. Published terminal 95% intervals are retained; missing SEs and other intervals are not invented. The official process is 2DAR1 and M is fixed at 0.2, according to final TOR 3.

All three completeness statuses remain partial. This initial summary import is not a completed curation: numerical catch-at-age, survey inputs/timing, historical biological matrices, full N/F-at-age outputs and current native configuration are still outstanding. No older framework numerical data have been substituted.

## Follow-up source checks

A renewed search for the 2026 WHAM object found no current native input archive. The WHAM comparison vignette explicitly labels its 2019 Georges Bank example as very preliminary; it is not a substitute for the official 2026 run (https://timjmiller.github.io/wham/articles/ex08_compare.html). The 2026 numerical catch, SSB, recruitment and Fbar rows are now checked directly against cached report text by `scripts/database/022_validate_georges_bank_haddock.R`, together with model identity, terminal year, fixed-M representation and continued partial status. Missing survey and age-composition coverage is tested explicitly rather than concealed by historical example data.
