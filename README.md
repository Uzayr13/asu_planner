# ASU Digital Planner 2027 · المفكرة الرقمية

Bilingual (Arabic/English) Flutter planner for the Arabic Speaking Union – Mauritius.
See `planner-app-spec.md` for the full spec.

## Supported platforms

| Platform | How it ships | Notes |
|---|---|---|
| **Web** | Hosted URL | Primary channel. No install |
| **iOS** | Web app, Add to Home Screen | Not a native app. See the storage note below |
| **macOS** | Web app in a browser, or Add to Dock | Not a native app |
| **Android** | Sideload APK + web fallback | Native. Enable install from unknown sources |
| **Windows** | Native zip + web fallback | Native. Built in CI |
| **Linux** | — | **Deliberately out of scope** |

iOS and macOS deliberately have **no native build**. Reaching them as web apps
avoids a full Xcode install, code signing, and the 7-day expiry free Apple IDs
impose. WebKit exempts home-screen web apps from its 7-day storage eviction, so
planner notes survive — **users must add the app to the home screen**. Opening
it in a Safari tab alone is not safe: Safari website data is deleted after
seven days without interaction.

## Run

```bash
flutter pub get
flutter test          # date-math + layout smoke tests
flutter run           # picks a connected device
```

Web is the fastest way to see it in a browser:

```bash
flutter run -d web-server --web-port 8080 --web-hostname 127.0.0.1
```

Note that a debug web build sits blank for ~8s while it compiles; the release
build below paints in about 2s.

## Build for distribution

```bash
zsh tool/build_web.sh             # web   -> build/web
flutter build apk --release       # android -> app-release.apk
flutter build windows --release   # windows -> build/windows/x64/runner/Release
```

Use `tool/build_web.sh` rather than a bare `flutter build web` — it passes
`--no-web-resources-cdn`, without which the app fetches its renderer from
`www.gstatic.com` and renders a **blank page** wherever that host is
unreachable. The script output makes zero external requests.

### How a user gets it

| Platform | Give them | Caveat |
|---|---|---|
| Web | The URL | Easiest. Add to Home Screen on iOS |
| Android | The APK | Must enable install from unknown sources |
| Windows | Zip the release folder | SmartScreen warns first run — More info → Run anyway |
| macOS | Open the URL | Add to Dock for an app-like window |
| iOS | The URL | **Add to Home Screen.** No native app exists |

Android release builds are signed with a real keystore configured in
`android/key.properties` (see `android/key.properties.example`). Without that
file the build falls back to debug signing and is for local testing only.

### CI

`.github/workflows/build.yml` builds web, Android and Windows on every push and
runs the tests first. Windows can only be compiled on a Windows runner, so CI
is the only place it is proven. Each green run attaches the three artifacts
(`web`, `android-apk`, `windows-zip`), downloadable from the run's Artifacts
section for 90 days.

### Hosting the web build privately

The build is a static folder — `build/web` — with **zero external requests**, so
it can go anywhere you control. GitHub Pages is deliberately **not** used: a
`github.io` URL is public regardless of this repo being private, and the planner
content is ASU's. Private options:

- **Any static host behind auth** — nginx, Caddy or a NAS on a LAN or VPN.
  Serve `build/web` as the document root.
- **Netlify / Cloudflare Access** — password-protect or gate the site behind
  your team's login. Free tiers cover both.
- **A private server** — `python3 -m http.server 8080 --directory build/web` is
  enough for a trusted network.

Whatever you pick, the base href must match where it is served. Build with
`sh tool/build_web.sh /` for a domain root, or `sh tool/build_web.sh /some/path/`
for a subpath.

## Install and offline

