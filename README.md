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
- source_cache/: ignored local PDFs, native files and fitted objects.

From the repository root, run:

```r
source("scripts/database/002_validate_database.R")
source("R/read_database.R")
database <- read_database()
```

The validator requires cli. Individual importers document their source-specific dependencies and expected cached files. Canonical validation does not fit an assessment model. Importers with preview controls use `SAIO_DATABASE_DRY_RUN` or `SAIO_IMPORT_DRY_RUN`; check the script for the required value (`true` or `1`).

## Versioned source records

Git commits identify source revisions and Git LFS stores the canonical CSV contents. Record the revision used in any secondary analysis. Retrieval URLs, dates, checksums and pinned native revisions belong in source provenance. Cached authoritative files are not rewritten to suit a downstream model.

## Attribution and reuse

Retain source attribution and any source-specific reuse terms. No blanket licence is assigned to third-party assessment material. Repository code retains its original attribution and GPL (>= 3) licence, preserved in [CODE_LICENSE.md](CODE_LICENSE.md).
