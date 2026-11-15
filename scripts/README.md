# SAIO scripts

Run these commands from the repository root.

| Folder | Purpose |
|---|---|
| [database](database/) | Restore and validate releases, and import and verify official assessment records. |
| [discovery](discovery/) | Build and screen the candidate register and generate inventory summaries. |

Find the stock and assessment IDs in the database tables. Search the importers
for the assessment ID, and check the source files and supported arguments near
the top of the script before running it. A stock may have separate importers
for its assessment, inputs and outputs. The prefix in a filename identifies
a script from the curation history.

~~~sh
rg --fixed-strings -l ices_sol_27_7a_2026 scripts/database
Rscript scripts/database/003_restore_release.R path/to/release/assets
Rscript scripts/database/002_validate_database.R
~~~

See the [curation protocol](../PROTOCOL.md) for source selection, provenance
and validation of an import.

## Discovery reports

Run these from the repository root to print the current linked units or progress as CSV.

~~~sh
Rscript scripts/discovery/196_summarize_inventory_units.R
Rscript scripts/discovery/195_summarize_discovery.R
~~~

Both commands derive their reports from the candidate register. The cached Stock SMART inventory supplies NOAA science centres when present. The database importers record screening and import updates in the candidate register.
