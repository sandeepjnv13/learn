import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../components/components.dart';
import '../../registry.dart';
import 'vertical_order_algo.dart';

/// Full-page visualizer for Vertical Order Traversal of a Binary Tree
/// (LeetCode 987), built on the reusable [TreeCanvas] and [CoordinateBoard]
/// primitives plus the shared recursion kit ([CallStackPanel] +
/// [RecursionPhaseChip]).
///
/// The tree is **built inside the visualizer** (edit mode: `+` grows a child,
/// `×` prunes). Run mode plays two phases: a recursive DFS that stamps every
/// node with a `(col, row)` coordinate and drops it onto the board, then a
/// non-recursive sort-and-group pass that reads the board column by column into
/// the answer.
///
/// Config (seed only — the tree is editable in the canvas):
///   type: vertical_order
///   tree: [3, 9, 20, null, null, 15, 7]   # level-order (LeetCode)
class VerticalOrderView extends StatefulWidget {
  final VizContext ctx;
  const VerticalOrderView(this.ctx, {super.key});

  static void register() {
    VizRegistry.register('vertical_order', (ctx) => VerticalOrderView(ctx));
  }

  @override
  State<VerticalOrderView> createState() => _VerticalOrderViewState();
}

class _VerticalOrderViewState extends State<VerticalOrderView> {
  // ── Tree model (mutable; built in-canvas) ─────────────────────────────
  final Map<int, TreeNodeSpec> _tree = {};
  int? _root;
  int _nextId = 0;

  bool _editing = false;

  // ── Playback ──────────────────────────────────────────────────────────
  late List<VerticalOrderStep> _steps;
  int _index = 0;
  Timer? _timer;

  bool get _playing => _timer != null;
  VerticalOrderStep get _step => _steps[_index];
  bool get _atStart => _index == 0;
  bool get _atEnd => _index == _steps.length - 1;

