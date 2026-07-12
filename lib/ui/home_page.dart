import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app_scope.dart';
import '../models/content_node.dart';

/// Landing page: a grid of the top-level sections.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final roots = AppScope.of(context).content.roots;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(32, 48, 32, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Learn',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'A personal, interactive knowledge base.',
            style: TextStyle(fontSize: 18, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [for (final s in roots) _SectionCard(node: s)],
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final ContentNode node;
  const _SectionCard({required this.node});

  int _countPages(ContentNode n) =>
      (n.isPage ? 1 : 0) + n.children.fold(0, (s, c) => s + _countPages(c));

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final firstPage = node.flattenPages().firstOrNull;
    final count = _countPages(node);

    return SizedBox(
      width: 240,
      child: Material(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: firstPage == null ? null : () => context.go(firstPage.route),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.6),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.folder_rounded, color: scheme.primary),
                const SizedBox(height: 16),
                Text(
                  node.title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$count ${count == 1 ? 'page' : 'pages'}',
                  style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
