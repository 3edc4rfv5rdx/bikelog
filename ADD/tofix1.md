# BikeLog — Code Audit Findings (tofix1)

Each item below is a self-contained prompt for an LLM coding agent. Fix one at a
time, verify, and update `CHANGELOG.md` in the same commit. File/line references
are from the audited revision (build +60) and may drift slightly.

---

## CRITICAL

### ✅ 1. Options save destroys hidden settings in memory
In `lib/options_settings_screen.dart`, `saveChanges()` does
`xdef = Map.from(_xdef);` (~line 91). But `_xdef` was built in `initState` by
filtering out every key starting with `.` (lines 24–26). As a result the
in-memory `xdef` loses `.PIN code`, `.First start`, and `.Prog version` after the
user saves Options (only `.Date format` and `.Date separator` are re-added on
lines 93–94). This breaks PIN verification within the same session (the verify
path compares `pin == xdef['.PIN code']`, which becomes `null`), and corrupts
other hidden state until the next restart reloads from the DB.
Fix: do not replace the whole `xdef` map. Instead update only the visible keys
in place (e.g. iterate `_xdef.entries` and assign `xdef[key] = value`), preserving
all dotted keys. Confirm `.PIN code` survives a save/return cycle.

### ✅ 2. Filter comment is escaped twice
In `lib/filter_screen.dart`, the Apply handler computes
`String normComment = strCleanAndEscape(_commentController.text);` (~line 447)
and passes it to `buildFilter(..., comment: normComment)`. Inside `buildFilter`
the same value is escaped again:
`s.add('actions.comment LIKE "%${strCleanAndEscape(comment)}%"');` (~line 91).
Double-escaping doubles single quotes twice (`'` → `''` → `''''`), so searching
comments that contain apostrophes never matches. The already-escaped string is
also stored back into `currentFilters['comment']` and re-displayed in the field
on reopen, showing mangled text. Fix: escape exactly once. Decide a single layer
(prefer escaping only inside `buildFilter` and pass the raw user text everywhere
else, including the returned map).

### ✅ 3. Comment LIKE uses double-quote string literal + manual escaping
In `lib/filter_screen.dart` (~line 91) the LIKE clause wraps the value in double
quotes (`"%...%"`) while `strCleanAndEscape` only escapes single quotes. In
SQLite double quotes denote identifiers (with a lenient string fallback), and a
user comment containing a `"` will break the query or allow SQL injection into
`xvFilter` (which is concatenated raw into the main query in
`bike_log_screen.dart::_loadActions`). Fix: stop building this predicate by string
concatenation. Refactor the filter so the comment LIKE is passed as a bound
parameter (`actions.comment LIKE ?` with `'%'+value+'%'` as an argument), or at
minimum use single-quote literals with correct single-quote escaping. Audit the
whole `xvFilter` → `_loadActions` path for injection.

