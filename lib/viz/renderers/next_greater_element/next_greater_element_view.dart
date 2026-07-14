import 'dart:async';

import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../components/components.dart';
import '../../registry.dart';
import 'next_greater_element_algo.dart';

/// Full-page Next Greater Element visualizer composed from the shared component
/// library and driven by the deterministic [generateNgeSteps] recorder. Uses a
/// **horizontal** [StackView] because the monotonic (strictly decreasing) stack
/// reads best left→right.
///
/// Config:
///   type: next-greater-element
///   array: [2, 1, 2, 4, 3]
class NextGreaterElementView extends StatefulWidget {
  final VizContext ctx;
  const NextGreaterElementView(this.ctx, {super.key});

  static void register() {
    VizRegistry.register(
        'next-greater-element', (ctx) => NextGreaterElementView(ctx));
  }

  @override
  State<NextGreaterElementView> createState() => _NgeViewState();
}

class _NgeViewState extends State<NextGreaterElementView> {
  late List<num> _array;
  late List<NgeStep> _steps;
  int _index = 0;
  Timer? _timer;

  late final TextEditingController _arrayCtrl;

  bool get _playing => _timer != null;
  NgeStep get _step => _steps[_index];
  bool get _atStart => _index == 0;
  bool get _atEnd => _index == _steps.length - 1;

  @override
  void initState() {
    super.initState();
    _array = _parseConfig();
    _arrayCtrl = TextEditingController(text: _array.join(', '));
    _steps = generateNgeSteps(_array);
  }

  List<num> _parseConfig() {
    final c = widget.ctx.config;
    if (c['array'] is List && (c['array'] as List).isNotEmpty) {
      return (c['array'] as List).map(_toNum).toList();
    }
    return const [2, 1, 2, 4, 3];
  }

  num _toNum(dynamic v) => v is num ? v : num.tryParse('$v'.trim()) ?? 0;

  // Preset examples - a spread of shapes plus the strict-vs-equal edge case
  // most people miss (equal is *not* greater, so it never resolves).
  static const List<(VizPreset, List<num>)> _presets = [
    (
      VizPreset('Mixed', detail: 'a bit of everything - some resolve, some wait'),
      [2, 1, 2, 4, 3],
    ),
    (
      VizPreset('Strictly increasing',
          detail: 'each bigger value instantly resolves the one before - stack stays tiny'),
      [1, 2, 3, 4, 5],
    ),
    (
      VizPreset('Strictly decreasing',
          detail: 'nothing resolves until the end; the stack fills up completely',
          edgeCase: true),
      [5, 4, 3, 2, 1],
    ),
    (
      VizPreset('All equal',
          detail: 'equal is NOT greater - every answer stays −1',
          edgeCase: true),
      [3, 3, 3, 3],
    ),
    (
      VizPreset('Single element',
          detail: 'one value, no successor - answer is −1', edgeCase: true),
      [7],
    ),
  ];

  void _loadPreset(int i) {
    _arrayCtrl.text = _presets[i].$2.join(', ');
    _rebuild();
  }

  /// Stable bar-height reference: the whole array's max, so an element keeps the
  /// same bar height across every step it is on the stack.
  num get _barMax =>
      _array.isEmpty ? 1 : _array.reduce((a, b) => a > b ? a : b);

  @override
  void dispose() {
    _timer?.cancel();
    _arrayCtrl.dispose();
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
    final arr = _arrayCtrl.text
        .split(RegExp(r'[,\s]+'))
        .where((s) => s.trim().isNotEmpty)
        .map((s) => num.tryParse(s.trim()))
        .whereType<num>()
        .toList();
    setState(() {
      _array = arr.isEmpty ? const [2, 1, 2, 4, 3] : arr;
      _arrayCtrl.text = _array.join(', ');
      _steps = generateNgeSteps(_array);
      _index = 0;
    });
  }

  // ── Derived view state ────────────────────────────────────────────────

  Map<int, VizState> _inputStates() {
    final s = _step;
    final onStack = s.stack.toSet();
    final states = <int, VizState>{};
    for (var k = 0; k < _array.length; k++) {
      if (s.nge[k] != -1) {
        states[k] = VizState.found; // resolved: found its NGE
      } else if (onStack.contains(k)) {
        states[k] = VizState.inScope; // still waiting on the stack
      } else {
        states[k] = VizState.inactive; // not reached yet
      }
    }
    if (s.poppedIndex != null) states[s.poppedIndex!] = VizState.processing;
    if (s.i != null && s.status == NgeStatus.running) {
      states[s.i!] = VizState.processing;
    }
    return states;
  }

