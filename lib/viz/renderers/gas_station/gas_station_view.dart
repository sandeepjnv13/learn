import 'dart:async';

import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../components/components.dart';
import '../../registry.dart';
import 'gas_station_algo.dart';

/// Rich, full-page Gas Station (LeetCode 134) visualizer composed entirely
/// from the shared component library. Driven by the deterministic
/// [generateGasStationSteps] recorder - stepping is pure index movement over
/// a precomputed list.
///
/// Config:
///   type: gas-station
///   gas: [1, 2, 3, 4, 5]
///   cost: [3, 4, 5, 1, 2]
class GasStationView extends StatefulWidget {
  final VizContext ctx;
  const GasStationView(this.ctx, {super.key});

  static void register() {
    VizRegistry.register('gas-station', (ctx) => GasStationView(ctx));
  }

  @override
  State<GasStationView> createState() => _GasStationViewState();
}

class _GasStationViewState extends State<GasStationView> {
  late List<int> _gas;
  late List<int> _cost;
  late List<GasStationStep> _steps;
  int _index = 0;
  Timer? _timer;

  late final TextEditingController _gasCtrl;
  late final TextEditingController _costCtrl;

  bool get _playing => _timer != null;
  GasStationStep get _step => _steps[_index];
  bool get _atStart => _index == 0;
  bool get _atEnd => _index == _steps.length - 1;

  @override
  void initState() {
    super.initState();
    final (gas, cost) = _parseConfig();
    _gas = gas;
    _cost = cost;
    _gasCtrl = TextEditingController(text: _gas.join(', '));
    _costCtrl = TextEditingController(text: _cost.join(', '));
    _steps = generateGasStationSteps(_gas, _cost);
  }

  (List<int>, List<int>) _parseConfig() {
    final c = widget.ctx.config;
    final gas = c['gas'] is List
        ? (c['gas'] as List).map(_toInt).toList()
        : [1, 2, 3, 4, 5];
    final cost = c['cost'] is List
        ? (c['cost'] as List).map(_toInt).toList()
        : [3, 4, 5, 1, 2];
    return (gas, cost);
  }

  int _toInt(dynamic v) => v is num ? v.toInt() : int.tryParse('$v'.trim()) ?? 0;

  // Preset examples - a comfortable win, the "always -1" total-cost check,
  // a single station, and consecutive deficits (startIdx moves twice).
  static const List<(VizPreset, List<int>, List<int>)> _presets = [
    (
      VizPreset('Circular route works', detail: 'answer is station 3'),
      [1, 2, 3, 4, 5],
      [3, 4, 5, 1, 2],
    ),
    (
      VizPreset('No solution',
          detail: 'total cost exceeds total gas - always −1', edgeCase: true),
      [2, 3, 4],
      [3, 4, 3],
    ),
    (
      VizPreset('Single station',
          detail: 'trivially feasible, start 0', edgeCase: true),
      [5],
      [4],
    ),
    (
      VizPreset('Consecutive deficits',
          detail: 'startIdx resets twice before it settles', edgeCase: true),
      [2, 3, 4, 1, 1],
      [3, 4, 1, 1, 1],
    ),
  ];

