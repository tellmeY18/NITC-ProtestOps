---
name: scrape-sources
description: Find and cache public NITC governance documents — Senate minutes, BoG minutes, constitutions, circulars — without copying personal data into git.
---

# Scrape sources

Use when you need a primary document and do not have it yet.

## Rules

- Public documents only. No logins, no CAPTCHAs, no paywalls, no private groups.
- Cache to `research/` (git-ignored). Never write raw scrapes into `analysis/`, `docs/` or `outputs/`.
- One request at a time, a descriptive User-Agent, a delay between requests.
- Record the URL, the retrieval date and the document title before you read it.

## Steps

1. **Find the index.**
   - Senate: `https://nitc.ac.in/minutes-and-reports/senate-minutes`
   - Board of Governors: `https://nitc.ac.in/minutes-and-reports`
   - Constitutions: `https://archive.org/details/sac-constitution`, `https://archive.org/details/sgb-constitution`
   - Fosscell wiki: `https://wiki.fosscell.org/SAC_To_SGB_Transition`

2. **Scrape the index into the cache.**

   ```bash
   ruby tools/scrape/senate.rb --out research/senate
   ruby tools/scrape/bog.rb --out research/bog
   ```

   The scraper writes a `manifest.json` with title, URL, date and local filename.

3. **Check what you actually got.** Institute sites often return an HTML error page with a `.pdf` name.

   ```bash
   ruby tools/parse/pdftext.rb research/senate/104.pdf
   ```

   If the output is HTML or mojibake, the file is not a real PDF. Record the failure in `research/notes/` and move on.

4. **Extract only the clause you need.**

   ```bash
   ruby tools/parse/pdftext.rb research/senate/93.pdf --out research/notes/senate-93.txt
   ```

   Then quote the operative sentence into `analysis/<topic>/claims.yml` with a locator.

5. **Do not publish the cache.** Add only reviewed excerpts to `research/notes/`, with names and contact details removed.

## Never

- Never commit `research/senate/`, `research/bog/`, raw PDFs or HTML.
- Never paste an attendance table, annexure or disciplinary list into a public file.
- Never retry a failing server more than twice.
- Never treat a missing document as proof that an event did not happen. Say "no published minute records it".

## Done when

- the document is cached locally,
- the clause is extracted with a locator,
- the claim row exists,
- `ruby tools/audit/sensitive_scan.rb .` passes.
