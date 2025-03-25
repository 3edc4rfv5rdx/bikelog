import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart'; // For Linux
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'dart:io';
import 'dart:convert'; // Для работы с JSON (json.decode)
import 'package:flutter/services.dart' show rootBundle; // Для загрузки файлов из assets

// Global key for accessing ScaffoldMessenger
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
// Global key for NavigatorState
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

const List<String> DATE_FORMATS = ['DD-MM-YYYY', 'MM-DD-YYYY', 'YYYY-MM-DD'];
const List<String> DATE_SEPARATORS = ['.', '/', '-'];

// Global Map for settings
Map<String, dynamic> xdef = {
  'Program language': 'EN',
  'Color theme': 'Light', // N 0
  'Last actions': '0',
  'Exchange rate': '42',
  'Newest first': 'true',
  'Several actions': 'false',
  'Back after clear': 'true',
  'Round to integer': 'true',
  'Use PIN': 'false',
  '.Date format': 'YYYY-MM-DD',
  '.Date separator': '-',
  '.PIN code': '',
  '.First start': 'false',
  '.Prog version': progVersion,
};

bool xvDebug = true;
String xvFilter = '';
String xvSelect = '???';
String xvHomePath = '/home/e/Documents';
String xvExt1Path = '';
String xvMainHome = '';
String xvSettHome = '';
String xvBakDir = '';
bool xvBusiness = false;

const String progVersion = '0.9.250324';
// const String progDate = '2025-02-19';
const String progAuthor = 'Eugen';
const String progEmail = 'xxxx@xxx.xx';
const String progSite = 'bikelogbook.od.ua';

const List<(String, int, int)> prgEditions = [
  ('Personal', 1, 3),
  ('Family', 5, 10),
  ('PRO', 9999, 99999),
];
const int currVers = 2;  // 0-1-2
String get progEdition => prgEditions[currVers].$1;
int get progOwners => prgEditions[currVers].$2;
int get progBikes => prgEditions[currVers].$3;

// all program landuages,
const List<String> appLANGUAGES = ['EN','RU','UA',];

String getLocaleCode(String language) {
  // Словарь только для исключений, где код страны отличается
  final Map<String, String> exceptions = {
    'UA': 'uk',  // ukraine
    'GR': 'el',  // greek
    'CN': 'zh',  // china
    'JP': 'ja',  // japan
    'SE': 'sv',  // sveden
    'DK': 'da',  // Датский
    'CZ': 'cs',  // cheska
  };
  String langCode = language.toUpperCase();
  return exceptions[langCode] ?? langCode.toLowerCase();
}

// color themes names
const List<String> appTHEMES = ['Light','Dark','Green','Blue','Brown','Purple','Orange',];

