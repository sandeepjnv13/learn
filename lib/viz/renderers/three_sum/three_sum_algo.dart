/// Deterministic step model for the 3Sum (LeetCode 15) two-pointer visualizer.
///
/// Like every recorder in the kit we run the real algorithm once, up front, and
/// emit ONE [ThreeSumStep] per pseudocode line executed — stepping the UI is
/// then pure index movement and can never double-fire. The array is **sorted**
/// first (the whole reason the converging two-pointer sweep works), then for
/// each fixed anchor `i` a `lo`/`hi` pair walks inward.
library;

enum ThreeSumStatus { sorting, running, done }

/// Full pseudocode shown in the panel. `line` in a [ThreeSumStep] is 1-based
/// into this list.
const List<String> threeSumPseudocode = [
  'sort(nums)', // 1
  'for i in 0 … n−3:', // 2
  '  if i > 0 and nums[i] == nums[i−1]: continue', // 3
  '  lo ← i+1 ;  hi ← n−1', // 4
  '  while lo < hi:', // 5
  '    s ← nums[i] + nums[lo] + nums[hi]', // 6
  '    if s == 0:', // 7
  '      add [nums[i], nums[lo], nums[hi]]', // 8
  '      lo++ ; hi−− ;  skip duplicates', // 9
  '    else if s < 0:  lo++', // 10
  '    else:           hi−−', // 11
  'return triplets', // 12
];

class ThreeSumStep {
  final int line; // 1-based pseudocode line highlighted
  final int? i; // fixed anchor index
  final int? lo; // converging low pointer
  final int? hi; // converging high pointer
  final num? sum; // nums[i] + nums[lo] + nums[hi] this step
  final String? badge; // comparison/decision just made
  final String log; // plain-English trace entry
  final Set<String> changed; // variable names updated this step (for pulse)
  final Set<int> matched; // indices flashed green as a recorded triplet
  final List<List<num>> triplets; // snapshot of triplets found so far
  final ThreeSumStatus status;

  const ThreeSumStep({
    required this.line,
    this.i,
    this.lo,
    this.hi,
    this.sum,
    this.badge,
    required this.log,
    this.changed = const {},
    this.matched = const {},
    this.triplets = const [],
    this.status = ThreeSumStatus.running,
  });
}

