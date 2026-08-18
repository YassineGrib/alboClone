import 'package:later/domain/models/save.dart';
import 'package:later/domain/save_timeline.dart';
import 'package:later/domain/source_app.dart';

enum CollectionScopeKind { all, unfiled, one }

class CollectionScope {
  const CollectionScope.all()
      : kind = CollectionScopeKind.all,
        id = null;

  const CollectionScope.unfiled()
      : kind = CollectionScopeKind.unfiled,
        id = null;

  const CollectionScope.one(String this.id) : kind = CollectionScopeKind.one;

  final CollectionScopeKind kind;
  final String? id;

  @override
  bool operator ==(Object other) {
    return other is CollectionScope && other.kind == kind && other.id == id;
  }

  @override
  int get hashCode => Object.hash(kind, id);
}

enum SaveWhen { any, today, yesterday, last7, last30 }

class SaveFilter {
  const SaveFilter({
    this.query = '',
    this.collection = const CollectionScope.all(),
    this.status,
    this.when = SaveWhen.any,
    this.appId,
    this.category,
  });

  final String query;
  final CollectionScope collection;
  final ContentStatus? status;
  final SaveWhen when;
  final String? appId;
  final String? category;

  bool get isConstrained {
    return collection != const CollectionScope.all() ||
        status != null ||
        when != SaveWhen.any ||
        appId != null ||
        category != null;
  }

  SaveFilter copyWith({
    String? query,
    CollectionScope? collection,
    ContentStatus? status,
    SaveWhen? when,
    String? appId,
    String? category,
    bool clearStatus = false,
    bool clearApp = false,
    bool clearCategory = false,
  }) {
    return SaveFilter(
      query: query ?? this.query,
      collection: collection ?? this.collection,
      status: clearStatus ? null : (status ?? this.status),
      when: when ?? this.when,
      appId: clearApp ? null : (appId ?? this.appId),
      category: clearCategory ? null : (category ?? this.category),
    );
  }

  SaveFilter clearAdvanced() {
    return SaveFilter(query: query);
  }
}

class SaveQuery {
  static List<SaveItem> apply({
    required List<SaveItem> saves,
    required SaveFilter filter,
    DateTime? now,
  }) {
    final needle = filter.query.trim().toLowerCase();
    final clock = now ?? DateTime.now();
    final today = SaveTimeline.dayOf(clock);
    final yesterday = today.subtract(const Duration(days: 1));

    return saves.where((item) {
      if (needle.isNotEmpty) {
        final haystack = '${item.title} ${item.url}'.toLowerCase();
        if (!haystack.contains(needle)) {
          return false;
        }
      }

      if (filter.status != null && item.contentStatus != filter.status) {
        return false;
      }

      if (filter.appId != null && SourceApp.idFor(item.url) != filter.appId) {
        return false;
      }

      if (filter.category != null && (item.category?.toLowerCase() != filter.category!.toLowerCase())) {
        return false;
      }

      final day = SaveTimeline.dayOf(item.createdAt);
      final inWhen = switch (filter.when) {
        SaveWhen.any => true,
        SaveWhen.today => day == today,
        SaveWhen.yesterday => day == yesterday,
        SaveWhen.last7 => !day.isBefore(today.subtract(const Duration(days: 6))),
        SaveWhen.last30 => !day.isBefore(today.subtract(const Duration(days: 29))),
      };
      if (!inWhen) {
        return false;
      }

      switch (filter.collection.kind) {
        case CollectionScopeKind.all:
          return true;
        case CollectionScopeKind.unfiled:
          return item.collectionId == null;
        case CollectionScopeKind.one:
          return item.collectionId == filter.collection.id;
      }
    }).toList();
  }
}
