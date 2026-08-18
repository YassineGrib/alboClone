import 'package:drift/drift.dart';
import 'package:later/data/local/app_database.dart';
import 'package:later/data/services/api_client.dart';
import 'package:later/domain/models/save.dart';
import 'package:uuid/uuid.dart';

class SaveRepository {
  SaveRepository({required this.db, required this.api});

  final AppDatabase db;
  final ApiClient api;
  static const _uuid = Uuid();

  Stream<List<SaveItem>> watchAlive() {
    return (db.select(db.saves)
          ..where((row) => row.deletedAt.isNull())
          ..orderBy([(row) => OrderingTerm.desc(row.createdAt)]))
        .watch()
        .map((rows) => rows.map(_toItem).toList());
  }

  Future<SaveItem> addUrl(String raw, {String? collectionId}) async {
    final url = raw.trim();
    final uri = Uri.tryParse(url);
    if (uri == null ||
        url.isEmpty ||
        !(uri.isScheme('http') || uri.isScheme('https')) ||
        uri.host.isEmpty) {
      throw const FormatException("That isn't a URL.");
    }

    final now = DateTime.now().toUtc();
    final item = SaveItem(
      id: _uuid.v4(),
      url: url,
      title: url,
      collectionId: collectionId,
      contentStatus: ContentStatus.pending,
      syncStatus: SyncStatus.pendingSync,
      createdAt: now,
      updatedAt: now,
    );

    await db.into(db.saves).insert(_toCompanion(item));

    try {
      await api.createSave(
        id: item.id,
        url: item.url,
        title: item.title,
        createdAt: item.createdAt,
        collectionId: item.collectionId,
      );
      final synced = item.copyWith(syncStatus: SyncStatus.synced, clearSyncError: true);
      await _update(synced);
      return synced;
    } on ApiException catch (error) {
      final failed = item.copyWith(
        syncStatus: SyncStatus.syncFailed,
        syncError: error.message,
      );
      await _update(failed);
      return failed;
    }
  }

  Future<void> retry(SaveItem item) async {
    if (item.deletedAt != null) {
      await _pushDelete(item);
      return;
    }
    try {
      await api.createSave(
        id: item.id,
        url: item.url,
        title: item.title,
        createdAt: item.createdAt,
        collectionId: item.collectionId,
      );
      await _update(item.copyWith(syncStatus: SyncStatus.synced, clearSyncError: true));
    } on ApiException catch (error) {
      await _update(item.copyWith(
        syncStatus: SyncStatus.syncFailed,
        syncError: error.message,
      ));
    }
  }

  Future<void> moveToCollection(SaveItem item, String? collectionId) async {
    final next = collectionId == null
        ? item.copyWith(clearCollectionId: true, updatedAt: DateTime.now().toUtc())
        : item.copyWith(collectionId: collectionId, updatedAt: DateTime.now().toUtc());
    await _update(next);

    if (item.syncStatus != SyncStatus.synced) {
      return;
    }

    try {
      await api.patchSave(id: item.id, collectionId: collectionId);
      await _update(next.copyWith(syncStatus: SyncStatus.synced, clearSyncError: true));
    } on ApiException catch (error) {
      await _update(next.copyWith(
        syncStatus: SyncStatus.syncFailed,
        syncError: error.message,
      ));
    }
  }

  Future<void> delete(SaveItem item) async {
    if (item.syncStatus == SyncStatus.pendingSync && item.deletedAt == null) {
      // Never reached the server: drop locally.
      try {
        await api.deleteSave(item.id);
      } on ApiException {
        // still remove local if it never synced
      }
      await (db.delete(db.saves)..where((row) => row.id.equals(item.id))).go();
      return;
    }

    if (item.syncStatus == SyncStatus.pendingSync) {
      await (db.delete(db.saves)..where((row) => row.id.equals(item.id))).go();
      return;
    }

    final tombstone = item.copyWith(deletedAt: DateTime.now().toUtc());
    await _update(tombstone);
    await _pushDelete(tombstone);
  }

  bool _isSyncing = false;

  Future<void> sync() async {
    if (_isSyncing) return;
    _isSyncing = true;
    try {
      final pending = await (db.select(db.saves)
            ..where((row) => row.syncStatus.isNotValue('synced')))
          .get();
      for (final row in pending) {
        await retry(_toItem(row));
      }

      try {
        final remote = await api.listSaves();
        for (final json in remote) {
          final id = json['id'] as String;
          final local = await (db.select(db.saves)..where((row) => row.id.equals(id)))
              .getSingleOrNull();
          if (local != null && local.syncStatus != 'synced') {
            continue;
          }
          final item = SaveItem(
            id: id,
            url: json['url'] as String,
            title: json['title'] as String,
            imageUrl: json['image_url'] as String?,
            collectionId: json['collection_id'] as String?,
            contentStatus: _contentStatus(json['content_status'] as String?),
            syncStatus: SyncStatus.synced,
            createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
                DateTime.now().toUtc(),
          );
          if (local == null) {
            await db.into(db.saves).insert(_toCompanion(item));
          } else if (local.syncStatus == 'synced') {
            await _update(item.copyWith(syncStatus: SyncStatus.synced));
          }
        }
      } on ApiException {
        // Pull is best-effort. Local rows stay.
      }
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _pushDelete(SaveItem item) async {
    try {
      await api.deleteSave(item.id);
      await (db.delete(db.saves)..where((row) => row.id.equals(item.id))).go();
    } on ApiException catch (error) {
      await _update(item.copyWith(
        syncStatus: SyncStatus.syncFailed,
        syncError: error.message,
      ));
    }
  }

  Future<void> _update(SaveItem item) async {
    await (db.update(db.saves)..where((row) => row.id.equals(item.id)))
        .write(_toCompanion(item));
  }

  SaveItem _toItem(Save row) {
    return SaveItem(
      id: row.id,
      url: row.url,
      title: row.title,
      imageUrl: row.imageUrl,
      collectionId: row.collectionId,
      contentStatus: _contentStatus(row.contentStatus),
      syncStatus: switch (row.syncStatus) {
        'synced' => SyncStatus.synced,
        'sync_failed' => SyncStatus.syncFailed,
        _ => SyncStatus.pendingSync,
      },
      syncError: row.syncError,
      deletedAt: row.deletedAt,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  ContentStatus _contentStatus(String? value) {
    return switch (value) {
      'ready' => ContentStatus.ready,
      'failed' => ContentStatus.failed,
      _ => ContentStatus.pending,
    };
  }

  SavesCompanion _toCompanion(SaveItem item) {
    return SavesCompanion.insert(
      id: item.id,
      url: item.url,
      title: item.title,
      imageUrl: Value(item.imageUrl),
      collectionId: Value(item.collectionId),
      contentStatus: Value(switch (item.contentStatus) {
        ContentStatus.ready => 'ready',
        ContentStatus.failed => 'failed',
        ContentStatus.pending => 'pending',
      }),
      syncStatus: switch (item.syncStatus) {
        SyncStatus.synced => 'synced',
        SyncStatus.syncFailed => 'sync_failed',
        SyncStatus.pendingSync => 'pending_sync',
      },
      syncError: Value(item.syncError),
      deletedAt: Value(item.deletedAt),
      createdAt: item.createdAt,
      updatedAt: Value(item.updatedAt),
    );
  }
}
