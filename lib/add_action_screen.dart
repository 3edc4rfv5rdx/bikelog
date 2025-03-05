import 'package:flutter/material.dart';
import 'dart:math';
import 'my_globals.dart'; // Import global variables and functions

class AddActionScreen extends StatefulWidget {
  final int? actionNum; // Action identifier for editing

  const AddActionScreen({super.key, this.actionNum});

  @override
  _AddActionScreenState createState() => _AddActionScreenState();
}

class _AddActionScreenState extends State<AddActionScreen> {
  // Data for the bike dropdown list
  List<Map<String, dynamic>> bikes = []; // List of bikes

  // Data for the event dropdown list
  List<Map<String, dynamic>> events = []; // List of events

  // Controllers for text fields
  final TextEditingController dateController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController commentController = TextEditingController();

  final double dropDownHeight = max(fsNormal * 1.8, kMinInteractiveDimension);
  final double textFieldHeight = fsNormal * 2.0;
  final double fieldPadding = fsNormal * 0.8;
  final double textFieldTextHeight = 1.0;

  // Focus nodes for fields
  final FocusNode priceFocusNode = FocusNode();
  final FocusNode bikeFocusNode = FocusNode();
  final FocusNode eventFocusNode = FocusNode();

  // Selected values for dropdowns
  String? selectedBike;
  String? selectedEvent;

  // Checkbox state for currency
  bool isDollar = false;

  @override
  void initState() {
    super.initState();

    // Initialize selected values as '0' to display the placeholder
    selectedBike = '0';
    selectedEvent = '0';

    // Set the current date in the date field
    final currentDate = DateTime.now();
    final formattedDate = "${currentDate.toLocal()}".split(' ')[0];
    dateController.text = formattedDate;

    // Load data on initialization
    _loadDataSequentially();
  }

  Future<void> _loadDataSequentially() async {
    try {
      await _loadBikes(); // Wait for _loadBikes to complete
      await _loadEvents(); // Wait for _loadEvents to complete

      // If actionNum is provided, load data for editing
      if (widget.actionNum != null) {
        await _loadActionData(widget.actionNum!);
      }
    } catch (e) {
      String msg = lw('Failed to load data');
      okInfoBarRed('$msg: $e');
    }
  }

  @override
  void dispose() {
    // Clean up controllers and FocusNodes when the widget is disposed
    dateController.dispose();
    priceController.dispose();
    commentController.dispose();
    priceFocusNode.dispose();
    bikeFocusNode.dispose();
    eventFocusNode.dispose();
    super.dispose();
  }

  // Load bikes from the database
  Future<void> _loadBikes() async {
    final sql = '''
      select bikes.num as num, owners.name as owner, 
      bikes.brand as brand, bikes.model as model
      from bikes
      inner join owners on bikes.owner = owners.num
      order by owners.name, bikes.brand, bikes.model;
    ''';
    // Execute the database query
    waitForMainDb();
    final bikesFromDb = await getDbData(sql);
    setState(() {
      // Save data to the bikes list
      bikes =
          bikesFromDb.map((bike) {
            return {
              'num':
                  bike['num']?.toString() ?? '0', // Use 'Num' from the query
              'owner':
                  bike['owner'] ?? lw('Unknown'), // Use 'Owner' from the query
              'brand':
                  bike['brand'] ?? lw('Unknown'), // Use 'Brand' from the query
              'model':
                  bike['model'] ?? lw('Unknown'), // Use 'Model' from the query
            };
          }).toList();
    });
  }

  // Load events from the database
  Future<void> _loadEvents() async {
    final sql = "select num as num, name as name from events order by num;";
    // Execute the database query
    waitForMainDb();
    final eventsFromDb = await getDbData(sql);
    setState(() {
      // Save data to the events list
      events =
          eventsFromDb.map((event) {
            return {
              'num':
                  event['num']?.toString() ?? '0', // Use 'Num' from the query
              'name':
                  event['name'] ?? lw('Unknown'), // Use 'Name' from the query
            };
          }).toList();
    });
  }

