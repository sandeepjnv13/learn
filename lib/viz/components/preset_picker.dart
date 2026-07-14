import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'viz_tokens.dart';

/// One selectable preset example for a visualizer.
///
/// A preset is just a *label* the learner sees in the dropdown; the composing
/// view owns the actual payload (the array / string / tree it loads). Mark the
/// **frequently-missed edge cases** with `edgeCase: true` so they read as the
/// tests worth studying, not just more happy-path inputs.
class VizPreset {
  /// Short menu title, e.g. `'Strictly decreasing'`.
  final String label;

  /// One-line explanation of what makes this example interesting, e.g.
  /// `'nothing resolves until the very end — the stack fills up'`.
  final String? detail;

  /// When true, badges the item as a frequently-missed edge case.
  final bool edgeCase;

  const VizPreset(this.label, {this.detail, this.edgeCase = false});
}

/// A dropdown of preset examples, styled to sit next to the editable input
/// fields in a [ControlBar]. Selecting an item calls [onSelected] with its
/// index; the view then loads that preset (usually by writing the input
/// controllers and re-running the recorder). Editing the loaded values is still
/// allowed — a preset is a *starting point*, not a lock.
///
/// This is a shared control: **every** step-by-step visualizer with editable
/// input should offer one (3–4 presets plus the most-missed edge cases).
class PresetPicker extends StatelessWidget {
  final List<VizPreset> presets;
  final void Function(int index) onSelected;
  final String label;

  const PresetPicker({
    super.key,
    required this.presets,
    required this.onSelected,
    this.label = 'Examples',
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return PopupMenuButton<int>(
      tooltip: 'Load a preset example',
      position: PopupMenuPosition.under,
      onSelected: onSelected,
      constraints: const BoxConstraints(minWidth: 300, maxWidth: 400),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(VizTokens.radius),
      ),
      itemBuilder: (context) => [
        for (var i = 0; i < presets.length; i++)
          PopupMenuItem<int>(
            value: i,
            child: _item(context, scheme, presets[i]),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: scheme.outline.withValues(alpha: 0.6)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome_motion_rounded,
                size: 18, color: scheme.primary),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
            ),
            Icon(Icons.arrow_drop_down_rounded, color: scheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  Widget _item(BuildContext context, ColorScheme scheme, VizPreset p) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  p.label,
                  style: AppTheme.mono(context, size: 13, color: scheme.onSurface)
                      .copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              if (p.edgeCase) ...[
                const SizedBox(width: 8),
                _edgeChip(scheme),
              ],
            ],
          ),
          if (p.detail != null) ...[
            const SizedBox(height: 3),
            Text(
              p.detail!,
              style: TextStyle(
                fontSize: 12,
                height: 1.25,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _edgeChip(ColorScheme scheme) {
    final c = scheme.tertiary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        'edge case',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: c,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
