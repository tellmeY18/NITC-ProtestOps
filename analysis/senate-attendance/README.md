# Senate representation of SAC office bearers

A short, checkable note on a claim made in the 2 November 2026 meeting: that the SAC's office bearers had no place in the Senate, so a separate student body was needed to represent students there.

The record says the opposite. The 2008 constitution put the student office bearers in the Senate. The 2024 text removed them. No Senate minute records the removal.

## 1. The 2008 text

**SAC Constitution, Ch. II, §8(A)** provides that the General Secretary, Academic Affairs Secretary and Cultural Affairs Secretary represent the General Student Body in the Institute Senate.

That is not an invitation. It is a constitutional seat.

## 2. The 2024 text

The SGB Constitution contains no equivalent provision. The student office bearers are not given Senate representation. The change is not mentioned in the SGB text as a change; the clause is simply absent.

## 3. What the minutes show

SAC office bearers appear as invitees in the Senate minutes from the **87th meeting (14 July 2022)** through the **95th meeting (11 January 2024)**. From the **96th meeting (8 May 2024)** through the **103rd meeting (17 November 2025)** they do not appear.

| Senate meeting | Date | SAC office bearers present |
|---|---|---|
| 87th | 14 Jul 2022 | yes |
| 88th–95th | 2022–11 Jan 2024 | yes (88th and 89th attendance unreadable) |
| 96th | 8 May 2024 | no |
| 97th–103rd | 2024–17 Nov 2025 | no |

## 4. What the minutes do not show

No published Senate minute records a decision to remove the office bearers from the Senate. The change appears in the 2024 text without a recorded vote.

This matters because the 2008 text requires Senate approval for amendments (Ch. VIII). A body cannot be removed from a room by a document that the room never approved.

## 5. Caveats

- Senate 88 and 89 have broken font encoding; their attendance lists are unreadable and are excluded from the count.
- Senate 104–106 are partly broken (HTML error pages, then garbled text). The series is reliable through the 103rd meeting.
- "Invitee" is the category in the attendance report. The 2008 clause is stronger than an invitation; the minutes record the practice, the constitution records the right.
- The raw minutes contain personal data and are git-ignored. Only the aggregate finding is published here.

## 6. How to re-check

1. Scrape the Senate index into `research/senate/` (`ruby tools/scrape/senate.rb`).
2. Extract the attendance pages (`ruby tools/parse/pdftext.rb`).
3. Search each meeting for the office-bearer titles.
4. Record the meeting number, date and presence in a table like the one above.
5. Do not commit the raw text.

## The claim, at its weakest defensible strength

> The 2008 SAC Constitution gave the General Secretary, Academic Affairs Secretary and Cultural Affairs Secretary seats in the Institute Senate. The 2024 SGB Constitution does not. The published minutes show the office bearers present from the 87th through the 95th meeting and absent from the 96th onward. No published minute records the removal.

That is the claim. It is narrower than "the administration silenced students in the Senate", and it is much harder to answer.
