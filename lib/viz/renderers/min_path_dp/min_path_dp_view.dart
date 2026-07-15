import 'dart:async';

import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../components/components.dart';
import '../../registry.dart';
import 'min_path_dp_algo.dart';

/// Bottom-up (tabulation) min-cost-path visualizer, composed from the shared
/// component library and driven by the deterministic [generateMinPathDpSteps]
/// recorder.
///
/// The companion to the `overlapping-subproblems` card on the same page: same
/// recurrence, but filled in an order where both predecessors are already known
/// - so the table replaces the recursion entirely.
///
/// Config:
///   type: min-path-dp
///   grid: [[1, 3, 1], [1, 5, 1], [4, 2, 1]]
class MinPathDpView extends StatefulWidget {
  final VizContext ctx;
  const MinPathDpView(this.ctx, {super.key});

  static void register() {
    VizRegistry.register('min-path-dp', (ctx) => MinPathDpView(ctx));
  }

  @override
  State<MinPathDpView> createState() => _MinPathDpViewState();
}

class _MinPathDpViewState extends State<MinPathDpView> {
  late List<List<num>> _grid;
  late List<MinPathStep> _steps;
  int _index = 0;
  Timer? _timer;

  late final TextEditingController _gridCtrl;

  bool get _playing => _timer != null;
  MinPathStep get _step => _steps[_index];
  bool get _atStart => _index == 0;
  bool get _atEnd => _index == _steps.length - 1;

  static const List<List<num>> _fallback = [
    [1, 3, 1],
    [1, 5, 1],
    [4, 2, 1],
  ];

  @override
  void initState() {
    super.initState();
    _grid = _parseConfig();
    _gridCtrl = TextEditingController(text: _encode(_grid));
    _steps = generateMinPathDpSteps(_grid);
  }

  List<List<num>> _parseConfig() {
    final raw = widget.ctx.config['grid'];
    if (raw is List && raw.isNotEmpty) {
      final rows = <List<num>>[];
      for (final r in raw) {
        if (r is List && r.isNotEmpty) {
          rows.add(r.map(_toNum).toList());
        }
      }
      if (rows.isNotEmpty && _rectangular(rows)) return rows;
    }
    return _fallback.map((r) => List<num>.from(r)).toList();
  }

  static bool _rectangular(List<List<num>> rows) =>
      rows.every((r) => r.length == rows[0].length);

  num _toNum(dynamic v) => v is num ? v : num.tryParse('$v'.trim()) ?? 0;

  String _fmt(num n) =>
      n is int || n == n.roundToDouble() ? n.toInt().toString() : n.toString();

  String _encode(List<List<num>> g) =>
      g.map((r) => r.map(_fmt).join(', ')).join(' ; ');

  // Presets: the classic grid, a case where the greedy-looking move loses, and
  // the degenerate shapes where whole loops never run.
  static const List<(VizPreset, List<List<num>>)> _presets = [
    (
      VizPreset('Classic 3×3', detail: 'the grid from the recursion tree above'),
      [
        [1, 3, 1],
        [1, 5, 1],
        [4, 2, 1],
      ],
    ),
    (
      VizPreset('Detour pays off',
          detail: 'the cheap first step leads into a wall - min() saves it'),
      [
        [1, 9, 9],
        [1, 9, 9],
        [1, 1, 1],
      ],
    ),
    (
      VizPreset('Above = left (tie)',
          detail: 'both predecessors equal - either choice gives the same total',
          edgeCase: true),
      [
        [1, 2],
        [2, 1],
      ],
    ),
    (
      VizPreset('Single row',
          detail: 'no cell above - the interior loop never runs',
          edgeCase: true),
      [
        [1, 2, 3, 4],
      ],
    ),
    (
      VizPreset('Single cell',
          detail: 'start is the end - the answer is just grid[0][0]',
          edgeCase: true),
      [
        [5],
      ],
    ),
  ];

  void _loadPreset(int i) {
    _gridCtrl.text = _encode(_presets[i].$2);
    _rebuild();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _gridCtrl.dispose();
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
    final rows = <List<num>>[];
    for (final chunk in _gridCtrl.text.split(RegExp(r'[;\n]'))) {
      final vals = chunk
          .split(RegExp(r'[,\s]+'))
          .where((s) => s.trim().isNotEmpty)
          .map((s) => num.tryParse(s.trim()))
          .whereType<num>()
          .toList();
      if (vals.isNotEmpty) rows.add(vals);
    }
    // Ragged or empty input is not a grid - fall back rather than crash.
    final grid = (rows.isEmpty || !_rectangular(rows))
        ? _fallback.map((r) => List<num>.from(r)).toList()
        : rows;
    setState(() {
      _grid = grid;
      _gridCtrl.text = _encode(_grid);
      _steps = generateMinPathDpSteps(_grid);
      _index = 0;
    });
  }

