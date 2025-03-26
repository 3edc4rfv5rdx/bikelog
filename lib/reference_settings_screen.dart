import 'package:flutter/material.dart';
import 'globals.dart';

class ReferenceSettingsScreen extends StatefulWidget {
  final int refMode;
  const ReferenceSettingsScreen({super.key, required this.refMode});

  @override
  _ReferenceSettingsScreenState createState() =>
      _ReferenceSettingsScreenState();
}

class _ReferenceSettingsScreenState extends State<ReferenceSettingsScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _commentController =
      TextEditingController(); // New controller for comment
  final FocusNode _nameFocusNode = FocusNode(); // Renamed for clarity
  final FocusNode _commentFocusNode =
      FocusNode(); // New focus node for comment field
  List<Map<String, dynamic>> _items = [];
  int? _selectedItemNum;
  int edMode = 0; // Режим: 0 - none, 1 - EDIT, 2 - DELETE, 3 - ADD
  bool _isEditing = false; // Флаг для управления состоянием редактирования

  String get _tableName {
    switch (widget.refMode) {
      case 1:
        return 'owners';
      case 2:
        return 'types';
      case 3:
        return 'events';
      default:
        return '';
    }
  }

  String get _title {
    switch (widget.refMode) {
      case 1:
        return lw('Owners Management');
      case 2:
        return lw('Types Management');
      case 3:
        return lw('Events Management');
      default:
        return lw('Settings');
    }
  }

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _commentController.dispose(); // Dispose the new controller
    _nameFocusNode.dispose(); // Updated variable name
    _commentFocusNode.dispose(); // Dispose the new focus node
    super.dispose();
  }

  Future<void> _loadItems() async {
    try {
      String orderBy = widget.refMode == 1 ? 'name' : 'num';
      // Updated query to include the comment field
      String sql =
          'SELECT num as num, name as name, comment as comment FROM $_tableName ORDER BY $orderBy';

      waitForMainDb();
      final items = await getDbData(sql);
      setState(() {
        _items = items;
      });
    } catch (e) {
      String msg = lw('Error loading data');
      okInfoBarRed('$msg: $e');
    }
  }

  Future<void> _deleteItem(int num) async {
    if ((widget.refMode == 1 || widget.refMode == 2) && num == 1) {
      // if owner mode
      okInfoBarOrange(lw('Cannot delete this record'));
      return;
    }

    setState(() {
      _selectedItemNum = num;
    });
    okInfoBarBlue(lw('Press SAVE to delete'));
  }

  Future<void> _saveItem() async {
    if (edMode == 0) {
      return;
    }

    String sql = '';
    String successMessage = '';
    String errorMessage = '';

    if (edMode == 1 || edMode == 3) {
      // Общая логика для режимов редактирования и добавления
      if (_nameController.text.isEmpty) {
        okInfoBarOrange(lw('Name cannot be empty'));
        return;
      }

      String normName = strCleanAndEscape(_nameController.text);
      String commentValue =
          _commentController.text.isEmpty
              ? "NULL"
              : // Use NULL for empty comments
              "'${strCleanAndEscape(_commentController.text)}'"; // Otherwise use the comment value in quotes

      // Для режима редактирования используем _selectedItemNum, для добавления - NULL
      final numValue = edMode == 1 ? _selectedItemNum : 'NULL';
      // Updated SQL to include the comment field, handling NULL properly
      sql =
          'INSERT OR REPLACE INTO $_tableName (num, name, comment) VALUES ($numValue, "$normName", $commentValue)';
      successMessage =
          edMode == 1 ? lw('Saved successfully') : lw('Added successfully');
      errorMessage =
          edMode == 1 ? lw('Error saving data') : lw('Error adding data');
    }

    if (edMode == 2) {
      if (_selectedItemNum == null) {
        okInfoBarOrange(lw('No item selected for deletion'));
        return;
      }

      if (widget.refMode == 1) {
        // Для владельцев
        if (_selectedItemNum == 1) {
          okInfoBarOrange(lw('Cannot delete this record'));
          return;
        }
        try {
          final deleted = await _deleteOwnerWithData(_selectedItemNum!);
          if (deleted) {
            successMessage = lw('Deleted successfully');
          } else {
            _selectedItemNum = null;
            edMode = 0;
            _isEditing = false;
            await _loadItems();
            return;
          }
        } catch (e) {
          String msg = lw('Error deleting data');
          okInfoBarRed('$msg: $e');
          return;
        }
      } else {
        // Для остальных типов записей - обычное удаление
        sql = 'DELETE FROM $_tableName WHERE num = $_selectedItemNum';
        successMessage = lw('Deleted successfully');
        errorMessage = lw('Error deleting data');
      }
    }

    try {
      await setDbData(sql);
      _nameController.clear();
      _commentController.clear(); // Clear the comment field
      _selectedItemNum = null;
      edMode = 0;
      _isEditing = false;
      await _loadItems();
      okInfoBarGreen(successMessage);
    } catch (e) {
      String msg = errorMessage;
      okInfoBarRed('$msg: $e');
    }
  }

  void _activateEditMode(String itemName, String? itemComment) {
    setState(() {
      edMode = 1;
      _isEditing = true;
      _nameController.text = itemName;
      _commentController.text =
          itemComment ??
          ''; // Set comment text, default to empty string if null
    });
    // Добавляем небольшую задержку
    Future.delayed(const Duration(milliseconds: 100), () {
      _nameFocusNode.requestFocus(); // Focus on the name field first
    });
  }

  void _activateAddMode() {
    setState(() {
      _selectedItemNum = null;
      _nameController.clear();
      _commentController.clear(); // Clear the comment field
      edMode = 3;
      _isEditing = true;
    });
    // Добавляем небольшую задержку
    Future.delayed(const Duration(milliseconds: 100), () {
      _nameFocusNode.requestFocus(); // Focus on the name field first
    });
  }

  Future<bool> _deleteOwnerWithData(int ownerNum) async {
    try {
      String sql = 'SELECT name as name FROM owners WHERE num = $ownerNum';
      final owner = await getDbData(sql);
      final ownerName = owner[0]['name'].toString();

      sql = 'SELECT COUNT(*) as cnt FROM bikes WHERE owner = $ownerNum';
      final bikes = await getDbData(sql);
      final bikesCount = int.parse(bikes[0]['cnt'].toString());

      sql =
          'SELECT COUNT(*) as cnt FROM actions '
          'WHERE bike IN (SELECT num FROM bikes WHERE owner = $ownerNum)';
      final actions = await getDbData(sql);
      final actionsCount = int.parse(actions[0]['cnt'].toString());

      final confirmed = await okConfirm(
        title: lw('Confirm Delete'),
        message:
            '${lw('This will also delete')}:\n'
            '${lw('Owner')}: $ownerName\n'
            '${lw('Bikes')}: $bikesCount\n'
            '${lw('Actions')}: $actionsCount',
      );

      if (!confirmed) {
        return false;
      }

      final statements = [
        'DELETE FROM actions WHERE bike IN (SELECT num FROM bikes WHERE owner = $ownerNum)',
        'DELETE FROM bikes WHERE owner = $ownerNum',
        'DELETE FROM owners WHERE num = $ownerNum',
      ];

      await executeDbTransaction(statements);
      return true;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onLongPress: () => okHelp(5),
          child: Text(
            _title,
            style: TextStyle(
              fontWeight: fwNormal,
              fontSize: fsLarge,
              color: clText,
            ),
          ),
        ),
        backgroundColor: clUpBar,
        leading: GestureDetector(
          onLongPress: () => okHelp(9),
          child: IconButton(
            icon: const Icon(Icons.arrow_back),
            color: clText,
            onPressed: () => Navigator.pop(context),
          ),
        ),
        actions: [
          GestureDetector(
            onLongPress: () => okHelp(58), // номер помощи для Save
            child: IconButton(
              icon: const Icon(Icons.save),
              color: clText,
              onPressed: _saveItem,
            ),
          ),
        ],
      ),
      backgroundColor: clFon,
      body: Column(
        children: [
          // Name field
          Padding(
            padding: const EdgeInsets.only(
              left: 8.0,
              right: 8.0,
              top: 8.0,
              bottom: 4.0,
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: GestureDetector(
                    onLongPress: () => okHelp(48),
                    child: Text(
                      lw('Name'),
                      style: TextStyle(
                        fontWeight: fwNormal,
                        fontSize: fsNormal,
                        color: clText,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.75,
                    child: TextField(
                      controller: _nameController,
                      focusNode: _nameFocusNode,
                      enabled: _isEditing,
                      style: TextStyle(
                        fontWeight: fwNormal,
                        fontSize: fsNormal,
                        color: clText,
                      ),
                      decoration: InputDecoration(
                        fillColor: clFill,
                        filled: true,
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: clText),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                      ),
                      onSubmitted: (_) {
                        _commentFocusNode
                            .requestFocus(); // Move to comment field when done
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Comment field - added below name
          Padding(
            padding: const EdgeInsets.only(
              left: 8.0,
              right: 8.0,
              top: 4.0,
              bottom: 8.0,
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: GestureDetector(
                    onLongPress:
                        () => okHelp(
                          48,
                        ), // You might want to add a specific help code for comment
                    child: Text(
                      lw('Comment'),
                      style: TextStyle(
                        fontWeight: fwNormal,
                        fontSize: fsNormal,
                        color: clText,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.75,
                    child: TextField(
                      controller: _commentController,
                      focusNode: _commentFocusNode,
                      enabled: _isEditing,
                      style: TextStyle(
                        fontWeight: fwNormal,
                        fontSize: fsNormal,
                        color: clText,
                      ),
                      decoration: InputDecoration(
                        fillColor: clFill,
                        filled: true,
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: clText),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Divider(
            height: 2, // общая высота элемента
            thickness: 2, // толщина линии
            color: clText, // цвет
            indent: 20, // отступ слева
            endIndent: 20, // отступ справа
          ),
          Expanded(
            child: Container(
              color: clFon,
              child: ListView.builder(
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  final item = _items[index];
                  final isSelected = item['num'] == _selectedItemNum;
                  final itemName = item['name']?.toString() ?? '';
                  final itemComment = item['comment']?.toString() ?? '';

                  // Create a display text that includes both name and comment if available
                  String displayText = itemName;
                  if (itemComment.isNotEmpty) {
                    displayText += ' - $itemComment';
                  }

                  return Container(
                    key: ValueKey(item['num']),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedItemNum = item['num'];
                        });
                      },
                      onLongPressStart: (LongPressStartDetails details) {
                        setState(() {
                          _selectedItemNum = item['num'];
                        });
                        showMenu(
                          context: context,
                          color: clMenu,
                          position: RelativeRect.fromLTRB(
                            details.globalPosition.dx - 100,
                            details.globalPosition.dy + 20,
                            details.globalPosition.dx + 1,
                            details.globalPosition.dy + 20,
                          ),
                          items: [
                            PopupMenuItem(
                              value: 'EDIT',
                              child: Text(
                                lw('EDIT'),
                                style: TextStyle(
                                  fontWeight: fwNormal,
                                  fontSize: fsNormal,
                                  color: clText,
                                ),
                              ),
                            ),
                            PopupMenuItem(
                              value: 'DELETE',
                              child: Text(
                                lw('DELETE'),
                                style: TextStyle(
                                  fontWeight: fwNormal,
                                  fontSize: fsNormal,
                                  color: clText,
                                ),
                              ),
                            ),
                          ],
                        ).then((value) {
                          if (value == 'EDIT') {
                            _activateEditMode(itemName, itemComment);
                          } else if (value == 'DELETE') {
                            edMode = 2;
                            _deleteItem(item['num']);
                          }
                        });
                      },
                      child: Container(
                        color: isSelected ? clSel : clFon,
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.0,
                          vertical: 12.0,
                        ),
                        alignment:
                            Alignment
                                .centerLeft, // Keep left alignment for readability
                        child: Text(
                          displayText,
                          style: TextStyle(
                            fontWeight: fwNormal,
                            fontSize: fsNormal,
                            color: clText,
                          ),
                          overflow:
                              TextOverflow
                                  .ellipsis, // Add this to handle long text
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: GestureDetector(
        onLongPress: () => okHelp(49),
        child: FloatingActionButton(
          backgroundColor: clUpBar,
          child: Icon(Icons.add, color: clText),
          onPressed: () async {
            // добавляем async
            // Проверяем лимит владельцев если включен business режим и это справочник owners
            if (xvBusiness == true && widget.refMode == 1) {
              int currentOwnersCount = await getTableRowCount('owners');
              if (currentOwnersCount >= progOwners) {
                String msg = lw('Maximum number of owners reached');
                okInfoBarRed('$msg: $progOwners');
                return;
              }
            }
            _activateAddMode();
          },
        ),
      ),
    );
  }
}
