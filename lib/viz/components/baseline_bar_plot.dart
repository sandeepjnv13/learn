import 'package:flutter/material.dart';

import 'fit_to_width.dart';
import 'viz_tokens.dart';

/// Structure primitive: a bar plot around a **zero baseline**. Positive values
/// rise above the line, negative values drop below it, each bar colored by a
/// semantic [VizState]. Column geometry matches [ArrayCells] (56px cell, 10px
/// gap) so a plot stacked under gas/cost rows lines up column-for-column.
///
/// Used for running-total style values (e.g. the gas-station `runningGas`)
/// where the whole point is *where the line crosses below zero*.
class BaselineBarPlot extends StatelessWidget {
  final List<num> values;

  /// State per index; missing indices default to [VizState.inactive].
  final Map<int, VizState> states;

  /// Total plot height (bars + axis labels).
  final double height;

  const BaselineBarPlot({
    super.key,
    required this.values,
    this.states = const {},
    this.height = 168,
  });

  static const double _colW = 56;
  static const double _gap = 10;
  double get _stride => _colW + _gap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final totalW = values.isEmpty ? 0.0 : values.length * _stride - _gap;
    return FitToWidth(
      naturalWidth: totalW,
      naturalHeight: height,
      child: CustomPaint(
        size: Size(totalW, height),
        painter: _BarPainter(
          values: values,
          states: states,
          scheme: scheme,
          colW: _colW,
          stride: _stride,
        ),
      ),
    );
  }
}

class _BarPainter extends CustomPainter {
  final List<num> values;
  final Map<int, VizState> states;
  final ColorScheme scheme;
  final double colW;
  final double stride;

  _BarPainter({
    required this.values,
    required this.states,
    required this.scheme,
    required this.colW,
    required this.stride,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    const topPad = 18.0; // room for value labels above positive bars
    const botPad = 20.0; // room for index labels under the axis
    final plotTop = topPad;
    final plotBottom = size.height - botPad;

    final maxV = values.reduce((a, b) => a > b ? a : b);
    final minV = values.reduce((a, b) => a < b ? a : b);
    final posMax = maxV > 0 ? maxV : 0;
    final negMin = minV < 0 ? minV : 0;
    final range = (posMax - negMin) == 0 ? 1 : (posMax - negMin);
    final scale = (plotBottom - plotTop) / range;
    final zeroY = plotTop + posMax * scale;

    // Zero baseline (dashed) across the full width.
    final faint = scheme.outlineVariant;
    var dx = 0.0;
    while (dx < size.width) {
      canvas.drawLine(
        Offset(dx, zeroY),
        Offset(dx + 8, zeroY),
        Paint()
          ..color = faint
          ..strokeWidth = 1.2,
      );
      dx += 14;
    }
    _text(canvas, '0', Offset(-4, zeroY), scheme.onSurfaceVariant,
        align: TextAlign.right);

    const barW = 34.0;
    for (var i = 0; i < values.length; i++) {
      final v = values[i];
      final cx = i * stride + colW / 2;
      final valY = zeroY - v * scale;
      final state = states[i] ?? VizState.inactive;
      final c = vizStateColors(scheme, state);

      final top = v >= 0 ? valY : zeroY;
      final bottom = v >= 0 ? zeroY : valY;
      final rect = Rect.fromLTWH(cx - barW / 2, top, barW, (bottom - top).abs());
      final rr = RRect.fromRectAndCorners(
        rect.height < 2
            ? Rect.fromLTWH(rect.left, rect.top - 1, rect.width, 2)
            : rect,
        topLeft: Radius.circular(v >= 0 ? 5 : 0),
        topRight: Radius.circular(v >= 0 ? 5 : 0),
        bottomLeft: Radius.circular(v >= 0 ? 0 : 5),
        bottomRight: Radius.circular(v >= 0 ? 0 : 5),
      );
      canvas.drawRRect(rr, Paint()..color = c.fill);
      canvas.drawRRect(
        rr,
        Paint()
          ..color = c.border
          ..style = PaintingStyle.stroke
          ..strokeWidth =
              state == VizState.processing || state == VizState.found ? 2 : 1.2,
      );

      // Value label just outside the bar end.
      _text(
        canvas,
        '$v',
        Offset(cx, v >= 0 ? valY - 9 : valY + 9),
        c.border,
        weight: FontWeight.w700,
      );
      // Index label under the axis.
      _text(canvas, '$i', Offset(cx, size.height - 8),
          scheme.onSurfaceVariant.withValues(alpha: 0.6),
          size: 11);
    }
  }

  void _text(Canvas c, String s, Offset at, Color color,
      {double size = 12,
      FontWeight weight = FontWeight.w600,
      TextAlign align = TextAlign.center}) {
    final tp = TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(
          color: color,
          fontSize: size,
          fontWeight: weight,
          fontFamily: 'monospace',
          height: 1.1,
        ),
      ),
      textAlign: align,
      textDirection: TextDirection.ltr,
    )..layout();
    Offset origin;
    if (align == TextAlign.right) {
      origin = at - Offset(tp.width, tp.height / 2);
    } else {
      origin = at - Offset(tp.width / 2, tp.height / 2);
    }
    tp.paint(c, origin);
  }

  @override
  bool shouldRepaint(covariant _BarPainter old) =>
      old.values != values || old.states != states || old.scheme != scheme;
}
