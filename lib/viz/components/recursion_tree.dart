import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'fit_to_width.dart';
import 'viz_tokens.dart';

/// One call in a [RecursionTree].
///
/// Unlike [TreeCanvas] - which draws a binary tree of *data* (numeric nodes,
/// left/right) - this models a **call tree**: nodes are calls labelled by their
/// signature (`(2,2)`, `fib(5)`), a call may have any number of children, and
/// nodes carry an identity [tint] so the *same* subproblem appearing in several
/// places is visibly the same.
class CallNodeSpec {
  final int id;

  /// The call signature shown in the node, e.g. `(2,2)`.
  final String label;

  /// Child call ids, left to right, in the order the algorithm makes them.
  final List<int> children;

  /// Identity tint index (see [vizIdentityColors]) - color-matches repeated
  /// calls. Null leaves the node in its semantic [state] color.
  final int? tint;

  /// Value this call returned, rendered under the node (`→ 7`).
  final String? returns;

  /// A **cache hit**: the memo already held this answer, so the call returned
  /// immediately and its whole subtree was never explored. Drawn as a faded,
  /// dashed stub that keeps its identity [tint] (so you can still see *which*
  /// subproblem it was) while reading as inert.
  final bool cacheHit;

  /// Small pill above the node, e.g. a repeat count `×6`.
  final String? badge;

  final VizState state;

  const CallNodeSpec({
    required this.id,
    required this.label,
    this.children = const [],
    this.tint,
    this.returns,
    this.cacheHit = false,
    this.badge,
    this.state = VizState.inactive,
  });
}

/// Structure primitive: an **n-ary recursion / call tree**. The picture for
/// "what does this recursion actually do" - overlapping subproblems, call
/// expansion, memoization collapse.
///
/// Layout is a leaf sweep: leaves take successive x slots and every internal
/// node centers over its children, so subtrees occupy disjoint x ranges and
/// nodes can never overlap. Depth drives y.
///
/// Dumb stateless render - no algorithm logic. Colors come from
/// [vizIdentityColors] / [vizStateColors], motion from [VizTokens], and it
/// self-fits via [FitToWidth] so a wide tree scales down rather than
/// side-scrolling.
class RecursionTree extends StatelessWidget {
  final List<CallNodeSpec> nodes;
  final int? rootId;

  const RecursionTree({
    super.key,
    required this.nodes,
    required this.rootId,
  });

  static const double _nodeW = 54;
  static const double _nodeH = 32;
  static const double _hGap = 64;
  static const double _vGap = 64;
  static const double _topPad = 22;
  static const double _sidePad = 10;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final byId = {for (final n in nodes) n.id: n};

