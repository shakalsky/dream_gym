part of 'exercise_form_cubit.dart';

enum ExerciseFormStatus { editing, saving, saved, failure }

final class ExerciseFormState extends Equatable {
  const ExerciseFormState({
    required this.name,
    required this.photo,
    this.exerciseId,
    this.status = ExerciseFormStatus.editing,
    this.error,
  });

  /// Null while adding a new exercise, set while editing one.
  final String? exerciseId;

  final String name;
  final PhotoSelection photo;
  final ExerciseFormStatus status;
  final String? error;

  bool get isEditing => exerciseId != null;

  bool get isSaving => status == ExerciseFormStatus.saving;

  /// A name is the only thing required — the photo is a nicety, and demanding
  /// one would stop someone adding an exercise mid-workout.
  bool get canSave => name.trim().isNotEmpty && !isSaving;

  ExerciseFormState copyWith({
    String? name,
    PhotoSelection? photo,
    ExerciseFormStatus? status,
    String? error,
  }) {
    return ExerciseFormState(
      exerciseId: exerciseId,
      name: name ?? this.name,
      photo: photo ?? this.photo,
      status: status ?? this.status,
      error: error,
    );
  }

  @override
  List<Object?> get props => [exerciseId, name, photo, status, error];
}
