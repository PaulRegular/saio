# Assumptions CSV encoding correction

The Icelandic plaice age-table import at cbc6e4e rewrote the existing
assumptions table. The pre-Yellowtail portion of 4949e97 matches the
assumptions LFS checksum at cbc6e4e, which dates the damage to the plaice
rewrite. The same Windows R rewrite under the C locale reproduces the
byte sequences. An en dash becomes 62 00 13, and a multiplication
sign becomes 43 17.

The correction restores 223 en dashes and three multiplication signs in
157 records. The November 11 Gulf red snapper staging archive confirms
143 of those records. The China rockfish and WCPO yellowfin importers
(670_import_noaa_china_rockfish_2015.R and
671_import_noaa_wcpfc_yellowfin_2026.R) confirm the other 14. The
archive also confirms 14 white hake source references whose section
signs were changed to B' by the same conversion.

The repair preserves row order, assessment IDs, units, and table
structure. The Icelandic plaice importer now checks the locale before
rewriting tables, and structural validation rejects embedded NULs in the
stock, assessment, and assumptions tables.
