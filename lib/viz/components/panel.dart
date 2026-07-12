import 'package:flutter/material.dart';

import 'viz_tokens.dart';

/// The white card shell every visualizer panel sits in: soft border, rounded
/// corners, an optional titled header with a leading icon.
class Panel extends StatelessWidget {
  final String? title;
  final IconData? icon;
  final Widget? trailing;

  /// Replaces the default titled header entirely (e.g. a tab switcher). When
  /// set, [title]/[icon]/[trailing] are ignored.
  final Widget? header;

  final EdgeInsetsGeometry padding;

  /// When true the content area flexes to fill the available height (the parent
  /// must provide a bounded height). Used for the scrolling event log.
  final bool fill;

  final Widget child;

  const Panel({
    super.key,
    this.title,
    this.icon,
    this.trailing,
    this.header,
    this.padding = const EdgeInsets.all(16),
    this.fill = false,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(VizTokens.radius + 2),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.7)),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: fill ? MainAxisSize.max : MainAxisSize.min,
        children: [
          if (header != null)
            header!
          else if (title != null)
            _header(scheme),
          if (fill)
            Expanded(child: Padding(padding: padding, child: child))
          else
            Padding(padding: padding, child: child),
        ],
      ),
    );
  }

  Widget _header(ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.6),
          ),
        ),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: scheme.primary),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              title!,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                letterSpacing: 0.2,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
