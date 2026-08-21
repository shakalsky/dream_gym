import 'package:equatable/equatable.dart';

/// The signed-in reader, as the settings screen needs them.
///
/// Deliberately not Supabase's `User`: auth is not wired yet, and when it is,
/// only this mapping should have to change.
// TODO(auth): build this from Supabase's session and watch
// `onAuthStateChange` instead of passing it in.
final class Account extends Equatable {
  const Account({required this.name, required this.email});

  final String name;
  final String email;

  /// One or two letters for the avatar — a photo is a later problem.
  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return email.isEmpty ? '?' : email[0].toUpperCase();

    return parts
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();
  }

  @override
  List<Object?> get props => [name, email];
}

/// How far along the sync is.
///
/// A value object with a stub source: PowerSync is a dependency but nothing
/// subscribes to it yet.
// TODO(sync): feed this from PowerSync's `statusStream`.
final class SyncStatus extends Equatable {
  const SyncStatus({
    required this.isConnected,
    this.lastSyncedAt,
    this.queuedSessions = 0,
    this.isSyncing = false,
  });

  /// What a local-only build reports: nothing to sync to, nothing pending.
  const SyncStatus.offline()
    : isConnected = false,
      lastSyncedAt = null,
      queuedSessions = 0,
      isSyncing = false;

  final bool isConnected;
  final DateTime? lastSyncedAt;
  final int queuedSessions;
  final bool isSyncing;

  @override
  List<Object?> get props => [
    isConnected,
    lastSyncedAt,
    queuedSessions,
    isSyncing,
  ];
}
