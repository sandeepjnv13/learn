import 'package:flutter/material.dart';

import '../../components/components.dart';
import '../../registry.dart';

/// Renders the `type: approach` **glance card** - a static, non-interactive
/// summary of how a problem is solved. Reads its content straight from the
/// `viz` YAML block:
///
/// ```yaml
/// type: approach
/// technique: Monotonic decreasing stack
/// pattern: monotonic-stack        # selects the schematic
/// idea: Keep indices whose answer is still unknown, values decreasing.
/// bullets:
///   - Pop every top smaller than the current value - it just found its answer
///   - Push the current index; leftovers at the end resolve to -1
/// gotcha: Use a strict `<` so equal values don't resolve each other.
/// complexity: O(n) time · O(n) space
/// ```
class ApproachView {
  static void register() {
    VizRegistry.register(
      'approach',
      (ctx) => _ApproachView(ctx),
      isStatic: true,
    );
  }
}

class _ApproachView extends StatelessWidget {
  final VizContext ctx;
  const _ApproachView(this.ctx);

  String? _str(String key) {
    return ctx.config[key]?.toString();
  }

  List<String> _list(String key) {
    final v = ctx.config[key];
    if (v is List) return v.map((e) => e.toString()).toList();
    if (v is String && v.isNotEmpty) return [v];
    return const [];
  }

  @override
  Widget build(BuildContext context) {
    return ApproachCard(
      technique: _str('technique') ?? 'Approach',
      pattern: _str('pattern') ?? 'generic',
      idea: _str('idea'),
      bullets: _list('bullets'),
      gotcha: _str('gotcha'),
      complexity: _str('complexity'),
    );
  }
}
