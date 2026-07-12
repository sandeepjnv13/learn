import 'package:flutter/material.dart';

import 'panel.dart';
import 'viz_tokens.dart';

/// One tab of a [TabbedPanel].
class PanelTab {
  final IconData icon;
  final String label;
  final Widget child;
  const PanelTab({required this.icon, required this.label, required this.child});
}

/// A [Panel] whose header is a segmented tab switcher: only one [PanelTab]'s
/// content is shown at a time. Used to fold two related panels (e.g. pseudocode
/// and the event log) into a single card so they share space instead of
/// stacking. When [fill] is true the active tab flexes to fill the bounded
/// height it is given (and may scroll internally).
class TabbedPanel extends StatefulWidget {
  final List<PanelTab> tabs;
  final bool fill;
  final int initialIndex;

  const TabbedPanel({
    super.key,
    required this.tabs,
    this.fill = false,
    this.initialIndex = 0,
  });

  @override
  State<TabbedPanel> createState() => _TabbedPanelState();
}

class _TabbedPanelState extends State<TabbedPanel> {
  late int _index = widget.initialIndex.clamp(0, widget.tabs.length - 1);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Keep every tab alive (preserves scroll position / animations) but only
    // show the selected one.
    final body = IndexedStack(
      index: _index,
      sizing: StackFit.expand,
      children: [for (final t in widget.tabs) t.child],
    );

    return Panel(
      header: _tabBar(scheme),
      padding: EdgeInsets.zero,
      fill: widget.fill,
      child: widget.fill ? body : SizedBox(height: 320, child: body),
    );
  }

  Widget _tabBar(ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.6)),
        ),
      ),
      child: Row(
        children: [
          for (var i = 0; i < widget.tabs.length; i++)
            Expanded(child: _tab(scheme, i)),
        ],
      ),
    );
  }

  Widget _tab(ColorScheme scheme, int i) {
    final selected = i == _index;
    final t = widget.tabs[i];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Material(
        color: selected ? scheme.primary.withValues(alpha: 0.12) : Colors.transparent,
        borderRadius: BorderRadius.circular(VizTokens.radius - 2),
        child: InkWell(
          borderRadius: BorderRadius.circular(VizTokens.radius - 2),
          onTap: selected ? null : () => setState(() => _index = i),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  t.icon,
                  size: 15,
                  color: selected ? scheme.primary : scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    t.label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? scheme.primary : scheme.onSurfaceVariant,
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
}
