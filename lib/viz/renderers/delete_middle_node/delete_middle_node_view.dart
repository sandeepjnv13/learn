import 'dart:async';

import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../components/components.dart';
import '../../registry.dart';
import 'delete_middle_node_algo.dart';

/// Full-page visualizer for deleting the middle node of a singly-linked list
/// (LeetCode 2095), composed from the shared component library and driven by the
/// deterministic [generateDeleteMiddleNodeSteps] recorder.
///
/// Config:
///   type: delete-middle-node
///   list: [1, 2, 3, 4, 5, 6]
class DeleteMiddleNodeView extends StatefulWidget {
  final VizContext ctx;
  const DeleteMiddleNodeView(this.ctx, {super.key});

  static void register() {
    VizRegistry.register(
        'delete-middle-node', (ctx) => DeleteMiddleNodeView(ctx));
  }

  @override
  State<DeleteMiddleNodeView> createState() => _DeleteMiddleNodeViewState();
}

class _DeleteMiddleNodeViewState extends State<DeleteMiddleNodeView> {
  late List<num> _list;
  late List<DmnStep> _steps;
  int _index = 0;
  Timer? _timer;

  late final TextEditingController _listCtrl;

  bool get _playing => _timer != null;
  DmnStep get _step => _steps[_index];
  bool get _atStart => _index == 0;
  bool get _atEnd => _index == _steps.length - 1;

  @override
  void initState() {
    super.initState();
    _list = _parseConfig();
    _listCtrl = TextEditingController(text: _list.join(', '));
    _steps = generateDeleteMiddleNodeSteps(_list);
  }

  List<num> _parseConfig() {
    final c = widget.ctx.config;
    final raw = c['list'] ?? c['input'] ?? c['array'];
    if (raw is List) {
      return raw.map(_toNum).toList();
    }
    return const [1, 2, 3, 4, 5, 6];
  }

  num _toNum(dynamic v) => v is num ? v : num.tryParse('$v'.trim()) ?? 0;

  @override
  void dispose() {
    _timer?.cancel();
    _listCtrl.dispose();
    super.dispose();
  }

  // ── Playback ──────────────────────────────────────────────────────────

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

  void _rebuild() {
    _stop();
    final list = _listCtrl.text
        .split(RegExp(r'[,\s]+'))
        .where((s) => s.trim().isNotEmpty)
        .map((s) => num.tryParse(s.trim()))
        .whereType<num>()
        .toList();
    setState(() {
      _list = list;
      _listCtrl.text = _list.join(', ');
      _steps = generateDeleteMiddleNodeSteps(_list);
      _index = 0;
    });
  }

  // ── Derived view state ────────────────────────────────────────────────

  Map<int, VizState> _nodeStates() {
    final s = _step;
    final done = s.status == DmnStatus.removed && _atEnd;
    final states = <int, VizState>{};
    for (var i = 0; i < _list.length; i++) {
      if (s.removedIndex == i) {
        states[i] = VizState.notFound; // unlinked node
      } else if (done) {
        states[i] = VizState.found; // final, healed list
      } else if (s.slow == null) {
        states[i] = VizState.inactive; // pointers not placed yet
      } else {
        states[i] = VizState.inScope; // live node in the chain
      }
    }
    // Highlight the current slow node (the running middle candidate).
    if (s.slow != null &&
        s.status == DmnStatus.running &&
        s.slow! < _list.length) {
      states[s.slow!] = VizState.processing;
    }
    return states;
  }

  Set<int> _removed() =>
      _step.removedIndex == null ? const {} : {_step.removedIndex!};

  List<LinkedNodePointer> _pointers(ColorScheme scheme) {
    final s = _step;
    final amber = scheme.brightness == Brightness.dark
        ? const Color(0xFFF0B429)
        : const Color(0xFFB77400);
    // Once fast walks off the end, park it on the null sentinel (index == n)
    // rather than hiding it.
    final fastIdx = s.fast ?? (s.fastAtNull ? _list.length : null);
    return [
      const LinkedNodePointer('head', 0, color: Colors.grey),
      if (s.prev != null)
        LinkedNodePointer('prev', s.prev!, color: scheme.tertiary),
      if (s.slow != null)
        LinkedNodePointer('slow', s.slow!, color: scheme.primary),
      if (fastIdx != null) LinkedNodePointer('fast', fastIdx, color: amber),
    ];
  }

