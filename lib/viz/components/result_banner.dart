import 'package:flutter/material.dart';

import 'viz_tokens.dart';

enum ResultKind { success, failure }

/// A distinct success/failure banner, visually separate from the event log.
/// Springs into view when a result is reached and collapses otherwise.
class ResultBanner extends StatelessWidget {
  final ResultKind? kind;
  final String? message;

  const ResultBanner({super.key, required this.kind, required this.message});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedSize(
      duration: VizTokens.moveDuration,
      curve: VizTokens.spring,
      child: (kind == null || message == null)
          ? const SizedBox(width: double.infinity)
          : _banner(context, scheme),
    );
  }

  Widget _banner(BuildContext context, ColorScheme scheme) {
    final success = kind == ResultKind.success;
    final state = success ? VizState.found : VizState.notFound;
    final c = vizStateColors(scheme, state);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: c.fill,
        borderRadius: BorderRadius.circular(VizTokens.radius),
        border: Border.all(color: c.border),
      ),
      child: Row(
        children: [
          Icon(
            success ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: c.border,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message!,
              style: TextStyle(
                color: c.foreground,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
