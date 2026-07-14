import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'viz_tokens.dart';

/// A **static, non-interactive "glance card"**: the at-a-glance answer to
/// *"how is this problem solved?"* that sits at the top of a problem page.
///
/// It is deliberately not a stepper - no play/step controls, no editable input.
/// It renders the **technique name**, a small **schematic** (a hand-drawn hint
/// keyed by [pattern] - e.g. a decreasing staircase for a monotonic stack), a
/// few short **mechanic** bullets, an optional **gotcha**, and the
/// **complexity**. Glancing at it should point you straight at the right idea.
///
/// Compose it via the `type: approach` viz block (see
/// `renderers/approach/approach_view.dart`); it is registered as a *static*
/// visualizer so it draws inline without the Fit/Focus chrome.
class ApproachCard extends StatelessWidget {
  /// The headline technique, e.g. `'Monotonic decreasing stack'`.
  final String technique;

  /// Selects the built-in schematic. Known values: `monotonic-stack`, `stack`,
  /// `binary-search`, `two-pointer`, `fast-slow`, `post-order`, `coordinate`,
  /// `interval`, `adjacent-swap`, `running-sum`, `gas-station`. Anything else
  /// falls back to a generic box.
  final String pattern;

  /// One-line gist under the headline (optional).
  final String? idea;

  /// 2–4 short mechanic lines - the moves that make the technique work.
  final List<String> bullets;

  /// A single highlighted watch-out (optional).
  final String? gotcha;

  /// Complexity summary, e.g. `'O(n) time · O(n) space'` (optional).
  final String? complexity;