  // ── Derived view state ────────────────────────────────────────────────

  List<GridCellSpec> _cells() {
    final s = _step;
    final out = <GridCellSpec>[];
    final lastRow = _grid.length - 1;
    final lastCol = _grid[0].length - 1;

    for (var i = 0; i < _grid.length; i++) {
      for (var j = 0; j < _grid[0].length; j++) {
        final value = s.dp[i][j];
        VizState state;
        if (s.path.contains('$i,$j')) {
          state = VizState.found;
        } else if (i == s.row && j == s.col && s.status != MinPathStatus.done) {
          state = VizState.processing;
        } else if (value != null) {
          state = VizState.inScope;
        } else {
          state = VizState.inactive;
        }
        out.add(GridCellSpec(
          row: i,
          col: j,
          value: value == null ? null : _fmt(value),
          corner: _fmt(_grid[i][j]),
          state: state,
          tag: i == 0 && j == 0
              ? 'start'
              : (i == lastRow && j == lastCol ? 'end' : null),
        ));
      }
    }
    return out;
  }

  List<GridArrow> _arrows() {
    final s = _step;
    if (s.fromRow == null || s.row == null) return const [];
    return [GridArrow(s.fromRow!, s.fromCol!, s.row!, s.col!)];
  }

  List<VizVar> _vars() {
    final s = _step;
    final cell = (s.row != null && s.col != null) ? s.dp[s.row!][s.col!] : null;
    return [
      VizVar('i', s.row?.toString() ?? '–', changed: s.changed.contains('i')),
      VizVar('j', s.col?.toString() ?? '–', changed: s.changed.contains('j')),
      VizVar(
        'dp[i][j]',
        cell == null ? '–' : _fmt(cell),
        changed: s.changed.contains('dp[i][j]'),
      ),
      VizVar('answer', s.answer == null ? '–' : _fmt(s.answer!)),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final done = _step.status == MinPathStatus.done;
    final filled =
        _step.dp.expand((r) => r).where((v) => v != null).length;
    final total = _grid.length * _grid[0].length;

    return VizScaffold(
      title: 'Min Cost Path - bottom-up table',
      subtitle: 'Fill every cell once, in an order that needs no recursion.',
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
          GridBoard(
            rows: _grid.length,
            cols: _grid[0].length,
            cells: _cells(),
            arrows: _arrows(),
          ),
          const SizedBox(height: 20),
          ComparisonBadge(text: _step.badge),
          const SizedBox(height: 16),
          StepProgress(
            step: _index,
            total: _steps.length,
            caption: 'cells solved: $filled / $total',
          ),
          const SizedBox(height: 16),
          Legend(
            states: const [
              VizState.inactive,
              VizState.processing,
              VizState.inScope,
              VizState.found,
            ],
            labels: const {
              VizState.inactive: 'Not solved yet',
              VizState.processing: 'Solving now',
              VizState.inScope: 'Solved (final)',
              VizState.found: 'Cheapest path',
            },
          ),
          const SizedBox(height: 16),
          ResultBanner(
            kind: done ? ResultKind.success : null,
            message: done && _step.answer != null
                ? 'Cheapest path costs ${_fmt(_step.answer!)} - '
                    '$total cells, each solved exactly once.'
                : null,
          ),
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
                lines: minPathDpPseudocode,
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
    // Wraps rather than overflowing when the control bar is narrow.
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        PresetPicker(
          presets: [for (final p in _presets) p.$1],
          onSelected: _loadPreset,
        ),
        SizedBox(
          width: 260,
          child: TextField(
            controller: _gridCtrl,
            style: AppTheme.mono(context, size: 13),
            decoration: InputDecoration(
              labelText: 'Grid (rows split by ;)',
              isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            onSubmitted: (_) => _rebuild(),
          ),
        ),
        IconButton.filledTonal(
          onPressed: _rebuild,
          icon: const Icon(Icons.check_rounded),
          tooltip: 'Apply grid',
        ),
      ],
    );
  }
}