  Future<void> _loadActionData(int actionNum) async {
    final sql = '''
    select bike as bike, date as date, event as event, price as price, comment as comment
    from actions where num = $actionNum;
  ''';
    try {
      waitForMainDb();
      final actionData = await getDbData(sql);
      if (actionData.isNotEmpty) {
        final action = actionData.first;
        setState(() {
          // Convert bike to string and check for null
          selectedBike = action['bike']?.toString() ?? '0';
          dateController.text = action['date'] ?? '';
          selectedEvent = action['event']?.toString() ?? '0';
          priceController.text = action['price'].toString();
          commentController.text = action['comment'] ?? '';
          // Ensure the selected bike exists in the bikes list
          if (!bikes.any((bike) => bike['num'] == selectedBike)) {
            selectedBike = '0'; // Set default value
          }
        });
        // Debug logging
      }
    } catch (e) {
      String msg = lw('Failed to load action data');
      okInfoBarRed('$msg: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: clFon, // Screen background color
      appBar: AppBar(
        backgroundColor: clUpBar, // AppBar background color
        title: GestureDetector(
          onLongPress: () => okHelp(2), // help_id  for the title
          child: Text(
            widget.actionNum == null ? lw('Add Action') : lw('Edit Action'),
            style: TextStyle(
              color: clText, // Задаем цвет текста
              fontSize: fsLarge, // Задаем размер шрифта
              fontWeight: fwNormal, // Делаем текст жирным
            ),
          ),
        ),

        leading: GestureDetector(
          child: Icon(Icons.arrow_back, color: clText),
          onTap: () {
            Navigator.of(context).pop();
          },
          onLongPress: () {
            okHelp(9);
          },
        ),

        actions: [
          GestureDetector(
            onLongPress: () => okHelp(58), // help_id = 58 for the save button
            child: IconButton(
              icon: Icon(Icons.save, color: clText), // Save icon color
              onPressed: () async {
                // Проверка, что поле Bike заполнено
                if (selectedBike == null || selectedBike == '0') {
                  okInfoBarYellow(lw('Please select a bike'));
                  bikeFocusNode.requestFocus(); // Установить фокус на поле Bike
                  return;
                }

                // Проверка, что поле Event заполнено
                if (selectedEvent == null || selectedEvent == '0') {
                  okInfoBarYellow(lw('Please select an event'));
                  eventFocusNode
                      .requestFocus(); // Установить фокус на поле Event
                  return;
                }

                // Проверка даты
                if (!validateDateInput(dateController.text)) {
                  String msg = lw('Invalid date');
                  msg += lw('Please enter a valid date in the format YYYY-MM-DD ',);
                  msg += lw('and ensure it is not in the future');
                  okInfoBarYellow(msg);
                  return;
                }

                // Проверка цены
                if (!validatePriceInput(priceController.text)) {
                  okInfoBarYellow(
                    lw(
                      'Invalid price. Please enter a valid number (with optional decimal point)',
                    ),
                  );
                  priceFocusNode.requestFocus(); // фокус на поле Price
                  return;
                }

                // Обработка цены
                String priceText = priceController.text.trim();
                double price = 0.0;
                if (priceText.isNotEmpty) {
                  // Преобразовать в double
                  price = double.tryParse(priceText) ?? 0.0;
                  // Если флажок установлен, умножить на курс обмена
                  if (isDollar) {
                    final exchangeRate =
                        double.tryParse(xdef['Exchange rate']) ?? 1.0;
                    price *= exchangeRate;
                    commentController.text += ' (\$$priceText)';
                  }
                  // Округлить цену согласно настройке
                  if (xdef['Round to integer'] == 'true') {
                    price = price.round().toDouble(); // Округляем до целого
                  } else {
                    price = double.parse(
                      price.toStringAsFixed(2),
                    ); // Округляем до 2 знаков
                  }
                }

                String originalComment = strCleanAndEscape(
                  commentController.text,
                );

                try {
                  String sql;
                  if (widget.actionNum != null) { // Update existing record
                    sql = '''
                      UPDATE actions 
                      SET bike = $selectedBike,
                          date = '${dateController.text}',
                          event = $selectedEvent,
                          price = $price,
                          comment = '$originalComment'
                      WHERE num = ${widget.actionNum};
                    ''';
                  } else { // Insert new record
                      sql = '''
                      INSERT INTO actions 
                      (bike, date, event, price, comment)
                      VALUES 
                      ($selectedBike, '${dateController.text}', 
                      $selectedEvent, $price, '$originalComment');
                    ''';
                  }
                  await setDbData(sql);

                  if (widget.actionNum == null &&
                      xdef['Several actions'] == 'true') {
                    // Clear the form and stay on screen
                    setState(() {
                      selectedBike = '0';
                      selectedEvent = '0';
                      // Reset date to current
                      final currentDate = DateTime.now();
                      final formattedDate =
                          "${currentDate.toLocal()}".split(' ')[0];
                      dateController.text = formattedDate;
                      priceController.text = '';
                      commentController.text = '';
                      isDollar = false;
                    });
                    okInfoBarGreen(lw('Action saved successfully'));
                  } else {
                    if (mounted) {
                      Navigator.pop(context, true);
                    }
                  }
                } catch (e) {
                  String msg = lw('Failed to save action');
                  okInfoBarRed('$msg: $e');
                }
              },
            ),
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  flex: 35,
                  child: GestureDetector(
                    onLongPress: () => okHelp(40),
                    child: Text(
                      lw('Bike'),
                      style: TextStyle(
                        fontSize: fsNormal,
                        fontWeight: fwNormal,
                        color: clText,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 65,
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: clFill,
                    ),
                    dropdownColor: clMenu,
                    value: selectedBike,
                    items: [
                      DropdownMenuItem<String>(
                        value: '0',
                        child: Text(
                          xvSelect,
                          style: TextStyle(
                            fontSize: fsNormal,
                            fontWeight: fwNormal,
                            color: clText,
                          ),
                        ),
                      ),
                      if (bikes.isNotEmpty)
                        ...bikes.map((Map<String, dynamic> bike) {
                          final owner = bike['owner'] ?? lw('Unknown');
                          final brand = bike['brand'] ?? lw('Unknown');
                          final model = bike['model'] ?? lw('Unknown');
                          return DropdownMenuItem<String>(
                            value: bike['num'],
                            child: Text(
                              '$owner-$brand-$model',
                              style: TextStyle(
                                fontSize: fsNormal,
                                fontWeight: fwNormal,
                                color: clText,
                              ),
                            ),
                          );
                        }),
                    ],
                    onChanged: (String? value) {
                      setState(() {
                        selectedBike = value;
                      });
                    },
                    focusNode: bikeFocusNode,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Date input field with calendar button
            Row(
              children: [
                Expanded(
                  flex: 35,
                  child: GestureDetector(
                    onLongPress: () => okHelp(41),
                    child: Text(
                      lw('Date'),
                      style: TextStyle(
                        fontSize: fsNormal,
                        fontWeight: fwNormal,
                        color: clText,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 65,
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: dateController,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: lw('YYYY-MM-DD'),
                            filled: true,
                            fillColor: clFill,
                          ),
                          style: TextStyle(
                            fontSize: fsNormal,
                            fontWeight: fwNormal,
                            color: clText,
                          ),
                          keyboardType: TextInputType.datetime,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(Icons.calendar_today, color: clText),
                        onPressed: () async {
                          final DateTime? pickedDate = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime.now(),
                          );
                          if (pickedDate != null) {
                            final formattedDate =
                                "${pickedDate.toLocal()}".split(' ')[0];
                            setState(() {
                              dateController.text = formattedDate;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Dropdown for selecting an event
            Row(
              children: [
                Expanded(
                  flex: 35,
                  child: GestureDetector(
                    onLongPress: () => okHelp(42),
                    child: Text(
                      lw('Event'),
                      style: TextStyle(
                        fontSize: fsNormal,
                        fontWeight: fwNormal,
                        color: clText,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 65,
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: clFill,
                    ),
                    dropdownColor: clMenu,
                    value: selectedEvent,
                    items: [
                      DropdownMenuItem<String>(
                        value: '0',
                        child: Text(
                          xvSelect,
                          style: TextStyle(
                            fontSize: fsNormal,
                            fontWeight: fwNormal,
                            color: clText,
                          ),
                        ),
                      ),
                      if (events.isNotEmpty)
                        ...events.map((Map<String, dynamic> event) {
                          final name = event['name'] ?? lw('Unknown');
                          return DropdownMenuItem<String>(
                            value: event['num'],
                            child: Text(
                              name,
                              style: TextStyle(
                                fontSize: fsNormal,
                                fontWeight: fwNormal,
                                color: clText,
                              ),
                            ),
                          );
                        }),
                    ],
                    onChanged: (String? value) {
                      setState(() {
                        selectedEvent = value;
                      });
                    },
                    focusNode: eventFocusNode,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Price input field with currency checkbox
            Row(
              children: [
                Expanded(
                  flex: 35,
                  child: GestureDetector(
                    onLongPress: () => okHelp(43),
                    child: Text(
                      lw('Price'),
                      style: TextStyle(
                        fontSize: fsNormal,
                        fontWeight: fwNormal,
                        color: clText,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 65,
                  child: Row(
                    children: [
                      Checkbox(
                        value: isDollar,
                        onChanged: (bool? value) {
                          setState(() {
                            isDollar = value ?? false;
                          });
                        },
                      ),
                      Text(
                        '\$',
                        style: TextStyle(
                          fontSize: fsNormal,
                          fontWeight: fwNormal,
                          color: clText,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: priceController,
                          focusNode: priceFocusNode,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            filled: true,
                            fillColor: clFill,
                          ),
                          style: TextStyle(
                            fontSize: fsNormal,
                            fontWeight: fwNormal,
                            color: clText,
                          ),
                          keyboardType: TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Comment input field
            Row(
              children: [
                Expanded(
                  flex: 35,
                  child: GestureDetector(
                    onLongPress: () => okHelp(44),
                    child: Text(
                      lw('Comment'),
                      style: TextStyle(
                        fontSize: fsNormal,
                        fontWeight: fwNormal,
                        color: clText,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 65,
                  child: TextFormField(
                    controller: commentController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: clFill,
                    ),
                    style: TextStyle(
                      fontSize: fsNormal,
                      fontWeight: fwNormal,
                      color: clText,
                    ),
                    maxLines: 3,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
