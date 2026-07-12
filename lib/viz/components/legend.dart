import 'package:flutter/material.dart';

import 'viz_tokens.dart';

/// A compact legend mapping semantic [VizState]s to their swatch + label, so
/// the reader can decode the structure colors at a glance.
class Legend extends StatelessWidget {
  final List<VizState> states;

  /// Optional label overrides keyed by state (e.g. "in scope" → "lo..hi").
  final Map<VizState, String> labels;

  const Legend({
    super.key,
    required this.states,
    this.labels = const {},
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        for (final s in states)
          _item(scheme, s, labels[s] ?? vizStateLabel(s)),
      ],
    );
  }

  Widget _item(ColorScheme scheme, VizState state, String label) {
    final c = vizStateColors(scheme, state);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: c.fill,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: c.border, width: 1.5),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: scheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
