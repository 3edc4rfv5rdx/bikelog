import 'package:flutter/material.dart';
import 'globals.dart';

String dateToStorageFormat(String displayDate) {
  if (displayDate.isEmpty) return '';

  String format = xdef['.Date format'];
  String separator = xdef['.Date separator'];

  List<String> parts = displayDate.split(separator);
  if (parts.length != 3) return displayDate;

  String year, month, day;

  switch (format) {
    case 'DD-MM-YYYY':
      day = parts[0].padLeft(2, '0');
      month = parts[1].padLeft(2, '0');
      year = parts[2];
      break;

    case 'MM-DD-YYYY':
      month = parts[0].padLeft(2, '0');
      day = parts[1].padLeft(2, '0');
      year = parts[2];
      break;

    case 'YYYY-MM-DD':
    default:
      year = parts[0];
      month = parts[1].padLeft(2, '0');
      day = parts[2].padLeft(2, '0');
      break;
  }

  return '$year-$month-$day';
}

String dateFromStorageFormat(String storageDate) {
  if (storageDate.isEmpty) return '';

  String format = xdef['.Date format'];
  String separator = xdef['.Date separator'];

  List<String> parts = storageDate.split('-');
  if (parts.length != 3) return storageDate;

  String year = parts[0];
  String month = parts[1];
  String day = parts[2];

  switch (format) {
    case 'DD-MM-YYYY':
      return day + separator + month + separator + year;

    case 'MM-DD-YYYY':
      return month + separator + day + separator + year;

    case 'YYYY-MM-DD':
    default:
      return year + separator + month + separator + day;
  }
}

String getDateFormatHint() {
  String format = xdef['.Date format'];
  String separator = xdef['.Date separator'];
  return format.replaceAll('-', separator);
}

String getDateFormatExample() {
  final today = DateTime.now();
  final day = today.day.toString().padLeft(2, '0');
  final month = today.month.toString().padLeft(2, '0');
  final year = today.year.toString();

  String format = xdef['.Date format'];
  String separator = xdef['.Date separator'];

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

bool isValidDateFormat(String input) {
  if (input.isEmpty) return false;

  String format = xdef['.Date format'];
  String separator = xdef['.Date separator'];

  String escapedSeparator = separator.replaceAll('.', '\\.');

  String pattern;
  switch (format) {
    case 'DD-MM-YYYY':
      pattern = '^\\d{1,2}$escapedSeparator\\d{1,2}$escapedSeparator\\d{4}\$';
      break;
    case 'MM-DD-YYYY':
      pattern = '^\\d{1,2}$escapedSeparator\\d{1,2}$escapedSeparator\\d{4}\$';
      break;
    case 'YYYY-MM-DD':
    default:
      pattern = '^\\d{4}$escapedSeparator\\d{1,2}$escapedSeparator\\d{1,2}\$';
      break;
  }

  return RegExp(pattern).hasMatch(input);
}

bool isValidDate(String input) {
  try {
    String storageFormat = dateToStorageFormat(input);
    final parts = storageFormat.split('-');
    if (parts.length != 3) return false;

    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final day = int.parse(parts[2]);

    final date = DateTime(year, month, day);
    return date.year == year && date.month == month && date.day == day;
  } catch (e) {
    return false;
  }
}

bool isDateNotInFuture(String input) {
  try {
    String storageFormat = dateToStorageFormat(input);
    final parts = storageFormat.split('-');
    if (parts.length != 3) return false;

    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final day = int.parse(parts[2]);

    final inputDate = DateTime(year, month, day);
    final currentDate = DateTime.now();

    return inputDate.isBefore(currentDate) || inputDate.isAtSameMomentAs(currentDate);
  } catch (e) {
    return false;
  }
}

bool isDateFromBeforeDateTo(String dateFrom, String dateTo) {
  try {
    String fromStorage = dateToStorageFormat(dateFrom);
    String toStorage = dateToStorageFormat(dateTo);

    final from = DateTime.parse(fromStorage);
    final to = DateTime.parse(toStorage);
    return from.isBefore(to) || from.isAtSameMomentAs(to);
  } catch (e) {
    return false;
  }
}

Future<DateTime?> showLocalizedDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
}) async {
  String lang = xdef['Program language'];
  Locale locale = Locale(getLocaleCode(lang));

  return showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: firstDate,
    lastDate: lastDate,
    locale: locale,
    builder: (BuildContext context, Widget? child) {
      return Theme(
        data: ThemeData.light().copyWith(
          colorScheme: ColorScheme.light(
            primary: clUpBar,
            onPrimary: clText,
            surface: clFill,
            onSurface: clText,
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: clText,
              backgroundColor: clUpBar,
            ),
          ),
        ),
        child: child!,
      );
    },
    helpText: '${lw('Select date')} (${getDateFormatHint()})',
  );
}

