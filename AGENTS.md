# AGENTS.md

Instructions for AI agents working in **NITC Protest Ops**.

This file is the contract. Read it before touching anything. When a user request conflicts with this file, say so and ask — do not quietly override it.

---

## 1. What this repository is

A public, GPL-licensed toolkit for student journalists and organisers at NIT Calicut. It contains:

- scrapers and parsers for public institutional documents,
- a fact-check and claim-tracking format,
- poster / carousel / story templates,
- and three finished advocacy decks in `outputs/`.

It is **political speech about public institutions**, produced by students. It is not neutral, and it is not pretending to be. It is, however, committed to being **accurate, sourced and correctable**.

---

## 2. Hard rules (never violate)

1. **Never commit personal data.** No student names, roll numbers, phone numbers, emails, hostel rooms, disciplinary records or appeal details. The raw caches in `research/senate/` and `research/bog/` contain all of these; they are git-ignored and must stay that way.
2. **Never commit proprietary fonts.** No `.ttf`, `.otf`, `.woff`, `.woff2`, `.eot`. Helvetica Neue and DIN Condensed are licensed; use the open substitutes named in `docs/design-system.md`.
3. **Never commit** `private/`, `scan.png`, `WhatsApp Image*`, raw PDFs, HTML dumps, zips or `.DS_Store`.
4. **Never invent a source, a quotation, a date or a clause number.** If you cannot point to a file or URL, write `UNSOURCED` in the claim table and stop.
5. **Never strengthen a claim in editing.** "No paper was shown" must not become "no sanction exists." "Paraphrase" must not acquire quotation marks. "Reported" must not become "confirmed."
6. **Never add a private individual's name to a public artefact.** Public officials acting in their public role may be named. Students, complainants, and bystanders may not.
7. **Never publish a deck without running the audit.** `ruby tools/audit/sensitive_scan.rb .` must pass, and the claim table must be complete.
8. **Never rewrite history in `outputs/`.** Published decks are receipts. Corrections get a new version and a note in `outputs/<post>/CORRECTIONS.md`; do not silently edit a published slide.

If a task requires breaking one of these, stop and explain why.

---

## 3. Repository conventions

### Language and tooling

- **Ruby** (stdlib only where possible) for tools. No Bundler, no gems that need native builds.
- **Nix** for the environment. `nix develop` must be enough to run everything.
- **HTML + CSS + WeasyPrint** for rendering. No headless Chrome.
- **YAML** for briefs, claim tables and source maps.
- **Markdown** for everything human-readable.

### Layout

| Path | Purpose | Committed? |
|---|---|---|
| `tools/scrape/` | fetch public indexes and documents | yes |
| `tools/parse/` | PDF → text, attendance tables | yes |
| `tools/audit/` | PII scan, image check, claim check | yes |
| `tools/render/` | poster / carousel / story rendering | yes |
| `templates/` | starter briefs and CSS | yes |
| `analysis/` | claim → source tables | yes |
| `research/notes/` | reviewed, non-personal excerpts | yes |
| `research/senate/`, `research/bog/` | raw cache | **no** |
| `outputs/` | finished decks | yes |
| `private/` | local-only | **no** |

### Naming

- Output folders: `outputs/post-NN-slug/`.
- Slides: `NN-slug.png`, zero-padded, matching the order in `copy.md`.
- Claims: `analysis/<topic>/claims.yml`.
- Sources: `analysis/<topic>/sources.yml`.
- Dates: ISO 8601 (`2026-11-02`) everywhere except display copy.

---

## 4. Standard workflows

### Add or change a claim

1. Open `analysis/<topic>/claims.yml`.
2. Add a row with: `id`, `claim`, `source`, `locator` (page / clause / item number), `checked` (date), `strength`.
3. `strength` is one of: `verbatim`, `documented`, `reported`, `paraphrase`, `inference`, `opinion`.
4. If `strength` is `paraphrase` or weaker, the slide must not use quotation marks.
5. Run `ruby tools/audit/claims_check.rb analysis/<topic>/claims.yml`.
6. Update the deck copy and the source panel.

### Build a poster

```bash
ruby tools/render/poster.rb templates/poster/example.yml
# → outputs/_review/<slug>.png
```

The brief is YAML: `title`, `kicker`, `body`, `footer`, `palette`, `size`. See `templates/poster/example.yml`.

### Build a carousel

```bash
ruby tools/render/carousel.rb templates/carousel/example.yml
# → outputs/_review/<slug>/NN-*.png
```

### Scrape and extract

```bash
ruby tools/scrape/senate.rb --out research/senate
ruby tools/scrape/bog.rb --out research/bog
ruby tools/parse/pdftext.rb research/senate/93.pdf --out research/notes/senate-93.txt
```

Scrapers must be polite: one request at a time, a real User-Agent, a delay between requests, and no retry storms. Cache before parsing.

### Audit before commit

```bash
ruby tools/audit/sensitive_scan.rb .
ruby tools/audit/image_check.rb outputs/
ruby tools/audit/claims_check.rb analysis/**/claims.yml
```

The sensitive scan fails the build on roll-number patterns, phone numbers, emails, ignored paths that are staged, or font files.

---

## 5. Editorial rules for copy

- **Headlines may be sharp; body copy must be precise.** The design carries the anger; the sentences carry the evidence.
- **No adjectives the source does not support.** "Historic" is fine in a headline; "corrupt" needs a finding.
- **Attribute reported speech.** `According to the minutes…`, `The reply said…`, `Four outlets reported…`.
- **Date every event.** `2 Nov 2026`, not `last week`.
- **Name the document, not just the institution.** `SGB Constitution, Ch. II §11`, not `the rules`.
- **Keep the caveat.** If a document is unpublished or a page is garbled, say so in the copy or the claim table. Honesty about a gap is stronger than a confident guess.
- **Bleep profanity** as `sh*t`, per the standing rule.
- **Do not use a person's face** without consent. The design system has no photographs for this reason.

---

## 6. Design rules

- Palette: `#000000`, `#FFFFFF`, `#E10600` only.
- Type: Anton (headline), DIN Condensed (kicker/footer), Helvetica Neue (body) in the original decks; open substitutes in the templates.
- One idea per panel. One inversion per deck (white or red), used at the turn.
- Index every panel: `NN/Total`.
- No logos, no faces, no photographs, no video stills, no clip art.
- Contrast: body text must clear 4.5:1; headline text 3:1.
- Export at 1080 × 1080 for feed, 1080 × 1920 for stories.

Details: `docs/design-system.md`.

---

## 7. When you are unsure

Ask. Specifically:

- Is this person a public official acting in their public role?
- Is this document published, and can I link to it?
- Is this a verbatim quote or my summary?
- Would I be comfortable defending this sentence in front of the person it names?

If any answer is no, the claim is not ready.

---

## 8. What "done" means

A change is done when:

- [ ] the claim table row exists and has a locator,
- [ ] the copy matches the strength of the evidence,
- [ ] the source panel is updated,
- [ ] `sensitive_scan`, `image_check` and `claims_check` pass,
- [ ] the output is in `outputs/` and the contact sheet is in `outputs/_review/`,
- [ ] `CORRECTIONS.md` is updated if a published claim changed,
- [ ] the commit message says what changed and why.
