import 'package:equatable/equatable.dart';

/// One movement the reader trains.
final class Exercise extends Equatable {
  const Exercise({
    required this.id,
    required this.name,
    required this.createdAt,
    this.photoFileName,
  });

  final String id;
  final String name;

  /// Name of the file in the photo store, or null when the reader did not add
  /// one. A photo is optional on purpose — it should never stand between the
  /// reader and writing down a set.
  final String? photoFileName;

  final DateTime createdAt;

  @override
  List<Object?> get props => [id, name, photoFileName, createdAt];
}