  void _loadPreset(int i) {
    final p = _presets[i];
    _gasCtrl.text = p.$2.join(', ');
    _costCtrl.text = p.$3.join(', ');
    _rebuild();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _gasCtrl.dispose();
    _costCtrl.dispose();
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

  List<int> _parseInts(String text) => text
      .split(RegExp(r'[,\s]+'))
      .where((s) => s.trim().isNotEmpty)
      .map((s) => int.tryParse(s.trim()))
      .whereType<int>()
      .toList();

  void _rebuild() {
    _stop();
    // Gas and cost are fuel amounts - never negative. Clamp any negative
    // input to 0 so the running balance still means "fuel in the tank".
    final gas = [for (final v in _parseInts(_gasCtrl.text)) v < 0 ? 0 : v];
    final cost = [for (final v in _parseInts(_costCtrl.text)) v < 0 ? 0 : v];
    setState(() {
      _gas = gas.isEmpty ? _gas : gas;
      _cost = cost.isEmpty ? _cost : cost;
      _gasCtrl.text = _gas.join(', ');
      _costCtrl.text = _cost.join(', ');
      _steps = generateGasStationSteps(_gas, _cost);
      _index = 0;
    });
  }

  // ── Derived view state ────────────────────────────────────────────────

  /// runningGas as the algorithm evaluates it at each station: the tank level
  /// right after adding `gas[i] - cost[i]`, *before* any reset-to-0. Dipping
  /// below the baseline is exactly what triggers moving the start forward.
  List<num> get _runSeries {
    var rg = 0;
    final out = <num>[];
    for (var k = 0; k < _gas.length; k++) {
      rg += _gas[k] - _cost[k];
      out.add(rg);
      if (rg < 0) rg = 0;
    }
    return out;
  }

  Map<int, VizState> _cellStates() {
    final s = _step;
    final states = <int, VizState>{};
    for (var idx = 0; idx < _gas.length; idx++) {
      if (s.status == GasStationStatus.found) {
        states[idx] = idx == s.result ? VizState.found : VizState.inScope;
      } else if (s.status == GasStationStatus.notFound) {
        states[idx] = VizState.discarded;
      } else if (idx < s.startIdx) {
        states[idx] = VizState.discarded;
      } else if (s.i != null && idx == s.i) {
        states[idx] = VizState.processing;
      } else if (s.i != null && idx > s.i!) {
        states[idx] = VizState.inactive;
      } else {
        states[idx] = VizState.inScope;
      }
    }
    return states;
  }

  List<ArrayPointer> _pointers(ColorScheme scheme) {
    final s = _step;
    return [
      ArrayPointer('start', s.startIdx, color: scheme.primary),
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
      VizVar('totalGas', '${s.totalGas}', changed: s.changed.contains('totalGas')),
      VizVar('totalCost', '${s.totalCost}',
          changed: s.changed.contains('totalCost')),
      VizVar('runningGas', '${s.runningGas}',
          changed: s.changed.contains('runningGas')),
      VizVar('startIdx', '${s.startIdx}', changed: s.changed.contains('startIdx')),
    ];
  }

  ({ResultKind? kind, String? msg}) _result() {
    final s = _step;
    if (s.status == GasStationStatus.found) {
      return (
        kind: ResultKind.success,
        msg: 'Start at station ${s.result} - the circuit can be completed.'
      );
    }
    if (s.status == GasStationStatus.notFound) {
      return (
        kind: ResultKind.failure,
        msg: 'No valid start - total cost exceeds total gas.'
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
      title: 'Gas Station',
      subtitle: 'One pass, running tank balance - reset the start on deficit.',
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
          _labeledRow(
            context,
            'gas',
            ArrayCells(
              values: _gas,
              states: _cellStates(),
              pointers: _pointers(scheme),
              showIndices: false,
            ),
          ),
          _labeledRow(
            context,
            'cost',
            ArrayCells(
              values: _cost,
              states: _cellStates(),
              showIndices: false,
            ),
          ),
          _labeledRow(
            context,
            'runningGas (resets to 0 when it drops below the baseline)',
            BaselineBarPlot(
              values: _runSeries,
              states: _cellStates(),
            ),
          ),
          const SizedBox(height: 24),
          ComparisonBadge(text: _step.badge),
          const SizedBox(height: 16),
          StepProgress(
            step: _index,
            total: _steps.length,
            caption: 'runningGas: ${_step.runningGas}',
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
              VizState.inScope: 'candidate range',
              VizState.discarded: 'ruled out',
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
                lines: gasStationPseudocode,
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

  // One stacked variable row (gas / cost / gas - cost) with a small caption
  // above it. All rows share the same length and centering, so the columns
  // line up into a single station-by-station table.
  Widget _labeledRow(BuildContext context, String label, Widget cells) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppTheme.mono(context, size: 11,
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.85))
                .copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          cells,
        ],
      ),
    );
  }

  Widget _inputs(ColorScheme scheme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        PresetPicker(
          presets: [for (final p in _presets) p.$1],
          onSelected: _loadPreset,
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 180,
          child: TextField(
            controller: _gasCtrl,
            style: AppTheme.mono(context, size: 13),
            decoration: _fieldDecoration('gas[]'),
            onSubmitted: (_) => _rebuild(),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 180,
          child: TextField(
            controller: _costCtrl,
            style: AppTheme.mono(context, size: 13),
            decoration: _fieldDecoration('cost[]'),
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