### ✅ 4. `waitForMainDb()` is called without `await`
Many data loaders call `waitForMainDb();` as a fire-and-forget statement, so the
intended wait never happens and execution proceeds immediately to the next
`await getDbData(...)`. Occurrences: `add_action_screen.dart` lines ~215, ~239,
~261; `filter_screen.dart` lines ~244, ~266, ~285; `reference_settings_screen.dart`
~line 73; `bike_settings_screen.dart` lines ~47, ~387, ~401, ~421. Fix: either
`await waitForMainDb();` or remove the calls if the busy-guard is reworked (see #5).

### ✅ 5. `dbMainBusy` lock is ineffective
In `lib/db_helpers.dart`, `getDbData`, `setDbData`, and `getDbOne` set
`dbMainBusy = true` at entry but never call `waitForMainDb()` first, while only
`compactDatabase`, `setMultiOper`, and `executeDbTransaction` wait. So a basic
read/write can run concurrently with an in-flight transaction, opening the same
database file twice and risking "database is locked" errors. The flag is also not
re-entrant (nested helper calls clear it prematurely). Fix: implement a real
serialization mechanism — e.g. a shared single `Database` instance kept open, or a
proper async mutex/queue that every DB helper goes through — and remove the
ad-hoc boolean.

### ✅ 6. Type #1 can be deleted despite the guard
In `lib/reference_settings_screen.dart`, `_deleteItem` blocks `num == 1` for both
owners and types (`widget.refMode == 1 || widget.refMode == 2`, ~line 85), but
`_saveItem`'s delete branch (`edMode == 2`) only protects owners
(`widget.refMode == 1`, ~line 133); for types it falls through to
`DELETE FROM types WHERE num = ?`. Since the long-press menu sets `_selectedItemNum`
before `_deleteItem` returns early, pressing Save afterwards deletes the protected
type #1 (referenced by the default bike created in `writeRef`). Fix: apply the
num==1 protection consistently in `_saveItem` for the same refModes guarded in
`_deleteItem`.

### ✅ 7. No referential integrity on type/event deletion
Foreign keys are declared in `assets/bikelog_main.sql` but `PRAGMA foreign_keys`
is never enabled, so they are not enforced. Owner deletion manually cascades
(`_deleteOwnerWithData`), and bike deletion cascades its actions, but deleting a
**type** leaves bikes pointing at a non-existent type, and deleting an **event**
leaves actions whose `INNER JOIN events` silently drops them from the main list
(data appears lost). Fix: before deleting a type or event, count and warn about
referencing rows (like the owner flow), and either block, reassign, or cascade.
Optionally enable `PRAGMA foreign_keys = ON` on every connection and handle the
constraint errors.

### ✅ 8. Bike photo stored as a temporary picker path
In `lib/bike_settings_screen.dart`, `_pickPhoto` stores `image.path` from
`ImagePicker` directly into `photoController` (~line 494), and `_saveBike` writes
that path to `bikes.photo`. On Android this is a cache/temp path that the OS can
purge, so `_showPhoto`/`Image.file` will fail after a while or after a restart.
Photos are also not included in backup/restore (only DB and CSV files are copied).
Fix: copy the picked image into the app's persistent storage (e.g. under
`xvHomePath`) with a stable filename, store that path, delete the old file on
replace, and include the photo directory in backup/restore.

---

## MEDIUM

### ✅ 9. "Sum" total is inconsistent with the visible list
In `lib/bike_log_screen.dart::_showTotalSum`: when a filter is active it folds
over the in-memory `actions` (which may be truncated by the 'Last actions' LIMIT
applied in `_loadActions`), but when no filter is active it runs
`SELECT COUNT(*), SUM(price) FROM actions` over the **entire** table, ignoring the
'Last actions' limit. The displayed total can therefore disagree with the visible
rows. Fix: make the sum reflect exactly the same rows shown (apply the same
filter + limit), or clearly document/label that the total is over all records.

### ⛔ 10. Filter foreign-currency flags are not persisted — NOT APPLICABLE
In `lib/filter_screen.dart`, the Apply handler always returns
`'isPriceFromForeign': false` and `'isPriceToForeign': false` (~lines 470–471),
discarding the actual checkbox state. The returned `priceFrom`/`priceTo` are
already converted to local currency, so on reopening the filter the values are
shown as if they were local and the `$` checkboxes are reset.

