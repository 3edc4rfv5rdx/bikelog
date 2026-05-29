# CHANGELOG
> N=new feature, E=error fix, F=fine-tune, R=refactor, I=infrastructure, T=tag

## Audit (2026-05-29)
- E: Block deleting a type/event still referenced by bikes/actions (tofix1 #7)
- F: Derive Linux paths from $HOME instead of hardcoded /home/e/Documents (tofix1 #16)
- F: Unify date-picker bounds via datePickerFirstDate/LastDate (1900..today) (tofix1 #22)
- E: Add missing "Build number" RU/UA translation shown in About (tofix1 #21 partial)
- R: Remove dead code: getDbOne, 6 unused date helpers, StringExtension, strCleanAndEscape (tofix1 #18)
- F: Replace deprecated Color.withOpacity with withValues(alpha:) (tofix1 #26)
- R: Remove redundant no-op setKey('.First start','true') in first-run flow (tofix1 #20)
- E: Protect default type #1 from deletion via Save in reference editor (tofix1 #6)
- E: Serialize all main-DB access to prevent concurrent "database is locked" (tofix1 #4, #5)
- E: Fix filter comment search — bind as SQL parameter, drop double-escaping (tofix1 #2, #3)
- E: Fix Options save dropping hidden settings (.PIN code etc.) from memory (tofix1 #1)

## v0.9.260324+57
- E: Fix photo icon tap requiring double tap in bike list (GestureDetector → IconButton)
- N: Swipe gestures on action list (right=edit, left=delete)

## Audit (2026-03-12)
- E: Fix copy-paste error in 02-RelUpload.sh: "shopper" → "bikelog" in comment
- F: Translate Russian comments to English in 00-Make.sh and pubspec.yaml
- F: Remove unused imports, variables, and dead code (fix all analyzer warnings)
- E: Fix Ukrainian translation: "owners" was mistranslated as "bicycles" in locales.json
- R: Remove duplicate initializeIni() from main.dart (already in db_helpers.dart)
- E: Use parameterized queries in bikes, references, CSV restore, and writeRef (prevent SQL injection)
- E: Fix missing comma in actions table FK definition; add indexes on foreign keys and date
- R: Split globals.dart into modules: db_helpers.dart, ui_helpers.dart, date_helpers.dart (via export)
- R: Consolidate 6 SnackBar functions into one okInfoBar() with color shortcuts

## Audit (2026-03-11)
- I: Move key.properties reference to ~/.my-safe/ (external secure storage)
- F: Translate Russian comment to English in build.gradle.kts
- R: Translate all Russian comments to English in all Dart files (9 files, 217 lines)
- F: Move backup directory from Download to Documents, fix "Bakup" typo
- E: Fix SQL injection: escape user input in filter comment, bike photo; add parameterized query support to getDbData/setDbData
- E: Fix SQL JOIN order in bike_log_screen (bikes before owners)
- E: Add null safety check in _deleteOwnerWithData (empty list guard)
- E: Show error to user on CSV restore failure (was silent)
- R: Extract common TextStyle into tsNormal/tsLarge getters, remove ~200 lines of duplication
