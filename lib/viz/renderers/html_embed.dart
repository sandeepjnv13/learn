import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../registry.dart';
import '../viz_card.dart';
import '../viz_focus.dart';
import 'html_platform_stub.dart'
    if (dart.library.js_interop) 'html_platform_web.dart';

/// Embeds a raw HTML file (or URL) as an interactive visualizer.
///
/// Config:
///   type: html
///   src: bubble-sort.html   # relative to the page's folder, or an http(s) URL
///   height: 400
class HtmlEmbed extends StatelessWidget {
  final VizContext ctx;
  const HtmlEmbed(this.ctx, {super.key});

  static void register() {
    VizRegistry.register('html', (ctx) => HtmlEmbed(ctx));
  }

  double get _height => (ctx.config['height'] as num?)?.toDouble() ?? 360;

  String? get _src => ctx.config['src'] as String?;

  bool get _isUrl {
    final s = _src ?? '';
    return s.startsWith('http://') || s.startsWith('https://');
  }

  String get _assetPath {
    final src = _src ?? '';
    final dir = ctx.pageDir;
    return dir.isEmpty ? src : '$dir/$src';
  }

  @override
  Widget build(BuildContext context) {
    final fullscreen = VizPresentation.isFullscreen(context);
    // In focus mode fill the viewport the host offers; inline uses the
    // author-configured height.
    final height = fullscreen
        ? ((VizPresentation.heightOf(context) ??
                    MediaQuery.sizeOf(context).height) -
                40)
            .clamp(360.0, double.infinity)
        : _height;

    if (_src == null) {
      return _frame(fullscreen,
          const Text('HTML visualizer is missing "src".'));
    }
    if (_isUrl) {
      return _frame(fullscreen, htmlIframe(src: _src, height: height));
    }
    return _frame(
      fullscreen,
      FutureBuilder<String>(
        future: rootBundle.loadString(_assetPath),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return SizedBox(
              height: height,
              child: const Center(child: CircularProgressIndicator()),
            );
          }
          if (snap.hasError) {
            return SizedBox(
              height: height,
              child: Center(child: Text('Could not load $_assetPath')),
            );
          }
          return htmlIframe(srcdoc: snap.data, height: height);
        },
      ),
    );
  }

  /// Inline: framed in a [VizCard]. Focus mode: bare so it fills the viewport.
  Widget _frame(bool fullscreen, Widget child) =>
      fullscreen ? child : VizCard(child: child);
}
