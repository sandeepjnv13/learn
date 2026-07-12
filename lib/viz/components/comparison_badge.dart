import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'viz_tokens.dart';

/// A pill spelling out the specific comparison / decision just made, e.g.
/// `arr[mid] (5) < target (7) → search right`. Animates in on change.
class ComparisonBadge extends StatelessWidget {
  final String? text;

  const ComparisonBadge({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedSwitcher(
      duration: VizTokens.moveDuration,
      switchInCurve: VizTokens.spring,
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.96, end: 1).animate(anim),
          child: child,
        ),
      ),
      child: text == null
          ? const SizedBox(height: 40, width: double.infinity)
          : Container(
              key: ValueKey(text),
              height: 40,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: scheme.tertiaryContainer.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(VizTokens.radius),
                border: Border.all(
                  color: scheme.tertiary.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.balance_rounded,
                      size: 15, color: scheme.tertiary),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      text!,
                      textAlign: TextAlign.center,
                      style: AppTheme.mono(
                        context,
                        size: 13,
                        color: scheme.onTertiaryContainer,
                      ).copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