Reviewed against the app's currency model and this is intended, not a bug. The
app stores prices only in local currency: `add_action_screen.dart` converts a
`$` amount by `Exchange rate` and notes the original in the comment as ` ($100)`,
the per-action `$` flag is reset after save, and there is no foreign column in
`actions`. The filter operates on `actions.price` (always local), so the `$` box
is just an input aid and the Apply handler correctly persists the local-currency
threshold with the flag cleared. Showing the local value on reopen matches the
model. No code change needed. (The genuine residual issue — the Back button
desyncing returned state from the applied filter — is tracked separately as #28.)

### ✅ 11. `menuLabels` localized once at construction
In `lib/bike_log_screen.dart`, the `menuLabels` map is initialized inline with
`lw(...)` calls (~lines 24–32), evaluated once when the State is created. The home
screen State lives for the app lifetime, so after the user changes the program
language and returns, the menu stays in the old language while the rest of the UI
(built with `lw()` in `build`) updates. Fix: compute the labels inside `build`
(or another per-build location) instead of as a final field.

### ✅ 12. Fragile SQL splitting in import/migration
`db_helpers.dart::setMultiOper` and `settings_screen.dart::processSqlFile` strip
comments with regex and split statements on `;`. This corrupts any statement whose
string data contains `;`, `--`, or `/* */`, and `processSqlFile` only drops lines
that *start* with `--` (inline trailing comments survive). Fix: use a proper
statement splitter that respects quoted string literals, or require/validate a
known-safe import format. At minimum, document the limitation and reject lines that
would be mis-parsed.

### ✅ 13. Restore does not reload settings or validate the source
`settings_screen.dart::restoreFromFiles` overwrites `xvMainHome` and `xvSettHome`
but the in-memory `xdef` is not reloaded, so restored settings only take effect
after a restart. There is also no check that the chosen directory actually
contains valid backup files (a missing file throws and is reported generically).
Fix: after a settings-DB restore, re-run the settings load (or prompt restart),
and validate that expected backup files exist before overwriting.

### ✅ 14. PIN stored in plaintext; PIN dialog controller leaked
`.PIN code` is stored as plaintext in the settings DB, and in
`ui_helpers.dart::showPinDialog` the `pinController` `TextEditingController` is
created but never disposed. Fix: dispose the controller when the dialog closes,
and consider storing a salted hash of the PIN instead of the raw value.

### ⏸ 15. Broad storage permission — DEFERRED to TODO.txt
Moved to TODO.txt: removing MANAGE_EXTERNAL_STORAGE while keeping backups in a
user-visible, uninstall-surviving location requires migrating the whole
backup/restore I/O from dart:io paths to MediaStore/SAF (new dependency). Done
as a standalone task before Play Store publishing, not inline with the audit.

`settings_screen.dart::requestStoragePermission` requests
`Permission.manageExternalStorage` (MANAGE_EXTERNAL_STORAGE), a Play-Store
restricted, all-files permission. Fix: prefer scoped storage / SAF
(`getDirectoryPath`, MediaStore, or app-specific external dir) and only fall back
to broad permissions where unavoidable, to keep the app publishable.

---

## LOW / CLEANUP

### ✅ 16. Hardcoded developer path
`lib/globals.dart` sets `xvHomePath = '/home/e/Documents';` and
`lib/main.dart::initializePaths` hardcodes `/home/e/Documents` and
`/home/e/Documents/BikeLogBackup` for the Linux platform. Replace with a portable
location (e.g. `getApplicationDocumentsDirectory()` / `HOME` env) and remove the
personal path.

### ⛔ 17. Debug logging shipped on — NOT APPLICABLE
`lib/globals.dart` has `bool xvDebug = true;`. This is intentional for dev: the
release build flips it via `00-Make.sh` (it `sed`s `xvDebug = false;` before the
build and restores it after — see lines ~160/173). No code change needed.

### ✅ 18. Dead code
The following are defined but never referenced: `getDbOne` (`db_helpers.dart`);
`isValidDate`, `isDateNotInFuture`, `isDateFromBeforeDateTo`, `sqlDateCondition`,
`sqlDateRangeCondition`, `isDateIntFromBeforeDateIntTo` (`date_helpers.dart`); and
the `StringExtension.replace` extension (`globals.dart`). Remove them or wire them
in if intended.

### ✅ 19. Unused `del` soft-delete column
Every table in `assets/bikelog_main.sql` has `del integer not null default 0`, but
no query ever writes or filters on `del` (all deletes are hard `DELETE FROM`).
Either implement soft-delete consistently (write `del=1` and add `WHERE del=0` to
all reads) or drop the column from the schema.

### ✅ 20. Redundant first-start write
`lib/main.dart::firstRunLanguageSelection` begins with
`if (xdef['.First start'] == 'true') { await setKey('.First start', 'true'); ... }`
— writing 'true' back to a key that is already 'true' is a no-op. Remove it.

### ✅ 21. Placeholder author contact / commented About fields
`lib/globals.dart` has `progEmail = 'xxxx@xxx.xx'`, and
`bike_log_screen.dart::_showAbout` has the email/site lines commented out and a
hardcoded "2025". Fill in real values or remove the dead lines, and avoid
hardcoding the year.

### ✅ 22. Inconsistent date-picker bounds
`firstDate` differs across pickers: `DateTime(1900)` in
`date_helpers.dart::showDatePickerWithFormat`, `DateTime(1950)` in
`add_action_screen.dart` and `filter_screen.dart`. `lastDate` is `now()` in some
places and `DateTime(2099)` in others. Unify the allowed range via shared
constants.

### ✅ 23. Price input edge cases
`globals.dart::validatePriceInput` regex `^\d+(\.\d{1,2})?$` rejects `.5` and `5.`,
and the expression evaluator in `add_action_screen.dart` does not support a leading
unary minus and allows negative results (e.g. `5-10`) to be saved as a negative
price with no guard. Decide intended behavior and validate accordingly (and reject
or warn on negative computed prices).

### 24. Duplicated query/loader code
`_loadBikes`, `_loadOwners`, and `_loadEvents` (and their mapping logic) are copied
across `add_action_screen.dart`, `filter_screen.dart`, and
`bike_settings_screen.dart`. Per project convention, extract these into shared
helper functions (e.g. in `db_helpers.dart` or a new `data_helpers.dart`) to
remove duplication.

### 25. Positional help-id mapping is fragile
`options_settings_screen.dart` derives help ids as `helpId = 20 + index` from the
order of `_xdef.entries`, and inserts an extra "Date Format" row using a fixed
`okHelp(29)`. Reordering or adding a setting silently shifts every help id and can
collide. Map help ids explicitly by setting key instead of by position.

### ✅ 26. Deprecated API usage
`options_settings_screen.dart` uses `clFill.withOpacity(0.5)` (~line 551).
`withOpacity` is deprecated in recent Flutter; switch to `withValues(alpha: ...)`
(or `.withAlpha`) to match the pattern already used in `bike_settings_screen.dart`.

### ✅ 27. Bike photo file orphaned on bike/owner deletion
Follow-up to #8. Deleting a bike (`_confirmAndDeleteBike` in
`bike_settings_screen.dart`) or cascade-deleting an owner
(`_deleteOwnerWithData` in `reference_settings_screen.dart`) removes the rows
but leaves the photo files under `xvPhotoDir` behind, leaking storage. Fix:
delete each affected bike's photo file before removing its row.

### ✅ 28. Filter Back button desyncs state from the applied filter
In `lib/filter_screen.dart` the screen has two exit paths that behave
differently. Apply (~line 388) converts foreign prices, calls `buildFilter` to
update the global `xvFilter`/`xvFilterArgs`, and returns the local-currency
state with the `$` flags cleared. The Back arrow (~line 322) returns a state map
too — with the raw (unconverted) price and the real `$` flags — but never calls
`buildFilter`. The caller (`bike_log_screen.dart`) stores the returned map as
`currentFilters` and reloads the list, so pressing Back changes what the filter
screen shows on reopen while the actual query keeps the previous `xvFilter`:
the displayed fields and the applied filter diverge, and the returned price is
unconverted/inconsistent with what Apply returns. Fix: make Back either not
return a result (pure cancel, leave `currentFilters` untouched) or go through
the same convert+`buildFilter` path as Apply so state and query stay in sync.
