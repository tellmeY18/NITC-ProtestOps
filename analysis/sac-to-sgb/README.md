# SAC → SGB analysis

This folder holds the claim table and source map behind posts 1–3.

| File | What it is |
|---|---|
| `claims.yml` | every factual claim, with source, locator, quote (where verbatim), strength and date checked |
| `sources.yml` | the document set, with URLs, local copies and licence notes |

## How to read a claim

```yaml
- id: gsb-supreme
  claim: The 2008 text names the General Student Body as the supreme power.
  source: research/notes/SAC_Constitution_djvu.txt
  locator: "Ch. I"
  quote: "Both the SAC and the EC shall remain responsible to the General Student Body - the supreme power."
  strength: verbatim
  checked: 2026-11-03
  slide: "post-02/03"
```

- **source** is a file in this repository or a URL.
- **locator** is the clause, page or item number. It is what makes the claim checkable.
- **quote** is only present on `verbatim` rows.
- **strength** determines what the copy may do. See `FACTCHECK.md`.
- **checked** is the date the source was last read.

## The argument in one line

The 2008 SAC was a student parliament with a binding policy role, a referendum, a censure net that included the executive, and a Senate approval gate. The 2024 SGB keeps the elections and the minutes but moves the final word to the DSW and the Director, fills the executive with faculty, and removes the Senate from amendments. The recorded Senate approval of July 2023 covers eight additions — not the transfer of power that followed.

## The honest caveats

- Annexure IV of the 93rd minutes is unpublished, so the claim is about the **recorded approval**, not about what the Senate saw in the annexure.
- No published Senate or BoG minute records approving the SGB Constitution. That is a claim about the published record, not about closed sessions.
- Senate 104–106 are partly broken; the analysis is reliable through the 103rd meeting (17 Nov 2025).
- The 2 November 2026 minutes and the statue reply are quoted from material supplied by an editor, not from a file in this repository. The decks paraphrase them and use no quotation marks.

## Run the check

```bash
ruby tools/audit/claims_check.rb analysis/sac-to-sgb/claims.yml
```
