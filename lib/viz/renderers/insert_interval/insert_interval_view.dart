import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart' hide Interval;

import '../../../theme/app_theme.dart';
import '../../components/components.dart';
import '../../registry.dart';
import 'insert_interval_algo.dart';

/// Full-page "insert interval" visualizer, composed from the shared component
/// library and driven by the deterministic [generateInsertIntervalSteps]
/// recorder. Adds a new interval to a list of non-overlapping (but possibly
/// unsorted) intervals by sorting, then sweeping once with a carried `toAdd`.
///
/// Config:
///   type: insert-interval
///   intervals: [[1, 2], [3, 5], [6, 7], [8, 10], [12, 16]]
///   newInterval: [4, 8]
class InsertIntervalView extends StatefulWidget {
  final VizContext ctx;
  const InsertIntervalView(this.ctx, {super.key});

  static void register() {
    VizRegistry.register('insert-interval', (ctx) => InsertIntervalView(ctx));
  }

  @override
  State<InsertIntervalView> createState() => _InsertIntervalViewState();
}

class _InsertIntervalViewState extends State<InsertIntervalView> {
  late List<Interval> _intervals; // sorted, as displayed
  late Interval _newInterval;
  late List<InsertIntervalStep> _steps;
  late num _domainMin;
  late num _domainMax;
  int _index = 0;
  Timer? _timer;

  late final TextEditingController _intervalsCtrl;
  late final TextEditingController _newCtrl;

  bool get _playing => _timer != null;
  InsertIntervalStep get _step => _steps[_index];
  bool get _atStart => _index == 0;
  bool get _atEnd => _index == _steps.length - 1;

  @override
  void initState() {
    super.initState();
    final (ivs, ni) = _parseConfig();
    _apply(ivs, ni);
    _intervalsCtrl = TextEditingController(text: _fmtList(_intervals));
    _newCtrl = TextEditingController(text: _fmtIv(_newInterval));
  }

  void _apply(List<Interval> ivs, Interval ni) {
    _intervals = List<Interval>.from(ivs)
      ..sort((a, b) => a.start.compareTo(b.start));
    _newInterval = ni;
    _steps = generateInsertIntervalSteps(_intervals, _newInterval);
    _computeDomain();
    _index = 0;
  }

  void _computeDomain() {
    num lo = _newInterval.start, hi = _newInterval.end;
    for (final iv in _intervals) {
      lo = math.min(lo, iv.start);
      hi = math.max(hi, iv.end);
    }
    final pad = math.max(1, (hi - lo) * 0.08);
    _domainMin = lo - pad;
    _domainMax = hi + pad;
  }

  (List<Interval>, Interval) _parseConfig() {
    final c = widget.ctx.config;
    final ivs = _toIntervalList(c['intervals']);
    final ni = _toInterval(c['newInterval']) ?? const Interval(4, 8);
    if (ivs.isEmpty) {
      return (
        const [
          Interval(1, 2),
          Interval(3, 5),
          Interval(6, 7),
          Interval(8, 10),
          Interval(12, 16),
        ],
        ni,
      );
    }
    return (ivs, ni);
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

  @override
  void dispose() {
    _timer?.cancel();
    _intervalsCtrl.dispose();
    _newCtrl.dispose();
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
    final ni = _parseIntervalsField(_newCtrl.text);
    setState(() {
      _apply(
        ivs,
        ni.isNotEmpty ? ni.first : _newInterval,
      );
      _intervalsCtrl.text = _fmtList(_intervals);
      _newCtrl.text = _fmtIv(_newInterval);
    });
  }

  /// Parses numbers out of free text and pairs them into intervals, e.g.
  /// "[1,2],[6,9]" or "1 2 6 9" → [ [1,2], [6,9] ].
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
    if (s.committedSources.contains(i)) return VizState.found;
    if (s.absorbedSources.contains(i)) return VizState.inScope;
    if (s.current == i) return VizState.processing;
    return VizState.inactive;
  }

