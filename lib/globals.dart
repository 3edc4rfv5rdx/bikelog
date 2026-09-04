import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/foundation.dart' show kReleaseMode;

export 'db_helpers.dart';
export 'ui_helpers.dart';
export 'date_helpers.dart';

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
  // Stored in plaintext by design: this is a casual lock, not a security
  // boundary. A 4-digit PIN is trivially brute-forceable, so hashing adds no
  // real protection.
  '.PIN code': '',
  '.First start': 'false',
  '.Prog version': progVersion,
};

// Debug logging follows the build type: on in debug and profile, off in release.
const bool xvDebug = !kReleaseMode;
String xvFilter = '';
// Bound arguments for the placeholders inside xvFilter (kept in sync with it).
List<dynamic> xvFilterArgs = [];
String xvSelect = '???';
String xvHomePath = ''; // set per-platform in initializePaths()
String xvExt1Path = '';
String xvMainHome = '';
String xvSettHome = '';
String xvBakDir = '';
String xvPhotoDir = ''; // persistent dir for bike photos, set in initializePaths()
bool xvBusiness = false;

// Subdirectory name for bike photos under xvHomePath, reused by backup/restore.
const String photoDirName = 'photos';

// Resolve a stored bike photo (filename only) to its full path. Empty stays
// empty. Photos live in xvPhotoDir so only the filename is persisted in the DB,
// keeping it valid across reinstalls and trivial to back up.
String bikePhotoPath(String? fileName) {
  if (fileName == null || fileName.isEmpty) return '';
  return '$xvPhotoDir/$fileName';
}

const String progVersion = '0.9.260903';
const int buildNumber = 71;
const String progAuthor = 'Eugen';
const String progEmail = '3edc4rfv5rdx@gmail.com';
const String progSite = 'bikelogbook.od.ua';
const String progGithub = 'https://github.com/3edc4rfv5rdx';

const List<(String, int, int)> prgEditions = [
  ('Personal', 1, 3),
  ('Family', 5, 10),
  ('PRO', 9999, 99999),
];
const int currVers = 2;  // 0-1-2
String get progEdition => prgEditions[currVers].$1;
int get progOwners => prgEditions[currVers].$2;
int get progBikes => prgEditions[currVers].$3;

// all program languages
const List<String> appLANGUAGES = ['EN','RU','UA',];

String getLocaleCode(String language) {
  // Dictionary only for exceptions where the country code differs
  final Map<String, String> exceptions = {
    'UA': 'uk',  // ukraine
    'GR': 'el',  // greek
    'CN': 'zh',  // china
    'JP': 'ja',  // japan
    'SE': 'sv',  // sveden
    'DK': 'da',  // Danish
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
    Color(0xFF121212),      // fon - almost black list background
    Color(0xFF5C5C5C),      // menu - medium-dark grey
    Color(0x4D6C6C6C),      // selected - grey with transparency
    Color(0xFF404040),      // upBar - dark grey
    Color(0xFFE0E0E0),      // text - light grey
    Color(0xFF4d4d4d),      // white
    Color(0xFF808080),      // grey
  ],
  // Green theme,  currentThemeIndex = 2
  [
    Color(0xFFF3F7ED),      // fon - light pistachio
    Color(0xFFD4E2C6),      // menu - sage
    Color(0x4D4C6B3D),      // selected - olive with transparency
    Color(0xFF97BA60),      // upBar - deep olive
    Color(0xFF121E0A),      // text - dark green
    Colors.white,          // fill
    Colors.grey,           // frame
  ],
  // blue theme = 3
  [
    Color(0xFFEDF7FB),      // fon - light azure
    Color(0xFFC6E0E9),      // menu - light blue
    Color(0x4D3D6B7F),      // selected - grey-blue with transparency
    Color(0xFF7FB8D5),      // upBar - deep blue
    Color(0xFF0A181E),      // text - dark blue
    Colors.white,          // fill
    Colors.grey,           // frame
  ],
  // Brown = 4
  [
    Color(0xFFF7F2ED),      // fon - light beige
    Color(0xFFE2D4C6),      // menu - light brown
    Color(0x4D6B4D3D),      // selected - brown with transparency
    Color(0xFFB69478),      // upBar - deep brown
    Colors.black,           // text
    Colors.white,          // fill
    Colors.grey,           // frame
  ],
  // purple = 5
  [
    Color(0xFFF2EDF7),      // fon - light lavender
    Color(0xFFD4C6E2),      // menu - light purple
    Color(0x4D5D3D6B),      // selected - purple with transparency
    Color(0xFF9A75B8),      // upBar - deep purple
    Color(0xFF180A1E),      // text - dark purple
    Color(0xFFFFFFFF),      // white
    Color(0xFF808080),      // grey
  ],
  // orange = 6
  [
    Color(0xFFF7F0ED),      // fon - light peach
    Color(0xFFE2CDC6),      // menu - light orange
    Color(0x4D6B533D),      // selected - orange with transparency
    Color(0xFFE59967),      // upBar - deep orange
    Color(0xFF1E120A),      // text - dark brown
    Color(0xFFFFFFFF),      // white
    Color(0xFF808080),      // grey
  ],
];

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

// Common text styles (non-const because colors change with theme)
TextStyle get tsNormal => TextStyle(fontSize: fsNormal, fontWeight: fwNormal, color: clText);
TextStyle get tsLarge => TextStyle(fontSize: fsLarge, fontWeight: fwNormal, color: clText);

const String prgName = 'bikelog';
// Main database and SQL file
const String mainDb = '${prgName}_main.db';
const String mainSql = '${prgName}_main.sql';
const String settDb = '${prgName}_sett.db';
// Adding a constant for the help file path
const String helpFile = 'assets/help.json';
const String langFile = 'assets/locales.json';
const String refFile = 'assets/references.json';

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
  return (index == -1) ? 0 : index;
}

// get theme name by index
String getThemeName(int index) {
  if (index >= 0 && index < appTHEMES.length) {
    return appTHEMES[index];
  }
  return appTHEMES[0];
}

// Function to initialize translations
Map<String, String> _translationCache = {};

// New function for loading localizations from a JSON file
Future<void> initTranslations() async {
  String lang = xdef['Program language'].toLowerCase();
  // No cache needed for English
  if (lang == 'en') { _translationCache.clear(); return; }
  try {
    // Load the JSON file with localizations
    final String jsonString = await rootBundle.loadString(langFile);
    final Map<String, dynamic> allTranslations = json.decode(jsonString);
    // Clear the cache before updating
    _translationCache.clear();
    // Fill the cache with translations for the current language
    allTranslations.forEach((key, value) {
      if (value is Map && value.containsKey(lang)) {
        _translationCache[key] = value[lang];
      }
    });
    myPrint('initTranslations finished, loaded ${_translationCache.length} translations');
  } catch (e) {
    myPrint('Error initializing translations: $e');
    _translationCache.clear();
  }
}

// Function to translate a word
String lw(String wrd) {
  String lang = xdef['Program language'];
  if (lang == 'EN') { return wrd; }
  return _translationCache[wrd] ?? '(( $wrd ))';
}

// Function to validate the price input
bool validatePriceInput(String input) {
  if (input.isEmpty) {
    return true;
  }
  // Accept 5, 5.5, .5 and 5. (up to 2 decimals); reject a lone dot.
  final RegExp priceRegex = RegExp(r'^(\d+\.?\d{0,2}|\.\d{1,2})$');
  return priceRegex.hasMatch(input);
}

void myPrint(String msg) {if (xvDebug) print('>>> $msg');}
