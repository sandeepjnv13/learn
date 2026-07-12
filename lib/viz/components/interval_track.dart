import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'viz_tokens.dart';

/// One interval bar drawn on a shared number line. [start]/[end] are domain
/// coordinates (not pixels); the [IntervalTrack] maps them to the track width.
class IntervalBar {
  final num start;
  final num end;

  /// Short lane label shown on the left (e.g. `toAdd`, `iv0`, `r1`).
  final String label;
  final VizState state;

  /// Emphasize as the interval currently being carried/merged (dashed halo).
  final bool isNew;

  const IntervalBar({
    required this.start,
    required this.end,
    required this.label,
    this.state = VizState.inScope,
    this.isNew = false,
  });
}

/// Structure primitive: a Gantt-style stack of interval bars sharing a single
/// number-line scale, one bar per lane. Bars glide/grow with the spring curve
/// when their coordinates change, so a merge visibly stretches the bar. Colored
/// by semantic [VizState]; self-sizing and theme-aware.
class IntervalTrack extends StatelessWidget {
  final List<IntervalBar> bars;
  final num domainMin;
  final num domainMax;
  final double laneLabelWidth;

  static const double _laneH = 44;

  const IntervalTrack({
    super.key,
    required this.bars,
    required this.domainMin,
    required this.domainMax,
    this.laneLabelWidth = 80,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final span = math.max(1e-9, (domainMax - domainMin).toDouble());

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _axis(context, scheme, span),
        const SizedBox(height: 6),
        for (final bar in bars) _lane(context, scheme, bar, span),
      ],
    );
  }

  double _px(num v, double width, double span) =>
      ((v - domainMin) / span) * width;

  Widget _axis(BuildContext context, ColorScheme scheme, double span) {
    final ticks = _ticks();
    final labelColor = scheme.onSurfaceVariant.withValues(alpha: 0.75);
    return Row(
      children: [
        SizedBox(width: laneLabelWidth),
        Expanded(
          child: LayoutBuilder(
            builder: (context, c) {
              final w = c.maxWidth;
              return SizedBox(
                height: 22,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    for (final t in ticks)
                      Positioned(
                        left: _px(t, w, span) - 16,
                        top: 0,
                        width: 32,
                        child: Column(
                          children: [
                            Text(
                              _fmt(t),
                              textAlign: TextAlign.center,
                              style: AppTheme.mono(context,
                                  size: 11, color: labelColor),
                            ),
                            Container(
                              width: 1,
                              height: 5,
                              color: scheme.outlineVariant,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _lane(
    BuildContext context,
    ColorScheme scheme,
    IntervalBar bar,
    double span,
  ) {
    final c = vizStateColors(scheme, bar.state);
    final emphatic = bar.isNew ||
        bar.state == VizState.processing ||
        bar.state == VizState.found;
    return SizedBox(
      height: _laneH,
      child: Row(
        children: [
          SizedBox(
            width: laneLabelWidth,
            child: Text(
              bar.label,
              textAlign: TextAlign.right,
              style: AppTheme.mono(context, size: 12, color: c.foreground)
                  .copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: LayoutBuilder(
              builder: (context, cons) {
                final w = cons.maxWidth;
                final left = _px(bar.start, w, span);
                final right = _px(bar.end, w, span);
                final barW = math.max(right - left, 6.0);
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // number-line baseline
                    Positioned(
                      left: 0,
                      right: 0,
                      top: _laneH / 2 - 1,
                      child: Container(
                        height: 2,
                        color: scheme.outlineVariant.withValues(alpha: 0.6),
                      ),
                    ),
                    AnimatedPositioned(
                      duration: VizTokens.moveDuration,
                      curve: VizTokens.spring,
                      left: left,
                      top: 8,
                      width: barW,
                      height: _laneH - 16,
                      child: AnimatedContainer(
                        duration: VizTokens.moveDuration,
                        curve: VizTokens.spring,
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
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              '[${_fmt(bar.start)}, ${_fmt(bar.end)}]',
                              style: AppTheme.mono(context,
                                      size: 13, color: c.foreground)
                                  .copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<num> _ticks() {
    final range = (domainMax - domainMin).toDouble();
    if (range <= 0) return [domainMin];
    const nice = [1, 2, 5, 10, 20, 25, 50, 100, 200, 500, 1000];
    double step = nice.last.toDouble();
    for (final s in nice) {
      if (range / s <= 10) {
        step = s.toDouble();
        break;
      }
    }
    final start = (domainMin / step).ceil() * step;
    final ticks = <num>[];
    for (var t = start; t <= domainMax + 1e-9; t += step) {
      ticks.add(t);
    }
    return ticks;
  }

  String _fmt(num n) => n is int || n == n.roundToDouble()
      ? n.toInt().toString()
      : n.toString();
}