  @override
  void initState() {
    super.initState();
    _parseSeed();
    _steps = _buildSteps();
    _editing = _root == null;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ── Seed parsing (level-order array → tree) ───────────────────────────

  void _parseSeed() {
    final c = widget.ctx.config;
    final raw = c['tree'] ?? c['input'];
    final values = <num?>[];
    if (raw is List) {
      for (final v in raw) {
        if (v == null || '$v'.toLowerCase() == 'null') {
          values.add(null);
        } else {
          values.add(v is num ? v : num.tryParse('$v'.trim()));
        }
      }
    }
    if (values.isEmpty || values.first == null) {
      _seedFromLevelOrder(const [3, 9, 20, null, null, 15, 7]);
      return;
    }
    _seedFromLevelOrder(values);
  }

  void _seedFromLevelOrder(List<num?> values) {
    _tree.clear();
    if (values.isEmpty || values.first == null) {
      _root = null;
      _nextId = 0;
      return;
    }
    int newId() => _nextId++;
    final rootId = newId();
    _tree[rootId] = TreeNodeSpec(id: rootId, value: values.first!);
    _root = rootId;
    final queue = Queue<int>()..add(rootId);
    var i = 1;
    while (queue.isNotEmpty && i < values.length) {
      final parent = queue.removeFirst();
      if (i < values.length && values[i] != null) {
        final id = newId();
        _tree[id] = TreeNodeSpec(id: id, value: values[i]!);
        _tree[parent] = _tree[parent]!.copyWith(left: id);
        queue.add(id);
      }
      i++;
      if (i < values.length && values[i] != null) {
        final id = newId();
        _tree[id] = TreeNodeSpec(id: id, value: values[i]!);
        _tree[parent] = _tree[parent]!.copyWith(right: id);
        queue.add(id);
      }
      i++;
    }
  }

  // ── Step generation ───────────────────────────────────────────────────

  List<VerticalOrderStep> _buildSteps() {
    return generateVerticalOrderSteps(
      value: {for (final n in _tree.values) n.id: n.value},
      left: {for (final n in _tree.values) n.id: n.left},
      right: {for (final n in _tree.values) n.id: n.right},
      rootId: _root,
    );
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
  }

  void _togglePlay() {
    if (_playing) {
      _stop();
      setState(() {});
      return;
    }
    if (_atEnd) _index = 0;
    _timer = Timer.periodic(const Duration(milliseconds: 1100), (_) {
      if (_atEnd) {
        _stop();
        setState(() {});
      } else {
        setState(() => _index++);
      }
    });
    setState(() {});
  }

  void _goto(int i) {
    _stop();
    setState(() => _index = i.clamp(0, _steps.length - 1));
  }

  void _reset() {
    _stop();
    setState(() => _index = 0);
  }

  // ── Edit ↔ Run transitions ────────────────────────────────────────────

  void _enterEdit() {
    _stop();
    setState(() => _editing = true);
  }

  void _visualize() {
    if (_root == null) return;
    _stop();
    setState(() {
      _steps = _buildSteps();
      _index = 0;
      _editing = false;
    });
  }

  // ── Tree editing ──────────────────────────────────────────────────────

  Future<void> _addRoot() async {
    final v = await _promptValue(title: 'Root value');
    if (v == null) return;
    final id = _nextId++;
    setState(() {
      _tree[id] = TreeNodeSpec(id: id, value: v);
      _root = id;
    });
  }

  Future<void> _addChild(int parentId, bool left) async {
    final v = await _promptValue(
        title: left ? 'Left child value' : 'Right child value');
    if (v == null) return;
    final id = _nextId++;
    setState(() {
      _tree[id] = TreeNodeSpec(id: id, value: v);
      _tree[parentId] = left
          ? _tree[parentId]!.copyWith(left: id)
          : _tree[parentId]!.copyWith(right: id);
    });
  }

  void _deleteNode(int id) {
    final doomed = <int>{};
    void collect(int? nid) {
      if (nid == null || !_tree.containsKey(nid)) return;
      doomed.add(nid);
      collect(_tree[nid]!.left);
      collect(_tree[nid]!.right);
    }

    collect(id);
    setState(() {
      for (final n in _tree.values.toList()) {
        if (n.left == id) _tree[n.id] = n.copyWith(clearLeft: true);
        if (n.right == id) _tree[n.id] = n.copyWith(clearRight: true);
      }
      for (final d in doomed) {
        _tree.remove(d);
      }
      if (doomed.contains(_root)) _root = null;
    });
  }

  Future<num?> _promptValue({required String title}) async {
    final ctrl = TextEditingController(text: '${_nextValueGuess()}');
    return showDialog<num>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Node value'),
          onSubmitted: (s) => Navigator.pop(ctx, num.tryParse(s.trim())),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, num.tryParse(ctrl.text.trim())),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  num _nextValueGuess() {
    num max = -1;
    for (final n in _tree.values) {
      if (n.value > max) max = n.value;
    }
    return max + 1;
  }

  // ── Derived view state (run mode) ─────────────────────────────────────

  Map<int, VizState> _nodeStates() {
    final s = _step;
    final states = <int, VizState>{};
    for (final id in _tree.keys) {
      states[id] = VizState.inactive;
    }
    for (final id in s.collected) {
      states[id] = VizState.inScope;
    }
    if (s.grouping) {
      for (final id in s.placed) {
        states[id] = VizState.found;
      }
      if (s.currentId != null) states[s.currentId!] = VizState.processing;
    } else {
      for (final id in s.spine) {
        states[id] = VizState.inScope;
      }
      if (s.current != null) states[s.current!] = VizState.processing;
    }
    return states;
  }

  // Coordinate labels below each collected node, e.g. "(−1, 1)".
  Map<int, String> _returnTags() {
    final s = _step;
    final tags = <int, String>{};
    for (final id in s.collected) {
      final col = s.colOf[id];
      final row = s.rowOf[id];
      if (col != null && row != null) {
        tags[id] = '(${col < 0 ? '−${-col}' : col}, $row)';
      }
    }
    return tags;
  }

  List<BoardItem> _boardItems() {
    final s = _step;
    final items = <BoardItem>[];
    for (final id in s.collected) {
      final col = s.colOf[id];
      final row = s.rowOf[id];
      if (col == null || row == null) continue;
      VizState state = VizState.inScope;
      if (s.grouping) {
        if (s.placed.contains(id)) state = VizState.found;
        if (s.currentId == id) state = VizState.processing;
      } else if (s.current == id) {
        state = VizState.processing;
      }
      items.add(BoardItem(
        id: id,
        value: _tree[id]!.value,
        col: col,
        row: row,
        state: state,
      ));
    }
    return items;
  }

  List<VizVar> _vars() {
    final s = _step;
    String prev() {
      if (!s.grouping) return '–';
      return s.prevCol == null ? '−∞' : '${s.prevCol}';
    }

    String current() {
      final id = s.currentId;
      if (id == null) return '–';
      return '(${s.colOf[id]}, ${s.rowOf[id]}, ${_tree[id]!.value})';
    }

    return [
      VizVar('nodes', '${s.collected.length}',
          changed: s.changed.contains('nodes')),
      VizVar('columns', '${s.columns.length}',
          changed: s.changed.contains('columns')),
      VizVar('prevCol', prev(), changed: s.changed.contains('prevCol')),
      VizVar('current', current(), changed: s.changed.contains('current')),
    ];
  }

  ({ResultKind? kind, String? msg}) _result() {
    if (!_atEnd) return (kind: null, msg: null);
    final s = _step;
    if (s.status == VerticalOrderStatus.done) {
      if (s.columns.isEmpty) {
        return (kind: ResultKind.failure, msg: s.log);
      }
      return (
        kind: ResultKind.success,
        msg: 'Vertical order traversal: '
            '${s.columns.map((c) => c.toList()).toList()}.',
      );
    }
    return (kind: null, msg: null);
  }

  // ── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return _editing ? _buildEdit(context) : _buildRun(context);
  }

