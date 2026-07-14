import 'dart:async';

import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../components/components.dart';
import '../../registry.dart';
import 'min_size_subarray_algo.dart';

/// Full-page LeetCode 209 (Minimum Size Subarray Sum) visualizer composed
/// from the shared component library, driven by the deterministic
/// [generateMinSizeSubarraySteps] recorder.
///
/// Reference **sliding-window** two-pointer instance: reuse [ArrayCells] with
/// a `start`/`i` pointer pair over a growing-then-shrinking `inScope` window -
/// no new structure primitive needed. Every outer-loop iteration is three
/// moves: add `nums[i]` to the window, maintain it (shrink from the left
/// while still valid), then use it as a length candidate.
///
/// Config:
///   type: min-size-subarray
///   array: [2, 3, 1, 2, 4, 3]
///   target: 7
class MinSizeSubarrayView extends StatefulWidget {
  final VizContext ctx;
  const MinSizeSubarrayView(this.ctx, {super.key});

  static void register() {
    VizRegistry.register('min-size-subarray', (ctx) => MinSizeSubarrayView(ctx));
  }

  @override
  State<MinSizeSubarrayView> createState() => _MinSizeSubarrayViewState();
}

class _MinSizeSubarrayViewState extends State<MinSizeSubarrayView> {
  late List<num> _array;
  late num _target;
  late List<MssStep> _steps;
  int _index = 0;
  Timer? _timer;

  late final TextEditingController _arrayCtrl;
  late final TextEditingController _targetCtrl;

  bool get _playing => _timer != null;
  MssStep get _step => _steps[_index];
  bool get _atStart => _index == 0;
  bool get _atEnd => _index == _steps.length - 1;

  @override
  void initState() {
    super.initState();
    final (arr, target) = _parseConfig();
    _array = arr;
    _target = target;
    _arrayCtrl = TextEditingController(text: _array.join(', '));
    _targetCtrl = TextEditingController(text: _fmt(_target));
    _steps = generateMinSizeSubarraySteps(_array, _target);
  }

  (List<num>, num) _parseConfig() {
    final c = widget.ctx.config;
    final arr = c['array'] is List
        ? (c['array'] as List).map(_toNum).toList()
        : <num>[2, 3, 1, 2, 4, 3];
    final target = c['target'] is num ? c['target'] as num : _toNum(c['target']);
    return (arr, c.containsKey('target') ? target : 7);
  }

  num _toNum(dynamic v) => v is num ? v : num.tryParse('$v'.trim()) ?? 0;

  String _fmt(num n) =>
      n is int || n == n.roundToDouble() ? n.toInt().toString() : n.toString();

  // Preset examples - the LeetCode example, plus the cases that trip up a
  // first pass: no valid window at all, a single element exactly at target,
  // and the whole array being the only valid window.
  static const List<(VizPreset, List<num>, num)> _presets = [
    (
      VizPreset('Classic', detail: 'the LeetCode example - shrinks to length 2'),
      [2, 3, 1, 2, 4, 3],
      7,
    ),
    (
      VizPreset('No valid window',
          detail: 'sum of everything is still below target', edgeCase: true),
      [1, 1, 1, 1],
      10,
    ),
    (
      VizPreset('Single element hits target',
          detail: 'one element already ≥ target', edgeCase: true),
      [1, 4, 4],
      4,
    ),
    (
      VizPreset('Whole array is the answer',
          detail: 'window never shrinks below n', edgeCase: true),
      [1, 1, 1, 1, 7],
      11,
    ),
  ];

  void _loadPreset(int i) {
    final p = _presets[i];
    _arrayCtrl.text = p.$2.join(', ');
    _targetCtrl.text = _fmt(p.$3);
    _rebuild();
  }

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
        .toList();
    final target = num.tryParse(_targetCtrl.text.trim()) ?? _target;
    setState(() {
      _array = arr;
      _target = target;
      _arrayCtrl.text = _array.join(', ');
      _steps = generateMinSizeSubarraySteps(_array, _target);
      _index = 0;
    });
  }

  // ── Derived view state ────────────────────────────────────────────────

  Map<int, VizState> _cellStates() {
    final s = _step;
    final states = <int, VizState>{};
    final i = s.i, start = s.start;
    for (var k = 0; k < _array.length; k++) {
      if (i == null || start == null) {
        states[k] = VizState.inactive;
      } else if (k > i) {
        states[k] = VizState.inactive; // not reached yet
      } else if (k < start) {
        states[k] = VizState.discarded; // shrunk out of the window
      } else {
        states[k] = VizState.inScope; // the live start..i window
      }
    }
    // Highlight the element being tested for removal during maintain.
    if ((s.line == 5 || s.line == 6) && start != null) {
      states[start] = VizState.processing;
    }
    if (s.status == MssStatus.found) {
      for (final m in s.matched) {
        states[m] = VizState.found;
      }
    }
    return states;
  }

  List<ArrayPointer> _pointers(ColorScheme scheme) {
    final s = _step;
    return [
      if (s.start != null) ArrayPointer('start', s.start!, color: scheme.primary),
      if (s.i != null)
        ArrayPointer('i', s.i!,
            color: scheme.brightness == Brightness.dark
                ? const Color(0xFFF0B429)
                : const Color(0xFFB77400)),
    ];
  }

  List<VizVar> _vars() {
    final s = _step;
    return [
      VizVar('target', _fmt(_target)),
      VizVar('start', s.start?.toString() ?? '–',
          changed: s.changed.contains('start')),
      VizVar('windowSum', s.windowSum?.toString() ?? '–',
          changed: s.changed.contains('windowSum')),
      VizVar('best', s.best?.toString() ?? '∞', changed: s.changed.contains('best')),
    ];
  }

  ({ResultKind? kind, String? msg}) _result() {
    final s = _step;
    if (s.status == MssStatus.found) {
      return (
        kind: ResultKind.success,
        msg: 'Shortest subarray with sum ≥ $_fmtTarget has length ${s.best}.',
      );
    }
    if (s.status == MssStatus.notFound) {
      return (
        kind: ResultKind.failure,
        msg: 'No subarray sums to at least $_fmtTarget - return 0.',
      );
    }
    if (s.status == MssStatus.empty) {
      return (kind: ResultKind.failure, msg: 'nums is empty - return 0.');
    }
    return (kind: null, msg: null);
  }

  String get _fmtTarget => _fmt(_target);

  // ── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final result = _result();
    final windowLen = (_step.start != null && _step.i != null && _step.i! >= _step.start!)
        ? _step.i! - _step.start! + 1
        : 0;

    return VizScaffold(
      title: '209. Minimum Size Subarray Sum',
      subtitle:
          'Grow the window by adding nums[i], shrink it from the left while '
          'still valid, then measure it - shortest valid window wins.',
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
          ArrayCells(
            values: _array,
            states: _cellStates(),
            pointers: _pointers(scheme),
          ),
          const SizedBox(height: 22),
          ComparisonBadge(text: _step.badge),
          const SizedBox(height: 16),
          StepProgress(
            step: _index,
            total: _steps.length,
            caption: 'window length: $windowLen  ·  best: ${_step.best ?? '∞'}',
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
              VizState.inScope: 'start..i (window)',
              VizState.processing: 'testing removal',
              VizState.discarded: 'shrunk out',
              VizState.found: 'best window',
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
                lines: minSizeSubarrayPseudocode,
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
          width: 220,
          child: TextField(
            controller: _arrayCtrl,
            style: AppTheme.mono(context, size: 13),
            decoration: _fieldDecoration('Array'),
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
