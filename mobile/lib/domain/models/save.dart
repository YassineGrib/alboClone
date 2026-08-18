enum SyncStatus { pendingSync, synced, syncFailed }

enum ContentStatus { pending, ready, failed }

class SaveItem {
  const SaveItem({
    required this.id,
    required this.url,
    required this.title,
    required this.contentStatus,
    required this.syncStatus,
    required this.createdAt,
    this.imageUrl,
    this.collectionId,
    this.syncError,
    this.deletedAt,
    this.updatedAt,
  });

  final String id;
  final String url;
  final String title;
  final String? imageUrl;
  final String? collectionId;
  final ContentStatus contentStatus;
  final SyncStatus syncStatus;
  final String? syncError;
  final DateTime? deletedAt;
  final DateTime createdAt;
  final DateTime? updatedAt;

  bool get isAlive => deletedAt == null;

  SaveItem copyWith({
    String? title,
    String? imageUrl,
    String? collectionId,
    ContentStatus? contentStatus,
    SyncStatus? syncStatus,
    String? syncError,
    DateTime? deletedAt,
    DateTime? updatedAt,
    bool clearSyncError = false,
    bool clearImageUrl = false,
    bool clearCollectionId = false,
  }) {
    return SaveItem(
      id: id,
      url: url,
      title: title ?? this.title,
      imageUrl: clearImageUrl ? null : (imageUrl ?? this.imageUrl),
      collectionId: clearCollectionId ? null : (collectionId ?? this.collectionId),
      contentStatus: contentStatus ?? this.contentStatus,
      syncStatus: syncStatus ?? this.syncStatus,
      syncError: clearSyncError ? null : (syncError ?? this.syncError),
      deletedAt: deletedAt ?? this.deletedAt,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
