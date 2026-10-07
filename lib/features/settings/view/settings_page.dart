import 'package:dream_gym/core/ui/app_card.dart';
import 'package:dream_gym/env/app_env.dart';
import 'package:dream_gym/features/settings/domain/account.dart';
import 'package:dream_gym/features/settings/domain/app_settings.dart';
import 'package:dream_gym/features/settings/providers/settings_notifier.dart';
import 'package:dream_gym/features/settings/widgets/settings_row.dart';
import 'package:dream_gym/features/settings/widgets/settings_section.dart';
import 'package:dream_gym/features/settings/widgets/sync_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_calm_ui_package/my_calm_ui_package.dart';

/// Everything about the app rather than about the training.
///
/// Reads the same [settingsProvider] that `App` watches for the theme (see
/// `app/view/app.dart`), so what this page shows and what the app looks like
/// cannot disagree.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({required this.env, this.account, super.key});

  final AppEnv env;

  /// Null until auth is wired, or when nobody is signed in.
  final Account? account;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(settingsProvider, (previous, next) {
      final error = next.error;
      if (error == null) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      ref.read(settingsProvider.notifier).errorShown();
    });

    final settings = ref.watch(
      settingsProvider.select((state) => state.settings),
    );

    return Scaffold(
      appBar: const AppAppBar(title: 'Settings', centerTitle: false),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSizes.defaultPadding,
          AppSizes.padding12,
          AppSizes.defaultPadding,
          AppSizes.padding32,
        ),
        children: [
          _AccountCard(account: account),
          AppSizes.padding24.verticalSpace,
          SettingsSection(
            title: 'Sync',
            padding: EdgeInsets.zero,
            children: [
              // TODO(sync): replace with PowerSync's status stream.
              SyncCard(
                status: env.hasBackend
                    ? SyncStatus(
                        isConnected: true,
                        lastSyncedAt: DateTime.now(),
                      )
                    : const SyncStatus.offline(),
                onSyncNow: env.hasBackend ? () {} : null,
              ),
            ],
          ),
          AppSizes.padding24.verticalSpace,
          _PreferencesSection(settings: settings),
          AppSizes.padding24.verticalSpace,
          _RemindersSection(settings: settings),
          AppSizes.padding24.verticalSpace,
          SettingsSection(
            title: 'Your data',
            padding: EdgeInsets.zero,
            children: [
              SettingsRow(
                title: 'Export training log',
                subtitle: 'CSV of every session and set.',
                onTap: () {},
              ),
              const SettingsDivider(indent: AppSizes.defaultPadding),
              SettingsRow(
                title: 'Import from a file',
                subtitle: 'Bring in a log from another app.',
                onTap: () {},
              ),
            ],
          ),
          AppSizes.padding24.verticalSpace,
          SettingsSection(
            title: 'About',
            padding: EdgeInsets.zero,
            children: [
              SettingsRow(
                title: 'Version',
                value: env.flavor.isDevelopment
                    ? '1.0.0 (1) · ${env.flavor.name}'
                    : '1.0.0 (1)',
              ),
              const SettingsDivider(indent: AppSizes.defaultPadding),
              SettingsRow(
                title: 'Open source licences',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) => const LicensePage(),
                  ),
                ),
              ),
              const SettingsDivider(indent: AppSizes.defaultPadding),
              SettingsRow(title: 'Privacy policy', onTap: () {}),
            ],
          ),
          if (account != null) ...[
            AppSizes.padding24.verticalSpace,
            _SignOutCard(onPressed: () {}),
          ],
        ],
      ),
    );
  }
}

/// Who is signed in — or an invitation to be.
class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.account});

  final Account? account;

  @override
  Widget build(BuildContext context) {
    final colors = context.appThemeColors;
    final account = this.account;

    if (account == null) {
      return SettingsSection(
        title: 'Account',
        padding: EdgeInsets.zero,
        children: [
          SettingsRow(
            title: 'Sign in',
            subtitle: 'Keep your training if you change phone.',
            // TODO(auth): open the sign-in flow.
            onTap: () {},
          ),
        ],
      );
    }

    return AppCard(
      padding: const EdgeInsets.all(AppSizes.padding12),
      // TODO(auth): open the profile screen.
      onTap: () {},
      child: Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              // A translucent primary rather than a fixed tint: it sits on
              // whichever surface the active theme paints behind it.
              color: colors.primary100,
              shape: BoxShape.circle,
            ),
            child: SizedBox.square(
              dimension: 48,
              child: Center(
                child: Text(
                  account.initials,
                  style: context.appFonts.labelLarge?.copyWith(
                    color: colors.primary500,
                  ),
                ),
              ),
            ),
          ),
          AppSizes.padding12.horizontalSpace,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  account.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.appFonts.labelLarge?.copyWith(
                    color: colors.gray1000,
                  ),
                ),
                AppSizes.padding2.verticalSpace,
                Text(
                  account.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.appFonts.bodySmall?.copyWith(
                    color: colors.gray500,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            size: AppSizes.iconsSize,
            color: colors.gray300,
          ),
        ],
      ),
    );
  }
}

