import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:later/domain/share_intake.dart';
import 'package:later/ui/app_providers.dart';

final laterMessengerKey = GlobalKey<ScaffoldMessengerState>();

class ShareListener extends ConsumerStatefulWidget {
  const ShareListener({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<ShareListener> createState() => _ShareListenerState();
}

class _ShareListenerState extends ConsumerState<ShareListener> {
  StreamSubscription<String>? _sub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _boot());
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _boot() async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    if (!mounted) return;

    final intake = ref.read(shareIntakeProvider);
    if (ref.read(authTokenProvider) != null) {
      final drained = await intake.drainPending();
      if (drained == ShareIntakeResult.saved && mounted) {
        _toast(drained);
      }
    }

    final shares = ref.read(incomingSharesProvider);
    final initial = await shares.takeColdStart();
    if (initial != null && mounted) {
      await _ingest(initial);
    }
    if (mounted) {
      _sub = shares.watch().listen(_ingest, onError: (_) {});
    }
  }

  Future<void> _ingest(String raw) async {
    final result = await ref.read(shareIntakeProvider).handle(
          raw,
          signedIn: ref.read(authTokenProvider) != null,
        );
    _toast(result);
  }

  void _toast(ShareIntakeResult result) {
    final text = switch (result) {
      ShareIntakeResult.saved => 'Saved',
      ShareIntakeResult.queued => 'Saved after you log in',
      ShareIntakeResult.ignored => 'No URL in that share',
    };
    laterMessengerKey.currentState?.showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authTokenProvider, (previous, next) async {
      if (previous == null && next != null) {
        final result = await ref.read(shareIntakeProvider).drainPending();
        if (result == ShareIntakeResult.saved) {
          _toast(result);
        }
      }
    });
    return widget.child;
  }
}
