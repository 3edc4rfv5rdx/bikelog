import 'package:flutter/material.dart';
import 'dart:math';
import 'package:file_picker/file_picker.dart';
import 'dart:io' show File;
import 'my_globals.dart';

class BikeSettingsScreen extends StatefulWidget {
  const BikeSettingsScreen({super.key});

  @override
  State<BikeSettingsScreen> createState() => _BikeSettingsScreenState();
}

class _BikeSettingsScreenState extends State<BikeSettingsScreen> {

  final double dropDownHeight = max(fsNormal * 2.0, kMinInteractiveDimension);  // Увеличен множитель
  final double textFieldHeight = fsNormal * 2.2;  // Увеличен множитель
  final double fieldPadding = fsNormal * 0.8;  // Увеличен множитель
  final double textFieldTextHeight = 1.0;  // Уменьшен межстрочный интервал

  bool _fieldsEnabled = false;
  int? selectedBikeIndex;

  List<Map<String, dynamic>> bikes = [];
  List<Map<String, dynamic>> owners = [];
  List<Map<String, dynamic>> types = [];

  // Controllers
  String? selectedOwner;
  String? selectedType;
  final TextEditingController brandController = TextEditingController();
  final TextEditingController modelController = TextEditingController();
  final TextEditingController serialNumController = TextEditingController();
  final TextEditingController buyDateController = TextEditingController();
  final TextEditingController photoController = TextEditingController();