  Map<int, VizState> _stackStates() {
    final s = _step;
    final states = <int, VizState>{};
    for (var p = 0; p < s.stack.length; p++) {
      states[p] = VizState.inScope;
    }
    // The top cell is the one being compared / about to pop.
    if (s.stack.isNotEmpty && (s.line == 3 || s.line == 4)) {
      states[s.stack.length - 1] = VizState.processing;
    }
    return states;
  }

  Map<int, VizState> _resultStates() {
    final s = _step;
    final states = <int, VizState>{};
    for (var k = 0; k < s.nge.length; k++) {
      states[k] = s.nge[k] != -1 ? VizState.found : VizState.inactive;
    }
    return states;
  }

  List<VizVar> _vars() {
    final s = _step;
    final topStr = s.stack.isEmpty ? '–' : '${_array[s.stack.last]} (idx ${s.stack.last})';
    return [
      VizVar('i', s.i?.toString() ?? '–', changed: s.changed.contains('i')),
      VizVar('stack (top)', topStr, changed: s.changed.contains('stack')),
      VizVar('depth', '${s.stack.length}', changed: s.changed.contains('stack')),
    ];
  }

  ({ResultKind? kind, String? msg}) _result() {
    if (_step.status == NgeStatus.done) {
      final pairs = <String>[];
      for (var k = 0; k < _array.length; k++) {
        pairs.add('${_array[k]}→${_step.nge[k]}');
      }
      return (kind: ResultKind.success, msg: 'NGE: ${pairs.join(', ')}');
    }
    return (kind: null, msg: null);
  }

  // ── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final result = _result();
    final s = _step;

    return VizScaffold(
      title: 'Next Greater Element',
      subtitle:
          'Monotonic stack: keep a strictly decreasing stack of indices; a bigger '
          'value resolves everything smaller waiting on it.',
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
          _sectionLabel(context, 'Input array'),
          const SizedBox(height: 6),
          ArrayCells(
            values: _array,
            states: _inputStates(),
            pointers: [
              if (s.i != null) ArrayPointer('i', s.i!, color: scheme.primary),
            ],
          ),
          const SizedBox(height: 22),
          _sectionLabel(
              context, 'Stack (bars = values; line traces the decreasing top →)'),
          const SizedBox(height: 6),
          StackView(
            values: [for (final idx in s.stack) _array[idx]],
            states: _stackStates(),
            captions: {
              for (var p = 0; p < s.stack.length; p++) p: '#${s.stack[p]}',
            },
            emptyLabel: 'empty',
            barMax: _barMax,
            compact: true,
            connectTops: true,
          ),
          const SizedBox(height: 22),
          _sectionLabel(context, 'Answer (nge)'),
          const SizedBox(height: 6),
          ArrayCells(values: s.nge, states: _resultStates()),
          const SizedBox(height: 20),
          ComparisonBadge(text: s.badge),
          const SizedBox(height: 14),
          StepProgress(
            step: _index,
            total: _steps.length,
            caption: 'stack depth: ${s.stack.length}',
          ),
          const SizedBox(height: 14),
          Legend(
            states: const [
              VizState.inactive,
              VizState.processing,
              VizState.inScope,
              VizState.found,
            ],
            labels: const {
              VizState.inactive: 'not reached',
              VizState.processing: 'current / popping',
              VizState.inScope: 'waiting on stack',
              VizState.found: 'resolved',
            },
          ),
          const SizedBox(height: 14),
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
                lines: ngePseudocode,
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

  Widget _sectionLabel(BuildContext context, String text) {
    final scheme = Theme.of(context).colorScheme;
    return Text(
      text,
      style: AppTheme.mono(
        context,
        size: 12,
        color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
      ).copyWith(fontWeight: FontWeight.w600),
    );
  }

  Widget _inputs() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        PresetPicker(
          presets: [for (final p in _presets) p.$1],
          onSelected: _loadPreset,
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 260,
          child: TextField(
            controller: _arrayCtrl,
            style: AppTheme.mono(context, size: 13),
            decoration: InputDecoration(
              labelText: 'Array',
              isDense: true,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
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
}
