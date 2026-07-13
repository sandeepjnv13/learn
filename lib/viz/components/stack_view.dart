import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'fit_to_width.dart';
import 'viz_tokens.dart';

/// Structure primitive: a **horizontal** LIFO stack. Elements are given
/// **bottom → top** (index 0 is the bottom, the last element is the current
/// top). Bottom sits on the left, the stack grows to the right, and the single
/// **top** slot — where *both* a push and a pop happen — is marked with a
/// subtle accent band plus a "top • push/pop" tag.
///
/// Presentation adapts to the data:
/// * **all-numeric** values render as **normalised bars** (height ∝ value,
///   capped so the stack never grows tall) — ideal for monotonic-stack problems
///   where you want to *see* the increasing/decreasing shape;
/// * anything else (e.g. bracket characters) renders as labelled **cells**.
///
/// Each element is colored by a semantic [VizState] and animates on change with
/// the shared spring curve. Like the other primitives it **self-fits** via
/// [FitToWidth]: a long stack shrinks to fit the page rather than side-scrolling.
class StackView extends StatelessWidget {
  /// Stack contents, bottom (index 0) → top (last). Numbers render as bars;
  /// other values (short strings) render as cells.
  final List<Object> values;

  /// State per index; missing indices default to [VizState.inScope] (a resting
  /// element currently on the stack).
  final Map<int, VizState> states;

  /// Text shown in the tag marking the top-of-stack (push/pop) slot.
  final String topLabel;

  /// Optional small caption rendered under each cell (e.g. the element's
  /// original array index for a monotonic stack). Keyed by stack index.
  final Map<int, String> captions;

  /// Placeholder shown when the stack is empty.
  final String emptyLabel;

  /// Reference maximum used to normalise bar heights so the *same value keeps
  /// the same height across steps*. Defaults to the max of [values]. Pass the
  /// whole input's max from the view for a stable scale.
  final num? barMax;

  const StackView({
    super.key,
    required this.values,
    this.states = const {},
    this.topLabel = 'top',
    this.captions = const {},
    this.emptyLabel = 'empty stack',
    this.barMax,
  });

  static const double _cellW = 58;
  static const double _gap = 12;
  static const double _cellH = 48; // cell mode element height
  static const double _labelH = 16; // value-label row (bar mode)
  static const double _maxBarH = 80; // tallest bar (normalised cap)
  static const double _minBarH = 14; // shortest visible bar
  static const double _captionH = 18;
  static const double _markerH = 26;
  static const double _bandPad = 5; // horizontal padding of the head band

  /// The head band / top tag glide should read as a calm slide, not the springy
  /// overshoot the elements use — an overshoot makes the marker look jittery.
  static const Curve _glide = Curves.easeInOutCubic;

  double get _stride => _cellW + _gap;
  bool get _barMode => values.isNotEmpty && values.every((v) => v is num);
  int get _topSlot => values.isEmpty ? 0 : values.length - 1;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final n = values.length;
    final cols = n == 0 ? 1 : n;
    final hasCaption = captions.isNotEmpty;
    final captionH = hasCaption ? _captionH : 0.0;

    // Vertical bands of the layout, top → bottom.
    final elementTop = _barMode ? _labelH : 0.0;
    final elementH = _barMode ? _maxBarH : _cellH;
    final baseline = elementTop + elementH; // bottom of the element region
    final captionTop = baseline + 4;
    final markerTop = captionTop + captionH;

    final naturalW = cols * _stride - _gap;
    final naturalH = markerTop + _markerH;

    // Normalisation reference for bar heights.
    final ref = _barMode
        ? math.max(
            (barMax ?? 1).toDouble(),
            values
                .whereType<num>()
                .fold<double>(1, (m, v) => math.max(m, v.toDouble())),
          )
        : 1.0;

