import 'package:flutter/material.dart';
import 'globals.dart'; // Import global variables and functions

class OptionsSettingsScreen extends StatefulWidget {
  const OptionsSettingsScreen({super.key});

  @override
  _OptionsSettingsScreenState createState() => _OptionsSettingsScreenState();
}

class _OptionsSettingsScreenState extends State<OptionsSettingsScreen> {
  late Map<String, dynamic> _xdef;
  final List<String> _languages = appLANGUAGES;
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    // Filter out keys starting with dot and create new map
    _xdef = Map.fromEntries(
        xdef.entries.where((entry) => !entry.key.startsWith('.'))
    );
    // Initialize controllers for text fields
    _xdef.forEach((key, value) {
      if (value is String && value != 'true' && value != 'false') {
        _controllers[key] = TextEditingController(text: value);
      }
    });
    // Проверяем текущий язык
    if (!_languages.contains(_xdef['Program language'])) {
      setState(() {
        _xdef['Program language'] = _languages[0];
      });
    }
  }

  @override
  void dispose() {
    // Dispose of controllers
    _controllers.forEach((key, controller) {
      controller.dispose();
    });
    super.dispose();
  }

  // Function to save changes to the database
  Future<void> saveChanges() async {
    try {
      // Check Last actions
      final lastActions = _xdef['Last actions'];
      if (int.tryParse(lastActions) == null) {
        String msg = lw('Last actions must be an integer number');
        okInfoBarOrange(msg);
        return;
      }
      // Check Exchange rate
      final exchangeRate = _xdef['Exchange rate'];
      if (double.tryParse(exchangeRate) == null) {
        String msg = lw('Exchange rate must be a number');
        okInfoBarOrange(msg);
        return;
      }
      // Check if Program language has changed
      final oldLang = xdef['Program language'];
      final newLang = _xdef['Program language'];
      bool languageChanged = oldLang != newLang;

      // Check if Color theme has changed
      final oldTheme = xdef['Color theme'];
      final newTheme = _xdef['Color theme'];
      bool themeChanged = oldTheme != newTheme;

      // Save values
      for (var entry in _xdef.entries) {
        await setKey(entry.key, entry.value);
      }

      // Update the global variable xdef
      xdef = Map.from(_xdef);

      if (languageChanged) {
        await initTranslations();
        String msg = lw('Language changed. Reference tables will not change. Please restart');
        okInfoBarYellow(msg);
      } else if (themeChanged) {
        String msg = lw('Theme changed. Please restart the program');
        okInfoBarYellow(msg);
      } else {
        String msg = lw('Settings saved successfully');
        okInfoBarGreen(msg);
      }
    } catch (e) {
      String msg = lw('Failed to save action');
      okInfoBarRed('$msg: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onLongPress: () => okHelp(4),  // оставляем как было
          child: Text(
            lw('Options Settings'),
            style: TextStyle(
              color: clText,
              fontWeight: fwNormal,
              fontSize: fsLarge,
            ),
          ),
        ),
        backgroundColor: clUpBar,
        leading: GestureDetector(
          onLongPress: () => okHelp(9),
          child: IconButton(
            icon: const Icon(Icons.arrow_back),
            color: clText,
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        actions: [
          GestureDetector(
            onLongPress: () => okHelp(58),
            child: IconButton(
              icon: const Icon(Icons.save),
              color: clText,
              onPressed: saveChanges,
              tooltip: lw('Save'),
            ),
          ),
        ],
      ),

      backgroundColor: clFon,

        body: ListView(
          children: List.generate(_xdef.entries.length, (index) {
            var entry = _xdef.entries.elementAt(index);
            int helpId = 20 + index;
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: GestureDetector(
                      onLongPress: () => okHelp(helpId),
                      child: Text(
                        lw(entry.key),
                        style: TextStyle(fontWeight: fwNormal, fontSize: fsNormal, color: clText,),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 5,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: entry.value == 'true' || entry.value == 'false'
                              ? 24  // Width for checkbox
                              : MediaQuery.of(context).size.width * 0.45, // 45% of screen width
                          child: entry.key == 'Program language'
                              ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              border: Border.all(color: clFrame),
                            ),
                            child: DropdownButton<String>(
                              underline: Container(),
                              value: _languages.contains(_xdef['Program language'])
                                  ? _xdef['Program language']
                                  : _languages[0],
                              items: _languages.map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(
                                    value,
                                    style: TextStyle(fontWeight: fwNormal, fontSize: fsNormal, color: clText,),
                                  ),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                if (newValue != null) {
                                  setState(() {
                                    _xdef['Program language'] = newValue;
                                  });
                                }
                              },
                              dropdownColor: clMenu,
                              style: TextStyle(fontWeight: fwNormal, fontSize: fsNormal, color: clText,),
                              icon: Icon(
                                Icons.arrow_drop_down,
                                color: clText,
                              ),
                              isExpanded: true,
                            ),
                          )
                              : entry.key == 'Color theme'
                              ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              border: Border.all(color: clFrame),
                            ),
                            child: DropdownButton<String>(
                              underline: Container(),
                              value: _xdef['Color theme'],
                              items: appTHEMES.map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(
                                    lw(value),
                                    style: TextStyle(fontWeight: fwNormal, fontSize: fsNormal, color: clText,),
                                  ),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                setState(() {
                                  _xdef['Color theme'] = newValue!;
                                  currentThemeIndex = getThemeIndex(newValue);
                                });
                              },
                              dropdownColor: clMenu,
                              style: TextStyle(fontWeight: fwNormal, fontSize: fsNormal, color: clText,),
                              icon: Icon(
                                Icons.arrow_drop_down,
                                color: clText,
                              ),
                              isExpanded: true,
                            ),
                          )
                              : entry.key == 'Use PIN'
                              ? Align(
                            alignment: Alignment.centerLeft,
                            child: Checkbox(
                              value: entry.value == 'true',
                              onChanged: (bool? value) async {
                                if (value == true) {
                                  // Если включаем PIN, показываем диалог для установки
                                  final pin = await showPinDialog(mode: PinDialogMode.setup);

                                  if (pin != null) {
                                    setState(() {
                                      _xdef['Use PIN'] = 'true';
                                    });
                                    xdef['.PIN code'] = pin;  // Используем новый ключ
                                    await setKey('.PIN code', pin);  // Сохраняем в настройках
                                  } else {
                                    setState(() {
                                      _xdef['Use PIN'] = 'false';
                                    });
                                  }
                                } else {
                                  // Если отключаем PIN, сбрасываем значение
                                  setState(() {
                                    _xdef['Use PIN'] = 'false';
                                  });
                                  xdef['.PIN code'] = '';  // Сбрасываем PIN
                                  await setKey('.PIN code', '');  // Сохраняем в настройках
                                }
                              },
                              activeColor: clText,
                              checkColor: clFill,
                            ),
                          )
                              : entry.value == 'true' || entry.value == 'false'
                              ? Align(
                            alignment: Alignment.centerLeft,
                            child: Checkbox(
                              value: entry.value == 'true',
                              onChanged: (bool? value) {
                                setState(() {
                                  _xdef[entry.key] = value.toString();
                                });
                              },
                              activeColor: clText,
                              checkColor: clFill,
                            ),
                          )
                              : TextField(
                            controller: _controllers[entry.key],
                            style: TextStyle(fontWeight: fwNormal, fontSize: fsNormal, color: clText,),
                            cursorColor: clText,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            ),
                            onChanged: (value) {
                              _xdef[entry.key] = value;
                            },
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            );
          }).toList(),
        ),

    );
  }

}
