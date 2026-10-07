part of 'statistics_notifier.dart';

enum StatisticsStatus { loading, success, failure }

final class StatisticsState extends Equatable {
  const StatisticsState({
    this.status = StatisticsStatus.loading,
    this.logs = const [],
    this.summary = TrainingSummary.empty,
    this.selectedExerciseId,
    this.metric = ProgressMetric.weight,
    this.error,
  });

  final StatisticsStatus status;

  /// Every exercise, including ones never trained — they are what the empty
  /// state has to talk about.
  final List<ExerciseLog> logs;

  final TrainingSummary summary;

  /// Which exercise the chart is about, or null when nothing has been trained.
  final String? selectedExerciseId;

  final ProgressMetric metric;
  final String? error;

  /// Only the exercises there is something to plot for.
  List<ExerciseLog> get trained =>
      logs.where((log) => log.progress.isNotEmpty).toList(growable: false);

  ExerciseLog? get selected {
    for (final log in logs) {
      if (log.exercise.id == selectedExerciseId) return log;
    }
    return null;
  }

  bool get hasData => trained.isNotEmpty;

  StatisticsState copyWith({
    StatisticsStatus? status,
    List<ExerciseLog>? logs,
    TrainingSummary? summary,
    String? selectedExerciseId,
    ProgressMetric? metric,
    String? error,
  }) {
    return StatisticsState(
      status: status ?? this.status,
      logs: logs ?? this.logs,
      summary: summary ?? this.summary,
      selectedExerciseId: selectedExerciseId ?? this.selectedExerciseId,
      metric: metric ?? this.metric,
      error: error,
    );
  }

  @override
  List<Object?> get props => [
    status,
    logs,
    summary,
    selectedExerciseId,
    metric,
    error,
  ];
}
