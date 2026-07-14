import 'dart:async';

import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../components/components.dart';
import '../../registry.dart';
import 'three_sum_algo.dart';

/// Full-page 3Sum (LeetCode 15) visualizer composed from the shared component
/// library and driven by the deterministic [generateThreeSumSteps] recorder.
///
/// It is the reference **two-pointer** instance: reuse [ArrayCells] (the array/
/// pointer primitive) with three gliding pointers - a fixed anchor `i` plus a
/// `lo`/`hi` pair that converges on the sorted remainder. No new structure
/// primitive is needed; converging pointers are just labelled markers over the
/// cells, exactly what `ArrayCells` provides.
///
/// Config:
///   type: three-sum
///   array: [-1, 0, 1, 2, -1, -4]   # unsorted ok - sorted for display
class ThreeSumView extends StatefulWidget {
  final VizContext ctx;
  const ThreeSumView(this.ctx, {super.key});

  static void register() {
    VizRegistry.register('three-sum', (ctx) => ThreeSumView(ctx));
  }

  @override
  State<ThreeSumView> createState() => _ThreeSumViewState();
}

class _ThreeSumViewState extends State<ThreeSumView> {
  late List<num> _array; // sorted, as displayed
  late List<ThreeSumStep> _steps;
  int _index = 0;
  Timer? _timer;

  late final TextEditingController _arrayCtrl;

  bool get _playing => _timer != null;
  ThreeSumStep get _step => _steps[_index];
  bool get _atStart => _index == 0;
  bool get _atEnd => _index == _steps.length - 1;

  @override
  void initState() {
    super.initState();
    _array = List<num>.from(_parseConfig())..sort((a, b) => a.compareTo(b));
    _arrayCtrl = TextEditingController(text: _array.join(', '));
    _steps = generateThreeSumSteps(_array);
  }

  List<num> _parseConfig() {
    final c = widget.ctx.config;
    if (c['array'] is List && (c['array'] as List).isNotEmpty) {
      return (c['array'] as List).map(_toNum).toList();
    }
    return const [-1, 0, 1, 2, -1, -4];
  }

  num _toNum(dynamic v) => v is num ? v : num.tryParse('$v'.trim()) ?? 0;

  // Preset examples - a hit, plus the duplicate-handling and empty-result cases
  // people get wrong (repeated anchors, duplicate pointer values, all-zeros,
  // and an input with no valid triplet).
  static const List<(VizPreset, List<num>)> _presets = [
    (
      VizPreset('Classic', detail: 'the LeetCode example - two triplets'),
      [-1, 0, 1, 2, -1, -4],
    ),
    (
      VizPreset('Many duplicates',
          detail: 'dup-skipping keeps the single triplet unique',
          edgeCase: true),
      [-2, 0, 0, 2, 2],
    ),
    (
      VizPreset('All zeros',
          detail: 'three zeros collapse to one [0, 0, 0]', edgeCase: true),
      [0, 0, 0, 0],
    ),
    (
      VizPreset('No triplet',
          detail: 'all positive - nothing can sum to 0', edgeCase: true),
      [1, 2, 3, 4],
    ),
  ];

