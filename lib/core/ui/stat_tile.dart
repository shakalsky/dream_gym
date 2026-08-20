import 'package:my_calm_ui_package/my_calm_ui_package.dart';

/// One number with a name under it.
///
/// The label goes below the value, not above: the number is what the eye is
/// looking for, and it should be the first thing it lands on.
class StatTile extends StatelessWidget {
  const StatTile({
    required this.value,
    required this.label,
    this.caption,
    this.captionColor,
    super.key,
  });

  final String value;
  final String label;

  /// An optional third line — a date, or a comparison with last week.
  final String? caption;
  final Color? captionColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.appThemeColors;
    final caption = this.caption;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.appFonts.titleLarge?.copyWith(color: colors.gray1000),
        ),
        AppSizes.padding2.verticalSpace,
        Text(
          label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: context.appFonts.bodySmall?.copyWith(color: colors.gray500),
        ),
        if (caption != null) ...[
          AppSizes.padding4.verticalSpace,
          Text(
            caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.appFonts.labelSmall?.copyWith(
              color: captionColor ?? colors.gray400,
            ),
          ),
        ],
      ],
    );
  }
}
