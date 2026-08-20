import 'dart:io';

import 'package:dream_gym/core/storage/photo_store.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_calm_ui_package/my_calm_ui_package.dart';

/// An exercise's photo, or a placeholder where one would be.
///
/// Resolves the stored file name through the [PhotoStore] provided above it, so
/// no screen has to know where the photo directory currently is.
class ExercisePhoto extends StatelessWidget {
  const ExercisePhoto({
    required this.photoFileName,
    this.width = AppSizes.imageSize,
    this.height = AppSizes.imageSize,
    this.borderRadius = AppSizes.imageRadius,
    super.key,
  }) : file = null;

  /// A photo the reader has just picked and not yet saved — shown from its
  /// temporary path, since it is not in the store yet.
  const ExercisePhoto.file(
    this.file, {
    this.width = AppSizes.imageSize,
    this.height = AppSizes.imageSize,
    this.borderRadius = AppSizes.imageRadius,
    super.key,
  }) : photoFileName = null;

  final String? photoFileName;
  final File? file;
  final double width;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final colors = context.appThemeColors;
    final fileName = photoFileName;
    final image =
        file ??
        (fileName == null ? null : context.read<PhotoStore>().fileFor(fileName));

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        width: width,
        height: height,
        child: image == null
            ? _Placeholder(size: width, color: colors.gray300)
            : Image.file(
                image,
                fit: BoxFit.cover,
                // A file can go missing — a restored backup that brought the
                // database but not the photos, say — and a broken image is not
                // a reason to fail the whole list.
                errorBuilder: (context, error, stackTrace) =>
                    _Placeholder(size: width, color: colors.gray300),
              ),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: context.appThemeColors.surface2,
      child: Center(
        child: Icon(
          Icons.fitness_center,
          size: (size * 0.45).clamp(AppSizes.iconsSize16, AppSizes.padding45),
          color: color,
        ),
      ),
    );
  }
}
