import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'fit_to_width.dart';
import 'viz_tokens.dart';

/// A labelled pointer that hovers over one node (head / prev / slow / fast …)
/// and glides horizontally as its [index] changes. An [index] equal to the node
/// count parks the marker over the trailing `null` sentinel (a pointer that has
/// walked off the end); any other out-of-range [index] hides it.
class LinkedNodePointer {
  final String label;
  final int index;

  /// Optional color; defaults to the scheme's tertiary.
  final Color? color;

  const LinkedNodePointer(this.label, this.index, {this.color});
}

/// Structure primitive: a singly-linked list drawn as a row of value nodes
/// joined by `next` arrows, terminating in a `null` sentinel, with a lane of
/// gliding [pointers] above.
///
/// Nodes are colored by a semantic [VizState]. Any index in [removed] is
/// treated as unlinked: it pops out of the chain (drops + fades) and the
/// surviving neighbours are reconnected with a healed bypass arc — the visual
/// heart of a "delete node" operation. Kept a dumb render of the step's data;
/// all algorithm logic lives in the recorder.
class LinkedListView extends StatelessWidget {
  final List<num> values;

  /// State per node index; missing indices default to [VizState.inactive].
  final Map<int, VizState> states;
  final List<LinkedNodePointer> pointers;

  /// Node indices that have been unlinked from the chain.
  final Set<int> removed;

  static const double _nodeW = 62;
  static const double _nodeH = 52;
  static const double _gap = 46; // arrow room between nodes
  static const double _laneRowH = 26;
  static const double _idxLabelH = 18;
  static const double _removedDrop = 22; // how far an unlinked node pops down

  const LinkedListView({
    super.key,
    required this.values,
    this.states = const {},
    this.pointers = const [],
    this.removed = const {},
  });

  double get _stride => _nodeW + _gap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final n = values.length;
    final laneH = pointers.isEmpty ? 0.0 : pointers.length * _laneRowH;
    final gapAboveChain = pointers.isEmpty ? 0.0 : 8.0;
    // One extra stride reserved for the trailing `null` sentinel (with a little
    // more room so a pointer parked over it isn't clipped).
    final totalW = n == 0 ? 60.0 : n * _stride + 64;
    final canvasH = _nodeH + _removedDrop + _idxLabelH;
    final totalH = laneH + gapAboveChain + canvasH + 8;

