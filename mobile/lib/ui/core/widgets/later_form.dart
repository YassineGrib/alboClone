import 'package:flutter/material.dart';
import 'package:later/ui/core/theme/later_theme.dart';

/// Outlined field icon; matches the saves list search field.
class LaterInputIcon extends StatelessWidget {
  const LaterInputIcon(this.icon, {super.key});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Icon(
      icon,
      size: 20,
      color: Theme.of(context).colorScheme.secondary,
    );
  }
}

class LaterSectionTitle extends StatelessWidget {
  const LaterSectionTitle({super.key, required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.secondary),
        const SizedBox(width: 8),
        Text(title, style: theme.textTheme.bodySmall),
      ],
    );
  }
}

class LaterLabel extends StatelessWidget {
  const LaterLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}

class LaterHelper extends StatelessWidget {
  const LaterHelper(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(text, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}

class LaterErrorNote extends StatelessWidget {
  const LaterErrorNote(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: LaterColors.chipFailedBg,
          borderRadius: LaterTheme.radius,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.error_outline,
                size: 18,
                color: LaterColors.chipFailedFg,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: LaterColors.chipFailedFg,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
