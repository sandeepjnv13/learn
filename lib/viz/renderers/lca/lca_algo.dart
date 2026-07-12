/// Deterministic step recorder for Lowest Common Ancestor of a Binary Tree
/// (LeetCode 236), post-order recursion.
///
/// Like every recorder in this kit we run the real algorithm once, up front,
/// and record ONE [LcaStep] per pseudocode line executed — so stepping the UI
/// is pure index movement and can never double-fire. Because the algorithm is
/// recursive, each step also snapshots the live **call stack** (as shared
/// [RecursionFrame]s) and its [RecursionPhase], which is what makes the
/// "descend then combine on the way back up" flow legible.
///
/// Pure Dart (no Flutter): the tree is passed as plain id→field maps so the
/// recorder stays trivially testable. The view maps the emitted node-role sets
/// to semantic colors.
library;

import '../../components/recursion_model.dart';

enum LcaStatus { running, found, notFound }

/// Full pseudocode shown in the panel. `line` in an [LcaStep] is 1-based here.
const List<String> lcaPseudocode = [
  'lca(root):', // 1
  '  if root == null or root == p or root == q:', // 2
  '    return root', // 3
  '  leftLca  = lca(root.left)', // 4
  '  rightLca = lca(root.right)', // 5
  '  if leftLca ≠ null and rightLca ≠ null:', // 6
  '    return root        # p, q on different sides → this is the LCA', // 7
  '  if leftLca ≠ null:  return leftLca', // 8
  '  return rightLca', // 9
];

class LcaStep {
  final int line; // 1-based pseudocode line highlighted
  final RecursionPhase phase;

  /// Live call stack this step (top of stack last).
  final List<RecursionFrame> stack;

  /// Node currently being examined (processing highlight), or null.
  final int? current;

  /// Nodes whose recursive call has returned null so far (dead subtrees).
  final Set<int> returnedNull;

  /// Node id → the node id its call returned (a found target bubbling up).
  final Map<int, int> returnedFound;

  /// Node ids on the active recursion path (for spine highlighting).
  final Set<int> spine;

  /// The final LCA node id, once determined.
  final int? resultId;

  final String? badge; // the decision just made
  final String log; // plain-English trace entry
  final LcaStatus status;

  const LcaStep({
    required this.line,
    required this.phase,
    required this.stack,
    this.current,
    this.returnedNull = const {},
    this.returnedFound = const {},
    this.spine = const {},
    this.resultId,
    this.badge,
    required this.log,
    this.status = LcaStatus.running,
  });
}

/// Mutable per-call frame state used while recording.
class _Frame {
  final int id;
  final num value;
  bool leftStarted = false;
  bool leftDone = false;
  int? leftVal;
  bool rightStarted = false;
  bool rightDone = false;
  int? rightVal;
  _Frame(this.id, this.value);
}

