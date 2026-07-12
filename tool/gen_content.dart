// Generates assets/manifest.json from the content/ tree and updates the
// managed asset list in pubspec.yaml.
//
// Run after adding/renaming content:   dart run tool/gen_content.dart
//
// Folder = section, .md file = page (unlimited nesting). A `_section.md` in a
// folder supplies that section's title/order/icon via frontmatter. Page title
// comes from its own frontmatter `title:`, else the filename.
import 'dart:convert';
import 'dart:io';

import 'package:yaml/yaml.dart';

const contentRoot = 'content';
const manifestPath = 'assets/manifest.json';
const beginMarker = '    # >>> generated content dirs (tool/gen_content.dart)';
const endMarker = '    # <<< generated content dirs';

final _assetDirs = <String>{};

void main() {
  final root = Directory(contentRoot);
  if (!root.existsSync()) {
    stderr.writeln('No $contentRoot/ directory found.');
    exit(1);
  }

  final sections = _buildChildren(root, '');

  final manifest = const JsonEncoder.withIndent('  ')
      .convert({'sections': sections});
  File(manifestPath)
    ..createSync(recursive: true)
    ..writeAsStringSync('$manifest\n');
  stdout.writeln('Wrote $manifestPath (${sections.length} sections).');

  _updatePubspecAssets();
  stdout.writeln('Updated pubspec.yaml asset list (${_assetDirs.length} dirs).');
}

/// Build the ordered list of child nodes (sub-sections + pages) for [dir].
List<Map<String, dynamic>> _buildChildren(Directory dir, String relBase) {
  final nodes = <Map<String, dynamic>>[];

  final entries = dir.listSync()..sort((a, b) => a.path.compareTo(b.path));
  for (final entity in entries) {
    final name = entity.uri.pathSegments
        .where((s) => s.isNotEmpty)
        .last;

    if (entity is Directory) {
      final rel = relBase.isEmpty ? name : '$relBase/$name';
      final meta = _sectionMeta(entity);
      final children = _buildChildren(entity, rel);
      if (children.isEmpty) continue; // skip empty folders
      nodes.add({
        'title': meta['title'] ?? _prettify(name),
        'route': '/$rel',
        if (meta['icon'] != null) 'icon': meta['icon'],
        'order': meta['order'] ?? 9999,
        'children': children,
      });
    } else if (entity is File && name.endsWith('.md') && name != '_section.md') {
      final rel = relBase.isEmpty
          ? name.replaceAll('.md', '')
          : '$relBase/${name.replaceAll('.md', '')}';
      final fm = _frontmatter(entity.readAsStringSync());
      _assetDirs.add('$contentRoot/${relBase.isEmpty ? '' : '$relBase/'}');
      nodes.add({
        'title': fm['title'] ?? _prettify(name.replaceAll('.md', '')),
        'route': '/$rel',
        'asset': '$contentRoot/${relBase.isEmpty ? '' : '$relBase/'}$name',
        'order': fm['order'] ?? 9999,
      });
    } else if (entity is File &&
        (name.endsWith('.html') || name.endsWith('.htm'))) {
      // Raw-HTML visualizers must be bundled too.
      _assetDirs.add('$contentRoot/${relBase.isEmpty ? '' : '$relBase/'}');
    }
  }

  nodes.sort((a, b) {
    final byOrder = (a['order'] as int).compareTo(b['order'] as int);
    return byOrder != 0
        ? byOrder
        : (a['title'] as String).compareTo(b['title'] as String);
  });
  // Drop the internal order key from the manifest (keep files tidy).
  for (final n in nodes) {
    n.remove('order');
  }
  return nodes;
}

Map<String, dynamic> _sectionMeta(Directory dir) {
  final f = File('${dir.path}/_section.md');
  if (!f.existsSync()) return {};
  return _frontmatter(f.readAsStringSync());
}

Map<String, dynamic> _frontmatter(String raw) {
  final text = raw.replaceFirst(RegExp(r'^﻿'), '');
  if (!text.startsWith('---')) return {};
  final end = text.indexOf('\n---', 3);
  if (end == -1) return {};
  try {
    final y = loadYaml(text.substring(3, end).trim());
    if (y is Map) {
      return y.map((k, v) => MapEntry(k.toString(), v));
    }
  } catch (_) {}
  return {};
}

String _prettify(String slug) {
  return slug
      .replaceAll(RegExp(r'[-_]'), ' ')
      .split(' ')
      .where((w) => w.isNotEmpty)
      .map((w) => w[0].toUpperCase() + w.substring(1))
      .join(' ');
}

void _updatePubspecAssets() {
  final file = File('pubspec.yaml');
  final lines = file.readAsLinesSync();
  final begin = lines.indexOf(beginMarker);
  final end = lines.indexOf(endMarker);
  if (begin == -1 || end == -1 || end < begin) {
    stderr.writeln(
      'Could not find generated-asset markers in pubspec.yaml. '
      'Ensure both marker lines exist under flutter: assets:.',
    );
    exit(1);
  }

  final dirs = _assetDirs.toList()..sort();
  final generated = dirs.map((d) => '    - $d').toList();

  final updated = [
    ...lines.sublist(0, begin + 1),
    ...generated,
    ...lines.sublist(end),
  ];
  file.writeAsStringSync('${updated.join('\n')}\n');
}
