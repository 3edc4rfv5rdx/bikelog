import 'package:flutter/material.dart';
import 'dart:io'; // For File and Directory operations
import 'filter_screen.dart'; // Import the filter screen
import 'settings_screen.dart'; // Import the settings screen
import 'package:flutter/services.dart';
import 'globals.dart'; // Import global variables (xv, xdef, etc.)

class BikeLogScreen extends StatefulWidget {
  const BikeLogScreen({super.key});

  @override
  _BikeLogScreenState createState() => _BikeLogScreenState();
}

class _BikeLogScreenState extends State<BikeLogScreen> with RouteAware {
  List<Map<String, dynamic>> actions = [];
  int? selectedIndex;
  Map<String, dynamic>? currentFilters;
  bool _pinVerified = false;

  final Map<String, String> menuLabels = {
    'filters': lw('Filters'),
    'settings': lw('Settings'),
    'sum': lw('Sum'),
    'reportToCSV': lw('Report to CSV'),
    'refresh': lw('Refresh'),
    'about': lw('About')
  };

  @override
  void initState() {
    super.initState();
    // Используем addPostFrameCallback для отложенного выполнения
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPinProtection();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)! as PageRoute);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    setState(() {
      _loadActions();
    });
  }

  Future<void> _checkPinProtection() async {
    if (xdef['Use PIN'] == 'true' && !_pinVerified) {
      final pin = await showPinDialog(mode: PinDialogMode.verify);

      if (pin != null) {
        setState(() {
          _pinVerified = true;
        });
        _loadActions();
      } else {
        // Если PIN не прошел проверку (3 неудачные попытки)
        SystemNavigator.pop(); // Выход из приложения
      }
    } else {
      _loadActions();
    }
  }

  Future<void> _exportActionsToCSV() async {
    try {
      // Create the directory for reports if it doesn't exist
      String reportDir = '$xvBakDir/reports';
      await newMakeDir(reportDir);
      // Generate a timestamp for the filename
      DateTime now = DateTime.now();
      String timestamp = "${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}";
      timestamp += "${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}";
      // Create the file with a timestamp
      File csvFile = File('$reportDir/actions-$timestamp.csv');
      IOSink sink = csvFile.openWrite();
      // Write header row if there's data
      if (actions.isNotEmpty) {
        // Get the keys from the first item for the header
        sink.writeln(actions.first.keys.join(','));
        // Write each row of data
        for (var row in actions) {
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
      } else {
        // If no data, just write a header row with standard fields
        sink.writeln('num,date,owner,brand,model,price,event,comment');
      }
      await sink.flush();
      await sink.close();
      String msg = 'Report exported to CSV';
      okInfoBarGreen(lw(msg));
      myPrint('$msg: ${csvFile.path}');
    } catch (e) {
      String msg = lw('Error exporting report to CSV');
      okInfoBarRed('$msg: $e');
      myPrint('$msg: $e');
    }
  }

  String _getIndicatorText() {
    if (xvFilter != '') {
      return '(F)';
    }
    final lastActions = int.tryParse(xdef['Last actions']) ?? 0;
    if (lastActions > 0) {
      return '($lastActions)';
    }
    return '(${lw('All')})';
  }

  void _showAbout() {
    String txt = lw('BikeLogBook');
    txt += '\n\n';
    txt += '${lw('Version')}: $progVersion\n\n';
//    txt += '${lw('Date')}: $progDate\n';
    txt += '(c): $progAuthor 2025\n';
//    txt += '$progEmail\n';
    // txt += '$progSite\n\n';
    if (xvBusiness == true) {
      txt += '${lw('Edition')}: $progEdition\n';
      txt += '${lw('Owners')}: $progOwners\n';
      txt += '${lw('Bikes')}: $progBikes\n';
    }
    txt += '\n';
    txt += lw('Long press to HELP');
    okInfo(txt);
  }

  // Function to load actions from the database
  Future<void> _loadActions() async {
    // Не загружаем данные, если PIN-защита включена, но PIN не прошел проверку
    if (xdef['Use PIN'] == 'true' && !_pinVerified) {
      return;
    }

    // Build the SQL query
    final String dateSort = xdef['Newest first'] == 'true' ? 'desc' : '';
    String sql = '''
    select actions.num as num, actions.date as date, owners.name as owner,
           bikes.brand as brand, bikes.model as model, actions.price as price, 
           events.name as event, actions.comment as comment
    from actions
    inner join owners on bikes.owner = owners.num
    inner join events on actions.event = events.num
    inner join bikes on actions.bike = bikes.num
    $xvFilter
    order by date $dateSort, owner, brand, model, price, event, num
  ''';

    // Add LIMIT clause if lines > 0
    // Convert xdef['Last actions'] to an integer
    int lines = int.tryParse(xdef['Last actions']) ?? 0;
    if (lines > 0) {
      sql += ' limit $lines offset 0';
    }
    sql += ';';

    // Execute the query using your getDbData function
    final actionsFromDb = await getDbData(sql);

    // Format dates according to user's preferences before setting state
    final formattedActions = actionsFromDb.map((action) {
      // Create a copy of the action map
      Map<String, dynamic> formattedAction = Map<String, dynamic>.from(action);

      // Format the date field if it exists
      if (formattedAction.containsKey('date') && formattedAction['date'] != null) {
        formattedAction['date'] = dateFromStorageFormat(formattedAction['date']);
      }

      return formattedAction;
    }).toList();

    // Update the state with the fetched data
    setState(() {
      actions = formattedActions; // Use formatted actions
    });
  }

  // Handle short tap (highlight the row)
  void _handleShortTap(int index) {
    setState(() {
      selectedIndex = index; // Highlight the selected row
    });
  }


  void _handleLongTap(int index) {
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) {
        return AlertDialog(
          backgroundColor: clMenu,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onLongPress: () => okHelp(16),
                child:   ListTile(
                  title: Text(
                    lw('EDIT'),
                    style: TextStyle(fontSize: fsNormal, fontWeight: fwNormal, color: clText),
                  ),
                  onTap: () {
                    Navigator.pop(context); // Close the dialog
                    _editAction(index);     // Call the edit function
                  },
                ),
              ),
              GestureDetector(
                onLongPress: () => okHelp(17),
                child: ListTile(
                  title: Text(lw('DELETE'),
                    style: TextStyle(fontSize: fsNormal, fontWeight: fwNormal, color: clText),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _deleteAction(index);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

// For editing action
  void _editAction(int index) async {
    final action = actions[index];
    final actionNum = action['num'];
    final result = await Navigator.pushNamed(
      context,
      '/add_action',
      arguments: actionNum,
    );
    if (result == true) {
      setState(() {
        selectedIndex = null;  // Сбрасываем выделение
      });
      _loadActions();
    }
  }


  Future<void> _deleteAction(int index) async {
    final action = actions[index];
    final num = action['num']; // Get the record ID
    // Show confirmation dialog
    final shouldDelete = await okConfirm(
      title: lw('Warning'),
      message: lw('Are you sure you want to delete this action?'),
    );
    if (shouldDelete) {
      final sql = 'delete from actions where num = $num;';
      await setDbData(sql);
      await _loadActions(); // refresh
      setState(() {
        selectedIndex = null; // Clear the selection
      });
      okInfoBarGreen(lw('Action deleted successfully'));
    }
  }

// Handle menu item selection
  void _onMenuItemSelected(String value) async {  // Добавляем async
    switch (value) {
      case 'filters':
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FilterScreen(initialFilters: currentFilters),
          ),
        );
        if (result != null) {
          setState(() {
            currentFilters = result;
          });
          await _loadActions(); // Перезагружаем список с новыми фильтрами
        }
        break;
      case 'settings':
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const SettingsScreen(),
          ),
        );
        if (result == true) {
          await _loadActions();
        }
        break;
      case 'sum':
        _showTotalSum();
        break;
      case 'reportToCSV':
        _exportActionsToCSV();
      case 'refresh':
        _loadActions();
        break;
      case 'about':
        _showAbout();
        break;
    }
  }


  void _showTotalSum() async {
    double totalSum;
    int totalCount;

    // Если есть фильтр, используем текущие actions
    if (xvFilter != '') {
      totalSum = actions.fold(0.0, (sum, action) {
        final price = action['price'] ?? 0.0;
        return sum + (price is String ? double.tryParse(price) ?? 0.0 : price);
      });
      totalCount = actions.length;
    }
    // Иначе делаем запрос на все записи
    else {
      String sql = 'SELECT COUNT(*) as count, SUM(price) as total FROM actions';
      final result = await getDbData(sql);
      totalSum = result[0]['total'] ?? 0.0;
      totalCount = result[0]['count'] ?? 0;
    }

    String sumStr = xdef['Round to integer'] == 'true'
        ? totalSum.round().toString()
        : totalSum.toStringAsFixed(2);

    String msg = '${lw('The total sum')}: $sumStr\n';
    msg += '${lw('Number of actions')}: $totalCount';
    okInfo(msg);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: clFon,
      appBar: AppBar(
        backgroundColor: clUpBar,
        title: GestureDetector(
          onLongPress: () => okHelp(1), // help_id for the title
          child: Text(lw('BikeLogBook'),
            style: TextStyle(color: clText, fontSize: fsLarge, fontWeight: fwNormal,),
          ),
        ),
        leading: GestureDetector(
          onLongPress: () => okHelp(9),
          child: IconButton(
            icon: const Icon(Icons.close),
            color: clText,
            onPressed: () async {
              await compactDatabase();
              SystemNavigator.pop();
            },
          ),
        ),
        actions: [
          Container(
            padding: const EdgeInsets.only(right: 10),
            child: Center(
              child: Text(
                _getIndicatorText(),
                style: TextStyle(
                  color: clText,
                  fontSize: fsNormal,
                ),
              ),
            ),
          ),
          GestureDetector(
            onLongPress: () => okHelp(10), // help_id for the menu button
            child: PopupMenuButton<String>(
              icon: Icon(Icons.menu, color: clText), // Menu icon
              iconSize: 24,
              onSelected: _onMenuItemSelected,
              color: clMenu,
              offset: const Offset(0, 50),
              itemBuilder: (BuildContext context) {
                return menuLabels.entries.map((entry) {
                  return PopupMenuItem<String>(
                    value: entry.key,
                    child: GestureDetector(
                      onLongPress: () {
                        switch (entry.key) {
                          case 'filters':
                            okHelp(11); // help_id = 3 for Filters
                            break;
                          case 'settings':
                            okHelp(12); // help_id = 4 for Settings
                            break;
                          case 'sum':
                            okHelp(13); // help_id = 5 for Sum
                            break;
                          case 'reportToCSV':
                            okHelp(18); // New help ID for Report to CSV
                            break;
                          case 'refresh':
                            okHelp(14); // help_id = 9 for Refresh
                            break;
                          case 'about':
                            okHelp(15); // help_id = 10 for About
                            break;
                        }
                      },
                      child: Text(entry.value,
                        style: TextStyle(color: clText, fontSize: fsNormal,),
                      ),
                    ),
                  );
                }).toList();
              },
            ),
          ),
        ],
      ),

      body: Scrollbar(
        // Установка thumbVisibility: true делает скролл-бар постоянно видимым
        thumbVisibility: true,
        // Радиус закругления для скролл-бара
        radius: const Radius.circular(15),
        // Толщина скролл-бара
        thickness: 6,
        // Делаем скролл-бар интерактивным для перетаскивания
        interactive: true,
        child: ListView.builder(
          itemCount: actions.length,
          itemBuilder: (context, index) {
            final action = actions[index];
            return GestureDetector(
              onTap: () => _handleShortTap(index),
              onLongPress: () => _handleLongTap(index),
              child: Container(
                color: selectedIndex == index
                    ? clSel
                    : null,
                child: ListTile(
                  title: Text(
                    '${action['date'] ?? lw('Unknown')} - ' +
                        '${action['owner'] ?? lw('Unknown')} - ' +
                        '${action['brand'] ?? lw('Unknown')} - ' +
                        '${action['model'] ?? lw('Unknown')} - ' +
                        '${action['price'] ?? '0.0'} - ' +
                        '${action['event'] ?? lw('Unknown')} - ' +
                        '${action['comment'] ?? lw('No comment')}',
                    style: TextStyle(color: clText,fontSize: fsNormal),
                  ),
                ),
              ),
            );
          },
        ),
      ),

      floatingActionButton: GestureDetector(
        onLongPress: () => okHelp(8), // help_id = 8 for the FAB
        child: FloatingActionButton(
          onPressed: () {
            // Navigate to AddActionScreen
            Navigator.pushNamed(
              context,
              '/add_action',
            ).then((_) {
              _loadActions(); // Reload actions after returning
            });
          },
          backgroundColor: clUpBar,
          foregroundColor: clText,
          child: const Icon(Icons.add, size: 32,),
        ),
      ),
    );
  }
}
