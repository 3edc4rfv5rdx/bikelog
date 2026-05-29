import 'dart:async';
import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'globals.dart';

void initializeSqflite() {
  if (defaultTargetPlatform == TargetPlatform.linux) {
    sqfliteFfiInit();
  }
}

// Function to open a database based on the platform
Future<Database> myOpenDatabase(String path) async {
  if (defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS) {
    return await openDatabase(path);
  } else if (defaultTargetPlatform == TargetPlatform.linux ||
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.macOS) {
    return await databaseFactoryFfi.openDatabase(path);
  } else {
    throw UnsupportedError('>>> Platform not supported');
  }
}

// Serialize all main-database operations so the same SQLite file is never
// opened from two concurrent code paths (which would cause "database is
// locked"). Every operation is chained onto a single tail future.
Future<dynamic> _dbQueue = Future<dynamic>.value();

Future<T> _runSerialized<T>(Future<T> Function() action) {
  final Completer<T> completer = Completer<T>();
  _dbQueue = _dbQueue.then((_) async {
    try {
      completer.complete(await action());
    } catch (e, st) {
      completer.completeError(e, st);
    }
  });
  return completer.future;
}

Future<List<Map<String, dynamic>>> getDbData(String sql, [List<dynamic>? arguments]) {
  return _runSerialized(() async {
    Database? database;
    List<Map<String, dynamic>> result = [];
    try {
      database = await myOpenDatabase(xvMainHome);
      result = await database.rawQuery(sql, arguments ?? []);
    } catch (e) {
      myPrint('Error in getDbData: $e');
      rethrow;
    } finally {
      await database?.close();
    }
    return result;
  });
}

Future<void> setDbData(String sql, [List<dynamic>? arguments]) {
  return _runSerialized(() async {
    Database? database;
    try {
      database = await myOpenDatabase(xvMainHome);
      await database.execute(sql, arguments ?? []);
    } catch (e) {
      myPrint('Error in setDbData: $e');
      rethrow;
    } finally {
      await database?.close();
    }
  });
}

Future<void> setKey(String key, String value) async {
  Database? database;
  try {
    database = await myOpenDatabase(xvSettHome);
    await database.execute(
        "INSERT OR REPLACE INTO settings (key, value) VALUES (?, ?)",
        [key, value]
    );
  } catch (e) {
    myPrint('Error in setKey: $e');
    rethrow;
  } finally {
    if (database != null) {
      await database.close();
    }
  }
}

Future<String> getKey(String key) async {
  Database? database;
  String result = '';
  try {
    database = await myOpenDatabase(xvSettHome);
    List<Map<String, dynamic>> queryResult = await database.rawQuery(
        "SELECT value as value FROM settings WHERE key = ?",
        [key]
    );
    if (queryResult.isNotEmpty && queryResult[0].values.first != null) {
      result = queryResult[0].values.first.toString().trim();
    }
  } catch (e) {
    myPrint('Error in getKey: $e');
    rethrow;
  } finally {
    if (database != null) {
      await database.close();
    }
  }
  return result;
}

Future<void> compactDatabase() {
  return _runSerialized(() async {
    Database? database;
    try {
      database = await myOpenDatabase(xvMainHome);
      await database.execute("VACUUM");
      myPrint('Database VACUUM ok');
    } catch (e) {
      myPrint('Error during VACUUM compaction: $e');
      okInfoBarRed('VACUUM ${lw('An error occurred')}: $e');
      rethrow;
    } finally {
      await database?.close();
    }
  });
}

/// Split a SQL script into individual statements, respecting single-quoted
/// strings, double-quoted identifiers, line comments (`--`) and block comments
/// (`/* */`). This prevents a `;`, `--`, or `/* */` embedded in string data
/// from corrupting the split, which the previous regex/`split(';')` approach
/// did. Returns trimmed, non-empty statements.
List<String> splitSqlStatements(String sql) {
  final List<String> statements = [];
  final StringBuffer current = StringBuffer();
  final int n = sql.length;
  int i = 0;
  while (i < n) {
    final String c = sql[i];

    // Line comment: -- ... to end of line.
    if (c == '-' && i + 1 < n && sql[i + 1] == '-') {
      i += 2;
      while (i < n && sql[i] != '\n') {
        i++;
      }
      continue;
    }

    // Block comment: /* ... */.
    if (c == '/' && i + 1 < n && sql[i + 1] == '*') {
      i += 2;
      while (i + 1 < n && !(sql[i] == '*' && sql[i + 1] == '/')) {
        i++;
      }
      i += 2; // Skip the closing */.
      continue;
    }

    // Quoted string ('...') or identifier ("..."), copied verbatim. A doubled
    // quote inside is an escaped quote, not a terminator.
    if (c == "'" || c == '"') {
      final String quote = c;
      current.write(c);
      i++;
      while (i < n) {
        final String d = sql[i];
        if (d == quote) {
          if (i + 1 < n && sql[i + 1] == quote) {
            current.write(quote);
            current.write(quote);
            i += 2;
            continue;
          }
          current.write(quote);
          i++;
          break;
        }
        current.write(d);
        i++;
      }
      continue;
    }

    // Top-level statement terminator.
    if (c == ';') {
      final String stmt = current.toString().trim();
      if (stmt.isNotEmpty) {
        statements.add(stmt);
      }
      current.clear();
      i++;
      continue;
    }

    current.write(c);
    i++;
  }

  final String tail = current.toString().trim();
  if (tail.isNotEmpty) {
    statements.add(tail);
  }
  return statements;
}

