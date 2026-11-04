# NITC ProtestOps

**A student-run toolkit for documenting, verifying and publishing what happens at NIT Calicut.**

This repository is the working kit behind a set of public posts about student governance at NITC. It is not a newspaper and it is not a court. It is a repeatable process: **find the document, read the clause, check the claim, make the poster, publish the receipt.**

Everything here is public-source. Everything here can be checked. If a claim cannot survive the check, it does not go on a slide.

> **Status:** scaffold. The tools, templates and skills are functional but deliberately small. Posters are rendered locally from the templates; they are not stored here.

---

## What this is for

Students at NITC — and at any campus — are asked to trust decisions they cannot see. The documents that govern them are public in principle and buried in practice: Senate minutes in numbered PDFs, constitutions on archive.org, circulars that exist only as a screenshot.

This repo gives a small group of students the ability to:

1. **Scrape** the primary documents (Senate minutes, BoG minutes, constitutions, circulars).
2. **Extract** the relevant clauses without copying personal data.
3. **Verify** each claim against a named source, and record its strength.
4. **Design** posters and carousels that are readable, consistent and fast to produce.
5. **Publish** with a source list, a correction path and a right of reply.

The point is not to make better propaganda. The point is to make **accountable argument** cheap enough that students can do it between classes.

---

## Outputs stay local

The finished posters, decks and exports (`outputs/`) are **not published in this repository**. `outputs/` is git-ignored: each organiser keeps their own posters on their own machine and publishes them on their own channels. What the repo publishes is everything needed to make, check and defend one:

- the **tools** that render posters and carousels (`tools/render/`),
- the **templates** to start from (`templates/`), including the reading-circle story,
- the **claim tables and sources** a poster must stand on (`analysis/`, `research/notes/`),
- the **method, ethics and fact-check rules** (`docs/`, `ETHICS.md`, `FACTCHECK.md`).

Renders land in `outputs/_review/` (local). Public corrections go in [`CORRECTIONS.md`](CORRECTIONS.md).

---

## Quick start

