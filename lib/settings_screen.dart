import 'package:flutter/material.dart';
import 'dart:io';  // Для работы с File и IOSink
import 'package:file_picker/file_picker.dart';
import 'package:sqflite/sqflite.dart';
import 'globals.dart';


const List<String> appTables = ['actions','types','owners','bikes','events'];
String currentDate = '';
String backupDirPath = '';

// Добавьте эту функцию в класс _SettingsScreenState
Future<void> processSqlFile() async {
  try {
    // Выбираем SQL файл
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['sql'],
    );

    if (result == null || result.files.single.path == null) {
      myPrint('No file selected');
      return;
    }

    String filePath = result.files.single.path!;
    myPrint('Selected SQL file: $filePath');

    // Считываем содержимое файла
    File sqlFile = File(filePath);
    String sqlContent = await sqlFile.readAsString();

    // Очищаем от комментариев и делим на запросы
    sqlContent = sqlContent.replaceAll(RegExp(r'/\*.*?\*/', dotAll: true), '');

    List<String> queries = sqlContent
        .split(';')
        .map((q) => q
        .split('\n')
        .where((line) => !line.trim().startsWith('--'))
        .join(' '))
        .map((q) => q.trim())
        .where((q) => q.isNotEmpty)
        .toList();

    // Выполняем запросы
    Database? database;
    try {
      database = await myOpenDatabase(xvMainHome);

      // Начинаем транзакцию
      await database.transaction((txn) async {
        for (String query in queries) {
          myPrint('Executing query: ${query.length > 50 ? query.substring(0, 50) + "..." : query}');
          await txn.execute(query);
        }
      });

      okInfoBarGreen(lw('SQL file executed successfully'));
      myPrint('SQL file executed successfully');
    } finally {
      if (database != null) {
        await database.close();
      }
    }
  } catch (e) {
    String msg = lw('Error processing SQL file');
    myPrint('Error: $e');
    okInfoBarRed('$msg: $e');
  }
}

Future<String?> selectRestoreDirectory() async {
  try {
    String initialDir = xvBakDir;
    String? selectedDir = await FilePicker.platform.getDirectoryPath(
      initialDirectory: initialDir,
    );
    return selectedDir;
  } catch (e) {
    String msg = lw('Error selecting directory');
    okInfoBarRed('$msg: $e');
    return null;
  }
}

Future<bool> restoreFromFiles(String backupDir) async {
  try {
    myPrint('Starting file restore from directory: $backupDir');
    List<(String, String)> filePairs = [
      (xvMainHome, '$backupDir/${xvMainHome.split('/').last}'),
      (xvSettHome, '$backupDir/${xvSettHome.split('/').last}'),
    ];

    for (var pair in filePairs) {
      myPrint('Copying file from ${pair.$2} to ${pair.$1}');
      File sourceFile = File(pair.$2);
      await sourceFile.copy(pair.$1);
    }
    myPrint('File restore completed successfully');
    return true;
  } catch (e) {
    String msg = lw('Error restoring from files');
    myPrint('Restore error: $e');
    okInfoBarRed('$msg: $e');
    return false;
  }
}


