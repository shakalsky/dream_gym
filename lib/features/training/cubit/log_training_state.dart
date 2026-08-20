part of 'log_training_cubit.dart';

enum LogTrainingStatus { editing, saving, saved, failure }

final class LogTrainingState extends Equatable {
  const LogTrainingState({
    required this.exerciseId,
    required this.day,
    required this.sets,
    required this.weightText,
    this.status = LogTrainingStatus.editing,
    this.error,
  });

  final String exerciseId;

  /// The training day. Defaults to today, but is editable — results get written
  /// up on the way home as often as in the gym.
  final DateTime day;

  final int sets;

  /// Kept as text, not a double: a half-typed '6' on the way to '62.5' is a
  /// state the form has to be able to hold.
  final String weightText;

  final LogTrainingStatus status;
  final String? error;

  bool get isSaving => status == LogTrainingStatus.saving;

  /// The weight as a number, or null while the field does not hold one.
  ///
  /// A comma is accepted because half the world's keyboards offer one for
  /// decimals.
  double? get weightKg {
    final parsed = double.tryParse(weightText.trim().replaceAll(',', '.'));
    if (parsed == null || parsed <= 0 || !parsed.isFinite) return null;
    return parsed;
  }

  bool get canSave => weightKg != null && sets > 0 && !isSaving;

  LogTrainingState copyWith({
    DateTime? day,
    int? sets,
    String? weightText,
    LogTrainingStatus? status,
    String? error,
  }) {
    return LogTrainingState(
      exerciseId: exerciseId,
      day: day ?? this.day,
      sets: sets ?? this.sets,
      weightText: weightText ?? this.weightText,
      status: status ?? this.status,
      error: error,
    );
  }

  @override
  List<Object?> get props => [
    exerciseId,
    day,
    sets,
    weightText,
    status,
    error,
  ];
}
