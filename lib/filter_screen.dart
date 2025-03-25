import 'package:flutter/material.dart';
import 'globals.dart';

enum FilterMode { byOwner, byBike }

class FilterScreen extends StatefulWidget {
  final Map<String, dynamic>? initialFilters;

  const FilterScreen({
    super.key,
    this.initialFilters
  });

  @override
  State<FilterScreen> createState() => _FilterScreenState();
}


class _FilterScreenState extends State<FilterScreen> {
  FilterMode _filterMode = FilterMode.byOwner;
  String? _selectedOwner = '0';  // инициализируем значением '0'
  String? _selectedBike = '0';   // инициализируем значением '0'
  String? _selectedEvent;
  DateTime? _dateFrom;
  DateTime? _dateTo;
  String? _priceFrom;
  String? _priceTo;
  String? _comment;
  bool _isPriceFromForeign = false;
  bool _isPriceToForeign = false;

  List<Map<String, dynamic>> owners = [];
  List<Map<String, dynamic>> bikes = [];
  List<Map<String, dynamic>> events = [];

  final TextEditingController _dateFromController = TextEditingController();
  final TextEditingController _dateToController = TextEditingController();
  final TextEditingController _priceFromController = TextEditingController();
  final TextEditingController _priceToController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _priceFromFocusNode = FocusNode();
  final FocusNode _priceToFocusNode = FocusNode();
  final FocusNode _dateFromFocusNode = FocusNode();
  final FocusNode _dateToFocusNode = FocusNode();


  void buildFilter({
    String? owner,
    String? bike,
    String? event,
    String? dateFrom,
    String? dateTo,
    String? priceFrom,
    String? priceTo,
    String? comment,
  }) {
    // First clear the global filter
    xvFilter = '';

    // Check if any field is filled
    if ((owner != null && owner != '0') ||
        (bike != null && bike != '0') ||
        (event != null && event != '0') ||
        (dateFrom != null) ||
        (dateTo != null) ||
        (priceFrom != null && priceFrom.isNotEmpty) ||
        (priceTo != null && priceTo.isNotEmpty) ||
        (comment != null && comment.isNotEmpty)) {

      List<String> s = [];
      if (_filterMode == FilterMode.byOwner && owner != null && owner != '0')
      {s.add('bikes.owner = $owner');}
      if (_filterMode == FilterMode.byBike && bike != null && bike != '0')
      {s.add('actions.bike = $bike');}

      if (event != null && event != '0') s.add('actions.event = $event');

      // Convert dates to integer format for the database query
      if (dateFrom != null) {
        int dateInt = dateToStorageInt(dateFrom);
        s.add('actions.date >= $dateInt');
      }

      if (dateTo != null) {
        int dateInt = dateToStorageInt(dateTo);
        s.add('actions.date <= $dateInt');
      }

      if (priceFrom != null && priceFrom.isNotEmpty) s.add('actions.price >= $priceFrom');
      if (priceTo != null && priceTo.isNotEmpty) s.add('actions.price <= $priceTo');
      if (comment != null && comment.isNotEmpty) s.add('actions.comment LIKE "%$comment%"');

      // Form the filter string
      if (s.isNotEmpty) {
        xvFilter = ' WHERE ' + s.join(' and ');
      }
    }
  }

  void _onDateFromChanged() {
    String text = _dateFromController.text;
    if (text.isEmpty) {
      setState(() => _dateFrom = null);
      return;
    }

    // Only validate if we have a complete date format
    if (text.length == getDateFormatHint().length) {
      if (validateDateInput(text)) {
        // Convert to DateTime for state storage
        int dateInt = dateToStorageInt(text);
        DateTime dateTime = intToDateTime(dateInt);
        setState(() => _dateFrom = dateTime);
      } else {
        // Revert to previous valid date if validation fails
        _dateFromController.text = _dateFrom != null ?
        dateFromStorageInt(dateTimeToInt(_dateFrom!)) : '';
      }
    }
    // Allow partial input without validation
  }

