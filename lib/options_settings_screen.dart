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

  // Переменные для временного хранения настроек формата даты
  String _dateFormat = 'YYYY-MM-DD';
  String _dateSeparator = '-';

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

    // Инициализируем настройки формата даты
    _dateFormat = xdef['.Date format'] ?? 'YYYY-MM-DD';
    _dateSeparator = xdef['.Date separator'] ?? '-';
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

      // Save values from _xdef
      for (var entry in _xdef.entries) {
        await setKey(entry.key, entry.value);
      }

      // Сохраняем настройки формата даты
      await setKey('.Date format', _dateFormat);
      await setKey('.Date separator', _dateSeparator);

      // Update the global variable xdef
      xdef = Map.from(_xdef);
      // Обновляем скрытые настройки в глобальной переменной
      xdef['.Date format'] = _dateFormat;
      xdef['.Date separator'] = _dateSeparator;

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

  // Метод для получения текущего примера даты для кнопки
  String _getCurrentDateExample() {
    return _getDateFormatExample(_dateFormat, _dateSeparator);
  }

  @override
  Widget build(BuildContext context) {
    // Создаем список виджетов для ListView
    List<Widget> settingItems = List.generate(_xdef.entries.length, (index) {
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
    }).toList();

    // Добавляем кнопку "Date Format" после "Exchange rate"
    int exchangeRateIndex = _xdef.keys.toList().indexOf('Exchange rate');
    if (exchangeRateIndex >= 0) {
      int insertIndex = exchangeRateIndex + 1;
      settingItems.insert(
        insertIndex,
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                flex: 5,
                child: GestureDetector(
                  onLongPress: () => okHelp(29),
                  child: Text(
                    lw('Date Format'),
                    style: TextStyle(fontWeight: fwNormal, fontSize: fsNormal, color: clText),
                  ),
                ),
              ),
              Expanded(
                flex: 5,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.45,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: clUpBar,
                          foregroundColor: clText,
                          minimumSize: Size(24, 32),
                        ),
                        onPressed: () async {
                          final result = await _showDateFormatDialog(context);
                          if (result == true) {
                            setState(() {
                              // Обновится текст на кнопке
                            });
                          }
                        },
                        child: Text(
                          _getCurrentDateExample(), // Показываем пример даты вместо "Configure"
                          style: TextStyle(fontSize: fsNormal, fontWeight: fwNormal),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onLongPress: () => okHelp(4),
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
        children: settingItems,
      ),
    );
  }

  Future<bool?> _showDateFormatDialog(BuildContext context) {
    // Используем локальные переменные класса для временного хранения
    String selectedFormat = _dateFormat;
    String selectedSeparator = _dateSeparator;

    return showDialog<bool?>(
      context: context,
      builder: (BuildContext context) {
        // Получаем размеры экрана
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;

        // Центрируем диалог повыше на экране и делаем его уже
        return Dialog(
          insetPadding: EdgeInsets.symmetric(
            // Делаем диалог уже, увеличивая горизонтальные отступы
            horizontal: screenWidth * 0.2, // 20% ширины экрана с каждой стороны
            vertical: screenHeight * 0.15, // 15% высоты экрана с каждой стороны
          ),
          backgroundColor: clFon,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: StatefulBuilder(
            builder: (context, setState) {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Заголовок
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        lw('Settings'),
                        style: TextStyle(color: clText, fontSize: fsLarge, fontWeight: fwBold),
                      ),
                    ),

                    // Format section
                    Text(
                      lw('Format'),
                      style: TextStyle(color: clText, fontSize: fsNormal, fontWeight: fwBold),
                    ),
                    const SizedBox(height: 4),
                    // Форматы в виде радио-кнопок (вертикально)
                    ...DATE_FORMATS.map((String format) {
                      // Показываем формат с текущим разделителем
                      String displayFormat = format.replaceAll('-', selectedSeparator);
                      return Row(
                        children: [
                          Radio<String>(
                            value: format,
                            groupValue: selectedFormat,
                            activeColor: clUpBar,
                            onChanged: (String? value) {
                              if (value != null) {
                                setState(() {
                                  selectedFormat = value;
                                });
                              }
                            },
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            displayFormat,
                            style: TextStyle(color: clText, fontSize: fsNormal),
                          ),
                        ],
                      );
                    }).toList(),

                    const SizedBox(height: 4),

                    // Separator section
                    Text(
                      lw('Separator'),
                      style: TextStyle(color: clText, fontSize: fsNormal, fontWeight: fwBold),
                    ),
                    const SizedBox(height: 4),

                    // Разделители в виде радио-кнопок с крупными значками рядом
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: DATE_SEPARATORS.map((String separator) {
                        return Row(
                          children: [
                            Radio<String>(
                              value: separator,
                              groupValue: selectedSeparator,
                              activeColor: clUpBar,
                              onChanged: (String? value) {
                                if (value != null) {
                                  setState(() {
                                    selectedSeparator = value;
                                  });
                                }
                              },
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                            ),
                            Text(
                              separator,
                              style: TextStyle(
                                color: clText,
                                fontSize: fsLarge * 1.333,
                                fontWeight: fwBold,
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 4),

                    // Example section
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: clFill,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: clFrame),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lw('Example'),
                            style: TextStyle(color: clText, fontSize: fsNormal),
                          ),
                          Center(
                            child: Text(
                              _getDateFormatExample(selectedFormat, selectedSeparator),
                              style: TextStyle(
                                color: clText,
                                fontSize: fsLarge,
                                fontWeight: fwBold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Кнопки OK/Cancel в одной строке, обе справа
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end, // Выравниваем по правому краю
                      children: [
                        TextButton(
                          style: TextButton.styleFrom(
                            backgroundColor: clUpBar,
                            foregroundColor: clText,
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          ),
                          onPressed: () {
                            Navigator.of(context).pop(false);
                          },
                          child: Text(lw('Cancel')),
                        ),
                        const SizedBox(width: 8), // Добавляем отступ между кнопками
                        TextButton(
                          style: TextButton.styleFrom(
                            backgroundColor: clUpBar,
                            foregroundColor: clText,
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          ),
                          onPressed: () {
                            // Обновляем только локальные переменные класса
                            _dateFormat = selectedFormat;
                            _dateSeparator = selectedSeparator;

                            // Реальное сохранение будет происходить при нажатии Save в основном экране
                            Navigator.of(context).pop(true);
                          },
                          child: Text(lw('Ok')),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  // Вспомогательный метод для примера формата даты
  String _getDateFormatExample(String format, String separator) {
    final today = DateTime.now();
    final day = today.day.toString().padLeft(2, '0');
    final month = today.month.toString().padLeft(2, '0');
    final year = today.year.toString();

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
}
