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

Future<void> waitForMainDb() async {
  int attempts = 0;
  while (dbMainBusy && attempts < 100) { // 5 seconds maximum
    await Future.delayed(Duration(milliseconds: 50));
    attempts++;
  }
  if (attempts >= 100) {
    throw Exception('Database busy timeout exceeded');
  }
}

Future<String> getDbOne(String sql) async {
  dbMainBusy = true;
  Database? database;
  String result = '';
  try {
    database = await myOpenDatabase(xvMainHome);
    List<Map<String, dynamic>> queryResult = await database.rawQuery(sql);
    if (queryResult.isNotEmpty && queryResult[0].values.first != null) {
      result = queryResult[0].values.first.toString();
    }
  } catch (e) {
    myPrint('Error in getDbOne: $e');
    rethrow;
  } finally {
    if (database != null) {
      await database.close();
    }
    dbMainBusy = false;
  }
  return result;
}

Future<List<Map<String, dynamic>>> getDbData(String sql, [List<dynamic>? arguments]) async {
  dbMainBusy = true;
  Database? database;
  List<Map<String, dynamic>> result = [];
  try {
    database = await myOpenDatabase(xvMainHome);
    result = await database.rawQuery(sql, arguments ?? []);
  } catch (e) {
    myPrint('Error in getDbData: $e');
    rethrow;
  } finally {
    if (database != null) {
      await database.close();
    }
    dbMainBusy = false;
  }
  return result;
}

Future<void> setDbData(String sql, [List<dynamic>? arguments]) async {
  dbMainBusy = true;
  Database? database;
  try {
    database = await myOpenDatabase(xvMainHome);
    await database.execute(sql, arguments ?? []);
  } catch (e) {
    myPrint('Error in setDbData: $e');
    rethrow;
  } finally {
    if (database != null) {
      await database.close();
    }
    dbMainBusy = false;
  }
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

Future<void> compactDatabase() async {
  waitForMainDb();
  dbMainBusy = true;
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
    if (database != null) {
      await database.close();
    }
    dbMainBusy = false;
  }
}

Future<void> setMultiOper(String sql, String databasePath) async {
  waitForMainDb();
  dbMainBusy = true;

  Database database = await myOpenDatabase(databasePath);
  String normalizedSql = sql
      .replaceAll(RegExp(r'/\*.*?\*/', dotAll: true), '') // Remove multi-line comments
      .replaceAll(RegExp(r'--.*$', multiLine: true), '')  // Remove single-line comments
      .replaceAll('\n', ' ')
      .replaceAll(RegExp(r'\s+'), ' ');
  try {
    List<String> queries = normalizedSql.split(';');
    await database.transaction((txn) async {
      for (String query in queries) {
        query = query.trim();
        if (query.isNotEmpty) {
          await txn.execute(query);
        }
      }
    });
  } catch (e) {
    myPrint('Error in setMultiOper: $e');
    rethrow;
  } finally {
    await database.close();
    dbMainBusy = false;
  }
}

Future<void> executeDbTransaction(List<String> sqlStatements) async {
  waitForMainDb();
  dbMainBusy = true;

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
    dbMainBusy = false;
  }
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
