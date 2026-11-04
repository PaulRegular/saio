# SAIO — Stock Assessment Inputs and Outputs Database

SAIO preserves publicly available inputs, model assumptions and outputs from stock assessments. Current curated coverage is finfish, with an emphasis on age-disaggregated information.

Repository: https://github.com/PaulRegular/saio

Clone this repository with Git LFS in any suitable local directory. Downloaded authoritative source files remain local and ignored by Git.

## Scope and verification

The database was constructed with substantial agentic-AI assistance. Not all records have been exhaustively human-verified. Check values, definitions and provenance against authoritative assessment sources before research use. Extraction completeness is separate from scientific verification.

## Contents

- database/: five canonical source tables; see [DATABASE_STRUCTURE.md](DATABASE_STRUCTURE.md).
- [PROTOCOL.md](PROTOCOL.md): stock selection, source recovery and validation.
- discovery/: inventories, stock-unit crosswalks and screening decisions.
- scripts/database/: reproducible importers and the canonical validator.
- source_reviews/: official source interpretation and unresolved gaps; see [review guidance](source_reviews/README.md).
- tests/: standalone source and reader checks.
- provenance/: tracked retrieval manifests.
- source_cache/: ignored local PDFs, native files and official assessment objects.

From the repository root, run:

```r
source("scripts/database/002_validate_database.R")
source("R/read_database.R")
database <- read_database()
```

The validator requires cli and checks source-table structure and consistency. Individual importers document their source-specific dependencies and expected cached files. Importers with preview controls use `--dry-run`, `SAIO_DATABASE_DRY_RUN` or `SAIO_IMPORT_DRY_RUN`; check the script for its supported control and required value (`true` or `1`). Previews parse and validate sources without updating the database or discovery register.

The inventory test checks the current register and derived summaries without rerunning screening decisions. Stock-specific source tests remain in their own files. After authorized register changes, regenerate `discovery/inventory_progress.csv` and `discovery/inventory_units.csv` with `195_summarize_discovery.R` and `196_summarize_inventory_units.R` before validating the inventory.

## Versioned source records

Git commits identify source revisions and Git LFS stores the canonical CSV contents. Record the revision used in any secondary analysis. Retrieval URLs, dates, checksums and pinned native revisions belong in source provenance. Cached authoritative files retain their original content and provenance.

## Attribution and reuse

Retain source attribution and any source-specific reuse terms. No blanket licence is assigned to third-party assessment material. Repository code retains its original attribution and GPL (>= 3) licence, preserved in [CODE_LICENSE.md](CODE_LICENSE.md).
