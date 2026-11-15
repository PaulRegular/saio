# Source manifests and transcriptions

Start with `assessment_id` in the assessment table and the matching [stock review](../source_reviews/). A `sources.csv` identifies the exact files used for curation. Look under the assessment, candidate or shared source collection. Supplementary sources and separately retrieved native runs can have their own subfolders.

The first seven columns are `file`, `url`, `revision`, `retrieved_on`, `sha256`, `bytes`, `notes`. Empty fields indicate information that was unavailable or unrecorded. Additional columns preserve details such as legacy filenames, MD5 checksums, verification dates and download status. Historical paths retain their recorded base. For new records, give the file path relative to the cache location identified by the review or manifest.

Keep reviewed transcriptions with the assessment they support. The original PDFs, native files and assessment objects are cached locally under `source_cache/`.

For an importer that writes a tracked manifest, load [the manifest writer](../scripts/database/source_manifest_io.R) and use `write_source_manifest()`. The release manifests in [database/releases](../database/releases/) identify the published SAIO tables and their checksums.