    // Scale the chain down to fit the available width instead of overflowing
    // into a horizontal scroll when the list is long.
    return FitToWidth(
      naturalWidth: totalW,
      naturalHeight: totalH,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (pointers.isNotEmpty)
              SizedBox(
                height: laneH,
                width: totalW,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    for (var p = 0; p < pointers.length; p++)
                      _pointer(context, scheme, pointers[p], p),
                  ],
                ),
              ),
            SizedBox(height: gapAboveChain),
            SizedBox(
              height: canvasH,
              width: totalW,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _ChainPainter(
                        count: n,
                        stride: _stride,
                        nodeW: _nodeW,
                        midY: _nodeH / 2,
                        removed: removed,
                        linkColor:
                            scheme.onSurfaceVariant.withValues(alpha: 0.65),
                        healColor: vizStateColors(scheme, VizState.found).border,
                      ),
                    ),
                  ),
                  for (var i = 0; i < n; i++) _node(context, scheme, i),
                  _nullSentinel(context, scheme, n),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pointer(
    BuildContext context,
    ColorScheme scheme,
    LinkedNodePointer ptr,
    int slot,
  ) {
    final color = ptr.color ?? scheme.tertiary;
    // index == values.length parks the marker over the trailing `null` sentinel.
    final visible = ptr.index >= 0 && ptr.index <= values.length;
    return AnimatedPositioned(
      duration: VizTokens.moveDuration,
      curve: VizTokens.spring,
      left: (visible ? ptr.index : 0) * _stride,
      top: slot * _laneRowH,
      width: _nodeW,
      height: _laneRowH,
      child: AnimatedOpacity(
        duration: VizTokens.moveDuration,
        opacity: visible ? 1 : 0,
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: color.withValues(alpha: 0.5)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  ptr.label,
                  style: AppTheme.mono(context, size: 12, color: color)
                      .copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(width: 3),
                Icon(Icons.arrow_drop_down_rounded, size: 16, color: color),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _node(BuildContext context, ColorScheme scheme, int i) {
    final gone = removed.contains(i);
    final state = states[i] ?? VizState.inactive;
    final c = vizStateColors(scheme, state);
    final emphatic =
        state == VizState.processing || state == VizState.found;
    return AnimatedPositioned(
      duration: VizTokens.moveDuration,
      curve: VizTokens.spring,
      left: i * _stride,
      top: gone ? _removedDrop : 0,
      width: _nodeW,
      height: _nodeH,
      child: AnimatedOpacity(
        duration: VizTokens.moveDuration,
        opacity: gone ? 0.55 : 1,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: VizTokens.moveDuration,
              curve: VizTokens.spring,
              width: _nodeW,
              height: _nodeH,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: c.fill,
                borderRadius: BorderRadius.circular(VizTokens.radius),
                border: Border.all(color: c.border, width: emphatic ? 2 : 1),
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
                '${values[i]}',
                style: AppTheme.mono(context, size: 17, color: c.foreground)
                    .copyWith(
                  fontWeight: FontWeight.w700,
                  decoration: gone ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              '$i',
              style: AppTheme.mono(
                context,
                size: 11,
                color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _nullSentinel(BuildContext context, ColorScheme scheme, int n) {
    return Positioned(
      left: n * _stride,
      top: (_nodeH - 26) / 2,
      height: 26,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: scheme.outlineVariant,
            width: 1,
          ),
        ),
        child: Text(
          'null',
          style: AppTheme.mono(
            context,
            size: 12,
            color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }
}

/// Paints the `next` arrows joining live nodes, healing over any removed node
/// with an arc, and the arrow into the trailing `null` sentinel.
class _ChainPainter extends CustomPainter {
  final int count;
  final double stride;
  final double nodeW;
  final double midY;
  final Set<int> removed;
  final Color linkColor;
  final Color healColor;

  _ChainPainter({
    required this.count,
    required this.stride,
    required this.nodeW,
    required this.midY,
    required this.removed,
    required this.linkColor,
    required this.healColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (count == 0) return;

    // Sequence of live targets, ending in the virtual `null` node at `count`.
    final seq = <int>[
      for (var i = 0; i < count; i++)
        if (!removed.contains(i)) i,
      count,
    ];

    for (var k = 0; k < seq.length - 1; k++) {
      final a = seq[k];
      final b = seq[k + 1];
      final fromX = a * stride + nodeW;
      final toX = b * stride;
      if (b == a + 1) {
        _straight(canvas, fromX, toX, linkColor);
      } else {
        // A node was skipped — draw the healed bypass link.
        _arc(canvas, fromX, toX, healColor);
      }
    }
  }

  void _straight(Canvas canvas, double fromX, double toX, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final tip = Offset(toX - 1, midY);
    canvas.drawLine(Offset(fromX + 2, midY), tip, paint);
    _head(canvas, tip, const Offset(1, 0), color);
  }

  void _arc(Canvas canvas, double fromX, double toX, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke;
    final start = Offset(fromX - nodeW / 2, midY - 4);
    final end = Offset(toX + nodeW / 2, midY - 4);
    final ctrl = Offset((start.dx + end.dx) / 2, midY - nodeW * 0.9);
    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..quadraticBezierTo(ctrl.dx, ctrl.dy, end.dx, end.dy);
    canvas.drawPath(path, paint);
    _head(canvas, end, end - ctrl, color);
  }

  void _head(Canvas canvas, Offset tip, Offset dir, Color color) {
    final len = dir.distance;
    if (len == 0) return;
    // Reverse (backward) unit vector — the barbs fan out around it.
    final bx = -dir.dx / len;
    final by = -dir.dy / len;
    const size = 8.0;
    const spread = 0.5; // radians, ~29° each side
    Offset barb(double sign) {
      final c = math.cos(sign * spread), s = math.sin(sign * spread);
      return Offset(
        tip.dx + size * (bx * c - by * s),
        tip.dy + size * (bx * s + by * c),
      );
    }

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(barb(1).dx, barb(1).dy)
      ..lineTo(barb(-1).dx, barb(-1).dy)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_ChainPainter old) =>
      old.count != count ||
      old.removed != removed ||
      old.linkColor != linkColor ||
      old.healColor != healColor;
}
