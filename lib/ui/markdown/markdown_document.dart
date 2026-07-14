import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:url_launcher/url_launcher.dart';
import 'package:yaml/yaml.dart';

import '../../theme/app_theme.dart';
import '../../viz/registry.dart';
import '../../viz/viz_focus.dart';

/// Slugifies heading text into a GitHub-style anchor, e.g.
/// "1013. Partition Array" -> "1013-partition-array".
String _slugify(String text) {
  final lower = text.toLowerCase().replaceAll(RegExp(r"[^\w\s-]"), '');
  return lower.trim().replaceAll(RegExp(r'\s+'), '-');
}

/// Renders `h2` headings wrapped in a keyed anchor so in-page `#slug` links
/// (e.g. from an "At a Glance" index) can scroll to them.
class _AnchorHeadingBuilder extends MarkdownElementBuilder {
  final TextStyle? style;
  final Map<String, GlobalKey> anchors;
  _AnchorHeadingBuilder(this.style, this.anchors);

  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final text = element.textContent;
    final key = anchors.putIfAbsent(_slugify(text), () => GlobalKey());
    return Padding(
      key: key,
      padding: const EdgeInsets.only(top: 8),
      child: Text(text, style: style),
    );
  }
}

/// Renders a markdown body, splitting out ```viz fenced blocks and rendering
/// each as a live visualizer. Everything else renders as normal markdown
/// (including ordinary code fences like ```dart).
class MarkdownDocument extends StatelessWidget {
  final String body;
  final String pageAsset;
  MarkdownDocument({
    super.key,
    required this.body,
    required this.pageAsset,
  });

  static final _vizFence = RegExp(
    r'^```viz[ \t]*\r?\n(.*?)\r?\n```[ \t]*$',
    multiLine: true,
    dotAll: true,
  );

  /// Shared measure for BOTH prose and visualizers so their left/right edges
  /// always line up and they use the same width. Fills the available width up
  /// to this cap on large monitors (keeping a little breathing room), and
  /// shrinks to fit on smaller ones.
  static const double _contentMaxWidth = 1500;

  /// Shared across all markdown segments on this page so `#slug` links can
  /// find the h2 heading they point at, however far away in the document.
  final Map<String, GlobalKey> _anchorKeys = {};

  @override
  Widget build(BuildContext context) {
    final segments = <Widget>[];
    var last = 0;

    for (final m in _vizFence.allMatches(body)) {
      final before = body.substring(last, m.start).trim();
      if (before.isNotEmpty) segments.add(_markdown(context, before));
      segments.add(_viz(m.group(1) ?? ''));
      last = m.end;
    }
    final tail = body.substring(last).trim();
    if (tail.isNotEmpty) segments.add(_markdown(context, tail));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: segments,
    );
  }

  Widget _viz(String yamlText) {
    Map<String, dynamic>? config;
    try {
      final y = loadYaml(yamlText);
      if (y is Map) config = _plain(y) as Map<String, dynamic>;
    } catch (_) {}
    if (config == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Text('Could not parse viz block.'),
      );
    }
    // Visualizers share the same measure as prose (see [_contentMaxWidth]) so
    // the two align and use the full width on large displays, capped so they
    // don't sprawl on ultra-wide monitors.
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _contentMaxWidth),
        child: VizLauncher(
          VizContext(config: config, pageAsset: pageAsset),
        ),
      ),
    );
  }

  dynamic _plain(dynamic v) {
    if (v is Map) {
      return v.map((k, val) => MapEntry(k.toString(), _plain(val)));
    }
    if (v is List) return v.map(_plain).toList();
    return v;
  }

  Widget _markdown(BuildContext context, String data) {
    // Prose uses the exact same measure as the visualizers so their edges align
    // and both fill the available width on large monitors.
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _contentMaxWidth),
        child: MarkdownBody(
          data: data,
          selectable: true,
          styleSheet: _styleSheet(context),
          onTapLink: (text, href, title) => _onTapLink(context, href),
          builders: {
            'h2': _AnchorHeadingBuilder(
              _styleSheet(context).h2,
              _anchorKeys,
            ),
          },
        ),
      ),
    );
  }

  void _onTapLink(BuildContext context, String? href) {
    if (href == null) return;
    if (href.startsWith('#')) {
      final key = _anchorKeys[href.substring(1)];
      final targetContext = key?.currentContext;
      if (targetContext != null) {
        Scrollable.ensureVisible(
          targetContext,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          alignment: 0.1,
        );
      }
    } else if (href.startsWith('/')) {
      context.go(href); // internal route
    } else {
      launchUrl(Uri.parse(href), mode: LaunchMode.externalApplication);
    }
  }

  MarkdownStyleSheet _styleSheet(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return MarkdownStyleSheet.fromTheme(theme).copyWith(
      p: theme.textTheme.bodyLarge,
      h1: theme.textTheme.headlineMedium,
      h2: theme.textTheme.titleLarge?.copyWith(fontSize: 24),
      h3: theme.textTheme.titleLarge,
      code: AppTheme.mono(context, size: 13.5, color: scheme.onSurface).copyWith(
        backgroundColor: scheme.surfaceContainerHighest,
      ),
      codeblockDecoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      codeblockPadding: const EdgeInsets.all(16),
      blockquoteDecoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: scheme.primary, width: 4)),
      ),
      blockquotePadding: const EdgeInsets.all(12),
      tableColumnWidth: const IntrinsicColumnWidth(),
      a: TextStyle(
        color: scheme.primary,
        decoration: TextDecoration.underline,
      ),
    );
  }
}
