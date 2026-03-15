import 'package:flutter/material.dart';

/// Widget reutilizable para estados vacíos.
///
/// Uso:
/// ```dart
/// EmptyStateWidget(
///   icon: Icons.fitness_center,
///   title: 'Sin entrenamiento hoy',
///   subtitle: 'No hay sesión programada para hoy.',
///   actionLabel: 'Ver plan',
///   onAction: () => context.push('/plan'),
/// )
/// ```
class EmptyStateWidget extends StatelessWidget {
  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.iconColor,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? iconColor;

  /// Si true, muestra versión compacta (para usar dentro de cards)
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (compact) return _CompactEmpty(this, theme);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: (iconColor ?? const Color(0xFF143C3A))
                    .withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 36,
                color: iconColor ?? const Color(0xFF143C3A),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: const Color(0xFF6B7280)),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

class _CompactEmpty extends StatelessWidget {
  const _CompactEmpty(this.w, this.theme);
  final EmptyStateWidget w;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Row(
        children: [
          Icon(
            w.icon,
            size: 24,
            color: w.iconColor ?? const Color(0xFF6B7280),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  w.title,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w500),
                ),
                if (w.subtitle != null)
                  Text(
                    w.subtitle!,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: const Color(0xFF6B7280)),
                  ),
              ],
            ),
          ),
          if (w.actionLabel != null && w.onAction != null)
            TextButton(onPressed: w.onAction, child: Text(w.actionLabel!)),
        ],
      ),
    );
  }
}
