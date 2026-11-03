# Contributing

Thanks for wanting to help. This project is small, political and evidence-driven. Contributions are welcome from students, alumni and anyone who can follow the method.

Read [`ETHICS.md`](ETHICS.md), [`FACTCHECK.md`](FACTCHECK.md) and [`AGENTS.md`](AGENTS.md) first. They are short, and they are the whole contract.

## Ways to contribute

- **Documents.** Find a public minute, circular or order we missed. Add the URL and a locator.
- **Checks.** Re-check an existing claim against its source. Open an issue if it fails.
- **Copy.** Tighten a slide without strengthening the claim.
- **Design.** Improve the templates while keeping the system.
- **Code.** Make the scrapers, parsers and audits more robust.
- **Translations.** Malayalam and Hindi versions of the explainers.
- **Corrections.** The most valuable contribution. See below.

## Development setup

```bash
git clone https://github.com/<org>/NITC-Protest-Ops.git
cd NITC-Protest-Ops
nix develop
```

That is the whole setup. If `nix develop` fails, open an issue with the output.

## Before you open a pull request

```bash
ruby tools/audit/sensitive_scan.rb .
ruby tools/audit/image_check.rb outputs/
ruby tools/audit/claims_check.rb analysis/**/claims.yml
```

All three must pass. The sensitive scan is the important one: it blocks roll numbers, phone numbers, emails, font files and ignored paths that were staged by accident.

## Pull request checklist

- [ ] The change is about one thing.
- [ ] Every new factual claim has a row in a `claims.yml` with a source and a locator.
- [ ] The copy matches the strength of the evidence (no quotes on a paraphrase).
- [ ] No personal data, fonts, raw PDFs, images or secrets are included.
- [ ] The source panel / `sources.wiki` is updated.
- [ ] If a published claim changed, `outputs/<post>/CORRECTIONS.md` is updated.
- [ ] The audit passes.
- [ ] The commit message says what changed and why.

## Commit messages

Short imperative subject, then a body if needed.

```
Add S96.2.2 locator to the seven-gates claim

The rulebook slide cited the gate but not the minute. Add the item
number and the quote so the claim is checkable.
```

Do not use `update`, `fix stuff`, or `final final v2`.

## Code style

- **Ruby:** stdlib first. Two-space indent. Methods under 20 lines where practical. No monkey-patching. Raise on bad input; do not silently continue.
- **Shell:** `set -euo pipefail`, quote variables, no `rm -rf` without a guard.
- **YAML:** two-space indent, no tabs, ISO dates.
- **Markdown:** one sentence per line is fine; wrap at ~100 characters.
- **HTML/CSS:** semantic markup, no frameworks, no CDN dependencies (the render must work offline).

## Adding a skill

Skills live in `.opencode/skills/<name>/SKILL.md`. A skill is a short, procedural instruction set for an agent. Include:

- when to use it,
- the exact commands,
- the files it reads and writes,
- the hard rules,
- what "done" looks like.

Keep it under ~150 lines. Link to the long-form docs instead of repeating them.

## Adding an output

1. Create `outputs/post-NN-slug/`.
2. Put the editable master, the exported PNGs, `copy.md` and `sources.wiki` there.
3. Add a contact sheet to `outputs/_review/`.
4. Add the claim table under `analysis/<topic>/`.
5. Update the table in `README.md`.
6. Run the audit.

## Corrections

If you are correcting a published deck:

1. Do not edit the published PNG in place.
2. Add a dated entry to `outputs/<post>/CORRECTIONS.md` with the old claim, the new claim, the source and the date.
3. Re-export the panel and add it as `NN-slug-v2.png`, or re-export the whole deck and bump the folder note.
4. Open a PR titled `Correct: <claim>`.

We would rather publish a visible correction than quietly rewrite the record.

## Review

One maintainer review is enough for docs and tools. Two are needed for a change to a published claim or a new deck. See [`GOVERNANCE.md`](GOVERNANCE.md).

## Licence

By contributing, you agree that your contribution is licensed under **GPL-3.0-or-later**, the licence of the repository. Do not contribute material you do not have the right to license.
