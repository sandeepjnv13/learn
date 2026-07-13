import 'package:flutter/material.dart';

/// Everything a visualizer builder needs from the page.
class VizContext {
  final Map<String, dynamic> config; // parsed from the ```viz YAML block
  final String pageAsset; // e.g. content/ds-algo/arrays/two-pointer.md

  const VizContext({required this.config, required this.pageAsset});

  /// Directory of the page asset, used to resolve relative `src:` paths.
  String get pageDir {
    final i = pageAsset.lastIndexOf('/');
    return i == -1 ? '' : pageAsset.substring(0, i);
  }
}

typedef VizBuilder = Widget Function(VizContext ctx);

/// Maps a `type:` string in a ```viz block to a renderer widget.
///
/// Add a new visualizer = write a widget + `VizRegistry.register('name', ...)`.
class VizRegistry {
  VizRegistry._();

  static final Map<String, VizBuilder> _builders = {};

  /// Types that render as a **static, inline** card (no stepper, no focus/fit
  /// chrome) — e.g. the `approach` glance card. [VizLauncher] omits its button
  /// cluster and full-screen route for these.
  static final Set<String> _static = {};

  static void register(String type, VizBuilder builder, {bool isStatic = false}) {
    _builders[type] = builder;
    if (isStatic) _static.add(type);
  }

  static bool has(String type) => _builders.containsKey(type);

  /// Whether [type] is a static inline card that should skip the launcher chrome.
  static bool isStatic(Object? type) => type is String && _static.contains(type);

  static Widget build(VizContext ctx) {
    final type = ctx.config['type'];
    if (type is! String || !_builders.containsKey(type)) {
      return _UnknownViz(type: type?.toString());
    }
    return _builders[type]!(ctx);
  }
}

class _UnknownViz extends StatelessWidget {
  final String? type;
  const _UnknownViz({this.type});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.errorContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        type == null
            ? 'Visualizer block is missing a "type".'
            : 'Unknown visualizer type: "$type".',
        style: TextStyle(color: scheme.onErrorContainer),
      ),
    );
  }
}