  // Focus nodes
  final FocusNode brandFocusNode = FocusNode();
  final FocusNode modelFocusNode = FocusNode();
  final FocusNode serialNumFocusNode = FocusNode();
  final FocusNode buyDateFocusNode = FocusNode();
  final FocusNode photoFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    brandController.dispose();
    modelController.dispose();
    serialNumController.dispose();
    buyDateController.dispose();
    photoController.dispose();
    brandFocusNode.dispose();
    modelFocusNode.dispose();
    serialNumFocusNode.dispose();
    buyDateFocusNode.dispose();
    photoFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await _loadOwners();
    await _loadTypes();
    await _loadBikes();
  }

  Future<void> _loadOwners() async {
    final sql = 'SELECT num as num, name as name FROM owners ORDER BY name;';
    try {
      waitForMainDb();
      final ownersFromDb = await getDbData(sql);
      setState(() {
        owners = ownersFromDb;
      });
    } catch (e) {
      String msg = lw('Failed to load owners');
      okInfoBarRed('$msg: $e');
    }
  }

  Future<void> _loadTypes() async {
    final sql = 'SELECT num as num, name as name  FROM types ORDER BY name;';
    try {
      waitForMainDb();
      final typesFromDb = await getDbData(sql);
      setState(() {
        types = typesFromDb;
      });
    } catch (e) {
      String msg = lw('Failed to load types');
      okInfoBarRed('$msg: $e');
    }
  }

  // Загрузка велосипедов из базы данных
  Future<void> _loadBikes() async {
    final sql = '''
      SELECT bikes.num as num, owners.name as owner,
             bikes.brand as brand, bikes.model as model,
              COALESCE(types.name, '=') as type, bikes.serialnum as sernum, 
             bikes.buydate as buydate, photo as photo,
             owners.num as owners_num, types.num as types_num
      FROM bikes
      LEFT JOIN owners ON bikes.owner = owners.num
      LEFT JOIN types ON bikes.type = types.num
      ORDER BY owner, brand, model;
    ''';
    try {
      waitForMainDb();
      final bikesFromDb = await getDbData(sql);
      setState(() {
        bikes = bikesFromDb;
      });
    } catch (e) {
      String msg = lw('Failed to load bikes');
      okInfoBarRed('$msg: $e');
    }
  }


  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        dialogTitle: lw('Select bike image'),
        type: FileType.custom,
        allowMultiple: false,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'gif'], // добавляем фильтр расширений
      );

      if (result != null) {
        PlatformFile file = result.files.first;
        setState(() {
          photoController.text = file.path ?? '';
        });
      }
    } catch (e) {
      String msg = lw('Error picking file');
      okInfoBarRed('$msg: $e');
    }
  }


  void _showActionMenu(Map<String, dynamic> bike) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    showMenu(
      context: context,
      color: clMenu,
      useRootNavigator: false,
      position: RelativeRect.fromLTRB(
        screenWidth / 2 - 100, // левая граница (центр минус половина ширины меню)
        screenHeight * 0.6,   // верхняя граница (67% высоты экрана)
        screenWidth / 2,       // правая граница (центр)
        screenHeight * 0.6,   // нижняя граница (та же что и верхняя)
      ),
      items: [
        PopupMenuItem(
          value: 'EDIT',
          child: Text(lw('EDIT'), style: TextStyle(color: clText, fontSize: fsNormal)),
        ),
        PopupMenuItem(
          value: 'DELETE',
          child: Text(lw('DELETE'), style: TextStyle(color: clText, fontSize: fsNormal)),
        ),
        if (bike['photo']?.isNotEmpty ?? false)
          PopupMenuItem(
            value: 'VIEW',
            child: Text(lw('View Photo'), style: TextStyle(color: clText, fontSize: fsNormal)),
          ),
      ],
    ).then((value) {
      if (value == 'EDIT') {
        setState(() {
          _fieldsEnabled = true;
          _fillFormWithBikeData(bike);
        });
      } else if (value == 'DELETE') {
        _confirmAndDeleteBike(bike);
      } else if (value == 'VIEW') {
        _showPhoto(bike['photo']);
      }
    });
  }

  void _fillFormWithBikeData(Map<String, dynamic> bike) {
    selectedOwner = bike['owners_num'].toString();
    selectedType = (bike['types_num'] ?? 0).toString();
    brandController.text = bike['brand'] ?? '';
    modelController.text = bike['model'] ?? '';
    serialNumController.text = bike['sernum'] ?? '';
    buyDateController.text = bike['buydate'] ?? '';
    photoController.text = bike['photo'] ?? '';
  }

  void _clearForm() {
    selectedOwner = '0';
    selectedType = '0';
    brandController.clear();
    modelController.clear();
    serialNumController.clear();
    buyDateController.clear();
    photoController.clear();
  }


  Future<void> _confirmAndDeleteBike(Map<String, dynamic> bike) async {
    // First, get the count of related actions
    try {
      final countSql = 'SELECT COUNT(*) as count FROM actions WHERE bike = ${bike['num']}';
      final result = await getDbData(countSql);
      final actionsCount = result[0]['count'];

      // Prepare confirmation message based on whether there are related actions
      String message = lw('Delete this bike?');
      if (actionsCount > 0) {
        message += '\n${lw('Also will be deleted related actions: ')} $actionsCount';
      }

      final confirm = await okConfirm(
          title: lw('Confirm Delete'),
          message: message
      );

      if (confirm) {
        // First delete related actions
        if (actionsCount > 0) {
          final deleteActionsSql = 'DELETE FROM actions WHERE bike = ${bike['num']}';
          await setDbData(deleteActionsSql);
        }

        // Then delete the bike
        final deleteBikeSql = 'DELETE FROM bikes WHERE num = ${bike['num']}';
        await setDbData(deleteBikeSql);

        await _loadBikes();
        _clearForm();
        setState(() {
          selectedBikeIndex = null;
          _fieldsEnabled = false;
        });
        okInfoBarGreen(lw('Bike deleted successfully'));
      }
    } catch (e) {
      String msg = lw('Failed to delete bike');
      okInfoBarRed('$msg: $e');
    }
  }


  void _showPhoto(String photoPath) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => Scaffold(
        backgroundColor: clFon,
        appBar: AppBar(
          backgroundColor: clUpBar,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: clText),
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
        ),
        body: Center(
          child: Image.file(File(photoPath)),
        ),
      ),
    );
  }

  Future<void> _saveBike() async {
    if (selectedOwner == '0' || selectedOwner == null) {  // Проверяем только owner
      okInfoBarOrange(lw('Please select an owner'));  // Уточняем сообщение об ошибке
      return;
    }

    // Проверяем корректность даты
    if (buyDateController.text.isNotEmpty && !validateDateInput(buyDateController.text)) {
      okInfoBarRed(lw('Invalid date format or value. Use YYYY-MM-DD and date not in future'));
      return;
    }

    try {
      String normBrand = strCleanAndEscape(brandController.text);
      String normModel = strCleanAndEscape(modelController.text);
      String normSerNum = strCleanAndEscape(serialNumController.text);

      final sql = '''INSERT OR REPLACE INTO bikes (num, owner, type, 
                    brand, model, serialnum, buydate, photo)
         VALUES (${selectedBikeIndex != null ? bikes[selectedBikeIndex!]['num'] : null}, 
                $selectedOwner, $selectedType, '$normBrand', '$normModel', '$normSerNum',
                '${buyDateController.text}', '${photoController.text}')''';

      await setDbData(sql);
      await _loadBikes();
      setState(() {
        _fieldsEnabled = false;
        selectedBikeIndex = null;
      });
      _clearForm();

    } catch (e) {
      String msg = lw('Failed to save bike');
      okInfoBarRed('$msg: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: clFon,
      floatingActionButton: GestureDetector(
        onLongPress: () => okHelp(59),
        child: FloatingActionButton(
          backgroundColor: clUpBar,
          child: Icon(Icons.add, color: clText),
          onPressed: () async {  // добавляем async
            // Проверяем лимит велосипедов если включен business режим
            if (xvBusiness == true) {
              int currentBikesCount = await getTableRowCount('bikes');
              if (currentBikesCount >= progBikes) {
                String msg = lw('Maximum number of bikes reached');
                okInfoBarRed('$msg: $progBikes');
                return;
              }
            }
            setState(() {
              _fieldsEnabled = true;
              selectedBikeIndex = null;
              _clearForm();
            });
          },
        ),
      ),
      appBar: AppBar(
      backgroundColor: clUpBar,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: clText),
        onPressed: () {
          Navigator.pop(context);
        },
      ),
      title: GestureDetector(
        onLongPress: () => okHelp(6),
        child: Text(
          lw('Bikes Management'),
          style: TextStyle(
            color: clText,
            fontSize: fsLarge,
            fontWeight: fwNormal,
          ),
        ),
      ),
        actions: [
          GestureDetector(
            onLongPress: () => okHelp(58),
            child: IconButton(
              icon: Icon(Icons.save, color: clText),
              onPressed: _fieldsEnabled ? _saveBike : null,
            ),
          ),
        ],
    ),
    body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [

                // Owner dropdown
                Row(
                  children: [
                    Expanded(
                      flex: 35,
                      child: GestureDetector(
                        onLongPress: () => okHelp(50),
                        child: Text(
                          lw('Owner'),
                          style: TextStyle(
                            fontSize: fsNormal,
                            color: clText,
                            fontWeight: fwNormal,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 65,
                      child: Container(
                        height: textFieldHeight, // Явно заданная высота
                      child: DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          border: OutlineInputBorder(
                            borderSide: BorderSide(color: clFrame),
                          ),
                          filled: true,
                          fillColor: clFill,
                        ),
                        isExpanded: true,
                        dropdownColor: clMenu,
                        itemHeight: dropDownHeight,
                        style: TextStyle(fontSize: fsNormal, color: clText),
                        value: selectedOwner,
                        hint: Text(xvSelect),
                        items: [
                          DropdownMenuItem<String>(
                            value: '0',
                            child: Text(xvSelect),
                          ),
                          ...owners.map((owner) => DropdownMenuItem<String>(
                            value: owner['num'].toString(),
                            child: Text(owner['name']),
                          )),
                        ],
                        onChanged: _fieldsEnabled ? (value) => setState(() => selectedOwner = value) : null,
                      ),
                      )
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                // Brand
                Row(
                  children: [
                    Expanded(
                      flex: 35,
                      child: GestureDetector(
                        onLongPress: () => okHelp(51),
                        child: Text(
                          lw('Brand'),
                          style: TextStyle(
                            fontSize: fsNormal,
                            color: clText,
                            fontWeight: fwNormal,
                          ),
                        ),
                      ),
                    ),
                    // Brand input field
                    Expanded(
                      flex: 65,
                      child: Container(
                        height: textFieldHeight,
                        child: TextField(
                          enabled: _fieldsEnabled,
                          controller: brandController,
                          focusNode: brandFocusNode,
                          decoration: InputDecoration(
                            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: fieldPadding),
                            border: OutlineInputBorder(
                              borderSide: BorderSide(color: clFrame),
                            ),
                            filled: true,
                            fillColor: clFill,
                          ),
                          style: TextStyle(
                            fontSize: fsNormal,
                            color: clText,
                            height: textFieldTextHeight,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Model
                Row(
                  children: [
                    Expanded(
                      flex: 35,
                      child: GestureDetector(
                        onLongPress: () => okHelp(52),
                        child: Text(
                          lw('Model'),
                          style: TextStyle(
                            fontSize: fsNormal,
                            color: clText,
                            fontWeight: fwNormal,
                          ),
                        ),
                      ),
                    ),
                    // Model input field
                    Expanded(
                      flex: 65,
                      child: Container(
                        height: textFieldHeight,
                        child: TextField(
                          enabled: _fieldsEnabled,
                          controller: modelController,
                          focusNode: modelFocusNode,
                          decoration: InputDecoration(
                            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: fieldPadding),
                            border: OutlineInputBorder(
                              borderSide: BorderSide(color: clFrame),
                            ),
                            filled: true,
                            fillColor: clFill,
                          ),
                          style: TextStyle(
                            fontSize: fsNormal,
                            color: clText,
                            height: textFieldTextHeight,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Type dropdown
                Row(
                  children: [
                    Expanded(
                      flex: 35,
                      child: GestureDetector(
                        onLongPress: () => okHelp(53),
                        child: Text(
                          lw('Type'),
                          style: TextStyle(
                            fontSize: fsNormal,
                            color: clText,
                            fontWeight: fwNormal,
                          ),
                        ),
                      ),
                    ),
                    // Type dropdown field
                    Expanded(
                      flex: 65,
                      child: Container(
                      height: textFieldHeight,
                      child: DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          border: OutlineInputBorder(
                            borderSide: BorderSide(color: clFrame),
                          ),
                          filled: true,
                          fillColor: clFill,
                        ),
                        dropdownColor: clMenu,
                        isExpanded: true,
                        itemHeight: dropDownHeight,
                        style: TextStyle(fontSize: fsNormal, color: clText),
                        value: selectedType,
                        hint: Text(xvSelect),
                        items: [
                          DropdownMenuItem<String>(
                            value: '0',
                            child: Text(xvSelect),
                          ),
                          ...types.map((type) => DropdownMenuItem<String>(
                            value: type['num'].toString(),
                            child: Text(type['name']),
                          )),
                        ],
                        onChanged: _fieldsEnabled ? (value) => setState(() => selectedType = value) : null,
                      ),
                      )
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Serial Number
                Row(
                  children: [
                    Expanded(
                      flex: 35,
                      child: GestureDetector(
                        onLongPress: () => okHelp(54),
                        child: Text(
                          lw('SerialNum'),
                          style: TextStyle(
                            fontSize: fsNormal,
                            color: clText,
                            fontWeight: fwNormal,
                          ),
                        ),
                      ),
                    ),
                    // Serial Number input field
                    Expanded(
                      flex: 65,
                      child: Container(
                        height: textFieldHeight,
                        child: TextField(
                          enabled: _fieldsEnabled,
                          controller: serialNumController,
                          focusNode: serialNumFocusNode,
                          decoration: InputDecoration(
                            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: fieldPadding),
                            border: OutlineInputBorder(
                              borderSide: BorderSide(color: clFrame),
                            ),
                            filled: true,
                            fillColor: clFill,
                          ),
                          style: TextStyle(
                            fontSize: fsNormal,
                            color: clText,
                            height: textFieldTextHeight,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Buy Date
                Row(
                  children: [
                    Expanded(
                      flex: 35,
                      child: GestureDetector(
                        onLongPress: () => okHelp(55),
                        child: Text(
                          lw('BuyDate'),
                          style: TextStyle(
                            fontSize: fsNormal,
                            color: clText,
                            fontWeight: fwNormal,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 65,
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: textFieldHeight,
                              child: TextField(
                                enabled: _fieldsEnabled,
                                controller: buyDateController,
                                focusNode: buyDateFocusNode,
                                decoration: InputDecoration(
                                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: fieldPadding),
                                  border: OutlineInputBorder(
                                    borderSide: BorderSide(color: clFrame),
                                  ),
                                  filled: true,
                                  fillColor: clFill,
                                  hintText: lw('YYYY-MM-DD'),
                                ),
                                style: TextStyle(
                                  fontSize: fsNormal,
                                  color: clText,
                                  height: textFieldTextHeight,
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.calendar_today, color: clText),
                            onPressed: _fieldsEnabled ? () async {
                              final DateTime? picked = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime(2000),
                                lastDate: DateTime.now(),
                              );
                              if (picked != null) {
                                setState(() {
                                  buyDateController.text = "${picked.toLocal()}".split(' ')[0];
                                });
                              }
                            } : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Photo
                Row(
                  children: [
                    Expanded(
                      flex: 35,
                      child: GestureDetector(
                        onLongPress: () => okHelp(57),
                        child: Text(
                          lw('Photo'),
                          style: TextStyle(
                            fontSize: fsNormal,
                            color: clText,
                            fontWeight: fwNormal,
                          ),
                        ),
                      ),
                    ),
                    // Photo input field with file picker
                    Expanded(
                      flex: 65,
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: textFieldHeight,
                              child: TextField(
                                enabled: _fieldsEnabled,
                                controller: photoController,
                                focusNode: photoFocusNode,
                                decoration: InputDecoration(
                                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: fieldPadding),
                                  border: OutlineInputBorder(
                                    borderSide: BorderSide(color: clFrame),
                                  ),
                                  filled: true,
                                  fillColor: clFill,
                                ),
                                style: TextStyle(
                                  fontSize: fsNormal,
                                  color: clText,
                                  height: textFieldTextHeight,
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.camera_alt, color: clText),
                            onPressed: _fieldsEnabled ? _pickFile : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                Container(
                  height: 2,
                  color: clFrame,
                ),
              ],
            ),
          ),

          Expanded(
              child: ListView.builder(
                itemCount: bikes.length,
                itemBuilder: (context, index) {
                  final bike = bikes[index];
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedBikeIndex = index;
                        _fieldsEnabled = false;
                      });
                    },
                    onLongPress: () => _showActionMenu(bike),
                    child: Container(
                      color: selectedBikeIndex == index ? clSel : null,
                      child: ListTile(
                        title: Text(
                          '${bike['owner']} - ${bike['brand']} - ${bike['model']} - ${bike['type']} - ${bike['sernum']} - ${bike['buydate']} - ${(bike['photo']?.isNotEmpty ?? false) ? ' [o]' : ''}',
                          style: TextStyle(fontSize: fsNormal, color: clText),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  );
                },
              )
          ),
        ],
      ),
    );
  }
}
