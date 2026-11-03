# Analysis

Claim tables and source maps. One folder per topic.

| Folder | Topic |
|---|---|
| `sac-to-sgb/` | the 2008 SAC → 2024 SGB transition; the claim table behind posts 1–3 |
| `senate-attendance/` | SAC office-bearer representation in the Senate, 87th–103rd meetings |

## Format

Each topic has:

- `claims.yml` — one row per factual claim,
- `sources.yml` — the document set,
- `README.md` — the argument, the caveats, how to re-check.

## Rules

- A claim without a source and a locator does not go on a slide.
- The `strength` label determines what the copy may do. See `FACTCHECK.md`.
- Quote only on `verbatim` rows.
- Record the date checked.
- Keep personal data out. If a source contains it, quote the clause, not the annexure.

## Check

```bash
ruby tools/audit/claims_check.rb analysis/**/claims.yml
```
