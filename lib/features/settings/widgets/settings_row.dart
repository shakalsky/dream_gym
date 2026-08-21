import 'package:my_calm_ui_package/my_calm_ui_package.dart';

/// One line of a settings card: a title, an optional explanation, and one
/// control or value on the right.
///
/// The subtitle is for what the setting *does*, not what it is called — a
/// switch labelled 'Weekly summary' still has to say when it arrives.
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    required this.title,
    this.subtitle,
    this.trailing,
    this.value,
    this.onTap,
    this.padding = const EdgeInsets.symmetric(
      horizontal: AppSizes.defaultPadding,
      vertical: AppSizes.padding14,
    ),
    super.key,
  });

  final String title;
  final String? subtitle;

  /// A switch, or anything else interactive. Takes precedence over [value].
  final Widget? trailing;

  /// A read-only right-hand value, like a version number.
  final String? value;

  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final colors = context.appThemeColors;
    final subtitle = this.subtitle;
    final value = this.value;

    final content = Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: context.appFonts.labelLarge?.copyWith(
                    color: colors.gray1000,
                  ),
                ),
                if (subtitle != null) ...[
                  AppSizes.padding2.verticalSpace,
                  Text(
                    subtitle,
                    style: context.appFonts.bodySmall?.copyWith(
                      color: colors.gray500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          AppSizes.padding12.horizontalSpace,
          if (trailing != null)
            trailing!
          else if (value != null)
            Text(
              value,
              style: context.appFonts.bodyMedium?.copyWith(
                color: colors.gray500,
              ),
            ),
          if (onTap != null && trailing == null) ...[
            AppSizes.padding4.horizontalSpace,
            Icon(
              Icons.chevron_right,
              size: AppSizes.iconsSize,
              color: colors.gray300,
            ),
          ],
        ],
      ),
    );

    if (onTap == null) return content;

    return InkWell(onTap: onTap, child: content);
  }
}

/// The switch used across the screen.
///
/// Wraps the design system's [AppToggle], which the row cannot label on its
/// own: `AppToggle` takes a value and a callback, and a screen reader landing
/// on a bare switch would hear neither the setting's name nor its subtitle.
class SettingsSwitch extends StatelessWidget {
  const SettingsSwitch({
    required this.value,
    required this.onChanged,
    required this.semanticLabel,
    super.key,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      child: AppToggle(value: value, onChanged: onChanged),
    );
  }
}
