import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart'; // For Linux
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'dart:io';

// Global key for accessing ScaffoldMessenger
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
// Global key for NavigatorState
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

// Global Map for settings
Map<String, dynamic> xdef = {
  'Program language': 'EN',
  'Color theme': 'Light', // N 0
  'Last actions': '0',
  'Exchange rate': '42',
  'Several actions': 'false',
  'Back after clear': 'true',
  'Round to integer': 'true',
  '.First start': 'false',
  '.Prog version': progVersion,
};

bool xvDebug = true;
String xvFilter = '';
String xvSelect = '???';
String xvHomePath = '/home/e/Documents';
String xvExt1Path = '';
String xvMainHome = '';
String xvLangHome = '';
String xvHelpHome = '';
String xvSettHome = '';
String xvBakDir = '';
bool xvBusiness = false;

const String progVersion = '0.8.250304';
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
const List<String> appLANGUAGES = ['EN','RU','UA',]; // if change, look at main/_getLocaleCode
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

const double fsSmall = 13;  // Small font size
const double fsNormal = 15; // Main font size
const double fsLarge = 18;  // Font size for headers

const FontWeight fwBold = FontWeight.bold;
const FontWeight fwNormal = FontWeight.normal;

bool dbMainBusy = false;
bool dbHelpBusy = false;
bool dbLangBusy = false;

const String prgName = 'bikelog';
// Main database and SQL file
const String mainDb = '${prgName}_main.db';
const String mainSql = '${prgName}_main.sql';
// Language database and SQL file
const String langDb = '${prgName}_lang.db';
const String langSql = '${prgName}_lang.sql';
// Help database and SQL file
const String helpDb = '${prgName}_help.db';
const String helpSql = '${prgName}_help.sql';
// Sett database and SQL file
const String settDb = '${prgName}_sett.db';
//const String settSql = '${prgName}_sett.sql';

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
            child: Text(lw('Yes')),
          ),
        ],
        elevation: 10.0,
      );
    },
  );
}

/// Retrieves help text from the database based on the specified help ID and current language
Future<String> getHelpText(int helpId) async {
  if (helpId == 0) return '';

  dbHelpBusy = true;
  Database? database;

  try {
    final columnName = xdef['Program language'].toUpperCase();
    final sql = 'SELECT $columnName FROM help WHERE num = ?';

    database = await myOpenDatabase(xvHelpHome);
    final result = await database.rawQuery(sql, [helpId]);

    if (result.isEmpty || result.first.values.first == null) {
      throw Exception(lw('Help text not found'));
    }

    return result.first.values.first.toString();

  } on DatabaseException catch (e) {
    final errorMsg = lw('An SQLite error occurred');
    okInfoBarPurple('$errorMsg: $e (helpId=$helpId)');
    return lw('DB Error');

  } catch (e) {
    final errorMsg = lw('An error occurred');
    okInfoBarPurple('$errorMsg: $e (helpId=$helpId)');
    return lw('Error');

  } finally {
    await database?.close();
    dbHelpBusy = false;
  }
}

/// Shows help dialog with text from database
void okHelp(int helpId) async {
  if (helpId == 0) return;

  final helpText = await getHelpText(helpId);
  if (helpText.isNotEmpty) {
    showCustomDialog(
      title: lw('Help'),
      message: helpText,
      color: Colors.blue,
      icon: Icons.info_outline,
    );
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

Future<void> initTranslations() async {
  String lang = xdef['Program language'].toLowerCase();
  if (lang == 'en') return;

  try {
    String sql = 'select word as word, $lang as $lang from langs where tag is null';
    List<Map<String, dynamic>> result = await getLangData(sql);

    _translationCache.clear(); // Clear the cache before updating
    for (var row in result) {
      _translationCache[row['word']] = row[lang];
    }
    myPrint('initTranslations finished');
  } catch (e) {
    myPrint('Error initializing translations: $e');
    rethrow;
  }
}

// Function to translate a word
String lw(String wrd) {
  String lang = xdef["Program language"].toUpperCase();
  if (lang == 'EN') {
    return wrd;
  }
  return _translationCache[wrd] ?? '*<( $wrd )>*';
}


// Function to validate the date format (YYYY-MM-DD)
bool isValidDateFormat(String input) {
  final RegExp dateRegex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
  return dateRegex.hasMatch(input);
}

// Function to check if the date is valid (e.g., not February 30)
bool isValidDate(String input) {
  try {
    final parts = input.split('-');
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

// Function to check if the date is not in the future
bool isDateNotInFuture(String input) {
  try {
    final parts = input.split('-');
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

// Function to validate the date input (format, validity, and not in the future)
bool validateDateInput(String input) {
  if (!isValidDateFormat(input)) {
    return false; // Invalid format
  }
  if (!isValidDate(input)) {
    return false; // Invalid date
  }
  if (!isDateNotInFuture(input)) {
    return false; // Date is in the future
  }
  return true; // Date is valid
}

// Function to validate the price input
bool validatePriceInput(String input) {
  if (input.isEmpty) {
    return true; // Allow empty price
  }
  final RegExp priceRegex = RegExp(r'^\d+(\.\d{1,2})?$');
  return priceRegex.hasMatch(input);
}

// Function to check if date-from is not greater than date-to
bool isDateFromBeforeDateTo(String dateFrom, String dateTo) {
  try {
    final from = DateTime.parse(dateFrom);
    final to = DateTime.parse(dateTo);
    return from.isBefore(to) || from.isAtSameMomentAs(to);
  } catch (e) {
    return false;
  }
}

// Function to execute a SQL query on the language database
Future<List<Map<String, dynamic>>> getLangData(String sql) async {
  dbLangBusy = true;
  Database? database;
  List<Map<String, dynamic>> result = []; // Default value
  try {
    database = await myOpenDatabase(xvLangHome);
    result = await database.rawQuery(sql);
  } catch (e) {
    myPrint('Error in getLangData: $e');
    rethrow;
  } finally {
    if (database != null) {
      await database.close();
    }
    dbLangBusy = false;
  }
  return result;
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
  //    .replaceAll('"', "''")
      .replaceAll('\\', '\\\\');
  return escaped;
}

