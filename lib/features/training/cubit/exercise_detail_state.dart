part of 'exercise_detail_cubit.dart';

enum ExerciseDetailStatus {
  loading,
  success,

  /// The exercise was deleted while its screen was open — the screen closes
  /// itself rather than showing a page about nothing.
  gone,
  failure,
}

final class ExerciseDetailState extends Equatable {
  const ExerciseDetailState({
    this.status = ExerciseDetailStatus.loading,
    this.exercise,
    this.progress = ExerciseProgress.empty,
    this.error,
  });

  final ExerciseDetailStatus status;
  final Exercise? exercise;
  final ExerciseProgress progress;
  final String? error;

  ExerciseDetailState copyWith({
    ExerciseDetailStatus? status,
    Exercise? exercise,
    ExerciseProgress? progress,
    String? error,
  }) {
    return ExerciseDetailState(
      status: status ?? this.status,
      exercise: exercise ?? this.exercise,
      progress: progress ?? this.progress,
      error: error,
    );
  }

  @override
  List<Object?> get props => [status, exercise, progress, error];
}
