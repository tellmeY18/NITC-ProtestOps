# Design system

Three colours. Two typefaces. One idea per panel.

The system was built for speed: a student should be able to turn a verified claim into a publishable panel in under ten minutes, and a reader should recognise the deck before reading a word.

---

## 1. Palette

| Token | Hex | Use |
|---|---|---|
| Black | `#000000` | default background, body text on light |
| White | `#FFFFFF` | default text, one inversion |
| Red | `#E10600` | masthead, accent words, bars, rules |
| Muted | `#A3A3A3` | notes only, never body copy |

No fourth colour. No gradients. No shadows. No transparency except the flat overlays in the original decks.

### Inversions

- **Black** is the default for every panel.
- **White** is used once, at the turn, when the argument changes gear.
- **Red** is used once, for the demand or the refusal.

Never use two inversions in one deck. The inversion is a structural signal, not decoration.

---

## 2. Type

### The original decks

| Role | Face | Notes |
|---|---|---|
| Headline | **Anton** | uppercase, tight leading, auto-shrunk to fit |
| Kicker / footer | **DIN Condensed** | uppercase, wide tracking |
| Body | **Helvetica Neue** | 26–32 px, leading 34–42 px |

These are **licensed fonts and are not in this repository**. Do not commit `.ttf`, `.otf`, `.woff` or `.woff2` files.

### The open substitutes

The HTML/CSS templates use fonts available in the Nix shell:

| Role | Substitute | Why |
|---|---|---|
| Headline | **Liberation Sans Bold/Black** | close grotesque weight, metric-compatible with Arial |
| Kicker / footer | **Liberation Sans Narrow Bold** | condensed without a licence |
| Body | **Liberation Sans Regular** | clean, wide language coverage |

Alternatives if you have them installed: **Inter** (body), **Archivo Black** (headline), **Roboto Condensed** (kicker). Any substitute must keep the same hierarchy: heavy headline, condensed kicker, plain body.

### Scale

| Element | Size | Tracking | Leading |
|---|---|---|---|
| Kicker | 26 px | 0.14 em | 1.0 |
| Index | 28 px | 0.04 em | 1.0 |
| Headline | 96–160 px | -0.025 em | 0.96 |
| Body | 26–32 px | 0 | 1.34 |
| Bar | 26 px | 0.04 em | 1.2 |
| Footer | 20 px | 0.06 em | 1.2 |
| Story prompt | 24 px | 0.08 em | 1.2 |

Headline auto-fit: `size = clamp(936 / (longest_line_chars × 0.56), 72, 160)`. The renderer implements this. If a headline needs more than three lines at 96 px, cut the headline.

---

## 3. Layout

### Feed panel — 1080 × 1080

```
┌──────────────────────────────────────────┐
│ MASTHEAD BAND 1080 × 96, RED             │
│ KICKER (black)                 INDEX     │
├──────────────────────────────────────────┤
│ ▌                                        │
│ ▌  HEADLINE                              │
│ ▌  (auto-fit, max 936 px wide)           │
│ ▌                                        │
│ ▌  ──── red rule 120 × 2                 │
│ ▌  BODY                                  │
│ ▌  (max 936 px, ≤ 55 words)              │
│                                          │
│ FOOTER (red, DIN, 20 px)                 │
└──────────────────────────────────────────┘
```

- Safe margin: **64 px** on all sides.
- Masthead: full bleed, 96 px, red on black/white, **black** on the red inversion.
- Kicker at `x+64, y+62` inside the band; index right-aligned to `x+1016`.
- Headline block starts at `y+400` (one line), `y+360` (two), `y+320` (three).
- Red side rule: 10 px wide at `x+40`, spanning the headline block.
- Body rule: 120 × 2 px, 26 px above the body.
- Footer baseline at `y+1012`.

### Story frame — 1080 × 1920

Same system, taller. Safe margins 250 px top and bottom (the UI covers the rest). Headline ≥ 64 px, body ≥ 28 px. Prompt bottom-right: `CONTINUE →`, `PART 2 NEXT →`, `SHARE THIS STORY →`.

### Print poster — A3 / A2

Scale the 1080 system by 1.5× or 2×. Keep the 64 px margin proportional (96 px at 1.5×). Export PDF from WeasyPrint, then PNG at 300 dpi if a raster is needed.

---

## 4. Components

### Masthead

The hard top edge that makes the deck recognisable at thumbnail size. Red band, black kicker, index on the right. On the red inversion, invert the band to black.

### Bars

A red block, 936 × 56 px, black condensed uppercase text. Used for lists, demands, and the five gaps. Maximum five bars per panel; more than five is a different panel.

### Rule

A 120 × 2 px red line between the headline and the body. It is the only divider in the system. Do not add boxes.

### Illustration

Flat line drawing, 3 px stroke, no fill, red accents only. Sits in the lower band. No faces, no photographs, no logos, no clip art. Eight illustrations in a twenty-panel deck is the right density: the type-only panels are the contrast that makes the drawings land.

### Source footer

`SOURCE: DOCUMENT, CLAUSE` in red condensed. On the last panel, a full source list and a QR code.

---

## 5. Accessibility

- Body contrast ≥ 4.5:1. Black on white and white on black both clear it. Red `#E10600` on black is ~4.0:1 — use it for headlines and bars, not body copy.
- Do not rely on colour alone. The index, the labels and the bars carry the structure.
- Alt text for every published image: the headline plus the first sentence of the body.
- Avoid all-caps for body copy; it is for headlines, kickers and bars only.
- Keep the index in the same place on every panel. It is a navigation aid.

---

## 6. Export

| Use | Size | Format |
|---|---|---|
| Instagram feed | 1080 × 1080 | PNG, sRGB |
| Instagram story | 1080 × 1920 | PNG, sRGB |
| Print poster | A3 / A2 | PDF (vector), 300 dpi PNG if needed |
| Contact sheet | 5 × N grid, 360 px tiles | PNG |

The renderer uses WeasyPrint (HTML/CSS → PDF) and poppler (`pdftoppm` → PNG). No browser, no headless Chrome, no ImageMagick PDF policy problems.

```bash
ruby tools/render/poster.rb templates/poster/example.yml
ruby tools/render/carousel.rb templates/carousel/example.yml
ruby tools/render/carousel.rb templates/story/example.yml --size 1080x1920
```

---

## 7. What not to do

- Do not add a logo. The decks have no logo by design.
- Do not use a photograph of a person. Consent is hard, and a face turns an argument into a target.
- Do not use more than one accent colour.
- Do not set body copy in all caps.
- Do not let a headline run to four lines.
- Do not put a quotation in a different colour from the body unless it is verbatim and attributed.
- Do not use a font you cannot license.
- Do not publish a panel without an index and a source footer.

---

## 8. Reference

The three decks in `outputs/` are the reference implementation:

- `post-01-sac-slides/` — the original 12-panel system, no masthead.
- `post-02-sac-to-sgb/` — 20 panels, the crash-course structure.
- `post-03-revival-day1/` — 20 panels, the masthead system, the most developed.

The design spec for post 3 is in `outputs/post-03-revival-day1/PLAN.md`.
