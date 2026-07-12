import 'package:flutter/material.dart';

import '../viz_focus.dart';
import 'viz_tokens.dart';

/// Full-page-scale shell for a native visualizer.
///
/// On desktop it lays out as **two big panels side by side**: an info column
/// (pseudocode, variables, and a scrolling [logPanel]) on the left and the
/// visualization [stage] filling the rest on the right. The row is
/// height-bounded so the whole experience fits without page scroll — only the
/// log scrolls internally.
///
/// On narrow screens everything stacks top-to-bottom in normal document flow.
class VizScaffold extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget controlBar;

  /// The visualization — the main, prominent area.
  final Widget stage;

  /// Fixed-height info panels stacked at the top of the left column
  /// (e.g. pseudocode, variables).
  final List<Widget> panels;

  /// The panel that fills the remaining height of the left column and scrolls
  /// internally (e.g. the event log). Should be an [EventLog] with `expand:true`.
  final Widget? logPanel;

  /// Fixed width of the left info column on desktop.
  final double infoWidth;

  /// Breakpoint below which the layout collapses to a single stacked column.
  final double breakpoint;

  const VizScaffold({
    super.key,
    required this.title,
    this.subtitle,
    required this.controlBar,
    required this.stage,
    required this.panels,
    this.logPanel,
    this.infoWidth = 380,
    this.breakpoint = 820,
  });

  @override
  Widget build(BuildContext context) {
    final fullscreen = VizPresentation.isFullscreen(context);
    final scheme = Theme.of(context).colorScheme;

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _header(context),
        const SizedBox(height: 16),
        controlBar,
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, c) => c.maxWidth >= breakpoint
              ? (fullscreen ? _wideFullscreen(context) : _wide(context))
              : _narrow(context),
        ),
      ],
    );

    // Focus mode: no card chrome or vertical margin — the page host frames it.
    if (fullscreen) return body;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: body,
    );
  }

  Widget _header(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        if (subtitle != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              subtitle!,
              style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
            ),
          ),
      ],
    );
  }

  // ── Desktop: info column | stage, height-bounded so nothing scrolls but
  //    the log ─────────────────────────────────────────────────────────────
  Widget _wide(BuildContext context) {
    final vh = MediaQuery.sizeOf(context).height;
    // Give the stage a comfortable, roomy height. It isn't forced to fit the
    // viewport exactly — a little page scroll is fine, and the "Fit" button
    // scrolls the whole card into view on demand.
    final height = (vh - 260).clamp(480.0, 820.0);
    return SizedBox(height: height, child: _stageRow(context));
  }

  // Focus mode: fill the viewport height the host offers, so the whole
  // experience sits on one locked page. Falls back to a sensible minimum on
  // very short windows (the host then scrolls rather than clipping).
  Widget _wideFullscreen(BuildContext context) {
    final avail =
        VizPresentation.heightOf(context) ?? MediaQuery.sizeOf(context).height;
    // Reserve the header + control bar + gaps that sit above this row.
    final height = (avail - 180).clamp(460.0, double.infinity);
    return SizedBox(height: height, child: _stageRow(context));
  }

  Widget _stageRow(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) => Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(width: _resolveInfoWidth(c.maxWidth), child: _infoColumn()),
          const SizedBox(width: VizTokens.panelGap),
          Expanded(child: _stageCard(context)),
        ],
      ),
    );
  }

  /// The info column (pseudocode/events + variables) is a fixed [infoWidth] on
  /// smaller screens so the stage — where the actual structure renders — keeps
  /// priority. On bigger screens it grows roughly in proportion to the width so
  /// the two panels don't drown in side padding, but the stage always stays the
  /// larger of the two (info capped at ~42% of the row).
  double _resolveInfoWidth(double w) {
    final maxInfo = w * 0.42; // stage keeps the remaining ~58%
    final target = w * 0.36;
    final floor = infoWidth < maxInfo ? infoWidth : maxInfo;
    return target.clamp(floor, maxInfo);
  }

  Widget _infoColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final p in panels) ...[
          p,
          const SizedBox(height: VizTokens.panelGap),
        ],
        if (logPanel != null) Expanded(child: logPanel!),
      ],
    );
  }

  Widget _stageCard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(VizTokens.radius + 2),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.7)),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: stage,
    );
  }

  // ── Narrow: stack everything top-to-bottom ────────────────────────────
  Widget _narrow(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _stageCard(context),
        const SizedBox(height: VizTokens.panelGap),
        for (final p in panels) ...[
          p,
          const SizedBox(height: VizTokens.panelGap),
        ],
        if (logPanel != null)
          SizedBox(height: 220, child: logPanel!),
      ],
    );
  }
}