int dateToStorageInt(String displayDate) {
  if (displayDate.isEmpty) return 0;

  String isoDate = dateToStorageFormat(displayDate);

  try {
    List<String> parts = isoDate.split('-');
    if (parts.length != 3) return 0;

    int year = int.parse(parts[0]);
    int month = int.parse(parts[1]);
    int day = int.parse(parts[2]);

    return year * 10000 + month * 100 + day;
  } catch (e) {
    myPrint('Error converting date to int: $e');
    return 0;
  }
}

String dateFromStorageInt(int dateInt) {
  if (dateInt <= 0) return '';

  try {
    int year = dateInt ~/ 10000;
    int month = (dateInt % 10000) ~/ 100;
    int day = dateInt % 100;

    String isoDate = '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';

    return dateFromStorageFormat(isoDate);
  } catch (e) {
    myPrint('Error converting int to date: $e');
    return '';
  }
}

int getTodayAsInt() {
  final now = DateTime.now();
  return now.year * 10000 + now.month * 100 + now.day;
}

bool isValidDateInt(int dateInt) {
  if (dateInt <= 0) return false;

  try {
    int year = dateInt ~/ 10000;
    int month = (dateInt % 10000) ~/ 100;
    int day = dateInt % 100;

    if (year < 1900 || year > 2100) return false;
    if (month < 1 || month > 12) return false;
    if (day < 1 || day > 31) return false;

    if (month == 2) {
      bool isLeapYear = (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
      if (day > (isLeapYear ? 29 : 28)) return false;
    } else if ([4, 6, 9, 11].contains(month) && day > 30) {
      return false;
    }

    return true;
  } catch (e) {
    return false;
  }
}

bool isDateIntInFuture(int dateInt) {
  if (dateInt <= 0) return false;
  int todayInt = getTodayAsInt();
  return dateInt > todayInt;
}

bool isDateIntFromBeforeDateIntTo(int dateFromInt, int dateToInt) {
  if (dateFromInt <= 0 || dateToInt <= 0) return false;
  return dateFromInt <= dateToInt;
}

String sqlDateCondition(String fieldName, String displayDate) {
  int dateInt = dateToStorageInt(displayDate);
  return "$fieldName = $dateInt";
}

String sqlDateRangeCondition(String fieldName, String fromDate, String toDate) {
  int fromDateInt = dateToStorageInt(fromDate);
  int toDateInt = dateToStorageInt(toDate);
  return "$fieldName BETWEEN $fromDateInt AND $toDateInt";
}

bool validateDateInput(String input) {
  if (!isValidDateFormat(input)) {
    return false;
  }

  int dateInt = dateToStorageInt(input);
  if (!isValidDateInt(dateInt)) {
    return false;
  }

  if (isDateIntInFuture(dateInt)) {
    return false;
  }

  return true;
}

int dateTimeToInt(DateTime dateTime) {
  return dateTime.year * 10000 + dateTime.month * 100 + dateTime.day;
}

DateTime intToDateTime(int dateInt) {
  if (dateInt <= 0) {
    return DateTime.now();
  }

  int year = dateInt ~/ 10000;
  int month = (dateInt % 10000) ~/ 100;
  int day = dateInt % 100;

  return DateTime(year, month, day);
}

Future<String> showDatePickerWithFormat({
  required BuildContext context,
  required String currentDate,
}) async {
  DateTime initialDate;

  if (currentDate.isEmpty) {
    initialDate = DateTime.now();
  } else {
    int dateInt = dateToStorageInt(currentDate);
    initialDate = intToDateTime(dateInt);
  }

  if (initialDate.isAfter(DateTime.now())) {
    initialDate = DateTime.now();
  }

  final DateTime? pickedDate = await showLocalizedDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: DateTime(1900),
    lastDate: DateTime.now(),
  );

  if (pickedDate != null) {
    int dateInt = dateTimeToInt(pickedDate);
    return dateFromStorageInt(dateInt);
  }

  return currentDate;
}
