import 'package:my_calm_ui_package/my_calm_ui_package.dart';

/// What a screen shows before there is anything on it.
///
/// Always says what to do next, not just that something is missing — a first
/// run is the one moment where the app has to explain itself.
class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
    super.key,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final colors = context.appThemeColors;
    final action = this.action;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.padding32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: colors.surface2,
                shape: BoxShape.circle,
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.padding18),
                child: Icon(
                  icon,
                  size: AppSizes.bigIconsSize,
                  color: colors.gray400,
                ),
              ),
            ),
            AppSizes.padding20.verticalSpace,
            Text(
              title,
              textAlign: TextAlign.center,
              style: context.appFonts.titleMedium?.copyWith(
                color: colors.gray1000,
              ),
            ),
            AppSizes.padding8.verticalSpace,
            Text(
              message,
              textAlign: TextAlign.center,
              style: context.appFonts.bodyMedium?.copyWith(
                color: colors.gray500,
              ),
            ),
            if (action != null) ...[
              AppSizes.padding24.verticalSpace,
              action,
            ],
          ],
        ),
      ),
    );
  }
}
