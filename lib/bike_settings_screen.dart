import 'package:flutter/material.dart';
import 'dart:math';
import 'package:file_picker/file_picker.dart';
import 'dart:io' show File;
import 'globals.dart';

class BikeSettingsScreen extends StatefulWidget {
  const BikeSettingsScreen({super.key});

  @override
  State<BikeSettingsScreen> createState() => _BikeSettingsScreenState();
}

class _BikeSettingsScreenState extends State<BikeSettingsScreen> {
  List<Map<String, dynamic>> bikes = [];
  int? selectedBikeIndex;
  int? edBikeId; // Переменная для ID редактируемого велосипеда

  @override
  void initState() {
    super.initState();
    _loadBikes();
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

  void _showActionMenu(Map<String, dynamic> bike) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    showMenu(
      context: context,
      color: clMenu,
      useRootNavigator: false,
      position: RelativeRect.fromLTRB(
        screenWidth / 2 - 100, // левая граница (центр минус половина ширины меню)
        screenHeight * 0.3,   // верхняя граница (30% высоты экрана)
        screenWidth / 2,       // правая граница (центр)
        screenHeight * 0.3,   // нижняя граница (та же что и верхняя)
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
          edBikeId = bike['num'];
          _showEditPanel();
        });
      } else if (value == 'DELETE') {
        _confirmAndDeleteBike(bike);
      } else if (value == 'VIEW') {
        _showPhoto(bike['photo']);
      }
    });
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
        setState(() {
          selectedBikeIndex = null;
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

  void _showEditPanel() {
    // Получаем высоту статус-бара и AppBar
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final appBarHeight = AppBar().preferredSize.height;

    // Открываем панель редактирования сверху экрана, но под AppBar
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (BuildContext context, _, __) {
          return BikeEditPanel(
            bikeId: edBikeId,
            onSaved: () {
              _loadBikes();
            },
            topPadding: statusBarHeight + appBarHeight + 5, // Передаем отступ сверху
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, -1.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;

          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);

          return SlideTransition(
            position: offsetAnimation,
            child: child,
          );
        },
      ),
    );
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
          onPressed: () async {
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
              edBikeId = null; // null значит новый велосипед
            });
            _showEditPanel();
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
      ),
      body: ListView.builder(
        itemCount: bikes.length,
        itemBuilder: (context, index) {
          final bike = bikes[index];
          return GestureDetector(
            onTap: () {
              setState(() {
                selectedBikeIndex = index;
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
      ),
    );
  }
}

class BikeEditPanel extends StatefulWidget {
  final int? bikeId; // null для нового велосипеда
  final Function onSaved;
  final double topPadding; // Отступ сверху для позиционирования под AppBar

  const BikeEditPanel({
    Key? key,
    this.bikeId,
    required this.onSaved,
    this.topPadding = 0,
  }) : super(key: key);

  @override
  State<BikeEditPanel> createState() => _BikeEditPanelState();
}

class _BikeEditPanelState extends State<BikeEditPanel> {
  final double dropDownHeight = max(fsNormal * 2.0, kMinInteractiveDimension);
  final double textFieldHeight = fsNormal * 2.2;
  final double fieldPadding = fsNormal * 0.8;
  final double textFieldTextHeight = 1.0;

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

    if (widget.bikeId != null) {
      await _loadBikeData();
    } else {
      _clearForm();
    }
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
    final sql = 'SELECT num as num, name as name FROM types ORDER BY name;';
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

  Future<void> _loadBikeData() async {
    final sql = '''
      SELECT bikes.owner, bikes.type, bikes.brand, bikes.model, 
             bikes.serialnum, bikes.buydate, bikes.photo
      FROM bikes
      WHERE bikes.num = ${widget.bikeId}
    ''';

    try {
      waitForMainDb();
      final bikeData = await getDbData(sql);
      if (bikeData.isNotEmpty) {
        final bike = bikeData[0];
        setState(() {
          selectedOwner = bike['owner'].toString();
          selectedType = bike['type'].toString();
          brandController.text = bike['brand'] ?? '';
          modelController.text = bike['model'] ?? '';
          serialNumController.text = bike['serialnum'] ?? '';
          buyDateController.text = bike['buydate'] ?? '';
          photoController.text = bike['photo'] ?? '';
        });
      }
    } catch (e) {
      String msg = lw('Failed to load data');
      okInfoBarRed('$msg: $e');
    }
  }

  void _clearForm() {
    setState(() {
      selectedOwner = '0';
      selectedType = '0';
      brandController.clear();
      modelController.clear();
      serialNumController.clear();
      buyDateController.clear();
      photoController.clear();
    });
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        dialogTitle: lw('Select bike image'),
        type: FileType.custom,
        allowMultiple: false,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'gif'],
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

  Future<void> _saveBike() async {
    if (selectedOwner == '0' || selectedOwner == null) {
      okInfoBarOrange(lw('Please select an owner'));
      return;
    }
    if (buyDateController.text.isNotEmpty && !validateDateInput(buyDateController.text)) {
      okInfoBarRed(lw('Invalid date format or value. Use YYYY-MM-DD and date not in future'));
      return;
    }
    try {
      String normBrand = strCleanAndEscape(brandController.text);
      String normModel = strCleanAndEscape(modelController.text);
      String normSerNum = strCleanAndEscape(serialNumController.text);

      // Create SQL statement based on whether we're updating or inserting
      String sql;
      if (widget.bikeId != null) {
        sql = '''
        UPDATE bikes
        SET owner = $selectedOwner, type = $selectedType,
            brand = '$normBrand', model = '$normModel',
            serialnum = '$normSerNum', buydate = '${buyDateController.text}',
            photo = '${photoController.text}'
        WHERE num = ${widget.bikeId}
        ''';
      } else {
        // Insert new bike
        sql = '''
        INSERT INTO bikes (owner, type, brand, model, serialnum, buydate, photo)
        VALUES ($selectedOwner, $selectedType, '$normBrand', '$normModel', 
                '$normSerNum', '${buyDateController.text}', '${photoController.text}')
        ''';
      }

      await setDbData(sql);
      widget.onSaved(); // Вызываем колбэк для обновления списка в основном экране
      Navigator.pop(context); // Закрываем панель редактирования

      String message = lw('Bike saved successfully');
      okInfoBarGreen(message);
    } catch (e) {
      String msg = lw('Failed to save bike');
      okInfoBarRed('$msg: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Получаем высоту экрана для определения размера панели
    final screenHeight = MediaQuery.of(context).size.height;
    final panelHeight = screenHeight * 0.7; // 70% от высоты экрана

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Полупрозрачный фон, который закрывает основной экран
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Navigator.pop(context), // Закрытие при нажатии на фон
              child: Container(
                color: Colors.black.withOpacity(0.5),
              ),
            ),
          ),
          // Выезжающая панель сверху, начиная под AppBar
          Positioned(
            top: widget.topPadding, // Используем переданный отступ сверху
            left: 0,
            right: 0,
            height: panelHeight,
            child: Container(
              decoration: BoxDecoration(
                color: clFon,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Панель с заголовком и кнопками
                  Container(
                    decoration: BoxDecoration(
                      color: clUpBar,
                      borderRadius: BorderRadius.vertical(bottom: Radius.circular(0)),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: Row(
                      children: [
                        // Используем Material для обертывания кнопки, чтобы обеспечить корректную обработку нажатий
                        Material(
                          color: Colors.transparent,
                          child: IconButton(
                            icon: Icon(Icons.close, color: clText),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            widget.bikeId == null ? lw('Add New Bike') : lw('Edit Bike'),
                            style: TextStyle(fontSize: fsLarge, color: clText, fontWeight: fwNormal),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        // Оборачиваем кнопку сохранения в Material
                        Material(
                          color: Colors.transparent,
                          child: IconButton(
                            icon: Icon(Icons.save, color: clText),
                            onPressed: _saveBike,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Контент панели
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.all(16),
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
                                  onChanged: (value) => setState(() => selectedOwner = value),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

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
                            Expanded(
                              flex: 65,
                              child: Container(
                                height: textFieldHeight,
                                child: TextField(
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
                        const SizedBox(height: 12),

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
                            Expanded(
                              flex: 65,
                              child: Container(
                                height: textFieldHeight,
                                child: TextField(
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
                        const SizedBox(height: 12),

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
                                  onChanged: (value) => setState(() => selectedType = value),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

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
                            Expanded(
                              flex: 65,
                              child: Container(
                                height: textFieldHeight,
                                child: TextField(
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
                        const SizedBox(height: 12),

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
                                  Material(
                                    color: Colors.transparent,
                                    child: IconButton(
                                      icon: Icon(Icons.calendar_today, color: clText),
                                      onPressed: () async {
                                        final DateTime? picked = await showDatePicker(
                                          context: context,
                                          initialDate: DateTime.now(),
                                          firstDate: DateTime(1950),
                                          lastDate: DateTime.now(),
                                        );
                                        if (picked != null) {
                                          setState(() {
                                            buyDateController.text = "${picked.toLocal()}".split(' ')[0];
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

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
                            Expanded(
                              flex: 65,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      height: textFieldHeight,
                                      child: TextField(
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
                                  Material(
                                    color: Colors.transparent,
                                    child: IconButton(
                                      icon: Icon(Icons.camera_alt, color: clText),
                                      onPressed: _pickFile,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Индикатор для перетаскивания (установлен внизу панели)
          Positioned(
            top: widget.topPadding + panelHeight - 20, // Размещаем внизу панели
            left: 0,
            right: 0,
            child: GestureDetector(
              onVerticalDragEnd: (details) {
                if (details.primaryVelocity != null && details.primaryVelocity! > 500) {
                  // Если скорость свайпа вниз достаточно большая, закрываем панель
                  Navigator.pop(context);
                }
              },
              child: Container(
                height: 20,
                decoration: BoxDecoration(
                  color: clUpBar,
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
                ),
                child: Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: clText.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
