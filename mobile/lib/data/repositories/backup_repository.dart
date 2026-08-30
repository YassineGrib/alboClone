import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:file_picker/file_picker.dart';
import 'package:later/data/local/app_database.dart';
import 'package:later/data/repositories/save_repository.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class BackupRepository {
  BackupRepository({required this.db, required this.saveRepository});

  final AppDatabase db;
  final SaveRepository saveRepository;

  /// Generates backup JSON string matching Later backup format.
  Future<String> generateBackupJson() async {
    final collections = await (db.select(db.collections)
          ..where((row) => row.syncStatus.isNotValue('pending_delete')))
        .get();

    final saves = await (db.select(db.saves)
          ..where((row) => row.deletedAt.isNull()))
        .get();

    final backupData = {
      'version': '1.0',
      'exported_at': DateTime.now().toUtc().toIso8601String(),
      'collections': collections.map((c) {
        return {
          'id': c.id,
          'name': c.name,
          'description': null,
          'is_shared': false,
        };
      }).toList(),
      'saves': saves.map((s) {
        final tagsList = s.aiTags != null && s.aiTags!.isNotEmpty
            ? s.aiTags!.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList()
            : <String>[];
        return {
          'id': s.id,
          'url': s.url,
          'title': s.title,
          'ai_summary': s.aiSummary,
          'category': s.category,
          'ai_tags': tagsList,
          'priority': s.priority,
          'collection_id': s.collectionId,
          'created_at': s.createdAt.toIso8601String(),
        };
      }).toList(),
    };

    return const JsonEncoder.withIndent('  ').convert(backupData);
  }

  /// Exports backup JSON to file and invokes system share sheet.
  Future<void> exportBackupFile() async {
    final jsonString = await generateBackupJson();
    final tempDir = await getTemporaryDirectory();
    final dateStr = DateTime.now().toIso8601String().substring(0, 10);
    final file = File('${tempDir.path}/later_backup_$dateStr.json');
    await file.writeAsString(jsonString);

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Later App Backup',
      text: 'Backup file of saved links and collections from Later.',
    );
  }

  /// Restores database state from JSON string.
  Future<int> restoreFromJson(String jsonContent) async {
    final map = jsonDecode(jsonContent) as Map<String, dynamic>;
    final collections = (map['collections'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final saves = (map['saves'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    final now = DateTime.now().toUtc();

    for (final col in collections) {
      final id = col['id'] as String;
      final name = col['name'] as String;
      await db.into(db.collections).insert(
            CollectionsCompanion.insert(
              id: id,
              name: name,
              syncStatus: 'pending_sync',
              createdAt: DateTime.now().toUtc(),
              updatedAt: Value(DateTime.now().toUtc()),
            ),
            mode: InsertMode.insertOrReplace,
          );
    }

    int restoredSavesCount = 0;
    for (final s in saves) {
      final id = s['id'] as String;
      final url = s['url'] as String;
      final title = (s['title'] as String?) ?? url;
      final aiSummary = s['ai_summary'] as String?;
      final category = s['category'] as String?;
      final rawTags = s['ai_tags'];
      final List<String> tagsList = rawTags is List ? rawTags.cast<String>() : [];
      final priority = (s['priority'] as int?) ?? 0;
      final collectionId = s['collection_id'] as String?;
      final createdAt = DateTime.tryParse(s['created_at'] as String? ?? '')?.toUtc() ?? now;

      await db.into(db.saves).insert(
            SavesCompanion.insert(
              id: id,
              url: url,
              title: title,
              aiSummary: Value(aiSummary),
              category: Value(category),
              aiTags: Value(tagsList.isNotEmpty ? tagsList.join(',') : null),
              priority: Value(priority),
              collectionId: Value(collectionId),
              contentStatus: const Value('pending'),
              syncStatus: 'pending_sync',
              createdAt: createdAt,
              updatedAt: Value(now),
            ),
            mode: InsertMode.insertOrReplace,
          );
      restoredSavesCount++;
    }

    // Trigger best-effort background sync for restored items
    unawaited(saveRepository.sync());

    return restoredSavesCount;
  }

  /// Opens system file picker to select a .json backup file and restores it.
  Future<int?> importAndRestoreFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result == null || result.files.isEmpty) {
      return null;
    }

    final path = result.files.first.path;
    if (path == null) {
      return null;
    }

    final file = File(path);
    final jsonContent = await file.readAsString();
    return await restoreFromJson(jsonContent);
  }
}
