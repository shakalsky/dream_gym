/// Formatting for the two things this app puts on screen constantly: weights
/// and training days.
///
/// Hand-written rather than `intl`: the app has one language, and a weight is
/// the one number a reader will notice being wrong ('62.5 kg', never '62.50').
library;

const _monthNames = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// A weight, without a trailing '.0' — plates come in halves, so one decimal
/// is kept when there is one.
String formatWeight(double kilograms) => '${formatKilograms(kilograms)} kg';

/// The number part of [formatWeight], for places that label the unit
/// separately.
String formatKilograms(double kilograms) {
  if (kilograms.abs() >= 1000) {
    // A month of squats runs into five digits; a grouped thousand reads faster
    // than '12750'.
    return _grouped(kilograms.round());
  }

  final rounded = double.parse(kilograms.toStringAsFixed(1));
  return rounded == rounded.roundToDouble()
      ? rounded.round().toString()
      : rounded.toString();
}

/// How a logged entry reads on one line: '4 × 60 kg'.
String formatSetsByWeight(int sets, double kilograms) =>
    '$sets × ${formatWeight(kilograms)}';

/// '1 set' / '4 sets'.
String formatSets(int sets) => sets == 1 ? '1 set' : '$sets sets';

/// A training day as the reader thinks of it.
///
/// [today] is a parameter rather than read from the clock so that a test can
/// pick a day, and so that a screen that is open at midnight can be rebuilt
/// against the new day.
String formatDay(DateTime day, {required DateTime today}) {
  final difference = dayOf(day).difference(dayOf(today)).inDays;

  return switch (difference) {
    0 => 'Today',
    -1 => 'Yesterday',
    < 0 && >= -6 => '${-difference} days ago',
    _ => formatDate(day, withYear: day.year != today.year),
  };
}

/// '12 Aug', or '12 Aug 2025' when the year cannot be assumed.
String formatDate(DateTime day, {bool withYear = false}) {
  final month = _monthNames[day.month - 1];
  return withYear
      ? '${day.day} $month ${day.year}'
      : '${day.day} $month';
}

/// The date part of [dateTime], at local midnight.
///
/// Every training day in the database goes through here, so that two entries
/// made on the same day — morning and evening — land on the same value.
DateTime dayOf(DateTime dateTime) =>
    DateTime(dateTime.year, dateTime.month, dateTime.day);

/// Monday of the week [dateTime] falls in, at local midnight.
DateTime weekStartOf(DateTime dateTime) {
  final day = dayOf(dateTime);
  return day.subtract(Duration(days: day.weekday - DateTime.monday));
}

String _grouped(int value) {
  final digits = value.abs().toString();
  final buffer = StringBuffer(value.isNegative ? '-' : '');

  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(' ');
    buffer.write(digits[i]);
  }

  return buffer.toString();
}
