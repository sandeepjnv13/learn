import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app_scope.dart';
import '../models/content_node.dart';

/// Navigation tree built from the content manifest. Sections expand/collapse;
/// pages are links. Works at any nesting depth.
class Sidebar extends StatelessWidget {
  final String currentRoute;
  final VoidCallback? onNavigate;

  /// When provided, a collapse control is shown in the header (desktop only).
  final VoidCallback? onCollapse;

  const Sidebar({
    super.key,
    required this.currentRoute,
    this.onNavigate,
    this.onCollapse,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final roots = AppScope.of(context).content.roots;

    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(
          right: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 8, 16),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      context.go('/');
                      onNavigate?.call();
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Icon(Icons.school_rounded, color: scheme.primary),
                          const SizedBox(width: 10),
                          Text(
                            'Learn',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (onCollapse != null)
                  IconButton(
                    tooltip: 'Collapse sidebar',
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.menu_open_rounded),
                    onPressed: onCollapse,
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                for (final node in roots)
                  _NavNode(
                    node: node,
                    depth: 0,
                    currentRoute: currentRoute,
                    onNavigate: onNavigate,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavNode extends StatefulWidget {
  final ContentNode node;
  final int depth;
  final String currentRoute;
  final VoidCallback? onNavigate;

  const _NavNode({
    required this.node,
    required this.depth,
    required this.currentRoute,
    this.onNavigate,
  });

  @override
  State<_NavNode> createState() => _NavNodeState();
}

class _NavNodeState extends State<_NavNode> {
  late bool _expanded = _containsCurrent(widget.node);

  bool _containsCurrent(ContentNode n) {
    if (n.route == widget.currentRoute) return true;
    return n.children.any(_containsCurrent);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final node = widget.node;
    final selected = node.route == widget.currentRoute;
    final indent = 12.0 + widget.depth * 14.0;

    if (node.hasChildren) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: EdgeInsets.fromLTRB(indent, 10, 12, 10),
              child: Row(
                children: [
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_down_rounded
                        : Icons.keyboard_arrow_right_rounded,
                    size: 18,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      node.title,
                      style: TextStyle(
                        fontWeight:
                            widget.depth == 0 ? FontWeight.w700 : FontWeight.w600,
                        color: scheme.onSurface,
                        fontSize: widget.depth == 0 ? 14 : 13.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            for (final c in node.children)
              _NavNode(
                node: c,
                depth: widget.depth + 1,
                currentRoute: widget.currentRoute,
                onNavigate: widget.onNavigate,
              ),
        ],
      );
    }

    // Leaf page
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      child: Material(
        color: selected ? scheme.primaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            context.go(node.route);
            widget.onNavigate?.call();
          },
          child: Padding(
            padding: EdgeInsets.fromLTRB(indent + 10, 9, 12, 9),
            child: Text(
              node.title,
              style: TextStyle(
                fontSize: 13.5,
                color: selected ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
