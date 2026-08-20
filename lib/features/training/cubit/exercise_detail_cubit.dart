import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:dream_gym/core/streams/combine_latest.dart';
import 'package:dream_gym/features/exercises/data/exercise_repository.dart';
import 'package:dream_gym/features/exercises/domain/exercise.dart';
import 'package:dream_gym/features/training/data/training_repository.dart';
import 'package:dream_gym/features/training/domain/exercise_progress.dart';
import 'package:equatable/equatable.dart';

part 'exercise_detail_state.dart';

/// Drives one exercise's screen: its photo, its numbers and its history.
class ExerciseDetailCubit extends Cubit<ExerciseDetailState> {
  ExerciseDetailCubit({
    required ExerciseRepository exercises,
    required TrainingRepository training,
    required String exerciseId,
  }) : _exercises = exercises,
       _training = training,
       _exerciseId = exerciseId,
       super(const ExerciseDetailState()) {
    _subscription =
        combineLatest2(
          exercises.watch(exerciseId),
          training.watchForExercise(exerciseId),
          (exercise, entries) => exercise == null
              ? const ExerciseDetailState(status: ExerciseDetailStatus.gone)
              : ExerciseDetailState(
                  status: ExerciseDetailStatus.success,
                  exercise: exercise,
                  progress: ExerciseProgress.fromEntries(entries),
                ),
        ).listen(_onState, onError: _onError);
  }

  final ExerciseRepository _exercises;
  final TrainingRepository _training;
  final String _exerciseId;
  late final StreamSubscription<ExerciseDetailState> _subscription;

  /// Removes the exercise and its whole history.
  ///
  /// Nothing is popped here: the deletion reaches the screen back through the
  /// stream as [ExerciseDetailStatus.gone], which is the same path taken when
  /// the row disappears for any other reason.
  Future<void> deleteExercise() async {
    try {
      await _exercises.delete(_exerciseId);
    } on Exception catch (error) {
      if (isClosed) return;
      emit(state.copyWith(error: '$error'));
    }
  }

  /// Removes one logged line. The session it belonged to disappears with it if
  /// it was the only one that day.
  Future<void> deleteEntry(String id) async {
    try {
      await _training.deleteEntry(id);
    } on Exception catch (error) {
      if (isClosed) return;
      emit(
        state.copyWith(status: ExerciseDetailStatus.success, error: '$error'),
      );
    }
  }

  void errorShown() {
    if (state.error == null) return;
    emit(state.copyWith());
  }

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }

  void _onState(ExerciseDetailState next) {
    if (isClosed) return;
    emit(next);
  }

  void _onError(Object error) {
    if (isClosed) return;
    emit(
      state.copyWith(
        status: ExerciseDetailStatus.failure,
        error: '$error',
      ),
    );
  }
}
