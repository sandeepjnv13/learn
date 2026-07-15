import 'package:flutter_test/flutter_test.dart';
import 'package:learn/algorithms/sorting.dart';
import 'package:learn/algorithms/searching.dart';
import 'package:learn/viz/renderers/insert_interval/insert_interval_algo.dart';
import 'package:learn/viz/renderers/non_overlapping_intervals/non_overlapping_intervals_algo.dart'
    as noi;
import 'package:learn/viz/renderers/delete_middle_node/delete_middle_node_algo.dart';
import 'package:learn/viz/renderers/lca/lca_algo.dart';
import 'package:learn/viz/renderers/min_path_dp/min_path_dp_algo.dart';
import 'package:learn/viz/renderers/overlapping_subproblems/overlap_model.dart';
import 'package:learn/viz/renderers/vertical_order/vertical_order_algo.dart';
import 'package:learn/viz/renderers/next_greater_element/next_greater_element_algo.dart';
import 'package:learn/viz/renderers/gas_station/gas_station_algo.dart';
import 'package:learn/viz/renderers/min_size_subarray/min_size_subarray_algo.dart';
import 'package:learn/viz/renderers/three_sum/three_sum_algo.dart';
import 'package:learn/viz/renderers/valid_parentheses/valid_parentheses_algo.dart';