  Widget _buildRun(BuildContext context) {
    final result = _result();
    final s = _step;
    return VizScaffold(
      title: 'Vertical Order Traversal',
      subtitle:
          'LeetCode 987 — DFS stamps each node with a (col, row); then sort by '
          '(col, row, val) and group column by column.',
      controlBar: ControlBar(
        playing: _playing,
        atStart: _atStart,
        atEnd: _atEnd,
        onReset: _reset,
        onStepBack: _atStart ? null : () => _goto(_index - 1),
        onStepForward: _atEnd ? null : () => _goto(_index + 1),
        onTogglePlay: _togglePlay,
        input: OutlinedButton.icon(
          onPressed: _enterEdit,
          icon: const Icon(Icons.edit_rounded, size: 18),
          label: const Text('Edit tree'),
        ),
      ),
      stage: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _phaseLabel(context, s),
            const SizedBox(height: 12),
            TreeCanvas(
              nodes: _tree.values.toList(),
              rootId: _root,
              states: _nodeStates(),
              returnTags: _returnTags(),
              spine: s.grouping ? const {} : s.spine,
            ),
            const SizedBox(height: 18),
            _boardHeader(context),
            const SizedBox(height: 6),
            CoordinateBoard(items: _boardItems(), activeColumn: s.activeCol),
            const SizedBox(height: 18),
            if (!s.grouping) ...[
              RecursionPhaseChip(phase: s.phase),
              const SizedBox(height: 12),
            ],
            ComparisonBadge(text: s.badge),
            const SizedBox(height: 16),
            StepProgress(
              step: _index,
              total: _steps.length,
              caption: s.grouping
                  ? 'grouping: ${s.columns.length} column${s.columns.length == 1 ? '' : 's'}'
                  : 'depth: ${s.stack.length}',
            ),
            const SizedBox(height: 16),
            Legend(
              states: const [
                VizState.inScope,
                VizState.processing,
                VizState.found,
              ],
              labels: const {
                VizState.inScope: 'collected / on active path',
                VizState.processing: 'current node / tuple',
                VizState.found: 'added to a column',
              },
            ),
            const SizedBox(height: 16),
            ResultBanner(kind: result.kind, message: result.msg),
          ],
        ),
      ),
      panels: [
        CallStackPanel(frames: s.stack),
        VariablesPanel(vars: _vars()),
      ],
      logPanel: TabbedPanel(
        fill: true,
        tabs: [
          PanelTab(
            icon: Icons.code_rounded,
            label: 'Pseudocode',
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: PseudocodePanel(
                lines: verticalOrderPseudocode,
                currentLine: s.line,
                framed: false,
              ),
            ),
          ),
          PanelTab(
            icon: Icons.receipt_long_rounded,
            label: 'Events',
            child: EventLog(
              entries: [for (var i = 0; i <= _index; i++) _steps[i].log],
              expand: true,
              framed: false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _phaseLabel(BuildContext context, VerticalOrderStep s) {
    final scheme = Theme.of(context).colorScheme;
    final (text, color) = s.grouping
        ? ('Phase 2 — sort & group (non-recursive)', scheme.tertiary)
        : ('Phase 1 — DFS coordinates (recursive)', scheme.primary);
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(VizTokens.radius),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Text(
          text,
          style: TextStyle(
              fontSize: 12.5, fontWeight: FontWeight.w700, color: color),
        ),
      ),
    );
  }

  Widget _boardHeader(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Text(
        'Coordinate board  ·  columns left→right, rows top→bottom',
        style: AppTheme.mono(context, size: 12, color: scheme.onSurfaceVariant),
      ),
    );
  }

  Widget _buildEdit(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return VizScaffold(
      title: 'Build the tree',
      subtitle: 'Grow the tree with +, prune with ×, then visualize.',
      controlBar: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FilledButton.icon(
            onPressed: _root == null ? null : _visualize,
            icon: const Icon(Icons.play_arrow_rounded, size: 18),
            label: const Text('Visualize traversal'),
          ),
        ],
      ),
      stage: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(VizTokens.radius),
                border: Border.all(color: scheme.primary.withValues(alpha: 0.4)),
              ),
              child: Text(
                'Tap + on an empty slot to add a child · tap × to prune a subtree.',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: scheme.primary),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TreeCanvas(
            nodes: _tree.values.toList(),
            rootId: _root,
            editable: true,
            onAddRoot: _addRoot,
            onAddChild: _addChild,
            onDeleteNode: _deleteNode,
          ),
        ],
      ),
      panels: [
        Panel(
          title: 'How it works',
          icon: Icons.tips_and_updates_rounded,
          child: Text(
            'Every node gets a column (x) and row (y): the root is (0, 0), going '
            'left is col−1, going right is col+1, and every step down is row+1. '
            'The answer groups nodes by column left→right, and within a column '
            'by row top→bottom, breaking ties by value.',
            style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}
