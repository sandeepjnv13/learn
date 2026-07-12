import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'fit_to_width.dart';
import 'viz_tokens.dart';

/// One node of a binary tree for [TreeCanvas]. Nodes are referenced by a stable
/// [id] (so a recorder can key states/tags to them regardless of value
/// duplicates); [left]/[right] hold child ids (or null). This same model backs
/// BST and general binary-tree visualizers; a weighted/undirected graph would
/// extend the primitive rather than this record.
class TreeNodeSpec {
  final int id;
  final num value;
  final int? left;
  final int? right;

  const TreeNodeSpec({
    required this.id,
    required this.value,
    this.left,
    this.right,
  });

  TreeNodeSpec copyWith({int? left, int? right, bool clearLeft = false, bool clearRight = false}) {
    return TreeNodeSpec(
      id: id,
      value: value,
      left: clearLeft ? null : (left ?? this.left),
      right: clearRight ? null : (right ?? this.right),
    );
  }
}

/// Structure primitive: a binary tree drawn as positioned circular nodes joined
/// by edges, laid out with an in-order sweep for x and depth for y (so nodes
/// never overlap). Colored per-node by a semantic [VizState]; an optional
/// [spine] set highlights the edges along the active recursion path; identity
/// [tags] (e.g. `p`/`q`) float above nodes and [returnTags] (e.g. `→ 6`) sit
/// below them.
///
/// When [editable] is true it also renders **in-canvas building affordances** —
/// a `+` on every empty child slot, a `×` to prune a node, and tap-to-select —
/// emitting callbacks so the owning view can mutate the tree. All tree mutation
/// logic stays in the view; this primitive only renders and reports intent.
/// Self-fits via [FitToWidth]: a wide tree scales down instead of side-scrolling.
class TreeCanvas extends StatelessWidget {
  final List<TreeNodeSpec> nodes;
  final int? rootId;

  final Map<int, VizState> states;

  /// Identity labels rendered as a pill *above* a node (p, q, …).
  final Map<int, String> tags;

  /// Returned-value labels rendered *below* a node (`→ 6`, `null`, …).
  final Map<int, String> returnTags;

  /// Node ids on the active recursion path; edges between consecutive spine
  /// nodes are drawn emphasized.
  final Set<int> spine;

  final bool editable;
  final void Function(int parentId, bool left)? onAddChild;
  final void Function(int id)? onDeleteNode;
  final void Function(int id)? onTapNode;
  final VoidCallback? onAddRoot;

  const TreeCanvas({
    super.key,
    required this.nodes,
    required this.rootId,
    this.states = const {},
    this.tags = const {},
    this.returnTags = const {},
    this.spine = const {},
    this.editable = false,
    this.onAddChild,
    this.onDeleteNode,
    this.onTapNode,
    this.onAddRoot,
  });

  static const double _nodeR = 23;
  static const double _hGap = 60;
  static const double _vGap = 82;
  static const double _slotR = 15;

  double get _topPad => 30;
  double get _sidePad => editable ? 40 : 16;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final byId = {for (final n in nodes) n.id: n};

    if (rootId == null || !byId.containsKey(rootId)) {
      return _emptyTree(context, scheme);
    }

    // In-order x assignment (guarantees non-overlapping real nodes) + depth y.
    final order = <int, int>{}; // id -> in-order index
    final depthOf = <int, int>{};
    final parentOf = <int, int>{}; // child id -> parent id
    var counter = 0;
    var maxDepth = 0;

    void assign(int? id, int depth) {
      if (id == null) return;
      final n = byId[id];
      if (n == null) return;
      if (n.left != null) parentOf[n.left!] = id;
      if (n.right != null) parentOf[n.right!] = id;
      assign(n.left, depth + 1);
      order[id] = counter++;
      depthOf[id] = depth;
      if (depth > maxDepth) maxDepth = depth;
      assign(n.right, depth + 1);
    }

    assign(rootId, 0);

    final count = counter;
    Offset centerOf(int id) => Offset(
          _sidePad + order[id]! * _hGap + _hGap / 2,
          _topPad + depthOf[id]! * _vGap + _nodeR,
        );

    final naturalWidth = count * _hGap + _sidePad * 2;
    final naturalHeight =
        _topPad + (maxDepth + (editable ? 2 : 1)) * _vGap;

    // Collect edges for the painter.
    final edges = <_Edge>[];
    for (final n in nodes) {
      if (!order.containsKey(n.id)) continue;
      for (final childId in [n.left, n.right]) {
        if (childId != null && order.containsKey(childId)) {
          edges.add(_Edge(
            from: centerOf(n.id),
            to: centerOf(childId),
            highlighted: spine.contains(n.id) && spine.contains(childId),
          ));
        }
      }
    }

    final children = <Widget>[
      Positioned.fill(
        child: CustomPaint(
          painter: _EdgePainter(
            edges: edges,
            baseColor: scheme.outlineVariant,
            spineColor: scheme.primary,
          ),
        ),
      ),
    ];

