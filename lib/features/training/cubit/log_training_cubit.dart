import 'package:bloc/bloc.dart';
import 'package:dream_gym/core/format/training_format.dart';
import 'package:dream_gym/features/training/data/training_repository.dart';
import 'package:dream_gym/features/training/domain/exercise_progress.dart';
import 'package:equatable/equatable.dart';

part 'log_training_state.dart';

/// Drives the 'write down what I just did' form.
///
/// Opens pre-filled with the last thing logged for this exercise, because the
/// common case in a gym is 'the same as last time' or 'the same, a bit heavier'
/// — and the form is being used between sets, one-handed.
class LogTrainingCubit extends Cubit<LogTrainingState> {
  LogTrainingCubit({
    required TrainingRepository training,
    required String exerciseId,
    required DateTime today,
    TrainingSession? lastSession,
  }) : _training = training,
       super(
         LogTrainingState(
           exerciseId: exerciseId,
           day: dayOf(today),
           sets: lastSession?.entries.last.sets ?? 3,
           weightText: lastSession == null
               ? ''
               : formatKilograms(lastSession.entries.last.weightKg),
         ),
       );

  /// A set count nobody reaches by accident, and one that keeps the stepper
  /// from running away on a long press.
  static const maxSets = 30;

  final TrainingRepository _training;

  void setsChanged(int sets) {
    emit(
      state.copyWith(
        sets: sets.clamp(1, maxSets),
        status: LogTrainingStatus.editing,
      ),
    );
  }

  void weightChanged(String value) {
    emit(
      state.copyWith(weightText: value, status: LogTrainingStatus.editing),
    );
  }

  void dayChanged(DateTime day) {
    emit(
      state.copyWith(day: dayOf(day), status: LogTrainingStatus.editing),
    );
  }

  Future<void> save() async {
    final weightKg = state.weightKg;
    if (weightKg == null || !state.canSave) return;

    emit(state.copyWith(status: LogTrainingStatus.saving));

    try {
      await _training.log(
        exerciseId: state.exerciseId,
        day: state.day,
        sets: state.sets,
        weightKg: weightKg,
      );

      if (isClosed) return;
      emit(state.copyWith(status: LogTrainingStatus.saved));
    } on Exception catch (error) {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: LogTrainingStatus.failure,
          error: 'Could not save the result: $error',
        ),
      );
    }
  }
}
