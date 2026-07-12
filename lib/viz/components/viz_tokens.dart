import 'package:flutter/material.dart';

/// Shared design tokens for native visualizers: semantic state colors, the
/// spring easing curve, and standard geometry. Every component and structure
/// primitive pulls from here so the whole kit reads as one system in both
/// light and dark themes.
class VizTokens {
  VizTokens._();

  /// Springy overshoot used on box/node transitions and pulses.
  static const Curve spring = Cubic(0.34, 1.56, 0.64, 1.0);

  static const Duration moveDuration = Duration(milliseconds: 420);
  static const Duration pulseDuration = Duration(milliseconds: 260);

  static const double radius = 12;
  static const double panelGap = 16;
}

/// Semantic states shared across every structure primitive. Colors are derived
/// from the active [ColorScheme] plus a couple of fixed semantic hues so they
/// stay legible on light and dark backgrounds.
enum VizState {
  /// Not part of the current working set (e.g. outside lo..hi).
  inactive,

  /// In the active window / in scope.
  inScope,

  /// Currently being examined (mid, current node, i/j).
  processing,

  /// Ruled out this step (discarded / visited).
  discarded,

  /// The successful result.
  found,

  /// Terminal failure.
  notFound,
}

/// A resolved color triple for a state: fill, border, and foreground (text).
class VizStateColors {
  final Color fill;
  final Color border;
  final Color foreground;
  const VizStateColors(this.fill, this.border, this.foreground);
}

VizStateColors vizStateColors(ColorScheme scheme, VizState state) {
  final dark = scheme.brightness == Brightness.dark;

  // Fixed semantic hues that read well in both themes.
  final amber = dark ? const Color(0xFFF0B429) : const Color(0xFFB77400);
  final amberFill = dark
      ? const Color(0xFF4A3A12)
      : const Color(0xFFFFF3D6);
  final green = dark ? const Color(0xFF4ADE80) : const Color(0xFF15803D);
  final greenFill = dark
      ? const Color(0xFF12351F)
      : const Color(0xFFDCFCE7);
  final red = dark ? const Color(0xFFF87171) : const Color(0xFFB91C1C);
  final redFill = dark ? const Color(0xFF3F1D1D) : const Color(0xFFFEE2E2);

  switch (state) {
    case VizState.inactive:
      return VizStateColors(
        scheme.surfaceContainerHighest,
        scheme.outlineVariant,
        scheme.onSurface,
      );
    case VizState.inScope:
      return VizStateColors(
        scheme.primaryContainer,
        scheme.primary,
        scheme.onPrimaryContainer,
      );
    case VizState.processing:
      return VizStateColors(amberFill, amber, amber);
    case VizState.discarded:
      return VizStateColors(
        scheme.surfaceContainerHigh.withValues(alpha: 0.5),
        scheme.outlineVariant.withValues(alpha: 0.5),
        scheme.onSurfaceVariant.withValues(alpha: 0.5),
      );
    case VizState.found:
      return VizStateColors(greenFill, green, green);
    case VizState.notFound:
      return VizStateColors(redFill, red, red);
  }
}

/// Human-readable label for a state, used by legends.
String vizStateLabel(VizState state) {
  switch (state) {
    case VizState.inactive:
      return 'Untouched';
    case VizState.inScope:
      return 'In scope';
    case VizState.processing:
      return 'Examining';
    case VizState.discarded:
      return 'Discarded';
    case VizState.found:
      return 'Found';
    case VizState.notFound:
      return 'Not found';
  }
}