// themes colors
const List<List<Color>> curTHEME = [
  // Color(0xFFxxxxx):  color format ARGB (Alpha, Red, Green, Blue),
  // Light theme, currentThemeIndex = 0
  [
    Color(0xFFFFF8E1),      // fon (Colors.amber.shade50)
    Color(0xFFB3E5FC),      // menu (Colors.lightBlue.shade100)
    Color(0x4DFFA500),      // select (30% opacity orange)
    Color(0xFFDAA520),      // upBar (mustard)
    Colors.black,           // text
    Colors.white,          // fill
    Colors.grey,           // frame
  ],
  // Dark theme, currentThemeIndex = 1
  [
    Color(0xFF121212),      // fon - почти черный фон списков
    Color(0xFF5C5C5C),      // menu - средне-темный серый
    Color(0x4D6C6C6C),      // selected - серый с прозрачностью
    Color(0xFF404040),      // upBar - темно-серый
    Color(0xFFE0E0E0),      // text - светло-серый
    Color(0xFF4d4d4d),      // white
    Color(0xFF808080),      // grey
  ],
  // Green theme,  currentThemeIndex = 2
  [
    Color(0xFFF3F7ED),      // fon - светлый фисташковый
    Color(0xFFD4E2C6),      // menu - шалфейный
    Color(0x4D4C6B3D),      // selected - оливковый с прозрачностью
    Color(0xFF97BA60),      // upBar - глубокий оливковый
    Color(0xFF121E0A),      // text - темно-зеленый
    Colors.white,          // fill
    Colors.grey,           // frame
  ],
  // blue theme = 3
  [
    Color(0xFFEDF7FB),      // fon - светлый лазурный
    Color(0xFFC6E0E9),      // menu - светло-голубой
    Color(0x4D3D6B7F),      // selected - серо-голубой с прозрачностью
    Color(0xFF7FB8D5),      // upBar - глубокий голубой
    Color(0xFF0A181E),      // text - темно-синий
    Colors.white,          // fill
    Colors.grey,           // frame
  ],
  // Brown = 4
  [
    Color(0xFFF7F2ED),      // fon - светлый бежевый
    Color(0xFFE2D4C6),      // menu - светло-коричневый
    Color(0x4D6B4D3D),      // selected - коричневый с прозрачностью
    Color(0xFFB69478),      // upBar - глубокий коричневый
    Colors.black,           // text
    Colors.white,          // fill
    Colors.grey,           // frame
  ],
  // purple = 5
  [
    Color(0xFFF2EDF7),      // fon - светлый лавандовый
    Color(0xFFD4C6E2),      // menu - светло-фиолетовый
    Color(0x4D5D3D6B),      // selected - фиолетовый с прозрачностью
    Color(0xFF9A75B8),      // upBar - глубокий фиолетовый
    Color(0xFF180A1E),      // text - темно-фиолетовый
    Color(0xFFFFFFFF),      // white
    Color(0xFF808080),      // grey
  ],
  // orange = 6
  [
    Color(0xFFF7F0ED),      // fon - светлый персиковый
    Color(0xFFE2CDC6),      // menu - светло-оранжевый
    Color(0x4D6B533D),      // selected - оранжевый с прозрачностью
    Color(0xFFE59967),      // upBar - глубокий оранжевый
    Color(0xFF1E120A),      // text - темно-коричневый
    Color(0xFFFFFFFF),      // white
    Color(0xFF808080),      // grey
  ],
]; //  color 77b300


// Define colors with names
Color clFon = curTHEME[0][0];
Color clMenu = curTHEME[0][1];
Color clSel = curTHEME[0][2];
Color clUpBar = curTHEME[0][3];
Color clText = curTHEME[0][4];
Color clFill = curTHEME[0][5];
Color clFrame = curTHEME[0][6];

Color clRed = Colors.red;

const double fsSmall = 13;  // Small font size
const double fsNormal = 15; // Main font size
const double fsLarge = 18;  // Font size for headers

const FontWeight fwBold = FontWeight.bold;
const FontWeight fwNormal = FontWeight.normal;

bool dbMainBusy = false;
const String prgName = 'bikelog';
// Main database and SQL file
const String mainDb = '${prgName}_main.db';
const String mainSql = '${prgName}_main.sql';
const String settDb = '${prgName}_sett.db';
// Добавляем константу для пути к файлу справки
const String helpFile = 'assets/help.json';
const String langFile = 'assets/locales.json';
const String refFile = 'assets/references.json';

extension StringExtension on String {
  String replace(String from, String to) {
    return replaceAll(from, to);
  }
}

int currentThemeIndex = 0;
void initThemeColors(int themeIndex) {
  clFon = curTHEME[themeIndex][0];
  clMenu = curTHEME[themeIndex][1];
  clSel = curTHEME[themeIndex][2];
  clUpBar = curTHEME[themeIndex][3];
  clText = curTHEME[themeIndex][4];
  clFill = curTHEME[themeIndex][5];
  clFrame = curTHEME[themeIndex][6];
}

// get theme index by name
int getThemeIndex(String themeName) {
  int index = appTHEMES.indexOf(themeName);
  return (index == -1) ? 0 : index; // 0 = appTHEMES.indexOf("Light")
}

// get theme name by index
String getThemeName(int index) {
  if (index >= 0 && index < appTHEMES.length) {
    return appTHEMES[index];
  }
  return appTHEMES[0]; // return Light by default
}


