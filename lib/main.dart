import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'dart:async'; // For Completer
import 'dart:io'; // For File and Directory operations
import 'dart:convert'; // For working with JSON (json.decode)
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart'; // For getting system paths
import 'globals.dart';
import 'add_action_screen.dart';
import 'bike_log_screen.dart';
import 'bike_settings_screen.dart';
import 'filter_screen.dart';
import 'options_settings_screen.dart';
import 'reference_settings_screen.dart';
import 'settings_screen.dart';

// === STARTER ===
Future<void> firstRunLanguageSelection() async {
  if (xdef['.First start'] == 'true') {
    List<String> availableLangs = appLANGUAGES;
    Completer<String> completer = Completer<String>();
    runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Builder(
          builder: (BuildContext context) {
            final screenWidth = MediaQuery.of(context).size.width;
            final containerWidth = screenWidth * 0.9; // 90% of screen width
            final buttonWidth = (containerWidth - 48 - 24) / 3;
            return Scaffold(
              body: Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/main512.png'),
                    fit: BoxFit.cover, // Stretch image to fill the container
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: MediaQuery.of(context).size.height * 0.2,
                      // Adjust this value to change position
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          width: containerWidth,
                          padding: const EdgeInsets.all(24),
                          margin: const EdgeInsets.only(bottom: 50),
                          decoration: BoxDecoration(
                            color: clFill,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: clText,
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
                                style: tsLarge,
                              ),
                              const SizedBox(height: 24),
                              Wrap(
                                spacing: 9, // horizontal
                                runSpacing: 12, // vertical space
                                alignment: WrapAlignment.center,
                                children:
                                    availableLangs
                                        .map(
                                          (lang) => SizedBox(
                                            width: buttonWidth,
                                            height: 40,
                                            child: ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: clUpBar,
                                                foregroundColor: clText,
                                                elevation: 3,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(15),
                                                ),
                                              ),
                                              onPressed: () {
                                                completer.complete(lang);
                                              },
                                              child: Text(
                                                lang,
                                                style: tsNormal,
                                              ),
                                            ),
                                          ),
                                        )
                                        .toList(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
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
    myPrint("firstRunLanguageSelection finished");
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Required for permission handling
  initializeSqflite();
  await initializePaths(); // Initialize paths
  await initializeIni();
  await initializeAllDatabases(); // first start or not
  await firstRunLanguageSelection(); // === STARTER ===
  // Brief delay to ensure database connection is fully released after creation
  await Future.delayed(const Duration(milliseconds: 200));
  await writeRef(); // one at first time
  await initTranslations();
  if (xdef['.First start'] == 'true') {
    xdef['.First start'] = 'false';
    await setKey('.First start', 'false');
  }
  // colors
  currentThemeIndex = getThemeIndex(xdef['Color theme']);
  initThemeColors(currentThemeIndex);
  // run!
  // Set portrait-only orientation
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]).then((_) {
    runApp(const BikeLogApp());
  });
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

      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: appLANGUAGES.map((lang) => Locale(getLocaleCode(lang))).toList(),
      locale: Locale(getLocaleCode(xdef['Program language'])),

      initialRoute: '/bike_log',
      routes: {
        '/bike_log': (context) => const BikeLogScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/reference_settings': (context) {
          final int refMode =
              ModalRoute.of(context)!.settings.arguments as int? ?? 1;
          return ReferenceSettingsScreen(refMode: refMode);
        },
        '/bike_settings': (context) => const BikeSettingsScreen(),
        '/filters': (context) => const FilterScreen(),
        '/add_action': (context) {
          final int? actionNum =
              ModalRoute.of(context)!.settings.arguments as int?;
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
      myPrint("Application documents path: $xvHomePath");

      final externalStorageDirectory = await getExternalStorageDirectory();
      xvExt1Path = externalStorageDirectory?.path ?? xvHomePath;
      myPrint("External storage directory path: $xvExt1Path");
      xvBakDir = '/storage/emulated/0/Documents/BikeLogBackup';
      break;

    case TargetPlatform.linux:
      xvHomePath = '/home/e/Documents';
      xvExt1Path = xvHomePath;
      xvBakDir = '/home/e/Documents/BikeLogBackup';
      break;

    case TargetPlatform.iOS:
      final appStorageDirectory = await getApplicationDocumentsDirectory();
      xvHomePath = appStorageDirectory.path;
      xvExt1Path = xvHomePath;
      xvBakDir = '$xvHomePath/BikeLogBackup';
      break;

    // case TargetPlatform.windows:
    // case TargetPlatform.macOS:
    //  throw UnsupportedError('Platform not supported yet');

    default:
      throw UnsupportedError('Unsupported platform');
  }

  // Set common database paths
  xvMainHome = '$xvHomePath/$mainDb';
  xvSettHome = '$xvHomePath/$settDb';
  myPrint("initializePaths finished");
}

Future<bool> initSqlDatabase({
  required String dbFilePath,
  required String sqlFilePath,
  required String dbType,
}) async {
  try {
    // Check if file exists
    File dbFile = File(dbFilePath);
    bool fileExists = await dbFile.exists();
    // if exist and this 'main' tnen skip
    if (dbType == 'main' && fileExists) {
      myPrint("Skipping main database initialization - file already exists");
      return true;
    }
    // Read SQL from assets and execute SQL operations
    String sql = await rootBundle.loadString(sqlFilePath);
    await setMultiOper(sql, dbFilePath);
    if (!fileExists) {
      myPrint("initSqlDatabase created new database for $dbType");
    } else {
      myPrint("initSqlDatabase updated existing database for $dbType");
    }
    return true;
  } catch (e) {
    String ee = 'An error occurred';
    myPrint('$ee: In type $dbType: $e');
    return false;
  }
}

Future<void> initializeAllDatabases() async {
  bool isFirstStart = xdef['.First start'] == 'true';
  bool isVersionChanged = progVersion != await getKey('.Prog version');
  // If not first launch and version unchanged, just exit
  if (!isFirstStart && !isVersionChanged) {
    myPrint("Skipping database initialization - not first start and version unchanged");
    return;
  }
  if (await initSqlDatabase(dbFilePath: xvMainHome,
      sqlFilePath: 'assets/$mainSql',dbType: 'main')) {
    await setKey('.Prog version', progVersion);
    myPrint("Databases initialized successfully, updated version");
  }
  myPrint("initializeAllDatabases finished");
}

Future<void> writeRef() async {
  // Check if there are already records in the types table
  if (await getTableRowCount('types') > 0) return;
  try {
    // Get current language
    final String programLanguage = xdef['Program language'].toLowerCase();
    // Load JSON file with reference data
    final String jsonString = await rootBundle.loadString(refFile);
    final Map<String, dynamic> refData = json.decode(jsonString);
    // Get references
    final Map<String, List<dynamic>> references = Map<String, List<dynamic>>.from(refData['references']);
    // Fill tables
    for (var tableEntry in references.entries) {
      String tableName = tableEntry.key.toLowerCase(); // 'Owners' -> 'owners'
      List<dynamic> items = tableEntry.value;
      for (var item in items) {
        // Select name based on current language
        String name = item[programLanguage] ?? item['en']; // If no translation, use English
        int num = item['num'];
        // Insert record into the corresponding table
        await setDbData("INSERT INTO $tableName (num, name) VALUES (?, ?);", [num, name]);
      }
    }
    // Insert record for bicycle (does not change)
    await setDbData('''
      INSERT INTO bikes (num, owner, brand, model, type, serialnum, buydate, photo)
      VALUES (1, 1, '*', '*', 1, '', '', '');
    ''');
    myPrint("writeRef finished");
  } catch (e) {
    myPrint('Error in writeRef: $e');
  }
}

