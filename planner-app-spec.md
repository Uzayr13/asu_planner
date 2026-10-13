# Digital Planner App: Product & Technical Spec

**Working title:** Digital Planner 2027 / المفكرة الرقمية
**Publisher:** Arabic Speaking Union – Mauritius (اتحاد متحدثي اللغة العربية – موريشيوس)
**Languages:** Arabic (RTL) + English (LTR), shown together on every page
**Draft date:** 12 Oct 2026

---

## 1. Overview

A bilingual (Arabic/English) digital planner for 2027. It reproduces the look and feel of a printed planner: a cover, a year overview, 12 month pages, 53 weekly pages, notes pages and a vocabulary log. Every page is editable by tap. The goal is to help people plan their year while learning a little Arabic every day.

**Target users:** Arabic learners and speakers in Mauritius, and ASU members and students.

**Core idea:** a planner plus a gentle daily Arabic-learning habit ("One Arabic word a day", "Word of the month", "Words I learned").

---

## 2. Reference Document Structure (70 pages)

| Page | Screen | Notes |
|---|---|---|
| 1 | Cover | Branded artwork, no editing |
| 2 | Year at a Glance | 12 mini calendars, event banner |
| 3–14 | Month pages (Jan–Dec) | Grid calendar + Word of the Month |
| 15–67 | Week pages (Week 53 of 2026 to the last week of 2027) | Priorities, daily lines, word habit tracker |
| 68–69 | Notes (Page 1, Page 2) | Lined free-writing |
| 70 | Words I Learned | 4-column vocabulary table |

*The reference starts with "Week 53" (28 Dec 2026 – 3 Jan 2027), so the week list includes the spillover week from 2026. Confirm the intended week numbering (ISO 8601 vs. custom).*

---

## 3. Global UI Elements (on every page)

### 3.1 Month tab bar (top)
- 12 pills: JAN FEB MAR APR MAY JUN JUL AUG SEP OCT NOV DEC.
- The active month is filled navy with white text. Inactive pills are beige.
- Tap jumps to that month's page. On week pages the tab highlights the month of the week's start date.

### 3.2 Footer navigation (bottom)
- Left: `Year · Weeks · Notes · Words`, in gold text. Each item is a jump link.
- Center: page number.
- Right: org name in Arabic, `اتحاد متحدثي اللغة العربية - موريشيوس`.
- Thin divider line above.

### 3.3 Section header pattern
- Large serif title in English (navy), e.g. "January".
- Arabic title on the opposite side in gold calligraphic type, e.g. يناير.
- Subtitle in letter-spaced caps (e.g. `2027`) and Arabic-Indic numerals (٢٠٢٧).
- A gold dotted/dashed divider below the header.

### 3.4 Editable fields
- Any input area is a tappable box with a light blue-grey fill.
- Tapping opens a text editor (keyboard or stylus) that saves on blur.
- Helper text under grids: *"Week starts on Monday. Tap a day to type in it."* and *"Tap a month to open it. On any page, tap a box to type in it."*

---

## 4. Screens

### 4.1 Cover
- Dark navy background with a faint repeating gold Islamic geometric pattern (8-point star in square).
- Center emblem: a rotated gold square, with a circle holding **٢٠٢٧** in gold.
- Title: **المفكرة الرقمية** (large, silver) and `DIGITAL PLANNER 2027` (letter-spaced gold caps).
- Subtitle: `Arabic · English`.
- Illustration: mountain silhouette, gold sun/moon, layered teal wave bands (Mauritius coast).
- Bottom: org name in Arabic and English (`ARABIC SPEAKING UNION - MAURITIUS`).
- Tap or scroll to enter the planner.

### 4.2 Year at a Glance
- Header: `2027` / `YEAR AT A GLANCE` (left), ٢٠٢٧ / نظرة على السنة (right).
- 3×4 grid of mini month calendars. Each has an English and an Arabic month name, Mon–Sun columns, and Sat/Sun numbers in gold.
- Tap a month to open its month page.
- Highlight card: **18 December: World Arabic Language Day** / اليوم العالمي للغة العربية. 18 Dec is marked with a gold filled circle in the December mini calendar.