    // Empty child-slot `+` affordances (edit mode only).
    if (editable) {
      for (final n in nodes) {
        if (!order.containsKey(n.id)) continue;
        final c = centerOf(n.id);
        final slotY = c.dy + _vGap;
        if (n.left == null) {
          children.add(_addSlot(
            scheme,
            Offset(c.dx - _hGap * 0.55, slotY),
            () => onAddChild?.call(n.id, true),
          ));
        }
        if (n.right == null) {
          children.add(_addSlot(
            scheme,
            Offset(c.dx + _hGap * 0.55, slotY),
            () => onAddChild?.call(n.id, false),
          ));
        }
      }
    }

    for (final n in nodes) {
      if (!order.containsKey(n.id)) continue;
      children.add(_nodeWidget(context, scheme, n, centerOf(n.id)));
    }

    return FitToWidth(
      naturalWidth: naturalWidth,
      naturalHeight: naturalHeight,
      child: SizedBox(
        width: naturalWidth,
        height: naturalHeight,
        child: Stack(clipBehavior: Clip.none, children: children),
      ),
    );
  }

  Widget _nodeWidget(
    BuildContext context,
    ColorScheme scheme,
    TreeNodeSpec n,
    Offset center,
  ) {
    final state = states[n.id] ?? VizState.inactive;
    final c = vizStateColors(scheme, state);
    final emphatic = state == VizState.processing || state == VizState.found;
    final tag = tags[n.id];
    final ret = returnTags[n.id];
    const w = _nodeR * 2;

    return Positioned(
      left: center.dx - _nodeR,
      top: center.dy - _nodeR,
      width: w,
      height: w,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Identity pill floating above (p / q).
          if (tag != null)
            Positioned(
              left: -_hGap / 2 + _nodeR,
              top: -24,
              width: _hGap,
              height: 20,
              child: Center(child: _identityPill(scheme, tag)),
            ),
          // Returned-value label below.
          if (ret != null)
            Positioned(
              left: -_hGap / 2 + _nodeR,
              top: w + 3,
              width: _hGap,
              height: 18,
              child: Center(child: _returnPill(context, scheme, ret)),
            ),
          // The node body.
          GestureDetector(
            onTap: onTapNode == null ? null : () => onTapNode!(n.id),
            child: AnimatedContainer(
              duration: VizTokens.moveDuration,
              curve: VizTokens.spring,
              width: w,
              height: w,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: c.fill,
                shape: BoxShape.circle,
                border: Border.all(color: c.border, width: emphatic ? 2.4 : 1.4),
                boxShadow: [
                  if (emphatic)
                    BoxShadow(
                      color: c.border.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                ],
              ),
              child: Text(
                '${n.value}',
                style: AppTheme.mono(context, size: 15, color: c.foreground)
                    .copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          // Prune `×` (edit mode).
          if (editable && onDeleteNode != null)
            Positioned(
              right: -8,
              top: -8,
              child: _iconButton(
                scheme,
                Icons.close_rounded,
                scheme.error,
                () => onDeleteNode!(n.id),
              ),
            ),
        ],
      ),
    );
  }

  Widget _addSlot(ColorScheme scheme, Offset center, VoidCallback onTap) {
    return Positioned(
      left: center.dx - _slotR,
      top: center.dy - _slotR,
      width: _slotR * 2,
      height: _slotR * 2,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: 0.06),
            shape: BoxShape.circle,
            border: Border.all(
              color: scheme.primary.withValues(alpha: 0.5),
              width: 1.2,
            ),
          ),
          child: Icon(Icons.add_rounded, size: 18, color: scheme.primary),
        ),
      ),
    );
  }

  Widget _iconButton(
    ColorScheme scheme,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: scheme.surface,
          shape: BoxShape.circle,
          border: Border.all(color: color.withValues(alpha: 0.6)),
        ),
        child: Icon(icon, size: 13, color: color),
      ),
    );
  }

  Widget _identityPill(ColorScheme scheme, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      decoration: BoxDecoration(
        color: scheme.tertiary,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: scheme.onTertiary,
        ),
      ),
    );
  }

  Widget _returnPill(BuildContext context, ColorScheme scheme, String text) {
    final green = scheme.brightness == Brightness.dark
        ? const Color(0xFF4ADE80)
        : const Color(0xFF15803D);
    return Text(
      text,
      style: AppTheme.mono(context, size: 11, color: green)
          .copyWith(fontWeight: FontWeight.w700),
    );
  }

  Widget _emptyTree(BuildContext context, ColorScheme scheme) {
    if (editable && onAddRoot != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: OutlinedButton.icon(
            onPressed: onAddRoot,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Add root node'),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(
          '(empty tree)',
          style: AppTheme.mono(context, size: 13, color: scheme.onSurfaceVariant),
        ),
      ),
    );
  }
}

class _Edge {
  final Offset from;
  final Offset to;
  final bool highlighted;
  const _Edge({required this.from, required this.to, required this.highlighted});
}

class _EdgePainter extends CustomPainter {
  final List<_Edge> edges;
  final Color baseColor;
  final Color spineColor;

  _EdgePainter({
    required this.edges,
    required this.baseColor,
    required this.spineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final e in edges) {
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..color = e.highlighted ? spineColor : baseColor.withValues(alpha: 0.8)
        ..strokeWidth = e.highlighted ? 3.0 : 1.6;
      canvas.drawLine(e.from, e.to, paint);
    }
  }

  @override
  bool shouldRepaint(_EdgePainter old) =>
      old.edges != edges ||
      old.baseColor != baseColor ||
      old.spineColor != spineColor;
}
