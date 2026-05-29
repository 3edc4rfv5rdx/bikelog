import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'globals.dart';

Future<bool> okConfirm({
  required String title,
  required String message,
}) async {
  final result = await showDialog<bool>(
    context: navigatorKey.currentContext!,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(title, style: tsLarge),
        content: Text(message, style: tsNormal),
        backgroundColor: clFon,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: clUpBar, width: 3.0),
          borderRadius: BorderRadius.circular(8.0),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              backgroundColor: clUpBar, foregroundColor: clText,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 4, minimumSize: Size(60, 40),
            ),
            child: Text(lw('No')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              backgroundColor: clUpBar, foregroundColor: clText,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 4, minimumSize: Size(60, 40),
            ),
            child: Text(lw('Yes')),
          ),
        ],
      );
    },
  );
  return result ?? false;
}

void showCustomDialog({
  required String title,
  required String message,
  required Color color,
  required IconData icon,
}) {
  showDialog(
    context: navigatorKey.currentContext!,
    builder: (context) {
      return AlertDialog(
        backgroundColor: clFon,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: clUpBar, width: 3.0),
          borderRadius: BorderRadius.circular(8.0),
        ),
        title: Row(
          children: [
            Icon(icon, color: color),
            SizedBox(width: 8),
            Text(title, style: tsLarge),
          ],
        ),
        content: SingleChildScrollView(child: Text(message, style: tsNormal)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              backgroundColor: clUpBar, foregroundColor: clText,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 4, minimumSize: Size(60, 40),
            ),
            child: Text(lw('Ok')),
          ),
        ],
        elevation: 10.0,
      );
    },
  );
}

void okHelp(int helpId) async {
  if (helpId == 0) return;
  try {
    final jsonString = await rootBundle.loadString(helpFile);
    final Map<String, dynamic> helpTexts = json.decode(jsonString);
    final String helpIdStr = helpId.toString();
    String helpText = '';
    final columnName = xdef['Program language'].toLowerCase();
    if (helpTexts.containsKey(helpIdStr)) {
      final Map<String, dynamic> helpEntry = helpTexts[helpIdStr];
      if (helpEntry.containsKey(columnName)) {
        helpText = helpEntry[columnName];
      } else if (helpEntry.containsKey('en')) {
        helpText = helpEntry['en'];
      } else {
        throw Exception(lw('Help text not found'));
      }
    } else {
      throw Exception(lw('Help text not found'));
    }
    if (helpText.isNotEmpty) {
      showCustomDialog(
        title: lw('Help'), message: helpText,
        color: clUpBar, icon: Icons.info_outline,
      );
    }
    myPrint('Showing help for ID: $helpId');
  } on Exception catch (e) {
    final errorMsg = lw('An error occurred');
    okInfoBarPurple('$errorMsg: $e (helpId=$helpId)');
  } catch (e) {
    final errorMsg = lw('An error occurred');
    okInfoBarPurple('$errorMsg: $e (helpId=$helpId)');
  }
}

void okInfo(String message) => showCustomDialog(title: lw('Info'), message: message, color: Colors.blue, icon: Icons.info_outline);
void okErr(String message) => showCustomDialog(title: lw('Error'), message: message, color: Colors.red, icon: Icons.error_outline);
void okWarning(String message) => showCustomDialog(title: lw('Warning'), message: message, color: Colors.orange, icon: Icons.warning_amber_outlined);
void okSuccess(String message) => showCustomDialog(title: lw('Success'), message: message, color: Colors.green, icon: Icons.check_circle_outline);

// Core SnackBar function
void okInfoBar(String message, {
  Color bgColor = Colors.blue,
  Color? textColor,
  Duration? duration,
  DismissDirection dismissDirection = DismissDirection.down,
  SnackBarAction? action,
}) {
  scaffoldMessengerKey.currentState?.showSnackBar(
    SnackBar(
      content: Text(message, style: TextStyle(fontSize: fsSmall, color: textColor ?? clText)),
      behavior: SnackBarBehavior.floating,
      backgroundColor: bgColor,
      duration: duration ?? const Duration(seconds: 4),
      dismissDirection: dismissDirection,
      action: action,
    ),
  );
}

