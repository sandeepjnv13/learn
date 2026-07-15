/// Deterministic step model for the bottom-up (tabulation) min-cost-path
/// visualizer.
///
/// The whole table is filled up front and ONE [MinPathStep] is recorded per
/// pseudocode line executed, so stepping the UI is pure index movement and a
/// click can never double-fire.
///
/// Same recurrence as the memoized recursion on the same page -
/// `dp[i][j] = grid[i][j] + min(dp[i-1][j], dp[i][j-1])` - just evaluated in an
/// order that guarantees both predecessors are already known, so no recursion
/// (and no call stack) is needed.
library;

enum MinPathStatus { filling, done }

/// Full pseudocode shown in the panel. `line` in a [MinPathStep] is 1-based
/// into this list.
const List<String> minPathDpPseudocode = [
  'dp[0][0] ← grid[0][0]', // 1
  'for j ← 1 to n−1:', // 2
  '  dp[0][j] ← dp[0][j−1] + grid[0][j]', // 3
  'for i ← 1 to m−1:', // 4
  '  dp[i][0] ← dp[i−1][0] + grid[i][0]', // 5
  'for i ← 1 to m−1:', // 6
  '  for j ← 1 to n−1:', // 7
  '    best ← min(dp[i−1][j], dp[i][j−1])', // 8
  '    dp[i][j] ← grid[i][j] + best', // 9
  'return dp[m−1][n−1]', // 10
];

class MinPathStep {
  /// 1-based pseudocode line highlighted.
  final int line;

  /// Snapshot of the table; null = not filled yet.
  final List<List<num?>> dp;

  /// Cell being written this step.
  final int? row;
  final int? col;

  /// Predecessor the value came from - drives the provenance arrow.
  final int? fromRow;
  final int? fromCol;

  /// Cells on the cheapest path, set only on the terminal step.
  final Set<String> path;

  final String? badge;
  final String log;
  final Set<String> changed;
  final MinPathStatus status;

  const MinPathStep({
    required this.line,
    required this.dp,
    this.row,
    this.col,
    this.fromRow,
    this.fromCol,
    this.path = const {},
    this.badge,
    required this.log,
    this.changed = const {},
    this.status = MinPathStatus.filling,
  });

  num? get answer => dp[dp.length - 1][dp[0].length - 1];
}

List<List<num?>> _snapshot(List<List<num?>> dp) =>
    [for (final row in dp) List<num?>.from(row)];

String _k(int i, int j) => '$i,$j';

/// Fills the table row by row, recording every pseudocode line executed.
List<MinPathStep> generateMinPathDpSteps(List<List<num>> grid) {
  final m = grid.length;
  final n = m == 0 ? 0 : grid[0].length;
  final steps = <MinPathStep>[];

  if (m == 0 || n == 0) {
    steps.add(const MinPathStep(
      line: 10,
      dp: [
        [null]
      ],
      log: 'Grid is empty - nothing to walk.',
      status: MinPathStatus.done,
    ));
    return steps;
  }

  final dp = List.generate(m, (_) => List<num?>.filled(n, null));

  dp[0][0] = grid[0][0];
  steps.add(MinPathStep(
    line: 1,
    dp: _snapshot(dp),
    row: 0,
    col: 0,
    log: 'Start cell costs ${grid[0][0]} - dp[0][0] ← ${grid[0][0]}',
    changed: {'dp[i][j]'},
  ));

  // Top row: there is no cell above, so the only way in is from the left.
  for (var j = 1; j < n; j++) {
    steps.add(MinPathStep(
      line: 2,
      dp: _snapshot(dp),
      log: 'Top row, j = $j - only the left neighbour can reach it',
      changed: {'j'},
    ));
    dp[0][j] = dp[0][j - 1]! + grid[0][j];
    steps.add(MinPathStep(
      line: 3,
      dp: _snapshot(dp),
      row: 0,
      col: j,
      fromRow: 0,
      fromCol: j - 1,
      badge: 'dp[0][${j - 1}] (${dp[0][j - 1]}) + grid[0][$j] (${grid[0][j]})',
      log: 'dp[0][$j] ← ${dp[0][j - 1]} + ${grid[0][j]} = ${dp[0][j]}',
      changed: {'dp[i][j]'},
    ));
  }

  // Left column: no cell to the left, so the only way in is from above.
  for (var i = 1; i < m; i++) {
    steps.add(MinPathStep(
      line: 4,
      dp: _snapshot(dp),
      log: 'Left column, i = $i - only the cell above can reach it',
      changed: {'i'},
    ));
    dp[i][0] = dp[i - 1][0]! + grid[i][0];
    steps.add(MinPathStep(
      line: 5,
      dp: _snapshot(dp),
      row: i,
      col: 0,
      fromRow: i - 1,
      fromCol: 0,
      badge: 'dp[${i - 1}][0] (${dp[i - 1][0]}) + grid[$i][0] (${grid[i][0]})',
      log: 'dp[$i][0] ← ${dp[i - 1][0]} + ${grid[i][0]} = ${dp[i][0]}',
      changed: {'dp[i][j]'},
    ));
  }

  // The interior: both predecessors are already final, so just take the cheaper.
  for (var i = 1; i < m; i++) {
    steps.add(MinPathStep(
      line: 6,
      dp: _snapshot(dp),
      log: 'Row i = $i',
      changed: {'i'},
    ));
    for (var j = 1; j < n; j++) {
      steps.add(MinPathStep(
        line: 7,
        dp: _snapshot(dp),
        row: i,
        col: j,
        log: 'Column j = $j - solving dp[$i][$j]',
        changed: {'j'},
      ));

      final up = dp[i - 1][j]!;
      final left = dp[i][j - 1]!;
      final fromUp = up <= left;
      steps.add(MinPathStep(
        line: 8,
        dp: _snapshot(dp),
        row: i,
        col: j,
        fromRow: fromUp ? i - 1 : i,
        fromCol: fromUp ? j : j - 1,
        badge: 'min(above $up, left $left) → ${fromUp ? up : left}',
        log: 'Cheaper way in: ${fromUp ? 'above' : 'left'} '
            '(${fromUp ? up : left}) - both are already final',
        changed: {'best'},
      ));

      dp[i][j] = grid[i][j] + (fromUp ? up : left);
      steps.add(MinPathStep(
        line: 9,
        dp: _snapshot(dp),
        row: i,
        col: j,
        fromRow: fromUp ? i - 1 : i,
        fromCol: fromUp ? j : j - 1,
        log: 'dp[$i][$j] ← ${grid[i][j]} + ${fromUp ? up : left} = ${dp[i][j]}',
        changed: {'dp[i][j]'},
      ));
    }
  }

  // Walk back from the corner to light up the cheapest path.
  final path = <String>{};
  var pi = m - 1;
  var pj = n - 1;
  path.add(_k(pi, pj));
  while (pi > 0 || pj > 0) {
    if (pi == 0) {
      pj--;
    } else if (pj == 0) {
      pi--;
    } else if (dp[pi - 1][pj]! <= dp[pi][pj - 1]!) {
      pi--;
    } else {
      pj--;
    }
    path.add(_k(pi, pj));
  }

  steps.add(MinPathStep(
    line: 10,
    dp: _snapshot(dp),
    row: m - 1,
    col: n - 1,
    path: path,
    log: 'The corner holds the answer: ${dp[m - 1][n - 1]}',
    status: MinPathStatus.done,
  ));

  return steps;
}
