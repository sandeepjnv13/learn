import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'recursion_model.dart';
import 'viz_tokens.dart';

export 'recursion_model.dart';

extension RecursionPhaseView on RecursionPhase {
  String get label {
    switch (this) {
      case RecursionPhase.descend:
        return 'DESCEND - go into a subtree';
      case RecursionPhase.base:
        return 'BASE CASE - return without recursing';
      case RecursionPhase.combine:
        return 'COMBINE - merge the children’s results';
      case RecursionPhase.returnUp:
        return 'RETURN - hand the answer up to the caller';
    }
  }

  IconData get icon {
    switch (this) {
      case RecursionPhase.descend:
        return Icons.south_rounded;
      case RecursionPhase.base:
        return Icons.flag_rounded;
      case RecursionPhase.combine:
        return Icons.merge_rounded;
      case RecursionPhase.returnUp:
        return Icons.north_rounded;
    }
  }
}

/// A prominent pill announcing the current [RecursionPhase]. The single most
/// important cue for "are we going down or coming back up" - the thing that
/// makes recursion legible. Reused by every recursion visualizer.
class RecursionPhaseChip extends StatelessWidget {
  final RecursionPhase phase;

  const RecursionPhaseChip({super.key, required this.phase});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final (fg, bg) = switch (phase) {
      RecursionPhase.descend => (
          scheme.primary,
          scheme.primary.withValues(alpha: dark ? 0.20 : 0.12),
        ),
      RecursionPhase.base => (
          dark ? const Color(0xFFF0B429) : const Color(0xFFB77400),
          (dark ? const Color(0xFFF0B429) : const Color(0xFFB77400))
              .withValues(alpha: dark ? 0.20 : 0.14),
        ),
      RecursionPhase.combine => (
          scheme.tertiary,
          scheme.tertiary.withValues(alpha: dark ? 0.22 : 0.14),
        ),
      RecursionPhase.returnUp => (
          dark ? const Color(0xFF4ADE80) : const Color(0xFF15803D),
          (dark ? const Color(0xFF4ADE80) : const Color(0xFF15803D))
              .withValues(alpha: dark ? 0.20 : 0.14),
        ),
    };
    return AnimatedSwitcher(
      duration: VizTokens.moveDuration,
      switchInCurve: VizTokens.spring,
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.94, end: 1).animate(anim),
          child: child,
        ),
      ),
      child: Container(
        key: ValueKey(phase),
        height: 40,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(VizTokens.radius),
          border: Border.all(color: fg.withValues(alpha: 0.45)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(phase.icon, size: 16, color: fg),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                phase.label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                  color: fg,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The star panel of every recursion visualizer: the live **call stack**,
/// newest (currently-executing) frame on top, growing as calls descend and
/// shrinking as they return. Each card shows the frame's arguments, its locals
/// (pending vs resolved), and its return value once it returns. Purely a render
/// of the step's frame snapshot - no algorithm logic lives here.
class CallStackPanel extends StatelessWidget {
  final List<RecursionFrame> frames;
  final String title;

  const CallStackPanel({
    super.key,
    required this.frames,
    this.title = 'Call stack',
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(VizTokens.radius + 2),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.7)),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _header(scheme),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: frames.isEmpty
                ? _empty(context, scheme)
                : ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 260),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        // Newest frame (top of the recursion) rendered first.
                        children: [
                          for (var d = frames.length - 1; d >= 0; d--)
                            Padding(
                              padding: EdgeInsets.only(top: d == frames.length - 1 ? 0 : 8),
                              child: _frameCard(context, scheme, frames[d], d),
                            ),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _header(ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.6)),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.layers_rounded, size: 16, color: scheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                letterSpacing: 0.2,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(
            'depth ${frames.length}',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _empty(BuildContext context, ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Text(
        'stack is empty',
        textAlign: TextAlign.center,
        style: AppTheme.mono(context, size: 12, color: scheme.onSurfaceVariant),
      ),
    );
  }

  Widget _frameCard(
    BuildContext context,
    ColorScheme scheme,
    RecursionFrame f,
    int depth,
  ) {
    final green = scheme.brightness == Brightness.dark
        ? const Color(0xFF4ADE80)
        : const Color(0xFF15803D);
    final Color border;
    final Color bg;
    if (f.returning) {
      border = green;
      bg = green.withValues(alpha: scheme.brightness == Brightness.dark ? 0.16 : 0.10);
    } else if (f.active) {
      border = scheme.primary;
      bg = scheme.primary.withValues(alpha: scheme.brightness == Brightness.dark ? 0.16 : 0.08);
    } else {
      border = scheme.outlineVariant;
      bg = scheme.surfaceContainerHighest.withValues(alpha: 0.4);
    }

    return AnimatedContainer(
      duration: VizTokens.moveDuration,
      curve: VizTokens.spring,
      // Deeper frames indent slightly, reinforcing "further down the stack".
      margin: EdgeInsets.only(left: depth * 6.0),
      padding: const EdgeInsets.fromLTRB(12, 9, 12, 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border, width: f.active || f.returning ? 1.6 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  f.signature,
                  style: AppTheme.mono(context, size: 13, color: scheme.onSurface)
                      .copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              if (f.active && !f.returning)
                Icon(Icons.play_arrow_rounded, size: 16, color: scheme.primary),
            ],
          ),
          for (final l in f.locals)
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Row(
                children: [
                  Text(
                    l.name,
                    style: AppTheme.mono(
                      context,
                      size: 12,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    ' = ',
                    style: AppTheme.mono(
                      context,
                      size: 12,
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
                    ),
                  ),
                  Text(
                    l.resolved ? l.value : '…',
                    style: AppTheme.mono(
                      context,
                      size: 12,
                      color: l.resolved
                          ? scheme.onSurface
                          : scheme.onSurfaceVariant.withValues(alpha: 0.5),
                    ).copyWith(
                      fontWeight: l.resolved ? FontWeight.w700 : FontWeight.w400,
                      fontStyle: l.resolved ? FontStyle.normal : FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          if (f.returns != null)
            Padding(
              padding: const EdgeInsets.only(top: 7),
              child: Row(
                children: [
                  Icon(Icons.north_rounded, size: 13, color: green),
                  const SizedBox(width: 4),
                  Text(
                    'returns ${f.returns}',
                    style: AppTheme.mono(context, size: 12, color: green)
                        .copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
