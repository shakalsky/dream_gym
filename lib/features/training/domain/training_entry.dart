import 'dart:math' as math;

import 'package:equatable/equatable.dart';

/// One set as the reader logs it: this many reps at this weight.
typedef SetResult = ({int reps, double weightKg});

/// One line the reader wrote down during a training: this many sets of an
/// exercise, of this many reps, at this weight, on this day.
///
/// A day can hold several entries for the same exercise — a lighter warm-up
/// and then working sets is two lines, not one — which is why the day is not
/// the identity. Sets logged together with different reps or weights are
/// stored the same way: one line per run of equal sets.
final class TrainingEntry extends Equatable {
  const TrainingEntry({
    required this.id,
    required this.exerciseId,
    required this.performedOn,
    required this.sets,
    required this.weightKg,
    required this.createdAt,
    this.reps,
  });

  final String id;
  final String exerciseId;

  /// The training day, at local midnight.
  final DateTime performedOn;

  final int sets;

  /// Repetitions in each set, or null for an entry logged before reps were
  /// recorded.
  final int? reps;

  final double weightKg;
  final DateTime createdAt;

  /// Sets times reps times weight — the number that actually tracks getting
  /// stronger, since three sets at 60 is more work than one at 70.
  ///
  /// An entry without reps counts each set once, which is what volume meant
  /// before reps were recorded.
  ///
  /// An assisted entry (below zero) counts as no load rather than taking
  /// work away: the bodyweight it was subtracted from is not known.
  double get volumeKg => sets * (reps ?? 1) * math.max(weightKg, 0);

  @override
  List<Object?> get props => [
    id,
    exerciseId,
    performedOn,
    sets,
    reps,
    weightKg,
    createdAt,
  ];
}
