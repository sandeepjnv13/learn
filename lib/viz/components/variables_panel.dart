import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'panel.dart';
import 'viz_tokens.dart';

/// A single named variable and its current value.
class VizVar {
  final String name;
  final String value;

  /// Whether this variable changed on the current step (triggers a pulse).
  final bool changed;

  const VizVar(this.name, this.value, {this.changed = false});
}

/// Live key variables, each rendered as a [PulseChip] that flashes when its
/// value changes.
class VariablesPanel extends StatelessWidget {
  final List<VizVar> vars;
  final String title;

  const VariablesPanel({
    super.key,
    required this.vars,
    this.title = 'Variables',
  });

  @override
  Widget build(BuildContext context) {
    return Panel(
      title: title,
      icon: Icons.data_object_rounded,
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          for (final v in vars)
            PulseChip(
              key: ValueKey(v.name),
              name: v.name,
              value: v.value,
              pulse: v.changed,
            ),
        ],
      ),
    );
  }
}

/// A `name value` chip that briefly flashes (scale + color) when [pulse] flips
/// or [value] changes, drawing the eye to the update.
class PulseChip extends StatefulWidget {
  final String name;
  final String value;
  final bool pulse;

  const PulseChip({
    super.key,
    required this.name,
    required this.value,
    required this.pulse,
  });

  @override
  State<PulseChip> createState() => _PulseChipState();
}

class _PulseChipState extends State<PulseChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: VizTokens.pulseDuration,
  );

  @override
  void initState() {
    super.initState();
    if (widget.pulse) _c.forward(from: 0);
  }

  @override
  void didUpdateWidget(covariant PulseChip old) {
    super.didUpdateWidget(old);
    if (widget.pulse && (old.value != widget.value || !old.pulse)) {
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final t = Curves.easeOut.transform(1 - _c.value); // 1 → 0
        final scale = 1 + 0.08 * t;
        final glow = scheme.primary.withValues(alpha: 0.5 * t);
        return Transform.scale(
          scale: scale,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Color.lerp(
                scheme.surfaceContainerHighest,
                scheme.primaryContainer,
                t,
              ),
              borderRadius: BorderRadius.circular(VizTokens.radius),
              border: Border.all(
                color: Color.lerp(scheme.outlineVariant, scheme.primary, t)!,
              ),
              boxShadow: [
                if (t > 0)
                  BoxShadow(color: glow, blurRadius: 12 * t, spreadRadius: t),
              ],
            ),
            child: child,
          ),
        );
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.name,
            style: AppTheme.mono(
              context,
              size: 12,
              color: scheme.onSurfaceVariant,
            ).copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 8),
          Text(
            widget.value,
            style: AppTheme.mono(context, size: 14, color: scheme.onSurface)
                .copyWith(
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