    return FitToWidth(
      naturalWidth: naturalW,
      naturalHeight: naturalH,
      child: SizedBox(
        width: naturalW,
        height: naturalH,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Subtle accent band marking the top (push/pop) slot.
            AnimatedPositioned(
              duration: VizTokens.moveDuration,
              curve: _glide,
              left: _topSlot * _stride - _bandPad,
              top: 0,
              width: _cellW + _bandPad * 2,
              height: naturalH,
              child: _headBand(scheme),
            ),

            // Baseline the bars stand on (bar mode only).
            if (_barMode)
              Positioned(
                left: 0,
                top: baseline,
                width: naturalW,
                height: 1,
                child: Container(color: scheme.outlineVariant),
              ),

            if (n == 0)
              Positioned(
                left: 0,
                top: elementTop,
                width: _cellW,
                height: elementH,
                child: _emptyBox(context, scheme),
              ),

            // Elements.
            for (var i = 0; i < n; i++)
              if (_barMode)
                AnimatedPositioned(
                  key: ValueKey('bar$i'),
                  duration: VizTokens.moveDuration,
                  curve: VizTokens.spring,
                  left: i * _stride,
                  top: baseline - _barHeight((values[i] as num).toDouble(), ref),
                  width: _cellW,
                  height: _barHeight((values[i] as num).toDouble(), ref),
                  child: _bar(context, scheme, i),
                )
              else
                AnimatedPositioned(
                  key: ValueKey('cell$i'),
                  duration: VizTokens.moveDuration,
                  curve: VizTokens.spring,
                  left: i * _stride,
                  top: elementTop,
                  width: _cellW,
                  height: elementH,
                  child: _cell(context, scheme, i),
                ),

            // Value labels aligned in a row above the bars (bar mode).
            if (_barMode)
              for (var i = 0; i < n; i++)
                Positioned(
                  left: i * _stride,
                  top: 0,
                  width: _cellW,
                  height: _labelH,
                  child: Center(child: _valueLabel(context, scheme, i)),
                ),

            // Captions under each element.
            for (var i = 0; i < n; i++)
              if (captions[i] != null)
                Positioned(
                  left: i * _stride,
                  top: captionTop,
                  width: _cellW,
                  height: captionH,
                  child: Center(child: _caption(context, scheme, captions[i]!)),
                ),

            // Top (push/pop) tag under the head slot.
            AnimatedPositioned(
              duration: VizTokens.moveDuration,
              curve: _glide,
              left: _topSlot * _stride - _bandPad,
              top: markerTop,
              width: _cellW + _bandPad * 2,
              height: _markerH,
              child: Center(child: _topTag(context, scheme, empty: n == 0)),
            ),
          ],
        ),
      ),
    );
  }

  double _barHeight(double value, double ref) {
    final frac = (value / ref).clamp(0.0, 1.0);
    return _minBarH + frac * (_maxBarH - _minBarH);
  }

  // ── Pieces ──────────────────────────────────────────────────────────────

  Widget _headBand(ColorScheme scheme) {
    // A soft, borderless wash so it frames the top slot without introducing a
    // second outline that fights the element's own border.
    final accent = scheme.tertiary;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(VizTokens.radius + 3),
      ),
    );
  }

  Widget _bar(BuildContext context, ColorScheme scheme, int i) {
    final state = states[i] ?? VizState.inScope;
    final c = vizStateColors(scheme, state);
    final emphatic = state == VizState.processing || state == VizState.found;
    return AnimatedContainer(
      duration: VizTokens.moveDuration,
      curve: VizTokens.spring,
      decoration: BoxDecoration(
        color: c.fill,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
        border: Border.all(color: c.border, width: emphatic ? 2 : 1),
        boxShadow: [
          if (emphatic)
            BoxShadow(
              color: c.border.withValues(alpha: 0.35),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
        ],
      ),
    );
  }

  Widget _valueLabel(BuildContext context, ColorScheme scheme, int i) {
    final c = vizStateColors(scheme, states[i] ?? VizState.inScope);
    return Text(
      '${values[i]}',
      style: AppTheme.mono(context, size: 13, color: c.foreground)
          .copyWith(fontWeight: FontWeight.w700),
    );
  }

  Widget _cell(BuildContext context, ColorScheme scheme, int i) {
    final state = states[i] ?? VizState.inScope;
    final c = vizStateColors(scheme, state);
    final emphatic = state == VizState.processing || state == VizState.found;
    return AnimatedContainer(
      duration: VizTokens.moveDuration,
      curve: VizTokens.spring,
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
            .copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _emptyBox(BuildContext context, ColorScheme scheme) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(VizTokens.radius),
        border: Border.all(color: scheme.outlineVariant),
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
      ),
      child: Text(
        emptyLabel,
        textAlign: TextAlign.center,
        style: AppTheme.mono(
          context,
          size: 10,
          color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
        ),
      ),
    );
  }

  Widget _caption(BuildContext context, ColorScheme scheme, String text) {
    return Text(
      text,
      maxLines: 1,
      style: AppTheme.mono(
        context,
        size: 11,
        color: scheme.onSurfaceVariant.withValues(alpha: 0.65),
      ),
    );
  }

  Widget _topTag(BuildContext context, ColorScheme scheme,
      {required bool empty}) {
    // Compact pill sized to its content and centered on the top column — the ⇅
    // icon conveys that push and pop share this end. Tooltip carries the detail
    // so the label stays short enough to sit within the column width.
    final color = scheme.tertiary;
    return Tooltip(
      message: empty
          ? 'Top of stack — the next push lands here'
          : 'Top of stack — push and pop both happen here',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.unfold_more_rounded, size: 14, color: color),
            const SizedBox(width: 3),
            Text(
              topLabel,
              style: AppTheme.mono(context, size: 11, color: color)
                  .copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
