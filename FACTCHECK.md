# Fact-checking

Every factual sentence on a slide has to earn its place. This file defines how.

## The strength ladder

Use exactly one of these labels in `analysis/<topic>/claims.yml`. The label determines what the copy may do.

| Strength | Meaning | Copy may… | Copy may not… |
|---|---|---|---|
| `verbatim` | exact words from a named document, with a locator | quote in quotation marks | extend, trim mid-sentence without ellipsis, or modernise spelling |
| `documented` | a fact stated in a named document, paraphrased | state it plainly, cite the document | imply a motive the document does not state |
| `reported` | a named outlet or person reported it | say "according to X" | present it as established fact |
| `paraphrase` | our summary of a document we hold but are not quoting | summarise, with "per the minutes" / "the reply said" | use quotation marks |
| `inference` | our reading of the evidence | say "we read this as…", "this suggests…" | state it as fact |
| `opinion` | editorial judgement | put it in a headline or a clearly editorial line | dress it as a finding |

If a row has no `source`, it is `UNSOURCED` and cannot appear on a slide.

## What counts as a source

**Primary**

- the constitution or rulebook itself,
- Senate / BoG / BoAC minutes,
- an official circular, order or reply,
- a court filing or judgment,
- a public post by the person who made the decision.

**Corroborating**

- a named news outlet with its own reporting,
- a second independent outlet,
- an official press release.

**Not a source**

- an anonymous screenshot with no chain of custody,
- a WhatsApp forward,
- "everyone knows",
- another post in this project (circular),
- an AI summary (including this one).

## The procedure

1. **Locate the operative sentence.** Not the preamble, not the table of contents. The clause that says who decides, who approves, what is forbidden.
2. **Record the locator.** Page, clause, item number, paragraph. `S93.3.3` is a locator. "The minutes" is not.
3. **Write the claim at its weakest defensible strength.** Then see if the stronger version is still true. If it is, use it. If not, keep the weak one.
4. **Check the negation.** The most common error is claiming something is absent. Search the whole document for the term (`grep -i supreme`), and record that you searched. Absence in a published document is evidence of absence *in that document*, not in the world.
5. **Check dates.** The date of the event, the date of the document, and the date you checked it are three different things. Record all three.
6. **Check names and titles.** A person's title at the time of the act, not today. "Dean (P&D)" in 2026 may not be "Dean (P&D)" in 2024.
7. **Separate report from comment.** If the deck answers a quote, the answer goes in a different visual or a different paragraph, never inside the quotation marks.
8. **Record the check.** `checked: 2026-11-03` and the URL or file path.

## Quotations

- Use quotation marks **only** for verbatim text.
- Use an ellipsis for omitted words; do not use one to change meaning.
- Do not "clean up" grammar inside quotation marks. Use `[sic]` if needed, or paraphrase.
- If the source is a scan with OCR errors, quote the corrected reading and note the correction in the claim table.
- If you cannot see the original (only a paraphrase of it), do not quote. Say "per the minutes" and paraphrase.

## Numbers

- Give the number and the denominator: "9 students, 10 faculty", not "a minority".
- Give the threshold and the change: "CGPA 7.0 → 6.5", not "lowered".
- Give the date range for a claim about a period: "87th (14 Jul 2022) to 95th (11 Jan 2024)".
- If a count comes from a search, say what you searched.

## Images and screenshots

- A screenshot is evidence of a screenshot, not of the event. Record where it came from and who took it.
- Check for cropping, editing and missing context. A reply with the top cut off is not a reply.
- Strip EXIF before publishing.
- Never publish a face without consent.

## When the record is incomplete

Say so. Examples from this project:

- Annexure IV of the 93rd Senate minutes is unpublished, so the claim is "the recorded approval covers eight amendments", not "the Senate never saw the draft".
- `104.pdf`–`106.pdf` were HTML error pages, so the attendance analysis stops at the 103rd meeting.
- `88.pdf` and `89.pdf` have broken font encoding, so their attendance lists are unreadable and are excluded.
- The 2 Nov minutes were supplied by an editor but are not in the repo, so the deck paraphrases and uses no quotation marks.

An honest gap is stronger than a confident guess. It also tells the next researcher where to start.

## The claim table

`analysis/<topic>/claims.yml`:

```yaml
- id: sgb-final-word
  claim: "The SGB Constitution gives the DSW the final decision."
  source: research/SGB_Constitution_djvu.txt
  locator: "Ch. II, §11"
  quote: "The DSW decision is final."
  strength: verbatim
  checked: 2026-11-03
  slide: "post-02/09"
```

Run `ruby tools/audit/claims_check.rb analysis/<topic>/claims.yml` before publishing. It checks for missing sources, missing locators, invalid strengths, and quotes on non-verbatim rows.

## The final test

Read the slide to someone who disagrees with you. If their objection is "that's not what the document says", you have failed. If their objection is "I disagree with your conclusion", you have succeeded.