Future<bool> okConfirm({
  required String title,
  required String message,
}) async {

  // Return the user's choice (true for "OK", false for "Cancel")
  final result = await showDialog<bool>(
    context: navigatorKey.currentContext!, // Use the global navigation key
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(
          title,
          style: TextStyle(color: clText, fontSize: fsLarge, fontWeight: fwNormal,),
        ),
        content: Text(
          message,
          style: TextStyle(color: clText, fontSize: fsNormal, fontWeight: fwNormal,),
        ),
        backgroundColor: clFon, // Background color
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: clUpBar, // Border color
            width: 3.0,
          ),
          borderRadius: BorderRadius.circular(8.0), // Rounded corners (radius 8)
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, false); // Return false for "Cancel"
            },
            style: TextButton.styleFrom(
              backgroundColor: clUpBar,
              foregroundColor: clText,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 4,
              minimumSize: Size(60, 40),
            ),
            child: Text(lw('No')),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context, true); // Return true for "OK"
            },
            style: TextButton.styleFrom(
              backgroundColor: clUpBar,
              foregroundColor: clText,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 4,
              minimumSize: Size(60, 40),
            ),
            child: Text(lw('Yes')),
          ),
        ],
      );
    },
  );
  // If the result is null (e.g., dialog closed without a choice), return false
  return result ?? false;
}

/// Shows a custom dialog with given parameters
void showCustomDialog({
  required String title,
  required String message,
  required Color color,
  required IconData icon,
}) {
  showDialog(
    context: navigatorKey.currentContext!,
// затемнение фона при показе
//    barrierColor: Colors.transparent,
//    barrierDismissible: true,
    builder: (context) {
      return AlertDialog(
        backgroundColor: clFon,
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: clUpBar,
            width: 3.0,
          ),
          borderRadius: BorderRadius.circular(8.0),
        ),
        title: Row(
          children: [
            Icon(icon, color: color),
            SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(color: clText, fontSize: fsLarge, fontWeight: fwNormal,),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(
            message,
            style: TextStyle(color: clText, fontSize: fsNormal, fontWeight: fwNormal,),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              backgroundColor: clUpBar,
              foregroundColor: clText,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 4,
              minimumSize: Size(60, 40),
            ),
            child: Text(lw('Ok')),
          ),
        ],
        elevation: 10.0,
      );
    },
  );
}

// Показывает диалог справки с текстом из JSON файла
void okHelp(int helpId) async {
  if (helpId == 0) return;

  try {
    // Загружаем JSON файл с текстами справки
    final jsonString = await rootBundle.loadString(helpFile);
    final Map<String, dynamic> helpTexts = json.decode(jsonString);
    final String helpIdStr = helpId.toString();
    String helpText = '';

    // Получаем текущий язык
    final columnName = xdef['Program language'].toLowerCase();

    // Получаем текст справки для текущего языка
    if (helpTexts.containsKey(helpIdStr)) {
      final Map<String, dynamic> helpEntry = helpTexts[helpIdStr];
      if (helpEntry.containsKey(columnName)) {
        helpText = helpEntry[columnName];
      } else if (helpEntry.containsKey('en')) {
        // Если нет перевода для текущего языка, используем английский
        helpText = helpEntry['en'];
      } else {
        throw Exception(lw('Help text not found'));
      }
    } else {
      throw Exception(lw('Help text not found'));
    }

    // Показываем диалог с текстом справки
    if (helpText.isNotEmpty) {
      showCustomDialog(
        title: lw('Help'),
        message: helpText,
        color: clUpBar,
        icon: Icons.info_outline,
      );
    }
    myPrint('Showing help for ID: $helpId');
  } on Exception catch (e) {
    final errorMsg = lw('An error occurred');
    okInfoBarPurple('$errorMsg: $e (helpId=$helpId)');
  } catch (e) {
    final errorMsg = lw('An error occurred');
    okInfoBarPurple('$errorMsg: $e (helpId=$helpId)');
  }
}

// Function to show an info dialog
void okInfo(String message) {
  showCustomDialog(
    title: lw('Info'), // Fixed title
    message: message,
    color: Colors.blue,
    icon: Icons.info_outline,
  );
}

// Function to show an error dialog
void okErr(String message) {
  showCustomDialog(
    title: lw('Error'), // Fixed title
    message: message,
    color: Colors.red,
    icon: Icons.error_outline,
  );
}

// Function to show a warning dialog
void okWarning(String message) {
  showCustomDialog(
    title: lw('Warning'), // Fixed title
    message: message,
    color: Colors.orange,
    icon: Icons.warning_amber_outlined,
  );
}

// Function to show a success dialog
void okSuccess(String message) {
  showCustomDialog(
    title: lw('Success'), // Fixed title
    message: message,
    color: Colors.green,
    icon: Icons.check_circle_outline,
  );
}

// Function to initialize translations
Map<String, String> _translationCache = {};

