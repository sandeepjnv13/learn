import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'panel.dart';
import 'viz_tokens.dart';

/// Shows the full pseudocode with the current line highlighted, in sync with
/// the active step. Lines are indented per their leading spaces.
class PseudocodePanel extends StatelessWidget {
  final List<String> lines;

  /// 1-based line to highlight; null highlights nothing.
  final int? currentLine;
  final String title;

  /// When false, renders just the code lines without the surrounding [Panel]
  /// card — used when embedded inside a shared shell such as a [TabbedPanel].
  final bool framed;

  const PseudocodePanel({
    super.key,
    required this.lines,
    required this.currentLine,
    this.title = 'Pseudocode',
    this.framed = true,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < lines.length; i++)
          _line(context, scheme, i + 1, lines[i]),
      ],
    );
    if (!framed) return content;
    return Panel(
      title: title,
      icon: Icons.code_rounded,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: content,
    );
  }

  Widget _line(BuildContext context, ColorScheme scheme, int n, String text) {
    final active = n == currentLine;
    final indent = text.length - text.trimLeft().length;
    return AnimatedContainer(
      duration: VizTokens.moveDuration,
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: active ? scheme.primary.withValues(alpha: 0.12) : null,
        border: Border(
          left: BorderSide(
            width: 3,
            color: active ? scheme.primary : Colors.transparent,
          ),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 22,
            child: Text(
              '$n',
              textAlign: TextAlign.right,
              style: AppTheme.mono(
                context,
                size: 12,
                color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ),
          ),
          SizedBox(width: 12 + indent * 8.0),
          Expanded(
            child: Text(
              text.trimLeft(),
              style: AppTheme.mono(
                context,
                size: 13,
                color: active ? scheme.primary : scheme.onSurface,
              ).copyWith(
                fontWeight: active ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
