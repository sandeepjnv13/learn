import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../components/components.dart';
import '../../registry.dart';
import 'lca_algo.dart';

/// Full-page visualizer for Lowest Common Ancestor of a Binary Tree
/// (LeetCode 236), built on the reusable [TreeCanvas] primitive and the shared
/// recursion kit ([CallStackPanel] + [RecursionPhaseChip]).
///
/// The tree is **built inside the visualizer** — there is no array text box.
/// Edit mode gives you an interactive canvas (`+` to grow a child, `×` to prune,
/// tap to mark p/q); Run mode steps through the recursion with a live call
/// stack, so you watch the answer bubble up on the way out of the recursion.
///
/// Config (seed only — everything is editable in the canvas):
///   type: lca
///   tree: [3, 5, 1, 6, 2, 0, 8, null, null, 7, 4]   # level-order (LeetCode)
///   p: 5
///   q: 1
class LcaView extends StatefulWidget {
  final VizContext ctx;
  const LcaView(this.ctx, {super.key});

  static void register() {
    VizRegistry.register('lca', (ctx) => LcaView(ctx));
  }

  @override
  State<LcaView> createState() => _LcaViewState();
}

enum _PickMode { build, pickP, pickQ }

class _LcaViewState extends State<LcaView> {
  // ── Tree model (mutable; built in-canvas) ─────────────────────────────
  final Map<int, TreeNodeSpec> _tree = {};
  int? _root;
  int? _p;
  int? _q;
  int _nextId = 0;

  // ── Modes ─────────────────────────────────────────────────────────────
  bool _editing = false;
  _PickMode _pick = _PickMode.build;

  // ── Playback ──────────────────────────────────────────────────────────
  late List<LcaStep> _steps;
  int _index = 0;
  Timer? _timer;

  bool get _playing => _timer != null;
  LcaStep get _step => _steps[_index];
  bool get _atStart => _index == 0;
  bool get _atEnd => _index == _steps.length - 1;

  @override
  void initState() {
    super.initState();
    _parseSeed();
    _steps = _buildSteps();
    _editing = !_valid; // if the seed is incomplete, open straight into edit
  }

