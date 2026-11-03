# Research method

This is the long version of the method in `README.md`. It is the process behind `analysis/` and the three decks.

## 1. Start with a question that has a document

Good: *Who approved the SGB Constitution, and what does the approval record say?*

Bad: *Why is the administration so corrupt?*

The first can be answered by a minute. The second cannot be answered at all, which means it will be answered by assertion. Assertion is cheap and loses arguments.

## 2. Build the document set before the argument

For student governance at NITC the core set is:

| Document | Where | Why |
|---|---|---|
| SAC Constitution (2008) | archive.org `sac-constitution` | the baseline: powers, referendum, Senate role |
| SGB Constitution (2024) | archive.org `sgb-constitution` | the operative text |
| Senate minutes 46–106 | `nitc.ac.in/minutes-and-reports/senate-minutes` | the record of approval, amendment and process |
| BoG minutes 65–71 | `nitc.ac.in/minutes-and-reports` | the higher approval gate |
| 93rd Senate minutes, S93.3.3 | Senate index | the eight amendments |
| News reports | Onmanorama, Mathrubhumi, Times Now, The News Minute | corroboration for public acts |

Cache them locally. Read the primary documents first; use the news only to corroborate.

## 3. Read for the operative clause

A constitution has three kinds of sentence:

- **Labels:** "The SGB shall be the apex policy making representative body."
- **Operative rules:** "The SGB will be governed by the EC." "The DSW decision is final."
- **Decoration:** preamble, aims, aspirations.

The argument lives in the operative rules. A label that contradicts an operative rule is not a defence; it is the thing to point at.

When two clauses conflict, quote both and say which one decides. Do not pretend the conflict does not exist.

## 4. Search for absence, and record the search

If the claim is "the SGB Constitution does not contain X":

```bash
rg -i 'supreme|referendum|joint secretary|alumni' research/notes/SGB_Constitution_djvu.txt
```

Record the command and the result. Absence in a document is a fact about the document. It is not a fact about the world.

If a document is unpublished, say so. The 93rd minutes' Annexure IV is the standing example: the recorded approval covers eight amendments, but the revised report itself is not public, so the defensible claim stops there.

## 5. Build the timeline

Dates are where most arguments break. Keep three dates separate:

- the date of the **event**,
- the date of the **document** that records it,
- the date you **checked** it.

A minute held on 17 July 2023 may be published later. A post dated 20 January 2024 is not a post on 30 January. A title held in 2026 may not be the title held in 2024.

## 6. Write the claim at its weakest defensible strength

This is the core discipline. Examples from the decks:

| Tempting | Defensible |
|---|---|
| "The Senate never approved the SGB Constitution." | "No published Senate or BoG minute records approving it." |
| "The administration abolished student power." | "The operative text moves final authority from the GSB and Senate to the DSW and Director." |
| "The statue has no sanction." | "A Ministry sanction was cited; no copy was produced." |
| "The Director lied." | "The Director said X; the document says Y." |
| "The Dean is a fascist." | "The Dean posted 'Proud of Godse for saving India' in January 2024; four outlets reported it." |

The weaker version is harder to attack and easier to defend. It also tends to be more damning, because it is checkable.

## 7. Separate the three voices

Every deck has three voices, and they must be visually distinct:

1. **The document** — quoted, with a locator.
2. **The report** — "according to X", named.
3. **Us** — the editorial line, in a headline, a red bar, or a separate paragraph.

Never put our answer inside their quotation marks. Never let a paraphrase wear a quote. If the minutes are not in hand, paraphrase and say "per the minutes".

## 8. Check the counter-argument

Before publishing, write the strongest objection you can think of, and answer it in the claim table or the copy.

Examples already in the project:

- *"SGB Ch. II §1 still calls the SGB the apex policy body."* → Answer: the operative clauses (Ch. I, Ch. II §11, Ch. IV) name who decides; the label is contradicted three pages earlier.
- *"S99.6(c) says the Senate has no mandate over student governance."* → Answer: the SAC Constitution was a Senate instrument, and the DSW brought the revision to the Senate in July 2023. You cannot concede jurisdiction in July and deny it in January.
- *"The committee was appointed by the DSW, so the Senate had no role."* → Answer: the 2008 text requires Senate approval for amendments, and the Senate did vote on eight of them.

An argument that has not met its best objection is not finished.

## 9. Publish the receipt

Every deck ends with:

- the document list,
- a QR code to the full source list,
- the date of the research,
- a correction route.

The receipt is not an appendix. It is the difference between a poster and a rumour.

## 10. Correct in public

If a claim is wrong:

1. add a dated row to `CORRECTIONS.md` (repo root),
2. publish a correction panel or story,
3. do not silently edit the PNG.

The record of the correction is part of the argument. It shows the method works.

---

## Checklists

### Before research

- [ ] The question can be answered by a document.
- [ ] I know which document set I need.
- [ ] I have a place to cache it (`research/`, git-ignored).

### Before a claim

- [ ] I have the primary document open.
- [ ] I have the operative sentence.
- [ ] I have a locator.
- [ ] I have checked the negation.
- [ ] I have checked the date and the title-at-the-time.
- [ ] I have chosen a strength.
- [ ] The copy matches the strength.

### Before publishing

- [ ] The claim table is complete.
- [ ] The source panel is accurate.
- [ ] The counter-argument is answered.
- [ ] The audit passes.
- [ ] The correction route is public.