### 4.3 Month Page
- Header with English and Arabic month name and year.
- Calendar grid: a navy header row with `MON … SUN` and the Arabic day names (الإثنين … الأحد). Days outside the month are greyed and non-editable.
- Each day cell shows the date number and an editable text area. Tapping opens a day editor.
- **Word of the Month card** (navy, rounded):
  - Label `WORD OF THE MONTH`
  - English word (e.g. *Sugar*) and transliteration (*sukkar · sugar*)
  - `French:` equivalent (*sucre*)
  - One-line cultural or etymology note
  - Large gold Arabic calligraphy of the word with diacritics (سُكَّر), over a faint geometric pattern
- Sample data: Jan = Sugar (سُكَّر), plus the Ḍād card (الضاد) in the reference's second Word of the Month card, which suggests a 12-word content set to confirm.

### 4.4 Week Page
- Header: `Week 53` and the date range `28 DEC 2026 – 3 JAN 2027`. Arabic: الأسبوع ٥٣ plus the Arabic-numeral date range.
- **Priorities box:** 3 checkbox rows with editable text.
- **Compact Word of the Month card** (same word as the current month).
- **Daily rows (Mon–Sun):** English day and date on the left, Arabic day name and Arabic-Indic date number on the right, and a lined writing area in the middle. Saturday and Sunday labels are in gold.
- **"One Arabic word a day" tracker:** 7 circular toggles (M T W T F S S). Tapping marks the day as done. Add a streak count (see Phase 2).

### 4.5 Notes Pages
- Header: `Notes` / ملاحظات with `PAGE 1`, `PAGE 2` and so on.
- Full-page ruled lines; free text.
- Ship 2 pages by default and allow users to add more.

### 4.6 Words I Learned (كلماتي)
- Header: `Words` / `I LEARNED IN 2027` / كلمات تعلّمتها.
- 4-column table with a navy header row: **الكلمة** (Arabic word) · **Meaning** · **Where I heard it** · **Date**.
- About 13 visible rows per page. Allow adding rows or pages.
- Phase 2: optional flashcard review from this list.

---

## 5. Design System

| Token | Value (approx., from screenshots) |
|---|---|
| Navy (primary) | `#12223F` |
| Gold (accent) | `#8B6F2E` / bright `#C9A24A` |
| Teal (cover waves) | `#1B5160` → `#0F3640` |
| Paper / beige | `#E8E4D6` |
| Input fill | light blue-grey `#C9D0E0` at ~60% opacity |
| Weekend text | gold |

- **Typography:** an elegant serif display (a Playfair Display-style face) for English titles, a clean humanist sans (Lato-style) for UI, and a Naskh/Kufi calligraphic face for Arabic titles (e.g. Amiri, Noto Naskh Arabic, Aref Ruqaa).
- **Motifs:** an 8-point star pattern, a dotted gold divider, rounded cards (16 px radius) and pill tabs.
- **Dark mode:** optional. The cover is already dark, so keep navy as the base.

---

## 6. Functional Requirements

### Must have (MVP)
1. All screens in §4, in the same order, with the global tab bar and footer.
2. Tap-to-edit on every field, with auto-save to local storage.
3. Correct 2027 calendar, Monday start, with week numbers and spillover days.
4. Full bilingual rendering: RTL Arabic text, Arabic-Indic numerals (٠١٢٣٤٥٦٧٨٩) alongside Western numerals, and correct diacritics on calligraphy words.
5. Internal navigation (jump links, month tabs, tap a mini month).
6. Highlight for 18 Dec and for today's date.
7. Offline-first: works without network.
8. Word of the Month content for all 12 months (data-driven, not hard-coded).

