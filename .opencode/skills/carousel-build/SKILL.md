---
name: carousel-build
description: Build a numbered Instagram carousel from a copy deck — panels, index, inversions, contact sheet — using HTML/CSS and WeasyPrint.
---

# Carousel build

Use for a multi-panel feed post. Render with `tools/render/carousel.rb`; keep the result local (`outputs/` is git-ignored).

## Shape

- **Panels:** 8–20. Instagram's cap is 20.
- **Index:** `NN/Total` on every panel, same position.
- **Arc:** record → turn → demand. One white or red inversion at the turn, never more.
- **Last panel:** the source list and a QR code.
- **Contact sheet:** one image showing every panel, for review.

## Steps

1. **Write the copy deck first.** `outputs/<post>/copy.md` (local), one section per panel:

   ```markdown
   ## 07 — THE ROOM
   **Kicker:** WHAT CHANGED
   **Headline:** NINE STUDENTS. / TEN FACULTY.
   **Body:** The SAC was restructured in 2024…
   **Footer:** SOURCE: SGB CONSTITUTION, CH. I
   ```

2. **Write the claim table.** `analysis/<topic>/claims.yml`. Every fact on every panel gets a row. Run `ruby tools/audit/claims_check.rb`.

3. **Build the YAML brief.** `templates/carousel/example.yml`:

   ```yaml
   slug: post-04-example
   title: "A crash course"
   palette: black
   panels:
     - kicker: A CRASH COURSE
       headline: "SAC TO SGB / FOR DUMMIES."
       body: "What we lost, why it matters."
       footer: ""
       inversion: none      # none | white | red
     - kicker: 11 FEBRUARY 2008
       headline: "STUDENTS WROTE / A CONSTITUTION."
       body: "The 19th Senate approved it."
       inversion: none
   ```

4. **Render.**

   ```bash
   ruby tools/render/carousel.rb templates/carousel/example.yml
   ```

   Output: `outputs/_review/<slug>/NN-*.png` plus `contact-sheet.png`.

5. **Review the contact sheet at thumbnail size.** If a panel is unreadable at 200 px wide, it is unreadable in the feed.

6. **Check every panel against the claim table.** Especially the ones with numbers, dates and quotations.

7. **Publish-ready layout.**

   ```bash
   mkdir -p outputs/post-NN-slug
   mv outputs/_review/<slug>/*.png outputs/post-NN-slug/
   mv outputs/_review/<slug>/contact-sheet.png outputs/_review/post-NN-contact-sheet.png
   ```

## Panel rules

- Headline ≤ 3 lines at 96 px.
- Body ≤ 55 words.
- One quotation per panel, maximum.
- Source footer on every panel that makes a factual claim.
- The source panel lists every document, with URLs, and a QR to the full list.
- Bleep profanity as `sh*t`.

## Never

- Never exceed 20 panels.
- Never use two inversions.
- Never put a claim on a panel that is not in the claim table.
- Never publish without the source panel.

## Done when

- every panel is numbered,
- the contact sheet is in `outputs/_review/`,
- the claim table is complete and the checker passes,
- the source panel is accurate,
- `ruby tools/audit/image_check.rb outputs/` passes.
