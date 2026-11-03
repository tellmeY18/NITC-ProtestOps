# Private

Local-only. Nothing in this directory is committed except this README and `.gitignore`.

Use it for:

- correspondence with people named in a deck,
- source identities,
- unredacted documents,
- drafts that are not ready,
- legal notices,
- anything you would not hand to a stranger.

## Rules

- Keep it on an encrypted disk.
- Do not sync it to a public cloud folder.
- Do not paste its contents into an issue, a chat, or a commit message.
- Delete correspondence when the matter is resolved.

The root `.gitignore` ignores `private/` entirely. If you ever see a file from here in `git status`, stop and fix the ignore rule before committing.