// Новая функция для загрузки локализаций из JSON файла
Future<void> initTranslations() async {
  String lang = xdef['Program language'].toLowerCase();
  // Для английского языка кеш не нужен
  if (lang == 'en') { _translationCache.clear(); return; }
  try {
    // Загружаем JSON файл с локализациями
    final String jsonString = await rootBundle.loadString(langFile);
    final Map<String, dynamic> allTranslations = json.decode(jsonString);
    // Очищаем кеш перед обновлением
    _translationCache.clear();
    // Заполняем кеш переводами для текущего языка
    allTranslations.forEach((key, value) {
      if (value is Map && value.containsKey(lang)) {
        _translationCache[key] = value[lang];
      }
    });
    myPrint('initTranslations finished, loaded ${_translationCache.length} translations');
  } catch (e) {
    myPrint('Error initializing translations: $e');
    _translationCache.clear(); // В случае ошибки очищаем кеш
  }
}

// Function to translate a word
String lw(String wrd) {
  String lang = xdef['Program language']; // was .toUpperCase();
  if (lang == 'EN') { return wrd; }
  return _translationCache[wrd] ?? '(( $wrd ))'; // Возвращаем текст, если перевод не найден
}

// Function to validate the price input
bool validatePriceInput(String input) {
  if (input.isEmpty) {
    return true; // Allow empty price
  }
  final RegExp priceRegex = RegExp(r'^\d+(\.\d{1,2})?$');
  return priceRegex.hasMatch(input);
}

// Function to execute a SQL query and return a single value
Future<String> getDbOne(String sql) async {
  dbMainBusy = true;
  Database? database;
  String result = ''; // Default value
  try {
    database = await myOpenDatabase(xvMainHome);
    List<Map<String, dynamic>> queryResult = await database.rawQuery(sql);
    // Check if the result is not empty and contains data
    if (queryResult.isNotEmpty && queryResult[0].values.first != null) {
      result = queryResult[0].values.first.toString(); // Get the first value
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
  return result; // Return the result
}

// Function to execute a SQL query and return a list of rows
Future<List<Map<String, dynamic>>> getDbData(String sql) async {
  dbMainBusy = true;
  Database? database;
  List<Map<String, dynamic>> result = []; // Default value
  try {
    database = await myOpenDatabase(xvMainHome);
    result = await database.rawQuery(sql);
  } catch (e) {
    myPrint('Error in getDbData: $e');
    rethrow;
  } finally {
    if (database != null) {
      await database.close();
    }
    dbMainBusy = false;
  }
  return result; // Return the result
}

// Function to execute a SQL command on the main database
Future<void> setDbData(String sql) async {
  dbMainBusy = true;
  Database? database;
  try {
    database = await myOpenDatabase(xvMainHome);
    await database.execute(sql);
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


// Function to compact the database using the VACUUM command
Future<void> compactDatabase() async {
  waitForMainDb();
  dbMainBusy = true;
  Database? database;
  try {
    database = await myOpenDatabase(xvMainHome);
    await database.execute("VACUUM"); // Execute the VACUUM operation
    myPrint('Database VACUUM ok');
  } catch (e) {
    myPrint('Error during VACUUM compaction: $e');
    okInfoBarRed('VACUUM ${lw('An error occurred')}: $e'); // Handle the error
    rethrow; // Пробрасываем ошибку дальше, чтобы ее можно было обработать в вызывающем коде
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
      .replaceAll(RegExp(r'/\*.*?\*/', dotAll: true), '') // Удаляем многострочные комментарии /* */
      .replaceAll(RegExp(r'--.*$', multiLine: true), '')  // Удаляем однострочные комментарии --
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

Future<void> waitForMainDb() async {
  int attempts = 0;
  while (dbMainBusy && attempts < 100) { // 5 секунд максимум
    await Future.delayed(Duration(milliseconds: 50));
    attempts++;
  }
  if (attempts >= 100) {
    throw Exception('Database busy timeout exceeded');
  }
}


// Function to show a blue SnackBar
void okInfoBarBlue(String message) {
  scaffoldMessengerKey.currentState?.showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: TextStyle(
          fontSize: fsSmall,
          color: Colors.white,
        ),
      ),
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.blue,
      duration: Duration(seconds: 5),
    ),
  );
}

// Function to show a red SnackBar
// EXAMPLE: okInfoBarRed("This is a message", duration: Duration(seconds: 3));
void okInfoBarRed(String message, {Duration? duration}) {
  scaffoldMessengerKey.currentState?.showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: TextStyle(
          fontSize: fsSmall,
          color: Colors.white,
        ),
      ),
      backgroundColor: Colors.red,
      duration: duration ?? Duration(seconds: 7),
      behavior: SnackBarBehavior.floating,
      dismissDirection: DismissDirection.none,
    ),
  );
}

