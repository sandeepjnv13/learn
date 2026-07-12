import 'package:flutter/material.dart';

import 'viz_tokens.dart';

/// The top control bar: Start/Reset, Step back/forward, and Auto-play toggle,
/// with an optional [input] slot (e.g. array + target fields) on the left.
///
/// Owns no playback state itself — the composing visualizer passes the current
/// flags and callbacks.
class ControlBar extends StatelessWidget {
  final bool playing;
  final bool atStart;
  final bool atEnd;
  final VoidCallback onReset;
  final VoidCallback? onStepBack;
  final VoidCallback? onStepForward;
  final VoidCallback onTogglePlay;

  /// Optional editable input(s) shown at the leading edge.
  final Widget? input;

  const ControlBar({
    super.key,
    required this.playing,
    required this.atStart,
    required this.atEnd,
    required this.onReset,
    required this.onStepBack,
    required this.onStepForward,
    required this.onTogglePlay,
    this.input,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(VizTokens.radius + 2),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.7)),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: [
          ?input,
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: onStepBack,
                icon: const Icon(Icons.skip_previous_rounded),
                tooltip: 'Step back',
              ),
              const SizedBox(width: 4),
              FilledButton.icon(
                onPressed: onTogglePlay,
                icon: Icon(
                  playing
                      ? Icons.pause_rounded
                      : (atEnd
                          ? Icons.replay_rounded
                          : Icons.play_arrow_rounded),
                ),
                label: Text(playing ? 'Pause' : (atEnd ? 'Replay' : 'Auto')),
              ),
              const SizedBox(width: 4),
              IconButton(
                onPressed: onStepForward,
                icon: const Icon(Icons.skip_next_rounded),
                tooltip: 'Step forward',
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: atStart && !playing ? null : onReset,
                icon: const Icon(Icons.restart_alt_rounded, size: 18),
                label: const Text('Reset'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
