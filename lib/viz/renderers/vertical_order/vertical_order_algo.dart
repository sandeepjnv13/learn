/// Deterministic step recorder for Vertical Order Traversal of a Binary Tree
/// (LeetCode 987).
///
/// The algorithm has two distinct halves, and this recorder shows both:
///   1. a **recursive DFS** that stamps every node with a `(col, row)`
///      coordinate (root at `(0, 0)`, left is `col-1`, right is `col+1`, every
///      step down is `row+1`), and
///   2. a **non-recursive** pass that sorts the collected tuples by
///      `(col, row, val)` and groups them column by column into the answer.
///
/// Like every recorder in this kit we run the real algorithm once, up front,
/// and record ONE step per pseudocode line executed — so stepping the UI is
/// pure index movement and can never double-fire. During the DFS half each step
/// also snapshots the live **call stack** (as shared [RecursionFrame]s) and its
/// [RecursionPhase]; during the grouping half the stack is empty and
/// [grouping] is true.
///
/// Pure Dart (no Flutter): the tree is passed as plain id→field maps so the
/// recorder stays trivially testable.
library;

import '../../components/recursion_model.dart';

enum VerticalOrderStatus { running, done }

/// Full pseudocode shown in the panel. `line` in a [VerticalOrderStep] is
/// 1-based here. Lines 1–10 are the outer routine; line 11 is a spacer; lines
/// 12–16 are the recursive DFS.
const List<String> verticalOrderPseudocode = [
  'verticalTraversal(root):', // 1
  '  nodes = []', // 2
  '  dfs(root, col=0, row=0)', // 3
  '  sort nodes by (col, row, val)', // 4
  '  columns = []; prevCol = -∞', // 5
  '  for (col, row, val) in nodes:', // 6
  '    if col ≠ prevCol:', // 7
  '      columns.add([]); prevCol = col', // 8
  '    columns.last.add(val)', // 9
  '  return columns', // 10
  '', // 11 (spacer)
  'dfs(node, col, row):', // 12
  '  if node == null: return', // 13
  '  nodes.add((col, row, node.val))', // 14
  '  dfs(node.left,  col−1, row+1)', // 15
  '  dfs(node.right, col+1, row+1)', // 16
];

class VerticalOrderStep {
  final int line; // 1-based pseudocode line highlighted
  final RecursionPhase phase;

  /// Live call stack this step (top of stack last). Empty during grouping.
  final List<RecursionFrame> stack;

  // ── Tree / DFS state ──────────────────────────────────────────────────
  /// Node currently being examined (processing highlight), or null.
  final int? current;

  /// Node ids on the active recursion path (spine highlight).
  final Set<int> spine;

  /// Nodes recorded into `nodes` so far (placed on the board).
  final Set<int> collected;

  /// Coordinate stamped on each collected node.
  final Map<int, int> colOf;
  final Map<int, int> rowOf;

  // ── Grouping (non-recursive) state ────────────────────────────────────
  /// True once the DFS is done and the sort/group pass is running.
  final bool grouping;

  /// Column value currently being built (highlight band), or null.
  final int? activeCol;

  /// Node whose tuple is being read this grouping step, or null.
  final int? currentId;

  /// Nodes already appended into `columns`.
  final Set<int> placed;

  /// The `prevCol` loop variable; null means -∞ (before the first column).
  final int? prevCol;

  /// The answer built so far — grouped columns of values.
  final List<List<num>> columns;

  final String? badge; // the decision just made
  final String log; // plain-English trace entry
  final Set<String> changed; // variable names updated this step (pulse)
  final VerticalOrderStatus status;

  const VerticalOrderStep({
    required this.line,
    required this.phase,
    required this.stack,
    this.current,
    this.spine = const {},
    this.collected = const {},
    this.colOf = const {},
    this.rowOf = const {},
    this.grouping = false,
    this.activeCol,
    this.currentId,
    this.placed = const {},
    this.prevCol,
    this.columns = const [],
    this.badge,
    required this.log,
    this.changed = const {},
    this.status = VerticalOrderStatus.running,
  });
}

