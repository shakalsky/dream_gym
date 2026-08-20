import 'package:dream_gym/core/database/app_database.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite_async/sqlite_async.dart';

/// Opens the local database the running flavour is configured for.
///
/// The file lives in the documents directory rather than a cache one: these
/// rows are the reader's own training log, and the system is not free to
/// reclaim them.
Future<AppDatabase> openDatabase(String databaseName) async {
  final directory = await getApplicationDocumentsDirectory();
  final connection = SqliteDatabase(
    path: p.join(directory.path, databaseName),
  );

  // Surfaces an open failure here rather than on the first query, where it
  // would arrive as a failed stream in whichever screen happened to be built.
  await connection.initialize();

  return AppDatabase(connection);
}
