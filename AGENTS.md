# SAIO development

Write for stock assessment biologists and researchers who use RStudio and GitHub.
Lead user documentation with copyable examples for installing the package, finding
assessments and reading their data. Explain release tags and local storage in plain language.

## R package

- Document exported functions in roxygen comments using Markdown. Regenerate
  `NAMESPACE` and `man/*.Rd` with `roxygen2::roxygenise()`.
- Add focused testthat edition 3 tests under `tests/testthat/` for changes to
  package behavior. Use small offline fixtures for downloads and queries.
- Run `testthat::test_local()` and `R CMD check` before sharing package changes.
  GitHub Actions runs package checks and reports test coverage.

## Database curation

- Read the [curation protocol](data-raw/PROTOCOL.md) and
  [data dictionary](DATABASE_STRUCTURE.md) before editing source records.
  Preserve source units, dimensions, provenance and completeness statuses.
- Use [the curation guide](data-raw/) to locate importers, source reviews,
  manifests and validation checks. Keep original source files under the ignored
  `source_cache/`. Run the database validator and affected source checks from
  the repository root with the existing working tables and caches.
- Keep curation independent of downstream modelling software. Keep model
  comparisons, translation instructions and project history in the consuming project.
- Maintain one release line on `main`. For a validated milestone, commit the
  reviewed importers, source manifests, correction notes, tests and release manifest.
  Build the five consolidated tables locally and publish them as compressed release assets.
  Follow [Batch commits and snapshots](data-raw/PROTOCOL.md#batch-commits-and-snapshots).
  Publish or push only with authorization.
