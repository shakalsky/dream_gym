import 'package:dream_gym/features/exercises/data/exercise_repository.dart';
import 'package:dream_gym/features/training/data/training_repository.dart';
import 'package:dream_gym/features/training/data/watch_exercise_logs.dart';
import 'package:dream_gym/features/training/domain/exercise_log.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'exercises_state.dart';

final NotifierProvider<ExercisesNotifier, ExercisesState> exercisesProvider =
    NotifierProvider.autoDispose(ExercisesNotifier.new);

/// Drives the exercises list.
///
/// Subscribes rather than fetches: an entry logged three screens away has to
/// show up here as 'last trained today' without anyone remembering to refresh.
class ExercisesNotifier extends Notifier<ExercisesState> {
  late ExerciseRepository _exercises;

  @override
  ExercisesState build() {
    _exercises = ref.watch(exerciseRepositoryProvider);

    final subscription = watchExerciseLogs(
      exercises: _exercises,
      training: ref.watch(trainingRepositoryProvider),
    ).listen(_onLogs, onError: _onError);
    ref.onDispose(subscription.cancel);

    return const ExercisesState();
  }

  /// Removes an exercise and everything logged against it.
  Future<void> deleteExercise(String id) async {
    try {
      await _exercises.delete(id);
    } on Exception catch (error) {
      if (!ref.mounted) return;
      state = state.copyWith(status: ExercisesStatus.failure, error: '$error');
    }
  }

  /// Clears a failure the screen has finished reporting, so the same message is
  /// not shown twice.
  void errorShown() {
    if (state.error == null) return;
    state = state.copyWith(status: ExercisesStatus.success);
  }

  void _onLogs(List<ExerciseLog> logs) {
    state = ExercisesState(status: ExercisesStatus.success, logs: logs);
  }

  void _onError(Object error) {
    state = state.copyWith(status: ExercisesStatus.failure, error: '$error');
  }
}