// Function to show an orange SnackBar
void okInfoBarOrange(String message) {
  scaffoldMessengerKey.currentState?.showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: TextStyle(
          fontSize: fsSmall,
          color: clText,
        ),
      ),
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.orange,
    ),
  );
}

// Function to show a yellow SnackBar
void okInfoBarYellow(String message) {
  scaffoldMessengerKey.currentState?.showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: TextStyle(
          fontSize: fsSmall,
          color: clText,
        ),
      ),
      backgroundColor: Colors.yellow,
      behavior: SnackBarBehavior.floating,
    ),
  );
}

// Function to show a green SnackBar
void okInfoBarGreen(String message, {Duration? duration}) {
  scaffoldMessengerKey.currentState?.showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: TextStyle(
          fontSize: fsSmall,
          color: clText,
        ),
      ),
      duration: duration ?? Duration(seconds: 3),
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.green,
    ),
  );
}

// Function to show a purple SnackBar
void okInfoBarPurple(String message) {
  scaffoldMessengerKey.currentState?.showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: TextStyle(
          fontSize: fsSmall,
          color: clFill,
        ),
      ),
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.purple,
      duration: Duration(days: 3),
      dismissDirection: DismissDirection.none,
      action: SnackBarAction(
        label: '[ OK ]',
        onPressed: () {
          scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
        },
      ),
    ),
  );
}

// Function to open a database based on the platform
Future<Database> myOpenDatabase(String path) async {
  if (defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS) {
    return await openDatabase(path); // Use sqflite.openDatabase
  } else if (defaultTargetPlatform == TargetPlatform.linux ||
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.macOS) {
    return await databaseFactoryFfi.openDatabase(path);
  } else {
    throw UnsupportedError('>>> Platform not supported');
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

Future<bool> newMakeDir(String newPath) async {
  // Create a Directory object
  Directory newDirectory = Directory(newPath);
  try {
    // Check if the directory already exists
    if (!await newDirectory.exists()) {
      // If not, create it
      await newDirectory.create(recursive: true); // recursive: true to create all nested directories
      myPrint('Directory successfully created: $newPath');
    } else {
      myPrint('Directory already exists: $newPath');
    }
    // Return true if the directory is created or already exists
    return true;
  } catch (e) {
    // In case of an error, print the message and return false
    myPrint('Error creating directory: $e');
    return false;
  }
}

// Function to copy (multiple) files
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

// Function to get the count of rows in a table
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


void initializeSqflite() {
  if (defaultTargetPlatform == TargetPlatform.linux) {
    sqfliteFfiInit();
  }
}

void myPrint(String msg) {if (xvDebug) print('>>> $msg');}

String strCleanAndEscape(String input) {
  if (input.isEmpty) return input;
  // Сначала очищаем строку от лишних пробелов и переносов
  String cleaned = input
      .trim()
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll(RegExp(r'[\r\n]+'), ' ');
  // Затем экранируем специальные символы SQL
  String escaped = cleaned
      .replaceAll("'", "''")
      .replaceAll('\\', '\\\\');
  return escaped;
}

// Тип диалога: установка или проверка PIN
enum PinDialogMode { setup, verify }

// Функция для показа диалога PIN-кода
Future<String?> showPinDialog({
  required PinDialogMode mode,
  int maxAttempts = 3,
}) async {
  final pinController = TextEditingController();
  int attempts = 0;

  String? result = await showDialog<String>(
    context: navigatorKey.currentContext!,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: clFon,
              shape: RoundedRectangleBorder(
                side: BorderSide(color: clUpBar, width: 3.0),
                borderRadius: BorderRadius.circular(8.0),
              ),
              title: Text(
                mode == PinDialogMode.setup ? lw('Set PIN code') : lw('Enter PIN'),
                style: TextStyle(color: clText, fontSize: fsLarge, fontWeight: fwNormal),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: pinController,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    obscureText: true,
                    obscuringCharacter: '*',
                    autofocus: true,
                    style: TextStyle(color: clText, fontSize: fsLarge),
                    decoration: InputDecoration(
                      labelText: lw('4-digit PIN'),
                      labelStyle: TextStyle(color: clText),
                      counterStyle: TextStyle(color: clText),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: clFrame),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: clUpBar),
                      ),
                    ),
                  ),
                  if (mode == PinDialogMode.verify)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        "${lw('Attempts left')}: ${maxAttempts - attempts}",
                        style: TextStyle(
                            color: (maxAttempts - attempts) <= 1 ? Colors.red : clText,
                            fontSize: fsNormal
                        ),
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context, null);
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: clUpBar,
                    foregroundColor: clText,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 4,
                    minimumSize: Size(60, 40),
                  ),
                  child: Text(mode == PinDialogMode.setup ? lw('Cancel') : lw('Exit')),
                ),
                TextButton(
                  onPressed: () {
                    final pin = pinController.text;

                    // Валидация PIN
                    bool isValid = pin.length == 4 && RegExp(r'^[0-9]+$').hasMatch(pin);

                    if (mode == PinDialogMode.setup) {
                      // В режиме установки просто проверяем формат
                      if (isValid) {
                        Navigator.pop(context, pin);
                      } else {
                        okInfoBarRed(lw('PIN must be exactly 4 digits'));
                        pinController.clear();
                      }
                    } else {
                      // В режиме проверки сверяем с сохраненным PIN
                      if (pin == xdef['.PIN code']) {
                        Navigator.pop(context, pin);
                      } else {
                        attempts++;
                        setState(() {}); // Обновляем состояние для показа количества попыток

                        if (attempts >= maxAttempts) {
                          Navigator.pop(context, null);
                        } else {
                          okInfoBarRed(lw('Incorrect PIN'));
                          pinController.clear();
                        }
                      }
                    }
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: clUpBar,
                    foregroundColor: clText,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 4,
                    minimumSize: Size(60, 40),
                  ),
                  child: Text(lw('Ok')),
                ),
              ],
            );
          }
      );
    },
  );

  return result;
}