/// Records the recursive LCA over a tree given as id-keyed maps.
///
/// [value], [left], [right] describe each node; [rootId] is the tree root and
/// [pId]/[qId] are the two target node ids. Returns the recorded steps.
List<LcaStep> generateLcaSteps({
  required Map<int, num> value,
  required Map<int, int?> left,
  required Map<int, int?> right,
  required int? rootId,
  required int? pId,
  required int? qId,
}) {
  final steps = <LcaStep>[];

  if (rootId == null || !value.containsKey(rootId)) {
    steps.add(const LcaStep(
      line: 1,
      phase: RecursionPhase.base,
      stack: [],
      log: 'The tree is empty — there is no ancestor to find.',
      status: LcaStatus.notFound,
    ));
    return steps;
  }
  if (pId == null || qId == null) {
    steps.add(const LcaStep(
      line: 1,
      phase: RecursionPhase.base,
      stack: [],
      log: 'Pick two distinct target nodes (p and q) to find their LCA.',
      status: LcaStatus.notFound,
    ));
    return steps;
  }

  final stack = <_Frame>[];
  final returnedNull = <int>{};
  final returnedFound = <int, int>{};
  int? resultId;

  String describe(int? id) => id == null ? 'null' : '${value[id]}';

  List<RecursionFrame> snapshot({int? returningId, String? returnValue}) {
    return [
      for (final f in stack)
        RecursionFrame(
          signature: 'lca(${f.value})',
          refId: f.id,
          active: f.id == stack.last.id,
          returning: returningId == f.id,
          returns: returningId == f.id ? returnValue : null,
          locals: [
            if (f.leftStarted)
              FrameLocal('leftLca',
                  f.leftDone ? describe(f.leftVal) : '…',
                  resolved: f.leftDone),
            if (f.rightStarted)
              FrameLocal('rightLca',
                  f.rightDone ? describe(f.rightVal) : '…',
                  resolved: f.rightDone),
          ],
        ),
    ];
  }

  void add({
    required int line,
    required RecursionPhase phase,
    required String log,
    String? badge,
    int? current,
    int? returningId,
    String? returnValue,
    int? result,
    LcaStatus status = LcaStatus.running,
  }) {
    steps.add(LcaStep(
      line: line,
      phase: phase,
      stack: snapshot(returningId: returningId, returnValue: returnValue),
      current: current,
      returnedNull: {...returnedNull},
      returnedFound: {...returnedFound},
      spine: {for (final f in stack) f.id},
      resultId: result ?? resultId,
      badge: badge,
      log: log,
      status: status,
    ));
  }

  // Recurses over a real (non-null) node; returns the node id it resolves to.
  int? solve(int nodeId, {required bool isRoot}) {
    final f = _Frame(nodeId, value[nodeId]!);
    stack.add(f);

    // Line 2 — base case check (this also visually "enters" the frame).
    final isTarget = nodeId == pId || nodeId == qId;
    add(
      line: 2,
      phase: isTarget ? RecursionPhase.base : RecursionPhase.descend,
      current: nodeId,
      badge: isTarget
          ? 'node ${f.value} == ${nodeId == pId ? 'p' : 'q'} → base case'
          : 'node ${f.value}: not null, not p, not q → keep going',
      log: 'Enter lca(${f.value}). '
          '${isTarget ? 'It is a target — base case.' : 'Not a target — recurse into its children.'}',
    );

    if (isTarget) {
      // Line 3 — return root (itself) up.
      returnedFound[nodeId] = nodeId;
      add(
        line: 3,
        phase: RecursionPhase.returnUp,
        current: nodeId,
        returningId: nodeId,
        returnValue: '${f.value}',
        badge: 'return node ${f.value}',
        log: 'Base case hit — return node ${f.value} up to its caller.',
      );
      stack.removeLast();
      return nodeId;
    }

    // Line 4 — leftLca = lca(root.left)
    f.leftStarted = true;
    final leftId = left[nodeId];
    if (leftId == null) {
      f.leftDone = true;
      f.leftVal = null;
      add(
        line: 4,
        phase: RecursionPhase.base,
        current: nodeId,
        badge: 'left child of ${f.value} is null → leftLca = null',
        log: 'lca(${f.value}).left is null → leftLca = null.',
      );
    } else {
      add(
        line: 4,
        phase: RecursionPhase.descend,
        current: leftId,
        badge: 'recurse into left child (${value[leftId]}) of ${f.value}',
        log: 'Descend left: call lca(${value[leftId]}).',
      );
      final r = solve(leftId, isRoot: false);
      f.leftVal = r;
      f.leftDone = true;
      add(
        line: 4,
        phase: RecursionPhase.combine,
        current: nodeId,
        badge: 'leftLca ← ${describe(r)}',
        log: 'Back in lca(${f.value}): leftLca = ${describe(r)}.',
      );
    }

    // Line 5 — rightLca = lca(root.right)
    f.rightStarted = true;
    final rightId = right[nodeId];
    if (rightId == null) {
      f.rightDone = true;
      f.rightVal = null;
      add(
        line: 5,
        phase: RecursionPhase.base,
        current: nodeId,
        badge: 'right child of ${f.value} is null → rightLca = null',
        log: 'lca(${f.value}).right is null → rightLca = null.',
      );
    } else {
      add(
        line: 5,
        phase: RecursionPhase.descend,
        current: rightId,
        badge: 'recurse into right child (${value[rightId]}) of ${f.value}',
        log: 'Descend right: call lca(${value[rightId]}).',
      );
      final r = solve(rightId, isRoot: false);
      f.rightVal = r;
      f.rightDone = true;
      add(
        line: 5,
        phase: RecursionPhase.combine,
        current: nodeId,
        badge: 'rightLca ← ${describe(r)}',
        log: 'Back in lca(${f.value}): rightLca = ${describe(r)}.',
      );
    }

    // Line 6 — both sides non-null?
    final both = f.leftVal != null && f.rightVal != null;
    add(
      line: 6,
      phase: RecursionPhase.combine,
      current: nodeId,
      badge: 'leftLca ${f.leftVal == null ? '= null' : '≠ null'} and '
          'rightLca ${f.rightVal == null ? '= null' : '≠ null'} → $both',
      log: 'Combine: leftLca = ${describe(f.leftVal)}, '
          'rightLca = ${describe(f.rightVal)}.',
    );

    int? result;
    if (both) {
      // Line 7 — this node is the LCA.
      resultId = nodeId;
      result = nodeId;
      returnedFound[nodeId] = nodeId;
      add(
        line: 7,
        phase: RecursionPhase.returnUp,
        current: nodeId,
        returningId: nodeId,
        returnValue: '${f.value}',
        result: nodeId,
        badge: 'both targets found → node ${f.value} is the LCA',
        log: 'p and q were found on different sides → node ${f.value} is the '
            'lowest common ancestor. Return it up.',
        status: isRoot ? LcaStatus.found : LcaStatus.running,
      );
    } else if (f.leftVal != null) {
      // Line 8 — bubble the left result up.
      result = f.leftVal;
      returnedFound[nodeId] = f.leftVal!;
      add(
        line: 8,
        phase: RecursionPhase.returnUp,
        current: nodeId,
        returningId: nodeId,
        returnValue: describe(f.leftVal),
        badge: 'leftLca ≠ null → return leftLca (${describe(f.leftVal)})',
        log: 'Only the left side found something → pass ${describe(f.leftVal)} '
            'up unchanged.',
        status: isRoot ? LcaStatus.found : LcaStatus.running,
      );
    } else {
      // Line 9 — return rightLca (may itself be null).
      result = f.rightVal;
      if (f.rightVal == null) {
        returnedNull.add(nodeId);
      } else {
        returnedFound[nodeId] = f.rightVal!;
      }
      add(
        line: 9,
        phase: RecursionPhase.returnUp,
        current: nodeId,
        returningId: nodeId,
        returnValue: describe(f.rightVal),
        badge: 'return rightLca (${describe(f.rightVal)})',
        log: f.rightVal == null
            ? 'Neither side found a target → return null.'
            : 'Only the right side found something → pass '
                '${describe(f.rightVal)} up unchanged.',
        status: isRoot && f.rightVal != null
            ? LcaStatus.found
            : LcaStatus.running,
      );
    }

    stack.removeLast();
    return result;
  }

  final answer = solve(rootId, isRoot: true);
  resultId = answer;

  // Terminal summary step (stack empty, answer settled).
  steps.add(LcaStep(
    line: answer == null ? 9 : (answer == resultId ? 7 : 8),
    phase: RecursionPhase.returnUp,
    stack: const [],
    returnedNull: {...returnedNull},
    returnedFound: {...returnedFound},
    resultId: answer,
    current: answer,
    badge: answer == null
        ? 'no common ancestor'
        : 'LCA = node ${value[answer]}',
    log: answer == null
        ? 'Recursion finished — p and q have no common ancestor in this tree.'
        : 'Recursion finished — the lowest common ancestor is node '
            '${value[answer]}.',
    status: answer == null ? LcaStatus.notFound : LcaStatus.found,
  ));

  return steps;
}