  void _loadPreset(int i) {
    _arrayCtrl.text = _presets[i].$2.join(', ');
    _rebuild();
  }

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
        .toList()
      ..sort((a, b) => a.compareTo(b));
    setState(() {
      _array = arr;
      _arrayCtrl.text = _array.join(', ');
      _steps = generateThreeSumSteps(_array);
      _index = 0;
    });
  }

  // ── Derived view state ────────────────────────────────────────────────

  Color _anchorColor(ColorScheme scheme) =>
      scheme.brightness == Brightness.dark
          ? const Color(0xFFF0B429)
          : const Color(0xFFB77400);

  Map<int, VizState> _cellStates() {
    final s = _step;
    final i = s.i, lo = s.lo, hi = s.hi;
    final states = <int, VizState>{};
    for (var k = 0; k < _array.length; k++) {
      if (i == null) {
        states[k] = VizState.inactive;
      } else if (k < i) {
        states[k] = VizState.discarded; // anchors already tried
      } else if (k == i) {
        states[k] = VizState.inScope; // the fixed anchor
      } else if (lo == null || hi == null) {
        states[k] = VizState.inactive; // pointers not placed yet
      } else if (k < lo || k > hi) {
        states[k] = VizState.discarded; // a pointer has swept past
      } else {
        states[k] = VizState.inScope; // the live lo..hi window
      }
    }
    // While summing / comparing, the two pointer cells are what we examine.
    if ((s.line == 6 || s.line == 7) && lo != null && hi != null) {
      states[lo] = VizState.processing;
      states[hi] = VizState.processing;
    }
    // A recorded triplet flashes green on i, lo, hi.
    for (final m in s.matched) {
      states[m] = VizState.found;
    }
    return states;
  }

  List<ArrayPointer> _pointers(ColorScheme scheme) {
    final s = _step;
    return [
      if (s.i != null) ArrayPointer('i', s.i!, color: _anchorColor(scheme)),
      if (s.lo != null) ArrayPointer('lo', s.lo!, color: scheme.primary),
      if (s.hi != null) ArrayPointer('hi', s.hi!, color: scheme.primary),
    ];
  }

  List<VizVar> _vars() {
    final s = _step;
    return [
      VizVar('target', '0'),
      VizVar('i', s.i?.toString() ?? '–', changed: s.changed.contains('i')),
      VizVar('lo', s.lo?.toString() ?? '–', changed: s.changed.contains('lo')),
      VizVar('hi', s.hi?.toString() ?? '–', changed: s.changed.contains('hi')),
      VizVar('sum', s.sum?.toString() ?? '–', changed: s.changed.contains('sum')),
      VizVar('triplets', '${s.triplets.length}'),
    ];
  }

  ({ResultKind? kind, String? msg}) _result() {
    final s = _step;
    if (s.status != ThreeSumStatus.done) return (kind: null, msg: null);
    if (s.triplets.isEmpty) {
      return (kind: ResultKind.failure, msg: 'No triplet sums to zero.');
    }
    final list = s.triplets.map((t) => '[${t.join(', ')}]').join('  ·  ');
    return (
      kind: ResultKind.success,
      msg: 'Found ${s.triplets.length} triplet(s): $list',
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final result = _result();

    return VizScaffold(
      title: '15. 3Sum',
      subtitle:
          'Sort, then for each anchor slide a lo/hi pair inward - the sum\'s '
          'sign says which pointer to move, so each step rules one value out.',
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
          // Self-fits: cells scale down to the width rather than side-scrolling.
          ArrayCells(
            values: _array,
            states: _cellStates(),
            pointers: _pointers(scheme),
          ),
          const SizedBox(height: 22),
          _tripletsRow(context, scheme),
          const SizedBox(height: 20),
          ComparisonBadge(text: _step.badge),
          const SizedBox(height: 14),
          StepProgress(
            step: _index,
            total: _steps.length,
            caption: 'triplets found: ${_step.triplets.length}',
          ),
          const SizedBox(height: 14),
          Legend(
            states: const [
              VizState.inScope,
              VizState.processing,
              VizState.discarded,
              VizState.found,
            ],
            labels: const {
              VizState.inScope: 'anchor / lo..hi window',
              VizState.processing: 'summing lo + hi',
              VizState.discarded: 'ruled out',
              VizState.found: 'triplet',
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
                lines: threeSumPseudocode,
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

  /// The running list of recorded triplets, rendered as small pills so the
  /// answer visibly accumulates as the pointers sweep.
  Widget _tripletsRow(BuildContext context, ColorScheme scheme) {
    final triplets = _step.triplets;
    final green = scheme.brightness == Brightness.dark
        ? const Color(0xFF4ADE80)
        : const Color(0xFF15803D);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 4, right: 10),
          child: Text(
            'triplets',
            style: AppTheme.mono(
              context,
              size: 12,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
            ).copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(
          child: triplets.isEmpty
              ? Text(
                  '- none yet -',
                  style: AppTheme.mono(
                    context,
                    size: 12,
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final t in triplets)
                      AnimatedContainer(
                        duration: VizTokens.moveDuration,
                        curve: VizTokens.spring,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: green.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                          border:
                              Border.all(color: green.withValues(alpha: 0.5)),
                        ),
                        child: Text(
                          '[${t.join(', ')}]',
                          style: AppTheme.mono(context, size: 12.5, color: green)
                              .copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                  ],
                ),
        ),
      ],
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
              labelText: 'Array (sorted on run)',
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
