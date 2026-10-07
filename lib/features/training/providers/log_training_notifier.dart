import 'package:dream_gym/core/format/training_format.dart';
import 'package:dream_gym/core/providers.dart';
import 'package:dream_gym/features/training/data/training_repository.dart';
import 'package:dream_gym/features/training/domain/exercise_progress.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';

part 'log_training_state.dart';

/// What the form opens on: the exercise, and what was logged for it last time.
typedef LogTrainingArgs = ({String exerciseId, TrainingSession? lastSession});

/// Disposed with the sheet, so the next one opens on the latest session.
final NotifierProviderFamily<
  LogTrainingNotifier,
  LogTrainingState,
  LogTrainingArgs
>
logTrainingProvider = NotifierProvider.autoDispose.family(
  LogTrainingNotifier.new,
);

/// Drives the 'write down what I just did' form.
///
/// Opens pre-filled with the last thing logged for this exercise, because the
/// common case in a gym is 'the same as last time' or 'the same, a bit heavier'
/// — and the form is being used between sets, one-handed.
class LogTrainingNotifier extends Notifier<LogTrainingState> {
  LogTrainingNotifier(this._args);

  /// A set count nobody reaches by accident, and one that keeps the stepper
  /// from running away on a long press.
  static const maxSets = 30;

  final LogTrainingArgs _args;
  late TrainingRepository _training;

  @override
  LogTrainingState build() {
    _training = ref.watch(trainingRepositoryProvider);
    final lastSession = _args.lastSession;

    return LogTrainingState(
      exerciseId: _args.exerciseId,
      day: dayOf(ref.watch(clockProvider)()),
      sets: lastSession?.entries.last.sets ?? 3,
      weightText: lastSession == null
          ? ''
          : formatKilograms(lastSession.entries.last.weightKg),
    );
  }

  void setsChanged(int sets) {
    state = state.copyWith(
      sets: sets.clamp(1, maxSets),
      status: LogTrainingStatus.editing,
    );
  }

  void weightChanged(String value) {
    state = state.copyWith(
      weightText: value,
      status: LogTrainingStatus.editing,
    );
  }

  void dayChanged(DateTime day) {
    state = state.copyWith(day: dayOf(day), status: LogTrainingStatus.editing);
  }

  Future<void> save() async {
    // Taken once, up front: the write below carries on even if the sheet is
    // closed mid-save, and a disposed notifier has no state left to read.
    final form = state;
    final weightKg = form.weightKg;
    if (weightKg == null || !form.canSave) return;

    state = form.copyWith(status: LogTrainingStatus.saving);

    try {
      await _training.log(
        exerciseId: form.exerciseId,
        day: form.day,
        sets: form.sets,
        weightKg: weightKg,
      );

      if (!ref.mounted) return;
      state = state.copyWith(status: LogTrainingStatus.saved);
    } on Exception catch (error) {
      if (!ref.mounted) return;
      state = state.copyWith(
        status: LogTrainingStatus.failure,
        error: 'Could not save the result: $error',
      );
    }
  }
}
