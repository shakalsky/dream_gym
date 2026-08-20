import 'package:dream_gym/core/format/training_format.dart';
import 'package:dream_gym/core/ui/app_card.dart';
import 'package:dream_gym/features/exercises/widgets/exercise_photo.dart';
import 'package:dream_gym/features/training/domain/exercise_log.dart';
import 'package:my_calm_ui_package/my_calm_ui_package.dart';

/// One row of the exercises list.
///
/// The subtitle is the last thing logged rather than the date the exercise was
/// created: 'what did I do last time' is the question the reader opens the app
/// with.
class ExerciseTile extends StatelessWidget {
  const ExerciseTile({
    required this.log,
    required this.today,
    required this.onTap,
    super.key,
  });

  final ExerciseLog log;
  final DateTime today;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appThemeColors;
    final latest = log.latest;

    return AppCard(
      padding: const EdgeInsets.all(AppSizes.padding12),
      onTap: onTap,
      child: Row(
        children: [
          ExercisePhoto(photoFileName: log.exercise.photoFileName),
          AppSizes.padding12.horizontalSpace,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  log.exercise.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.appFonts.labelLarge?.copyWith(
                    color: colors.gray1000,
                  ),
                ),
                AppSizes.padding4.verticalSpace,
                Text(
                  latest == null
                      ? 'Not trained yet'
                      : '${formatSetsByWeight(latest.sets, latest.heaviestWeightKg)}'
                            ' · ${formatDay(latest.day, today: today)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.appFonts.bodySmall?.copyWith(
                    color: latest == null ? colors.gray400 : colors.gray500,
                  ),
                ),
              ],
            ),
          ),
          AppSizes.padding8.horizontalSpace,
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
