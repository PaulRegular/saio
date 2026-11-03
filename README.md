# SAIO — Stock Assessment Inputs and Outputs Database

SAIO preserves publicly available inputs, model assumptions and outputs from stock assessments. Current curated coverage is finfish, with an emphasis on age-disaggregated information.

## Scope and verification

The database was constructed with substantial agentic-AI assistance. Not all records have been exhaustively human-verified. Check values, definitions and provenance against authoritative assessment sources before research use. Extraction completeness and translation success are separate from scientific verification.

## Contents

- database/: five canonical source tables; see DATABASE_STRUCTURE.md.
- PROTOCOL.md: stock selection, source recovery and validation.
- discovery/: inventories, stock-unit crosswalks and screening decisions.
- scripts/database/: reproducible importers and the canonical validator.
- source_reviews/: source interpretation and unresolved gaps.
- tests/: source checks that do not require tinyAM.
- provenance/: tracked retrieval manifests copied from the local source cache.
- source_cache/: ignored local PDFs, native files and fitted objects.

Use Git LFS when cloning. From the SAIO repository root, run:

```r
source("scripts/database/002_validate_database.R")
source("R/read_database.R")
database <- read_database()
```

The validator requires cli. Individual importers document their source-specific dependencies and expected cached files. No fitting or tinyAM installation is needed for canonical validation.

## Migration and provenance

The initial snapshot is an exact copy of the canonical CSVs at tinyAM comp-assessments commit 34470212e1102f3f31bf3f08c26a8a72a985c948. migration.json records table sizes and SHA-256 hashes. Historical commits remain available in the [original repository](https://github.com/PaulRegular/tinyAM/tree/34470212e1102f3f31bf3f08c26a8a72a985c948/analysis/comp_assessments); history has not been rewritten. This repository begins with the preserved source snapshot.

The reviewed and preliminary tinyAM translations remain in tinyAM. Their governing document is analysis/comp_assessments/TINYAM_TRANSLATION.md there. The source protocol's references to that document refer to this downstream workflow.

## Attribution and reuse

Retain the source attribution and any source-specific reuse terms. This migration does not assign a new blanket licence to third-party assessment material. Code originating in tinyAM retains its original attribution; see the original repository for its licence.
