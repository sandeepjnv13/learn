import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart' hide Interval;

import '../../../theme/app_theme.dart';
import '../../components/components.dart';
import '../../registry.dart';
import 'non_overlapping_intervals_algo.dart';

/// Full-page "non-overlapping intervals" visualizer (LeetCode 435), composed
/// from the shared component library and driven by the deterministic
/// [generateNonOverlapSteps] recorder. Sorts intervals by start, then sweeps
/// once keeping a single `active` interval - greedily discarding whichever
/// overlapping interval has the larger end.
///
/// Config:
///   type: non-overlapping-intervals
///   intervals: [[1, 2], [2, 3], [3, 4], [1, 3]]
class NonOverlappingIntervalsView extends StatefulWidget {
  final VizContext ctx;
  const NonOverlappingIntervalsView(this.ctx, {super.key});

  static void register() {
    VizRegistry.register(
        'non-overlapping-intervals', (ctx) => NonOverlappingIntervalsView(ctx));
  }

  @override
  State<NonOverlappingIntervalsView> createState() =>
      _NonOverlappingIntervalsViewState();
}

class _NonOverlappingIntervalsViewState
    extends State<NonOverlappingIntervalsView> {
  late List<Interval> _intervals; // sorted, as displayed
  late List<NonOverlapStep> _steps;
  late num _domainMin;
  late num _domainMax;
  int _index = 0;
  Timer? _timer;

  late final TextEditingController _intervalsCtrl;

  bool get _playing => _timer != null;
  NonOverlapStep get _step => _steps[_index];
  bool get _atStart => _index == 0;
  bool get _atEnd => _index == _steps.length - 1;

  @override
  void initState() {
    super.initState();
    final ivs = _parseConfig();
    _apply(ivs);
    _intervalsCtrl = TextEditingController(text: _fmtList(_intervals));
  }

  void _apply(List<Interval> ivs) {
    _intervals = List<Interval>.from(ivs)
      ..sort((a, b) => a.start.compareTo(b.start));
    _steps = generateNonOverlapSteps(_intervals);
    _computeDomain();
    _index = 0;
  }

  void _computeDomain() {
    if (_intervals.isEmpty) {
      _domainMin = 0;
      _domainMax = 1;
      return;
    }
    num lo = _intervals.first.start, hi = _intervals.first.end;
    for (final iv in _intervals) {
      lo = math.min(lo, iv.start);
      hi = math.max(hi, iv.end);
    }
    final pad = math.max(1, (hi - lo) * 0.08);
    _domainMin = lo - pad;
    _domainMax = hi + pad;
  }

  List<Interval> _parseConfig() {
    final c = widget.ctx.config;
    final ivs = _toIntervalList(c['intervals']);
    if (ivs.isEmpty) {
      return const [
        Interval(1, 2),
        Interval(2, 3),
        Interval(3, 4),
        Interval(1, 3),
      ];
    }
    return ivs;
  }

  List<Interval> _toIntervalList(dynamic v) {
    if (v is! List) return const [];
    return v.map(_toInterval).whereType<Interval>().toList();
  }

  Interval? _toInterval(dynamic v) {
    if (v is List && v.length >= 2) {
      return Interval(_toNum(v[0]), _toNum(v[1]));
    }
    return null;
  }

  num _toNum(dynamic v) => v is num ? v : num.tryParse('$v'.trim()) ?? 0;

  // Preset examples - the worked overlap case, plus the frequently-missed
  // edge cases: already non-overlapping, touching (not overlapping)
  // endpoints, fully nested, and everything identical.
  static const List<(VizPreset, List<List<num>>)> _presets = [
    (
      VizPreset('One overlap', detail: '[1,3] conflicts - remove it'),
      [[1, 2], [2, 3], [3, 4], [1, 3]],
    ),
    (
      VizPreset('Already non-overlapping',
          detail: 'sorted and disjoint → 0 removals', edgeCase: true),
      [[1, 2], [3, 4], [5, 6]],
    ),
    (
      VizPreset('Touching endpoints',
          detail: 'iv.start == active.end does NOT overlap', edgeCase: true),
      [[1, 2], [2, 3]],
    ),
    (
      VizPreset('Nested interval',
          detail: 'wide outer interval has the larger end - it gets removed, '
              'not the narrow inner one',
          edgeCase: true),
      [[1, 10], [2, 3], [4, 5]],
    ),
    (
      VizPreset('All identical',
          detail: 'every interval conflicts - keep just 1, remove the rest',
          edgeCase: true),
      [[1, 5], [1, 5], [1, 5], [1, 5]],
    ),
  ];

  void _loadPreset(int i) {
    final p = _presets[i];
    _intervalsCtrl.text =
        p.$2.map((iv) => '[${_fmt(iv[0])}, ${_fmt(iv[1])}]').join(', ');
    _rebuild();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _intervalsCtrl.dispose();
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
    final ivs = _parseIntervalsField(_intervalsCtrl.text);
    setState(() {
      _apply(ivs);
      _intervalsCtrl.text = _fmtList(_intervals);
    });
  }

  /// Parses numbers out of free text and pairs them into intervals, e.g.
  /// "[1,2],[2,3]" or "1 2 2 3" → [ [1,2], [2,3] ].
  List<Interval> _parseIntervalsField(String text) {
    final nums = RegExp(r'-?\d+(\.\d+)?')
        .allMatches(text)
        .map((m) => num.parse(m.group(0)!))
        .toList();
    final out = <Interval>[];
    for (var i = 0; i + 1 < nums.length; i += 2) {
      out.add(Interval(nums[i], nums[i + 1]));
    }
    return out;
  }

  // ── Derived view state ────────────────────────────────────────────────

  VizState _sourceState(int i) {
    final s = _step;
    if (s.discardedSources.contains(i)) return VizState.discarded;
    if (i == s.activeIndex) return VizState.found;
    if (s.current == i) return VizState.processing;
    if (s.keptSources.contains(i)) return VizState.inScope;
    return VizState.inactive;
  }

  List<IntervalBar> _bars() {
    final s = _step;
    return [
      for (var i = 0; i < _intervals.length; i++)
        IntervalBar(
          start: _intervals[i].start,
          end: _intervals[i].end,
          label: 'iv$i',
          state: _sourceState(i),
          isNew: i == s.activeIndex,
        ),
    ];
  }

  List<VizVar> _vars() {
    final s = _step;
    return [
      VizVar('active', s.activeIndex < 0 ? '–' : _fmtIv(s.active),
          changed: s.changed.contains('active')),
      VizVar('iv', s.current == null ? '–' : _fmtIv(_intervals[s.current!])),
      VizVar('removed', '${s.removed}', changed: s.changed.contains('removed')),
    ];
  }

  ({ResultKind? kind, String? msg}) _result() {
    final s = _step;
    if (s.status == NonOverlapStatus.done) {
      return (
        kind: ResultKind.success,
        msg: 'Minimum removals = ${s.removed}',
      );
    }
    return (kind: null, msg: null);
  }

  // ── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final result = _result();

    return VizScaffold(
      title: 'Non-overlapping Intervals',
      subtitle:
          'Sort by start, then keep one active interval - on conflict, '
          'discard whichever ends later.',
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
      stage: LayoutBuilder(
        builder: (context, c) {
          final track = _intervals.isEmpty
              ? _emptyResult(context, Theme.of(context).colorScheme)
              : IntervalTrack(
                  bars: _bars(),
                  domainMin: _domainMin,
                  domainMax: _domainMax,
                );

          final tail = Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ComparisonBadge(text: _step.badge),
              const SizedBox(height: 16),
              StepProgress(
                step: _index,
                total: _steps.length,
                caption: 'removed so far: ${_step.removed}',
              ),
              const SizedBox(height: 16),
              Legend(
                states: const [
                  VizState.found,
                  VizState.processing,
                  VizState.inScope,
                  VizState.discarded,
                  VizState.inactive,
                ],
                labels: const {
                  VizState.found: 'active (kept reference)',
                  VizState.processing: 'examining (iv)',
                  VizState.inScope: 'kept',
                  VizState.discarded: 'removed',
                  VizState.inactive: 'not yet reached',
                },
              ),
              const SizedBox(height: 16),
              ResultBanner(kind: result.kind, message: result.msg),
            ],
          );

          if (c.maxHeight.isFinite) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: SingleChildScrollView(child: track)),
                const SizedBox(height: 16),
                tail,
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [track, const SizedBox(height: 16), tail],
          );
        },
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
                lines: nonOverlapPseudocode,
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

  Widget _emptyResult(BuildContext context, ColorScheme scheme) {
    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(VizTokens.radius),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Text(
        'empty',
        style: AppTheme.mono(context,
            size: 12, color: scheme.onSurfaceVariant.withValues(alpha: 0.8)),
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
          width: 320,
          child: TextField(
            controller: _intervalsCtrl,
            style: AppTheme.mono(context, size: 13),
            decoration: _fieldDecoration('Intervals (sorted on run)'),
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

  String _fmt(num n) => n is int || n == n.roundToDouble()
      ? n.toInt().toString()
      : n.toString();

  String _fmtIv(Interval iv) => '[${_fmt(iv.start)}, ${_fmt(iv.end)}]';

  String _fmtList(List<Interval> ivs) => ivs.map(_fmtIv).join(', ');
}
