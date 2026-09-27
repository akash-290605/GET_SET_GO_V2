import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

class TimeService extends ChangeNotifier {
  static final TimeService instance = TimeService._internal();

  Timer? _timer;
  DateTime _istNow = _calculateIstNow();

  TimeService._internal() {
    _startClock();
  }

  static DateTime _calculateIstNow() {
    final utc = DateTime.now().toUtc();
    return utc.add(const Duration(hours: 5, minutes: 30));
  }

  void _startClock() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _istNow = _calculateIstNow();
      notifyListeners();
    });
  }

  DateTime get istNow => _istNow;

  String get currentTimeString => DateFormat('hh:mm:ss a').format(_istNow);

  String get currentTimeShort => DateFormat('hh:mm a').format(_istNow);

  String get currentDateString => DateFormat('EEEE, d MMMM yyyy').format(_istNow);

  String get currentDateShort => DateFormat('d MMM yyyy').format(_istNow);

  String get todayDateKey => DateFormat('yyyy-MM-dd').format(_istNow);

  String get todayDayName => DateFormat('EEEE').format(_istNow);

  String get currentIsoWeekKey => getWeekKey(_istNow);

  static String getWeekKey(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    final dayNr = (d.weekday + 6) % 7;
    final thursday = d.subtract(Duration(days: dayNr - 3));
    final firstThursday = DateTime(thursday.year, 1, 4);
    final firstThursdayDayNr = (firstThursday.weekday + 6) % 7;
    final firstWeekStart = firstThursday.subtract(Duration(days: firstThursdayDayNr));
    final weekNr = ((thursday.difference(firstWeekStart).inDays) / 7).floor() + 1;
    final weekFormatted = weekNr.toString().padLeft(2, '0');
    return '${thursday.year}-W$weekFormatted';
  }

  static String formatDateKey(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
