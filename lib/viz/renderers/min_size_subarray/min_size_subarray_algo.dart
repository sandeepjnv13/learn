/// Deterministic step model for the LeetCode 209 (Minimum Size Subarray Sum)
/// visualizer.
///
/// Like every recorder in the kit we run the real algorithm once, up front,
/// and emit ONE [MssStep] per pseudocode line executed - stepping the UI is
/// then pure index movement and can never double-fire.
///
/// This is the **sliding-window** flavour of two pointers (same-direction,
/// variable-size window), as opposed to the **converging** flavour in
/// `three_sum_algo.dart`. Every iteration of the outer loop follows the same
/// three moves, which the pseudocode lines below are grouped to make explicit:
///   1. ADD     - fold `nums[i]` into the window sum.
///   2. MAINTAIN - shrink from the left while the window would still be
///      valid *after* the removal, so the window is always minimal before
///      it's used.
///   3. USE     - if the window is valid, record it as a candidate answer.
library;

enum MssStatus { running, found, notFound, empty }

/// Full pseudocode shown in the panel. `line` in a [MssStep] is 1-based into
/// this list.
const List<String> minSizeSubarrayPseudocode = [
  'start ← 0 ;  windowSum ← 0 ;  best ← ∞', // 1
  'for i in 0 … n−1:', // 2
  '  windowSum ← windowSum + nums[i]        // 1. add', // 3
  '  while windowSum ≥ target and start ≤ i:  // 2. maintain', // 4
  '    if windowSum − nums[start] ≥ target:', // 5
  '      windowSum −= nums[start] ; start++', // 6
  '    else: break', // 7
  '  if windowSum ≥ target:                  // 3. use', // 8
  '    best ← min(best, i − start + 1)', // 9
  'return best == ∞ ? 0 : best', // 10
];

class MssStep {
  final int line; // 1-based pseudocode line highlighted
  final int? i; // right edge of the window (current element)
  final int? start; // left edge of the window
  final num? windowSum;
  final num? best; // finite candidate answer so far (null if none yet)
  final String? badge; // comparison/decision just made
  final String log; // plain-English trace entry
  final Set<String> changed; // variable names updated this step (for pulse)
  final Set<int> matched; // indices flashed green as the best window so far
  final MssStatus status;

  const MssStep({
    required this.line,
    this.i,
    this.start,
    this.windowSum,
    this.best,
    this.badge,
    required this.log,
    this.changed = const {},
    this.matched = const {},
    this.status = MssStatus.running,
  });
}

/// Runs the shrinking-window scan over [nums] looking for the shortest
/// contiguous subarray with sum ≥ [target], recording every pseudocode line
/// executed. Mirrors the exact shape of the reference Java solution: the
/// window only shrinks while removing the leftmost element would *still*
/// leave it valid, so it is always minimal before being measured.
List<MssStep> generateMinSizeSubarraySteps(List<num> nums, num target) {
  final n = nums.length;
  final steps = <MssStep>[];

  if (n == 0) {
    steps.add(const MssStep(
      line: 1,
      status: MssStatus.empty,
      log: 'nums is empty - there is no subarray to measure. Return 0.',
    ));
    return steps;
  }

  var start = 0;
  num windowSum = 0;
  num? best;
  final bestWindow = <int>{};

  steps.add(MssStep(
    line: 1,
    start: start,
    windowSum: windowSum,
    best: best,
    changed: const {'start', 'windowSum', 'best'},
    log: 'start ← 0, windowSum ← 0, best ← ∞.',
  ));

  for (var i = 0; i < n; i++) {
    steps.add(MssStep(
      line: 2,
      i: i,
      start: start,
      windowSum: windowSum,
      best: best,
      matched: Set.of(bestWindow),
      log: 'i ← $i (nums[$i] = ${nums[i]}).',
    ));

    // 1. ADD - fold the current element into the window.
    windowSum += nums[i];
    steps.add(MssStep(
      line: 3,
      i: i,
      start: start,
      windowSum: windowSum,
      best: best,
      changed: const {'windowSum'},
      matched: Set.of(bestWindow),
      log: 'Add nums[$i] = ${nums[i]} to the window → windowSum = $windowSum.',
    ));

    // 2. MAINTAIN - shrink from the left while still valid afterwards.
    while (true) {
      final guard = windowSum >= target && start <= i;
      steps.add(MssStep(
        line: 4,
        i: i,
        start: start,
        windowSum: windowSum,
        best: best,
        badge: 'windowSum ($windowSum) ≥ target ($target) and start ($start) '
            '≤ i ($i) → $guard',
        matched: Set.of(bestWindow),
        log: guard
            ? 'Window sum reaches target - try shrinking it from the left.'
            : 'Window is not (yet) valid or is empty - nothing to shrink.',
      ));
      if (!guard) break;

      final canShrink = windowSum - nums[start] >= target;
      steps.add(MssStep(
        line: 5,
        i: i,
        start: start,
        windowSum: windowSum,
        best: best,
        badge: 'windowSum ($windowSum) − nums[$start] (${nums[start]}) ≥ '
            'target ($target) → $canShrink',
        matched: Set.of(bestWindow),
        log: canShrink
            ? 'Removing nums[$start] would still leave the window valid - '
                'shrink it.'
            : 'Removing nums[$start] would drop below target - stop '
                'shrinking, this is the minimal valid window for i = $i.',
      ));

      if (canShrink) {
        windowSum -= nums[start];
        start++;
        steps.add(MssStep(
          line: 6,
          i: i,
          start: start,
          windowSum: windowSum,
          best: best,
          changed: const {'windowSum', 'start'},
          matched: Set.of(bestWindow),
          log: 'Drop nums[${start - 1}] → windowSum = $windowSum, '
              'start = $start.',
        ));
      } else {
        steps.add(MssStep(
          line: 7,
          i: i,
          start: start,
          windowSum: windowSum,
          best: best,
          matched: Set.of(bestWindow),
          log: 'Break out of the shrink loop.',
        ));
        break;
      }
    }

    // 3. USE - a still-valid window is a length candidate.
    final valid = windowSum >= target;
    steps.add(MssStep(
      line: 8,
      i: i,
      start: start,
      windowSum: windowSum,
      best: best,
      badge: 'windowSum ($windowSum) ≥ target ($target) → $valid',
      matched: Set.of(bestWindow),
      log: valid
          ? 'Window [$start..$i] is valid - measure it.'
          : 'Window is not valid - no candidate from this i.',
    ));

    if (valid) {
      final len = i - start + 1;
      final improved = best == null || len < best;
      if (improved) {
        best = len;
        bestWindow
          ..clear()
          ..addAll([for (var k = start; k <= i; k++) k]);
      }
      steps.add(MssStep(
        line: 9,
        i: i,
        start: start,
        windowSum: windowSum,
        best: best,
        changed: const {'best'},
        matched: Set.of(bestWindow),
        badge: improved ? 'new best length $len' : 'length $len - no improvement',
        log: improved
            ? 'best ← min(best, $len) = $len - new shortest window.'
            : 'best ← min(best, $len) - stays $best.',
      ));
    }
  }

  steps.add(MssStep(
    line: 10,
    start: start,
    best: best,
    matched: Set.of(bestWindow),
    status: best == null ? MssStatus.notFound : MssStatus.found,
    log: best == null
        ? 'No window ever reached target $target - return 0.'
        : 'Scan complete - shortest window has length $best. Return $best.',
  ));
  return steps;
}
