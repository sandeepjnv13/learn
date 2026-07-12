import 'package:flutter/material.dart';

import '../../algorithms/registry.dart';
import '../frame.dart';
import '../player.dart';
import '../registry.dart';
import '../viz_card.dart';

/// Renders an array/list as a row of animated cells, stepping through frames.
///
/// Config forms:
///   type: array
///   data: [5, 1, 4]              # single static frame
///   highlight: [0, 1]
///
///   type: array
///   frames: [{data: [...], highlight: [...], note: "..."}, ...]
///
///   type: array
///   algo: bubble-sort            # frames generated live by Dart (Phase 3)
///   input: [5, 1, 4, 2, 8]
class ArrayView extends StatelessWidget {
  final VizContext ctx;
  const ArrayView(this.ctx, {super.key});

  static void register() {
    VizRegistry.register('array', (ctx) => ArrayView(ctx));
  }

  List<ArrayFrame> _frames() {
    final c = ctx.config;

    // Live mode: an algorithm generates the frames.
    if (c['algo'] is String) {
      final input = (c['input'] as List<dynamic>? ?? const [])
          .map((e) => e as num)
          .toList();
      return AlgorithmRegistry.run(c['algo'] as String, input);
    }

    // Authored multi-frame mode.
    if (c['frames'] is List) {
      return (c['frames'] as List)
          .map((e) => ArrayFrame.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
    }

    // Single static frame.
    return [ArrayFrame.fromMap(Map<String, dynamic>.from(c))];
  }

  @override
  Widget build(BuildContext context) {
    final frames = _frames();
    if (frames.isEmpty) {
      return const VizCard(child: Text('No data to visualize.'));
    }
    final title = ctx.config['label'] as String? ?? ctx.config['algo'] as String?;
    return VizCard(
      title: title,
      child: VizPlayer(
        frameCount: frames.length,
        frameBuilder: (context, i) => _ArrayFrameView(frame: frames[i]),
      ),
    );
  }
}

class _ArrayFrameView extends StatelessWidget {
  final ArrayFrame frame;
  const _ArrayFrameView({required this.frame});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Invert pointer map: index -> [names]
    final pointersAt = <int, List<String>>{};
    frame.pointers.forEach((name, idx) {
      pointersAt.putIfAbsent(idx, () => []).add(name);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (var i = 0; i < frame.data.length; i++)
                _Cell(
                  value: frame.data[i],
                  highlighted: frame.highlight.contains(i),
                  pointers: pointersAt[i] ?? const [],
                  scheme: scheme,
                ),
            ],
          ),
        ),
        if (frame.note != null) ...[
          const SizedBox(height: 12),
          Text(
            frame.note!,
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }
}

class _Cell extends StatelessWidget {
  final num value;
  final bool highlighted;
  final List<String> pointers;
  final ColorScheme scheme;

  const _Cell({
    required this.value,
    required this.highlighted,
    required this.pointers,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: highlighted
                  ? scheme.primary
                  : scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: highlighted ? scheme.primary : scheme.outlineVariant,
              ),
            ),
            child: Text(
              '$value',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 18,
                color: highlighted ? scheme.onPrimary : scheme.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 18,
            child: Text(
              pointers.join(' '),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: scheme.tertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