You need [Nix](https://nixos.org/) with flakes enabled. Nothing else is required — no Chrome, no Python, no global Ruby gems.

```bash
git clone https://github.com/tellmeY18/NITC-ProtestOps.git
cd NITC-ProtestOps
nix develop
```

The dev shell provides Ruby, poppler, ImageMagick, WeasyPrint, `jq`, `ripgrep`, `git`, `gh`, `shellcheck`, `zstd`, `unzip`, `curl` and `tesseract`.

```bash
# 1. Scrape the public index of Senate minutes into the local cache
ruby tools/scrape/senate.rb --out research/senate

# 2. Extract text from the PDFs you care about
ruby tools/parse/pdftext.rb research/senate/93.pdf

# 3. Audit the tree before committing anything
ruby tools/audit/sensitive_scan.rb .

# 4. Render a poster from a YAML brief
ruby tools/render/poster.rb templates/poster/example.yml
```

> The scraper writes into `research/`, which is **git-ignored**. That is intentional. The cache contains personal data. Only reviewed excerpts belong in `research/notes/`.

---

## Use it with an AI agent

The rules live in one file, [`AGENTS.md`](AGENTS.md), and the workflows live in six skills under [`.opencode/skills/`](.opencode/skills/) (`scrape-sources`, `fact-check`, `poster-design`, `carousel-build`, `story-split`, `publish`). Any agent that reads `AGENTS.md` follows the same hard rules: no personal data, no fonts, no unsourced claims, nothing under `outputs/` committed.

**Every agent, first step:** clone the repo, then run commands inside the dev shell so the tools exist.

```bash
git clone https://github.com/tellmeY18/NITC-ProtestOps.git
cd NITC-ProtestOps
nix develop                      # interactive shell, or:
nix develop --command ruby tools/audit/sensitive_scan.rb .
```

| Agent | How it picks up the rules | Skills | Setup |
|---|---|---|---|
| **OpenCode** | reads `AGENTS.md` | reads `.opencode/skills/` | open the folder in OpenCode; nothing else |
| **Claude Code** | reads `CLAUDE.md`, which imports `AGENTS.md` | reads `.claude/skills/`, a link to `.opencode/skills/` | run `claude` in the repo root |
| **Codex (CLI / VS Code extension)** | reads `AGENTS.md` | no skill folder; say "follow `.opencode/skills/<name>/SKILL.md`" | run `codex` in the repo root |
| **VS Code + GitHub Copilot** | reads `AGENTS.md` when agent instructions are enabled | no skill folder; attach the `SKILL.md` as context | open the folder in VS Code |
| **Cursor, Windsurf, others** | most read `AGENTS.md`; if yours does not, add it to the project rules or paste it as the first message | attach the `SKILL.md` you need | copy or link `AGENTS.md` into the tool's rules file |

Tool support changes quickly. If your agent does not pick up `AGENTS.md`, start the session with this prompt:

```text
Read AGENTS.md, ETHICS.md and FACTCHECK.md first. Follow them.
Then read .opencode/skills/<skill>/SKILL.md for this task.
Run all commands with: nix develop --command <command>
```

### What to ask for

- **Check a claim:** "Use the `fact-check` skill. Add this claim to `analysis/sac-to-sgb/claims.yml` with a locator, then run the claims check."
- **Make a poster:** "Use the `poster-design` skill. Render `templates/poster/example.yml` with my copy."
- **Reading-circle story:** `nix develop --command ruby tools/render/reading_circle.rb templates/reading-circle/brief.yml --when "FRI 6 PM" --where "OAT"`
- **Before you push:** "Use the `publish` skill and run all three audits."

### Guardrails that hold for every agent

- Raw minutes in `research/senate/` and `research/bog/` contain personal data. They are git-ignored; never ask an agent to paste or commit them.
- Review every diff before you commit. An agent can be wrong; the audits catch personal data, not bad claims.
- Posters stay in `outputs/` on your machine. `outputs/*` is git-ignored on purpose.

---

## Repository map

```
.
├── flake.nix                  # reproducible dev shell
├── AGENTS.md                  # rules for AI agents working here
├── ETHICS.md                  # what we will and will not publish
├── SECURITY.md                # handling personal data and takedown requests
├── DISCLAIMER.md              # legal and editorial status
├── FACTCHECK.md               # how a claim earns its place on a slide
├── CONTRIBUTING.md            # how to add a post without breaking the process
├── GOVERNANCE.md              # who decides, and how to disagree
├── CODE_OF_CONDUCT.md
├── LICENSE                    # GPL-3.0-or-later
│
├── .opencode/skills/          # agent skills: scrape, fact-check, design, publish
├── docs/                      # method, design system, privacy, licensing
├── tools/                     # scrapers, parsers, audits, renderers
├── templates/                 # poster, carousel and story starters
├── analysis/                  # claim tables and source maps
├── research/                  # notes (raw cache is ignored)
├── outputs/                   # local-only renders (git-ignored)
└── private/                   # local-only; ignored by git
```

---

## The method in one page

1. **Pick a question, not a conclusion.** "Who approved the SGB Constitution?" is research. "The Director is a fascist" is a conclusion looking for evidence.
2. **Find the primary document.** A constitution, a minute, a circular, a court filing. A news report is corroboration, not the source.
3. **Quote the operative clause.** Not the preamble, not the label — the sentence that says who decides.
4. **Write the claim at its weakest defensible strength.** "No paper was shown" beats "no sanction exists." "The recorded approval covers eight amendments" beats "the Senate never saw it."
5. **Name the source on the artefact.** Every deck ends with a sources panel and a QR code.
6. **Separate reported speech from editorial line.** If you do not have the transcript, paraphrase and say so. No quotation marks around a paraphrase.
7. **Publish a correction path.** A right of reply is not a weakness; it is what makes the claim credible.
8. **Strip personal data.** No student roll numbers, phone numbers, emails, hostel rooms or disciplinary records. Public officials acting in public roles are named; private students are not.

The long version is in [`docs/research-method.md`](docs/research-method.md) and [`FACTCHECK.md`](FACTCHECK.md).

---

## Design system

Three colours (`#000000`, `#FFFFFF`, `#E10600`), two typefaces, no photographs, no faces, no logos. The system is documented in [`docs/design-system.md`](docs/design-system.md) and implemented in [`templates/`](templates/).

The decks were built in **PhotoCraft** and exported as PNG. The templates here reproduce the same language in HTML/CSS so a post can be built with WeasyPrint on any machine, with no proprietary app.

**Fonts are not included.** Helvetica Neue and DIN Condensed are licensed. The templates use open substitutes and document the metric differences. See [`docs/design-system.md`](docs/design-system.md#fonts).

---

## Privacy and safety

This repository is public. That means:

- **Never commit** `research/senate/`, `research/bog/`, `private/`, raw PDFs, HTML dumps, WhatsApp images or QR scans. The ignore rules already cover them; `tools/audit/sensitive_scan.rb` checks that they stayed out.
- **Never commit** student names, roll numbers, phone numbers, emails, hostel details or disciplinary/appeal records.
- **Never commit** proprietary fonts.
- **Do commit** the claim, the clause, the source URL, the date you checked it, and the strength of the evidence.

If you are a person named in a deck and you believe something is wrong, see [`SECURITY.md`](SECURITY.md). We will publish a correction, not argue about it.

---

## Licence

**GNU General Public License v3.0 or later** for the whole repository — code, templates and documentation. See [`LICENSE`](LICENSE).

You may copy, modify and redistribute this work, including commercially, provided you preserve the licence and make the source available. Derivative decks must carry the same licence. Attribution to *NITC ProtestOps* is requested but is not an extra condition.

Third-party documents quoted here (constitutions, minutes, news reports) remain the property of their authors and are used for criticism, review and reporting. Source URLs are recorded in [`analysis/`](analysis/) and in each deck's `sources.wiki`.

---

## Contributing

Read [`CONTRIBUTING.md`](CONTRIBUTING.md) and [`ETHICS.md`](ETHICS.md) first. The short version:

- One claim, one source, one row in the claim table.
- Run the audit before you open a pull request.
- If you cannot source it, label it as opinion or cut it.
- Do not add a name to a slide that you would not put on a poster in your own name.

---

## A note on tone

The decks are angry. They are also careful. That combination is the whole point: **the anger is in the design, the accuracy is in the footnotes.** Keep both.
