import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'viz_tokens.dart';

/// A slim progress bar with a smooth width transition plus a step counter.
/// Optionally shows a secondary caption (e.g. "search space: 3").
class StepProgress extends StatelessWidget {
  final int step; // 0-based
  final int total; // number of steps
  final String? caption;

  const StepProgress({
    super.key,
    required this.step,
    required this.total,
    this.caption,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fraction = total <= 1 ? 1.0 : (step / (total - 1)).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              'Step ${step + 1} / $total',
              style: AppTheme.mono(
                context,
                size: 12,
                color: scheme.onSurfaceVariant,
              ).copyWith(fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            if (caption != null)
              Text(
                caption!,
                style: AppTheme.mono(
                  context,
                  size: 12,
                  color: scheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, c) => Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              AnimatedContainer(
                duration: VizTokens.moveDuration,
                curve: Curves.easeOutCubic,
                height: 8,
                width: c.maxWidth * fraction,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [scheme.primary, scheme.tertiary],
                  ),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
