import 'dart:math';

import 'package:flutter/material.dart';

import 'globals.dart'; // Import global variables and functions

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

  // Functions for evaluating mathematical expressions
  double evaluateExpression(String expression) {
    try {
      // Remove all spaces
      expression = expression.replaceAll(' ', '');

      // Parse and evaluate the expression
      List<String> tokens = _tokenize(expression);
      return _evaluate(tokens);
    } catch (e) {
      // Return error value on any exception
      throw FormatException('Invalid expression: $expression');
    }
  }

  // Helper function to tokenize the expression
  List<String> _tokenize(String expression) {
    List<String> tokens = [];
    String currentNumber = '';

    for (int i = 0; i < expression.length; i++) {
      String char = expression[i];

      if (char == '+' || char == '-' || char == '*' || char == '/') {
        if (currentNumber.isNotEmpty) {
          tokens.add(currentNumber);
          currentNumber = '';
        }
        tokens.add(char);
      } else if (char.contains(RegExp(r'[0-9.]'))) {
        currentNumber += char;
      } else {
        throw FormatException('Invalid character: $char');
      }
    }

    if (currentNumber.isNotEmpty) {
      tokens.add(currentNumber);
    }

    return tokens;
  }

  // Helper function to evaluate tokenized expression
  double _evaluate(List<String> tokens) {
    // First pass: Handle multiplication and division
    List<String> secondPassTokens = [];

    int i = 0;
    while (i < tokens.length) {
      if (i + 2 < tokens.length &&
          (tokens[i + 1] == '*' || tokens[i + 1] == '/')) {
        double leftOperand = double.parse(tokens[i]);
        String operator = tokens[i + 1];
        double rightOperand = double.parse(tokens[i + 2]);

        double result;
        if (operator == '*') {
          result = leftOperand * rightOperand;
        } else {
          // operator == '/'
          if (rightOperand == 0) {
            throw FormatException('Division by zero');
          }
          result = leftOperand / rightOperand;
        }

        secondPassTokens.add(result.toString());
        i += 3;
      } else {
        secondPassTokens.add(tokens[i]);
        i++;
      }
    }

    // Second pass: Handle addition and subtraction
    double result = double.parse(secondPassTokens[0]);

    for (i = 1; i < secondPassTokens.length; i += 2) {
      String operator = secondPassTokens[i];
      double operand = double.parse(secondPassTokens[i + 1]);

      if (operator == '+') {
        result += operand;
      } else if (operator == '-') {
        result -= operand;
      }
    }

    return result;
  }

  // Price input validation function (including expressions)
  bool isValidCalculatorExpression(String input) {
    if (input.isEmpty) {
      return true; // Allow empty price
    }

    // Check if the input contains any mathematical operators
    bool hasOperators = input.contains(RegExp(r'[+\-*/]'));

    if (!hasOperators) {
      // If no operators, validate as regular numeric input
      return validatePriceInput(input);
    }

    try {
      // Try to evaluate the expression
      evaluateExpression(input);
      return true; // If no exception was thrown, the expression is valid
    } catch (e) {
      return false; // Invalid expression
    }
  }

  @override
  void initState() {
    super.initState();

    // Initialize selected values as '0' to display the placeholder
    selectedBike = '0';
    selectedEvent = '0';

    // Set the current date in the date field using integer format
    final currentDate = DateTime.now();
    final dateInt = currentDate.year * 10000 + currentDate.month * 100 + currentDate.day;
    final formattedDate = dateFromStorageInt(dateInt);
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
    final loaded = await loadBikesForSelect();
    setState(() {
      bikes = loaded;
    });
  }

  // Load events from the database
  Future<void> _loadEvents() async {
    final loaded = await loadEventsForSelect();
    setState(() {
      events = loaded;
    });
  }

  Future<void> _loadActionData(int actionNum) async {
    final sql = '''
    select bike as bike, date as date, event as event, price as price, comment as comment
    from actions where num = $actionNum;
  ''';
    try {
      final actionData = await getDbData(sql);
      if (actionData.isNotEmpty) {
        final action = actionData.first;
        setState(() {
          // Convert bike to string and check for null
          selectedBike = action['bike']?.toString() ?? '0';

          // Format the date from integer format to display format
          int dateInt = action['date'] ?? 0;
          dateController.text = dateFromStorageInt(dateInt);

          selectedEvent = action['event']?.toString() ?? '0';
          priceController.text = action['price'].toString();
          commentController.text = action['comment'] ?? '';
          // Ensure the selected bike exists in the bikes list
          if (!bikes.any((bike) => bike['num'] == selectedBike)) {
            selectedBike = '0'; // Set default value
          }
        });
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
            style: tsLarge,
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
                // Check that Bike field is filled
                if (selectedBike == null || selectedBike == '0') {
                  okInfoBarYellow(lw('Please select a bike'));
                  bikeFocusNode.requestFocus();
                  return;
                }

                // Check that Event field is filled
                if (selectedEvent == null || selectedEvent == '0') {
                  okInfoBarYellow(lw('Please select an event'));
                  eventFocusNode.requestFocus();
                  return;
                }

                // Date validation
                if (!validateDateInput(dateController.text)) {
                  String msg = lw('Invalid date');
                  msg += ' ' + lw('Please enter a valid date in the format') + ' ' + getDateFormatHint();
                  msg += ' ' + lw('and ensure it is not in the future');
                  okInfoBarYellow(msg);
                  return;
                }

                // Price validation
                if (!isValidCalculatorExpression(priceController.text)) {
                  okInfoBarYellow(
                    lw('Invalid price. Please enter a valid number (with optional decimal point)'),
                  );
                  priceFocusNode.requestFocus();
                  return;
                }

                // Process price
                String priceText = priceController.text.trim();
                double price = 0.0;
                if (priceText.isNotEmpty) {
                  // Check for mathematical operators
                  bool isExpression = priceText.contains(RegExp(r'[+\-*/]'));

                  if (isExpression) {
                    // Calculate the expression
                    price = evaluateExpression(priceText);

                    // A price is a cost: reject a negative computed result.
                    if (price < 0) {
                      okInfoBarYellow(lw('Price cannot be negative'));
                      priceFocusNode.requestFocus();
                      return;
                    }

                    // Add expression to comment
                    String expressionComment = ' (=' + priceText + ')';
                    if (!commentController.text.contains(expressionComment)) {
                      commentController.text += expressionComment;
                    }
                  } else {
                    // Regular price
                    price = double.tryParse(priceText) ?? 0.0;
                  }

                  // If dollar currency, multiply by exchange rate
                  if (isDollar) {
                    // For expressions, first add the dollar result
                    if (isExpression) {
                      String dollarValueComment = ' (\$' + price.toString() + ')';
                      if (!commentController.text.contains(dollarValueComment)) {
                        commentController.text += dollarValueComment;
                      }
                    } else {
                      // For regular price, add the original value
                      String dollarComment = ' (\$' + priceText + ')';
                      if (!commentController.text.contains(dollarComment)) {
                        commentController.text += dollarComment;
                      }
                    }

                    // Convert to local currency
                    final exchangeRate = double.tryParse(xdef['Exchange rate']) ?? 1.0;
                    price *= exchangeRate;
                  }

                  // Round price according to settings
                  if (xdef['Round to integer'] == 'true') {
                    price = price.round().toDouble(); // Round to integer
                  } else {
                    price = double.parse(price.toStringAsFixed(2)); // Round to 2 decimal places
                  }
                }

                String originalComment = commentController.text.trim();

                // Convert display date to integer format for storage
                int dbDateInt = dateToStorageInt(dateController.text);

                try {
                  String sql;
                  List<dynamic> args;
                  if (widget.actionNum != null) {
                    // Update existing record
                    sql = 'UPDATE actions SET bike = ?, date = ?, event = ?, price = ?, comment = ? WHERE num = ?';
                    args = [selectedBike, dbDateInt, selectedEvent, price, originalComment, widget.actionNum];
                  } else {
                    // Insert new record
                    sql = 'INSERT INTO actions (bike, date, event, price, comment) VALUES (?, ?, ?, ?, ?)';
                    args = [selectedBike, dbDateInt, selectedEvent, price, originalComment];
                  }
                  await setDbData(sql, args);

                  if (widget.actionNum == null && xdef['Several actions'] == 'true') {
                    // Clear the form and stay on screen
                    setState(() {
                      selectedBike = '0';
                      selectedEvent = '0';
                      // Reset date to current
                      final currentDate = DateTime.now();
                      final dateInt = currentDate.year * 10000 + currentDate.month * 100 + currentDate.day;
                      final formattedDate = dateFromStorageInt(dateInt);
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
                      style: tsNormal,
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
                          style: tsNormal,
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
                              style: tsNormal,
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
                      style: tsNormal,
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
                            hintText: getDateFormatHint(),
                            filled: true,
                            fillColor: clFill,
                          ),
                          style: tsNormal,
                          keyboardType: TextInputType.datetime,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(Icons.calendar_today, color: clText),
                        onPressed: () async {
                          DateTime initialDate;
                          try {
                            // Try to parse the current value in the field
                            int dateInt = dateToStorageInt(dateController.text);
                            int year = dateInt ~/ 10000;
                            int month = (dateInt % 10000) ~/ 100;
                            int day = dateInt % 100;
                            initialDate = DateTime(year, month, day);
                          } catch (e) {
                            // If parsing fails, use current date
                            initialDate = DateTime.now();
                          }

                          final DateTime? pickedDate = await showLocalizedDatePicker(
                            context: context,
                            initialDate: initialDate,
                            firstDate: datePickerFirstDate,
                            lastDate: datePickerLastDate,
                          );

                          if (pickedDate != null) {
                            // Convert directly to integer format
                            final dateInt = pickedDate.year * 10000 + pickedDate.month * 100 + pickedDate.day;
                            final displayFormat = dateFromStorageInt(dateInt);

                            setState(() {
                              dateController.text = displayFormat;
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
                      style: tsNormal,
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
                          style: tsNormal,
                        ),
                      ),
                      if (events.isNotEmpty)
                        ...events.map((Map<String, dynamic> event) {
                          final name = event['name'] ?? lw('Unknown');
                          return DropdownMenuItem<String>(
                            value: event['num'],
                            child: Text(
                              name,
                              style: tsNormal,
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
                      style: tsNormal,
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
                        style: tsNormal,
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
                          style: tsNormal,
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
                      style: tsNormal,
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
                    style: tsNormal,
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
