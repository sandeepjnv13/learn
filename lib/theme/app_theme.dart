import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Clean, modern, docs-style theme with light + dark variants.
class AppTheme {
  static const _seed = Color(0xFF4F46E5); // indigo

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: brightness,
    );

    final baseText = GoogleFonts.interTextTheme(
      ThemeData(brightness: brightness).textTheme,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      textTheme: baseText.copyWith(
        headlineMedium: baseText.headlineMedium?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        titleLarge: baseText.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        bodyLarge: baseText.bodyLarge?.copyWith(height: 1.6),
        bodyMedium: baseText.bodyMedium?.copyWith(height: 1.6),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: 0.5),
        thickness: 1,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.6)),
        ),
      ),
    );
  }

  /// Monospace style for code and visualizer labels.
  static TextStyle mono(BuildContext context, {double? size, Color? color}) {
    return GoogleFonts.jetBrainsMono(
      fontSize: size ?? 14,
      color: color ?? Theme.of(context).colorScheme.onSurface,
    );
  }
}
