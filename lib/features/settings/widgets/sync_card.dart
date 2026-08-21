import 'package:dream_gym/core/format/training_format.dart';
import 'package:dream_gym/core/ui/app_card.dart';
import 'package:dream_gym/features/settings/domain/account.dart';
import 'package:my_calm_ui_package/my_calm_ui_package.dart';

/// Whether the reader's training is safely off this phone.
///
/// States the consequence rather than the mechanism: 'saved on this phone and
/// will upload' is what someone offline in a gym basement needs to read, not a
/// connection state.
class SyncCard extends StatelessWidget {
  const SyncCard({required this.status, required this.onSyncNow, super.key});

  final SyncStatus status;
  final VoidCallback? onSyncNow;

  @override
  Widget build(BuildContext context) {
    final colors = context.appThemeColors;
    final isOffline = !status.isConnected;
    final lastSyncedAt = status.lastSyncedAt;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: AppSizes.padding6),
                // The theme extension carries no semantic colours, so these
                // come from the palette directly — both read on either theme's
                // surface.
                child: _Dot(
                  color: isOffline
                      ? SideColors.warning500
                      : SideColors.success500,
                ),
              ),
              AppSizes.padding10.horizontalSpace,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      switch ((isOffline, status.isSyncing)) {
                        (true, _) => 'Waiting for a connection',
                        (false, true) => 'Syncing…',
                        (false, false) => 'Everything is synced',
                      },
                      style: context.appFonts.labelLarge?.copyWith(
                        color: colors.gray1000,
                      ),
                    ),
                    AppSizes.padding2.verticalSpace,
                    Text(
                      isOffline
                          ? 'Your sessions are saved on this phone and will '
                                'upload the next time you are online.'
                          : lastSyncedAt == null
                          ? 'Not synced yet.'
                          : 'Last synced '
                                '${formatDay(lastSyncedAt, today: DateTime.now())
                                    .toLowerCase()}.',
                      style: context.appFonts.bodySmall?.copyWith(
                        color: colors.gray500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          AppSizes.padding14.verticalSpace,
          ColoredBox(
            color: colors.gray100,
            child: const SizedBox(height: 1, width: double.infinity),
          ),
          AppSizes.padding6.verticalSpace,
          Row(
            children: [
              Expanded(
                child: Text(
                  status.queuedSessions == 0
                      ? 'Nothing waiting'
                      : '${status.queuedSessions} '
                            '${status.queuedSessions == 1 ? 'session' : 'sessions'} '
                            'queued',
                  style: context.appFonts.bodySmall?.copyWith(
                    color: colors.gray400,
                  ),
                ),
              ),
              AppLiteButton.small(text: 'Sync now', onPressed: onSyncNow),
            ],
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: const SizedBox.square(dimension: 8),
    );
  }
}
