import 'package:flutter/material.dart';

/// Shrinks a **fixed-size structure visual** (a row of array cells, a chain of
/// linked-list nodes, a set of tree nodes …) down uniformly so it always fits
/// the available width instead of overflowing into a horizontal scrollbar.
///
/// This is the generic answer to "too many inputs make the visualizer
/// side-scroll": when the natural width exceeds what the stage offers, the
/// **elements themselves** are scaled to fit the page; only the data visual
/// resizes — the surrounding panels, controls and step tracker are untouched.
/// The visual is never enlarged past its natural size, and it is centered in
/// the available space when it already fits.
///
/// Callers pass the visual's intrinsic [naturalWidth]/[naturalHeight] (which a
/// structure primitive always knows from its element geometry) and the
/// fixed-size [child]. Scaling is width-driven and aspect-preserving, so the
/// row reserves exactly `naturalHeight * scale` of vertical space — no
/// distortion, no clipping (the inner [FittedBox] keeps `Clip.none` so gliding
/// pointer lanes and healed arcs that paint outside the box stay visible).
class FitToWidth extends StatelessWidget {
  /// Intrinsic width of [child] at 1:1 scale.
  final double naturalWidth;

  /// Intrinsic height of [child] at 1:1 scale.
  final double naturalHeight;

  /// The fixed-size structure visual to scale down when needed.
  final Widget child;

  /// Horizontal placement within the available width when the visual fits
  /// (defaults to centered, matching the app's stage convention).
  final Alignment alignment;

  const FitToWidth({
    super.key,
    required this.naturalWidth,
    required this.naturalHeight,
    required this.child,
    this.alignment = Alignment.center,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final avail = c.maxWidth;
        final scale = (avail.isFinite && naturalWidth > avail && naturalWidth > 0)
            ? avail / naturalWidth
            : 1.0;
        final sized = SizedBox(
          width: naturalWidth,
          height: naturalHeight,
          child: child,
        );
        // Reserve the scaled height so the visual sits in normal flow, and
        // center it horizontally when there is spare room.
        return SizedBox(
          height: naturalHeight * scale,
          child: Align(
            alignment: alignment,
            child: SizedBox(
              width: naturalWidth * scale,
              height: naturalHeight * scale,
              child: scale == 1.0
                  ? sized
                  : FittedBox(fit: BoxFit.fill, child: sized),
            ),
          ),
        );
      },
    );
  }
}