String dateToStorageFormat(String displayDate) {
  if (displayDate.isEmpty) return '';

  String format = xdef['.Date format'];
  String separator = xdef['.Date separator'];

  List<String> parts = displayDate.split(separator);
  if (parts.length != 3) return displayDate; // Неверный формат

  String year, month, day;

  switch (format) {
    case 'DD-MM-YYYY':
      day = parts[0].padLeft(2, '0');
      month = parts[1].padLeft(2, '0');
      year = parts[2];
      break;

    case 'MM-DD-YYYY':
      month = parts[0].padLeft(2, '0');
      day = parts[1].padLeft(2, '0');
      year = parts[2];
      break;

    case 'YYYY-MM-DD':
    default:
    // Уже в ISO формате, просто стандартизируем разделители
      year = parts[0];
      month = parts[1].padLeft(2, '0');
      day = parts[2].padLeft(2, '0');
      break;
  }

  return '$year-$month-$day'; // Всегда используем - для хранения
}

// Преобразование из формата хранения (YYYY-MM-DD) в формат отображения
String dateFromStorageFormat(String storageDate) {
  if (storageDate.isEmpty) return '';

  String format = xdef['.Date format'];
  String separator = xdef['.Date separator'];

  List<String> parts = storageDate.split('-');
  if (parts.length != 3) return storageDate; // Неверный формат

  String year = parts[0];
  String month = parts[1];
  String day = parts[2];

  switch (format) {
    case 'DD-MM-YYYY':
      return day + separator + month + separator + year;

    case 'MM-DD-YYYY':
      return month + separator + day + separator + year;

    case 'YYYY-MM-DD':
    default:
      return year + separator + month + separator + day;
  }
}

// Получение текста подсказки для полей ввода даты на основе текущих настроек
String getDateFormatHint() {
  String format = xdef['.Date format'];
  String separator = xdef['.Date separator'];
  return format.replaceAll('-', separator);
}