/// Runs 3Sum over a copy of [rawArray] (sorted first), recording every
/// pseudocode line executed. Returns all unique triplets summing to zero.
List<ThreeSumStep> generateThreeSumSteps(List<num> rawArray) {
  final nums = List<num>.from(rawArray)..sort((a, b) => a.compareTo(b));
  final n = nums.length;
  final steps = <ThreeSumStep>[];
  final found = <List<num>>[];

  List<List<num>> snap() => [for (final t in found) List<num>.from(t)];

  // 1 — sort. Sorting is the precondition that makes converging pointers valid.
  steps.add(ThreeSumStep(
    line: 1,
    status: ThreeSumStatus.sorting,
    log: n == 0
        ? 'Sort the array (it is empty).'
        : 'Sort nums → [${nums.join(', ')}]. A sorted array is what lets two '
            'pointers converge.',
    triplets: snap(),
  ));

  if (n < 3) {
    steps.add(ThreeSumStep(
      line: 12,
      status: ThreeSumStatus.done,
      badge: 'fewer than 3 numbers',
      log: 'Fewer than 3 numbers — no triplet is possible. Return [].',
      triplets: snap(),
    ));
    return steps;
  }

  for (var i = 0; i <= n - 3; i++) {
    // 2 — fix the anchor for this pass.
    steps.add(ThreeSumStep(
      line: 2,
      i: i,
      changed: const {'i'},
      badge: 'anchor i = $i  (nums[i] = ${nums[i]})',
      log: 'Fix anchor nums[$i] = ${nums[i]}; now find a pair after it summing '
          'to ${-nums[i]}.',
      triplets: snap(),
    ));

    // 3 — skip a repeated anchor so triplets are not duplicated.
    final dupAnchor = i > 0 && nums[i] == nums[i - 1];
    steps.add(ThreeSumStep(
      line: 3,
      i: i,
      badge: i > 0
          ? 'nums[$i] (${nums[i]}) == nums[${i - 1}] (${nums[i - 1]}) → $dupAnchor'
          : 'first anchor — nothing before it',
      log: dupAnchor
          ? 'nums[$i] repeats the previous anchor — skip it to avoid duplicate '
              'triplets.'
          : 'Anchor is not a repeat — proceed.',
      triplets: snap(),
    ));
    if (dupAnchor) continue;

    // 4 — set the pointers on the remaining sub-array.
    var lo = i + 1;
    var hi = n - 1;
    steps.add(ThreeSumStep(
      line: 4,
      i: i,
      lo: lo,
      hi: hi,
      changed: const {'lo', 'hi'},
      log: 'lo ← ${i + 1}, hi ← ${n - 1}. Converge them from both ends.',
      triplets: snap(),
    ));

    while (true) {
      // 5 — loop guard.
      final cond = lo < hi;
      steps.add(ThreeSumStep(
        line: 5,
        i: i,
        lo: lo,
        hi: hi,
        badge: 'lo ($lo) < hi ($hi) → $cond',
        log: cond
            ? 'Pointers have not crossed — keep scanning.'
            : 'lo met hi — this anchor is exhausted.',
        triplets: snap(),
      ));
      if (!cond) break;

      // 6 — sum the three.
      final s = nums[i] + nums[lo] + nums[hi];
      steps.add(ThreeSumStep(
        line: 6,
        i: i,
        lo: lo,
        hi: hi,
        sum: s,
        changed: const {'sum'},
        badge: 's = ${nums[i]} + ${nums[lo]} + ${nums[hi]} = $s',
        log: 'Sum the anchor and both pointers → $s.',
        triplets: snap(),
      ));

      // 7 — is it zero?
      final isZero = s == 0;
      steps.add(ThreeSumStep(
        line: 7,
        i: i,
        lo: lo,
        hi: hi,
        sum: s,
        badge: 's ($s) == 0 → $isZero',
        log: 'Is the sum zero? $isZero.',
        triplets: snap(),
      ));

      if (isZero) {
        // 8 — record the triplet.
        found.add([nums[i], nums[lo], nums[hi]]);
        steps.add(ThreeSumStep(
          line: 8,
          i: i,
          lo: lo,
          hi: hi,
          sum: s,
          matched: {i, lo, hi},
          badge: 'triplet found',
          log: 'Triplet! Record [${nums[i]}, ${nums[lo]}, ${nums[hi]}].',
          triplets: snap(),
        ));

        // 9 — step both inward, skipping equal values on each side.
        final prevLo = lo, prevHi = hi;
        lo++;
        hi--;
        while (lo < hi && nums[lo] == nums[lo - 1]) {
          lo++;
        }
        while (lo < hi && nums[hi] == nums[hi + 1]) {
          hi--;
        }
        final skipped = lo - prevLo > 1 || prevHi - hi > 1;
        steps.add(ThreeSumStep(
          line: 9,
          i: i,
          lo: lo,
          hi: hi,
          changed: const {'lo', 'hi'},
          log: skipped
              ? 'Move both inward, skipping equal values so the same triplet is '
                  'not recorded twice (lo→$lo, hi→$hi).'
              : 'Move both pointers inward (lo→$lo, hi→$hi).',
          triplets: snap(),
        ));
      } else if (s < 0) {
        // 10 — too small: only a bigger value can help, so raise lo.
        lo++;
        steps.add(ThreeSumStep(
          line: 10,
          i: i,
          lo: lo,
          hi: hi,
          sum: s,
          changed: const {'lo'},
          badge: 's ($s) < 0 → lo++',
          log: 'Sum is too small — only a larger value helps, so lo++ → $lo.',
          triplets: snap(),
        ));
      } else {
        // 11 — too big: only a smaller value can help, so lower hi.
        hi--;
        steps.add(ThreeSumStep(
          line: 11,
          i: i,
          lo: lo,
          hi: hi,
          sum: s,
          changed: const {'hi'},
          badge: 's ($s) > 0 → hi−−',
          log: 'Sum is too big — only a smaller value helps, so hi−− → $hi.',
          triplets: snap(),
        ));
      }
    }
  }

  // 12 — done.
  steps.add(ThreeSumStep(
    line: 12,
    status: ThreeSumStatus.done,
    badge: found.isEmpty
        ? 'no triplet sums to 0'
        : '${found.length} triplet(s) found',
    log: found.isEmpty
        ? 'Scan complete — no triplet sums to zero. Return [].'
        : 'Scan complete — return ${found.length} triplet(s).',
    triplets: snap(),
  ));
  return steps;
}
