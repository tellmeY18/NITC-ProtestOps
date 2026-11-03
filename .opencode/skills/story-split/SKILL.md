---
name: story-split
description: Split a long-form argument into a sequence of Instagram story frames, each readable in five seconds, with a clear continue/share prompt.
---

# Story split

Use when the argument is too long for a carousel but too important to cut.

## Shape

- **6–10 frames**, split into 2–3 parts.
- **1080 × 1920**, safe margins 250 px top and bottom.
- **One paragraph cluster per frame.** A frame is a breath, not a page.
- **Prompt at the bottom:** `CONTINUE →`, `PART 2 NEXT →`, `SHARE THIS STORY →`.
- **Frame 1** states the stake. **Last frame** states the ask and the source.

## Steps

1. **Write the long text first.** `outputs/<post>/stories.md`, numbered paragraphs. Do not design yet.
2. **Mark the seams.** Where does the argument change gear? Those are the frame breaks.
3. **Give each frame one job:**
   - frame 1: why this exists,
   - frames 2–4: the record,
   - frame 5: the turn,
   - frame 6: the demand and the source.
4. **Cut 20%.** Stories are read at thumb speed. If a sentence does not change the reader's mind or move the story, cut it.
5. **Write the frame brief.** `templates/story/example.yml`:

   ```yaml
   slug: post-04-stories
   part: "PART 1 OF 2"
   frames:
     - index: "1/6"
       kicker: DAY 1
       headline: "NOT A SINGLE / STEP BACK."
       body: "2 Nov 2026. The Director met students."
       prompt: "CONTINUE →"
   ```

6. **Render.**

   ```bash
   ruby tools/render/carousel.rb templates/story/example.yml --size 1080x1920
   ```

7. **Check on a phone-sized preview.** Headline ≥ 64 px, body ≥ 28 px, contrast ≥ 4.5:1.

## Copy rules

- Short sentences. One idea each.
- No paragraph longer than four lines.
- Keep the caveats; a story is not a licence to overstate.
- No quotation marks around a paraphrase.
- Bleep profanity as `sh*t`.
- Every factual frame has a source in the claim table, even if the source is only on the last frame.

## Never

- Never put more than ~90 words on a frame.
- Never use a face without consent.
- Never end without the ask.
- Never publish a story frame that is not in the claim table.

## Done when

- frames are numbered and prompted,
- the last frame carries the ask and the source,
- the long text is in `stories.md`,
- the claim table covers every factual frame.
