import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'registry.dart';

/// How a visualizer is currently being presented.
enum VizMode {
  /// Embedded inline in the flowing markdown document.
  inline,

  /// Taken over the full viewport in focus mode.
  fullscreen,
}

/// Ambient presentation info for the visualizer subtree. Renderers read this to
/// decide whether to draw their compact inline card or fill the whole viewport.
class VizPresentation extends InheritedWidget {
  final VizMode mode;

  /// In [VizMode.fullscreen], the height available to the viz (viewport minus
  /// the focus-mode chrome). Null when inline.
  final double? availableHeight;

  const VizPresentation({
    super.key,
    required this.mode,
    this.availableHeight,
    required super.child,
  });

  static VizPresentation? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<VizPresentation>();

  /// The current mode, defaulting to [VizMode.inline] outside any focus host.
  static VizMode modeOf(BuildContext context) =>
      maybeOf(context)?.mode ?? VizMode.inline;

  static bool isFullscreen(BuildContext context) =>
      modeOf(context) == VizMode.fullscreen;

  static double? heightOf(BuildContext context) =>
      maybeOf(context)?.availableHeight;

  @override
  bool updateShouldNotify(VizPresentation old) =>
      mode != old.mode || availableHeight != old.availableHeight;
}

/// Wraps every visualizer with "Fit" and "Focus" affordances. Inline it renders
/// the viz as usual with a small button cluster in the corner: **Fit** scrolls
/// the page so the entire visualizer is on screen (it is sized to fit the
/// viewport, so no internal scroll is needed), and **Focus** opens the same viz
/// full-screen (see [_FocusModePage]).
class VizLauncher extends StatefulWidget {
  final VizContext ctx;
  const VizLauncher(this.ctx, {super.key});

  @override
  State<VizLauncher> createState() => _VizLauncherState();
}

class _VizLauncherState extends State<VizLauncher> {
  /// Marks the viz subtree so [_fit] can scroll it fully into view.
  final GlobalKey _vizKey = GlobalKey();

  void _openFocus() {
    Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder(
        opaque: true,
        fullscreenDialog: true,
        transitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (_, _, _) => _FocusModePage(ctx: widget.ctx),
        transitionsBuilder: (_, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  /// Scrolls the enclosing page so the whole visualizer sits in view, aligning
  /// its top with the top of the scroll viewport.
  void _fit() {
    final target = _vizKey.currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      alignment: 0.0,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Static cards (e.g. the `approach` glance card) are non-interactive and
    // inline-only: render them plainly, without the Fit/Focus chrome.
    if (VizRegistry.isStatic(widget.ctx.config['type'])) {
      return VizPresentation(
        mode: VizMode.inline,
        child: VizRegistry.build(widget.ctx),
      );
    }
    // Fresh inline instance; focus mode builds its own separate instance.
    return VizPresentation(
      mode: VizMode.inline,
      child: Stack(
        key: _vizKey,
        children: [
          VizRegistry.build(widget.ctx),
          Positioned(
            top: 28,
            right: 12,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _PillButton(
                  icon: Icons.fit_screen_rounded,
                  label: 'Fit',
                  onPressed: _fit,
                ),
                const SizedBox(width: 8),
                _PillButton(
                  icon: Icons.open_in_full_rounded,
                  label: 'Focus',
                  onPressed: _openFocus,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A small rounded action button shown in the corner of inline visualizers.
class _PillButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  const _PillButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.9),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: scheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Full-viewport takeover for a single visualizer. Covers the app chrome
/// (including the left nav, since it is pushed on the root navigator), and
/// provides an Exit affordance. The viz fills the viewport and stays locked when
/// it fits; when the window is too short or narrow it scrolls instead of
/// clipping.
class _FocusModePage extends StatelessWidget {
  final VizContext ctx;
  const _FocusModePage({required this.ctx});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      body: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.escape): () =>
              Navigator.of(context).maybePop(),
        },
        child: Focus(
          autofocus: true,
          child: SafeArea(
            child: Column(
              children: [
                _topBar(context),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, c) => VizPresentation(
                      mode: VizMode.fullscreen,
                      availableHeight: c.maxHeight,
                      child: SingleChildScrollView(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 20),
                        child: VizRegistry.build(ctx),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _topBar(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 12, 6),
      child: Row(
        children: [
          Icon(Icons.center_focus_strong_rounded,
              size: 18, color: scheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Text(
            'Focus mode',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.close_rounded, size: 18),
            label: const Text('Exit'),
            style: TextButton.styleFrom(foregroundColor: scheme.onSurface),
          ),
        ],
      ),
    );
  }
}
