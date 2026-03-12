# Check-list after audit

## 1. Startup and initialization
- [x] First run (delete DB) — language selection screen appears
- [x] DB creation — tables and indexes created without errors
- [x] References (owners, types, events) populated with initial data
- [x] Restart — data persisted

## 2. CRUD operations
- [x] Add owner, type, event — saves
- [x] Edit owner, type, event — updates
- [x] Delete owner (cascade delete bikes and actions)
- [x] Add bike — all fields saved (brand, model, serial, photo, date)
- [x] Edit bike — updates
- [x] Add action — date, price, comment saved correctly
- [x] Edit action — updates
- [x] Special characters in comments: `'`, `"`, `\`, `%` — don't break queries

## 3. Filters
- [x] Filter by owner works
- [x] Filter by bike works
- [x] Filter by event type works
- [x] Filter by date range works
- [x] Filter by comment (with special characters) works
- [x] Clear filter returns all records

## 4. Dates
- [x] Format DD-MM-YYYY — input, display, storage
- [x] Format MM-DD-YYYY — input, display, storage
- [x] Format YYYY-MM-DD — input, display, storage
- [x] Separators `.` `/` `-` work
- [x] Date picker opens and returns correct date
- [x] Future date rejected

## 5. Backup / Restore
- [x] Backup files — created in `Documents/BikeLogBackup/`
- [x] Backup CSV — files created
- [x] Restore from files — data restored
- [x] Restore from CSV — data restored
- [x] Restore error — red SnackBar shown

## 6. Settings and themes
- [x] Switch all 7 themes — colors applied
- [x] Switch language EN/RU/UA — UI translated
- [x] PIN — setup, login with correct PIN, lockout after 3 failed attempts
- [x] All settings persist between restarts

## 7. Localization
- [x] RU — check a few screens, no `(( text ))` wrappers
- [x] UA — especially check "Досягнуто лiмiт власникiв" (fixed translation)

## 8. General
- [x] Action list sorting (newest first / oldest first)
- [x] Totals (count, sum) displayed correctly
- [x] Help (?) — help dialog opens
- [x] VACUUM (compactDatabase) — runs without errors