  List<IntervalBar> _workingBars() {
    final s = _step;
    return [
      if (s.toAdd != null)
        IntervalBar(
          start: s.toAdd!.start,
          end: s.toAdd!.end,
          label: 'toAdd',
          state: VizState.inScope,
          isNew: true,
        ),
      for (var i = 0; i < _intervals.length; i++)
        IntervalBar(
          start: _intervals[i].start,
          end: _intervals[i].end,
          label: 'iv$i',
          state: _sourceState(i),
        ),
    ];
  }

  List<IntervalBar> _resultBars() {
    final r = _step.result;
    return [
      for (var i = 0; i < r.length; i++)
        IntervalBar(
          start: r[i].start,
          end: r[i].end,
          label: 'r$i',
          state: VizState.found,
        ),
    ];
  }

  List<VizVar> _vars() {
    final s = _step;
    return [
      VizVar('newInterval', _fmtIv(_newInterval)),
      VizVar('toAdd', s.toAdd == null ? '–' : _fmtIv(s.toAdd!),
          changed: s.changed.contains('toAdd')),
      VizVar('iv', s.current == null ? '–' : _fmtIv(_intervals[s.current!])),
      VizVar('result', '[${s.result.map(_fmtIv).join(', ')}]',
          changed: s.changed.contains('result')),
    ];
  }

  ({ResultKind? kind, String? msg}) _result() {
    final s = _step;
    if (s.status == InsertIntervalStatus.done) {
      return (
        kind: ResultKind.success,
        msg: 'Inserted → [${s.result.map(_fmtIv).join(', ')}]',
      );
    }
    return (kind: null, msg: null);
  }

  // ── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final result = _result();
    final merges = _step.absorbedSources.length;

    return VizScaffold(
      title: 'Insert Interval',
      subtitle:
          'Sort, then sweep once carrying a single toAdd — non-overlap checks '
          'first, overlap by elimination.',
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
          final tracks = Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _trackHeading(context, scheme, 'Working set',
                  'toAdd (carried) + intervals'),
              const SizedBox(height: 8),
              IntervalTrack(
                bars: _workingBars(),
                domainMin: _domainMin,
                domainMax: _domainMax,
              ),
              const SizedBox(height: 22),
              _trackHeading(context, scheme, 'result',
                  'committed intervals'),
              const SizedBox(height: 8),
              if (_step.result.isEmpty)
                _emptyResult(context, scheme)
              else
                IntervalTrack(
                  bars: _resultBars(),
                  domainMin: _domainMin,
                  domainMax: _domainMax,
                ),
            ],
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
                caption: 'merged into toAdd: $merges',
              ),
              const SizedBox(height: 16),
              Legend(
                states: const [
                  VizState.inScope,
                  VizState.processing,
                  VizState.found,
                  VizState.inactive,
                ],
                labels: const {
                  VizState.inScope: 'toAdd / absorbed',
                  VizState.processing: 'examining (iv)',
                  VizState.found: 'committed to result',
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
                Expanded(
                  child: SingleChildScrollView(child: tracks),
                ),
                const SizedBox(height: 16),
                tail,
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [tracks, const SizedBox(height: 16), tail],
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
                lines: insertIntervalPseudocode,
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

  Widget _trackHeading(
    BuildContext context,
    ColorScheme scheme,
    String title,
    String hint,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          title,
          style: AppTheme.mono(context, size: 13, color: scheme.onSurface)
              .copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(width: 8),
        Text(
          hint,
          style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
        ),
      ],
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
        SizedBox(
          width: 260,
          child: TextField(
            controller: _intervalsCtrl,
            style: AppTheme.mono(context, size: 13),
            decoration: _fieldDecoration('Intervals (sorted on run)'),
            onSubmitted: (_) => _rebuild(),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 120,
          child: TextField(
            controller: _newCtrl,
            style: AppTheme.mono(context, size: 13),
            decoration: _fieldDecoration('New interval'),
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
