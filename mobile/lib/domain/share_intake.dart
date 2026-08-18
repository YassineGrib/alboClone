import 'package:later/data/repositories/save_repository.dart';
import 'package:later/data/repositories/settings_repository.dart';
import 'package:later/domain/share_url.dart';

enum ShareIntakeResult { saved, queued, ignored }

class ShareIntake {
  ShareIntake({required this.saves, required this.settings});

  final SaveRepository saves;
  final SettingsRepository settings;

  Future<ShareIntakeResult> handle(String raw, {required bool signedIn}) async {
    final url = ShareUrlExtractor.first(raw);
    if (url == null) {
      return ShareIntakeResult.ignored;
    }
    if (!signedIn) {
      await settings.stashPendingShare(url);
      return ShareIntakeResult.queued;
    }
    await saves.addUrl(url);
    return ShareIntakeResult.saved;
  }

  Future<ShareIntakeResult> drainPending() async {
    final url = settings.pendingShareUrl();
    if (url == null) {
      return ShareIntakeResult.ignored;
    }
    await settings.clearPendingShare();
    await saves.addUrl(url);
    return ShareIntakeResult.saved;
  }
}
