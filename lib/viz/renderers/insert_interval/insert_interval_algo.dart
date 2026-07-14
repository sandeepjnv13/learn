/// Deterministic step model for the "insert interval" visualizer.
///
/// The list of existing intervals is non-overlapping but may be UNSORTED, so we
/// sort it first, then sweep once carrying a single `toAdd` interval. As with
/// every visualizer here, we run the whole algorithm up front and record ONE
/// [InsertIntervalStep] per pseudocode line executed - stepping the UI is then
/// pure index movement.
library;

import 'dart:math' as math;

enum InsertIntervalStatus { sorting, scanning, done }

/// An inclusive integer/real interval `[start, end]`.
class Interval {
  final num start;
  final num end;
  const Interval(this.start, this.end);

  Interval mergedWith(Interval o) =>
      Interval(math.min(start, o.start), math.max(end, o.end));

  @override
  String toString() => '[${_fmt(start)}, ${_fmt(end)}]';
}

/// Full pseudocode. `line` in a step is 1-based into this list.
///
/// Note the ORDER of the checks inside the loop: the two *non-overlap* cases
/// (entirely before / entirely after) are tested first, and "overlap" is simply
/// whatever is left in the `else`. Detecting overlap directly is fiddly and easy
/// to get wrong at the touching endpoints - ruling out the two disjoint cases is
/// the clean way to be certain.
const List<String> insertIntervalPseudocode = [
  'sort intervals by start', // 1
  'result ← [ ]', // 2
  'toAdd ← newInterval', // 3
  'for iv in intervals:', // 4
  '  if iv.end < toAdd.start:       # iv fully BEFORE', // 5
  '    result.add(iv)', // 6
  '  else if iv.start > toAdd.end:  # iv fully AFTER', // 7
  '    result.add(toAdd)', // 8
  '    toAdd ← iv', // 9
  '  else:                          # they OVERLAP', // 10
  '    toAdd ← merge(toAdd, iv)', // 11
  'result.add(toAdd)', // 12
  'return result', // 13
];

class InsertIntervalStep {
  final int line; // 1-based pseudocode line highlighted
  final List<Interval> intervals; // sorted source list (stable across steps)
  final int? current; // index into [intervals] under examination
  final Interval? toAdd; // interval currently carried
  final List<Interval> result; // committed so far
  final Set<int> committedSources; // source idx now living in result
  final Set<int> absorbedSources; // source idx merged into the live toAdd
  final String? badge; // comparison/decision just made
  final String log; // plain-English trace entry
  final Set<String> changed; // variable names updated this step (pulse)
  final InsertIntervalStatus status;

  const InsertIntervalStep({
    required this.line,
    required this.intervals,
    this.current,
    this.toAdd,
    required this.result,
    this.committedSources = const {},
    this.absorbedSources = const {},
    this.badge,
    required this.log,
    this.changed = const {},
    this.status = InsertIntervalStatus.scanning,
  });
}

String _fmt(num n) =>
    n is int || n == n.roundToDouble() ? n.toInt().toString() : n.toString();

/// Runs the insert-interval sweep over a copy of [rawIntervals] (sorted by
/// start) inserting [newInterval], recording every pseudocode line executed.
List<InsertIntervalStep> generateInsertIntervalSteps(
  List<Interval> rawIntervals,
  Interval newInterval,
) {
  final intervals = List<Interval>.from(rawIntervals)
    ..sort((a, b) => a.start.compareTo(b.start));
  final n = intervals.length;

  final steps = <InsertIntervalStep>[];
  final result = <Interval>[];
  final committed = <int>{};
  final absorbed = <int>{};
  Interval? toAdd;

  void add(
    int line, {
    int? current,
    String? badge,
    required String log,
    Set<String> changed = const {},
    InsertIntervalStatus status = InsertIntervalStatus.scanning,
  }) {
    steps.add(InsertIntervalStep(
      line: line,
      intervals: intervals,
      current: current,
      toAdd: toAdd,
      result: List<Interval>.from(result),
      committedSources: Set<int>.from(committed),
      absorbedSources: Set<int>.from(absorbed),
      badge: badge,
      log: log,
      changed: changed,
      status: status,
    ));
  }

  // 1: sort intervals by start
  add(1,
      log: 'Sort the list by start → '
          '[${intervals.join(', ')}]. The list can arrive unsorted, and the '
          'whole sweep relies on left-to-right order.',
      status: InsertIntervalStatus.sorting);

  // 2: result ← []
  add(2, log: 'result ← [ ]  (empty - we build the answer as we go).');

  // 3: toAdd ← newInterval
  toAdd = newInterval;
  add(3,
      log: 'toAdd ← newInterval = $newInterval. This is the one interval we '
          'carry and keep growing as it swallows overlaps.',
      changed: {'toAdd'});

  for (var i = 0; i < n; i++) {
    final iv = intervals[i];

    // 4: for iv in intervals
    add(4, current: i, log: 'Look at interval $iv (index $i).');

    // 5: if iv.end < toAdd.start  → fully before
    final before = iv.end < toAdd!.start;
    add(5,
        current: i,
        badge: 'iv.end ${_fmt(iv.end)} < toAdd.start ${_fmt(toAdd.start)} → '
            '$before',
        log: 'Non-overlap check #1 - is $iv entirely BEFORE toAdd $toAdd? '
            '$before');
    if (before) {
      // 6: result.add(iv)
      result.add(iv);
      committed.add(i);
      add(6,
          current: i,
          log: '$iv sits completely to the left of toAdd, so it can never '
              'touch it → drop it straight into result and move on.',
          changed: {'result'});
      continue;
    }

    // 7: else if iv.start > toAdd.end  → fully after
    final after = iv.start > toAdd.end;
    add(7,
        current: i,
        badge: 'iv.start ${_fmt(iv.start)} > toAdd.end ${_fmt(toAdd.end)} → '
            '$after',
        log: 'Non-overlap check #2 - is $iv entirely AFTER toAdd $toAdd? '
            '$after');
    if (after) {
      // 8: result.add(toAdd)
      result.add(toAdd);
      committed.addAll(absorbed);
      absorbed.clear();
      add(8,
          current: i,
          log: 'toAdd $toAdd is fully to the left of $iv. Since the list is '
              'sorted, nothing later can reach back to it → toAdd is final. '
              'Commit it to result.',
          changed: {'result'});
      // 9: toAdd ← iv
      toAdd = iv;
      absorbed.add(i);
      add(9,
          current: i,
          log: 'toAdd ← $iv - this interval now becomes the one we carry '
              'forward.',
          changed: {'toAdd'});
      continue;
    }

    // 10: else → overlap
    add(10,
        current: i,
        badge: 'not before & not after → OVERLAP',
        log: '$iv is neither before nor after toAdd $toAdd, so by elimination '
            'they must OVERLAP (or touch).');
    // 11: toAdd ← merge(toAdd, iv)
    final merged = toAdd.mergedWith(iv);
    toAdd = merged;
    absorbed.add(i);
    add(11,
        current: i,
        log: 'Absorb $iv into toAdd → $merged  (min of starts, max of ends).',
        changed: {'toAdd'});
  }

  // 12: result.add(toAdd)
  result.add(toAdd!);
  committed.addAll(absorbed);
  absorbed.clear();
  add(12,
      log: 'Loop finished. The carried toAdd $toAdd was never committed inside '
          'the loop → add it now.',
      changed: {'result'});

  // 13: return result
  add(13,
      log: 'Done → result = [${result.join(', ')}].',
      status: InsertIntervalStatus.done);

  return steps;
}