  bool get _valid =>
      _root != null &&
      _p != null &&
      _q != null &&
      _p != _q &&
      _tree.containsKey(_p) &&
      _tree.containsKey(_q);

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
      // Fall back to the classic LeetCode example tree.
      _seedFromLevelOrder(
          const [3, 5, 1, 6, 2, 0, 8, null, null, 7, 4]);
      _p = _findByValue(5);
      _q = _findByValue(1);
      return;
    }
    _seedFromLevelOrder(values);
    _p = _findByValue(c['p'] is num ? c['p'] as num : num.tryParse('${c['p']}'));
    _q = _findByValue(c['q'] is num ? c['q'] as num : num.tryParse('${c['q']}'));
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
      // left
      if (i < values.length && values[i] != null) {
        final id = newId();
        _tree[id] = TreeNodeSpec(id: id, value: values[i]!);
        _tree[parent] = _tree[parent]!.copyWith(left: id);
        queue.add(id);
      }
      i++;
      // right
      if (i < values.length && values[i] != null) {
        final id = newId();
        _tree[id] = TreeNodeSpec(id: id, value: values[i]!);
        _tree[parent] = _tree[parent]!.copyWith(right: id);
        queue.add(id);
      }
      i++;
    }
  }

  int? _findByValue(num? v) {
    if (v == null) return null;
    for (final n in _tree.values) {
      if (n.value == v) return n.id;
    }
    return null;
  }

  // ── Step generation ───────────────────────────────────────────────────

  List<LcaStep> _buildSteps() {
    return generateLcaSteps(
      value: {for (final n in _tree.values) n.id: n.value},
      left: {for (final n in _tree.values) n.id: n.left},
      right: {for (final n in _tree.values) n.id: n.right},
      rootId: _root,
      pId: _p,
      qId: _q,
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
    _timer = Timer.periodic(const Duration(milliseconds: 1200), (_) {
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
    setState(() {
      _editing = true;
      _pick = _PickMode.build;
    });
  }

  void _visualize() {
    if (!_valid) return;
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
    final v = await _promptValue(title: left ? 'Left child value' : 'Right child value');
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
    // Collect the whole subtree rooted at id.
    final doomed = <int>{};
    void collect(int? nid) {
      if (nid == null || !_tree.containsKey(nid)) return;
      doomed.add(nid);
      collect(_tree[nid]!.left);
      collect(_tree[nid]!.right);
    }

    collect(id);
    setState(() {
      // Unlink from parent.
      for (final n in _tree.values.toList()) {
        if (n.left == id) _tree[n.id] = n.copyWith(clearLeft: true);
        if (n.right == id) _tree[n.id] = n.copyWith(clearRight: true);
      }
      for (final d in doomed) {
        _tree.remove(d);
      }
      if (doomed.contains(_root)) _root = null;
      if (doomed.contains(_p)) _p = null;
      if (doomed.contains(_q)) _q = null;
    });
  }

  void _tapNode(int id) {
    setState(() {
      switch (_pick) {
        case _PickMode.pickP:
          if (_q == id) _q = null;
          _p = (_p == id) ? null : id;
          break;
        case _PickMode.pickQ:
          if (_p == id) _p = null;
          _q = (_q == id) ? null : id;
          break;
        case _PickMode.build:
          break;
      }
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
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
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
    for (final id in s.returnedFound.keys) {
      states[id] = VizState.inScope;
    }
    for (final id in s.returnedNull) {
      states[id] = VizState.discarded;
    }
    for (final id in s.spine) {
      states[id] = VizState.inScope;
    }
    if (s.current != null && s.status == LcaStatus.running) {
      states[s.current!] = VizState.processing;
    }
    if (s.resultId != null) states[s.resultId!] = VizState.found;
    return states;
  }

  Map<int, String> _identityTags() {
    final tags = <int, String>{};
    if (_p != null) tags[_p!] = (_q == _p) ? 'p·q' : 'p';
    if (_q != null && _q != _p) tags[_q!] = 'q';
    return tags;
  }

  Map<int, String> _returnTags() {
    final s = _step;
    final tags = <int, String>{};
    for (final e in s.returnedFound.entries) {
      tags[e.key] = '→ ${_tree[e.value]?.value ?? '?'}';
    }
    for (final id in s.returnedNull) {
      tags[id] = '→ ∅';
    }
    return tags;
  }

  List<VizVar> _vars() {
    String at(int? id) => id == null ? '–' : '${_tree[id]?.value}';
    return [
      VizVar('p', at(_p)),
      VizVar('q', at(_q)),
      VizVar('answer', _step.resultId == null ? '–' : at(_step.resultId)),
    ];
  }

  ({ResultKind? kind, String? msg}) _result() {
    if (!_atEnd) return (kind: null, msg: null);
    final s = _step;
    if (s.status == LcaStatus.found && s.resultId != null) {
      return (
        kind: ResultKind.success,
        msg: 'Lowest common ancestor of ${_tree[_p]?.value} and '
            '${_tree[_q]?.value} is node ${_tree[s.resultId]?.value}.',
      );
    }
    if (s.status == LcaStatus.notFound) {
      return (kind: ResultKind.failure, msg: s.log);
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
    return VizScaffold(
      title: 'Lowest Common Ancestor',
      subtitle:
          'LeetCode 236 — post-order recursion; watch the answer bubble up the call stack.',
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
      stage: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TreeCanvas(
            nodes: _tree.values.toList(),
            rootId: _root,
            states: _nodeStates(),
            tags: _identityTags(),
            returnTags: _returnTags(),
            spine: _step.spine,
          ),
          const SizedBox(height: 20),
          RecursionPhaseChip(phase: _step.phase),
          const SizedBox(height: 12),
          ComparisonBadge(text: _step.badge),
          const SizedBox(height: 16),
          StepProgress(
            step: _index,
            total: _steps.length,
            caption: 'depth: ${_step.stack.length}',
          ),
          const SizedBox(height: 16),
          Legend(
            states: const [
              VizState.inScope,
              VizState.processing,
              VizState.discarded,
              VizState.found,
            ],
            labels: const {
              VizState.inScope: 'on active path / target found',
              VizState.processing: 'current call',
              VizState.discarded: 'dead subtree (null)',
              VizState.found: 'LCA',
            },
          ),
          const SizedBox(height: 16),
          ResultBanner(kind: result.kind, message: result.msg),
        ],
      ),
      panels: [
        CallStackPanel(frames: _step.stack),
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
                lines: lcaPseudocode,
                currentLine: _step.line,
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

  Widget _buildEdit(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return VizScaffold(
      title: 'Build the tree',
      subtitle:
          'Grow the tree with +, prune with ×, then tap nodes to mark p and q.',
      controlBar: _editControls(scheme),
      stage: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _pickBanner(scheme),
          const SizedBox(height: 12),
          TreeCanvas(
            nodes: _tree.values.toList(),
            rootId: _root,
            states: _editStates(),
            tags: _identityTags(),
            editable: true,
            onAddRoot: _addRoot,
            onAddChild: _addChild,
            onDeleteNode: _deleteNode,
            onTapNode: _tapNode,
          ),
        ],
      ),
      panels: [
        _helpPanel(context, scheme),
      ],
    );
  }

  // In edit mode, only p/q identity coloring matters.
  Map<int, VizState> _editStates() {
    final states = <int, VizState>{};
    if (_p != null) states[_p!] = VizState.processing;
    if (_q != null) states[_q!] = VizState.found;
    return states;
  }

  Widget _editControls(ColorScheme scheme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SegmentedButton<_PickMode>(
          segments: const [
            ButtonSegment(
              value: _PickMode.build,
              icon: Icon(Icons.account_tree_rounded, size: 16),
              label: Text('Build'),
            ),
            ButtonSegment(
              value: _PickMode.pickP,
              icon: Icon(Icons.adjust_rounded, size: 16),
              label: Text('Set p'),
            ),
            ButtonSegment(
              value: _PickMode.pickQ,
              icon: Icon(Icons.adjust_rounded, size: 16),
              label: Text('Set q'),
            ),
          ],
          selected: {_pick},
          onSelectionChanged: (s) => setState(() => _pick = s.first),
          showSelectedIcon: false,
        ),
        const SizedBox(width: 14),
        FilledButton.icon(
          onPressed: _valid ? _visualize : null,
          icon: const Icon(Icons.play_arrow_rounded, size: 18),
          label: const Text('Visualize LCA'),
        ),
      ],
    );
  }

  Widget _pickBanner(ColorScheme scheme) {
    final (text, color) = switch (_pick) {
      _PickMode.build => (
          'Tap + on an empty slot to add a child · tap × to prune a subtree.',
          scheme.primary,
        ),
      _PickMode.pickP => ('Tap a node to mark it as p.', scheme.tertiary),
      _PickMode.pickQ => ('Tap a node to mark it as q.', scheme.tertiary),
    };
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(VizTokens.radius),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ),
    );
  }

  Widget _helpPanel(BuildContext context, ColorScheme scheme) {
    String at(int? id) => id == null ? 'not set' : '${_tree[id]?.value}';
    final ready = _valid;
    return Panel(
      title: 'Setup',
      icon: Icons.tips_and_updates_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _setupRow(scheme, 'root', _root == null ? 'not set' : at(_root), _root != null),
          const SizedBox(height: 8),
          _setupRow(scheme, 'p', at(_p), _p != null),
          const SizedBox(height: 8),
          _setupRow(scheme, 'q', at(_q), _q != null && _q != _p),
          const Divider(height: 24),
          Text(
            ready
                ? 'Ready — press “Visualize LCA”.'
                : 'Set a root, then two distinct nodes as p and q.',
            style: TextStyle(
              fontSize: 12.5,
              color: ready
                  ? (scheme.brightness == Brightness.dark
                      ? const Color(0xFF4ADE80)
                      : const Color(0xFF15803D))
                  : scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _setupRow(ColorScheme scheme, String label, String value, bool ok) {
    return Row(
      children: [
        Icon(
          ok ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
          size: 16,
          color: ok
              ? (scheme.brightness == Brightness.dark
                  ? const Color(0xFF4ADE80)
                  : const Color(0xFF15803D))
              : scheme.onSurfaceVariant.withValues(alpha: 0.5),
        ),
        const SizedBox(width: 8),
        Text(label, style: AppTheme.mono(context, size: 13, color: scheme.onSurface)),
        const Spacer(),
        Text(value, style: AppTheme.mono(context, size: 13, color: scheme.onSurfaceVariant)),
      ],
    );
  }
}
