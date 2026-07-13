import 'package:flutter_test/flutter_test.dart';
import 'package:learn/algorithms/sorting.dart';
import 'package:learn/algorithms/searching.dart';
import 'package:learn/viz/renderers/insert_interval/insert_interval_algo.dart';
import 'package:learn/viz/renderers/delete_middle_node/delete_middle_node_algo.dart';
import 'package:learn/viz/renderers/lca/lca_algo.dart';
import 'package:learn/viz/renderers/vertical_order/vertical_order_algo.dart';
import 'package:learn/viz/renderers/next_greater_element/next_greater_element_algo.dart';
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
}
