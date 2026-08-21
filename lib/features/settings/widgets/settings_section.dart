import 'package:dream_gym/core/ui/app_card.dart';
import 'package:my_calm_ui_package/my_calm_ui_package.dart';

/// A labelled group of settings.
///
/// The label sits outside the card rather than inside it: it names the group,
/// and a heading inside the surface would compete with the rows' own titles.
class SettingsSection extends StatelessWidget {
  const SettingsSection({
    required this.title,
    required this.children,
    this.padding,
    super.key,
  });

  final String title;
  final List<Widget> children;

  /// Overridden by row-based sections, which pad each row instead so that a
  /// tap highlight reaches the card's edges.
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final colors = context.appThemeColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: AppSizes.padding4),
          child: Text(
            title.toUpperCase(),
            style: context.appFonts.labelSmall?.copyWith(
              color: colors.gray400,
              letterSpacing: 0.6,
            ),
          ),
        ),
        AppSizes.padding8.verticalSpace,
        AppCard(
          padding: padding ?? const EdgeInsets.all(AppSizes.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    );
  }
}

/// The hairline between two rows of a section.
class SettingsDivider extends StatelessWidget {
  const SettingsDivider({this.indent = 0, super.key});

  /// Set to the row's horizontal padding so the line starts under the text.
  final double indent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: indent),
      child: ColoredBox(
        color: context.appThemeColors.gray100,
        child: const SizedBox(height: 1, width: double.infinity),
      ),
    );
  }
}
