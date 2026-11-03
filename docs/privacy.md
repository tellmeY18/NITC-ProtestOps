# Privacy

The project exists to scrutinise a public institution, not to expose private people. That distinction is the whole privacy policy.

## What we publish

- clauses from public constitutions and minutes,
- the names and public acts of public officials,
- public statements and public social-media posts by office-holders,
- aggregate counts (for example, "9 students, 10 faculty"), never individual records.

## What we never publish

- student names, roll numbers, phone numbers, emails, hostel rooms,
- disciplinary, appeal, medical or financial records,
- attendance sheets with names,
- private messages, unless the sender consents or the message is a threat and the public interest clearly outweighs the privacy cost,
- photographs of faces,
- anything from `private/`.

## The raw caches

`research/senate/` and `research/bog/` contain:

- 1,843 roll-number matches,
- phone numbers and emails,
- disciplinary and appeal cases.

They are **git-ignored** and must stay local. `tools/audit/sensitive_scan.rb` fails the build if they are tracked. The audit also scans for roll-number, email and phone patterns in every published text file.

If you need to quote a minute that contains personal data:

1. quote the clause, not the annexure,
2. replace names with roles (`a fourth-year student`, `the complainant`),
3. remove the roll number, phone and email,
4. keep the locator so the quote can still be checked,
5. record the redaction in `research/notes/`.

## Images

- Strip EXIF before publishing (`tools/audit/image_check.rb` warns).
- Do not publish a screenshot that shows a name, a number, a chat header or a profile photo.
- Crop to the claim, not to the person.
- The design system has no faces. Keep it that way.

## Sources

- Do not name a source who asked to be anonymous.
- Do not describe a source so precisely that they become identifiable.
- Do not store source identities in git, even in a private branch.
- Use `private/` for correspondence, and keep it off cloud sync.

## Data minimisation

Collect the minimum. If a document has 40 pages and you need one clause, keep the clause and delete the rest from the published tree. The cache can hold the full document locally; the repository holds the excerpt.

## Retention

- `research/` cache: delete when the post ships, or keep locally if you are still working on the topic.
- `private/`: delete when the correspondence is resolved.
- `outputs/`: keep. It is the public record.
- `analysis/`: keep. It is the receipt.

## A person's request

If someone asks to remove their personal data:

1. remove it within 7 days,
2. confirm in writing what was removed,
3. if it was in git history, rewrite history and force-push, then ask mirrors to update,
4. record the incident in `outputs/_review/incidents.md` without repeating the data.

Do not argue about whether the data was already public. Remove it.

## Children and students

Most people in these documents are adults, but many are students in a hierarchical institution. Treat student data as sensitive by default. A roll number is an identifier; a disciplinary record is a harm.

## The test

> Would I be comfortable if my own roll number, phone number and disciplinary file appeared in a public repository?

If not, it does not go in.
