import 'package:dream_gym/core/providers.dart';
import 'package:dream_gym/features/exercises/data/exercise_repository.dart';
import 'package:dream_gym/features/statistics/domain/training_summary.dart';
import 'package:dream_gym/features/training/data/training_repository.dart';
import 'package:dream_gym/features/training/data/watch_exercise_logs.dart';
import 'package:dream_gym/features/training/domain/exercise_log.dart';
import 'package:dream_gym/features/training/domain/exercise_progress.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'statistics_state.dart';

final NotifierProvider<StatisticsNotifier, StatisticsState> statisticsProvider =
    NotifierProvider.autoDispose(StatisticsNotifier.new);

/// Drives the statistics screen.
class StatisticsNotifier extends Notifier<StatisticsState> {
  late DateTime Function() _clock;

  @override
  StatisticsState build() {
    _clock = ref.watch(clockProvider);

    final subscription = watchExerciseLogs(
      exercises: ref.watch(exerciseRepositoryProvider),
      training: ref.watch(trainingRepositoryProvider),
    ).listen(_onLogs, onError: _onError);
    ref.onDispose(subscription.cancel);

    return const StatisticsState();
  }

  void exerciseSelected(String exerciseId) {
    state = state.copyWith(selectedExerciseId: exerciseId);
  }

  void metricSelected(ProgressMetric metric) {
    state = state.copyWith(metric: metric);
  }

  void _onLogs(List<ExerciseLog> logs) {
    final trained = logs
        .where((log) => log.progress.isNotEmpty)
        .toList(growable: false);

    state = state.copyWith(
      status: StatisticsStatus.success,
      logs: logs,
      summary: TrainingSummary.fromLogs(logs, today: _clock()),
      // Keeps a selection that still exists, and otherwise falls to whatever
      // was trained most recently — which is what the reader came to look at.
      selectedExerciseId: _resolveSelection(trained),
    );
  }

  String? _resolveSelection(List<ExerciseLog> trained) {
    final selected = state.selectedExerciseId;
    final stillTrained = trained.any(
      (log) => log.exercise.id == selected,
    );
    if (selected != null && stillTrained) return selected;
    if (trained.isEmpty) return null;

    return trained
        .reduce(
          (latest, log) =>
              log.progress.lastTrainedOn!.isAfter(latest.progress.lastTrainedOn!)
              ? log
              : latest,
        )
        .exercise
        .id;
  }

  void _onError(Object error) {
    state = state.copyWith(status: StatisticsStatus.failure, error: '$error');
  }
}
