import 'package:my_calm_ui_package/my_calm_ui_package.dart';

/// The surface everything on a screen sits on.
///
/// One place decides the radius, the border and the padding, so a list of
/// exercises and a statistics panel look like the same app.
class AppCard extends StatelessWidget {
  const AppCard({
    required this.child,
    this.padding = const EdgeInsets.all(AppSizes.defaultPadding),
    this.onTap,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appThemeColors;
    final radius = BorderRadius.circular(AppSizes.borderRadius16);

    return Material(
      color: colors.surface,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: colors.gray100),
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
