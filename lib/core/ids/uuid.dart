import 'dart:math';

final _random = Random.secure();

/// Generates a random (version 4) UUID.
///
/// Hand-rolled rather than pulled from a package: it is fifteen lines, and the
/// format matters — PowerSync expects UUID primary keys, so ids minted offline
/// today stay valid when sync is turned on.
String newUuid() {
  final bytes = List<int>.generate(16, (_) => _random.nextInt(256));

  // Version 4, variant 1 — the two fields that make this a random UUID rather
  // than an arbitrary 128-bit number.
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;

  final hex = bytes
      .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
      .join();

  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
      '${hex.substring(20)}';
}