// Colored SnackBar shortcuts
void okInfoBarBlue(String message) => okInfoBar(message, bgColor: Colors.blue, textColor: Colors.white, duration: const Duration(seconds: 5));
void okInfoBarRed(String message, {Duration? duration}) => okInfoBar(message, bgColor: Colors.red, textColor: Colors.white, duration: duration ?? const Duration(seconds: 7), dismissDirection: DismissDirection.none);
void okInfoBarOrange(String message) => okInfoBar(message, bgColor: Colors.orange);
void okInfoBarYellow(String message) => okInfoBar(message, bgColor: Colors.yellow);
void okInfoBarGreen(String message, {Duration? duration}) => okInfoBar(message, bgColor: Colors.green, duration: duration ?? const Duration(seconds: 3));
void okInfoBarPurple(String message) => okInfoBar(message, bgColor: Colors.purple, textColor: clFill, duration: const Duration(days: 3), dismissDirection: DismissDirection.none, action: SnackBarAction(label: '[ OK ]', onPressed: () { scaffoldMessengerKey.currentState?.hideCurrentSnackBar(); }));

// Dialog type: setup or verify PIN
enum PinDialogMode { setup, verify }

Future<String?> showPinDialog({
  required PinDialogMode mode,
  int maxAttempts = 3,
}) async {
  final pinController = TextEditingController();
  int attempts = 0;

  String? result = await showDialog<String>(
    context: navigatorKey.currentContext!,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: clFon,
              shape: RoundedRectangleBorder(
                side: BorderSide(color: clUpBar, width: 3.0),
                borderRadius: BorderRadius.circular(8.0),
              ),
              title: Text(
                mode == PinDialogMode.setup ? lw('Set PIN code') : lw('Enter PIN'),
                style: tsLarge,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: pinController,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    obscureText: true,
                    obscuringCharacter: '*',
                    autofocus: true,
                    style: TextStyle(color: clText, fontSize: fsLarge),
                    decoration: InputDecoration(
                      labelText: lw('4-digit PIN'),
                      labelStyle: TextStyle(color: clText),
                      counterStyle: TextStyle(color: clText),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: clFrame)),
                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: clUpBar)),
                    ),
                  ),
                  if (mode == PinDialogMode.verify)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        "${lw('Attempts left')}: ${maxAttempts - attempts}",
                        style: TextStyle(
                            color: (maxAttempts - attempts) <= 1 ? Colors.red : clText,
                            fontSize: fsNormal
                        ),
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, null),
                  style: TextButton.styleFrom(
                    backgroundColor: clUpBar, foregroundColor: clText,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 4, minimumSize: Size(60, 40),
                  ),
                  child: Text(mode == PinDialogMode.setup ? lw('Cancel') : lw('Exit')),
                ),
                TextButton(
                  onPressed: () {
                    final pin = pinController.text;
                    bool isValid = pin.length == 4 && RegExp(r'^[0-9]+$').hasMatch(pin);
                    if (mode == PinDialogMode.setup) {
                      if (isValid) {
                        Navigator.pop(context, pin);
                      } else {
                        okInfoBarRed(lw('PIN must be exactly 4 digits'));
                        pinController.clear();
                      }
                    } else {
                      if (pin == xdef['.PIN code']) {
                        Navigator.pop(context, pin);
                      } else {
                        attempts++;
                        setState(() {});
                        if (attempts >= maxAttempts) {
                          Navigator.pop(context, null);
                        } else {
                          okInfoBarRed(lw('Incorrect PIN'));
                          pinController.clear();
                        }
                      }
                    }
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: clUpBar, foregroundColor: clText,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 4, minimumSize: Size(60, 40),
                  ),
                  child: Text(lw('Ok')),
                ),
              ],
            );
          }
      );
    },
  );
  pinController.dispose();
  return result;
}
