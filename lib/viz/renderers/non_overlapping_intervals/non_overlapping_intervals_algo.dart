/// Deterministic step model for the "non-overlapping intervals" visualizer
/// (LeetCode 435): find the minimum number of intervals to remove so the
/// rest don't overlap.
///
/// Sort by start, then sweep keeping one `active` interval (tracked by its
/// index into the sorted list). Whenever the next interval overlaps `active`,
/// we must discard one - always the one with the LARGER end (keep the
/// smaller end as the new `active`), since that leaves maximum room for what
/// follows. As with every visualizer here, the whole algorithm runs up front
/// and records ONE step per pseudocode line executed.
library;

enum NonOverlapStatus { sorting, scanning, done }

/// An inclusive integer/real interval `[start, end]`.
class Interval {
  final num start;
  final num end;
  const Interval(this.start, this.end);

  @override
  String toString() => '[${_fmt(start)}, ${_fmt(end)}]';
}

/// Full pseudocode. `line` in a step is 1-based into this list.
const List<String> nonOverlapPseudocode = [
  'sort intervals by start', // 1
  'active ← intervals[0]', // 2
  'removed ← 0', // 3
  'for iv in intervals[1:]:', // 4
  '  if iv.start >= active.end:      # no overlap', // 5
  '    active ← iv', // 6
  '  else:                           # overlap - discard one', // 7
  '    removed ← removed + 1', // 8
  '    if iv.end < active.end:       # iv ends sooner', // 9
  '      active ← iv                 # keep the smaller end', // 10
  'return removed', // 11
];

class NonOverlapStep {
  final int line; // 1-based pseudocode line highlighted
  final List<Interval> intervals; // sorted source list (stable across steps)
  final int? current; // index into [intervals] under examination
  final int activeIndex; // index into [intervals] of the kept reference
  final int removed; // removal count so far
  final Set<int> keptSources; // source idx confirmed kept (settled so far)
  final Set<int> discardedSources; // source idx ruled out (removed)
  final String? badge; // comparison/decision just made
  final String log; // plain-English trace entry
  final Set<String> changed; // variable names updated this step (pulse)
  final NonOverlapStatus status;

  const NonOverlapStep({
    required this.line,
    required this.intervals,
    this.current,
    required this.activeIndex,
    this.removed = 0,
    this.keptSources = const {},
    this.discardedSources = const {},
    this.badge,
    required this.log,
    this.changed = const {},
    this.status = NonOverlapStatus.scanning,
  });

  Interval get active => intervals[activeIndex];
}

String _fmt(num n) =>
    n is int || n == n.roundToDouble() ? n.toInt().toString() : n.toString();

/// Runs the greedy sweep over a copy of [rawIntervals] (sorted by start),
/// recording every pseudocode line executed.
List<NonOverlapStep> generateNonOverlapSteps(List<Interval> rawIntervals) {
  final intervals = List<Interval>.from(rawIntervals)
    ..sort((a, b) => a.start.compareTo(b.start));
  final n = intervals.length;

  final steps = <NonOverlapStep>[];

  if (n == 0) {
    steps.add(const NonOverlapStep(
      line: 1,
      intervals: [],
      activeIndex: -1,
      log: 'No intervals - nothing can overlap, so 0 removals are needed.',
      status: NonOverlapStatus.done,
    ));
    return steps;
  }

  int activeIndex = 0;
  int removed = 0;
  final kept = <int>{0};
  final discarded = <int>{};

  void add(
    int line, {
    int? current,
    String? badge,
    required String log,
    Set<String> changed = const {},
    NonOverlapStatus status = NonOverlapStatus.scanning,
  }) {
    steps.add(NonOverlapStep(
      line: line,
      intervals: intervals,
      current: current,
      activeIndex: activeIndex,
      removed: removed,
      keptSources: Set<int>.from(kept),
      discardedSources: Set<int>.from(discarded),
      badge: badge,
      log: log,
      changed: changed,
      status: status,
    ));
  }

  // 1: sort by start
  add(1,
      log: 'Sort the list by start → '
          '[${intervals.join(', ')}]. The greedy sweep only works left to right.',
      status: NonOverlapStatus.sorting);

  // 2: active ← intervals[0]
  add(2,
      current: 0,
      log: 'active ← intervals[0] = ${intervals[0]} - the first interval '
          'always survives.',
      changed: {'active'});

  // 3: removed ← 0
  add(3, current: 0, log: 'removed ← 0.', changed: {'removed'});

  if (n == 1) {
    add(11,
        log: 'Only one interval - nothing to compare → removed = 0.',
        status: NonOverlapStatus.done);
    return steps;
  }

  for (var i = 1; i < n; i++) {
    final iv = intervals[i];
    final active = intervals[activeIndex];

    // 4: for iv in intervals[1:]
    add(4, current: i, log: 'Look at interval $iv (index $i).');

    // 5: if iv.start >= active.end → no overlap
    final noOverlap = iv.start >= active.end;
    add(5,
        current: i,
        badge:
            'iv.start ${_fmt(iv.start)} >= active.end ${_fmt(active.end)} → '
            '$noOverlap',
        log: 'Does $iv start at or after active $active ends? $noOverlap');

    if (noOverlap) {
      // 6: active ← iv
      activeIndex = i;
      kept.add(i);
      add(6,
          current: i,
          log: 'No overlap - $iv becomes the new active interval.',
          changed: {'active'});
      continue;
    }

    // 7: else → overlap, discard one
    add(7,
        current: i,
        badge: 'overlap',
        log: '$iv overlaps active $active - one of them must be removed.');

    // 8: removed += 1
    removed += 1;
    add(8,
        current: i,
        log: 'removed ← ${removed - 1} + 1 = $removed.',
        changed: {'removed'});

    // 9: if iv.end < active.end → iv ends sooner
    final ivEndsSooner = iv.end < active.end;
    add(9,
        current: i,
        badge: 'iv.end ${_fmt(iv.end)} < active.end ${_fmt(active.end)} → '
            '$ivEndsSooner',
        log: 'Which one to keep? Keep whichever ends sooner - it leaves more '
            'room for what follows. Does $iv end before active $active? '
            '$ivEndsSooner');

    if (ivEndsSooner) {
      // 10: active ← iv (discard the old active, it had the larger end)
      discarded.add(activeIndex);
      kept.remove(activeIndex);
      activeIndex = i;
      kept.add(i);
      add(10,
          current: i,
          log: '$iv ends sooner than the old active - discard the old '
              'active $active (it had the larger end, so it was more likely '
              'to keep overlapping) and keep $iv.',
          changed: {'active'});
    } else {
      discarded.add(i);
      add(9,
          current: i,
          log: 'active already ends sooner (or equal) - discard $iv and '
              'keep active as is.');
    }
  }

  // 11: return removed
  add(11,
      log: 'Done → minimum removals = $removed.',
      status: NonOverlapStatus.done);

  return steps;
}
