# BikeLog - Bicycle Maintenance Logbook

A cross-platform mobile application for tracking bicycle maintenance, repairs, and expenses. Built with Flutter/Dart.

## Features

- **Multiple owners and bikes** - manage bikes for the whole family or a fleet
- **Maintenance log** - record services, repairs, purchases, tuning with dates and costs
- **Flexible filtering** - filter actions by owner, bike, event type, date range, and comment
- **Expense tracking** - track costs per bike, per event type, with totals and summaries
- **Reference management** - customizable lists of owners, bike types, and event types
- **Backup & restore** - full database backup and CSV export/import to Documents folder
- **7 color themes** - Light, Dark, Green, Blue, Brown, Purple, Orange
- **3 languages** - English, Russian, Ukrainian
- **Configurable date formats** - DD-MM-YYYY, MM-DD-YYYY, YYYY-MM-DD with custom separators
- **PIN protection** - optional 4-digit PIN lock
- **Context help** - built-in help system with localized texts

## Editions

| Edition  | Owners | Bikes |
|----------|--------|-------|
| Personal | 1      | 3     |
| Family   | 5      | 10    |
| PRO      | unlimited | unlimited |

## Tech Stack

- **Framework:** Flutter (Dart)
- **Database:** SQLite via sqflite / sqflite_common_ffi
- **Platforms:** Android, Linux (iOS possible)
- **Min Android SDK:** 21 (Android 5.0)

## Project Structure

```
lib/
  main.dart                    - app entry point, initialization, first-run setup
  globals.dart                 - global state, constants, themes, translations
  db_helpers.dart              - database operations, file I/O, settings
  ui_helpers.dart              - dialogs, snackbars, PIN dialog
  date_helpers.dart            - date formatting, validation, picker
  bike_log_screen.dart         - main actions list screen
  add_action_screen.dart       - add/edit maintenance action
  bike_settings_screen.dart    - bike management
  reference_settings_screen.dart - owners, types, events management
  filter_screen.dart           - filter configuration
  settings_screen.dart         - backup, restore, app settings
  options_settings_screen.dart - theme, language, date format options
assets/
  bikelog_main.sql             - database schema
  locales.json                 - UI translations (EN/RU/UA)
  references.json              - default reference data
  help.json                    - context help texts
```

## Build

```bash
# Development
flutter pub get
flutter run

# Release APK (via build script)
./00-Make.sh
```

## Author

Eugen - [bikelogbook.od.ua](https://bikelogbook.od.ua)