// Вспомогательная функция для получения примера даты в текущем формате
String getDateFormatExample() {
  final today = DateTime.now();
  final day = today.day.toString().padLeft(2, '0');
  final month = today.month.toString().padLeft(2, '0');
  final year = today.year.toString();

  String format = xdef['.Date format'];
  String separator = xdef['.Date separator'];

  switch (format) {
    case 'DD-MM-YYYY':
      return '$day$separator$month$separator$year';
    case 'MM-DD-YYYY':
      return '$month$separator$day$separator$year';
    case 'YYYY-MM-DD':
    default:
      return '$year$separator$month$separator$day';
  }
}

// Обновим существующие функции проверки даты
bool isValidDateFormat(String input) {
  if (input.isEmpty) return false;

  String format = xdef['.Date format'];
  String separator = xdef['.Date separator'];

  // Экранируем разделитель для регулярного выражения
  String escapedSeparator = separator.replaceAll('.', '\\.');

  String pattern;
  switch (format) {
    case 'DD-MM-YYYY':
      pattern = '^\\d{1,2}$escapedSeparator\\d{1,2}$escapedSeparator\\d{4}\$';
      break;
    case 'MM-DD-YYYY':
      pattern = '^\\d{1,2}$escapedSeparator\\d{1,2}$escapedSeparator\\d{4}\$';
      break;
    case 'YYYY-MM-DD':
    default:
      pattern = '^\\d{4}$escapedSeparator\\d{1,2}$escapedSeparator\\d{1,2}\$';
      break;
  }

  return RegExp(pattern).hasMatch(input);
}

bool isValidDate(String input) {
  try {
    // Сначала преобразуем в формат хранения
    String storageFormat = dateToStorageFormat(input);

    // Разбиваем по ISO разделителю
    final parts = storageFormat.split('-');
    if (parts.length != 3) return false;

    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final day = int.parse(parts[2]);

    final date = DateTime(year, month, day);
    return date.year == year && date.month == month && date.day == day;
  } catch (e) {
    return false;
  }
}

bool isDateNotInFuture(String input) {
  try {
    // Сначала преобразуем в формат хранения
    String storageFormat = dateToStorageFormat(input);

    // Разбиваем по ISO разделителю
    final parts = storageFormat.split('-');
    if (parts.length != 3) return false;

    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final day = int.parse(parts[2]);

    final inputDate = DateTime(year, month, day);
    final currentDate = DateTime.now();

    return inputDate.isBefore(currentDate) || inputDate.isAtSameMomentAs(currentDate);
  } catch (e) {
    return false;
  }
}

bool isDateFromBeforeDateTo(String dateFrom, String dateTo) {
  try {
    // Преобразуем обе даты в формат хранения
    String fromStorage = dateToStorageFormat(dateFrom);
    String toStorage = dateToStorageFormat(dateTo);

    final from = DateTime.parse(fromStorage);
    final to = DateTime.parse(toStorage);
    return from.isBefore(to) || from.isAtSameMomentAs(to);
  } catch (e) {
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

// Updated helper function for showing localized date picker with proper colors
Future<DateTime?> showLocalizedDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
}) async {
  String lang = xdef['Program language'];
  Locale locale = Locale(getLocaleCode(lang));

  return showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: firstDate,
    lastDate: lastDate,
    locale: locale,
    builder: (BuildContext context, Widget? child) {
      return Theme(
        data: ThemeData.light().copyWith(
          colorScheme: ColorScheme.light(
            primary: clUpBar,
            onPrimary: clText,
            surface: clFill,
            onSurface: clText,
          ),
//          dialogBackgroundColor: clFon,
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: clText,
              backgroundColor: clUpBar,
            ),
          ),
        ),
        child: child!,
      );
    },
    // Add a simple note to guide users about the format
    helpText: '${lw('Select date')} (${getDateFormatHint()})',
  );
}

// Convert display date string to integer format YYYYMMDD for storage
int dateToStorageInt(String displayDate) {
  if (displayDate.isEmpty) return 0;

  // First convert to standard format
  String isoDate = dateToStorageFormat(displayDate);

  try {
    // Parse the ISO date (YYYY-MM-DD)
    List<String> parts = isoDate.split('-');
    if (parts.length != 3) return 0;

    int year = int.parse(parts[0]);
    int month = int.parse(parts[1]);
    int day = int.parse(parts[2]);

    // Format as YYYYMMDD integer
    return year * 10000 + month * 100 + day;
  } catch (e) {
    myPrint('Error converting date to int: $e');
    return 0;
  }
}

