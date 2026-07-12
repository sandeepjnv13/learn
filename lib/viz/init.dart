import 'renderers/array_view.dart';
import 'renderers/binary_search/binary_search_view.dart';
import 'renderers/html_embed.dart';
import 'renderers/insert_interval/insert_interval_view.dart';

/// Register all built-in visualizers. Called once at startup.
/// Add a new renderer here as the kit grows (linkedlist, tree, graph, stack…).
void registerVisualizers() {
  ArrayView.register();
  BinarySearchView.register();
  HtmlEmbed.register();
  InsertIntervalView.register();
}
