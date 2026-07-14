import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'panel.dart';

/// A scrolling plain-English trace. Shows every entry up to (and including) the
/// current step, auto-scrolling to keep the newest line in view and dimming the
/// past.
class EventLog extends StatefulWidget {
  final List<String> entries; // all entries visible so far, oldest first
  final String title;
  final double height;

  /// When true the log flexes to fill the height its parent gives it (which
  /// must be bounded) instead of using the fixed [height]. Only the log
  /// scrolls; everything around it stays put.
  final bool expand;

  /// When false, renders just the scrolling list without the surrounding
  /// [Panel] card - used when embedded inside a shared shell such as a
  /// [TabbedPanel].
  final bool framed;

  const EventLog({
    super.key,
    required this.entries,
    this.title = 'Event log',
    this.height = 180,
    this.expand = false,
    this.framed = true,
  });

  @override
  State<EventLog> createState() => _EventLogState();
}

class _EventLogState extends State<EventLog> {
  final _scroll = ScrollController();

  @override
  void didUpdateWidget(covariant EventLog old) {
    super.didUpdateWidget(old);
    if (old.entries.length != widget.entries.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          _scroll.animateTo(
            _scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final last = widget.entries.length - 1;

    final content = SizedBox(
      height: widget.expand ? null : widget.height,
      child: widget.entries.isEmpty
          ? Center(
              child: Text(
                'Press Start to begin.',
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
            )
          : ListView.builder(
              controller: _scroll,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: widget.entries.length,
              itemBuilder: (context, i) {
                final current = i == last;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${i + 1}'.padLeft(2, '0'),
                        style: AppTheme.mono(
                          context,
                          size: 11,
                          color:
                              scheme.onSurfaceVariant.withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.entries[i],
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.4,
                            color: current
                                ? scheme.onSurface
                                : scheme.onSurfaceVariant
                                    .withValues(alpha: 0.7),
                            fontWeight:
                                current ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );

    if (!widget.framed) return content;
    return Panel(
      title: widget.title,
      icon: Icons.receipt_long_rounded,
      padding: EdgeInsets.zero,
      fill: widget.expand,
      child: content,
    );
  }
}
