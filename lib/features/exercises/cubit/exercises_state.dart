part of 'exercises_cubit.dart';

enum ExercisesStatus { loading, success, failure }

final class ExercisesState extends Equatable {
  const ExercisesState({
    this.status = ExercisesStatus.loading,
    this.logs = const [],
    this.error,
  });

  final ExercisesStatus status;

  /// Every exercise with its progress, alphabetically.
  final List<ExerciseLog> logs;

  /// Set when a delete or a read failed; the screen reports it and calls
  /// `errorShown`.
  final String? error;

  bool get isEmpty => status == ExercisesStatus.success && logs.isEmpty;

  ExercisesState copyWith({
    ExercisesStatus? status,
    List<ExerciseLog>? logs,
    String? error,
  }) {
    return ExercisesState(
      status: status ?? this.status,
      logs: logs ?? this.logs,
      // Not `error ?? this.error`: a state that has been shown needs a way to
      // drop the message, and copyWith is it.
      error: error,
    );
  }

  @override
  List<Object?> get props => [status, logs, error];
}