### Should have (Phase 2)
- Reminders and notifications for days and priorities.
- Daily "Arabic word" push notification and streak counter.
- Export or share a page as PDF or image.
- Cloud backup and sync across devices (account or anonymous ID).
- Search across notes and words.
- Handwriting or stylus input (pen layer) on tablets.
- Audio pronunciation for each word.

### Could have
- Hijri date overlay and Islamic/Mauritian public holidays.
- Flashcards and quizzes generated from "Words I learned".
- A language switch for the UI chrome (English-only, Arabic-only or both).
- Themes (e.g. a light cover variant).

---

## 7. Data Model (sketch)

```text
PlannerYear { year: 2027, weekStart: "MON", locale: ["ar","en"] }

DayEntry     { date: "2027-01-04", text: string, updatedAt }
WeekEntry    { weekId: "2027-W01", priorities: [{text, done}x3],
               dayLines: {mon..sun: string},
               wordHabit: {mon..sun: bool} }
NoteLine     { pageIndex, content: string }          // per notes page
LearnedWord  { id, arabic, meaning, whereHeard, date }
MonthWord    { month: 1..12, en, translit, fr, noteEn, arabicDisplay, noteAr? }
Event        { date, titleEn, titleAr }              // e.g. 2027-12-18
```

Static content (month words, events, Arabic day and month names) lives in a bundled JSON file. User-entered data is stored in a local database (SQLite, Isar or IndexedDB) and optionally synced.

---

## 8. Suggested Tech Stack

Pick one:

- **Flutter** (recommended): strong RTL and custom-font support, one codebase for Android, iOS and tablet, and a good fit for the custom ornamental UI. Storage: Isar or Drift (SQLite). PDF export: `pdf` and `printing` packages.
- **React Native (Expo):** if the team is JS-first. Use `react-native-svg` for the geometric patterns.
- **PWA (React/Vue + IndexedDB):** the fastest to ship and distribute through a link, with weaker offline polish.

Common libraries: an i18n/RTL layer (`intl`, `flutter_localizations`), a local notifications package, and an SVG renderer for the pattern backgrounds and emblem.

---

## 9. Non-Functional Requirements

- **Performance:** 70+ pages render lazily. The first paint should take under 2 s on mid-range Android.
- **Accessibility:** minimum 4.5:1 text contrast (check gold on beige), scalable fonts, screen-reader labels in both languages, and 44 px minimum tap targets.
- **Privacy:** no account is required for MVP, and user text stays on-device unless sync is enabled.
- **Platforms:** Android first (the reference screenshots are Android), then iOS and tablet.

---

## 10. Milestones

| Phase | Scope | Rough time |
|---|---|---|
| 0 | Design system, fonts, SVG assets, content JSON | 1–2 wks |
| 1 | Cover, Year, Month, navigation, local storage | 3 wks |
| 2 | Weeks (53), Notes, Words, habit tracker | 3 wks |
| 3 | Reminders, PDF export, polish, QA | 2 wks |
| 4 | Backup/sync, audio, flashcards (optional) | TBD |

---

## 11. Open Questions

1. Is this a **one-year (2027) product** or a template that regenerates each year?
2. Is week numbering **ISO** (so that 28 Dec 2026 is week 53) or custom?
3. Who supplies the **Word of the Month** content for all 12 months (Arabic, transliteration, French, notes)?
4. Should **Hijri dates and holidays** be included?
5. Is **handwriting/stylus** support needed, or typed input only?
6. Free app, paid app, or members-only distribution?
7. Do we need **French** UI text in addition to Arabic and English? The cards include French equivalents.

---

## 12. Acceptance Criteria (MVP)

- [ ] All 70 pages are reachable, with page numbers and footer links working.
- [ ] Every date in 2027 maps to the correct weekday, month cell and week page.
- [ ] Text typed in any field persists after the app is closed and reopened.
- [ ] Arabic text renders RTL with correct letter shaping and diacritics on all screens.
- [ ] 18 Dec 2027 is highlighted on both the year and December views.
- [ ] The app is fully usable in airplane mode.
