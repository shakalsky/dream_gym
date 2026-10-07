import 'dart:io';

import 'package:dream_gym/core/ids/uuid.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Where a photo is coming from.
///
/// Declared here so that `image_picker` stops at this file: the form notifier
/// and the widgets talk about cameras and libraries, not about plugins, and a
/// test never has to stand one up.
enum PhotoSource {
  camera('Take a photo'),
  gallery('Choose from library');

  const PhotoSource(this.label);

  final String label;
}

/// Where exercise photos live, and the only thing that puts them there.
///
/// Photos are files rather than blobs in the database: an image column would
/// be read into memory by every query that touches the row, and a list of
/// exercises reads every row.
class PhotoStore {
  PhotoStore({required Directory directory, ImagePicker? picker})
    : _directory = directory,
      _picker = picker ?? ImagePicker();

  /// Opens (and creates, on first run) the photo directory.
  static Future<PhotoStore> open() async {
    final documents = await getApplicationDocumentsDirectory();
    final directory = Directory(p.join(documents.path, 'exercise_photos'));

    if (!directory.existsSync()) {
      await directory.create(recursive: true);
    }

    return PhotoStore(directory: directory);
  }

  final Directory _directory;
  final ImagePicker _picker;

  /// The file a stored [fileName] refers to.
  ///
  /// Only file names are persisted, so this is the one place that knows where
  /// the directory currently is — which is what makes the rows survive the
  /// documents directory moving between installs.
  File fileFor(String fileName) => File(p.join(_directory.path, fileName));

  /// Asks the reader for a photo and returns its temporary path, or null if
  /// they backed out.
  ///
  /// Nothing is stored yet: a picked photo that the reader then abandons by
  /// leaving the form should not leave a file behind. [store] is what commits
  /// it.
  Future<String?> pick(PhotoSource source) async {
    final picked = await _picker.pickImage(
      source: switch (source) {
        PhotoSource.camera => ImageSource.camera,
        PhotoSource.gallery => ImageSource.gallery,
      },
      // A photo taken on a modern phone is far larger than the ~200px it is
      // ever drawn at. Downscaling here keeps the directory from growing into
      // tens of megabytes for a handful of exercises.
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );

    return picked?.path;
  }

  /// Copies a picked photo into the store and returns its file name.
  Future<String> store(String temporaryPath) async {
    // A fresh name per stored photo, so replacing an exercise's photo can
    // never be served from Flutter's image cache under the old key.
    final fileName = '${newUuid()}${p.extension(temporaryPath).toLowerCase()}';
    await File(temporaryPath).copy(p.join(_directory.path, fileName));

    return fileName;
  }

  /// Removes a stored photo. Missing files are not an error — the row that
  /// pointed at it is going away either way.
  Future<void> delete(String fileName) async {
    final file = fileFor(fileName);
    if (file.existsSync()) await file.delete();
  }
}
