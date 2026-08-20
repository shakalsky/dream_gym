import 'package:equatable/equatable.dart';

/// One line the reader wrote down during a training: this many sets of an
/// exercise, at this weight, on this day.
///
/// A day can hold several entries for the same exercise — a lighter warm-up
/// and then working sets is two lines, not one — which is why the day is not
/// the identity.
final class TrainingEntry extends Equatable {
  const TrainingEntry({
    required this.id,
    required this.exerciseId,
    required this.performedOn,
    required this.sets,
    required this.weightKg,
    required this.createdAt,
  });

  final String id;
  final String exerciseId;

  /// The training day, at local midnight.
  final DateTime performedOn;

  final int sets;
  final double weightKg;
  final DateTime createdAt;

  /// Sets times weight — the number that actually tracks getting stronger,
  /// since three sets at 60 is more work than one at 70.
  double get volumeKg => sets * weightKg;

  @override
  List<Object?> get props => [
    id,
    exerciseId,
    performedOn,
    sets,
    weightKg,
    createdAt,
  ];
}