    if (rootId == null || !byId.containsKey(rootId)) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            '(no calls)',
            style: AppTheme.mono(context, size: 13, color: scheme.onSurfaceVariant),
          ),
        ),
      );
    }

    // Leaf sweep: leaves claim successive slots, parents center over children.
    final slotOf = <int, double>{};
    final depthOf = <int, int>{};
    var nextLeaf = 0.0;
    var maxDepth = 0;

    double assign(int id, int depth) {
      final n = byId[id]!;
      depthOf[id] = depth;
      if (depth > maxDepth) maxDepth = depth;
      final kids = n.children.where(byId.containsKey).toList();
      double slot;
      if (kids.isEmpty) {
        slot = nextLeaf++;
      } else {
        var sum = 0.0;
        for (final k in kids) {
          sum += assign(k, depth + 1);
        }
        slot = sum / kids.length;
      }
      slotOf[id] = slot;
      return slot;
    }

    assign(rootId!, 0);

    Offset centerOf(int id) => Offset(
          _sidePad + slotOf[id]! * _hGap + _hGap / 2,
          _topPad + depthOf[id]! * _vGap + _nodeH / 2,
        );

    final naturalWidth = nextLeaf * _hGap + _sidePad * 2;
    final naturalHeight = _topPad + maxDepth * _vGap + _nodeH + 30;

    final edges = <_CallEdge>[];
    for (final n in nodes) {
      if (!slotOf.containsKey(n.id)) continue;
      for (final childId in n.children) {
        if (!slotOf.containsKey(childId)) continue;
        edges.add(_CallEdge(
          from: centerOf(n.id),
          to: centerOf(childId),
          faded: byId[childId]!.cacheHit,
        ));
      }
    }

    return FitToWidth(
      naturalWidth: naturalWidth,
      naturalHeight: naturalHeight,
      child: SizedBox(
        width: naturalWidth,
        height: naturalHeight,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _CallEdgePainter(
                  edges: edges,
                  color: scheme.outlineVariant,
                ),
              ),
            ),
            for (final n in nodes)
              if (slotOf.containsKey(n.id))
                _nodeWidget(context, scheme, n, centerOf(n.id)),
          ],
        ),
      ),
    );
  }

  Widget _nodeWidget(
    BuildContext context,
    ColorScheme scheme,
    CallNodeSpec n,
    Offset center,
  ) {
    final c = n.tint != null
        ? vizIdentityColors(scheme, n.tint!)
        : vizStateColors(scheme, n.state);

    return Positioned(
      left: center.dx - _nodeW / 2,
      top: center.dy - _nodeH / 2,
      width: _nodeW,
      height: _nodeH,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (n.badge != null)
            Positioned(
              left: -_hGap / 2 + _nodeW / 2,
              top: -19,
              width: _hGap,
              height: 17,
              child: Center(child: _badgePill(context, c, n.badge!)),
            ),
          if (n.returns != null)
            Positioned(
              left: -_hGap / 2 + _nodeW / 2,
              top: _nodeH + 2,
              width: _hGap,
              height: 16,
              child: Center(child: _returnLabel(context, scheme, n.returns!)),
            ),
          AnimatedOpacity(
            duration: VizTokens.moveDuration,
            opacity: n.cacheHit ? 0.55 : 1.0,
            child: AnimatedContainer(
              duration: VizTokens.moveDuration,
              curve: VizTokens.spring,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: n.cacheHit ? c.fill.withValues(alpha: 0.5) : c.fill,
                borderRadius: BorderRadius.circular(VizTokens.radius - 3),
                // A solid border for a real call; the dashed one is painted
                // over the top for a cache-hit stub.
                border: Border.all(
                  color: n.cacheHit ? Colors.transparent : c.border,
                  width: 1.4,
                ),
              ),
              foregroundDecoration: n.cacheHit
                  ? _DashedBorder(color: c.border, radius: VizTokens.radius - 3)
                  : null,
              child: Text(
                n.label,
                style: AppTheme.mono(context, size: 12, color: c.foreground)
                    .copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _badgePill(BuildContext context, VizStateColors c, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: c.border,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: AppTheme.mono(context, size: 9.5, color: Colors.white)
            .copyWith(fontWeight: FontWeight.w800),
      ),
    );
  }

  Widget _returnLabel(BuildContext context, ColorScheme scheme, String text) {
    final green = scheme.brightness == Brightness.dark
        ? const Color(0xFF4ADE80)
        : const Color(0xFF15803D);
    return Text(
      text,
      style: AppTheme.mono(context, size: 10, color: green)
          .copyWith(fontWeight: FontWeight.w700),
    );
  }
}

/// Dashed rounded-rect border, used to mark a cache-hit stub.
class _DashedBorder extends Decoration {
  final Color color;
  final double radius;
  const _DashedBorder({required this.color, required this.radius});

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) =>
      _DashedBorderPainter(color, radius);
}

class _DashedBorderPainter extends BoxPainter {
  final Color color;
  final double radius;
  _DashedBorderPainter(this.color, this.radius);

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration cfg) {
    final size = cfg.size;
    if (size == null) return;
    final rrect = RRect.fromRectAndRadius(
      (offset & size).deflate(0.7),
      Radius.circular(radius),
    );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    for (final metric in (Path()..addRRect(rrect)).computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        final end = (d + 4).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(d, end), paint);
        d += 7;
      }
    }
  }
}

class _CallEdge {
  final Offset from;
  final Offset to;
  final bool faded;
  const _CallEdge({required this.from, required this.to, required this.faded});
}

class _CallEdgePainter extends CustomPainter {
  final List<_CallEdge> edges;
  final Color color;

  _CallEdgePainter({required this.edges, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    for (final e in edges) {
      canvas.drawLine(
        e.from,
        e.to,
        Paint()
          ..color = color.withValues(alpha: e.faded ? 0.35 : 0.8)
          ..strokeWidth = 1.5
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_CallEdgePainter old) =>
      old.edges != edges || old.color != color;
}
