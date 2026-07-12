import 'renderers/array_view.dart';
import 'renderers/binary_search/binary_search_view.dart';
import 'renderers/delete_middle_node/delete_middle_node_view.dart';
import 'renderers/html_embed.dart';
import 'renderers/insert_interval/insert_interval_view.dart';
import 'renderers/lca/lca_view.dart';
import 'renderers/vertical_order/vertical_order_view.dart';

/// Register all built-in visualizers. Called once at startup.
/// Add a new renderer here as the kit grows (linkedlist, tree, graph, stack…).
void registerVisualizers() {
  ArrayView.register();
  BinarySearchView.register();
  DeleteMiddleNodeView.register();
  HtmlEmbed.register();
  InsertIntervalView.register();
  LcaView.register();
  VerticalOrderView.register();
}
