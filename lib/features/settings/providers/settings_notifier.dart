import 'package:dream_gym/features/settings/data/settings_repository.dart';
import 'package:dream_gym/features/settings/domain/app_settings.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'settings_state.dart';

/// Not auto-disposed: `App` watches it for the theme, so it lives as long as
/// the app does, and the settings page reads this same instance rather than a
/// second one that could disagree with it.
final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(
  SettingsNotifier.new,
);

/// Drives the settings screen — and, through [SettingsState.settings], the
/// theme of the whole app.
///
/// Subscribes rather than fetches, so a preference changed on another device
/// (once PowerSync is carrying the row) arrives without a refresh. Writes go
/// straight to the repository and come back through the subscription: one
/// source of truth, no optimistic copy to reconcile.
class SettingsNotifier extends Notifier<SettingsState> {
  late SettingsRepository _settings;

  @override
  SettingsState build() {
    _settings = ref.watch(settingsRepositoryProvider);

    final subscription = _settings.watch().listen(
      _onSettings,
      onError: _onError,
    );
    ref.onDispose(subscription.cancel);

    return const SettingsState();
  }

  Future<void> unitChanged(WeightUnit unit) =>
      _write(state.settings.copyWith(unit: unit));

  Future<void> themeChanged(ThemeChoice theme) =>
      _write(state.settings.copyWith(theme: theme));

  /// Turns the training reminder on or off.
  // TODO(notifications): schedule or cancel the local notification here — the
  // stored flag and the OS's idea of it have to agree.
  Future<void> reminderChanged({required bool isOn}) =>
      _write(state.settings.copyWith(trainingReminder: isOn));

  Future<void> reminderTimeChanged(int minutesSinceMidnight) =>
      _write(state.settings.copyWith(reminderMinutes: minutesSinceMidnight));

  Future<void> weeklySummaryChanged({required bool isOn}) =>
      _write(state.settings.copyWith(weeklySummary: isOn));

  /// Clears a failure the screen has finished reporting.
  void errorShown() {
    if (state.error == null) return;
    state = state.copyWith(status: SettingsStatus.success);
  }

  Future<void> _write(AppSettings settings) async {
    try {
      await _settings.save(settings);
    } on Exception catch (error) {
      if (!ref.mounted) return;
      state = state.copyWith(status: SettingsStatus.failure, error: '$error');
    }
  }

  void _onSettings(AppSettings settings) {
    state = SettingsState(status: SettingsStatus.success, settings: settings);
  }

  void _onError(Object error) {
    state = state.copyWith(status: SettingsStatus.failure, error: '$error');
  }
}
