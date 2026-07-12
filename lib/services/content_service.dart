import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:yaml/yaml.dart';

import '../models/content_node.dart';

/// A parsed markdown page: frontmatter + body.
class PageContent {
  final String title;
  final Map<String, dynamic> frontmatter;
  final String body;

  const PageContent({
    required this.title,
    required this.frontmatter,
    required this.body,
  });
}

/// Loads the content manifest and individual pages from bundled assets.
class ContentService {
  List<ContentNode> _roots = const [];
  List<ContentNode> get roots => _roots;

  final Map<String, ContentNode> _byRoute = {};

  /// Load and parse `assets/manifest.json`. Call once at startup.
  Future<void> load() async {
    final raw = await rootBundle.loadString('assets/manifest.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    _roots = (json['sections'] as List<dynamic>)
        .map((e) => ContentNode.fromJson(e as Map<String, dynamic>))
        .toList();
    _byRoute.clear();
    for (final r in _roots) {
      _index(r);
    }
  }

  void _index(ContentNode node) {
    _byRoute[node.route] = node;
    for (final c in node.children) {
      _index(c);
    }
  }

  ContentNode? nodeForRoute(String route) => _byRoute[route];

  /// All page nodes across every root, in tree order.
  List<ContentNode> allPages() =>
      _roots.expand((r) => r.flattenPages()).toList();

  /// Load and split a markdown page into frontmatter + body.
  Future<PageContent> loadPage(String asset) async {
    final raw = await rootBundle.loadString(asset);
    return _parse(raw, asset);
  }

  PageContent _parse(String raw, String asset) {
    var body = raw;
    Map<String, dynamic> fm = {};

    final trimmed = raw.replaceFirst(RegExp(r'^﻿'), '');
    if (trimmed.startsWith('---')) {
      final end = trimmed.indexOf('\n---', 3);
      if (end != -1) {
        final fmText = trimmed.substring(3, end).trim();
        final rest = trimmed.substring(end + 4);
        body = rest.replaceFirst(RegExp(r'^\s*\n'), '');
        try {
          final parsed = loadYaml(fmText);
          if (parsed is Map) {
            fm = Map<String, dynamic>.from(
              parsed.map((k, v) => MapEntry(k.toString(), v)),
            );
          }
        } catch (_) {
          // Malformed frontmatter — ignore, keep body as-is.
        }
      }
    }

    final title = (fm['title'] as String?) ??
        asset.split('/').last.replaceAll('.md', '');
    return PageContent(title: title, frontmatter: fm, body: body);
  }
}