Future<void> setMultiOper(String sql, String databasePath) {
  return _runSerialized(() async {
    Database database = await myOpenDatabase(databasePath);
    try {
      List<String> queries = splitSqlStatements(sql);
      await database.transaction((txn) async {
        for (String query in queries) {
          await txn.execute(query);
        }
      });
    } catch (e) {
      myPrint('Error in setMultiOper: $e');
      rethrow;
    } finally {
      await database.close();
    }
  });
}

Future<void> executeDbTransaction(List<String> sqlStatements) {
  return _runSerialized(() async {
    final db = await myOpenDatabase(xvMainHome);
    try {
      await db.transaction((txn) async {
        for (String sql in sqlStatements) {
          sql = sql.trim();
          if (sql.isNotEmpty) {
            await txn.execute(sql);
          }
        }
      });
    } catch (e) {
      myPrint('Error in executeDbTransaction: $e');
      rethrow;
    } finally {
      await db.close();
    }
  });
}

Future<int> getTableRowCount(String tableName) async {
  try {
    final sql = 'SELECT COUNT(*) as count FROM $tableName;';
    final result = await getDbData(sql);
    return result[0]['count'] as int;
  } catch (e) {
    myPrint('Error getting row count from $tableName: $e');
    return 0;
  }
}

Future<bool> newMakeDir(String newPath) async {
  Directory newDirectory = Directory(newPath);
  try {
    if (!await newDirectory.exists()) {
      await newDirectory.create(recursive: true);
      myPrint('Directory successfully created: $newPath');
    } else {
      myPrint('Directory already exists: $newPath');
    }
    return true;
  } catch (e) {
    myPrint('Error creating directory: $e');
    return false;
  }
}

Future<bool> copyFiles(List<String> sourcePaths, String destinationDir) async {
  try {
    for (String sourcePath in sourcePaths) {
      String fileName = sourcePath.split('/').last;
      String destinationPath = '$destinationDir/$fileName';
      await File(sourcePath).copy(destinationPath);
      myPrint('File copied: $destinationPath');
    }
    return true;
  } catch (e) {
    myPrint('Error copying files: $e');
    return false;
  }
}

// Copy every file directly inside sourceDir into destinationDir (created if
// needed). Subdirectories are ignored. A missing source is treated as success
// (nothing to copy). Used to carry the bike photos dir through backup/restore.
Future<bool> copyDirFiles(String sourceDir, String destinationDir) async {
  try {
    final src = Directory(sourceDir);
    if (!await src.exists()) return true;
    if (!await newMakeDir(destinationDir)) return false;
    final files = src.listSync().whereType<File>().map((f) => f.path).toList();
    if (files.isEmpty) return true;
    return await copyFiles(files, destinationDir);
  } catch (e) {
    myPrint('Error copying directory $sourceDir: $e');
    return false;
  }
}

// Best-effort delete of a bike photo file by its stored filename (no-op for
// null/empty). Keeps the photos dir from leaking files on replace or row
// deletion.
Future<void> deleteBikePhoto(String? fileName) async {
  if (fileName == null || fileName.isEmpty) return;
  try {
    final f = File(bikePhotoPath(fileName));
    if (await f.exists()) await f.delete();
  } catch (e) {
    myPrint('Failed to delete photo file $fileName: $e');
  }
}

Future<void> initializeIni() async {
  final dbFile = File(xvSettHome);
  if (!await dbFile.exists()) {
    Database? database;
    xdef['.First start'] = 'true';
    try {
      database = await myOpenDatabase(xvSettHome);
      await database.execute('''
        CREATE TABLE IF NOT EXISTS settings (
          key TEXT PRIMARY KEY NOT NULL,
          value TEXT NOT NULL)
      ''');
    } catch (e) {
      myPrint('Error creating database: $e');
    } finally {
      await database?.close();
    }
  }
  for (var key in xdef.keys) {
    String saved = await getKey(key);
    if (saved == '') {
      await setKey(key, xdef[key]); // defaults
    } else {
      xdef[key] = saved;
    }
  }
  myPrint("initializeIni finished");
}
