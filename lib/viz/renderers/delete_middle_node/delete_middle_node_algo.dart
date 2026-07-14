/// Deterministic step model for the "delete the middle node of a linked list"
/// visualizer (LeetCode 2095).
///
/// As with the other recorders we run the whole algorithm up front and record
/// ONE [DmnStep] per pseudocode line executed, so stepping the UI is pure index
/// movement and can never double-fire.
///
/// Approach: two pointers walk the list - `fast` moves two nodes per iteration,
/// `slow` one, and `prev` (starting null) trails one step behind `slow`. When
/// `fast` falls off the end, `slow` sits on the middle node and `prev` is the
/// node just before it, so `prev.next = slow.next` unlinks the middle. A list of
/// fewer than two nodes empties out, returning null.
library;

enum DmnStatus { running, removed, empty }

/// Full pseudocode shown in the panel. `line` in a [DmnStep] is 1-based into
/// this list.
const List<String> deleteMiddleNodePseudocode = [
  'if head is null:  return null', // 1
  'if head.next is null:  return null', // 2  (single node → empty list)
  'slow ← head', // 3
  'fast ← head', // 4
  'prev ← null', // 5
  'while fast ≠ null and fast.next ≠ null:', // 6
  '  prev ← slow', // 7
  '  slow ← slow.next', // 8
  '  fast ← fast.next.next', // 9
  'prev.next ← slow.next   # unlink middle', // 10
  'return head', // 11
];

class DmnStep {
  final int line; // 1-based pseudocode line highlighted
  final int? slow; // node index, or null pointer
  final int? fast;
  final int? prev;

  /// True once `fast` has walked *off the end* to the null terminal (as opposed
  /// to simply not being initialised yet). Lets the view park the marker on the
  /// trailing `null` node instead of hiding it.
  final bool fastAtNull;
  final int? removedIndex; // set once the middle node is unlinked
  final String? badge; // decision just made
  final String log; // plain-English trace
  final Set<String> changed; // variable names updated this step (for pulse)
  final DmnStatus status;

  const DmnStep({
    required this.line,
    this.slow,
    this.fast,
    this.prev,
    this.fastAtNull = false,
    this.removedIndex,
    this.badge,
    required this.log,
    this.changed = const {},
    this.status = DmnStatus.running,
  });
}

/// Runs the algorithm over a list whose node values are [values] (index = node
/// position), recording every pseudocode line executed.
List<DmnStep> generateDeleteMiddleNodeSteps(List<num> values) {
  final n = values.length;
  final steps = <DmnStep>[];

  // Line 1 - head is null?  (true only for an empty list)
  final headNull = n == 0;
  steps.add(DmnStep(
    line: 1,
    badge: 'head = null → $headNull',
    log: 'Check whether the list is empty → $headNull',
    status: headNull ? DmnStatus.empty : DmnStatus.running,
  ));
  if (headNull) {
    steps.add(const DmnStep(
      line: 1,
      log: 'Empty list - nothing to delete → return null.',
      status: DmnStatus.empty,
    ));
    return steps;
  }

  // Line 2 - head.next is null?  (true only for a single node)
  final single = n == 1;
  steps.add(DmnStep(
    line: 2,
    badge: 'head.next = null → $single',
    log: 'Check whether there is only one node → $single',
    status: single ? DmnStatus.empty : DmnStatus.running,
  ));
  if (single) {
    steps.add(const DmnStep(
      line: 2,
      log: 'Only one node - it is the middle, so deleting it empties the '
          'list → return null.',
      status: DmnStatus.empty,
    ));
    return steps;
  }

  // Line 3-5 - initialise the pointers.
  int slow = 0;
  steps.add(DmnStep(
    line: 3,
    slow: slow,
    log: 'slow ← head (node 0)',
    changed: {'slow'},
  ));

  int? fast = 0;
  steps.add(DmnStep(
    line: 4,
    slow: slow,
    fast: fast,
    log: 'fast ← head (node 0)',
    changed: {'fast'},
  ));

  int? prev;
  steps.add(DmnStep(
    line: 5,
    slow: slow,
    fast: fast,
    prev: prev,
    log: 'prev ← null (it will trail one step behind slow)',
    changed: {'prev'},
  ));

  // Line 6-9 - advance until fast walks off the end.
  while (true) {
    final fastNotNull = fast != null;
    final fastNextNotNull = fast != null && fast + 1 <= n - 1;
    final cond = fastNotNull && fastNextNotNull;
    steps.add(DmnStep(
      line: 6,
      slow: slow,
      fast: fast,
      prev: prev,
      fastAtNull: fast == null,
      badge: 'fast ${fastNotNull ? '≠ null' : '= null'} and '
          'fast.next ${fastNextNotNull ? '≠ null' : '= null'} → $cond',
      log: 'Loop check → $cond',
    ));
    if (!cond) break;

    prev = slow;
    steps.add(DmnStep(
      line: 7,
      slow: slow,
      fast: fast,
      prev: prev,
      log: 'prev ← slow (node $prev)',
      changed: {'prev'},
    ));

    slow = slow + 1;
    steps.add(DmnStep(
      line: 8,
      slow: slow,
      fast: fast,
      prev: prev,
      log: 'slow advances one → node $slow',
      changed: {'slow'},
    ));

    fast = fast + 2 <= n - 1 ? fast + 2 : null;
    steps.add(DmnStep(
      line: 9,
      slow: slow,
      fast: fast,
      prev: prev,
      fastAtNull: fast == null,
      log: 'fast jumps two → ${fast == null ? 'null (past the end)' : 'node $fast'}',
      changed: {'fast'},
    ));
  }

  // Line 10 - unlink the middle node (slow), reconnecting prev to slow.next.
  final removedIndex = slow;
  final removedVal = values[removedIndex];
  final nextOfSlow = slow + 1 <= n - 1 ? 'node ${slow + 1}' : 'null';
  steps.add(DmnStep(
    line: 10,
    slow: slow,
    fast: fast,
    prev: prev,
    fastAtNull: fast == null,
    removedIndex: removedIndex,
    badge: 'prev.next ← slow.next',
    log: 'Middle is node $removedIndex (value $removedVal). '
        'Link prev (node $prev) straight to $nextOfSlow - node '
        '$removedIndex is now unlinked.',
    status: DmnStatus.removed,
  ));

  // Line 11 - return the (unchanged) head of the healed list.
  steps.add(DmnStep(
    line: 11,
    slow: slow,
    fast: fast,
    prev: prev,
    fastAtNull: fast == null,
    removedIndex: removedIndex,
    log: 'Return head - the list now skips the deleted middle node.',
    status: DmnStatus.removed,
  ));

  return steps;
}