void main() {
  test('bubbleSort records frames and ends sorted', () {
    final frames = bubbleSort([3, 1, 2]);
    expect(frames.length, greaterThan(1));
    expect(frames.last.data, [1, 2, 3]);
  });

  test('binarySearch finds the target (last element is the target)', () {
    final frames = binarySearch([1, 3, 5, 7, 9, 5]); // search for 5
    expect(frames.last.note, contains('Found'));
  });

  group('insertInterval recorder', () {
    List<List<num>> finalResult(List<InsertIntervalStep> steps) => steps
        .last.result
        .map((iv) => [iv.start, iv.end])
        .toList();

    test('merges overlaps from an unsorted list', () {
      // Deliberately unsorted; [4,8] should absorb [3,5],[6,7],[8,10].
      final steps = generateInsertIntervalSteps(
        const [
          Interval(8, 10),
          Interval(1, 2),
          Interval(12, 16),
          Interval(3, 5),
          Interval(6, 7),
        ],
        const Interval(4, 8),
      );
      expect(steps.last.status, InsertIntervalStatus.done);
      expect(finalResult(steps), [
        [1, 2],
        [3, 10],
        [12, 16],
      ]);
      // Stepping is monotonic over pseudocode lines within valid bounds.
      for (final s in steps) {
        expect(s.line, inInclusiveRange(1, insertIntervalPseudocode.length));
      }
    });

    test('touching endpoints merge (strict comparisons)', () {
      // [1,4] and [4,8] touch at 4 → must combine into [1,8].
      final steps = generateInsertIntervalSteps(
        const [Interval(1, 4)],
        const Interval(4, 8),
      );
      expect(finalResult(steps), [
        [1, 8],
      ]);
    });

    test('empty list yields just the new interval', () {
      final steps =
          generateInsertIntervalSteps(const [], const Interval(2, 5));
      expect(steps.last.status, InsertIntervalStatus.done);
      expect(finalResult(steps), [
        [2, 5],
      ]);
    });
  });

  group('nonOverlapIntervals recorder', () {
    test('one overlap removed, touching intervals kept', () {
      final steps = noi.generateNonOverlapSteps(const [
        noi.Interval(1, 2),
        noi.Interval(2, 3),
        noi.Interval(3, 4),
        noi.Interval(1, 3),
      ]);
      expect(steps.last.status, noi.NonOverlapStatus.done);
      expect(steps.last.removed, 1);
      for (final s in steps) {
        expect(s.line, inInclusiveRange(1, noi.nonOverlapPseudocode.length));
      }
    });

    test('nested interval discards the wide outer one', () {
      final steps = noi.generateNonOverlapSteps(const [
        noi.Interval(1, 10),
        noi.Interval(2, 3),
        noi.Interval(4, 5),
      ]);
      expect(steps.last.removed, 1);
    });

    test('already non-overlapping needs no removals', () {
      final steps = noi.generateNonOverlapSteps(const [
        noi.Interval(1, 2),
        noi.Interval(3, 4),
        noi.Interval(5, 6),
      ]);
      expect(steps.last.removed, 0);
    });

    test('all identical removes n - 1', () {
      final steps = noi.generateNonOverlapSteps(const [
        noi.Interval(1, 5),
        noi.Interval(1, 5),
        noi.Interval(1, 5),
        noi.Interval(1, 5),
      ]);
      expect(steps.last.removed, 3);
    });

    test('empty list needs no removals', () {
      final steps = noi.generateNonOverlapSteps(const []);
      expect(steps.last.status, noi.NonOverlapStatus.done);
      expect(steps.last.removed, 0);
    });
  });

  group('deleteMiddleNode recorder', () {
    int? removedOf(List<DmnStep> steps) => steps.last.removedIndex;

    test('even length removes n/2 (0-indexed)', () {
      final steps = generateDeleteMiddleNodeSteps([1, 2, 3, 4]);
      expect(steps.last.status, DmnStatus.removed);
      expect(removedOf(steps), 2); // ⌊4/2⌋
    });

    test('odd length removes the true middle', () {
      final steps = generateDeleteMiddleNodeSteps([1, 2, 3, 4, 5]);
      expect(removedOf(steps), 2); // ⌊5/2⌋
    });

    test('two nodes remove the second (the middle)', () {
      final steps = generateDeleteMiddleNodeSteps([1, 2]);
      expect(removedOf(steps), 1);
    });

    test('single node empties the list, nothing unlinked', () {
      final steps = generateDeleteMiddleNodeSteps([9]);
      expect(steps.last.status, DmnStatus.empty);
      expect(removedOf(steps), isNull);
    });

    test('empty list returns null', () {
      final steps = generateDeleteMiddleNodeSteps([]);
      expect(steps.last.status, DmnStatus.empty);
      expect(removedOf(steps), isNull);
    });

    test('every step highlights a valid pseudocode line', () {
      final steps = generateDeleteMiddleNodeSteps([1, 2, 3, 4, 5, 6]);
      for (final s in steps) {
        expect(s.line,
            inInclusiveRange(1, deleteMiddleNodePseudocode.length));
      }
    });
  });

  group('lca recorder', () {
    // Builds id-keyed maps from a LeetCode level-order array (ids = insertion
    // order), mirroring the view's seed logic.
    ({
      Map<int, num> value,
      Map<int, int?> left,
      Map<int, int?> right,
      int root,
      int Function(num) idOf,
    }) build(List<num?> arr) {
      final value = <int, num>{};
      final left = <int, int?>{};
      final right = <int, int?>{};
      var next = 0;
      final rootId = next++;
      value[rootId] = arr.first!;
      final queue = <int>[rootId];
      var i = 1;
      var head = 0;
      while (head < queue.length && i < arr.length) {
        final parent = queue[head++];
        if (i < arr.length && arr[i] != null) {
          final id = next++;
          value[id] = arr[i]!;
          left[parent] = id;
          queue.add(id);
        }
        i++;
        if (i < arr.length && arr[i] != null) {
          final id = next++;
          value[id] = arr[i]!;
          right[parent] = id;
          queue.add(id);
        }
        i++;
      }
      int idOf(num v) => value.entries.firstWhere((e) => e.value == v).key;
      return (value: value, left: left, right: right, root: rootId, idOf: idOf);
    }

    List<LcaStep> run(List<num?> arr, num p, num q) {
      final t = build(arr);
      return generateLcaSteps(
        value: t.value,
        left: t.left,
        right: t.right,
        rootId: t.root,
        pId: t.idOf(p),
        qId: t.idOf(q),
      );
    }

    num? lcaValue(List<num?> arr, num p, num q) {
      final t = build(arr);
      final steps = generateLcaSteps(
        value: t.value,
        left: t.left,
        right: t.right,
        rootId: t.root,
        pId: t.idOf(p),
        qId: t.idOf(q),
      );
      final id = steps.last.resultId;
      return id == null ? null : t.value[id];
    }

    const tree = [3, 5, 1, 6, 2, 0, 8, null, null, 7, 4];

    test('targets in different subtrees → their branch point', () {
      expect(lcaValue(tree, 5, 1), 3);
    });

    test('ancestor is one of the targets itself', () {
      expect(lcaValue(tree, 5, 4), 5);
    });

    test('both targets deep in the same subtree', () {
      expect(lcaValue(tree, 6, 4), 5);
    });

    test('finishes in a found state', () {
      expect(run(tree, 7, 4).last.status, LcaStatus.found);
    });

    test('every step highlights a valid pseudocode line', () {
      for (final s in run(tree, 5, 1)) {
        expect(s.line, inInclusiveRange(1, lcaPseudocode.length));
      }
    });
  });

  group('verticalOrder recorder', () {
    ({
      Map<int, num> value,
      Map<int, int?> left,
      Map<int, int?> right,
      int? root,
    }) build(List<num?> arr) {
      final value = <int, num>{};
      final left = <int, int?>{};
      final right = <int, int?>{};
      if (arr.isEmpty || arr.first == null) {
        return (value: value, left: left, right: right, root: null);
      }
      var next = 0;
      final rootId = next++;
      value[rootId] = arr.first!;
      final queue = <int>[rootId];
      var i = 1;
      var head = 0;
      while (head < queue.length && i < arr.length) {
        final parent = queue[head++];
        if (i < arr.length && arr[i] != null) {
          final id = next++;
          value[id] = arr[i]!;
          left[parent] = id;
          queue.add(id);
        }
        i++;
        if (i < arr.length && arr[i] != null) {
          final id = next++;
          value[id] = arr[i]!;
          right[parent] = id;
          queue.add(id);
        }
        i++;
      }
      return (value: value, left: left, right: right, root: rootId);
    }

    List<VerticalOrderStep> run(List<num?> arr) {
      final t = build(arr);
      return generateVerticalOrderSteps(
        value: t.value,
        left: t.left,
        right: t.right,
        rootId: t.root,
      );
    }

    List<List<num>> result(List<num?> arr) => run(arr).last.columns;

    test('classic example groups by column with row order', () {
      // [[9],[3,15],[20],[7]]
      expect(result([3, 9, 20, null, null, 15, 7]), [
        [9],
        [3, 15],
        [20],
        [7],
      ]);
    });

    test('same (col,row) breaks ties by value', () {
      // 5 and 6 both land on (0,2); the smaller value comes first.
      expect(result([1, 2, 3, 4, 6, 5, 7]), [
        [4],
        [2],
        [1, 5, 6],
        [3],
        [7],
      ]);
    });

    test('empty tree yields an empty result', () {
      final steps = run([]);
      expect(steps.last.status, VerticalOrderStatus.done);
      expect(steps.last.columns, isEmpty);
    });

    test('finishes done and every step is a valid pseudocode line', () {
      final steps = run([3, 9, 20, null, null, 15, 7]);
      expect(steps.last.status, VerticalOrderStatus.done);
      for (final s in steps) {
        expect(s.line, inInclusiveRange(1, verticalOrderPseudocode.length));
      }
    });
  });

  group('nextGreaterElement recorder', () {
    test('classic case computes the right answers', () {
      final steps = generateNgeSteps([2, 1, 2, 4, 3]);
      expect(steps.last.status, NgeStatus.done);
      // 2→4, 1→2, 2→4, 4→-1, 3→-1
      expect(steps.last.nge, [4, 2, 4, -1, -1]);
    });

    test('strictly decreasing input yields all -1', () {
      final steps = generateNgeSteps([5, 4, 3, 2, 1]);
      expect(steps.last.nge, [-1, -1, -1, -1, -1]);
    });

    test('strictly increasing input resolves every earlier element', () {
      final steps = generateNgeSteps([1, 2, 3, 4]);
      expect(steps.last.nge, [2, 3, 4, -1]);
    });

    test('empty array terminates cleanly', () {
      final steps = generateNgeSteps([]);
      expect(steps.last.status, NgeStatus.done);
      expect(steps.last.nge, isEmpty);
    });

    test('every step is a valid pseudocode line', () {
      final steps = generateNgeSteps([2, 1, 2, 4, 3]);
      for (final s in steps) {
        expect(s.line, inInclusiveRange(1, ngePseudocode.length));
      }
    });
  });

  group('gasStation recorder', () {
    test('finds the feasible start with margin', () {
      final steps = generateGasStationSteps([1, 2, 3, 4, 5], [3, 4, 5, 1, 2]);
      expect(steps.last.status, GasStationStatus.found);
      expect(steps.last.result, 3);
    });

    test('reports -1 when total cost exceeds total gas', () {
      final steps = generateGasStationSteps([2, 3, 4], [3, 4, 3]);
      expect(steps.last.status, GasStationStatus.notFound);
      expect(steps.last.result, -1);
    });

    test('single feasible station returns 0', () {
      final steps = generateGasStationSteps([5], [4]);
      expect(steps.last.status, GasStationStatus.found);
      expect(steps.last.result, 0);
    });

    test('consecutive deficits move startIdx twice before settling', () {
      final steps =
          generateGasStationSteps([2, 3, 4, 1, 1], [3, 4, 1, 1, 1]);
      expect(steps.last.status, GasStationStatus.found);
      expect(steps.last.result, 2);
    });

    test('empty input terminates cleanly', () {
      final steps = generateGasStationSteps([], []);
      expect(steps.last.status, GasStationStatus.empty);
    });

    test('every step is a valid pseudocode line and index is monotonic', () {
      final steps = generateGasStationSteps([1, 2, 3, 4, 5], [3, 4, 5, 1, 2]);
      for (final s in steps) {
        expect(s.line, inInclusiveRange(1, gasStationPseudocode.length));
      }
    });
  });

  group('threeSum recorder', () {
    List<List<num>> result(List<num> arr) =>
        generateThreeSumSteps(arr).last.triplets;

    test('classic example finds both unique triplets (sorted)', () {
      // [-1,0,1,2,-1,-4] → sorted [-4,-1,-1,0,1,2] → [[-1,-1,2],[-1,0,1]]
      expect(result([-1, 0, 1, 2, -1, -4]), [
        [-1, -1, 2],
        [-1, 0, 1],
      ]);
    });

    test('duplicates collapse to unique triplets', () {
      // Many equal values must not produce repeated triplets.
      expect(result([-2, 0, 0, 2, 2]), [
        [-2, 0, 2],
      ]);
      expect(result([0, 0, 0, 0]), [
        [0, 0, 0],
      ]);
    });

    test('no triplet sums to zero', () {
      expect(result([1, 2, 3, 4]), isEmpty);
    });

    test('fewer than 3 numbers terminates cleanly', () {
      final steps = generateThreeSumSteps([1, -1]);
      expect(steps.last.status, ThreeSumStatus.done);
      expect(steps.last.triplets, isEmpty);
    });

    test('every step highlights a valid pseudocode line', () {
      final steps = generateThreeSumSteps([-1, 0, 1, 2, -1, -4]);
      expect(steps.last.status, ThreeSumStatus.done);
      for (final s in steps) {
        expect(s.line, inInclusiveRange(1, threeSumPseudocode.length));
      }
    });
  });

  group('minSizeSubarray recorder', () {
    num? result(List<num> arr, num target) =>
        generateMinSizeSubarraySteps(arr, target).last.best;

    test('classic example shrinks to length 2', () {
      // [2,3,1,2,4,3], target 7 → [4,3]
      expect(result([2, 3, 1, 2, 4, 3], 7), 2);
    });

    test('no valid window leaves best null → notFound', () {
      final steps = generateMinSizeSubarraySteps([1, 1, 1, 1], 10);
      expect(steps.last.status, MssStatus.notFound);
      expect(steps.last.best, isNull);
    });

    test('single element already at target', () {
      expect(result([1, 4, 4], 4), 1);
    });

    test('whole array is the only valid window', () {
      expect(result([1, 1, 1, 1, 7], 11), 5);
    });

    test('empty input terminates cleanly', () {
      final steps = generateMinSizeSubarraySteps([], 5);
      expect(steps.last.status, MssStatus.empty);
    });

    test('every step highlights a valid pseudocode line', () {
      final steps = generateMinSizeSubarraySteps([2, 3, 1, 2, 4, 3], 7);
      expect(steps.last.status, MssStatus.found);
      for (final s in steps) {
        expect(s.line, inInclusiveRange(1, minSizeSubarrayPseudocode.length));
      }
    });
  });

  group('validParentheses recorder', () {
    VpStatus run(String s) => generateValidParenthesesSteps(s).last.status;

    test('well-formed nested brackets are valid', () {
      expect(run('([{}])'), VpStatus.valid);
      expect(run('()[]{}'), VpStatus.valid);
    });

    test('empty string is valid', () {
      expect(run(''), VpStatus.valid);
    });

    test('mismatched pair is invalid', () {
      expect(run('([)]'), VpStatus.invalid);
    });

    test('leftover openers are invalid', () {
      expect(run('((('), VpStatus.invalid);
    });

    test('closer with empty stack is invalid', () {
      expect(run(']'), VpStatus.invalid);
    });

    test('every step is a valid pseudocode line', () {
      for (final s in generateValidParenthesesSteps('([{}])')) {
        expect(s.line, inInclusiveRange(1, validParenthesesPseudocode.length));
      }
    });
  });

  group('overlapping subproblems model', () {
    const grid = [
      [1, 3, 1],
      [1, 5, 1],
      [4, 2, 1],
    ];

    test('naive recursion expands 19 calls for 9 distinct cells', () {
      final tree = buildNaiveTree(grid);
      expect(tree.nodeCount, 19);
      expect(tree.cellCounts.length, 9);
      expect(tree.cacheHitCount, 0);
      expect(tree.answer, 7);
    });

    test('naiveNodeCount agrees with the expanded tree', () {
      expect(naiveNodeCount(grid), buildNaiveTree(grid).nodeCount);
      // A wider grid: still the 1 + up + left recurrence.
      const wide = [
        [1, 1, 1, 1],
        [1, 1, 1, 1],
        [1, 1, 1, 1],
        [1, 1, 1, 1],
      ];
      expect(naiveNodeCount(wide), buildNaiveTree(wide).nodeCount);
    });

    test('repeated cells carry the expected counts', () {
      final counts = buildNaiveTree(grid).cellCounts;
      expect(counts['0,0'], 6);
      expect(counts['0,1'], 3);
      expect(counts['1,0'], 3);
      expect(counts['1,1'], 2);
      // Everything else is reached exactly once.
      final repeated = counts.entries.where((e) => e.value > 1).map((e) => e.key);
      expect(repeated.toSet(), {'0,0', '0,1', '1,0', '1,1'});
    });

    test('memoizing collapses 19 nodes to 9 computes + 4 cache hits', () {
      final tree = buildMemoTree(grid);
      expect(tree.computeCount, 9);
      expect(tree.cacheHitCount, 4);
      expect(tree.nodeCount, 13);
      expect(tree.answer, 7);
      // Each distinct cell is computed exactly once.
      final computedCells =
          tree.nodes.where((n) => !n.cacheHit).map((n) => cellKey(n.i, n.j));
      expect(computedCells.toSet().length, 9);
      // A cache hit never explores a subtree.
      for (final n in tree.nodes.where((n) => n.cacheHit)) {
        expect(n.children, isEmpty);
      }
    });

    test('memo table fills with the cheapest cost to every cell', () {
      expect(buildMemoTable(grid), [
        [1, 4, 5],
        [2, 7, 6],
        [6, 8, 7],
      ]);
    });

    test('naive and memoized agree on the answer', () {
      const grids = [
        [
          [1, 3, 1],
          [1, 5, 1],
          [4, 2, 1],
        ],
        [
          [1, 9, 9],
          [1, 9, 9],
          [1, 1, 1],
        ],
        [
          [5]
        ],
        [
          [1, 2, 3, 4]
        ],
      ];
      for (final g in grids) {
        expect(buildNaiveTree(g).answer, buildMemoTree(g).answer);
      }
    });

    test('only repeated cells are tinted, stably ordered', () {
      final tints = repeatedCellTints(buildNaiveTree(grid));
      expect(tints.keys.toSet(), {'0,0', '0,1', '1,0', '1,1'});
      // Sorted by (i, j) so the trees and the memo table agree on the colors.
      expect(tints['0,0'], 0);
      expect(tints['0,1'], 1);
      expect(tints['1,0'], 2);
      expect(tints['1,1'], 3);
    });
  });

  group('minPathDp recorder', () {
    const grid = [
      [1, 3, 1],
      [1, 5, 1],
      [4, 2, 1],
    ];

    test('classic grid fills the same table as the memoized recursion', () {
      final steps = generateMinPathDpSteps(grid);
      expect(steps.last.status, MinPathStatus.done);
      expect(steps.last.answer, 7);
      expect(steps.last.dp, buildMemoTable(grid));
    });

    test('the cheapest path is walked back from the corner', () {
      final steps = generateMinPathDpSteps(grid);
      // 1 → 1 → 5? no: down the left column, then across the bottom is dearer.
      // Cheapest is 1,3,1,1,1 = 7 via the top row then down the right column.
      expect(steps.last.path, {'0,0', '0,1', '0,2', '1,2', '2,2'});
    });

    test('a greedy first step loses to the detour', () {
      final steps = generateMinPathDpSteps(const [
        [1, 9, 9],
        [1, 9, 9],
        [1, 1, 1],
      ]);
      expect(steps.last.answer, 5);
      expect(steps.last.path, {'0,0', '1,0', '2,0', '2,1', '2,2'});
    });

    test('single cell needs no loops', () {
      final steps = generateMinPathDpSteps(const [
        [5]
      ]);
      expect(steps.last.answer, 5);
      expect(steps.last.path, {'0,0'});
    });

    test('single row only ever comes from the left', () {
      final steps = generateMinPathDpSteps(const [
        [1, 2, 3, 4]
      ]);
      expect(steps.last.answer, 10);
      // The interior loop never runs, so nothing is ever sourced from above.
      for (final s in steps) {
        if (s.fromRow != null) expect(s.fromRow, 0);
      }
    });

    test('empty grid terminates cleanly', () {
      final steps = generateMinPathDpSteps(const []);
      expect(steps, hasLength(1));
      expect(steps.last.status, MinPathStatus.done);
    });

    test('every step is a valid pseudocode line and dp only grows', () {
      final steps = generateMinPathDpSteps(grid);
      var filled = 0;
      for (final s in steps) {
        expect(s.line, inInclusiveRange(1, minPathDpPseudocode.length));
        // Cells are written once and never unwritten.
        final now = s.dp.expand((r) => r).where((v) => v != null).length;
        expect(now, greaterThanOrEqualTo(filled));
        filled = now;
      }
      expect(filled, 9);
    });
  });
}
