import 'package:dream_gym/core/providers.dart';
import 'package:dream_gym/features/training/domain/exercise_progress.dart';
import 'package:dream_gym/features/training/domain/training_entry.dart';
import 'package:dream_gym/features/training/providers/log_training_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_database.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(openTestDatabase()),
        clockProvider.overrideWithValue(() => DateTime(2026, 10, 25, 12)),
      ],
    );
    addTearDown(container.dispose);
  });

  TrainingEntry entry(int sets, double weightKg, {int? reps, int order = 0}) {
    return TrainingEntry(
      id: '$order',
      exerciseId: 'bench',
      performedOn: DateTime(2026, 10, 20),
      sets: sets,
      reps: reps,
      weightKg: weightKg,
      createdAt: DateTime(2026, 10, 20, 18, 0, order),
    );
  }

  /// Opens the form and keeps it alive for the rest of the test.
  LogTrainingProviderHandle open([List<TrainingEntry>? lastTime]) {
    final provider = logTrainingProvider((
      exerciseId: 'bench',
      lastSession: lastTime == null
          ? null
          : TrainingSession(day: DateTime(2026, 10, 20), entries: lastTime),
    ));
    final subscription = container.listen(provider, (_, _) {});
    addTearDown(subscription.close);

    return (
      read: () => container.read(provider),
      notifier: container.read(provider.notifier),
    );
  }

  test('a first training opens empty and cannot be saved yet', () {
    final form = open();

    expect(form.read().sets, 3);
    expect(form.read().sameForEverySet, isTrue);
    expect(form.read().canSave, isFalse);

    form.notifier
      ..repsChanged('10')
      ..weightChanged('62,5');

    expect(form.read().setResults, List.filled(3, (reps: 10, weightKg: 62.5)));
    expect(form.read().canSave, isTrue);
  });

  test('takes bodyweight and assisted weights', () {
    final form = open();

    form.notifier
      ..repsChanged('8')
      ..weightChanged('-10.5');
    expect(form.read().setResults, List.filled(3, (reps: 8, weightKg: -10.5)));

    form.notifier.weightChanged('0');
    expect(form.read().canSave, isTrue);
  });

  test('an assisted set adds no volume', () {
    expect(entry(3, -20, reps: 8).volumeKg, 0);
    expect(entry(3, 20, reps: 8).volumeKg, 480);
  });

  test('opens on last time, set by set', () {
    final form = open([
      entry(1, 60, reps: 12),
      entry(2, 70, reps: 8, order: 1),
    ]);

    final state = form.read();
    expect(state.sets, 3);
    expect(state.sameForEverySet, isFalse);
    expect(state.setRepsTexts, ['12', '8', '8']);
    expect(state.setWeightTexts, ['60', '70', '70']);
  });

  test('opens on shared fields when every set was the same', () {
    final form = open([entry(3, 60)]);

    final state = form.read();
    expect(state.sameForEverySet, isTrue);
    expect(state.weightText, '60');
    expect(state.repsText, '', reason: 'reps were never recorded');
  });

  test('switching to per-set starts every set at the shared values', () {
    final form = open([entry(3, 60, reps: 10)]);

    form.notifier
      ..sameForEverySetChanged(same: false)
      ..setRepsChanged(2, '7')
      ..setWeightChanged(2, '65')
      ..setsChanged(4);

    expect(form.read().setRepsTexts, ['10', '10', '7', '7']);
    expect(form.read().setWeightTexts, ['60', '60', '65', '65']);
    expect(form.read().setResults, [
      (reps: 10, weightKg: 60.0),
      (reps: 10, weightKg: 60.0),
      (reps: 7, weightKg: 65.0),
      (reps: 7, weightKg: 65.0),
    ]);

    form.notifier.setsChanged(2);
    expect(form.read().setRepsTexts, ['10', '10']);
    expect(form.read().setWeightTexts, ['60', '60']);

    form.notifier.sameForEverySetChanged(same: true);
    expect(form.read().repsText, '10');
    expect(form.read().weightText, '60');
  });

  test('an unfinished set blocks saving', () {
    final form = open();

    form.notifier
      ..repsChanged('10')
      ..weightChanged('60')
      ..sameForEverySetChanged(same: false)
      ..setRepsChanged(1, '');

    expect(form.read().canSave, isFalse);
  });
}

typedef LogTrainingProviderHandle = ({
  LogTrainingState Function() read,
  LogTrainingNotifier notifier,
});
