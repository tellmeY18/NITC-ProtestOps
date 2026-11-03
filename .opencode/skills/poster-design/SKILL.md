---
name: poster-design
description: Build a single 1080×1080 poster in the NITC Protest Ops visual system using HTML/CSS and WeasyPrint, with no browser and no proprietary fonts.
---

# Poster design

Use for a one-off poster, a print handout, or a single feed image.

## The system

- **Palette:** `#000000`, `#FFFFFF`, `#E10600`. Nothing else.
- **Type:** Anton (headline), DIN Condensed (kicker/footer), Helvetica Neue (body) in the original decks. The templates use open substitutes — see `docs/design-system.md#fonts`.
- **One idea per poster.** A headline, a kicker, a body, a footer. That is the whole vocabulary.
- **One inversion.** Black by default. White or red for the turn.
- **No photographs, no faces, no logos, no clip art.** Flat line illustration only.

## Steps

1. **Write the brief in YAML.** Copy `templates/poster/example.yml`:

   ```yaml
   slug: open-gates
   kicker: 2 NOVEMBER 2026
   headline: |-
     OPEN GATES.
     SAC BACK.
   body: >-
     The demand is not new. The gates were never the institute's to close.
   footer: NITC PROTEST OPS
   palette: black        # black | white | red
   size: 1080x1080
   ```

2. **Render.**

   ```bash
   ruby tools/render/poster.rb templates/poster/example.yml
   ```

   Output goes to `outputs/_review/<slug>.png`.

3. **Look at it.** Check:
   - headline fits without shrinking below 72 px,
   - body clears 4.5:1 contrast,
   - nothing touches the 64 px safe margin,
   - the footer is legible at thumbnail size.

4. **Fix the copy first, the layout second.** If the headline needs three lines, the headline is too long.

5. **Move it into an output folder** once approved:

   ```bash
   mkdir -p outputs/post-NN-slug
   mv outputs/_review/<slug>.png outputs/post-NN-slug/
   ```

## Type scale

| Element | Size | Notes |
|---|---|---|
| Kicker | 26 px | tracking 140, uppercase |
| Headline | 96–160 px | auto-shrink to fit 936 px width |
| Body | 26–32 px | leading 34–42 px |
| Footer | 20 px | tracking 60, uppercase |

## Never

- Never use a font you do not have a licence for.
- Never add a second accent colour "just for this one".
- Never put a face on a poster without consent.
- Never let the design imply a fact the copy does not state.

## Done when

- the PNG is 1080×1080 (or the requested size),
- the copy is in `copy.md` with a claim row for every fact,
- the poster is in `outputs/`,
- `ruby tools/audit/image_check.rb outputs/` passes.