Future<bool> restoreFromCSV(String csvDir) async {
  try {
    myPrint('Starting CSV restore from directory: $csvDir');
    for (String tableName in appTables) {
      myPrint('Processing table: $tableName');
      File csvFile = File('$csvDir/main-$tableName.csv');
      if (!await csvFile.exists()) {
        myPrint('CSV file not found for table: $tableName');
        continue;
      }
      List<String> lines = await csvFile.readAsLines();
      if (lines.isEmpty) {
        myPrint('Empty CSV file for table: $tableName');
        continue;
      }
      await setDbData('DELETE FROM $tableName;');
      List<String> headers = parseCSVLine(lines[0]);
      myPrint('Processing ${lines.length - 1} records for table: $tableName');
      for (int i = 1; i < lines.length; i++) {
        List<String> values = parseCSVLine(lines[i]);
        if (values.length != headers.length) {
          myPrint('Skipping malformed line: ${lines[i]}');
          continue;
        }
        String columns = headers.join(',');
        String vals = values.map((v) => "'${v.replaceAll("'", "''")}'").join(',');
        await setDbData('INSERT INTO $tableName ($columns) VALUES ($vals);');
      }
    }
    myPrint('CSV restore completed successfully');
    return true;
  } catch (e) {
    String msg = lw('Error restoring from CSV');
    myPrint('CSV restore error: $e');
    okInfoBarRed('$msg: $e');
    return false;
  }
}

// Helper function to properly parse CSV lines with quoted values
List<String> parseCSVLine(String line) {
  List<String> result = [];
  bool inQuotes = false;
  String currentValue = '';
  for (int i = 0; i < line.length; i++) {
    String char = line[i];
    if (char == '"') {
      // Check if this is an escaped quote (double quote)
      if (i + 1 < line.length && line[i + 1] == '"') {
        currentValue += '"';
        i++; // Skip the next quote
      } else {
        // Toggle the inQuotes flag
        inQuotes = !inQuotes;
      }
    } else if (char == ',' && !inQuotes) {
      // End of value
      result.add(currentValue);
      currentValue = '';
    } else {
      // Add character to current value
      currentValue += char;
    }
  }
  // Add the last value
  result.add(currentValue);
  return result;
}


// Основная функция бекапа базы
Future<bool> backupDatabase() async {
  DateTime now = DateTime.now();
  currentDate = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  backupDirPath = '$xvBakDir/bak-$currentDate';
  myPrint('Starting database backup to: $backupDirPath');
  // Создаем каталог для бекапа
  if (!await newMakeDir(backupDirPath)) {
    myPrint('Failed to create backup directory');
    return false;
  }
  // Копируем файлы базы данных
  List<String> dbFiles = [xvMainHome, xvSettHome];
  myPrint('Copying database files to backup directory');
  bool result = await copyFiles(dbFiles, backupDirPath);
  myPrint(result ? 'Database backup completed successfully' : 'Database backup failed');
  return result;
}

Future<bool> backupToCSV() async {
  myPrint('Starting CSV backup to: $backupDirPath');
  try {
    for (String tableName in appTables) {
      List<Map<String, dynamic>> data = await getDbData("SELECT * FROM $tableName");
      File csvFile = File('$backupDirPath/main-$tableName.csv');
      IOSink sink = csvFile.openWrite();
      if (data.isNotEmpty) {
        // Write header row
        sink.writeln(data.first.keys.join(','));
        // Write data rows with proper CSV formatting
        for (var row in data) {
          // Process each value properly for CSV format
          List<String> formattedValues = row.values.map((value) {
            // If value is a string, enclose in quotes and escape any existing quotes
            if (value is String) {
              String escapedValue = value.replaceAll('"', '""');
              return '"$escapedValue"';
            } else if (value == null) {
              return '""'; // Empty quoted string for null values
            } else {
              return value.toString(); // Numbers don't need quotes
            }
          }).toList();
          sink.writeln(formattedValues.join(','));
        }
      }
      await sink.flush();
      await sink.close();
    }
    String msg = 'CSV export completed';
    myPrint(msg);
    okInfoBarGreen(lw(msg));
    return true;
  } catch (e) {
    String msg = 'Error exporting tables to CSV';
    myPrint(msg);
    okInfoBarPurple(lw(msg) + ': ' + e.toString());
    return false;
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _backupWithCSV = false; // State for Backup + CSV
  bool _restoreWithCSV = false; // State for Restore + CSV

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: clFon,
      // Модифицированный AppBar в SettingsScreen
      appBar: AppBar(
        backgroundColor: clUpBar,
        title: GestureDetector(
          onLongPress: () => okHelp(7), // help_id для заголовка
          child: Text(
            lw('Settings'),
            style: TextStyle(color: clText, fontSize: fsLarge, fontWeight: fwNormal,),
          ),
        ),
        leading: GestureDetector(
          onLongPress: () {
            okHelp(9);
          },
          child: IconButton(
            icon: Icon(Icons.arrow_back, color: clText),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        // Добавляем кнопку в AppBar
        actions: [
          GestureDetector(
            onLongPress: () => okHelp(67), // Добавьте соответствующий ID для справки
            child: IconButton(
              icon: Icon(Icons.download, color: clUpBar), // Иконка для SQL
              onPressed: () {
                processSqlFile(); // Вызов функции обработки SQL-файла
              },
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Top block of buttons (75% width)
          Column(
            children: [
              const SizedBox(height: 20), // Add some space at the top
              // Options Button
              Center(
                child: FractionallySizedBox(
                  widthFactor: 0.75, // Set width to 75% of the available space
                  child: GestureDetector(
                    onLongPress: () => okHelp(60), // help_id = 2 for Options
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: clUpBar, // Set button background color to clUpBar
                        foregroundColor: clText, // Set button text color to clText
                        minimumSize: const Size(double.infinity, 48), // Set button height
                      ),
                      onPressed: () {
                        // Navigate to the Options Settings screen
                        Navigator.pushNamed(context, '/options_settings');
                      },
                      child: Text(
                        lw('Options'),
                        style: TextStyle(fontWeight: fwNormal, fontSize: fsNormal, color: clText,),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Owner Settings Button
              Center(
                child: FractionallySizedBox(
                  widthFactor: 0.75, // Set width to 75% of the available space
                  child: GestureDetector(
                    onLongPress: () => okHelp(61), // help_id = 3 for Owner Settings
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: clUpBar, // Set button background color to clUpBar
                        foregroundColor: clText, // Set button text color to clText
                        minimumSize: const Size(double.infinity, 48), // Set button height
                      ),
                      onPressed: () {
                        // Navigate to the Reference Settings screen with refMode = 1 (Owner)
                        Navigator.pushNamed(
                          context,
                          '/reference_settings',
                          arguments: 1, // 1 for Owner
                        );
                      },
                      child: Text(
                        lw('Owners Management'),
                        style: TextStyle(fontWeight: fwNormal, fontSize: fsNormal, color: clText,),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Type Settings Button
              Center(
                child: FractionallySizedBox(
                  widthFactor: 0.75, // Set width to 75% of the available space
                  child: GestureDetector(
                    onLongPress: () => okHelp(62), // help_id = 4 for Type Settings
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: clUpBar, // Set button background color to clUpBar
                        foregroundColor: clText, // Set button text color to clText
                        minimumSize: const Size(double.infinity, 48), // Set button height
                      ),
                      onPressed: () {
                        // Navigate to the Reference Settings screen with refMode = 2 (Type)
                        Navigator.pushNamed(
                          context,
                          '/reference_settings',
                          arguments: 2, // 2 for Type
                        );
                      },
                      child: Text(
                        lw('Types Management'),
                        style: TextStyle(fontWeight: fwNormal, fontSize: fsNormal, color: clText,),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Event Settings Button
              Center(
                child: FractionallySizedBox(
                  widthFactor: 0.75, // Set width to 75% of the available space
                  child: GestureDetector(
                    onLongPress: () => okHelp(63), // help_id = 5 for Event Settings
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: clUpBar, // Set button background color to clUpBar
                        foregroundColor: clText, // Set button text color to clText
                        minimumSize: const Size(double.infinity, 48), // Set button height
                      ),
                      onPressed: () {
                        // Navigate to the Reference Settings screen with refMode = 3 (Event)
                        Navigator.pushNamed(
                          context,
                          '/reference_settings',
                          arguments: 3, // 3 for Event
                        );
                      },
                      child: Text(
                        lw('Events Management'),
                        style: TextStyle(fontWeight: fwNormal, fontSize: fsNormal, color: clText,),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Bike Settings Button
              Center(
                child: FractionallySizedBox(
                  widthFactor: 0.75, // Set width to 75% of the available space
                  child: GestureDetector(
                    onLongPress: () => okHelp(64), // help_id = 6 for Bike Settings
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: clUpBar, // Set button background color to clUpBar
                        foregroundColor: clText, // Set button text color to clText
                        minimumSize: const Size(double.infinity, 48), // Set button height
                      ),
                      onPressed: () {
                        // Navigate to the Bike Settings screen
                        Navigator.pushNamed(context, '/bike_settings');
                      },
                      child: Text(lw('Bikes Management'),
                        style: TextStyle(fontWeight: fwNormal, fontSize: fsNormal, color: clText,),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Опускаем нижние кнопки на 50 пикселей
          const SizedBox(height: 50),

          // Bottom block of buttons (Backup and Restore) - 60% width
          Column(
            children: [
              // Backup Button and Checkbox
              Center(
                child: FractionallySizedBox(
                  widthFactor: 0.75, // Set width to 75% of the available space
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onLongPress: () => okHelp(65), // help_id = 7 for Backup
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: clUpBar, // Set button background color to clUpBar
                              foregroundColor: clText, // Set button text color to clText
                              minimumSize: const Size.fromHeight(48), // Set button height
                            ),
                            // Обработчик кнопки
                            onPressed: () async {
                              // Сначала делаем бекап базы
                              bool backupSuccess = await backupDatabase();
                              if (!backupSuccess) {
                                okInfoBarRed(lw('Database backup failed'));
                                return;
                              }

                              // Если включен CSV флаг, делаем экспорт в CSV
                              if (_backupWithCSV) {
                                bool csvSuccess = await backupToCSV();
                                if (!csvSuccess) {
                                  okInfoBarRed(lw('CSV export failed'));
                                  return;
                                }
                              }

                              setState(() {
                                _backupWithCSV = false; // Сбрасываем флаг после успешного выполнения
                              });
                              okInfoBarGreen(lw('Backup completed successfully'));
                            },
                            child: Text(
                              lw('Backup'),
                              style: TextStyle(fontWeight: fwNormal, fontSize: fsNormal, color: clText,),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      GestureDetector(
                        onLongPress: () => okHelp(68), // help_id = 8 for Backup Checkbox
                        child: Row(
                          children: [
                            Text(
                              '+csv',
                              style: TextStyle(fontWeight: fwNormal, fontSize: fsLarge, color: clText,),
                            ),
                            Transform.scale(
                              scale: 1.5, // Масштаб
                              child: Checkbox(
                                value: _backupWithCSV,
                                onChanged: (bool? value) {
                                  setState(() {
                                    _backupWithCSV = value ?? false;
                                  });
                                },
                                activeColor: clText, // Цвет фона Checkbox, когда он активен (выбран)
                                checkColor: clFill, // Цвет галочки (иконки) внутри Checkbox
                                side: BorderSide(color: clFrame),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Restore Button and Checkbox
              Center(
                child: FractionallySizedBox(
                  widthFactor: 0.75, // Set width to 75% of the available space
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onLongPress: () => okHelp(66), // help_id = 9 for Restore
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: clUpBar, // Set button background color to clUpBar
                              foregroundColor: clText, // Set button text color to clText
                              minimumSize: const Size.fromHeight(48), // Set button height
                            ),
                            onPressed: () async {
                              String? selectedDir = await selectRestoreDirectory();
                              if (selectedDir == null) {
                                return;
                              }

                              bool success;
                              if (_restoreWithCSV) {
                                success = await restoreFromCSV(selectedDir);
                              } else {
                                success = await restoreFromFiles(selectedDir);
                              }

                              if (success) {
                                setState(() {
                                  _restoreWithCSV = false; // Сбрасываем флаг после успешного выполнения
                                });
                                okInfoBarGreen(lw('Restore completed successfully'));
//                                Navigator.pop(context, true);  // Добавляем возврат с результатом
                              } else {
                                okInfoBarRed(lw('Restore failed. Check logs for details'));
                              }
                            },
                            child: Text(
                            lw('Restore'),
                              style: TextStyle(fontWeight: fwNormal, fontSize: fsNormal, color: clText,),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      GestureDetector(
                        onLongPress: () => okHelp(69), // help_id = 10 for Restore Checkbox
                        child: Row(
                          children: [
                            Text(
                              '+csv',
                              style: TextStyle(fontWeight: fwNormal, fontSize: fsLarge, color: clText,),
                            ),
                            Transform.scale(
                              scale: 1.5, // Масштаб
                              child: Checkbox(
                                value: _restoreWithCSV,
                                onChanged: (bool? value) {
                                  setState(() {
                                    _restoreWithCSV = value ?? false;
                                  });
                                },
                                activeColor: clText, // Цвет фона Checkbox, когда он активен (выбран)
                                checkColor: clFill, // Цвет галочки (иконки) внутри Checkbox
                                side: BorderSide(color: clFrame),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
