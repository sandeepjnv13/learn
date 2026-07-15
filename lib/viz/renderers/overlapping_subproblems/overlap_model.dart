/// Flutter-free model for the "overlapping subproblems" demo.
///
/// Expands the min-cost-path recursion
///
///   minCost(i, j) = grid[i][j] + min(minCost(i-1, j), minCost(i, j-1))
///   minCost(0, 0) = grid[0][0]
///
/// two ways - once naively (every call re-explored) and once memoized (a repeat
/// call returns from the cache as a childless stub) - so the view can show the
/// same tree collapsing. Every number the page quotes (node counts, repeat
/// counts, the memo table) is derived here rather than hardcoded.
library;

/// A single call in an expanded recursion tree.
class CallNode {
  final int id;
  final int i;
  final int j;

  /// Child call ids in call order: `(i-1, j)` before `(i, j-1)`.
  final List<int> children;

  /// What this call returned.
  final num value;

  /// True when the memo already held the answer, so the call returned at once
  /// and never expanded its children.
  final bool cacheHit;

  const CallNode({
    required this.id,
    required this.i,
    required this.j,
    required this.children,
    required this.value,
    this.cacheHit = false,
  });
}

/// An expanded recursion tree plus the tallies the page talks about.
class CallTree {
  final List<CallNode> nodes;
  final int rootId;

  const CallTree({required this.nodes, required this.rootId});

  /// Every call drawn, cache-hit stubs included.
  int get nodeCount => nodes.length;

  /// Calls that actually did work (i.e. were not answered from the memo).
  int get computeCount => nodes.where((n) => !n.cacheHit).length;

  /// Calls answered straight from the memo.
  int get cacheHitCount => nodes.where((n) => n.cacheHit).length;

  /// How many times each cell is visited, keyed `'i,j'`.
  Map<String, int> get cellCounts {
    final counts = <String, int>{};
    for (final n in nodes) {
      counts.update('${n.i},${n.j}', (v) => v + 1, ifAbsent: () => 1);
    }
    return counts;
  }

  num get answer => nodes.firstWhere((n) => n.id == rootId).value;
}

String cellKey(int i, int j) => '$i,$j';

/// Size of the naive tree **without expanding it** - the same recurrence as the
/// node count itself (`nodes(i,j) = 1 + nodes(i-1,j) + nodes(i,j-1)`), so a
/// caller can budget before building a tree that grows exponentially.
int naiveNodeCount(List<List<num>> grid) {
  final m = grid.length;
  final n = grid[0].length;
  final f = List.generate(m, (_) => List<int>.filled(n, 0));
  for (var i = 0; i < m; i++) {
    for (var j = 0; j < n; j++) {
      f[i][j] = 1 +
          (i > 0 ? f[i - 1][j] : 0) +
          (j > 0 ? f[i][j - 1] : 0);
    }
  }
  return f[m - 1][n - 1];
}

/// Fully expanded, **unmemoized** recursion tree rooted at the bottom-right
/// cell - the exponential one, where the same cell is recomputed over and over.
CallTree buildNaiveTree(List<List<num>> grid) {
  final nodes = <CallNode>[];
  var nextId = 0;

  // Returns the call's id and what it evaluated to.
  (int, num) expand(int i, int j) {
    final id = nextId++;
    final children = <int>[];
    num value;
    if (i == 0 && j == 0) {
      value = grid[0][0];
    } else {
      num best = double.infinity;
      if (i > 0) {
        final (childId, v) = expand(i - 1, j);
        children.add(childId);
        best = v;
      }
      if (j > 0) {
        final (childId, v) = expand(i, j - 1);
        children.add(childId);
        if (v < best) best = v;
      }
      value = grid[i][j] + best;
    }
    nodes.add(CallNode(
      id: id,
      i: i,
      j: j,
      children: children,
      value: value,
    ));
    return (id, value);
  }

  final (rootId, _) = expand(grid.length - 1, grid[0].length - 1);
  return CallTree(nodes: nodes, rootId: rootId);
}

/// The **memoized** recursion tree: the same call order, but a cell already in
/// the memo returns immediately as a childless stub. The tree stops growing the
/// moment every distinct cell has been solved once.
CallTree buildMemoTree(List<List<num>> grid) {
  final nodes = <CallNode>[];
  final memo = <String, num>{};
  var nextId = 0;

  (int, num) expand(int i, int j) {
    final id = nextId++;
    final key = cellKey(i, j);

    // A hit: answer straight from the memo, explore nothing.
    final cached = memo[key];
    if (cached != null) {
      nodes.add(CallNode(
        id: id,
        i: i,
        j: j,
        children: const [],
        value: cached,
        cacheHit: true,
      ));
      return (id, cached);
    }

    final children = <int>[];
    num value;
    if (i == 0 && j == 0) {
      value = grid[0][0];
    } else {
      num best = double.infinity;
      if (i > 0) {
        final (childId, v) = expand(i - 1, j);
        children.add(childId);
        best = v;
      }
      if (j > 0) {
        final (childId, v) = expand(i, j - 1);
        children.add(childId);
        if (v < best) best = v;
      }
      value = grid[i][j] + best;
    }

    memo[key] = value;
    nodes.add(CallNode(
      id: id,
      i: i,
      j: j,
      children: children,
      value: value,
    ));
    return (id, value);
  }

  final (rootId, _) = expand(grid.length - 1, grid[0].length - 1);
  return CallTree(nodes: nodes, rootId: rootId);
}

/// The memo table once the memoized run finishes: `table[i][j]` is the cheapest
/// cost from the top-left corner to `(i, j)`.
List<List<num>> buildMemoTable(List<List<num>> grid) {
  final tree = buildMemoTree(grid);
  final table = List.generate(
    grid.length,
    (i) => List<num>.filled(grid[0].length, 0),
  );
  for (final n in tree.nodes) {
    table[n.i][n.j] = n.value;
  }
  return table;
}

/// Tint index per repeated cell, keyed `'i,j'`.
///
/// Only cells visited **more than once** get a tint - those are the overlapping
/// subproblems, and they are the whole point of the picture. Cells visited once
/// stay neutral so the color-matched ones stand out instead of drowning in a
/// rainbow. Ordered by first appearance so the naive tree, the memoized tree,
/// and the memo table all agree on which color means which cell.
Map<String, int> repeatedCellTints(CallTree tree) {
  final counts = tree.cellCounts;
  final tints = <String, int>{};
  // Root-first order: nodes are appended post-order, so walk the deepest,
  // most-repeated cells in a stable order by (i, j).
  final repeated = counts.keys.where((k) => counts[k]! > 1).toList()
    ..sort((a, b) {
      final pa = a.split(',').map(int.parse).toList();
      final pb = b.split(',').map(int.parse).toList();
      final byI = pa[0].compareTo(pb[0]);
      return byI != 0 ? byI : pa[1].compareTo(pb[1]);
    });
  for (var k = 0; k < repeated.length; k++) {
    tints[repeated[k]] = k;
  }
  return tints;
}
