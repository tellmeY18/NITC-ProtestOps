# Research notes

Reviewed, non-personal excerpts from public documents. This is the only part of `research/` that is committed.

## What is here

| File | Source | Notes |
|---|---|---|
| `SAC_Constitution_djvu.txt` | archive.org `sac-constitution` | OCR of the 2008 constitution; clause order preserved, page numbers not |
| `SGB_Constitution_djvu.txt` | archive.org `sgb-constitution` | OCR of the 2024 constitution |
| `senate-93-excerpt.txt` | 93rd Senate minutes, item S93.3.3 | the eight amendments; no personal data |
| `wiki_transition.txt` | wiki.fosscell.org | CC BY-SA; attribution to Fosscell and the wiki authors |

## What is not here

The raw Senate and BoG caches (`research/senate/`, `research/bog/`) contain roll numbers, phone numbers, emails and disciplinary cases. They are git-ignored and must stay local. See `docs/privacy.md`.

## Adding an excerpt

1. Quote only the clause you need.
2. Remove names, roll numbers, phone numbers, emails and case details.
3. Keep the locator (meeting number, item number, clause).
4. Add the provenance and the retrieval date to the table above.
5. Run `ruby tools/audit/sensitive_scan.rb .`.

## OCR caveats

- The OCR preserves clause order but not page numbers. Cite clauses, not pages.
- Curly quotes and dashes may be mangled. Quote the corrected reading and note the correction.
- `senate-93-excerpt.txt` is a manual excerpt, not a full OCR dump.
- Senate 88 and 89 have broken font encoding; their attendance lists are unreadable.
- Senate 104–106 are partly broken; the series is reliable through the 103rd meeting.
