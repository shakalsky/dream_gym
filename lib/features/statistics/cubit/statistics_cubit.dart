import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:dream_gym/features/exercises/data/exercise_repository.dart';
import 'package:dream_gym/features/statistics/domain/training_summary.dart';
import 'package:dream_gym/features/training/data/training_repository.dart';
import 'package:dream_gym/features/training/data/watch_exercise_logs.dart';
import 'package:dream_gym/features/training/domain/exercise_log.dart';
import 'package:dream_gym/features/training/domain/exercise_progress.dart';
import 'package:equatable/equatable.dart';

part 'statistics_state.dart';

/// Drives the statistics screen.
class StatisticsCubit extends Cubit<StatisticsState> {
  StatisticsCubit({
    required ExerciseRepository exercises,
    required TrainingRepository training,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now,
       super(const StatisticsState()) {
    _subscription =
        watchExerciseLogs(exercises: exercises, training: training).listen(
          _onLogs,
          onError: _onError,
        );
  }

  final DateTime Function() _clock;
  late final StreamSubscription<List<ExerciseLog>> _subscription;

  void exerciseSelected(String exerciseId) {
    emit(state.copyWith(selectedExerciseId: exerciseId));
  }

  void metricSelected(ProgressMetric metric) {
    emit(state.copyWith(metric: metric));
  }

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }

  void _onLogs(List<ExerciseLog> logs) {
    if (isClosed) return;

    final trained = logs
        .where((log) => log.progress.isNotEmpty)
        .toList(growable: false);

    emit(
      state.copyWith(
        status: StatisticsStatus.success,
        logs: logs,
        summary: TrainingSummary.fromLogs(logs, today: _clock()),
        // Keeps a selection that still exists, and otherwise falls to whatever
        // was trained most recently — which is what the reader came to look at.
        selectedExerciseId: _resolveSelection(trained),
      ),
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
    if (isClosed) return;
    emit(state.copyWith(status: StatisticsStatus.failure, error: '$error'));
  }
}
