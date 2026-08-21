import 'package:equatable/equatable.dart';
import 'package:my_calm_ui_package/my_calm_ui_package.dart';

/// The unit every weight in the app is shown in.
///
/// Storage stays in kilograms regardless — this is a display choice, so that
/// switching it cannot rewrite history or round a log twice.
enum WeightUnit {
  kilograms('Kilograms', 'kg'),
  pounds('Pounds', 'lb');

  const WeightUnit(this.label, this.suffix);

  final String label;
  final String suffix;

  static const _kgPerLb = 0.45359237;

  /// Converts a stored kilogram value into this unit.
  double fromKilograms(double kg) =>
      this == WeightUnit.kilograms ? kg : kg / _kgPerLb;

  static WeightUnit parse(String name) => WeightUnit.values.firstWhere(
    (unit) => unit.name == name,
    orElse: () => WeightUnit.kilograms,
  );
}

/// Which theme the reader asked for, as opposed to which one is showing.
enum ThemeChoice {
  light('Light', ThemeMode.light),
  dark('Dark', ThemeMode.dark),
  system('System', ThemeMode.system);

  const ThemeChoice(this.label, this.mode);

  final String label;
  final ThemeMode mode;

  static ThemeChoice parse(String name) => ThemeChoice.values.firstWhere(
    (choice) => choice.name == name,
    orElse: () => ThemeChoice.system,
  );
}

/// Everything the settings screen can change.
///
/// A value object, so the cubit can emit a changed copy and the repository can
/// write one without either knowing about the table's columns.
final class AppSettings extends Equatable {
  const AppSettings({
    this.unit = WeightUnit.kilograms,
    this.theme = ThemeChoice.system,
    this.trainingReminder = false,
    this.reminderMinutes = 18 * 60 + 30,
    this.weeklySummary = false,
  });

  final WeightUnit unit;
  final ThemeChoice theme;

  /// Whether to nudge the reader on the days they usually train.
  final bool trainingReminder;

  /// Minutes since local midnight.
  final int reminderMinutes;

  final bool weeklySummary;

  TimeOfDay get reminderTime =>
      TimeOfDay(hour: reminderMinutes ~/ 60, minute: reminderMinutes % 60);

  /// 24-hour, padded — the format the row shows.
  String get reminderLabel {
    final time = reminderTime;
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }

  AppSettings copyWith({
    WeightUnit? unit,
    ThemeChoice? theme,
    bool? trainingReminder,
    int? reminderMinutes,
    bool? weeklySummary,
  }) {
    return AppSettings(
      unit: unit ?? this.unit,
      theme: theme ?? this.theme,
      trainingReminder: trainingReminder ?? this.trainingReminder,
      reminderMinutes: reminderMinutes ?? this.reminderMinutes,
      weeklySummary: weeklySummary ?? this.weeklySummary,
    );
  }

  @override
  List<Object?> get props => [
    unit,
    theme,
    trainingReminder,
    reminderMinutes,
    weeklySummary,
  ];
}
