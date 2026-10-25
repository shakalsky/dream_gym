part of 'log_training_notifier.dart';

enum LogTrainingStatus { editing, saving, saved, failure }

final class LogTrainingState extends Equatable {
  const LogTrainingState({
    required this.exerciseId,
    required this.day,
    required this.sets,
    required this.repsText,
    required this.weightText,
    required this.setRepsTexts,
    required this.setWeightTexts,
    this.sameForEverySet = true,
    this.status = LogTrainingStatus.editing,
    this.error,
  });

  final String exerciseId;

  /// The training day. Defaults to today, but is editable — results get written
  /// up on the way home as often as in the gym.
  final DateTime day;

  final int sets;

  /// Whether every set was done at [repsText] and [weightText], or each with
  /// its own from [setRepsTexts] and [setWeightTexts].
  final bool sameForEverySet;

  /// The reps for all sets, used while [sameForEverySet] is on.
  final String repsText;

  /// The weight for all sets, used while [sameForEverySet] is on.
  ///
  /// Kept as text, not a double: a half-typed '6' on the way to '62.5' is a
  /// state the form has to be able to hold.
  final String weightText;

  /// Reps per set, used while [sameForEverySet] is off. Always [sets] long.
  final List<String> setRepsTexts;

  /// Weight per set, used while [sameForEverySet] is off. Always [sets] long.
  final List<String> setWeightTexts;

  final LogTrainingStatus status;
  final String? error;

  bool get isSaving => status == LogTrainingStatus.saving;

  /// Every set as numbers, or null while any field does not hold one.
  List<SetResult>? get setResults {
    if (sameForEverySet) {
      final reps = parseReps(repsText);
      final weightKg = parseWeight(weightText);
      if (reps == null || weightKg == null) return null;
      return List.filled(sets, (reps: reps, weightKg: weightKg));
    }

    final results = <SetResult>[];
    for (var i = 0; i < sets; i++) {
      final reps = parseReps(setRepsTexts[i]);
      final weightKg = parseWeight(setWeightTexts[i]);
      if (reps == null || weightKg == null) return null;
      results.add((reps: reps, weightKg: weightKg));
    }
    return results;
  }

  bool get canSave => sets > 0 && setResults != null && !isSaving;

  /// Typed reps as a number, or null when they are not a positive one.
  static int? parseReps(String text) {
    final parsed = int.tryParse(text.trim());
    if (parsed == null || parsed <= 0) return null;
    return parsed;
  }

  /// A typed weight as a number, or null when it is not one.
  ///
  /// Zero is bodyweight, and below zero is assistance — an assisted pull-up
  /// machine taking 20 kg off is logged as -20.
  ///
  /// A comma is accepted because half the world's keyboards offer one for
  /// decimals.
  static double? parseWeight(String text) {
    final parsed = double.tryParse(text.trim().replaceAll(',', '.'));
    if (parsed == null || !parsed.isFinite) return null;
    return parsed;
  }

  LogTrainingState copyWith({
    DateTime? day,
    int? sets,
    bool? sameForEverySet,
    String? repsText,
    String? weightText,
    List<String>? setRepsTexts,
    List<String>? setWeightTexts,
    LogTrainingStatus? status,
    String? error,
  }) {
    return LogTrainingState(
      exerciseId: exerciseId,
      day: day ?? this.day,
      sets: sets ?? this.sets,
      sameForEverySet: sameForEverySet ?? this.sameForEverySet,
      repsText: repsText ?? this.repsText,
      weightText: weightText ?? this.weightText,
      setRepsTexts: setRepsTexts ?? this.setRepsTexts,
      setWeightTexts: setWeightTexts ?? this.setWeightTexts,
      status: status ?? this.status,
      error: error,
    );
  }

  @override
  List<Object?> get props => [
    exerciseId,
    day,
    sets,
    sameForEverySet,
    repsText,
    weightText,
    setRepsTexts,
    setWeightTexts,
    status,
    error,
  ];
}
