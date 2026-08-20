import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:dream_gym/features/exercises/data/exercise_repository.dart';
import 'package:dream_gym/features/training/data/training_repository.dart';
import 'package:dream_gym/features/training/data/watch_exercise_logs.dart';
import 'package:dream_gym/features/training/domain/exercise_log.dart';
import 'package:equatable/equatable.dart';

part 'exercises_state.dart';

/// Drives the exercises list.
///
/// Subscribes rather than fetches: an entry logged three screens away has to
/// show up here as 'last trained today' without anyone remembering to refresh.
class ExercisesCubit extends Cubit<ExercisesState> {
  ExercisesCubit({
    required ExerciseRepository exercises,
    required TrainingRepository training,
  }) : _exercises = exercises,
       super(const ExercisesState()) {
    _subscription =
        watchExerciseLogs(exercises: exercises, training: training).listen(
          _onLogs,
          onError: _onError,
        );
  }

  final ExerciseRepository _exercises;
  late final StreamSubscription<List<ExerciseLog>> _subscription;

  /// Removes an exercise and everything logged against it.
  Future<void> deleteExercise(String id) async {
    try {
      await _exercises.delete(id);
    } on Exception catch (error) {
      if (isClosed) return;
      emit(state.copyWith(status: ExercisesStatus.failure, error: '$error'));
    }
  }

  /// Clears a failure the screen has finished reporting, so the same message is
  /// not shown twice.
  void errorShown() {
    if (state.error == null) return;
    emit(state.copyWith(status: ExercisesStatus.success));
  }

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }

  void _onLogs(List<ExerciseLog> logs) {
    if (isClosed) return;
    emit(ExercisesState(status: ExercisesStatus.success, logs: logs));
  }

  void _onError(Object error) {
    if (isClosed) return;
    emit(state.copyWith(status: ExercisesStatus.failure, error: '$error'));
  }
}
