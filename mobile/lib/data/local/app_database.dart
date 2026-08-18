import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

class Saves extends Table {
  TextColumn get id => text()();
  TextColumn get url => text()();
  TextColumn get title => text()();
  TextColumn get imageUrl => text().nullable()();
  TextColumn get aiSummary => text().nullable()();
  TextColumn get category => text().nullable()();
  IntColumn get priority => integer().withDefault(const Constant(0))();
  TextColumn get aiTags => text().nullable()();
  TextColumn get collectionId => text().nullable()();
  TextColumn get contentStatus => text().withDefault(const Constant('pending'))();
  TextColumn get syncStatus => text()();
  TextColumn get syncError => text().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Collections extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get syncStatus => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DriftDatabase(tables: [Saves, Collections])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _open());

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (migrator, from, to) async {
          if (from < 2) {
            await migrator.addColumn(saves, saves.imageUrl);
          }
          if (from < 3) {
            await migrator.createTable(collections);
            await migrator.addColumn(saves, saves.collectionId);
          }
          if (from < 4) {
            await migrator.addColumn(saves, saves.aiSummary);
            await migrator.addColumn(saves, saves.category);
            await migrator.addColumn(saves, saves.aiTags);
          }
          if (from < 5) {
            await migrator.addColumn(saves, saves.priority);
          }
        },
      );

  static QueryExecutor _open() {
    return driftDatabase(name: 'later.db');
  }
}