  void _onDateToChanged() {
    String text = _dateToController.text;
    if (text.isEmpty) {
      setState(() => _dateTo = null);
      return;
    }

    // Only validate if we have a complete date format
    if (text.length == getDateFormatHint().length) {
      if (validateDateInput(text)) {
        // Convert to DateTime for state storage
        int dateInt = dateToStorageInt(text);
        DateTime dateTime = intToDateTime(dateInt);
        setState(() => _dateTo = dateTime);
      } else {
        // Revert to previous valid date if validation fails
        _dateToController.text = _dateTo != null ?
        dateFromStorageInt(dateTimeToInt(_dateTo!)) : '';
      }
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialFilters != null) {
      if (widget.initialFilters!['bike'] != null && widget.initialFilters!['bike'] != '0') {
        _filterMode = FilterMode.byBike;
      } else {
        _filterMode = FilterMode.byOwner;
      }

      // Load bikes before checking existence
      _loadDataSequentially().then((_) {
        setState(() {
          String? ownerId = widget.initialFilters!['owner'];
          if (ownerId != null) {
            bool ownerExists = owners.any((owner) => owner['num'].toString() == ownerId);
            _selectedOwner = ownerExists ? ownerId : '0';
          }

          // Set values only if corresponding records exist
          String? bikeId = widget.initialFilters!['bike'];
          if (bikeId != null) {
            bool bikeExists = bikes.any((bike) => bike['num'].toString() == bikeId);
            _selectedBike = bikeExists ? bikeId : '0';
          }

          String? eventId = widget.initialFilters!['event'];
          if (eventId != null) {
            bool eventExists = events.any((event) => event['num'].toString() == eventId);
            _selectedEvent = eventExists ? eventId : '0';
          }

          _dateFrom = widget.initialFilters!['dateFrom'];
          _dateTo = widget.initialFilters!['dateTo'];

          var priceFrom = widget.initialFilters!['priceFrom'];
          var priceTo = widget.initialFilters!['priceTo'];

          _priceFromController.text = priceFrom?.toString() ?? '';
          _priceToController.text = priceTo?.toString() ?? '';
          _commentController.text = widget.initialFilters!['comment'] ?? '';
          _isPriceFromForeign = widget.initialFilters!['isPriceFromForeign'] ?? false;
          _isPriceToForeign = widget.initialFilters!['isPriceToForeign'] ?? false;

          _priceFrom = _priceFromController.text;
          _priceTo = _priceToController.text;
          _comment = _commentController.text;

          if (_dateFrom != null) {
            // Convert DateTime to integer, then to display format
            int dateInt = dateTimeToInt(_dateFrom!);
            _dateFromController.text = dateFromStorageInt(dateInt);
          }

          if (_dateTo != null) {
            // Convert DateTime to integer, then to display format
            int dateInt = dateTimeToInt(_dateTo!);
            _dateToController.text = dateFromStorageInt(dateInt);
          }
        });
      });
    } else {
      _loadDataSequentially();
    }

    _dateFromController.addListener(_onDateFromChanged);
    _dateToController.addListener(_onDateToChanged);
  }


