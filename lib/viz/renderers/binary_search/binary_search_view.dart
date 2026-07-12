import 'dart:async';

import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../components/components.dart';
import '../../registry.dart';
import 'binary_search_algo.dart';

/// Rich, full-page binary-search visualizer composed entirely from the shared
/// component library. Driven by the deterministic [generateBinarySearchSteps]
/// recorder — stepping is pure index movement over a precomputed list.
///
/// Config:
///   type: binary-search
///   array: [8, 3, 11, 5, 1, 7, 4]   # unsorted ok — sorted for display
///   target: 7
///   # or, legacy: input: [8, 3, 11, 5, 1, 7, 4, 7]  (last = target)
class BinarySearchView extends StatefulWidget {
  final VizContext ctx;
  const BinarySearchView(this.ctx, {super.key});

  static void register() {
    VizRegistry.register('binary-search', (ctx) => BinarySearchView(ctx));
  }

  @override
  State<BinarySearchView> createState() => _BinarySearchViewState();
}

class _BinarySearchViewState extends State<BinarySearchView> {
  late List<num> _array; // sorted, as displayed
  late num _target;
  late List<BsStep> _steps;
  int _index = 0;
  Timer? _timer;

  late final TextEditingController _arrayCtrl;
  late final TextEditingController _targetCtrl;

  bool get _playing => _timer != null;
  BsStep get _step => _steps[_index];
  bool get _atStart => _index == 0;
  bool get _atEnd => _index == _steps.length - 1;

  @override
  void initState() {
    super.initState();
    final (arr, target) = _parseConfig();
    _target = target;
    _array = List<num>.from(arr)..sort((a, b) => a.compareTo(b));
    _arrayCtrl = TextEditingController(text: _array.join(', '));
    _targetCtrl = TextEditingController(text: _fmt(_target));
    _steps = generateBinarySearchSteps(_array, _target);
  }

  (List<num>, num) _parseConfig() {
    final c = widget.ctx.config;
    if (c['array'] is List) {
      final arr = (c['array'] as List).map(_toNum).toList();
      final target = c['target'] is num ? c['target'] as num : _toNum(c['target']);
      return (arr, target);
    }
    // Legacy: input list with the last element as the target.
    if (c['input'] is List && (c['input'] as List).isNotEmpty) {
      final input = (c['input'] as List).map(_toNum).toList();
      final target = input.removeLast();
      return (input, target);
    }
    return ([1, 3, 5, 7, 9, 11], 7);
  }

  num _toNum(dynamic v) =>
      v is num ? v : num.tryParse('$v'.trim()) ?? 0;

  String _fmt(num n) => n is int || n == n.roundToDouble()
      ? n.toInt().toString()
      : n.toString();

  @override
  void dispose() {
    _timer?.cancel();
    _arrayCtrl.dispose();
    _targetCtrl.dispose();
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
        .toList()
      ..sort((a, b) => a.compareTo(b));
    final target = num.tryParse(_targetCtrl.text.trim()) ?? _target;
    setState(() {
      _array = arr.isEmpty ? [target] : arr;
      _target = target;
      _arrayCtrl.text = _array.join(', ');
      _steps = generateBinarySearchSteps(_array, _target);
      _index = 0;
    });
  }

  // ── Derived view state ────────────────────────────────────────────────

  Map<int, VizState> _cellStates() {
    final s = _step;
    final states = <int, VizState>{};
    final started = s.lo != null || s.hi != null;
    for (var i = 0; i < _array.length; i++) {
      if (!started) {
        states[i] = VizState.inactive;
      } else if (s.lo != null && s.hi != null && (i < s.lo! || i > s.hi!)) {
        states[i] = VizState.discarded;
      } else {
        states[i] = VizState.inScope;
      }
    }
    if (s.mid != null && s.status == BsStatus.searching) {
      states[s.mid!] = VizState.processing;
    }
    if (s.foundIndex != null) states[s.foundIndex!] = VizState.found;
    return states;
  }

  List<ArrayPointer> _pointers(ColorScheme scheme) {
    final s = _step;
    return [
      if (s.lo != null) ArrayPointer('lo', s.lo!, color: scheme.primary),
      if (s.hi != null) ArrayPointer('hi', s.hi!, color: scheme.primary),
      if (s.mid != null)
        ArrayPointer('mid', s.mid!,
            color: scheme.brightness == Brightness.dark
                ? const Color(0xFFF0B429)
                : const Color(0xFFB77400)),
    ];
  }

  List<VizVar> _vars() {
    final s = _step;
    return [
      VizVar('target', _fmt(_target)),
      VizVar('lo', s.lo?.toString() ?? '–', changed: s.changed.contains('lo')),
      VizVar('hi', s.hi?.toString() ?? '–', changed: s.changed.contains('hi')),
      VizVar('mid', s.mid?.toString() ?? '–',
          changed: s.changed.contains('mid')),
    ];
  }

  ({ResultKind? kind, String? msg}) _result() {
    final s = _step;
    if (s.status == BsStatus.found) {
      return (kind: ResultKind.success, msg: 'Found $_fmtTarget at index ${s.foundIndex}.');
    }
    if (s.status == BsStatus.notFound) {
      return (kind: ResultKind.failure, msg: '$_fmtTarget is not in the array.');
    }
    return (kind: null, msg: null);
  }

  String get _fmtTarget => _fmt(_target);

  // ── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final result = _result();
    final searchSpace =
        (_step.lo != null && _step.hi != null && _step.hi! >= _step.lo!)
            ? _step.hi! - _step.lo! + 1
            : 0;

    return VizScaffold(
      title: 'Binary Search',
      subtitle: 'Halve a sorted range until the target is found.',
      controlBar: ControlBar(
        playing: _playing,
        atStart: _atStart,
        atEnd: _atEnd,
        onReset: _reset,
        onStepBack: _atStart ? null : () => _goto(_index - 1),
        onStepForward: _atEnd ? null : () => _goto(_index + 1),
        onTogglePlay: _togglePlay,
        input: _inputs(scheme),
      ),
      stage: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Center the array when it fits; scroll horizontally when it doesn't.
          LayoutBuilder(
            builder: (context, c) => SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: c.maxWidth),
                child: Center(
                  child: ArrayCells(
                    values: _array,
                    states: _cellStates(),
                    pointers: _pointers(scheme),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          ComparisonBadge(text: _step.badge),
          const SizedBox(height: 16),
          StepProgress(
            step: _index,
            total: _steps.length,
            caption: 'search space: $searchSpace',
          ),
          const SizedBox(height: 16),
          Legend(
            states: const [
              VizState.inScope,
              VizState.processing,
              VizState.discarded,
              VizState.found,
            ],
            labels: const {VizState.inScope: 'lo..hi (in scope)'},
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
                lines: binarySearchPseudocode,
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

  Widget _inputs(ColorScheme scheme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 220,
          child: TextField(
            controller: _arrayCtrl,
            style: AppTheme.mono(context, size: 13),
            decoration: _fieldDecoration('Array (sorted on run)'),
            onSubmitted: (_) => _rebuild(),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 90,
          child: TextField(
            controller: _targetCtrl,
            style: AppTheme.mono(context, size: 13),
            keyboardType: TextInputType.number,
            decoration: _fieldDecoration('Target'),
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
