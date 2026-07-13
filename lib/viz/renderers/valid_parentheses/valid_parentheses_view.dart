import 'dart:async';

import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../components/components.dart';
import '../../registry.dart';
import 'valid_parentheses_algo.dart';

/// Full-page Valid Parentheses visualizer composed from the shared component
/// library and driven by the deterministic [generateValidParenthesesSteps]
/// recorder. Uses a **vertical** [StackView] — the textbook LIFO picture that
/// makes "the most recent opener must close first" obvious.
///
/// Config:
///   type: valid-parentheses
///   input: "([{}])"
class ValidParenthesesView extends StatefulWidget {
  final VizContext ctx;
  const ValidParenthesesView(this.ctx, {super.key});

  static void register() {
    VizRegistry.register(
        'valid-parentheses', (ctx) => ValidParenthesesView(ctx));
  }

  @override
  State<ValidParenthesesView> createState() => _VpViewState();
}

class _VpViewState extends State<ValidParenthesesView> {
  late String _input;
  late List<VpStep> _steps;
  int _index = 0;
  Timer? _timer;

  late final TextEditingController _inputCtrl;

  bool get _playing => _timer != null;
  VpStep get _step => _steps[_index];
  bool get _atStart => _index == 0;
  bool get _atEnd => _index == _steps.length - 1;

  @override
  void initState() {
    super.initState();
    _input = _parseConfig();
    _inputCtrl = TextEditingController(text: _input);
    _steps = generateValidParenthesesSteps(_input);
  }

  String _parseConfig() {
    final c = widget.ctx.config;
    final v = c['input'] ?? c['string'] ?? c['s'];
    if (v is String && v.trim().isNotEmpty) return v.trim();
    return '([{}])';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _inputCtrl.dispose();
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
    setState(() {
      _input = _inputCtrl.text.trim().isEmpty ? '([{}])' : _inputCtrl.text.trim();
      _steps = generateValidParenthesesSteps(_input);
      _index = 0;
    });
  }

  /// The bracket characters actually processed (non-bracket chars are ignored
  /// by the recorder, so the strip must show the same filtered sequence).
  List<String> get _chars => _input
      .split('')
      .where((c) => '()[]{}'.contains(c))
      .toList();

  // ── Derived view state ────────────────────────────────────────────────

  Map<int, VizState> _charStates() {
    final s = _step;
    final states = <int, VizState>{};
    for (var k = 0; k < _chars.length; k++) {
      if (s.i == null) {
        states[k] = VizState.discarded; // terminal step: all read
      } else if (k < s.i!) {
        states[k] = VizState.discarded; // already consumed
      } else if (k == s.i!) {
        states[k] = VizState.processing; // current char
      } else {
        states[k] = VizState.inactive; // not read yet
      }
    }
    return states;
  }

  Map<int, VizState> _stackStates() {
    final s = _step;
    final states = <int, VizState>{};
    for (var p = 0; p < s.stack.length; p++) {
      states[p] = VizState.inScope;
    }
    // Highlight the top when we are comparing / popping it (lines 5–8).
    if (s.stack.isNotEmpty && s.line >= 5 && s.line <= 8) {
      states[s.stack.length - 1] = VizState.processing;
    }
    return states;
  }

  List<VizVar> _vars() {
    final s = _step;
    final ch = s.i != null && s.i! < _chars.length ? _chars[s.i!] : '–';
    final top = s.stack.isEmpty ? '–' : s.stack.last;
    return [
      VizVar('ch', ch, changed: s.changed.contains('ch')),
      VizVar('top', top, changed: s.changed.contains('stack')),
      VizVar('depth', '${s.stack.length}', changed: s.changed.contains('stack')),
    ];
  }

  ({ResultKind? kind, String? msg}) _result() {
    switch (_step.status) {
      case VpStatus.valid:
        return (kind: ResultKind.success, msg: 'Valid — every bracket is balanced.');
      case VpStatus.invalid:
        return (kind: ResultKind.failure, msg: 'Not valid — brackets are unbalanced.');
      case VpStatus.running:
        return (kind: null, msg: null);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final result = _result();
    final s = _step;

    return VizScaffold(
      title: 'Valid Parentheses',
      subtitle:
          'Push every opener; each closer must match the most recent opener on '
          'top of the stack (LIFO).',
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
          _sectionLabel(context, 'Input'),
          const SizedBox(height: 8),
          _CharStrip(chars: _chars, states: _charStates(), cursor: s.i),
          const SizedBox(height: 22),
          _sectionLabel(context, 'Stack (top = most recent opener, push/pop here)'),
          const SizedBox(height: 8),
          StackView(
            values: s.stack,
            states: _stackStates(),
            emptyLabel: 'empty',
          ),
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
              VizState.discarded,
            ],
            labels: const {
              VizState.inactive: 'unread',
              VizState.processing: 'current / top',
              VizState.inScope: 'on stack',
              VizState.discarded: 'consumed',
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
                lines: validParenthesesPseudocode,
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
      textAlign: TextAlign.center,
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
        SizedBox(
          width: 220,
          child: TextField(
            controller: _inputCtrl,
            style: AppTheme.mono(context, size: 14),
            decoration: InputDecoration(
              labelText: 'Brackets, e.g. ([{}])',
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

/// Read-only strip of the input bracket characters with a gliding cursor — a
/// lightweight input display (not a structure primitive). Self-fits the width.
class _CharStrip extends StatelessWidget {
  final List<String> chars;
  final Map<int, VizState> states;
  final int? cursor;

  const _CharStrip({required this.chars, required this.states, this.cursor});

  static const double _w = 44;
  static const double _gap = 8;
  static const double _laneH = 24;
  static const double _idxH = 16;

  double get _stride => _w + _gap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final n = chars.length;
    final totalW = n == 0 ? _w : n * _stride - _gap;
    final totalH = _laneH + 4 + _w + 4 + _idxH;

    return FitToWidth(
      naturalWidth: totalW,
      naturalHeight: totalH,
      child: SizedBox(
        width: totalW,
        height: totalH,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            if (cursor != null && cursor! >= 0 && cursor! < n)
              AnimatedPositioned(
                duration: VizTokens.moveDuration,
                curve: VizTokens.spring,
                left: cursor! * _stride,
                top: 0,
                width: _w,
                height: _laneH,
                child: Center(
                  child: Icon(Icons.arrow_drop_down_rounded,
                      color: scheme.primary, size: 22),
                ),
              ),
            for (var k = 0; k < n; k++)
              Positioned(
                left: k * _stride,
                top: _laneH + 4,
                width: _w,
                height: _w,
                child: _box(context, scheme, k),
              ),
            for (var k = 0; k < n; k++)
              Positioned(
                left: k * _stride,
                top: _laneH + 4 + _w + 4,
                width: _w,
                height: _idxH,
                child: Center(
                  child: Text(
                    '$k',
                    style: AppTheme.mono(context,
                        size: 11,
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.6)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _box(BuildContext context, ColorScheme scheme, int k) {
    final c = vizStateColors(scheme, states[k] ?? VizState.inactive);
    final emphatic = (states[k] ?? VizState.inactive) == VizState.processing;
    return AnimatedContainer(
      duration: VizTokens.moveDuration,
      curve: VizTokens.spring,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: c.fill,
        borderRadius: BorderRadius.circular(VizTokens.radius),
        border: Border.all(color: c.border, width: emphatic ? 2 : 1),
      ),
      child: Text(
        chars[k],
        style: AppTheme.mono(context, size: 18, color: c.foreground)
            .copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}
