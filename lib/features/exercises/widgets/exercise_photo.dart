import 'dart:io';

import 'package:dream_gym/core/providers.dart';
import 'package:dream_gym/features/exercises/domain/exercise_icon.dart';
import 'package:dream_gym/features/exercises/widgets/exercise_icon_data.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_calm_ui_package/my_calm_ui_package.dart';

/// An exercise's photo, or its [icon] where there is none.
///
/// Resolves the stored file name through [photoStoreProvider], so no screen
/// has to know where the photo directory currently is.
class ExercisePhoto extends ConsumerWidget {
  const ExercisePhoto({
    required this.photoFileName,
    this.icon = ExerciseIcon.fallback,
    this.iconColor,
    this.width = AppSizes.imageSize,
    this.height = AppSizes.imageSize,
    this.borderRadius = AppSizes.imageRadius,
    super.key,
  }) : file = null;

  /// A photo the reader has just picked and not yet saved — shown from its
  /// temporary path, since it is not in the store yet.
  const ExercisePhoto.file(
    this.file, {
    this.icon = ExerciseIcon.fallback,
    this.iconColor,
    this.width = AppSizes.imageSize,
    this.height = AppSizes.imageSize,
    this.borderRadius = AppSizes.imageRadius,
    super.key,
  }) : photoFileName = null;

  final String? photoFileName;
  final File? file;
  final ExerciseIcon icon;

  /// The placeholder icon's color. Defaults to a muted gray.
  final Color? iconColor;

  final double width;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final placeholderColor = iconColor ?? context.appThemeColors.gray300;
    final fileName = photoFileName;
    final image =
        file ??
        (fileName == null
            ? null
            : ref.watch(photoStoreProvider).fileFor(fileName));

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        width: width,
        height: height,
        child: image == null
            ? _Placeholder(icon: icon, size: width, color: placeholderColor)
            : Image.file(
                image,
                fit: BoxFit.cover,
                // A file can go missing — a restored backup that brought the
                // database but not the photos, say — and a broken image is not
                // a reason to fail the whole list.
                errorBuilder: (context, error, stackTrace) => _Placeholder(
                  icon: icon,
                  size: width,
                  color: placeholderColor,
                ),
              ),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({
    required this.icon,
    required this.size,
    required this.color,
  });

  final ExerciseIcon icon;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: context.appThemeColors.surface2,
      child: Center(
        child: Icon(
          icon.data,
          semanticLabel: icon.label,
          size: (size * 0.45).clamp(AppSizes.iconsSize16, AppSizes.padding45),
          color: color,
        ),
      ),
    );
  }
}
