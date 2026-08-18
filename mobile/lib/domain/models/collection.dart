import 'package:later/domain/models/save.dart';

class CollectionItem {
  const CollectionItem({
    required this.id,
    required this.name,
    required this.syncStatus,
    required this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final SyncStatus syncStatus;
  final DateTime createdAt;
  final DateTime? updatedAt;

  CollectionItem copyWith({
    String? name,
    SyncStatus? syncStatus,
    DateTime? updatedAt,
  }) {
    return CollectionItem(
      id: id,
      name: name ?? this.name,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