// Convert integer YYYYMMDD from storage to formatted display date
String dateFromStorageInt(int dateInt) {
  if (dateInt <= 0) return '';

  try {
    // Extract year, month, day from YYYYMMDD format
    int year = dateInt ~/ 10000;
    int month = (dateInt % 10000) ~/ 100;
    int day = dateInt % 100;

    // Format to YYYY-MM-DD
    String isoDate = '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';

    // Convert to display format based on user settings
    return dateFromStorageFormat(isoDate);
  } catch (e) {
    myPrint('Error converting int to date: $e');
    return '';
  }
}

// Get today's date as YYYYMMDD integer
int getTodayAsInt() {
  final now = DateTime.now();
  return now.year * 10000 + now.month * 100 + now.day;
}

// Validate integer date format
bool isValidDateInt(int dateInt) {
  if (dateInt <= 0) return false;

  try {
    int year = dateInt ~/ 10000;
    int month = (dateInt % 10000) ~/ 100;
    int day = dateInt % 100;

    // Check if date is valid
    if (year < 1900 || year > 2100) return false;
    if (month < 1 || month > 12) return false;
    if (day < 1 || day > 31) return false;

    // Check specific month lengths
    if (month == 2) {
      bool isLeapYear = (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
      if (day > (isLeapYear ? 29 : 28)) return false;
    } else if ([4, 6, 9, 11].contains(month) && day > 30) {
      return false;
    }

    return true;
  } catch (e) {
    return false;
  }
}

// Check if a date is in the future (for validation)
bool isDateIntInFuture(int dateInt) {
  if (dateInt <= 0) return false;

  int todayInt = getTodayAsInt();
  return dateInt > todayInt;
}

// Compare two dates (returns true if dateFrom is before or equal to dateTo)
bool isDateIntFromBeforeDateIntTo(int dateFromInt, int dateToInt) {
  if (dateFromInt <= 0 || dateToInt <= 0) return false;
  return dateFromInt <= dateToInt;
}

// Helper function for SQL queries with date comparison
String sqlDateCondition(String fieldName, String displayDate) {
  int dateInt = dateToStorageInt(displayDate);
  return "$fieldName = $dateInt";
}

// Create a range condition for dates
String sqlDateRangeCondition(String fieldName, String fromDate, String toDate) {
  int fromDateInt = dateToStorageInt(fromDate);
  int toDateInt = dateToStorageInt(toDate);
  return "$fieldName BETWEEN $fromDateInt AND $toDateInt";
}

// Updated validator for date input field
bool validateDateInput(String input) {
  if (!isValidDateFormat(input)) {
    return false; // Invalid format
  }

  int dateInt = dateToStorageInt(input);
  if (!isValidDateInt(dateInt)) {
    return false; // Invalid date
  }

  if (isDateIntInFuture(dateInt)) {
    return false; // Date is in the future
  }

  return true; // Date is valid
}

// Convert DateTime object to int format YYYYMMDD
int dateTimeToInt(DateTime dateTime) {
  return dateTime.year * 10000 + dateTime.month * 100 + dateTime.day;
}

// Convert int format YYYYMMDD to DateTime object
DateTime intToDateTime(int dateInt) {
  if (dateInt <= 0) {
    return DateTime.now(); // Default to today if invalid
  }

  int year = dateInt ~/ 10000;
  int month = (dateInt % 10000) ~/ 100;
  int day = dateInt % 100;

  return DateTime(year, month, day);
}

// Updated function for date picker to work with new format
Future<String> showDatePickerWithFormat({
  required BuildContext context,
  required String currentDate,
}) async {
  DateTime initialDate;

  // Convert current date string to DateTime
  if (currentDate.isEmpty) {
    initialDate = DateTime.now();
  } else {
    int dateInt = dateToStorageInt(currentDate);
    initialDate = intToDateTime(dateInt);
  }

  // Ensure initialDate is valid and not in the future
  if (initialDate.isAfter(DateTime.now())) {
    initialDate = DateTime.now();
  }

  // Show date picker
  final DateTime? pickedDate = await showLocalizedDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: DateTime(1900),
    lastDate: DateTime.now(),
  );

  // Return formatted date if user selected one
  if (pickedDate != null) {
    int dateInt = dateTimeToInt(pickedDate);
    return dateFromStorageInt(dateInt);
  }

  // Return original date if canceled
  return currentDate;
}
