---
name: fact-check
description: Turn a draft claim into a sourced, strength-labelled row in a claim table, and reject anything that cannot survive the check.
---

# Fact-check

Use before a claim goes on a slide, and whenever someone challenges a published claim.

## The ladder

Label every claim with exactly one strength:

| Strength | Test | Copy may |
|---|---|---|
| `verbatim` | exact words, named document, locator | quote in quotation marks |
| `documented` | fact stated in a named document | state plainly, cite |
| `reported` | a named outlet/person reported it | say "according to X" |
| `paraphrase` | our summary of a document we hold | summarise, no quotes |
| `inference` | our reading of the evidence | "we read this as…" |
| `opinion` | editorial judgement | headline / clearly editorial |

No source → `UNSOURCED` → cut it.

## Steps

1. **Write the claim as a single sentence.** One fact per row.
2. **Open the primary document.** Not a news summary, not another post.
3. **Find the operative sentence.** The one that says who decides, who approves, what is forbidden.
4. **Record the locator.** Page, clause, item number. `S93.3.3` is a locator; "the minutes" is not.
5. **Quote it exactly** into `quote:` if it is verbatim. If you are summarising, leave `quote:` empty.
6. **Test the negation.** If the claim is "X is absent", search the whole document (`rg -i 'x' file`) and record the search.
7. **Set the strength.** When in doubt, go one step weaker.
8. **Add the date you checked it** (`checked: YYYY-MM-DD`).
9. **Run the checker.**

   ```bash
   ruby tools/audit/claims_check.rb analysis/<topic>/claims.yml
   ```

10. **Fix the copy, not the label.** If the slide overstates the source, change the slide.

## Red flags

- A quotation mark around a paraphrase.
- "Clearly", "obviously", "everyone knows" — usually an inference in disguise.
- A motive attributed to a named person without a document that states it.
- A date that comes from memory rather than the document.
- A title that is current but not the title at the time of the act.
- An absence claim based on one search of one file.
- A number without a denominator or a date.

## Incomplete records

Say so in the claim table and, if it matters, on the slide. Examples:

- an annexure is unpublished,
- a PDF is an error page,
- a font encoding is broken,
- the minutes were supplied by an editor but are not in the repo.

An honest gap is stronger than a confident guess.

## Done when

- the row exists with source, locator, strength and date,
- the copy matches the strength,
- the checker passes,
- a person who disagrees could follow the row to the sentence.
