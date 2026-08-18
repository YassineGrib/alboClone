import 'package:share_handler/share_handler.dart';

abstract class IncomingShares {
  Future<String?> takeColdStart();
  Stream<String> watch();
}

class ShareHandlerIncomingShares implements IncomingShares {
  String? _text(SharedMedia? media) {
    final content = media?.content?.trim();
    if (content == null || content.isEmpty) {
      return null;
    }
    return content;
  }

  @override
  Future<String?> takeColdStart() async {
    try {
      final handler = ShareHandler.instance;
      final media = await handler.getInitialSharedMedia();
      await handler.resetInitialSharedMedia();
      return _text(media);
    } catch (_) {
      return null;
    }
  }

  @override
  Stream<String> watch() {
    try {
      return ShareHandler.instance.sharedMediaStream
          .handleError((Object _) {})
          .map(_text)
          .where((value) => value != null)
          .cast<String>();
    } catch (_) {
      return const Stream.empty();
    }
  }
}