The web build is installable and works with no network. Flutter 3.47 ships a
service worker that unregisters itself, so this is done by two files of our
own: `web/sw.js` (a real offline-first worker) and `web/flutter_bootstrap.js`
(registers it, and deliberately omits `serviceWorkerSettings` — that path is
deprecated and would register Flutter's stub over ours).

**On iOS and macOS — Add to Home Screen.** Share → Add to Home Screen. This is
not optional: Safari deletes website data after seven days in a normal tab, and
only a home-screen install is exempt. The app says this once on first visit.

**On Android** the browser offers Install, or Settings has the APK.
**On Windows** Settings has the zip, or just use the web build.

After the first visit the app runs from cache — including the fonts and the
CanvasKit renderer — so it opens with no connection. A new build replaces the
cache on the next online visit.

Verify the offline claim any time:

```bash
sh tool/build_web.sh /
python3 -m http.server 8080 --directory build/web &
node tool/offline_check.mjs
```

It warms the cache, kills the server, reloads, and fails unless the app renders.

## Security

**What this app is.** Notes are stored on your device and nowhere else. There is
no server, no account, and nothing is uploaded. The web build makes **zero
external requests** — fonts and the renderer are bundled — so there is no third
party in the path at all. Text is drawn to a canvas rather than the DOM, so
notes cannot be interpreted as markup.

**What it is not.** There is no app lock. Anyone who can unlock the device or
open the browser profile can read the notes. That is the main gap, and it is the
next thing worth building.

**Backups are the trust boundary.** Importing a JSON file writes into the
store. The parser rejects files that are oversized, malformed, from a future
format version, or that try to write reserved `backup:`/`ui:` keys; nothing is
applied unless the whole file validates, and a snapshot is taken first. Still:
import a file only from someone you trust.

**Signing keys.** The Android release keystore lives outside the repo in
`android/key.properties` (gitignored). Back it up — losing it means users
cannot update without uninstalling, which erases their notes.

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
  layout/layout.dart      the one authority for breakpoints, spacing and row heights
  backup/backup.dart      pure-Dart JSON encode / decode / merge for notes
  backup/backup_io.dart   the thin file-picker edge
  data/content.dart       months, days, the 12 Words of the Month, ASU events
  data/holidays.dart      Mauritius public holidays 2027
  audio/word_audio.dart   "Hear now" playback (looks for recordings in assets/audio/words)
  widgets/holiday_widgets.dart  holiday list card + day labels
  data/calendar_math.dart Monday-first grid, ISO weeks, 53 planner weeks
  widgets/common.dart     tabs, footer, headers, EditableBox, WordCard
  pages/                  cover, year, month, week, day, notes, words, settings, welcome notice

web/
  sw.js                   offline-first service worker
  flutter_bootstrap.js    loader; registers sw.js, leaves Flutter's stub alone
tool/
  build_web.sh            the canonical web release build
  offline_check.mjs       proves the app renders with no server
  screenshot_matrix.mjs   screenshots every view at ten viewport sizes
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

## Backup and restore

The gear on the bottom view bar opens Settings. From there you can move notes
between devices or keep a copy safe.

**To move to a new device**

1. Old device: **Export my notes** → save the `.json` somewhere both devices can
   reach (Drive, email it to yourself, USB).
2. New device: open or install the app → **Import from a file** → pick that file.

Every note travels: day notes, both notes pages, the vocabulary table, week and
day priorities, the schedule, habit dots and checkboxes. The same file works
across platforms — export from the Android APK and import into the web app.

**What import does**

Importing **merges**, it never wipes the device. Where both have a note for the
same key, the **backup wins**. Anything the device has that the file does not
mention is left alone. Before anything is written, a snapshot of the current
notes is kept and the app tells you what will change ("12 to add · 3 to
replace").

**If an import goes wrong**

**Restore snapshot** puts things back. It is a swap: restoring makes the state
it replaced the new snapshot, so tapping restore again undoes the restore.
Note the slot is one-deep — a second import overwrites it. For a permanent copy
keep the exported `.json` file, which is why the sheet says to export before
importing.

**Not automatic sync.** Export copies the data at that moment; it does not link
devices. If you re-import an old file later, it overwrites whatever you changed
since. The habit that avoids surprises: export just before you switch, import
just after.

## Known gaps / next steps

- **No automatic sync.** Notes are local; moving devices means export then
  import (see Backup and restore). PDF export and cloud sync remain Phase 2 in
  the spec.
- **Word of the Month:** all 12 are filled in from the design reference. Have the
  ASU team proof-read the Arabic diacritics and notes in `lib/data/content.dart`.
- **Eid-Ul-Fitr (10 Mar 2027) is provisional** (moon sighting) and the Arabic
  holiday names are drafts. Verify against the Gazette before release.
- **Audio recordings** for Word of the Month are not present; add
  `assets/audio/words/01.mp3`…`12.mp3` and the button starts working with no
  code change.
- Page layouts follow the screenshots by eye; compare on a device and fine-tune spacing.
- Not yet built (Phase 2): reminders, PDF export, streak counter, backup/sync.
- **It is a 2027 planner.** `planYear` and the holiday table are hardcoded;
  2028 needs new data and a re-check of the 53-week maths.
