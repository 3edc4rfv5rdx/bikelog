import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart'; // For getting system paths
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'dart:io'; // For File and Directory operations
import 'package:flutter/services.dart' show rootBundle;
import 'dart:typed_data'; // ByteData
import 'dart:async'; // For Completer
import 'package:sqflite_common_ffi/sqflite_ffi.dart'; // For Linux
// my
import 'my_globals.dart';
import 'bike_log_screen.dart';
import 'settings_screen.dart';
import 'reference_settings_screen.dart';
import 'bike_settings_screen.dart';
import 'filter_screen.dart';
import 'add_action_screen.dart';
import 'options_settings_screen.dart';

// === STARTER ===
Future<void> firstRunLanguageSelection() async {
  if (xdef['.First start'] == 'true') {
    await setKey('.First start', 'true');
    List<String> availableLangs = appLANGUAGES;
    Completer<String> completer = Completer<String>();
    runApp(
      MaterialApp(
        home: Builder(
          builder: (BuildContext context) {
            final screenWidth = MediaQuery.of(context).size.width;
            final containerWidth = screenWidth * 0.9; // 90% ширины экрана
            final buttonWidth = (containerWidth - 48 - 24) / 3;

            return Scaffold(
              body: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [clFon, clUpBar],
                  ),
                ),
                child: Center(
                  child: Container(
                    width: containerWidth,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: clFill,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black,
                          blurRadius: 10,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Select Language',
                          style: TextStyle(
                            fontSize: fsLarge,
                            fontWeight: fwNormal,
                            color: clText,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Wrap(
                          spacing: 9, // horizontal
                          runSpacing: 12, // vertical space
                          alignment: WrapAlignment.center,
                          children: availableLangs.map((lang) =>
                              SizedBox(
                                width: buttonWidth,
                                height: 40,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: clUpBar,
                                    foregroundColor: clText,
                                    elevation: 3,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20), // Более закругленные края
                                    ),
                                  ),
                                  onPressed: () {
                                    completer.complete(lang);
                                  },
                                  child: Text(
                                    lang,
                                    style: TextStyle(
                                      fontSize: fsNormal,
                                      fontWeight: fwNormal,
                                    ),
                                  ),
                                ),
                              ),
                          ).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
    String selectedLang = await completer.future;
    xdef['Program language'] = selectedLang;
    setKey('Program language', selectedLang);
  }
}

// ==============

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Required for permission handling
  initializeSqflite();
  await initializePaths(); // Initialize paths
  await initializeIni();
  await copyAssetsToFileSystem(); // one at first time
  await initializeAllDatabases(); // first start or not
  await firstRunLanguageSelection(); // === STARTER ===
  await writeRef(); // one at first time
  await initTranslations();
  await processExtraData(); // todo for DEBUG only, xxxxx.sql add
  if (xdef['.First start'] == 'true') {
    xdef['.First start'] = 'false';
    await setKey('.First start', 'false');
  }
  // colors
  currentThemeIndex = getThemeIndex(xdef['Color theme']);
  initThemeColors(currentThemeIndex);
  // run!
  runApp(const BikeLogApp());
}

class BikeLogApp extends StatelessWidget {
  const BikeLogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorObservers: [routeObserver],
      debugShowCheckedModeBanner: false, // Disable debug banner
      scaffoldMessengerKey: scaffoldMessengerKey, // global key for ScaffoldMessenger
      navigatorKey: navigatorKey, // Global key for NavigatorState
      title: lw('BikeLogBook'),
      initialRoute: '/bike_log',
      routes: {
        '/bike_log': (context) => const BikeLogScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/reference_settings': (context) {
          final int refMode = ModalRoute.of(context)!.settings.arguments as int? ?? 1;
          return ReferenceSettingsScreen(refMode: refMode);
        },
        '/bike_settings': (context) => const BikeSettingsScreen(),
        '/filters': (context) => const FilterScreen(),
        '/add_action': (context) {
          final int? actionNum = ModalRoute.of(context)!.settings.arguments as int?;
          return AddActionScreen(actionNum: actionNum);
        },
        '/options_settings': (context) => const OptionsSettingsScreen(),
      },
    );
  }
}


Future<void> initializePaths() async {
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      final appStorageDirectory = await getApplicationDocumentsDirectory();
      xvHomePath = appStorageDirectory.path;
      myPrint(">>> Application documents path: ${xvHomePath}");

      final externalStorageDirectory = await getExternalStorageDirectory();
      xvExt1Path = externalStorageDirectory?.path ?? xvHomePath;
      myPrint(">>> External storage directory path: ${xvExt1Path}");

      xvBakDir = '/storage/emulated/0/Download/BikeLogBackup';
      break;

    case TargetPlatform.linux:
      xvHomePath = '/home/e/Documents';
      xvExt1Path = xvHomePath;
      xvBakDir = '/home/e/Download/BikeLogBakup';
      break;

    case TargetPlatform.iOS:
      final appStorageDirectory = await getApplicationDocumentsDirectory();
      xvHomePath = appStorageDirectory.path;
      xvExt1Path = xvHomePath;
      xvBakDir = '${xvHomePath}/BikeLogBackup';
      break;

//    case TargetPlatform.windows:
//    case TargetPlatform.macOS:
    // Добавить специфичные пути для Windows и macOS
    //  throw UnsupportedError('Platform not supported yet');

    default:
      throw UnsupportedError('Unsupported platform');
  }

  // Установка общих путей к базам данных
  xvMainHome = '${xvHomePath}/$mainDb';
  xvLangHome = '${xvHomePath}/$langDb';
  xvHelpHome = '${xvHomePath}/$helpDb';
  xvSettHome = '${xvHomePath}/$settDb';
}



