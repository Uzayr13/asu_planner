# ASU Digital Planner 2027 · المفكرة الرقمية

Bilingual (Arabic/English) Flutter planner for the Arabic Speaking Union – Mauritius.
See `planner-app-spec.md` for the full spec.

## Run

All six platform folders are present (`android/`, `ios/`, `macos/`, `web/`,
`windows/`, `linux/`). No `flutter create` step is needed.

```bash
flutter pub get
flutter test          # date-math + layout smoke tests
flutter run           # picks a connected device
```

Web is the fastest way to see it in a browser:

```bash
flutter run -d web-server --web-port 8080 --web-hostname 127.0.0.1
```

Desktop runners are generated but must be built on their own OS —
`flutter build windows` on Windows, `flutter build linux` on Linux.

## Reverting

Every change is its own commit, tagged and pushed, so you can go back to any
point by name:

```bash
git tag --list 'v*'      # see the list
git checkout v0.2.4      # the state where the month grid first fitted the viewport
git revert <commit>      # undo just that one change
```

The version in `pubspec.yaml` is the single source of truth and bumps with each
tag.

## Responsive layout

The planner fits 320pt phones through desktop and web, portrait and landscape.
`lib/layout/layout.dart` is the single authority for that: width bands, spacing
tokens, and the formulas for month row height, mini-month markers and habit
dots. Breakpoints only change structure; everything else derives from the
available space.

`tool/screenshot_matrix.mjs` screenshots every view at ten viewport sizes into
`shots/` — the only visual regression check, since the UI renders to canvas and
cannot be asserted on directly.

## Structure

```text
lib/
  main.dart               app shell, cover, bottom view bar (Year/Month/Week/Day/Notes/Words)
  theme.dart              colours + fonts (Playfair / Lato / Amiri / Noto Naskh)
  store.dart              shared_preferences autosave (all user text + toggles)
  data/content.dart       months, days, the 12 Words of the Month, ASU events
  data/holidays.dart      Mauritius public holidays 2027
  audio/word_audio.dart   "Hear now" playback (looks for recordings in assets/audio/words)
  widgets/holiday_widgets.dart  holiday list card + day labels
  data/calendar_math.dart Monday-first grid, ISO weeks, 53 planner weeks
  widgets/common.dart     tabs, footer, headers, EditableBox, WordCard
  pages/                  cover, year, month, week, day, notes, words
```

## Views (2027 only)

| View | Swipe through | Tap to go deeper |
|---|---|---|
| Month | 12 months | date number -> Day view |
| Week | 53 weeks (Week 1 = 28 Dec 2026 - 3 Jan 2027, days outside 2027 greyed) | day name -> Day view |
| Day | 365 days | - |

The selected date is shared: swiping in one view and switching to another opens
the same date. The day note is stored once (`day:<date>`), so it shows identically
in the Month cell, the Week row and the Day page.

## Public holidays 2027

16 days in `lib/data/holidays.dart`, from the Cabinet decision of 28 Aug 2026
(15 holidays; Ganesh Chaturthi falls on a Sunday so Mon 6 Sep is also off).
They show in red: tinted day cells with the name (Month/Week), red circles in the
Year view, a list under each month, and a banner on the Day page.
**Eid-Ul-Fitr (10 Mar) is provisional** (moon sighting) and is marked with `*`.
Arabic holiday names are drafts for the ASU team to review. Verify the list
against the Government Information Service / Gazette before release.
World Arabic Language Day (18 Dec) is shown in gold as an ASU event, not a holiday.

## Word of the Month audio

Each word card has a **Hear now / استمع** button. Add recordings to
`assets/audio/words/` named `01.mp3` ... `12.mp3` (see the README.txt there).
No code change is needed: until a file exists the button says "Recording coming soon".

## Known gaps / next steps

- **Fonts load via `google_fonts` at runtime.** For true offline use, download the
  four families into `assets/fonts/`, declare them in `pubspec.yaml`, and set
  `GoogleFonts.config.allowRuntimeFetching = false`.
- **Word of the Month:** all 12 are filled in from the design reference. Have the ASU
  team proof-read the Arabic diacritics and notes in `lib/data/content.dart`.
- Page layouts follow the screenshots by eye; compare on a device and fine-tune spacing.
- Not yet built (Phase 2): reminders, PDF export, streak counter, backup/sync.
