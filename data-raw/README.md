# Curate SAIO

Start with the [curation protocol](PROTOCOL.md) and the [data dictionary](../DATABASE_STRUCTURE.md).
Use the stock ID to find its [import scripts](scripts/) and [source review](source_reviews/).
Use the assessment ID to find the [source manifest](provenance/). The
[candidate register](../database/candidates.csv) records screening decisions.

Run curation commands from the SAIO repository root.

~~~sh
Rscript data-raw/scripts/002_validate_database.R
Rscript data-raw/tests/test_source_manifest_layout.R
~~~

Run the source checks for the stocks you changed from `data-raw/tests/`.
Some checks need the local working tables in `database/` or original files
under `source_cache/<stock_id>/<assessment_id>/`. Keep shared sources under
`source_cache/shared/`. The source cache is ignored by Git.

To populate an empty working database from verified release assets, run
`Rscript data-raw/scripts/003_restore_release.R path/to/release/assets`.
See [Batch commits and snapshots](PROTOCOL.md#batch-commits-and-snapshots)
for validation and publication steps.

The package tests run separately with `testthat::test_local()`. They use
small offline fixtures.