  List<VizVar> _vars() {
    final s = _step;
    String at(int? i) => i == null ? 'null' : 'node $i';
    return [
      VizVar('prev', at(s.prev), changed: s.changed.contains('prev')),
      VizVar('slow', at(s.slow), changed: s.changed.contains('slow')),
      VizVar('fast', at(s.fast), changed: s.changed.contains('fast')),
    ];
  }

  ({ResultKind? kind, String? msg}) _result() {
    if (!_atEnd) return (kind: null, msg: null);
    final s = _step;
    if (s.status == DmnStatus.empty) {
      return (
        kind: ResultKind.success,
        msg: _list.length <= 1
            ? 'List had ${_list.length} node — deleting the middle empties it → returned null.'
            : 'Returned null.',
      );
    }
    if (s.status == DmnStatus.removed && s.removedIndex != null) {
      final remaining = [
        for (var i = 0; i < _list.length; i++)
          if (i != s.removedIndex) _list[i]
      ];
      return (
        kind: ResultKind.success,
        msg: 'Deleted node ${s.removedIndex} (value ${_list[s.removedIndex!]}). '
            'Result: [${remaining.join(', ')}].',
      );
    }
    return (kind: null, msg: null);
  }

  // ── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final result = _result();

    return VizScaffold(
      title: 'Delete the Middle Node',
      subtitle:
          'LeetCode 2095 — slow/fast pointers find the middle; prev unlinks it.',
      controlBar: ControlBar(
        playing: _playing,
        atStart: _atStart,
        atEnd: _atEnd,
        onReset: _reset,
        onStepBack: _atStart ? null : () => _goto(_index - 1),
        onStepForward: _atEnd ? null : () => _goto(_index + 1),
        onTogglePlay: _togglePlay,
        input: _inputs(),
      ),
      stage: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // LinkedListView self-fits: it scales the chain down to the width
          // when the list is long, so there is never a horizontal scroll.
          Center(
            child: _list.isEmpty
                ? _emptyList(scheme)
                : LinkedListView(
                    values: _list,
                    states: _nodeStates(),
                    pointers: _pointers(scheme),
                    removed: _removed(),
                  ),
          ),
          const SizedBox(height: 24),
          ComparisonBadge(text: _step.badge),
          const SizedBox(height: 16),
          StepProgress(
            step: _index,
            total: _steps.length,
            caption: 'nodes: ${_list.length}',
          ),
          const SizedBox(height: 16),
          Legend(
            states: const [
              VizState.inScope,
              VizState.processing,
              VizState.notFound,
              VizState.found,
            ],
            labels: const {
              VizState.inScope: 'in list',
              VizState.processing: 'slow (candidate)',
              VizState.notFound: 'unlinked',
              VizState.found: 'final list',
            },
          ),
          const SizedBox(height: 16),
          ResultBanner(kind: result.kind, message: result.msg),
        ],
      ),
      panels: [
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
                lines: deleteMiddleNodePseudocode,
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

  Widget _emptyList(ColorScheme scheme) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Text(
          'head → null  (empty list)',
          style: AppTheme.mono(context, size: 14, color: scheme.onSurfaceVariant),
        ),
      );

  Widget _inputs() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 260,
          child: TextField(
            controller: _listCtrl,
            style: AppTheme.mono(context, size: 13),
            decoration: _fieldDecoration('List (head → tail)'),
            onSubmitted: (_) => _rebuild(),
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filledTonal(
          onPressed: _rebuild,
          icon: const Icon(Icons.check_rounded),
          tooltip: 'Apply input',
        ),
      ],
    );
  }

  InputDecoration _fieldDecoration(String label) => InputDecoration(
        labelText: label,
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      );
}
