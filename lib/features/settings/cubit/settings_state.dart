part of 'settings_cubit.dart';

enum SettingsStatus { loading, success, failure }

final class SettingsState extends Equatable {
  const SettingsState({
    this.status = SettingsStatus.loading,
    this.settings = const AppSettings(),
    this.error,
  });

  final SettingsStatus status;

  /// The defaults until the first read comes back — the screen is readable
  /// immediately and no spinner is needed for a single row.
  final AppSettings settings;

  /// Set when a write failed; the screen reports it and calls `errorShown`.
  final String? error;

  SettingsState copyWith({
    SettingsStatus? status,
    AppSettings? settings,
    String? error,
  }) {
    return SettingsState(
      status: status ?? this.status,
      settings: settings ?? this.settings,
      // Not `error ?? this.error`: a shown message needs a way to be dropped.
      error: error,
    );
  }

  @override
  List<Object?> get props => [status, settings, error];
}
