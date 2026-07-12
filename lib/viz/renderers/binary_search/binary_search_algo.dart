/// Deterministic step model for the binary-search visualizer.
///
/// Rather than run a live state machine (which risks double-firing on a click),
/// we execute the whole algorithm up front and record ONE [BsStep] per
/// pseudocode line executed. Stepping is then just moving an index — always
/// predictable.
library;

enum BsStatus { searching, found, notFound }

/// Full pseudocode shown in the panel. `line` in a [BsStep] is 1-based into
/// this list.
const List<String> binarySearchPseudocode = [
  'lo ← 0', // 1
  'hi ← n − 1', // 2
  'while lo ≤ hi:', // 3
  '  mid ← (lo + hi) / 2', // 4
  '  if arr[mid] = target:', // 5
  '    return mid', // 6
  '  else if arr[mid] < target:', // 7
  '    lo ← mid + 1', // 8
  '  else:', // 9
  '    hi ← mid − 1', // 10
  'return −1', // 11
];

class BsStep {
  final int line; // 1-based pseudocode line highlighted
  final int? lo;
  final int? hi;
  final int? mid;
  final int? foundIndex;
  final String? badge; // comparison/decision just made
  final String log; // plain-English trace entry
  final Set<String> changed; // variable names updated this step (for pulse)
  final BsStatus status;

  const BsStep({
    required this.line,
    this.lo,
    this.hi,
    this.mid,
    this.foundIndex,
    this.badge,
    required this.log,
    this.changed = const {},
    this.status = BsStatus.searching,
  });
}

/// Runs binary search over a copy of [rawArray] (sorted first, since binary
/// search requires it) looking for [target], recording every line executed.
List<BsStep> generateBinarySearchSteps(List<num> rawArray, num target) {
  final arr = List<num>.from(rawArray)..sort((a, b) => a.compareTo(b));
  final n = arr.length;
  final steps = <BsStep>[];

  if (n == 0) {
    steps.add(BsStep(
      line: 11,
      log: 'Array is empty — $target not found.',
      status: BsStatus.notFound,
    ));
    return steps;
  }

  int lo = 0;
  steps.add(BsStep(line: 1, lo: lo, log: 'lo ← 0', changed: {'lo'}));

  int hi = n - 1;
  steps.add(BsStep(
    line: 2,
    lo: lo,
    hi: hi,
    log: 'hi ← n − 1 = ${n - 1}',
    changed: {'hi'},
  ));

  int? mid;

  while (true) {
    final cond = lo <= hi;
    steps.add(BsStep(
      line: 3,
      lo: lo,
      hi: hi,
      mid: mid,
      badge: 'lo ($lo) ≤ hi ($hi) → $cond',
      log: 'Check lo ≤ hi → $cond',
    ));
    if (!cond) break;

    mid = (lo + hi) ~/ 2;
    steps.add(BsStep(
      line: 4,
      lo: lo,
      hi: hi,
      mid: mid,
      log: 'mid ← ($lo + $hi) / 2 = $mid',
      changed: {'mid'},
    ));

    final atMid = arr[mid];
    final eq = atMid == target;
    steps.add(BsStep(
      line: 5,
      lo: lo,
      hi: hi,
      mid: mid,
      badge: 'arr[mid] ($atMid) = target ($target) → $eq',
      log: 'Compare arr[$mid] = $atMid with target $target',
    ));
    if (eq) {
      steps.add(BsStep(
        line: 6,
        lo: lo,
        hi: hi,
        mid: mid,
        foundIndex: mid,
        log: 'Found $target at index $mid → return $mid',
        status: BsStatus.found,
      ));
      return steps;
    }

    final lt = atMid < target;
    steps.add(BsStep(
      line: 7,
      lo: lo,
      hi: hi,
      mid: mid,
      badge: 'arr[mid] ($atMid) < target ($target) → $lt',
      log: 'Is arr[$mid] < target? $lt',
    ));

    if (lt) {
      lo = mid + 1;
      steps.add(BsStep(
        line: 8,
        lo: lo,
        hi: hi,
        mid: mid,
        log: 'Target is bigger → search right half: lo ← mid + 1 = $lo',
        changed: {'lo'},
      ));
    } else {
      hi = mid - 1;
      steps.add(BsStep(
        line: 10,
        lo: lo,
        hi: hi,
        mid: mid,
        log: 'Target is smaller → search left half: hi ← mid − 1 = $hi',
        changed: {'hi'},
      ));
    }
  }

  steps.add(BsStep(
    line: 11,
    lo: lo,
    hi: hi,
    mid: mid,
    log: '$target not found → return −1',
    status: BsStatus.notFound,
  ));
  return steps;
}