  const ApproachCard({
    super.key,
    required this.technique,
    required this.pattern,
    this.idea,
    this.bullets = const [],
    this.gotcha,
    this.complexity,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final schematic = ApproachSchematic(pattern: pattern);
    final details = _details(context, scheme);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          _header(scheme),
          Padding(
            padding: const EdgeInsets.all(18),
            child: LayoutBuilder(
              builder: (context, c) {
                final narrow = c.maxWidth < 620;
                if (narrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      schematic,
                      const SizedBox(height: 16),
                      details,
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: 320, child: schematic),
                    const SizedBox(width: 22),
                    Expanded(child: details),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 14, 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.6),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.bolt_rounded, size: 16, color: scheme.primary),
          const SizedBox(width: 8),
          Text(
            'At a glance',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              letterSpacing: 0.4,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          if (complexity != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                complexity!,
                style: TextStyle(
                  fontSize: 11.5,
                  fontFeatures: const [ui.FontFeature.tabularFigures()],
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _details(BuildContext context, ColorScheme scheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          technique,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            height: 1.2,
            color: scheme.onSurface,
          ),
        ),
        if (idea != null) ...[
          const SizedBox(height: 6),
          Text(
            idea!,
            style: TextStyle(
              fontSize: 13.5,
              height: 1.4,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
        if (bullets.isNotEmpty) ...[
          const SizedBox(height: 14),
          for (final b in bullets) _bullet(context, scheme, b),
        ],
        if (gotcha != null) ...[
          const SizedBox(height: 12),
          _gotcha(scheme),
        ],
      ],
    );
  }

  Widget _bullet(BuildContext context, ColorScheme scheme, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6, right: 10),
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: scheme.primary,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.45,
                color: scheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _gotcha(ColorScheme scheme) {
    final dark = scheme.brightness == Brightness.dark;
    final amber = dark ? const Color(0xFFF0B429) : const Color(0xFFB77400);
    final amberFill = dark ? const Color(0x334A3A12) : const Color(0xFFFFF3D6);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: amberFill,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: amber.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, size: 16, color: amber),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              gotcha!,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: dark ? const Color(0xFFF0B429) : const Color(0xFF7A4E00),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The small vector schematic that heads an [ApproachCard]. A pure, static
/// drawing keyed by `pattern` - no animation, no state, theme-aware.
class ApproachSchematic extends StatelessWidget {
  final String pattern;
  const ApproachSchematic({super.key, required this.pattern});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: 168,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(VizTokens.radius),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: CustomPaint(
        painter: _SchematicPainter(pattern: pattern, scheme: scheme),
        size: Size.infinite,
      ),
    );
  }
}

class _SchematicPainter extends CustomPainter {
  final String pattern;
  final ColorScheme scheme;

  _SchematicPainter({required this.pattern, required this.scheme});

  // Resolved palette (theme-aware, mirrors the semantic viz colors).
  bool get _dark => scheme.brightness == Brightness.dark;
  Color get _primary => scheme.primary;
  Color get _primaryFill => scheme.primaryContainer;
  Color get _muted => scheme.onSurfaceVariant;
  Color get _faint => scheme.outlineVariant;
  Color get _amber => _dark ? const Color(0xFFF0B429) : const Color(0xFFB77400);
  Color get _amberFill =>
      _dark ? const Color(0xFF4A3A12) : const Color(0xFFFFF3D6);
  Color get _green => _dark ? const Color(0xFF4ADE80) : const Color(0xFF15803D);
  Color get _greenFill =>
      _dark ? const Color(0xFF12351F) : const Color(0xFFDCFCE7);

  @override
  void paint(Canvas canvas, Size size) {
    final r = Rect.fromLTWH(16, 14, size.width - 32, size.height - 28);
    switch (pattern) {
      case 'monotonic-stack':
        _monotonicStack(canvas, r);
      case 'stack':
        _stack(canvas, r);
      case 'binary-search':
        _binarySearch(canvas, r);
      case 'two-pointer':
        _twoPointer(canvas, r);
      case 'fast-slow':
        _fastSlow(canvas, r);
      case 'post-order':
        _postOrder(canvas, r);
      case 'coordinate':
        _coordinate(canvas, r);
      case 'interval':
        _interval(canvas, r);
      case 'adjacent-swap':
        _adjacentSwap(canvas, r);
      case 'running-sum':
        _runningSum(canvas, r);
      case 'gas-station':
        _gasStation(canvas, r);
      default:
        _generic(canvas, r);
    }
  }

  // ---- shared drawing helpers -------------------------------------------

  void _rrect(Canvas c, Rect rect, Color fill, {Color? border, double rad = 6}) {
    final rr = RRect.fromRectAndRadius(rect, Radius.circular(rad));
    c.drawRRect(rr, Paint()..color = fill);
    if (border != null) {
      c.drawRRect(
        rr,
        Paint()
          ..color = border
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4,
      );
    }
  }

  void _line(Canvas c, Offset a, Offset b, Color color, {double w = 1.5}) {
    c.drawLine(
      a,
      b,
      Paint()
        ..color = color
        ..strokeWidth = w
        ..strokeCap = StrokeCap.round,
    );
  }

  /// Arrow from a → b with a small solid head at b.
  void _arrow(Canvas c, Offset a, Offset b, Color color, {double w = 1.6}) {
    _line(c, a, b, color, w: w);
    final dir = (b - a);
    final len = dir.distance;
    if (len < 0.01) return;
    final u = dir / len;
    final n = Offset(-u.dy, u.dx);
    const head = 6.5;
    final p1 = b - u * head + n * (head * 0.55);
    final p2 = b - u * head - n * (head * 0.55);
    final path = Path()
      ..moveTo(b.dx, b.dy)
      ..lineTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy)
      ..close();
    c.drawPath(path, Paint()..color = color);
  }

  void _text(
    Canvas c,
    String s,
    Offset at,
    Color color, {
    double size = 11,
    FontWeight weight = FontWeight.w500,
    TextAlign align = TextAlign.center,
    bool mono = false,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(
          color: color,
          fontSize: size,
          fontWeight: weight,
          fontFamily: mono ? 'monospace' : null,
          height: 1.1,
        ),
      ),
      textAlign: align,
      textDirection: TextDirection.ltr,
    )..layout();
    Offset origin = at;
    if (align == TextAlign.center) {
      origin = at - Offset(tp.width / 2, tp.height / 2);
    } else if (align == TextAlign.right) {
      origin = at - Offset(tp.width, tp.height / 2);
    } else {
      origin = at - Offset(0, tp.height / 2);
    }
    tp.paint(c, origin);
  }

  // ---- schematics --------------------------------------------------------

  /// Descending staircase of bars + a taller incoming element that pops them.
  void _monotonicStack(Canvas c, Rect r) {
    _text(c, 'stack - strictly decreasing', Offset(r.left + 4, r.top + 6),
        _muted,
        size: 10.5, align: TextAlign.left);
    final base = r.bottom - 22;
    const n = 4;
    final bw = 26.0;
    final gap = 8.0;
    final heights = [64.0, 50.0, 36.0, 22.0];
    var x = r.left + 6;
    for (var i = 0; i < n; i++) {
      final h = heights[i];
      final rect = Rect.fromLTWH(x, base - h, bw, h);
      _rrect(c, rect, _primaryFill, border: _primary);
      x += bw + gap;
    }
    // top marker over the last (shortest) bar
    final topX = r.left + 6 + (n - 1) * (bw + gap) + bw / 2;
    _text(c, 'top', Offset(topX, base - heights[n - 1] - 12), _primary,
        size: 10, weight: FontWeight.w700);
    _line(c, Offset(r.left + 6, base + 1), Offset(x - gap, base + 1), _faint);

    // incoming larger element on the right
    final inX = x + 12;
    final inH = 78.0;
    final inRect = Rect.fromLTWH(inX, base - inH, bw + 4, inH);
    _rrect(c, inRect, _amberFill, border: _amber);
    _text(c, 'new', Offset(inX + (bw + 4) / 2, base + 12), _amber,
        size: 10, weight: FontWeight.w700);

    // pop arrow: from the incoming bar back to the shortest tops
    _arrow(c, Offset(inX - 3, base - 30), Offset(topX + bw / 2, base - 26),
        _amber);
    // The mechanic caption lives in the BOTTOM band - one caption per band, so it
    // never shares the top band with the title (they overlapped at the ~288px
    // row-mode width). Sits below the "new" label with vertical clearance. See
    // the schematic-label guidance in the skill's components reference.
    _text(c, 'pop while top < new', Offset(r.center.dx, r.bottom + 6),
        _amber,
        size: 10, weight: FontWeight.w600);
  }

  /// LIFO stack of cells with a push/pop double-arrow at the top.
  void _stack(Canvas c, Rect r) {
    const labels = ['(', '[', '{'];
    final cw = 46.0;
    final ch = 30.0;
    final cx = r.left + 30;
    // Start low enough that the push/pop labels above the top cell stay inside
    // the box.
    final startY = r.bottom - 12;
    var y = startY;
    for (var i = 0; i < labels.length; i++) {
      final rect = Rect.fromLTWH(cx, y - ch, cw, ch);
      final top = i == labels.length - 1;
      _rrect(c, rect, top ? _primaryFill : scheme.surfaceContainerHighest,
          border: top ? _primary : _faint);
      _text(c, labels[i], rect.center, top ? _primary : _muted,
          size: 15, weight: FontWeight.w700, mono: true);
      y -= ch + 6;
    }
    final topY = startY - (labels.length - 1) * (ch + 6) - ch;
    // push/pop double arrow above the top cell
    final ax = cx + cw + 26;
    _arrow(c, Offset(ax, topY + 4), Offset(ax, topY - 20), _primary);
    _arrow(c, Offset(ax + 18, topY - 20), Offset(ax + 18, topY + 4), _amber);
    _text(c, 'push', Offset(ax - 4, topY - 30), _primary,
        size: 10, align: TextAlign.right, weight: FontWeight.w600);
    _text(c, 'pop', Offset(ax + 22, topY - 30), _amber,
        size: 10, align: TextAlign.left, weight: FontWeight.w600);
    _text(c, 'top', Offset(cx - 8, topY + ch / 2), _primary,
        size: 10, align: TextAlign.right, weight: FontWeight.w700);
    _text(c, 'LIFO - last opened, first matched',
        Offset(r.center.dx, r.bottom + 2), _muted,
        size: 10);
  }

  /// Sorted range with lo/mid/hi and one half discarded.
  void _binarySearch(Canvas c, Rect r) {
    const n = 8;
    final cw = (r.width - 8) / n;
    final ch = 34.0;
    final y = r.center.dy - 6;
    final mid = 3;
    for (var i = 0; i < n; i++) {
      final rect = Rect.fromLTWH(r.left + 4 + i * cw, y, cw - 5, ch);
      final discarded = i <= mid; // left half ruled out
      final Color fill;
      final Color? border;
      if (i == mid + 1) {
        fill = _amberFill;
        border = _amber;
      } else if (discarded) {
        fill = scheme.surfaceContainerHighest.withValues(alpha: 0.4);
        border = _faint.withValues(alpha: 0.5);
      } else {
        fill = _primaryFill;
        border = _primary;
      }
      _rrect(c, rect, fill, border: border, rad: 5);
    }
    Offset centerOf(int i) =>
        Offset(r.left + 4 + i * cw + (cw - 5) / 2, y);
    // markers
    _text(c, 'lo', centerOf(0) + Offset(0, -ch), _muted, size: 10);
    _text(c, 'mid', centerOf(mid) + Offset(0, -ch), _muted, size: 10);
    _text(c, 'hi', centerOf(n - 1) + Offset(0, -ch), _muted, size: 10);
    // discard cross-out on left half
    _text(c, 'target > mid → drop left half',
        Offset(r.center.dx, r.bottom - 2), _amber,
        size: 10.5, weight: FontWeight.w600);
    _arrow(c, Offset(centerOf(mid).dx, y + ch + 14),
        Offset(centerOf(n - 1).dx, y + ch + 14), _primary);
  }

  /// Row of cells with converging lo → ← hi pointers.
  void _twoPointer(Canvas c, Rect r) {
    const n = 6;
    final cw = (r.width - 8) / n;
    final ch = 34.0;
    final y = r.center.dy - 8;
    for (var i = 0; i < n; i++) {
      final rect = Rect.fromLTWH(r.left + 4 + i * cw, y, cw - 6, ch);
      final active = i == 1 || i == n - 2;
      _rrect(c, rect, active ? _primaryFill : scheme.surfaceContainerHighest,
          border: active ? _primary : _faint, rad: 5);
    }
    double cx(int i) => r.left + 4 + i * cw + (cw - 6) / 2;
    // lo pointer moving right
    _arrow(c, Offset(cx(1) - 10, y + ch + 14), Offset(cx(1) + 12, y + ch + 14),
        _primary);
    _text(c, 'lo', Offset(cx(1) - 16, y + ch + 14), _primary,
        size: 10, align: TextAlign.right, weight: FontWeight.w700);
    // hi pointer moving left
    _arrow(c, Offset(cx(n - 2) + 10, y + ch + 14),
        Offset(cx(n - 2) - 12, y + ch + 14), _amber);
    _text(c, 'hi', Offset(cx(n - 2) + 16, y + ch + 14), _amber,
        size: 10, align: TextAlign.left, weight: FontWeight.w700);
    _text(c, 'sorted - move the pointers inward',
        Offset(r.center.dx, r.top + 2), _muted,
        size: 10.5);
  }

  /// Linked list with slow (1×) and fast (2×) pointers.
  void _fastSlow(Canvas c, Rect r) {
    const n = 5;
    final nodeW = 34.0;
    final gap = (r.width - n * nodeW) / (n - 1);
    final y = r.center.dy - 4;
    double nx(int i) => r.left + i * (nodeW + gap);
    for (var i = 0; i < n; i++) {
      final rect = Rect.fromLTWH(nx(i), y - 16, nodeW, 32);
      final isSlow = i == 1;
      final isFast = i == 3;
      _rrect(
        c,
        rect,
        isSlow || isFast ? _primaryFill : scheme.surfaceContainerHighest,
        border: isSlow || isFast ? _primary : _faint,
        rad: 6,
      );
      if (i < n - 1) {
        _arrow(c, Offset(nx(i) + nodeW + 1, y),
            Offset(nx(i + 1) - 1, y), _muted, w: 1.3);
      }
    }
    _text(c, 'slow', Offset(nx(1) + nodeW / 2, y - 30), _primary,
        size: 10.5, weight: FontWeight.w700);
    _text(c, '+1', Offset(nx(1) + nodeW / 2, y + 28), _primary, size: 10);
    _text(c, 'fast', Offset(nx(3) + nodeW / 2, y - 30), _amber,
        size: 10.5, weight: FontWeight.w700);
    _text(c, '+2', Offset(nx(3) + nodeW / 2, y + 28), _amber, size: 10);
    _text(c, 'fast walks 2× → slow lands on the middle',
        Offset(r.center.dx, r.bottom), _muted,
        size: 10);
  }

  /// Small tree with return-up arrows; the meeting node highlighted.
  void _postOrder(Canvas c, Rect r) {
    final rad = 15.0;
    final root = Offset(r.center.dx, r.top + rad + 4);
    final l = Offset(r.center.dx - 58, r.top + 66);
    final rr = Offset(r.center.dx + 58, r.top + 66);
    final ll = Offset(l.dx - 30, r.bottom - rad - 16);
    final lr = Offset(l.dx + 30, r.bottom - rad - 16);
    // edges
    for (final e in [
      [root, l],
      [root, rr],
      [l, ll],
      [l, lr],
    ]) {
      _line(c, e[0], e[1], _faint, w: 1.4);
    }
    // return-up arrows along the two subtrees
    _arrow(c, ll + Offset(6, -6), l + Offset(-6, 10), _green, w: 1.5);
    _arrow(c, rr + Offset(-4, -8), root + Offset(6, 10), _green, w: 1.5);
    void node(Offset o, Color fill, Color border, String s, Color fg) {
      c.drawCircle(o, rad, Paint()..color = fill);
      c.drawCircle(
          o,
          rad,
          Paint()
            ..color = border
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6);
      _text(c, s, o, fg, size: 11, weight: FontWeight.w700);
    }

    node(root, _greenFill, _green, 'LCA', _green);
    node(l, scheme.surfaceContainerHighest, _faint, '', _muted);
    node(rr, _primaryFill, _primary, 'q', _primary);
    node(ll, _primaryFill, _primary, 'p', _primary);
    node(lr, scheme.surfaceContainerHighest, _faint, '', _muted);
    _text(c, 'post-order: answers bubble up ↑',
        Offset(r.center.dx, r.bottom + 2), _muted,
        size: 10);
  }

  /// Sparse coordinate board: dots placed by (col,row), grouped by column.
  void _coordinate(Canvas c, Rect r) {
    const cols = 4;
    const rows = 3;
    final cw = (r.width - 6) / cols;
    final rh = (r.height - 30) / rows;
    // highlight active column band
    final activeCol = 1;
    _rrect(
      c,
      Rect.fromLTWH(r.left + activeCol * cw, r.top, cw, rows * rh),
      _primaryFill.withValues(alpha: 0.5),
      rad: 6,
    );
    // grid lines
    for (var i = 0; i <= cols; i++) {
      _line(c, Offset(r.left + i * cw, r.top),
          Offset(r.left + i * cw, r.top + rows * rh), _faint.withValues(alpha: 0.4),
          w: 1);
    }
    for (var j = 0; j <= rows; j++) {
      _line(c, Offset(r.left, r.top + j * rh),
          Offset(r.left + cols * cw, r.top + j * rh),
          _faint.withValues(alpha: 0.4),
          w: 1);
    }
    // dots at some (col,row)
    final dots = <List<int>>[
      [0, 0],
      [1, 1],
      [1, 2],
      [2, 1],
      [3, 2],
    ];
    for (final d in dots) {
      final o = Offset(r.left + (d[0] + 0.5) * cw, r.top + (d[1] + 0.5) * rh);
      c.drawCircle(o, 7, Paint()..color = d[0] == activeCol ? _primary : _muted);
    }
    _text(c, 'place at (col, row) · sort by (col,row,val)',
        Offset(r.center.dx, r.bottom - 2), _muted,
        size: 10);
  }

  /// Number line with grey intervals and one growing merged interval.
  void _interval(Canvas c, Rect r) {
    final y = r.center.dy;
    _line(c, Offset(r.left, y + 30), Offset(r.right, y + 30),
        _faint.withValues(alpha: 0.6));
    void bar(double a, double b, double dy, Color fill, Color border) {
      _rrect(c, Rect.fromLTWH(a, y + dy, b - a, 16), fill, border: border, rad: 5);
    }

    // existing intervals (grey)
    bar(r.left + 8, r.left + 60, -34, scheme.surfaceContainerHighest, _faint);
    bar(r.left + 78, r.left + 150, -34, scheme.surfaceContainerHighest, _faint);
    bar(r.left + 168, r.left + 230, -34, scheme.surfaceContainerHighest, _faint);
    // growing "toAdd" that swallows the middle two
    bar(r.left + 70, r.left + 240, 2, _amberFill, _amber);
    _text(c, 'toAdd', Offset(r.left + 155, y + 10), _amber,
        size: 10, weight: FontWeight.w700);
    _text(c, 'sort by start · merge overlaps into one',
        Offset(r.center.dx, r.top + 2), _muted,
        size: 10.5);
    _text(c, 'check the two NON-overlap cases first',
        Offset(r.center.dx, r.bottom + 2), _amber,
        size: 10, weight: FontWeight.w600);
  }

  /// Bars with two adjacent highlighted and a swap arc.
  void _adjacentSwap(Canvas c, Rect r) {
    final heights = [30.0, 54.0, 40.0, 66.0, 48.0, 24.0];
    final n = heights.length;
    final bw = 26.0;
    final gap = (r.width - n * bw) / (n - 1);
    final base = r.bottom - 22;
    for (var i = 0; i < n; i++) {
      final x = r.left + i * (bw + gap);
      final active = i == 1 || i == 2;
      _rrect(c, Rect.fromLTWH(x, base - heights[i], bw, heights[i]),
          active ? _amberFill : _primaryFill,
          border: active ? _amber : _primary);
    }
    final x1 = r.left + 1 * (bw + gap) + bw / 2;
    final x2 = r.left + 2 * (bw + gap) + bw / 2;
    final topY = base - 74;
    _arrow(c, Offset(x1, topY + 6), Offset(x2, topY + 6), _amber);
    _arrow(c, Offset(x2, topY + 16), Offset(x1, topY + 16), _amber);
    _text(c, 'swap if a[j] > a[j+1]', Offset(r.center.dx, r.top + 2), _amber,
        size: 10.5, weight: FontWeight.w600);
    _text(c, 'each pass bubbles the max to the end',
        Offset(r.center.dx, r.bottom + 2), _muted,
        size: 10);
  }

  /// Zigzag running sum crossing a dashed target line, with hit markers where
  /// it lands exactly on target and resets back to zero.
  void _runningSum(Canvas c, Rect r) {
    final targetY = r.top + r.height * 0.32;
    // dashed target line
    var dx = r.left;
    while (dx < r.right) {
      _line(c, Offset(dx, targetY), Offset(dx + 8, targetY), _faint, w: 1.2);
      dx += 14;
    }
    _text(c, 'target', Offset(r.right, targetY - 10), _muted,
        size: 10, align: TextAlign.right);

    // non-monotonic running-sum path: rises above target, dips back to it,
    // overshoots again, lands on it once more.
    final baseY = r.bottom - 10;
    final xs = [
      r.left,
      r.left + r.width * 0.22,
      r.left + r.width * 0.42,
      r.left + r.width * 0.64,
      r.left + r.width * 0.82,
      r.right,
    ];
    final ys = [
      baseY,
      targetY - 26,
      targetY, // first hit - reset
      targetY - 34,
      targetY,
      targetY, // second hit
    ];
    final path = Path()..moveTo(xs[0], ys[0]);
    for (var i = 1; i < xs.length; i++) {
      path.lineTo(xs[i], ys[i]);
    }
    c.drawPath(
      path,
      Paint()
        ..color = _primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8,
    );
    // hit markers where the path touches target
    for (final i in [2, 5]) {
      c.drawCircle(Offset(xs[i], ys[i]), 4.5, Paint()..color = _amber);
    }
    _text(c, 'runningSum == target → reset to 0',
        Offset(r.center.dx, r.bottom + 6), _amber,
        size: 10, weight: FontWeight.w600);
    _text(c, 'sum is not monotonic', Offset(r.left, r.top + 6), _muted,
        size: 10, align: TextAlign.left);
  }

  /// Mirrors the visualizer: gas / cost as cell rows, then runningGas plotted
  /// as signed bars around a zero baseline. Where a bar drops below the line
  /// the tank is reset and the candidate start jumps to the next station.
  void _gasStation(Canvas c, Rect r) {
    // Illustrative data (gas & cost non-negative): one clean dip at station 1.
    const gas = [4, 1, 2, 5];
    const cost = [1, 5, 1, 1];
    const run = [3, -1, 1, 5]; // gas−cost accumulated, reset after the −1
    const deficit = 1; // station where runningGas goes < 0
    const start = 2; // station right after the deficit = the answer
    const n = 4;

    const labelW = 32.0;
    const gap = 7.0;
    const cellH = 20.0;
    const rowGap = 6.0;
    final gridLeft = r.left + labelW;
    final cellW = ((r.right - gridLeft) - gap * (n - 1)) / n;
    double colX(int i) => gridLeft + i * (cellW + gap);
    double colCenter(int i) => colX(i) + cellW / 2;

    // ── gas / cost cell rows ────────────────────────────────────────────
    final rows = <(String, List<int>)>[('gas', gas), ('cost', cost)];
    final rowsTop = r.top + 16;
    for (var rIdx = 0; rIdx < rows.length; rIdx++) {
      final (name, vals) = rows[rIdx];
      final y = rowsTop + rIdx * (cellH + rowGap);
      _text(c, name, Offset(r.left, y + cellH / 2), _muted,
          size: 10, align: TextAlign.left);
      for (var i = 0; i < n; i++) {
        final rect = Rect.fromLTWH(colX(i), y, cellW, cellH);
        _rrect(c, rect, scheme.surfaceContainerHighest, border: _faint, rad: 5);
        _text(c, '${vals[i]}', rect.center, _muted,
            size: 11, weight: FontWeight.w700, mono: true);
      }
    }

    // ── runningGas baseline plot ────────────────────────────────────────
    final plotTop = rowsTop + 2 * (cellH + rowGap) + 6;
    final plotBottom = r.bottom - 4;
    final maxV = run.reduce((a, b) => a > b ? a : b);
    final minV = run.reduce((a, b) => a < b ? a : b);
    final range = (maxV - minV) == 0 ? 1 : (maxV - minV);
    final scale = (plotBottom - plotTop) / range;
    final zeroY = plotTop + maxV * scale;

    _text(c, 'run', Offset(r.left, zeroY), _muted, size: 10,
        align: TextAlign.left);

    // dashed zero baseline
    var dx = gridLeft;
    while (dx < r.right) {
      _line(c, Offset(dx, zeroY), Offset(dx + 8, zeroY), _faint, w: 1.2);
      dx += 14;
    }
    _text(c, '0', Offset(gridLeft - 4, zeroY), _muted, size: 9.5,
        align: TextAlign.right);

    final barW = cellW * 0.62;
    for (var i = 0; i < n; i++) {
      final v = run[i];
      final valY = zeroY - v * scale;
      final top = v >= 0 ? valY : zeroY;
      final h = (zeroY - valY).abs().clamp(2.0, double.infinity);
      Color fill = _primaryFill, border = _primary;
      if (i == deficit) {
        fill = _amberFill;
        border = _amber;
      } else if (i == start) {
        fill = _greenFill;
        border = _green;
      }
      _rrect(c, Rect.fromLTWH(colCenter(i) - barW / 2, top, barW, h),
          fill, border: border, rad: 4);
    }

    // annotations: reset target = the answer station
    final startValY = zeroY - run[start] * scale;
    _text(c, 'start', Offset(colCenter(start), startValY - 8), _green,
        size: 9.5, weight: FontWeight.w700);

    _text(c, 'runningGas drops below 0 → reset, start at next station',
        Offset(r.center.dx, r.bottom + 6), _green,
        size: 10, weight: FontWeight.w600);
  }

  void _generic(Canvas c, Rect r) {
    _rrect(c, r.deflate(30), scheme.surfaceContainerHighest, border: _faint);
    _text(c, pattern, r.center, _muted, size: 12, weight: FontWeight.w600);
  }

  @override
  bool shouldRepaint(_SchematicPainter old) =>
      old.pattern != pattern || old.scheme != scheme;
}
