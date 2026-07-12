import 'dart:async';

import 'package:flutter/material.dart';

/// Wraps any frame-based visualizer with play / prev / next / scrub controls.
///
/// The renderer supplies how to draw a single frame via [frameBuilder]; the
/// Player owns playback state. Used by ArrayView and every future renderer.
class VizPlayer extends StatefulWidget {
  final int frameCount;
  final Widget Function(BuildContext context, int index) frameBuilder;
  final Duration interval;

  const VizPlayer({
    super.key,
    required this.frameCount,
    required this.frameBuilder,
    this.interval = const Duration(milliseconds: 900),
  });

  @override
  State<VizPlayer> createState() => _VizPlayerState();
}

class _VizPlayerState extends State<VizPlayer> {
  int _index = 0;
  Timer? _timer;
  bool get _playing => _timer != null;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _togglePlay() {
    if (_playing) {
      _stop();
    } else {
      if (_index >= widget.frameCount - 1) _index = 0;
      _timer = Timer.periodic(widget.interval, (_) {
        if (_index >= widget.frameCount - 1) {
          _stop();
        } else {
          setState(() => _index++);
        }
      });
      setState(() {});
    }
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
    if (mounted) setState(() {});
  }

  void _goto(int i) {
    _stop();
    setState(() => _index = i.clamp(0, widget.frameCount - 1));
  }

  @override
  Widget build(BuildContext context) {
    final single = widget.frameCount <= 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        widget.frameBuilder(context, _index),
        if (!single) ...[
          const SizedBox(height: 12),
          _controls(context),
        ],
      ],
    );
  }

  Widget _controls(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        IconButton(
          onPressed: _index > 0 ? () => _goto(_index - 1) : null,
          icon: const Icon(Icons.skip_previous_rounded),
          tooltip: 'Previous',
        ),
        IconButton.filledTonal(
          onPressed: _togglePlay,
          icon: Icon(_playing ? Icons.pause_rounded : Icons.play_arrow_rounded),
          tooltip: _playing ? 'Pause' : 'Play',
        ),
        IconButton(
          onPressed: _index < widget.frameCount - 1
              ? () => _goto(_index + 1)
              : null,
          icon: const Icon(Icons.skip_next_rounded),
          tooltip: 'Next',
        ),
        Expanded(
          child: Slider(
            value: _index.toDouble(),
            min: 0,
            max: (widget.frameCount - 1).toDouble(),
            divisions: widget.frameCount - 1,
            onChanged: (v) => _goto(v.round()),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 4, right: 8),
          child: Text(
            '${_index + 1}/${widget.frameCount}',
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }
}
