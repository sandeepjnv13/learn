import 'package:flutter_test/flutter_test.dart';
import 'package:learn/algorithms/sorting.dart';
import 'package:learn/algorithms/searching.dart';
import 'package:learn/viz/renderers/insert_interval/insert_interval_algo.dart';

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
}
