/// Deterministic step model for the Valid Parentheses visualizer.
///
/// We run the real stack algorithm once, up front, recording ONE [VpStep] per
/// pseudocode line executed. Stepping the UI is then pure index movement.
///
/// Algorithm: scan the string. Push every opening bracket. On a closing
/// bracket, the stack top must be its matching opener - pop and check. A close
/// with an empty stack, a mismatched pair, or any leftover openers at the end
/// all mean the string is invalid.
library;

enum VpStatus { running, valid, invalid }

/// Full pseudocode shown in the panel. `line` in a [VpStep] is 1-based.
const List<String> validParenthesesPseudocode = [
  'for ch in s:', // 1
  '  if ch is one of ( [ {:', // 2
  '    stack.push(ch)', // 3
  '  else:  // ch is a closing bracket', // 4
  '    if stack is empty:', // 5
  '      return false', // 6
  '    open ← stack.pop()', // 7
  '    if open does not match ch:', // 8
  '      return false', // 9
  'return stack is empty', // 10
];

const Map<String, String> _pairFor = {')': '(', ']': '[', '}': '{'};
const Set<String> _openers = {'(', '[', '{'};

class VpStep {
  final int line; // 1-based pseudocode line highlighted
  final int? i; // current char index in the string
  final List<String> stack; // stack contents, bottom → top
  final String? badge; // comparison/decision just made
  final String log; // plain-English trace entry
  final Set<String> changed; // variable names updated this step (for pulse)
  final VpStatus status;

  const VpStep({
    required this.line,
    this.i,
    required this.stack,
    this.badge,
    required this.log,
    this.changed = const {},
    this.status = VpStatus.running,
  });
}

/// Runs the balanced-brackets check over [raw], recording every line executed.
/// Non-bracket characters in the input are ignored (kept simple/robust).
List<VpStep> generateValidParenthesesSteps(String raw) {
  final chars = raw
      .split('')
      .where((c) => _openers.contains(c) || _pairFor.containsKey(c))
      .toList();
  final s = chars.join();
  final steps = <VpStep>[];
  final stack = <String>[];

  if (s.isEmpty) {
    steps.add(VpStep(
      line: 10,
      stack: const [],
      log: 'Empty string - trivially balanced.',
      status: VpStatus.valid,
    ));
    return steps;
  }

  for (var i = 0; i < s.length; i++) {
    final ch = s[i];
    steps.add(VpStep(
      line: 1,
      i: i,
      stack: List<String>.from(stack),
      log: "Read character '$ch' at index $i.",
      changed: {'ch'},
    ));

    final isOpen = _openers.contains(ch);
    steps.add(VpStep(
      line: 2,
      i: i,
      stack: List<String>.from(stack),
      badge: "'$ch' is an opening bracket? $isOpen",
      log: "Is '$ch' an opening bracket? $isOpen",
    ));

    if (isOpen) {
      stack.add(ch);
      steps.add(VpStep(
        line: 3,
        i: i,
        stack: List<String>.from(stack),
        log: "Push '$ch' onto the stack (waiting for its match).",
        changed: {'stack'},
      ));
      continue;
    }

    // Closing bracket branch.
    steps.add(VpStep(
      line: 4,
      i: i,
      stack: List<String>.from(stack),
      log: "'$ch' is a closing bracket - it must match the current top.",
    ));

    final empty = stack.isEmpty;
    steps.add(VpStep(
      line: 5,
      i: i,
      stack: List<String>.from(stack),
      badge: 'stack is empty? $empty',
      log: empty
          ? 'Stack is empty - no opener to match this closer.'
          : 'Stack is not empty - pop the top to compare.',
    ));
    if (empty) {
      steps.add(VpStep(
        line: 6,
        i: i,
        stack: List<String>.from(stack),
        log: "No matching '(' before '$ch' → not valid.",
        status: VpStatus.invalid,
      ));
      return steps;
    }

    final open = stack.removeLast();
    steps.add(VpStep(
      line: 7,
      i: i,
      stack: List<String>.from(stack),
      badge: "open ← '$open'",
      log: "Pop the top: open = '$open'.",
      changed: {'open', 'stack'},
    ));

    final mismatch = _pairFor[ch] != open;
    steps.add(VpStep(
      line: 8,
      i: i,
      stack: List<String>.from(stack),
      badge: "'$open' matches '$ch'? ${!mismatch}",
      log: mismatch
          ? "'$open' does not close with '$ch' (need '${_pairFor[ch]}')."
          : "'$open' correctly closes with '$ch'.",
    ));
    if (mismatch) {
      steps.add(VpStep(
        line: 9,
        i: i,
        stack: List<String>.from(stack),
        log: "Mismatched pair '$open$ch' → not valid.",
        status: VpStatus.invalid,
      ));
      return steps;
    }
  }

  final balanced = stack.isEmpty;
  steps.add(VpStep(
    line: 10,
    stack: List<String>.from(stack),
    badge: 'stack is empty? $balanced',
    log: balanced
        ? 'Reached the end with an empty stack → valid.'
        : 'Reached the end but ${stack.length} opener(s) still unmatched → not valid.',
    status: balanced ? VpStatus.valid : VpStatus.invalid,
  ));
  return steps;
}
