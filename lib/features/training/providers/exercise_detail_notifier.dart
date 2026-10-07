import 'package:dream_gym/core/streams/combine_latest.dart';
import 'package:dream_gym/features/exercises/data/exercise_repository.dart';
import 'package:dream_gym/features/exercises/domain/exercise.dart';
import 'package:dream_gym/features/training/data/training_repository.dart';
import 'package:dream_gym/features/training/domain/exercise_progress.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';

part 'exercise_detail_state.dart';

/// One per exercise id, and gone once its screen closes.
final NotifierProviderFamily<
  ExerciseDetailNotifier,
  ExerciseDetailState,
  String
>
exerciseDetailProvider = NotifierProvider.autoDispose.family(
  ExerciseDetailNotifier.new,
);

/// Drives one exercise's screen: its photo, its numbers and its history.
class ExerciseDetailNotifier extends Notifier<ExerciseDetailState> {
  ExerciseDetailNotifier(this._exerciseId);

  final String _exerciseId;
  late ExerciseRepository _exercises;
  late TrainingRepository _training;

  @override
  ExerciseDetailState build() {
    _exercises = ref.watch(exerciseRepositoryProvider);
    _training = ref.watch(trainingRepositoryProvider);

    final subscription =
        combineLatest2(
          _exercises.watch(_exerciseId),
          _training.watchForExercise(_exerciseId),
          (exercise, entries) => exercise == null
              ? const ExerciseDetailState(status: ExerciseDetailStatus.gone)
              : ExerciseDetailState(
                  status: ExerciseDetailStatus.success,
                  exercise: exercise,
                  progress: ExerciseProgress.fromEntries(entries),
                ),
        ).listen((next) => state = next, onError: _onError);
    ref.onDispose(subscription.cancel);

    return const ExerciseDetailState();
  }

  /// Removes the exercise and its whole history.
  ///
  /// Nothing is popped here: the deletion reaches the screen back through the
  /// stream as [ExerciseDetailStatus.gone], which is the same path taken when
  /// the row disappears for any other reason.
  Future<void> deleteExercise() async {
    try {
      await _exercises.delete(_exerciseId);
    } on Exception catch (error) {
      if (!ref.mounted) return;
      state = state.copyWith(error: '$error');
    }
  }

  /// Removes one logged line. The session it belonged to disappears with it if
  /// it was the only one that day.
  Future<void> deleteEntry(String id) async {
    try {
      await _training.deleteEntry(id);
    } on Exception catch (error) {
      if (!ref.mounted) return;
      state = state.copyWith(
        status: ExerciseDetailStatus.success,
        error: '$error',
      );
    }
  }

  void errorShown() {
    if (state.error == null) return;
    state = state.copyWith();
  }

  void _onError(Object error) {
    state = state.copyWith(
      status: ExerciseDetailStatus.failure,
      error: '$error',
    );
  }
}
