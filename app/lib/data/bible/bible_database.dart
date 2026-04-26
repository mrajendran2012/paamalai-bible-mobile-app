import 'dart:io';

import 'package:drift/drift.dart' show QueryExecutor, QueryExecutorUser;
import 'package:drift/native.dart' show NativeDatabase;
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Thin read-only wrapper around one bundled Bible SQLite (e.g. `web.sqlite`).
///
/// On first open we copy the asset into the app's documents directory because
/// `package:sqlite3` cannot mmap from inside an APK/IPA bundle. On subsequent
/// launches we re-use the copy unless the bundled asset's byte length differs,
/// which signals a translation update.
class BibleDatabase {
  BibleDatabase._(this._executor);

  final QueryExecutor _executor;

  static final Map<String, BibleDatabase> _cache = {};

  /// Returns `null` if the asset is missing (e.g. Tamil bundle not yet built,
  /// or running on the web platform). Callers handle absence gracefully.
  static Future<BibleDatabase?> openFromAsset(String assetPath) async {
    final cached = _cache[assetPath];
    if (cached != null) return cached;

    try {
      final dir = await getApplicationDocumentsDirectory();
      final dst = File(p.join(dir.path, p.basename(assetPath)));

      final asset = await rootBundle.load(assetPath);
      final bytes = asset.buffer.asUint8List(
        asset.offsetInBytes,
        asset.lengthInBytes,
      );
      if (!dst.existsSync() || dst.lengthSync() != bytes.length) {
        await dst.writeAsBytes(bytes, flush: true);
      }

      final executor = NativeDatabase(dst);
      await executor.ensureOpen(_BareUser());

      final db = BibleDatabase._(executor);
      _cache[assetPath] = db;
      return db;
    } catch (_) {
      return null;
    }
  }

  Future<List<Map<String, Object?>>> select(
    String sql, [
    List<Object?> args = const [],
  ]) =>
      _executor.runSelect(sql, args);

  Future<void> close() async {
    await _executor.close();
    _cache.removeWhere((_, v) => identical(v, this));
  }
}

/// Drift wants a [QueryExecutorUser] to open lazily. We only need the no-op
/// default — there's no schema to migrate; the bundled SQLite is authoritative.
class _BareUser implements QueryExecutorUser {
  @override
  int get schemaVersion => 1;

  @override
  Future<void> beforeOpen(_, __) async {}
}