/// Mutable per-call frame used while recording the DFS.
class _Frame {
  final int id;
  final num value;
  final int col;
  final int row;
  _Frame(this.id, this.value, this.col, this.row);
}

/// Records vertical order traversal over a tree given as id-keyed maps.
///
/// [value], [left], [right] describe each node; [rootId] is the tree root.
List<VerticalOrderStep> generateVerticalOrderSteps({
  required Map<int, num> value,
  required Map<int, int?> left,
  required Map<int, int?> right,
  required int? rootId,
}) {
  final steps = <VerticalOrderStep>[];

  if (rootId == null || !value.containsKey(rootId)) {
    steps.add(const VerticalOrderStep(
      line: 1,
      phase: RecursionPhase.base,
      stack: [],
      grouping: true,
      log: 'The tree is empty — the vertical order traversal is [].',
      status: VerticalOrderStatus.done,
    ));
    return steps;
  }

  final stack = <_Frame>[];
  final collected = <int>{};
  final colOf = <int, int>{};
  final rowOf = <int, int>{};
  final placed = <int>{};
  final columns = <List<num>>[];
  int? prevCol;

  List<RecursionFrame> snapshot({int? returningId}) {
    return [
      for (final f in stack)
        RecursionFrame(
          signature: 'dfs(${f.value})',
          refId: f.id,
          active: f.id == stack.last.id,
          returning: returningId == f.id,
          locals: [
            FrameLocal('col', '${f.col}'),
            FrameLocal('row', '${f.row}'),
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
    bool grouping = false,
    int? activeCol,
    int? currentId,
    Set<String> changed = const {},
    VerticalOrderStatus status = VerticalOrderStatus.running,
  }) {
    steps.add(VerticalOrderStep(
      line: line,
      phase: phase,
      stack: grouping ? const [] : snapshot(returningId: returningId),
      current: current,
      spine: {for (final f in stack) f.id},
      collected: {...collected},
      colOf: {...colOf},
      rowOf: {...rowOf},
      grouping: grouping,
      activeCol: activeCol,
      currentId: currentId,
      placed: {...placed},
      prevCol: prevCol,
      columns: [for (final c in columns) [...c]],
      badge: badge,
      log: log,
      changed: changed,
      status: status,
    ));
  }

  // ── DFS half (recursive) ───────────────────────────────────────────────
  add(
    line: 2,
    phase: RecursionPhase.descend,
    log: 'Start with an empty list of (col, row, val) tuples.',
    badge: 'nodes = []',
    changed: const {'nodes'},
  );
  add(
    line: 3,
    phase: RecursionPhase.descend,
    current: rootId,
    log: 'Begin DFS at the root, column 0, row 0.',
    badge: 'dfs(root, 0, 0)',
  );

  void solve(int id, int col, int row) {
    final f = _Frame(id, value[id]!, col, row);
    stack.add(f);
    final v = f.value;

    add(
      line: 13,
      phase: RecursionPhase.descend,
      current: id,
      badge: 'node $v is not null → keep going',
      log: 'Enter dfs($v) at column $col, row $row.',
    );

    collected.add(id);
    colOf[id] = col;
    rowOf[id] = row;
    add(
      line: 14,
      phase: RecursionPhase.descend,
      current: id,
      changed: const {'nodes'},
      badge: 'record ($col, $row, $v)',
      log: 'Place node $v on the board at column $col, row $row. '
          'Collected ${collected.length} node${collected.length == 1 ? '' : 's'}.',
    );

    // Line 15 — left child.
    final leftId = left[id];
    if (leftId == null) {
      add(
        line: 15,
        phase: RecursionPhase.base,
        current: id,
        badge: 'left child of $v is null → return',
        log: 'dfs(node.left) of $v is null — nothing to record.',
      );
    } else {
      add(
        line: 15,
        phase: RecursionPhase.descend,
        current: leftId,
        badge: 'recurse left → col ${col - 1}, row ${row + 1}',
        log: 'Descend left into ${value[leftId]} (column ${col - 1}).',
      );
      solve(leftId, col - 1, row + 1);
    }

    // Line 16 — right child.
    final rightId = right[id];
    if (rightId == null) {
      add(
        line: 16,
        phase: RecursionPhase.base,
        current: id,
        badge: 'right child of $v is null → return',
        log: 'dfs(node.right) of $v is null — nothing to record.',
      );
    } else {
      add(
        line: 16,
        phase: RecursionPhase.descend,
        current: rightId,
        badge: 'recurse right → col ${col + 1}, row ${row + 1}',
        log: 'Descend right into ${value[rightId]} (column ${col + 1}).',
      );
      solve(rightId, col + 1, row + 1);
    }

    // Return (void) — pop the frame.
    add(
      line: 16,
      phase: RecursionPhase.returnUp,
      current: id,
      returningId: id,
      badge: 'dfs($v) done → return to caller',
      log: 'Finished node $v; return up and continue.',
    );
    stack.removeLast();
  }

  solve(rootId, 0, 0);

  // ── Sort + group half (non-recursive) ──────────────────────────────────
  final sorted = collected.toList()
    ..sort((a, b) {
      if (colOf[a] != colOf[b]) return colOf[a]!.compareTo(colOf[b]!);
      if (rowOf[a] != rowOf[b]) return rowOf[a]!.compareTo(rowOf[b]!);
      return value[a]!.compareTo(value[b]!);
    });

  add(
    line: 4,
    phase: RecursionPhase.combine,
    grouping: true,
    log: 'DFS done. Sort the tuples by column, then row, then value — because '
        'each node already sits at its (col, row), the board is now in reading '
        'order: left→right by column, top→bottom by row, ties by value.',
    badge: 'sort by (col, row, val)',
    changed: const {'nodes'},
  );

  add(
    line: 5,
    phase: RecursionPhase.combine,
    grouping: true,
    log: 'Start with no columns and prevCol = -∞.',
    badge: 'columns = [], prevCol = -∞',
    changed: const {'columns', 'prevCol'},
  );

  for (final id in sorted) {
    final col = colOf[id]!;
    final row = rowOf[id]!;
    final v = value[id]!;

    add(
      line: 6,
      phase: RecursionPhase.combine,
      grouping: true,
      activeCol: col,
      currentId: id,
      badge: 'read tuple ($col, $row, $v)',
      log: 'Take the next tuple: value $v at column $col, row $row.',
      changed: const {'current'},
    );

    final prevText = prevCol == null ? '-∞' : '$prevCol';
    if (prevCol != col) {
      add(
        line: 7,
        phase: RecursionPhase.combine,
        grouping: true,
        activeCol: col,
        currentId: id,
        badge: 'col $col ≠ prevCol $prevText → new column',
        log: 'Column $col differs from prevCol ($prevText) — open a new column.',
      );
      columns.add(<num>[]);
      prevCol = col;
      add(
        line: 8,
        phase: RecursionPhase.combine,
        grouping: true,
        activeCol: col,
        currentId: id,
        changed: const {'columns', 'prevCol'},
        badge: 'start column ${columns.length}; prevCol = $col',
        log: 'Started column ${columns.length} (for col $col); prevCol = $col.',
      );
    } else {
      add(
        line: 7,
        phase: RecursionPhase.combine,
        grouping: true,
        activeCol: col,
        currentId: id,
        badge: 'col $col == prevCol → same column',
        log: 'Column $col equals prevCol — stay in the current column.',
      );
    }

    columns.last.add(v);
    placed.add(id);
    add(
      line: 9,
      phase: RecursionPhase.combine,
      grouping: true,
      activeCol: col,
      currentId: id,
      changed: const {'columns'},
      badge: 'append $v to column ${columns.length}',
      log: 'Append $v to the current column → ${columns.last}.',
    );
  }

  add(
    line: 10,
    phase: RecursionPhase.returnUp,
    grouping: true,
    badge: 'return ${columns.length} column${columns.length == 1 ? '' : 's'}',
    log: 'Done — the vertical order traversal is '
        '${columns.map((c) => c.toList()).toList()}.',
    status: VerticalOrderStatus.done,
  );

  return steps;
}
