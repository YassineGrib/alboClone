import 'package:flutter/material.dart';
import 'package:later/l10n/app_localizations.dart';
import 'package:later/ui/core/widgets/bouncy_tap.dart';

class ClipboardIntakeBanner extends StatefulWidget {
  const ClipboardIntakeBanner({
    super.key,
    required this.url,
    required this.onAdd,
    required this.onDismiss,
  });

  final String url;
  final VoidCallback onAdd;
  final VoidCallback onDismiss;

  @override
  State<ClipboardIntakeBanner> createState() => _ClipboardIntakeBannerState();
}

class _ClipboardIntakeBannerState extends State<ClipboardIntakeBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    _slideAnimation = Tween<double>(begin: 40.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOutBack,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOut,
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOutBack,
      ),
    );

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _dismissWithAnim() {
    widget.onDismiss();
    _animController.reverse();
  }

  IconData _getDomainIcon(String url) {
    final lower = url.toLowerCase();
    if (lower.contains('youtube') || lower.contains('youtu.be')) {
      return Icons.play_circle_fill_rounded;
    } else if (lower.contains('tiktok')) {
      return Icons.music_note_rounded;
    } else if (lower.contains('instagram')) {
      return Icons.camera_alt_rounded;
    } else if (lower.contains('twitter') || lower.contains('x.com')) {
      return Icons.alternate_email_rounded;
    } else if (lower.contains('github')) {
      return Icons.code_rounded;
    }
    return Icons.link_rounded;
  }

  Color _getDomainColor(String url) {
    final lower = url.toLowerCase();
    if (lower.contains('youtube') || lower.contains('youtu.be')) {
      return Colors.red;
    } else if (lower.contains('tiktok')) {
      return Colors.pink.shade400;
    } else if (lower.contains('instagram')) {
      return Colors.purple.shade400;
    } else if (lower.contains('twitter') || lower.contains('x.com')) {
      return Colors.blue;
    }
    return Colors.teal;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final iconColor = _getDomainColor(widget.url);
    final l10n = context.l10n;

    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Opacity(
              opacity: _fadeAnimation.value.clamp(0.0, 1.0),
              child: child,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: iconColor.withValues(alpha: 0.4),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
              blurRadius: 20,
              spreadRadius: 2,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            // Domain Icon Badge
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getDomainIcon(widget.url),
                color: iconColor,
                size: 22,
              ),
            ),

            const SizedBox(width: 12),

            // URL Text Preview
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: iconColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Link in Clipboard',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: iconColor,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    widget.url,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 13.5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Actions: Add Link & Dismiss
            BouncyTap(
              onTap: widget.onAdd,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add_link_rounded, size: 18, color: Colors.white),
                    const SizedBox(width: 6),
                    Text(
                      l10n.get('save'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 4),

            IconButton(
              icon: const Icon(Icons.close_rounded, size: 20),
              color: theme.colorScheme.secondary,
              onPressed: _dismissWithAnim,
              tooltip: 'Dismiss',
            ),
          ],
        ),
      ),
    );
  }
}
