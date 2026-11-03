# Sources

Every claim in this project points to a document. This page is the index of the document set.

## Primary documents

| Document | URL | Local copy | Notes |
|---|---|---|---|
| SAC Constitution (2008) | https://archive.org/details/sac-constitution | `research/notes/SAC_Constitution_djvu.txt` | approved by the 19th Senate, 11 Feb 2008 |
| SGB Constitution (2024) | https://archive.org/details/sgb-constitution | `research/notes/SGB_Constitution_djvu.txt` | "Replaced SAC in 2024" |
| Senate minutes index | https://nitc.ac.in/minutes-and-reports/senate-minutes | `research/senate/` (ignored) | 46–106; 104–106 partly broken |
| Board of Governors minutes | https://nitc.ac.in/minutes-and-reports | `research/bog/` (ignored) | 65–71 |
| 93rd Senate minutes, S93.3.3 | Senate index | `research/notes/senate-93-excerpt.txt` | the eight amendments, 17 Jul 2023 |
| Fosscell comparison | https://wiki.fosscell.org/SAC_To_SGB_Transition | `research/notes/wiki_transition.txt` | CC BY-SA; attribution required |

## Corroborating reporting

| Outlet | Use |
|---|---|
| Onmanorama | Dean (P&D) post, case, appointment |
| Mathrubhumi | same |
| Times Now | same |
| The News Minute | same |

These are corroboration, not the primary source. The decks say "four outlets reported" where the claim rests on reporting.

## What is not a source

- screenshots without a chain of custody,
- WhatsApp forwards,
- another post in this project,
- an AI summary,
- "everyone knows".

## How to add a source

1. Add a row to `analysis/<topic>/sources.yml`:

   ```yaml
   - id: sac-2008
     title: "SAC Constitution (2008)"
     url: "https://archive.org/details/sac-constitution"
     local: "research/notes/SAC_Constitution_djvu.txt"
     retrieved: 2026-11-03
     licence: "public document; quoted for criticism and review"
   ```

2. Add the claim row in `analysis/<topic>/claims.yml`, with the locator.
3. Archive the URL (Wayback Machine) and record the archive link.
4. Add the source to the deck's `sources.wiki` and the last panel.

## Known gaps

Be honest about these; they are part of the record.

- **Senate 104–106**: `104.pdf`–`106.pdf` were HTML error pages. `104b.pdf` downloaded but its text extraction is garbled. Analysis is reliable through the 103rd meeting (17 Nov 2025).
- **Senate 88–89**: broken font encoding; attendance lists are unreadable and excluded.
- **93rd minutes, Annexure IV**: the revised report is unpublished. The claim is limited to "the recorded approval covers eight amendments".
- **2 Nov 2026 minutes**: supplied by an editor, not in the repository. The deck paraphrases and uses no quotation marks.
- **Statue reply**: quoted in the source manuscript; the PDF has not been seen. The deck says "the reply said", not "the document proves".

## Privacy

The raw Senate and BoG caches contain personal data and are git-ignored. Only reviewed, non-personal excerpts belong in `research/notes/`. See `docs/privacy.md`.
