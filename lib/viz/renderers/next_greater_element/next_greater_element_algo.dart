/// Deterministic step model for the Next Greater Element visualizer.
///
/// We run the real monotonic-stack algorithm once, up front, recording ONE
/// [NgeStep] per pseudocode line executed. Stepping the UI is then pure index
/// movement - a click always advances exactly one line.
///
/// Algorithm (O(n)): keep a **strictly decreasing** stack of *indices*. Scan
/// left→right; when the current value is greater than the value at the stack's
/// top, those smaller elements have just found their next greater element (the
/// current one) - pop each and record it. Push the current index. Anything left
/// on the stack at the end has no greater element to its right → −1.
library;

enum NgeStatus { running, done }

/// Full pseudocode shown in the panel. `line` in an [NgeStep] is 1-based into
/// this list.
const List<String> ngePseudocode = [
  'nge[k] ← −1 for all k', // 1
  'for i ← 0 … n−1:', // 2
  '  while stack not empty and arr[stack.top] < arr[i]:', // 3
  '    j ← stack.pop()', // 4
  '    nge[j] ← arr[i]', // 5
  '  stack.push(i)', // 6
  'return nge', // 7
];

class NgeStep {
  final int line; // 1-based pseudocode line highlighted
  final int? i; // current scan index
  final List<int> stack; // stack contents as array indices, bottom → top
  final List<num> nge; // result so far (−1 = unresolved)
  final int? poppedIndex; // array index just popped (for highlight)
  final int? pushedIndex; // array index just pushed
  final String? badge; // comparison/decision just made
  final String log; // plain-English trace entry
  final Set<String> changed; // variable names updated this step (for pulse)
  final NgeStatus status;

  const NgeStep({
    required this.line,
    this.i,
    required this.stack,
    required this.nge,
    this.poppedIndex,
    this.pushedIndex,
    this.badge,
    required this.log,
    this.changed = const {},
    this.status = NgeStatus.running,
  });
}

/// Runs the monotonic-stack NGE algorithm over [rawArray], recording every line
/// executed. The stack holds indices; the strictly-decreasing invariant means
/// `arr[stack[0]] > arr[stack[1]] > …` from bottom to top.
List<NgeStep> generateNgeSteps(List<num> rawArray) {
  final arr = List<num>.from(rawArray);
  final n = arr.length;
  final steps = <NgeStep>[];

  final nge = List<num>.filled(n, -1);
  final stack = <int>[];

  if (n == 0) {
    steps.add(NgeStep(
      line: 7,
      stack: const [],
      nge: const [],
      log: 'Array is empty - nothing to do.',
      status: NgeStatus.done,
    ));
    return steps;
  }

  steps.add(NgeStep(
    line: 1,
    stack: const [],
    nge: List<num>.from(nge),
    log: 'Initialise nge[k] ← −1 for every index (no answer yet).',
    changed: {'nge'},
  ));

  for (var i = 0; i < n; i++) {
    steps.add(NgeStep(
      line: 2,
      i: i,
      stack: List<int>.from(stack),
      nge: List<num>.from(nge),
      log: 'Consider arr[$i] = ${arr[i]}.',
      changed: {'i'},
    ));

    while (true) {
      final canPop = stack.isNotEmpty && arr[stack.last] < arr[i];
      final topStr = stack.isEmpty ? '∅' : 'arr[${stack.last}]=${arr[stack.last]}';
      steps.add(NgeStep(
        line: 3,
        i: i,
        stack: List<int>.from(stack),
        nge: List<num>.from(nge),
        badge: stack.isEmpty
            ? 'stack empty → stop popping'
            : '$topStr < arr[$i]=${arr[i]} → $canPop',
        log: stack.isEmpty
            ? 'Stack is empty - nothing smaller waiting; stop popping.'
            : 'Is top ($topStr) smaller than arr[$i]=${arr[i]}? $canPop',
      ));
      if (!canPop) break;

      final j = stack.removeLast();
      steps.add(NgeStep(
        line: 4,
        i: i,
        stack: List<int>.from(stack),
        nge: List<num>.from(nge),
        poppedIndex: j,
        badge: 'pop index $j (value ${arr[j]})',
        log: 'arr[$i] is bigger → pop index $j (value ${arr[j]}).',
      ));

      nge[j] = arr[i];
      steps.add(NgeStep(
        line: 5,
        i: i,
        stack: List<int>.from(stack),
        nge: List<num>.from(nge),
        poppedIndex: j,
        badge: 'nge[$j] ← ${arr[i]}',
        log: 'Next greater element of ${arr[j]} is arr[$i] = ${arr[i]}.',
        changed: {'nge'},
      ));
    }

    stack.add(i);
    steps.add(NgeStep(
      line: 6,
      i: i,
      stack: List<int>.from(stack),
      nge: List<num>.from(nge),
      pushedIndex: i,
      log: 'Push index $i. Stack stays strictly decreasing by value.',
      changed: {'stack'},
    ));
  }

  final leftover = stack.map((k) => arr[k]).join(', ');
  steps.add(NgeStep(
    line: 7,
    stack: List<int>.from(stack),
    nge: List<num>.from(nge),
    log: stack.isEmpty
        ? 'Scan complete. Every element found a next greater element.'
        : 'Scan complete. Leftover on stack [$leftover] have no greater element → −1.',
    status: NgeStatus.done,
  ));
  return steps;
}
