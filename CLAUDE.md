# BikeLog project rules

Flutter / Dart Android app. SQLite via `sqflite`. Single-package `lib/` layout.

## Build / install
- Release-only workflow. Use the numbered scripts (do not run `flutter build`
  manually):
  - `00-Make.sh` — build APK splits, auto-bump version code, archive
  - `98-InstallAPK.sh` — install latest `Bike*.apkx` on the device via adb
  - `01-PushTag.sh` / `02-RelUpload.sh` — tag and publish
- The build/version number lives in **two** places that must stay in sync:
  `version:` in `pubspec.yaml` and `progVersion` / `buildNumber` in
  `lib/globals.dart`. `00-Make.sh` owns both — never bump them by hand. When
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
  `## vX.Y.ZZZZZZ+NN` (a released tag) — nothing else. At tag time
  `01-PushTag.sh` renames `## Unreleased` to the release version and opens a
  fresh empty `## Unreleased` above it; `02-RelUpload.sh` reads the release
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
