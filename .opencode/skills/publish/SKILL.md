---
name: publish
description: Run the pre-publish gate — audit for personal data, check claims and images, confirm sources and corrections — then package a deck for release.
---

# Publish

Use only after a deck is built and reviewed. This is the gate, not the build.

## The gate

Run all of these from the repository root. Any failure stops the release.

```bash
ruby tools/audit/sensitive_scan.rb .
ruby tools/audit/image_check.rb outputs/
ruby tools/audit/claims_check.rb analysis/**/claims.yml
```

Then check by hand:

- [ ] Every factual claim has a row in a `claims.yml`.
- [ ] No quotation marks around a paraphrase.
- [ ] Every named person is a public official acting in their public role.
- [ ] No student names, roll numbers, phone numbers, emails, hostel details or disciplinary records.
- [ ] No faces, no logos, no photographs.
- [ ] The source panel lists every document with a URL.
- [ ] The right-of-reply route is in the caption or the bio link.
- [ ] The licence and disclaimer are linked.
- [ ] `CORRECTIONS.md` is current.

## Package

```
outputs/post-NN-slug/
├── copy.md              # the copy deck
├── sources.wiki         # every source, with URLs
├── CORRECTIONS.md       # dated correction log
├── NN-*.png             # the panels, in order
└── master.pcraft        # editable master, if there is one
```

Contact sheet: `outputs/_review/post-NN-contact-sheet.png`.

## Caption

- Lead with the stake, not the process.
- Put the source list and the correction route at the end.
- No hashtags that invite harassment. No tagging a named person.
- Keep the caveat if the record is incomplete.

## Release

1. Commit with a message that says what the deck claims and what it is based on.
2. Tag the release: `git tag post-NN-v1`.
3. Publish the panels in order. Do not reorder after posting.
4. Archive the source URLs (Wayback Machine) and record the archive links in `sources.wiki`.
5. Watch the replies for 48 hours. Corrections are published, not argued.

## If something is wrong after publishing

1. Do not silently delete.
2. Add a dated entry to `CORRECTIONS.md`: old claim, new claim, source, date.
3. Publish a correction panel or a story frame.
4. If the error is serious, unpublish the panel and say why.

## Never

- Never publish from a dirty tree with uncommitted personal data.
- Never publish a claim you cannot point to a sentence for.
- Never publish a deck that names a private individual.
- Never force-push a published tag.
- Never let a correction wait for a "batch".

## Done when

- the audit passes,
- the deck is committed and tagged,
- the sources are archived,
- the caption carries the correction route,
- the contact sheet is in `outputs/_review/`.
