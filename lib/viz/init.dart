import 'renderers/approach/approach_view.dart';
import 'renderers/array_view.dart';
import 'renderers/binary_search/binary_search_view.dart';
import 'renderers/delete_middle_node/delete_middle_node_view.dart';
import 'renderers/gas_station/gas_station_view.dart';
import 'renderers/html_embed.dart';
import 'renderers/insert_interval/insert_interval_view.dart';
import 'renderers/lca/lca_view.dart';
import 'renderers/min_size_subarray/min_size_subarray_view.dart';
import 'renderers/next_greater_element/next_greater_element_view.dart';
import 'renderers/non_overlapping_intervals/non_overlapping_intervals_view.dart';
import 'renderers/three_sum/three_sum_view.dart';
import 'renderers/valid_parentheses/valid_parentheses_view.dart';
import 'renderers/vertical_order/vertical_order_view.dart';

/// Register all built-in visualizers. Called once at startup.
/// Add a new renderer here as the kit grows (linkedlist, tree, graph, stack…).
void registerVisualizers() {
  ApproachView.register();
  ArrayView.register();
  BinarySearchView.register();
  DeleteMiddleNodeView.register();
  GasStationView.register();
  HtmlEmbed.register();
  InsertIntervalView.register();
  LcaView.register();
  MinSizeSubarrayView.register();
  NextGreaterElementView.register();
  NonOverlappingIntervalsView.register();
  ThreeSumView.register();
  ValidParenthesesView.register();
  VerticalOrderView.register();
}
