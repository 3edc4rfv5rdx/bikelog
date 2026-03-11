# CHANGELOG
> N=new feature, E=error fix, F=fine-tune, R=refactor, I=infrastructure, T=tag

## Audit (2026-03-11)
- I: Move key.properties reference to ~/.my-safe/ (external secure storage)
- F: Translate Russian comment to English in build.gradle.kts
- R: Translate all Russian comments to English in all Dart files (9 files, 217 lines)
- F: Move backup directory from Download to Documents, fix "Bakup" typo
- E: Fix SQL injection: escape user input in filter comment, bike photo; add parameterized query support to getDbData/setDbData
- E: Fix SQL JOIN order in bike_log_screen (bikes before owners)
- E: Add null safety check in _deleteOwnerWithData (empty list guard)
- E: Show error to user on CSV restore failure (was silent)