/// Units and appearance.
class _PreferencesSection extends ConsumerWidget {
  const _PreferencesSection({required this.settings});

  final AppSettings settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(settingsProvider.notifier);

    return SettingsSection(
      title: 'Preferences',
      children: [
        Text(
          'Weight units',
          style: context.appFonts.labelLarge?.copyWith(
            color: context.appThemeColors.gray1000,
          ),
        ),
        AppSizes.padding2.verticalSpace,
        Text(
          'How every set is shown. Your log is stored in kilograms either way.',
          style: context.appFonts.bodySmall?.copyWith(
            color: context.appThemeColors.gray500,
          ),
        ),
        AppSizes.padding10.verticalSpace,
        Row(
          spacing: AppSizes.padding8,
          children: [
            for (final unit in WeightUnit.values)
              AppChip(
                title: unit.label,
                isSelected: unit == settings.unit,
                onPressed: () => notifier.unitChanged(unit),
              ),
          ],
        ),
        AppSizes.padding18.verticalSpace,
        const SettingsDivider(),
        AppSizes.padding18.verticalSpace,
        Text(
          'Appearance',
          style: context.appFonts.labelLarge?.copyWith(
            color: context.appThemeColors.gray1000,
          ),
        ),
        AppSizes.padding10.verticalSpace,
        Row(
          spacing: AppSizes.padding8,
          children: [
            for (final choice in ThemeChoice.values)
              AppChip(
                title: choice.label,
                isSelected: choice == settings.theme,
                onPressed: () => notifier.themeChanged(choice),
              ),
          ],
        ),
      ],
    );
  }
}

/// The two notifications the app sends.
class _RemindersSection extends ConsumerWidget {
  const _RemindersSection({required this.settings});

  final AppSettings settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(settingsProvider.notifier);
    final colors = context.appThemeColors;

    return SettingsSection(
      title: 'Reminders',
      padding: EdgeInsets.zero,
      children: [
        SettingsRow(
          title: 'Training reminder',
          subtitle: 'A nudge on the days you usually train.',
          trailing: SettingsSwitch(
            value: settings.trainingReminder,
            semanticLabel: 'Training reminder',
            onChanged: (isOn) => notifier.reminderChanged(isOn: isOn),
          ),
        ),
        // The time only exists as a question once the reminder is on.
        if (settings.trainingReminder)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSizes.defaultPadding,
              0,
              AppSizes.defaultPadding,
              AppSizes.padding12,
            ),
            child: Material(
              color: colors.surface1,
              borderRadius: BorderRadius.circular(AppSizes.mediumButtonRadius),
              child: InkWell(
                borderRadius: BorderRadius.circular(AppSizes.mediumButtonRadius),
                onTap: () => _pickTime(context, notifier),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.padding14,
                    vertical: AppSizes.padding12,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Remind me at',
                          style: context.appFonts.bodyMedium?.copyWith(
                            color: colors.gray800,
                          ),
                        ),
                      ),
                      Text(
                        settings.reminderLabel,
                        style: context.appFonts.labelMedium?.copyWith(
                          color: colors.primary500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        const SettingsDivider(indent: AppSizes.defaultPadding),
        SettingsRow(
          title: 'Weekly summary',
          subtitle: 'Monday morning, your week in numbers.',
          trailing: SettingsSwitch(
            value: settings.weeklySummary,
            semanticLabel: 'Weekly summary',
            onChanged: (isOn) => notifier.weeklySummaryChanged(isOn: isOn),
          ),
        ),
      ],
    );
  }

  Future<void> _pickTime(
    BuildContext context,
    SettingsNotifier notifier,
  ) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: settings.reminderTime,
    );

    if (picked == null) return;
    await notifier.reminderTimeChanged(picked.hour * 60 + picked.minute);
  }
}

/// Signing out, kept away from everything it could be mistaken for.
class _SignOutCard extends StatelessWidget {
  const _SignOutCard({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onPressed,
      padding: const EdgeInsets.all(AppSizes.padding14),
      child: Center(
        child: Text(
          'Sign out',
          style: context.appFonts.labelLarge?.copyWith(
            color: SideColors.error500,
          ),
        ),
      ),
    );
  }
}
