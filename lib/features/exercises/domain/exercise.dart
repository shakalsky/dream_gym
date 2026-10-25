import 'package:dream_gym/features/exercises/domain/exercise_icon.dart';
import 'package:equatable/equatable.dart';

/// One movement the reader trains.
final class Exercise extends Equatable {
  const Exercise({
    required this.id,
    required this.name,
    required this.createdAt,
    this.icon = ExerciseIcon.fallback,
    this.photoFileName,
  });

  final String id;
  final String name;

  /// Shown wherever the exercise has no photo.
  final ExerciseIcon icon;

  /// Name of the file in the photo store, or null when the reader did not add
  /// one. A photo is optional on purpose — it should never stand between the
  /// reader and writing down a set.
  final String? photoFileName;

  final DateTime createdAt;

  @override
  List<Object?> get props => [id, name, icon, photoFileName, createdAt];
}
