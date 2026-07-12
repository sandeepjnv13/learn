/// A node in the content tree: either a section (folder) or a page (.md file).
///
/// The tree is produced by `tool/gen_content.dart`, which walks `content/`
/// and emits `assets/manifest.json`. Nesting is unlimited.
class ContentNode {
  final String title;
  final String route; // e.g. /ds-algo/arrays/two-pointer
  final String? asset; // e.g. content/ds-algo/arrays/two-pointer.md (pages only)
  final String? icon; // optional material icon name for sections
  final int order;
  final List<ContentNode> children;

  const ContentNode({
    required this.title,
    required this.route,
    this.asset,
    this.icon,
    this.order = 0,
    this.children = const [],
  });

  bool get isPage => asset != null;
  bool get hasChildren => children.isNotEmpty;

  factory ContentNode.fromJson(Map<String, dynamic> json) {
    return ContentNode(
      title: json['title'] as String,
      route: json['route'] as String,
      asset: json['asset'] as String?,
      icon: json['icon'] as String?,
      order: (json['order'] as num?)?.toInt() ?? 0,
      children: (json['children'] as List<dynamic>? ?? [])
          .map((e) => ContentNode.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Depth-first list of all page nodes (used to build routes).
  List<ContentNode> flattenPages() {
    final pages = <ContentNode>[];
    void walk(ContentNode n) {
      if (n.isPage) pages.add(n);
      for (final c in n.children) {
        walk(c);
      }
    }

    walk(this);
    return pages;
  }
}
