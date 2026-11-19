# Source manifests and transcriptions

Start with `assessment_id` in the assessment table and the matching [stock review](../source_reviews/). A `sources.csv` identifies the exact files used for curation. Look under the assessment ID. Candidate-only evidence uses an organization-prefixed candidate key. Multi-stock collections are in [shared](shared/). Sources from a distinct run or collection have their own named folder.

The first seven columns are `file`, `url`, `revision`, `retrieved_on`, `sha256`, `bytes`, `notes`. Empty fields indicate information that was unavailable or unrecorded. Additional columns preserve details such as legacy filenames, MD5 checksums, verification dates and download status. Paths are relative to the cache base identified in the stock review or importer. A `cache_folder` field gives the folder relative to `source_cache/`. When reading a previously published release, use the repository revision for that release.

Keep reviewed transcriptions with the assessment they support. The original PDFs, native files and assessment objects are cached locally under `source_cache/<stock_id>/<assessment_id>/`. For shared material, use `source_cache/shared/<collection>/`. Candidate-only material uses the script candidate key and a source collection label.

For an importer that writes a tracked manifest, load [the manifest writer](../scripts/shared/source_manifest_io.R) and use `write_source_manifest()`. The release manifests in [database/releases](../../database/releases/) identify the published SAIO tables and their checksums.