Future<bool> copyAssetsToFileSystem() async {
  String currentVersionInDb = await getKey('.Prog version');
  if (
      (xdef['.First start'] == 'false') &&
      (currentVersionInDb == progVersion)
  ) {
    return true;
  }
  bool allSuccess = true;
  final List<(String, String)> assetFiles = [
    ('assets/sql/bikelog_main.sql', mainSql),
    ('assets/sql/bikelog_lang.sql', langSql),
    ('assets/sql/bikelog_help.sql', helpSql),
  ];
  for (final (assetPath, fileName) in assetFiles) {
    try {
      final filePath = '${xvHomePath}/$fileName';
      final ByteData data = await rootBundle.load(assetPath);
      final List<int> bytes = data.buffer.asUint8List();
      await File(filePath).writeAsBytes(bytes);
      myPrint('>>> Successfully copied $assetPath to $filePath');
    } catch (e) {
      allSuccess = false;
      myPrint('>>> Failed to copy $assetPath: $e');
      if (e is FlutterError) {
        myPrint('>>> Asset not found: $assetPath');
      } else if (e is FileSystemException) {
        myPrint('>>> File system error: ${e.message}');
      }
    }
  }
  // Если успешно скопировали, обновляем версию в БД
  if (allSuccess) {
    await setKey('.Prog version', progVersion);
  }
  return allSuccess;
}


Future<void> initSqlDatabase({
  required String dbFilePath,
  required String sqlFilePath,
  required String dbType
}) async {
  try {
    File dbFile = File(dbFilePath);
    if (!await dbFile.exists() || await dbFile.length() == 0) {
      // Read SQL file and execute queries
      String sql = await File(sqlFilePath).readAsString();
      await setMultiOper(sql, dbFilePath);
    } else {
      return;
    }
  } catch (e) {
    String ee = 'An error occurred';
    myPrint('>>> $ee: In type $dbType: $e');
  }
}

// save from sql to db
Future<void> initializeAllDatabases() async {
  if (xdef['.First start'] != 'true') {
    return;
  }
  // Array of database types
  final List<String> databaseTypes = ['main', 'lang', 'help'];
  // Array of xv[] keys for database file paths
  final List<String> dbFileKeys = [xvMainHome, xvLangHome, xvHelpHome];
  // Array of SQL file names
  final List<String> sqlFiles = [mainSql, langSql, helpSql];
  // Initialize each database in a loop
  for (int i = 0; i < databaseTypes.length; i++) {
    // Get the current database type
    final type = databaseTypes[i];
    // Get the database file path from xv[]
    final dbFilePath = dbFileKeys[i];
    // Get the SQL file name
    final sqlFile = '${xvHomePath}/${sqlFiles[i]}';
    // Call the universal function
    await initSqlDatabase(dbFilePath: dbFilePath, sqlFilePath: sqlFile, dbType: type);
  }
}


Future<void> writeRef() async {
  if (await getTableRowCount('types') > 0) return;

  final String programLanguage = xdef['Program language'].toLowerCase();
  final String langColumn = programLanguage == 'en' ? 'word' : programLanguage;

  List<Map<String, dynamic>> rows = await getLangData('''
    SELECT 
      $langColumn AS name, 
      SUBSTR(tag, 1, INSTR(tag, '|') - 1) AS tablename, 
      CAST(SUBSTR(tag, INSTR(tag, '|') + 1) AS INTEGER) AS num 
    FROM langs 
    WHERE tag IS NOT NULL AND tag != '' 
    ORDER BY tablename, num;
  ''');

  for (var row in rows) {
    String table = row['tablename'];
    int num = row['num'];
    String name = row['name'];
    await setDbData("INSERT INTO $table (num, name) VALUES ($num, '$name');");
  }

  await setDbData('''
    INSERT INTO bikes (num, owner, brand, model, type, serialnum, buydate, photo) 
    VALUES (1, 1, '*', '*', 1, '', '', '');
    ''');
}



// first time init settings db-file and write ini-keys
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
          value TEXT NOT NULL
        )
      ''');
    } catch (e) {
      myPrint('>>> Error creating database: $e');
    } finally {
      await database?.close();
    }
  }
  // write ini keys
  for (var key in xdef.keys) {
    String s = await getKey(key);
    if (s == '') {
      await setKey(key, xdef[key]);
    } else {
      xdef[key] = s;
    }
  }
}


// if first start and was file xxxxx.sql then add it
Future<void> processExtraData() async {
  // Exit early if not first start
  if (xdef['.First start'] != 'true') {
    return;
  }

  String xxxFilePath = '${xvHomePath}/xxxxx.sql';
  File xxxFile = File(xxxFilePath);
  if (await xxxFile.exists()) {
    try {
      String sql = await xxxFile.readAsString();
      // Сначала удаляем многострочные комментарии
      sql = sql.replaceAll(RegExp(r'/\*.*?\*/', dotAll: true), '');

      List<String> queries = sql
          .split(';')
          .map((q) => q.split('\n')
          .where((line) => !line.trim().startsWith('--'))
          .join(' '))
          .map((q) => q.trim())
          .where((q) => q.isNotEmpty)
          .toList();

      Database database = await myOpenDatabase(xvMainHome);
      try {
        for (String query in queries) {
          await database.execute(query);
        }
      } finally {
        await database.close();
      }
    } catch (e) {
      myPrint('>>> Failed to process xxxxx.sql: $e');
    }
  }
}
