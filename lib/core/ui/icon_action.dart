import 'package:my_calm_ui_package/my_calm_ui_package.dart';

/// A tappable icon for an app bar.
///
/// The design system ships a back button and a close button but no general
/// action, and an app bar of 40x40 slots wants one that fits them.
class IconAction extends StatelessWidget {
  const IconAction({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.color,
    super.key,
  });

  final IconData icon;
  final VoidCallback? onPressed;

  /// Also the semantics label — an icon on its own says nothing to a screen
  /// reader.
  final String tooltip;

  final Color? color;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      icon: Icon(icon),
      iconSize: AppSizes.iconsSize,
      color: color ?? context.appThemeColors.gray900,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints.tightFor(width: 40, height: 40),
      padding: EdgeInsets.zero,
    );
  }
}
