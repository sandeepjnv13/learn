import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'fit_to_width.dart';
import 'viz_tokens.dart';

/// A labelled pointer that hovers over one cell (lo / hi / mid / i / j …) and
/// glides horizontally as its [index] changes.
class ArrayPointer {
  final String label;
  final int index;

  /// Optional color; defaults to the scheme's tertiary.
  final Color? color;

  const ArrayPointer(this.label, this.index, {this.color});
}

/// Structure primitive: a horizontal row of value cells, each colored by a
/// semantic [VizState], with a lane of gliding [pointers] above. Cells animate
/// their color/scale on state change with spring easing.
class ArrayCells extends StatelessWidget {
  final List<num> values;

  /// State per index; missing indices default to [VizState.inactive].
  final Map<int, VizState> states;
  final List<ArrayPointer> pointers;

  static const double _cellW = 56;
  static const double _gap = 10;
  static const double _laneRowH = 26;
  static const double _idxLabelH = 17; // index caption below each cell
  static const double _cellGapH = 6; // gap between cell and its index caption

  const ArrayCells({
    super.key,
    required this.values,
    this.states = const {},
    this.pointers = const [],
  });

  double get _stride => _cellW + _gap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final laneH = pointers.isEmpty ? 0.0 : pointers.length * _laneRowH;
    final gapAboveCells = pointers.isEmpty ? 0.0 : 6.0;
    final totalW = values.isEmpty ? 0.0 : values.length * _stride - _gap;
    final totalH =
        laneH + gapAboveCells + _cellW + _cellGapH + _idxLabelH + 8;

    // Scale the cells down to fit the available width instead of overflowing
    // into a horizontal scroll when there are many elements.
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
            SizedBox(height: gapAboveCells),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < values.length; i++) ...[
                  _cell(context, scheme, i),
                  if (i != values.length - 1) const SizedBox(width: _gap),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _pointer(
    BuildContext context,
    ColorScheme scheme,
    ArrayPointer ptr,
    int slot,
  ) {
    final color = ptr.color ?? scheme.tertiary;
    final visible = ptr.index >= 0 && ptr.index < values.length;
    return AnimatedPositioned(
      duration: VizTokens.moveDuration,
      curve: VizTokens.spring,
      left: (visible ? ptr.index : 0) * _stride,
      top: slot * _laneRowH,
      width: _cellW,
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

  Widget _cell(BuildContext context, ColorScheme scheme, int i) {
    final state = states[i] ?? VizState.inactive;
    final c = vizStateColors(scheme, state);
    final emphatic =
        state == VizState.processing || state == VizState.found;
    return Column(
      children: [
        AnimatedContainer(
          duration: VizTokens.moveDuration,
          curve: VizTokens.spring,
          width: _cellW,
          height: _cellW,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: c.fill,
            borderRadius: BorderRadius.circular(VizTokens.radius),
            border: Border.all(
              color: c.border,
              width: emphatic ? 2 : 1,
            ),
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
                .copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '$i',
          style: AppTheme.mono(
            context,
            size: 11,
            color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}
