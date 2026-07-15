import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../components/components.dart';
import '../../registry.dart';
import 'overlap_model.dart';

/// The **concept** card for dynamic programming: one click flips the same
/// min-cost-path recursion between naive and memoized, so the tree visibly
/// collapses and the memo table fills.
///
/// Not a stepper - there is no algorithm to walk here, only two pictures of the
/// same recursion to compare. The pseudocode panel flips with the tree, so the
/// two extra lines that caused the collapse are right next to their effect.
///
/// Config:
///   type: overlapping-subproblems
///   grid: [[1, 3, 1], [1, 5, 1], [4, 2, 1]]
class OverlappingSubproblemsView extends StatefulWidget {
  final VizContext ctx;
  const OverlappingSubproblemsView(this.ctx, {super.key});

  static void register() {
    VizRegistry.register(
      'overlapping-subproblems',
      (ctx) => OverlappingSubproblemsView(ctx),
    );
  }

  @override
  State<OverlappingSubproblemsView> createState() =>
      _OverlappingSubproblemsViewState();
}

class _OverlappingSubproblemsViewState
    extends State<OverlappingSubproblemsView> {
  bool _memoized = false;

  late final List<List<num>> _grid;
  late final CallTree _naive;
  late final CallTree _memo;
  late final List<List<num>> _memoTable;
  late final Map<String, int> _tints;

  /// Naive expansion is exponential; past this the tree stops being a picture
  /// and starts being a wall, so the config is clamped back to the default.
  static const int _nodeBudget = 120;

  static const List<List<num>> _fallback = [
    [1, 3, 1],
    [1, 5, 1],
    [4, 2, 1],
  ];

  @override
  void initState() {
    super.initState();
    _grid = _parseConfig();
    _naive = buildNaiveTree(_grid);
    _memo = buildMemoTree(_grid);
    _memoTable = buildMemoTable(_grid);
    _tints = repeatedCellTints(_naive);
  }

  List<List<num>> _parseConfig() {
    final raw = widget.ctx.config['grid'];
    if (raw is List && raw.isNotEmpty) {
      final rows = <List<num>>[];
      for (final r in raw) {
        if (r is List && r.isNotEmpty) {
          rows.add(r.map((v) => v is num ? v : num.tryParse('$v'.trim()) ?? 0).toList());
        }
      }
      final ok = rows.isNotEmpty &&
          rows.every((r) => r.length == rows[0].length) &&
          naiveNodeCount(rows) <= _nodeBudget;
      if (ok) return rows;
    }
    return _fallback.map((r) => List<num>.from(r)).toList();
  }

  String _fmt(num n) =>
      n is int || n == n.roundToDouble() ? n.toInt().toString() : n.toString();

  CallTree get _tree => _memoized ? _memo : _naive;

  // ── Pseudocode ────────────────────────────────────────────────────────

  static const List<String> _naivePseudocode = [
    'minCost(i, j):',
    '  if i = 0 and j = 0:',
    '    return grid[0][0]',
    '  best ← ∞',
    '  if i > 0:',
    '    best ← min(best, minCost(i−1, j))',
    '  if j > 0:',
    '    best ← min(best, minCost(i, j−1))',
    '  return grid[i][j] + best',
  ];

  static const List<String> _memoPseudocode = [
    'memo ← empty map',
    '',
    'minCost(i, j):',
    '  if i = 0 and j = 0:',
    '    return grid[0][0]',
    '  if (i, j) in memo:',
    '    return memo[(i, j)]',
    '  best ← ∞',
    '  if i > 0:',
    '    best ← min(best, minCost(i−1, j))',
    '  if j > 0:',
    '    best ← min(best, minCost(i, j−1))',
    '  memo[(i, j)] ← grid[i][j] + best',
    '  return memo[(i, j)]',
  ];

  // ── Derived view state ────────────────────────────────────────────────

  List<CallNodeSpec> _callNodes() {
    return [
      for (final n in _tree.nodes)
        CallNodeSpec(
          id: n.id,
          label: '(${n.i},${n.j})',
          children: n.children,
          tint: _tints[cellKey(n.i, n.j)],
          cacheHit: n.cacheHit,
          returns: n.cacheHit ? null : '→ ${_fmt(n.value)}',
          state: VizState.inScope,
        ),
    ];
  }

  List<GridCellSpec> _memoCells() {
    final lastRow = _grid.length - 1;
    final lastCol = _grid[0].length - 1;
    return [
      for (var i = 0; i < _grid.length; i++)
        for (var j = 0; j < _grid[0].length; j++)
          GridCellSpec(
            row: i,
            col: j,
            value: _fmt(_memoTable[i][j]),
            corner: _fmt(_grid[i][j]),
            tint: _tints[cellKey(i, j)],
            state: i == lastRow && j == lastCol
                ? VizState.found
                : VizState.inScope,
            tag: i == lastRow && j == lastCol ? 'answer' : null,
          ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final distinct = _grid.length * _grid[0].length;

    return VizScaffold(
      title: 'Overlapping subproblems',
      subtitle: 'The same recursion, before and after one line of caching.',
      controlBar: _toggle(context),
      stage: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, c) {
              final tree =
                  RecursionTree(nodes: _callNodes(), rootId: _tree.rootId);
              if (!_memoized) return tree;
              // Side by side when there is room; the memo table is the payoff,
              // so it stays visible either way.
              return c.maxWidth >= 620
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(child: tree),
                        const SizedBox(width: 20),
                        _memoTableVisual(context),
                      ],
                    )
                  : Column(
                      children: [
                        tree,
                        const SizedBox(height: 16),
                        _memoTableVisual(context),
                      ],
                    );
            },
          ),
          const SizedBox(height: 20),
          ResultBanner(
            kind: _memoized ? ResultKind.success : ResultKind.failure,
            message: _memoized
                ? '${_naive.nodeCount} nodes → ${_memo.computeCount} computed. '
                    '${_memo.cacheHitCount} calls returned straight from the memo.'
                : '${_naive.nodeCount} calls to solve $distinct distinct cells. '
                    'Everything below a repeated cell is recomputed from scratch.',
          ),
        ],
      ),
      panels: [_tallyPanel(context)],
      logPanel: Panel(
        title: _memoized ? 'Recursion + memo' : 'Plain recursion',
        icon: Icons.code_rounded,
        fill: true,
        child: SingleChildScrollView(
          child: PseudocodePanel(
            lines: _memoized ? _memoPseudocode : _naivePseudocode,
            // In memo mode, point at the line that collapsed the tree.
            currentLine: _memoized ? 6 : null,
            framed: false,
          ),
        ),
      ),
    );
  }

  /// The filled memo table, sitting beside the collapsed tree: every distinct
  /// cell solved exactly once, color-matched to the calls that produced it.
  Widget _memoTableVisual(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const cell = 46.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'memo',
          style: AppTheme.mono(context, size: 11, color: scheme.onSurfaceVariant)
              .copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: _grid[0].length * (cell + 8) - 8 + 20,
          child: GridBoard(
            rows: _grid.length,
            cols: _grid[0].length,
            cells: _memoCells(),
            cellSize: cell,
          ),
        ),
      ],
    );
  }

  Widget _toggle(BuildContext context) {
    return Center(
      child: SegmentedButton<bool>(
        segments: const [
          ButtonSegment(
            value: false,
            icon: Icon(Icons.account_tree_rounded, size: 18),
            label: Text('Naive recursion'),
          ),
          ButtonSegment(
            value: true,
            icon: Icon(Icons.bolt_rounded, size: 18),
            label: Text('Add a memo'),
          ),
        ],
        selected: {_memoized},
        onSelectionChanged: (s) => setState(() => _memoized = s.first),
      ),
    );
  }

  Widget _tallyPanel(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final counts = _naive.cellCounts;
    final repeated = _tints.keys.toList()
      ..sort((a, b) => counts[b]!.compareTo(counts[a]!));

    return Panel(
      title: 'Repeated subproblems',
      icon: Icons.repeat_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final key in repeated)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: _tallyRow(context, scheme, key, counts[key]!),
            ),
          const SizedBox(height: 8),
          Text(
            _memoized
                ? 'Each is solved once; every later call is a cache hit.'
                : 'Each is solved from scratch, every single time.',
            style: TextStyle(fontSize: 11.5, color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _tallyRow(
    BuildContext context,
    ColorScheme scheme,
    String key,
    int count,
  ) {
    final c = vizIdentityColors(scheme, _tints[key]!);
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: c.fill,
            border: Border.all(color: c.border, width: 1.4),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '($key)',
          style: AppTheme.mono(context, size: 12.5, color: scheme.onSurface),
        ),
        const Spacer(),
        Text(
          _memoized ? '1 compute + ${count - 1} hits' : '×$count',
          style: AppTheme.mono(context, size: 11.5, color: c.foreground)
              .copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