  @override
  void dispose() {
    _dateFromController.removeListener(_onDateFromChanged);
    _dateToController.removeListener(_onDateToChanged);
    _dateFromController.dispose();
    _dateToController.dispose();
    _priceFromController.dispose();
    _priceToController.dispose();
    _commentController.dispose();
    _priceFromFocusNode.dispose();
    _priceToFocusNode.dispose();
    _dateFromFocusNode.dispose();
    _dateToFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadDataSequentially() async {
    try {
      await _loadOwners();
      await _loadBikes();
      await _loadEvents();
    } catch (e) {
      String msg = lw('Failed to load data');
      okInfoBarRed('$msg: $e');
    }
  }

  Future<void> _loadOwners() async {
    final sql = "select num as num, name as name from owners order by name;";
    waitForMainDb();
    final ownersFromDb = await getDbData(sql);
    setState(() {
      owners = ownersFromDb.map((owner) {
        return {
          'num': owner['num']?.toString() ?? '0',
          'name': owner['name'] ?? lw('Unknown'),
        };
      }).toList();
    });
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
      bikes = bikesFromDb.map((bike) {
        return {
          'num': bike['num']?.toString() ?? '0',  // Use 'Num' from the query
          'owner': bike['owner'] ?? lw('Unknown'),    // Use 'Owner' from the query
          'brand': bike['brand'] ?? lw('Unknown'),    // Use 'Brand' from the query
          'model': bike['model'] ?? lw('Unknown'),    // Use 'Model' from the query
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
      events = eventsFromDb.map((event) {
        return {
          'num': event['num']?.toString() ?? '0',  // Use 'Num' from the query
          'name': event['name'] ?? lw('Unknown'),      // Use 'Name' from the query
        };
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onLongPress: () => okHelp(3),
          child: Text(
            lw('Actions Filters'),
            style: TextStyle(
              fontSize: fsLarge,
              fontWeight: fwNormal,
              color: clText,
            ),
          ),
        ),
        backgroundColor: clUpBar,
        leading: GestureDetector(
          onLongPress: () => okHelp(9),
          child: IconButton(
            icon: Icon(Icons.arrow_back, color: clText),
            iconSize: fsLarge,
            color: clText,
            onPressed: () {
              Navigator.pop(context, {
                'owner': _selectedOwner,
                'bike': _selectedBike,
                'event': _selectedEvent,
                'dateFrom': _dateFrom,
                'dateTo': _dateTo,
                'priceFrom': _priceFrom != null ? double.tryParse(_priceFrom!) : null,
                'priceTo': _priceTo != null ? double.tryParse(_priceTo!) : null,
                'comment': _comment,
                'isPriceFromForeign': _isPriceFromForeign,
                'isPriceToForeign': _isPriceToForeign,
              });
            },
          ),
        ),
        actions: [
          // Clear button
          GestureDetector(
            onLongPress: () => okHelp(76),
            child: IconButton(
              icon: Icon(Icons.delete_sweep, color: clText),
              onPressed: () {
                setState(() {
                  _selectedOwner = '0';
                  _selectedBike = '0';
                  _selectedEvent = '0';
                  _dateFrom = null;
                  _dateTo = null;
                  _priceFrom = '';
                  _priceTo = '';
                  _comment = '';
                  _dateFromController.text = '';
                  _dateToController.text = '';
                  _priceFromController.text = '';
                  _priceToController.text = '';
                  _commentController.text = '';
                  _isPriceFromForeign = false;
                  _isPriceToForeign = false;
                });
                xvFilter = '';

                // Only navigate back if 'Back after clear' is true
                if (xdef['Back after clear'] == 'true') {
                  Navigator.pop(context, {
                    'owner': null,
                    'bike': null,
                    'event': null,
                    'dateFrom': null,
                    'dateTo': null,
                    'priceFrom': null,
                    'priceTo': null,
                    'comment': '',
                    'isPriceFromForeign': false,
                    'isPriceToForeign': false,
                  });
                }
              },
              tooltip: lw('Clear'),
            ),
          ),

          // Apply button
          GestureDetector(
            onLongPress: () => okHelp(77),
            child: IconButton(
              icon: Icon(Icons.check, color: clText),
              onPressed: () {
                // Validate dates
                if (_dateFromController.text.isNotEmpty && !validateDateInput(_dateFromController.text)) {
                  okInfoBarRed(lw('Invalid date FROM. Please enter a valid date not in the future'));
                  _dateFromFocusNode.requestFocus();
                  return;
                }

                if (_dateToController.text.isNotEmpty && !validateDateInput(_dateToController.text)) {
                  okInfoBarRed(lw('Invalid date TO. Please enter a valid date not in the future'));
                  _dateToFocusNode.requestFocus();
                  return;
                }

                if (_dateFromController.text.isNotEmpty && _dateToController.text.isNotEmpty) {
                  // Compare dates using integer format
                  int dateFromInt = dateToStorageInt(_dateFromController.text);
                  int dateToInt = dateToStorageInt(_dateToController.text);

                  if (dateFromInt > dateToInt) {
                    okInfoBarRed(lw('Date from must be before or equal to date to'));
                    _dateFromFocusNode.requestFocus();
                    return;
                  }
                }

                // Convert prices if they're in foreign currency
                double? priceFrom = double.tryParse(_priceFromController.text);
                double? priceTo = double.tryParse(_priceToController.text);

                if (_isPriceFromForeign && priceFrom != null) {
                  priceFrom = priceFrom * double.parse(xdef['Exchange rate']);
                  if (xdef['Round to integer'] == 'true') {
                    priceFrom = priceFrom.roundToDouble();
                  } else {
                    priceFrom = double.parse(priceFrom.toStringAsFixed(2));
                  }
                }

                if (_isPriceToForeign && priceTo != null) {
                  priceTo = priceTo * double.parse(xdef['Exchange rate']);
                  if (xdef['Round to integer'] == 'true') {
                    priceTo = priceTo.roundToDouble();
                  } else {
                    priceTo = double.parse(priceTo.toStringAsFixed(2));
                  }
                }

                // Check that price-from is less than or equal to price-to
                if (priceFrom != null && priceTo != null && priceFrom > priceTo) {
                  okInfoBarRed(lw('Price FROM must be less than or equal TO price to'));
                  _priceFromFocusNode.requestFocus();
                  return;
                }

                String? dateFromStr = _dateFromController.text.isNotEmpty ?
                _dateFromController.text : null;
                String? dateToStr = _dateToController.text.isNotEmpty ?
                _dateToController.text : null;

                String normComment = strCleanAndEscape(_commentController.text);

                buildFilter(
                  owner: _selectedOwner,
                  bike: _selectedBike,
                  event: _selectedEvent,
                  dateFrom: dateFromStr,
                  dateTo: dateToStr,
                  priceFrom: priceFrom?.toString(),
                  priceTo: priceTo?.toString(),
                  comment: normComment,
                );

                // Return data to the calling widget
                Navigator.pop(context, {
                  'owner': _selectedOwner,
                  'bike': _selectedBike,
                  'event': _selectedEvent,
                  'dateFrom': _dateFrom,
                  'dateTo': _dateTo,
                  'priceFrom': priceFrom,
                  'priceTo': priceTo,
                  'comment': normComment,
                  'isPriceFromForeign': false,
                  'isPriceToForeign': false,
                });
              },
              tooltip: lw('Apply'),
            ),
          ),
        ],
      ),

      backgroundColor: clFon,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Owners Dropdown with clear button
            Row(
              children: [
                Expanded(
                  flex: 32,
                  child: GestureDetector(
                    onLongPress: () => okHelp(40),
                    child: Text(lw('Owner'), style: TextStyle(fontSize: fsNormal, color: clText, fontWeight: fwNormal,)),
                  ),
                ),
                Radio<FilterMode>(
                  value: FilterMode.byOwner,
                  groupValue: _filterMode,
                  fillColor: WidgetStateColor.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return clUpBar;
                    }
                    return clText;
                  }),
                  onChanged: (FilterMode? value) {
                    setState(() {
                      _filterMode = value!;
                      _selectedBike = '0';
                    });
                  },
                ),
                Expanded(
                  flex: 58,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: clFrame),
                    ),
                    child: DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        hintText: xvSelect,
                        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                        filled: true,
                        fillColor: clFill,
                        border: InputBorder.none,
                      ),
                      dropdownColor: clMenu,
                      value: _selectedOwner,
                      items: [
                        DropdownMenuItem<String>(
                          value: '0',
                          child: Text(
                            xvSelect,
                            style: TextStyle(
                                color: _filterMode == FilterMode.byOwner ? clText : clFill,
                                fontSize: fsNormal
                            ),
                          ),
                        ),
                        if (owners.isNotEmpty)
                          ...owners.map((Map<String, dynamic> owner) {
                            final name = owner['name'] ?? lw('Unknown');
                            return DropdownMenuItem<String>(
                              value: owner['num'],
                              child: Text(
                                name,
                                style: TextStyle(
                                    color: _filterMode == FilterMode.byOwner ? clText : clFill,
                                    fontSize: fsNormal
                                ),
                              ),
                            );
                          }),
                      ],
                      onChanged: _filterMode == FilterMode.byOwner ?
                          (value) {
                        setState(() {
                          _selectedOwner = value;
                        });
                      } : null,
                    ),
                  ),
                ),
                Expanded(
                  flex: 10,
                  child: Center(
                    child: IconButton(
                      icon: Icon(Icons.clear, color: clText, size: 16),
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(minWidth: 24, minHeight: 24),
                      onPressed: _filterMode == FilterMode.byOwner ? () {
                        setState(() {
                          _selectedOwner = '0';
                        });
                      } : null,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Bike Dropdown with clear button
            Row(
              children: [
                Expanded(
                  flex: 32,
                  child: GestureDetector(
                    onLongPress: () => okHelp(40),
                    child: Text(lw('Bike'), style: TextStyle(fontSize: fsNormal, color: clText, fontWeight: fwNormal,)),
                  ),
                ),
                Radio<FilterMode>(
                  value: FilterMode.byBike,
                  groupValue: _filterMode,
                  fillColor: WidgetStateColor.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return clUpBar;
                    }
                    return clText;
                  }),
                  onChanged: (FilterMode? value) {
                    setState(() {
                      _filterMode = value!;
                      _selectedOwner = '0';
                    });
                  },
                ),
                Expanded(
                  flex: 58,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: clFrame),
                    ),
                    child: DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        hintText: xvSelect,
                        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                        filled: true,
                        fillColor: clFill,
                        border: InputBorder.none,
                      ),
                      dropdownColor: clMenu,
                      value: _selectedBike,
                      items: [
                        DropdownMenuItem<String>(
                          value: '0',
                          child: Text(
                            xvSelect,
                            style: TextStyle(
                                color: _filterMode == FilterMode.byBike ? clText : clFill,
                                fontSize: fsNormal),
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
                                style: TextStyle(color: clText, fontSize: fsNormal),
                              ),
                            );
                          }),
                      ],
                      onChanged: _filterMode == FilterMode.byBike ?
                          (value) {
                        setState(() {
                          _selectedBike = value;
                        });
                      } : null,
                    ),
                  ),
                ),
                Expanded(
                  flex: 10,
                  child: Center(
                    child: IconButton(
                      icon: Icon(Icons.clear, color: clText, size: 16),
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(minWidth: 24, minHeight: 24),
                      onPressed: _filterMode == FilterMode.byBike ? () {
                        setState(() {
                          _selectedBike = '0';
                        });
                      } : null,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Event Dropdown with clear button
        // Event Dropdown with clear button
        Row(
          children: [
            Expanded(
              flex: 32,
              child: GestureDetector(
                onLongPress: () => okHelp(42),
                child: Text(lw('Event'), style: TextStyle(fontSize: fsNormal, color: clText, fontWeight: fwNormal,)),
              ),
            ),
            SizedBox(width: 48), // Space for the radio button alignment
            Expanded(
              flex: 58, // Keep the same as the Bike field
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: clFrame),
                ),
                child: DropdownButtonFormField<String>(
                  isExpanded: true, // Add this to ensure the dropdown fits in its container
                  decoration: InputDecoration(
                    hintText: xvSelect,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4), // Match the Bike field padding
                    filled: true,
                    fillColor: clFill,
                    border: InputBorder.none,
                  ),
                  dropdownColor: clMenu,
                  value: _selectedEvent,
                  items: [
                    DropdownMenuItem<String>(
                      value: '0',
                      child: Text(
                        xvSelect,
                        style: TextStyle(fontSize: fsNormal, color: clText, fontWeight: fwNormal,),
                      ),
                    ),
                    if (events.isNotEmpty)
                      ...events.map((Map<String, dynamic> event) {
                        final name = event['name'] ?? 'Unknown';
                        return DropdownMenuItem<String>(
                          value: event['num'],
                          child: Text(
                            name,
                            style: TextStyle(fontSize: fsNormal, color: clText, fontWeight: fwNormal,),
                            overflow: TextOverflow.ellipsis, // Add this to handle long text
                          ),
                        );
                      }),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedEvent = value;
                    });
                  },
                ),
              ),
            ),
            Expanded(
              flex: 10, // Keep the same as the Bike field
              child: Center(
                child: IconButton(
                  icon: Icon(Icons.clear, color: clText, size: 16),
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(minWidth: 24, minHeight: 24),
                  onPressed: () {
                    setState(() {
                      _selectedEvent = '0';
                    });
                  },
                ),
              ),
            ),
          ],
        ),

            const SizedBox(height: 8),

            // Date From with clear button
            Row(
              children: [
                Expanded(
                  flex: 32,
                  child: GestureDetector(
                    onLongPress: () => okHelp(72),
                    child: Text(lw('Date from'),
                        style: TextStyle(
                          fontSize: fsNormal,
                          color: clText,
                          fontWeight: fwNormal,
                        )),
                  ),
                ),
                SizedBox(width: 48), // Space for alignment
                Expanded(
                  flex: 58,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: clFrame),
                      color: clFill,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _dateFromController,
                            focusNode: _dateFromFocusNode,
                            keyboardType: TextInputType.text,
                            style: TextStyle(
                              fontSize: fsNormal,
                              color: clText,
                            ),
                            decoration: InputDecoration(
                              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              border: InputBorder.none,
                              hintText: getDateFormatHint(),
                            ),
                          ),
                        ),
                        // Date picker button
                        IconButton(
                          icon: Icon(Icons.calendar_today, color: clText, size: 16),
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(minWidth: 24, minHeight: 24),
                          onPressed: () async {
                            final DateTime? picked = await showLocalizedDatePicker(
                              context: context,
                              initialDate: _dateFrom ?? DateTime.now(),
                              firstDate: DateTime(1950),
                              lastDate: DateTime(2099),
                            );
                            if (picked != null && picked != _dateFrom) {
                              setState(() {
                                _dateFrom = picked;
                                int dateInt = dateTimeToInt(picked);
                                _dateFromController.text = dateFromStorageInt(dateInt);
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 10,
                  child: Center(
                    child: IconButton(
                      icon: Icon(Icons.clear, color: clText, size: 16),
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(minWidth: 24, minHeight: 24),
                      onPressed: () {
                        setState(() {
                          _dateFromController.clear();
                          _dateFrom = null;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Date To with clear button
            Row(
              children: [
                Expanded(
                  flex: 32,
                  child: GestureDetector(
                    onLongPress: () => okHelp(73),
                    child: Text(lw('Date to'),
                        style: TextStyle(
                          fontSize: fsNormal,
                          color: clText,
                          fontWeight: fwNormal,
                        )),
                  ),
                ),
                SizedBox(width: 48), // Space for alignment
                Expanded(
                  flex: 58,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: clFrame),
                      color: clFill,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _dateToController,
                            focusNode: _dateToFocusNode,
                            keyboardType: TextInputType.text,
                            style: TextStyle(
                              fontSize: fsNormal,
                              color: clText,
                            ),
                            decoration: InputDecoration(
                              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              border: InputBorder.none,
                              hintText: getDateFormatHint(),
                            ),
                          ),
                        ),
                        // Date picker button
                        IconButton(
                          icon: Icon(Icons.calendar_today, color: clText, size: 16),
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(minWidth: 24, minHeight: 24),
                          onPressed: () async {
                            final DateTime? picked = await showLocalizedDatePicker(
                              context: context,
                              initialDate: _dateTo ?? DateTime.now(),
                              firstDate: DateTime(1950),
                              lastDate: DateTime(2099),
                            );
                            if (picked != null && picked != _dateTo) {
                              setState(() {
                                _dateTo = picked;
                                int dateInt = dateTimeToInt(picked);
                                _dateToController.text = dateFromStorageInt(dateInt);
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 10,
                  child: Center(
                    child: IconButton(
                      icon: Icon(Icons.clear, color: clText, size: 16),
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(minWidth: 24, minHeight: 24),
                      onPressed: () {
                        setState(() {
                          _dateToController.clear();
                          _dateTo = null;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Price From with clear button
            Row(
              children: [
                Expanded(
                  flex: 32,
                  child: GestureDetector(
                    onLongPress: () => okHelp(74),
                    child: Text(lw('Price from'), style: TextStyle(fontSize: fsNormal, color: clText, fontWeight: fwNormal,)),
                  ),
                ),
                Checkbox(
                  value: _isPriceFromForeign,
                  activeColor: clFill,
                  checkColor: clText,
                  side: BorderSide(
                    color: clFrame,
                    width: 2.0,
                  ),
                  onChanged: (bool? value) {
                    setState(() {
                      _isPriceFromForeign = value!;
                    });
                  },
                ),
                Text('\$', style: TextStyle(fontSize: fsNormal, color: clText)),
                Expanded(
                  flex: 58,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: clFrame),
                      color: clFill,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: TextField(
                      controller: _priceFromController,
                      focusNode: _priceFromFocusNode,
                      keyboardType: TextInputType.number,
                      style: TextStyle(fontSize: fsNormal, color: clText),
                      onChanged: (value) {
                        setState(() {
                          _priceFrom = value;
                        });
                      },
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 10,
                  child: Center(
                    child: IconButton(
                      icon: Icon(Icons.clear, color: clText, size: 16),
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(minWidth: 24, minHeight: 24),
                      onPressed: () {
                        setState(() {
                          _priceFromController.clear();
                          _priceFrom = '';
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Price To with clear button
            Row(
              children: [
                Expanded(
                  flex: 32,
                  child: GestureDetector(
                    onLongPress: () => okHelp(75),
                    child: Text(lw('Price to'), style: TextStyle(fontSize: fsNormal, color: clText, fontWeight: fwNormal,)),
                  ),
                ),
                Checkbox(
                  value: _isPriceToForeign,
                  activeColor: clFill,
                  checkColor: clText,
                  side: BorderSide(
                    color: clFrame,
                    width: 2.0,
                  ),
                  onChanged: (bool? value) {
                    setState(() {
                      _isPriceToForeign = value!;
                    });
                  },
                ),
                Text('\$', style: TextStyle(fontSize: fsNormal, color: clText)),
                Expanded(
                  flex: 58,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: clFrame),
                      color: clFill,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: TextField(
                      controller: _priceToController,
                      focusNode: _priceToFocusNode,
                      keyboardType: TextInputType.number,
                      style: TextStyle(fontSize: fsNormal, color: clText),
                      onChanged: (value) {
                        setState(() {
                          _priceTo = value;
                        });
                      },
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 10,
                  child: Center(
                    child: IconButton(
                      icon: Icon(Icons.clear, color: clText, size: 16),
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(minWidth: 24, minHeight: 24),
                      onPressed: () {
                        setState(() {
                          _priceToController.clear();
                          _priceTo = '';
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Comment with clear button
            Row(
              children: [
                Expanded(
                  flex: 32,
                  child: GestureDetector(
                    onLongPress: () => okHelp(44),
                    child: Text(lw('Comment'), style: TextStyle(fontSize: fsNormal, color: clText, fontWeight: fwNormal,)),
                  ),
                ),
                SizedBox(width: 48), // Space for alignment
                Expanded(
                  flex: 58,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: clFrame),
                      color: clFill,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: TextField(
                      controller: _commentController,
                      keyboardType: TextInputType.text,
                      style: TextStyle(fontSize: fsNormal, color: clText),
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                        border: InputBorder.none,
                      ),
                      onChanged: (value) {
                        setState(() {
                          _comment = value;
                        });
                      },
                    ),
                  ),
                ),
                Expanded(
                  flex: 10,
                  child: Center(
                    child: IconButton(
                      icon: Icon(Icons.clear, color: clText, size: 16),
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(minWidth: 24, minHeight: 24),
                      onPressed: () {
                        setState(() {
                          _commentController.clear();
                          _comment = '';
                        });
                      },
                    ),
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
