import 'package:equatable/equatable.dart';

/// The photo an open exercise form will save.
///
/// Three states rather than a nullable string, because 'no photo' and 'a photo
/// picked but not yet copied into the store' are different things, and saving
/// has to tell them apart.
sealed class PhotoSelection extends Equatable {
  const PhotoSelection();

  @override
  List<Object?> get props => const [];
}

/// The exercise has no photo.
final class NoPhoto extends PhotoSelection {
  const NoPhoto();
}

/// A photo that is already in the store, unchanged by this form.
final class StoredPhoto extends PhotoSelection {
  const StoredPhoto(this.fileName);

  final String fileName;

  @override
  List<Object?> get props => [fileName];
}

/// A photo the reader just picked, still in the picker's temporary directory.
final class PickedPhoto extends PhotoSelection {
  const PickedPhoto(this.path);

  final String path;

  @override
  List<Object?> get props => [path];
}
