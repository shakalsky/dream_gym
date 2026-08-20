import 'package:dream_gym/core/format/training_format.dart';
import 'package:dream_gym/core/ui/app_card.dart';
import 'package:dream_gym/core/ui/icon_action.dart';
import 'package:dream_gym/features/training/domain/exercise_progress.dart';
import 'package:my_calm_ui_package/my_calm_ui_package.dart';

/// One training day of one exercise, with everything logged that day.
class SessionCard extends StatelessWidget {
  const SessionCard({
    required this.session,
    required this.today,
    required this.onDeleteEntry,
    this.isPersonalBest = false,
    super.key,
  });

  final TrainingSession session;
  final DateTime today;

  /// Called with the id of the entry to remove.
  final ValueChanged<String> onDeleteEntry;

  /// Whether this is the day the top weight was set.
  final bool isPersonalBest;

  @override
  Widget build(BuildContext context) {
    final colors = context.appThemeColors;

    return AppCard(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.defaultPadding,
        AppSizes.padding12,
        AppSizes.padding8,
        AppSizes.padding12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: AppSizes.padding8),
            child: Row(
              children: [
                Text(
                  formatDay(session.day, today: today),
                  style: context.appFonts.labelLarge?.copyWith(
                    color: colors.gray1000,
                  ),
                ),
                if (isPersonalBest) ...[
                  AppSizes.padding8.horizontalSpace,
                  const AppBadge(
                    label: 'Best',
                    style: BadgeStyle.lite,
                    font: BadgeFont.small,
                  ),
                ],
                const Spacer(),
                Text(
                  '${formatWeight(session.volumeKg)} total',
                  style: context.appFonts.bodySmall?.copyWith(
                    color: colors.gray500,
                  ),
                ),
              ],
            ),
          ),
          for (final entry in session.entries)
            Row(
              children: [
                Expanded(
                  child: Text(
                    formatSetsByWeight(entry.sets, entry.weightKg),
                    style: context.appFonts.bodyLarge?.copyWith(
                      color: colors.gray800,
                    ),
                  ),
                ),
                IconAction(
                  icon: Icons.delete_outline,
                  tooltip: 'Delete this result',
                  color: colors.gray400,
                  onPressed: () => onDeleteEntry(entry.id),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
