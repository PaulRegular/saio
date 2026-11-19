
# SAIO processing scripts

Run these commands from the SAIO root. Start with the stock ID in the stock
table. Its folder contains the scripts used to screen sources, import records
and check values for that unit. The filenames retain their original script
numbers and identify the operation or the assessment run. Cases still under
review use the organization-prefixed candidate key.

For example, the Northern Gulf cod stock has [these scripts](dfo_cod_3pn4rs/)
and a [source review](../source_reviews/dfo_cod_3pn4rs.md). The review and
assessment table identify the official run, and the assessment ID identifies
its source manifest. The local cache uses the same stock ID as the
script folder, followed by the assessment ID.

[Shared scripts](shared/) handle inventories, multi-stock sources and helpers.
The two commands at this level restore and check the five published tables.

~~~sh
Rscript data-raw/scripts/003_restore_release.R path/to/release/assets
Rscript data-raw/scripts/002_validate_database.R
~~~

See the [curation protocol](../PROTOCOL.md) for source selection, provenance
and validation. Check each script's inputs and arguments before running it.

## Candidate summaries

Print the register overview and linked stock units as CSV from the SAIO root.

~~~sh
Rscript data-raw/scripts/shared/195_summarize_candidates.R
Rscript data-raw/scripts/shared/196_summarize_inventory_units.R
~~~

Both commands read the [candidate register](../../database/candidates.csv). The
cached Stock SMART inventory supplies NOAA science centres when present.
