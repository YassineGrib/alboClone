import 'package:drift/drift.dart';
import 'package:later/data/local/app_database.dart';
import 'package:later/data/services/api_client.dart';
import 'package:later/domain/models/collection.dart';
import 'package:later/domain/models/save.dart';
import 'package:uuid/uuid.dart';

class CollectionRepository {
  CollectionRepository({required this.db, required this.api});

  final AppDatabase db;
  final ApiClient api;
  static const _uuid = Uuid();

  Stream<List<CollectionItem>> watchAlive() {
    return (db.select(db.collections)
          ..where((row) => row.syncStatus.isNotValue('pending_delete'))
          ..orderBy([(row) => OrderingTerm.asc(row.name)]))
        .watch()
        .map((rows) => rows.map(_toItem).toList());
  }

  Future<CollectionItem> create(String rawName) async {
    final name = rawName.trim();
    if (name.isEmpty) {
      throw const FormatException('Name a folder.');
    }

    final now = DateTime.now().toUtc();
    final item = CollectionItem(
      id: _uuid.v4(),
      name: name,
      syncStatus: SyncStatus.pendingSync,
      createdAt: now,
      updatedAt: now,
    );
    await db.into(db.collections).insert(_toCompanion(item));

    try {
      await api.createCollection(id: item.id, name: item.name);
      final synced = item.copyWith(syncStatus: SyncStatus.synced);
      await _update(synced);
      return synced;
    } on ApiException {
      final failed = item.copyWith(syncStatus: SyncStatus.syncFailed);
      await _update(failed);
      return failed;
    }
  }

  Future<void> rename(CollectionItem item, String rawName) async {
    final name = rawName.trim();
    if (name.isEmpty) {
      throw const FormatException('Name a folder.');
    }

    final next = item.copyWith(name: name, updatedAt: DateTime.now().toUtc());
    await _update(next);

    try {
      await api.renameCollection(id: item.id, name: name);
      await _update(next.copyWith(syncStatus: SyncStatus.synced));
    } on ApiException {
      await _update(next.copyWith(syncStatus: SyncStatus.syncFailed));
    }
  }

  Future<void> delete(CollectionItem item) async {
    await (db.update(db.saves)..where((row) => row.collectionId.equals(item.id)))
        .write(const SavesCompanion(collectionId: Value(null)));

    if (item.syncStatus == SyncStatus.pendingSync) {
      await (db.delete(db.collections)..where((row) => row.id.equals(item.id))).go();
      return;
    }

    await (db.update(db.collections)..where((row) => row.id.equals(item.id)))
        .write(const CollectionsCompanion(syncStatus: Value('pending_delete')));

    try {
      await api.deleteCollection(item.id);
      await (db.delete(db.collections)..where((row) => row.id.equals(item.id))).go();
    } on ApiException {
      // Hidden locally as pending_delete until a later sync.
    }
  }

  bool _isSyncing = false;

  Future<void> sync() async {
    if (_isSyncing) return;
    _isSyncing = true;
    try {
      final pending = await (db.select(db.collections)
            ..where((row) => row.syncStatus.isNotValue('synced')))
          .get();

      for (final row in pending) {
        if (row.syncStatus == 'pending_delete') {
          try {
            await api.deleteCollection(row.id);
            await (db.delete(db.collections)..where((tbl) => tbl.id.equals(row.id))).go();
          } on ApiException {
            // Keep the tombstone.
          }
          continue;
        }

        try {
          await api.createCollection(id: row.id, name: row.name);
          await (db.update(db.collections)..where((tbl) => tbl.id.equals(row.id)))
              .write(const CollectionsCompanion(syncStatus: Value('synced')));
        } on ApiException {
          await (db.update(db.collections)..where((tbl) => tbl.id.equals(row.id)))
              .write(const CollectionsCompanion(syncStatus: Value('sync_failed')));
        }
      }

      try {
        final remote = await api.listCollections();
        final pendingDelete = await (db.select(db.collections)
              ..where((row) => row.syncStatus.equals('pending_delete')))
            .get();
        final skip = pendingDelete.map((row) => row.id).toSet();

        for (final json in remote) {
          final id = json['id'] as String;
          if (skip.contains(id)) {
            continue;
          }
          final local = await (db.select(db.collections)..where((row) => row.id.equals(id)))
              .getSingleOrNull();
          if (local != null && local.syncStatus != 'synced') {
            continue;
          }
          final item = CollectionItem(
            id: id,
            name: json['name'] as String,
            syncStatus: SyncStatus.synced,
            createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
                DateTime.now().toUtc(),
          );
          if (local == null) {
            await db.into(db.collections).insert(_toCompanion(item));
          } else {
            await _update(item);
          }
        }
      } on ApiException {
        // Pull is best-effort.
      }
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _update(CollectionItem item) async {
    await (db.update(db.collections)..where((row) => row.id.equals(item.id)))
        .write(_toCompanion(item));
  }

  CollectionItem _toItem(Collection row) {
    return CollectionItem(
      id: row.id,
      name: row.name,
      syncStatus: switch (row.syncStatus) {
        'synced' => SyncStatus.synced,
        'sync_failed' => SyncStatus.syncFailed,
        _ => SyncStatus.pendingSync,
      },
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  CollectionsCompanion _toCompanion(CollectionItem item) {
    return CollectionsCompanion.insert(
      id: item.id,
      name: item.name,
      syncStatus: switch (item.syncStatus) {
        SyncStatus.synced => 'synced',
        SyncStatus.syncFailed => 'sync_failed',
        SyncStatus.pendingSync => 'pending_sync',
      },
      createdAt: item.createdAt,
      updatedAt: Value(item.updatedAt),
    );
  }
}
