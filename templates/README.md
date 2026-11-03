# Templates

Starter briefs for the renderers. Copy one, change the copy, render.

| Template | Renderer | Output |
|---|---|---|
| `poster/example.yml` | `tools/render/poster.rb` | `outputs/_review/<slug>.png` |
| `carousel/example.yml` | `tools/render/carousel.rb` | `outputs/_review/<slug>/NN-*.png` |
| `story/example.yml` | `tools/render/carousel.rb --size 1080x1920` | `outputs/_review/<slug>/NN-*.png` |
| `reading-circle/brief.yml` | `tools/render/reading_circle.rb` | `outputs/_review/reading-circle.png` (QR + WHEN/WHERE) |

## YAML fields

### Poster

| Field | Required | Notes |
|---|---|---|
| `slug` | yes | output filename |
| `kicker` | yes | masthead, uppercase |
| `headline` | yes | use ` / ` for line breaks, `**...**` for the accent colour |
| `body` | no | plain text; newlines become line breaks |
| `bars` | no | list of red bars |
| `footer` | no | source line |
| `palette` | no | `black` (default), `white`, `red` |
| `size` | no | `1080x1080` (default) |

### Carousel / story

Same fields per panel, plus:

| Field | Notes |
|---|---|
| `panels` | list of panel objects |
| `inversion` | `none`, `white`, `red` — one per deck |
| `index` | auto `NN/Total` if omitted |
| `prompt` | story-only: `CONTINUE →`, `SHARE THIS STORY →` |
| `slug` | per-panel filename |

## Copy rules

- ` / ` is a hard line break. Do not use it inside a sentence.
- `**text**` turns the text red (or the accent colour of the palette). It can span a line break.
- Keep body copy under 55 words per panel.
- No quotation marks around a paraphrase.
- Bleep profanity as `sh*t`.

## Fonts

The renderer uses the open fonts from `flake.nix` (Liberation Sans / Liberation Sans Narrow). The original decks use Anton, DIN Condensed and Helvetica Neue, which are licensed and not included. See `docs/design-system.md#fonts`.
