import 'package:dream_gym/core/format/training_format.dart';
import 'package:dream_gym/core/providers.dart';
import 'package:dream_gym/features/training/data/training_repository.dart';
import 'package:dream_gym/features/training/domain/exercise_progress.dart';
import 'package:dream_gym/features/training/domain/training_entry.dart';
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
    final day = dayOf(ref.watch(clockProvider)());

    if (lastSession == null) {
      return LogTrainingState(
        exerciseId: _args.exerciseId,
        day: day,
        sets: 3,
        repsText: '',
        weightText: '',
        setRepsTexts: const ['', '', ''],
        setWeightTexts: const ['', '', ''],
      );
    }

    // The whole of last time, set by set, so 'the same again' is one tap.
    final done = lastSession.setsDone.take(maxSets).toList();
    final reps = [for (final set in done) set.reps?.toString() ?? ''];
    final weights = [for (final set in done) formatKilograms(set.weightKg)];

    return LogTrainingState(
      exerciseId: _args.exerciseId,
      day: day,
      sets: done.length,
      sameForEverySet: reps.toSet().length == 1 && weights.toSet().length == 1,
      repsText: reps.first,
      weightText: weights.first,
      setRepsTexts: List.unmodifiable(reps),
      setWeightTexts: List.unmodifiable(weights),
    );
  }

  void setsChanged(int sets) {
    final count = sets.clamp(1, maxSets);

    // A new set starts as a copy of the one before it — the usual next step is
    // the same again, or a little more.
    List<String> resized(List<String> current, String fallback) {
      final filler = current.isEmpty ? fallback : current.last;
      return List.unmodifiable([
        for (var i = 0; i < count; i++)
          i < current.length ? current[i] : filler,
      ]);
    }

    state = state.copyWith(
      sets: count,
      setRepsTexts: resized(state.setRepsTexts, state.repsText),
      setWeightTexts: resized(state.setWeightTexts, state.weightText),
      status: LogTrainingStatus.editing,
    );
  }

  /// Switches between one reps-and-weight for every set and one per set.
  void sameForEverySetChanged({required bool same}) {
    if (same == state.sameForEverySet) return;

    state = same
        ? state.copyWith(
            sameForEverySet: true,
            repsText: state.setRepsTexts.first,
            weightText: state.setWeightTexts.first,
            status: LogTrainingStatus.editing,
          )
        // Every set starts at the shared values; only the ones that differ
        // need touching.
        : state.copyWith(
            sameForEverySet: false,
            setRepsTexts: List.unmodifiable(
              List.filled(state.sets, state.repsText),
            ),
            setWeightTexts: List.unmodifiable(
              List.filled(state.sets, state.weightText),
            ),
            status: LogTrainingStatus.editing,
          );
  }

  void repsChanged(String value) {
    state = state.copyWith(repsText: value, status: LogTrainingStatus.editing);
  }

  void weightChanged(String value) {
    state = state.copyWith(
      weightText: value,
      status: LogTrainingStatus.editing,
    );
  }

  void setRepsChanged(int index, String value) {
    state = state.copyWith(
      setRepsTexts: List.unmodifiable(
        [...state.setRepsTexts]..[index] = value,
      ),
      status: LogTrainingStatus.editing,
    );
  }

  void setWeightChanged(int index, String value) {
    state = state.copyWith(
      setWeightTexts: List.unmodifiable(
        [...state.setWeightTexts]..[index] = value,
      ),
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
    final sets = form.setResults;
    if (sets == null || !form.canSave) return;

    state = form.copyWith(status: LogTrainingStatus.saving);

    try {
      await _training.log(
        exerciseId: form.exerciseId,
        day: form.day,
        sets: sets,
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
