# Security and privacy

This repository is public and contains criticism of named public officials. That creates two kinds of risk: **personal data leaking into git**, and **people being harmed by what we publish**.

## Reporting a privacy or security problem

If you find personal data in this repository, or a claim that puts someone at risk, **do not open a public issue**. Email the maintainers (see `GOVERNANCE.md`) or use GitHub's private vulnerability reporting.

Include:

- the file path and line,
- what the data is (roll number, phone, email, document),
- whether it is already in git history,
- how urgently it needs removal.

We aim to acknowledge within 72 hours and to remove or redact within 7 days.

## If you are named in a deck

If you believe a claim about you is wrong, or that a private detail has been published:

1. Email the maintainers with the post, the slide number and the specific sentence.
2. Tell us what is wrong and what the correct position is.
3. We will check it against the source, publish a correction if warranted, and add your reply.

We will not remove criticism because it is uncomfortable. We will remove personal data, correct errors, and publish a right of reply.

## What must never enter git

| Material | Why | Where it lives |
|---|---|---|
| Senate / BoG raw minutes | roll numbers, phones, emails, disciplinary cases | `research/senate/`, `research/bog/` (ignored) |
| Raw PDFs and HTML dumps | same, plus metadata | `research/` (ignored) |
| `private/` | correspondence, drafts, source identity | local only |
| WhatsApp images, `scan.png` | unknown provenance, possible personal data | local only |
| Fonts | licence violation | local only |
| `.env`, keys, tokens | credential leak | local only |

The ignore rules cover these. `tools/audit/sensitive_scan.rb` checks that they stayed out, including in the staged index.

## Threat model

We assume:

- **The repository is mirrored.** Once pushed, history is effectively permanent. Remove data *before* the first push, not after.
- **Screenshots travel.** A slide can be cropped, re-captioned and used to harass someone. Design for the worst crop.
- **Documents are incomplete.** A missing minute is not proof of absence. Say "no published minute records it", not "it never happened".
- **The institution can respond.** Keep the evidence, the locator and the date for every claim.
- **Contributors are students.** Do not ask anyone to take a risk you would not take. Do not publish a source's identity to prove a point.

## Safe scraping

- One request at a time; a descriptive User-Agent; a delay between requests.
- Respect `robots.txt` and site terms.
- Cache to `research/` and parse locally. Do not hammer an institute server to prove a point.
- Never scrape authenticated, private or paywalled material.
- Never bypass a login, a CAPTCHA or an access control.

## Device hygiene

- Keep raw material on an encrypted disk.
- Strip EXIF from images before publishing (`tools/audit/image_check.rb` warns).
- Do not sync `private/` to a public cloud folder.
- Rotate any token that has ever been committed.

## Incident response

1. **Contain** — remove the file from the working tree and the index.
2. **Assess** — was it pushed? To where? Who has it?
3. **Purge** — if pushed, rewrite history (`git filter-repo`) and force-push, then ask mirrors to update.
4. **Notify** — tell affected people plainly what was exposed and for how long.
5. **Record** — add a dated entry to `private/incidents.md` (without repeating the data).
6. **Fix the rule** — add a test or an ignore pattern so it cannot recur.
