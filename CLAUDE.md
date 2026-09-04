# BikeLog project rules

Flutter / Dart app for Android and Linux desktop. SQLite via `sqflite` on
Android and `sqflite_common_ffi` on the desktop. Single-package `lib/` layout.

## Build / install
- Release-only workflow. Use the numbered scripts (do not run `flutter build`
  manually):
  - `00-MakeAll.sh` — the whole run: build, install on emulator and phone, link OUT/
  - `05-Lint.sh` / `06-Test.sh` — analyze and run the tests
  - `10-MakeRelease.sh` — build the release APK splits and auto-bump the version
  - `11-EmulRELEASE.sh` / `12-PhoneRELEASE.sh` — install the fresh release on the
    emulator / on a physical phone
  - `13-MakeLinux.sh` / `14-MakeAppImage.sh` — the Linux desktop build: the
    bundle, and the same bundle packed into one AppImage. Both ship without the
    execute bit and are commented out in `00-MakeAll.sh`: the desktop build is
    slow and needs the clang/GTK toolchain, so it is run by hand when a Linux
    artifact is wanted. `19-LinkOut.sh` and `22-RelUpload.sh` pick the AppImage
    up when there is one and say so when there is not.
  - `19-LinkOut.sh` — link the arm64 and universal APKs, and the AppImage if one
    was built, into `OUT/` under their own names, sweeping whatever else was there
  - `20-MakeTag.sh` — stamp the changelog and create the tag locally
  - `21-PushTag.sh` — push the branch and the tag
  - `22-RelUpload.sh` — publish the GitHub release with the APKs attached
  - `98-InstallAPK.sh` — install the newest `*.apkx` on every attached device
  - `99-CopyToAPKX.sh` — link the arm64 APK next to the sources as `*.apkx`
- Artifacts carry one name across every project here:
  `bikelog-<version>-<build>-<abi>.apk`, and the tag is `v<version>-<build>`.
- The build/version number lives in **two** places that must stay in sync:
  `version:` in `pubspec.yaml` and `progVersion` / `buildNumber` in
  `lib/globals.dart`. `10-MakeRelease.sh` owns both — never bump them by hand. When
  committing other changes, do stage them along if they show as modified, so the
  repo version stays in sync with the artifact.
- Never build or install automatically. Make code changes only; the user builds
  and installs.

## Language
- All code, comments, commit messages, and repo docs (`.md` / `.txt`) are English.
- Only UI-facing strings are localized via `lw()`, backed by `assets/locales.json`.
- Localization files hold clean strings only (no trailing punctuation). Add any
  punctuation in code.

## CHANGELOG.md
- One short English line per entry, type tag prefix with colon:
  `N:` new feature, `E:` error fix, `F:` fine-tune, `R:` refactor,
  `I:` infrastructure, `T:` tag.
- Entries for unreleased work go under the topmost `## Unreleased` section,
  newest first. Do not sort by tag.
- Section headings are either `## Unreleased` (work in progress) or
  `## v<major>.<minor>.<date>-<build>` (a released tag) — nothing else. At tag time
  `20-MakeTag.sh` renames `## Unreleased` to the release version and opens a
  fresh empty `## Unreleased` above it; `22-RelUpload.sh` reads the release
  notes from that `## vX...` section. Don't stamp versions by hand.
- Write the entry **only at commit time**, in the same commit as the code change.
  Skip during implementation. Every commit MUST include a CHANGELOG.md update.

## Tracking docs (ADD/tofix*.md, etc.)
- Always re-read the relevant section before implementing — don't make the user
  repeat what's already documented.
- ToFix entries can be stale. Before touching anything, verify the described bug
  still reproduces in the current code (read the cited file/lines and confirm the
  symptom is real). If it's already fixed or no longer applies, report that
  instead of re-fixing.
- When an item ships end-to-end, prefix its heading with a leading ✅, in the same
  commit as the fix:
  - `### ✅ 4. waitForMainDb() is called without await`

## Working style
- Respond in Russian. Do exactly what's asked — minimal diff, no adjacent
  refactors, no library/component swaps. If a different approach looks better,
  propose it in text first ("предлагаю X вместо Y потому что Z — делать?") and
  wait for approval.
- One-sentence proactive observations are welcome (UX copy gap, data-integrity
  risk worth checking, next step). Surface, don't auto-fix.
- Never commit. Only commit when the user explicitly says so ("запиши", "коммит",
  "commit").
- Reuse shared code first. Check `lib/globals.dart`, `lib/ui_helpers.dart`,
  `lib/db_helpers.dart`, and `lib/date_helpers.dart` (all re-exported through
  `globals.dart`) before writing inline UI or queries. Extract early when a
  pattern repeats — no duplication between screens.
- All DB access goes through the helpers in `db_helpers.dart`
  (`getDbData`/`setDbData`/…). Use parameterized queries (`?` + args) for any
  user-supplied value; never concatenate user input into SQL.

## UI rules
- Theme everything. Never hardcode colors, font sizes, or weights — use the
  globals from `lib/globals.dart`:
  - Colors: `clText`, `clUpBar`, `clMenu`, `clSel`, `clFill`, `clFrame`,
    `clFon` (screen background), `clRed`
  - Sizes: `fsSmall`, `fsNormal`, `fsLarge`
  - Weights: `fwNormal`, `fwBold`
  - Prefer the shared text styles `tsNormal` / `tsLarge` for body/headers.
- Reuse the common dialogs/snackbars in `ui_helpers.dart` instead of building
  new ones: `okConfirm`, `showCustomDialog`, `okInfo` / `okErr` / `okWarning` /
  `okSuccess`, the `okInfoBar*` colored snackbars, and `showPinDialog`.
- Dialog action buttons follow the existing convention: a styled `TextButton`
  with `backgroundColor: clUpBar`, `foregroundColor: clText`, and
  `RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))`. Style the
  Cancel/No button the same way. (Match `okConfirm` in `ui_helpers.dart`.)
- All UI strings (labels, buttons, snackbars, dialog titles) are maximally short
  and passed through `lw()`. "Изменить" not "Редактировать".
- Long-press on a control opens its contextual help via `okHelp(<id>)` — keep
  this pattern when adding controls.
