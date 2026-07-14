import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'fit_to_width.dart';
import 'viz_tokens.dart';

/// One value placed on a [CoordinateBoard] at grid position ([col], [row]).
/// Referenced by a stable [id] so a recorder can key it regardless of duplicate
/// values, and colored by a semantic [VizState].
class BoardItem {
  final int id;
  final num value;
  final int col;
  final int row;
  final VizState state;

  const BoardItem({
    required this.id,
    required this.value,
    required this.col,
    required this.row,
    this.state = VizState.inactive,
  });
}

/// Structure primitive: a 2-D **column board** that places each [BoardItem] at
/// its integer `(col, row)` coordinate - columns laid left→right by column
/// value, rows top→bottom by row value, and items that share a cell laid out
/// side by side sorted by value. An optional [activeColumn] paints a highlight
/// band behind one column (e.g. the column being emitted while grouping).
///
/// This is the natural picture for *coordinate-grouping* algorithms - vertical
/// order traversal, "group by column/diagonal", bucketing by key - where the
/// answer is read off the board column by column. Like every primitive it is a
/// dumb, stateless render of the step's data (no algorithm logic), colors come
/// from [vizStateColors], motion from [VizTokens], and it **self-fits** via
/// [FitToWidth] so a wide board scales down instead of side-scrolling.
class CoordinateBoard extends StatelessWidget {
  final List<BoardItem> items;

  /// Column value whose band is highlighted, or null for none.
  final int? activeColumn;

  const CoordinateBoard({
    super.key,
    required this.items,
    this.activeColumn,
  });

  static const double _chipW = 46;
  static const double _chipH = 32;
  static const double _chipGap = 5;
  static const double _rowH = 46;
  static const double _colGap = 16;
  static const double _colPad = 8;
  static const double _headerH = 26;
  static const double _gutterW = 34;
  static const double _bottomPad = 8;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 28),
        child: Center(
          child: Text(
            '(no nodes collected yet)',
            style:
                AppTheme.mono(context, size: 13, color: scheme.onSurfaceVariant),
          ),
        ),
      );
    }

    // Distinct, sorted columns and rows present on the board.
    final cols = items.map((e) => e.col).toSet().toList()..sort();
    final rows = items.map((e) => e.row).toSet().toList()..sort();
    final rowSlot = {for (var i = 0; i < rows.length; i++) rows[i]: i};

    // Bucket items into cells, sorted within a cell by value (the tie-break).
    final cell = <int, Map<int, List<BoardItem>>>{}; // col -> row -> items
    for (final it in items) {
      (cell[it.col] ??= {})[it.row] = [...?cell[it.col]?[it.row], it];
    }
    for (final byRow in cell.values) {
      for (final list in byRow.values) {
        list.sort((a, b) => a.value.compareTo(b.value));
      }
    }

    double cellWidth(List<BoardItem> list) =>
        list.length * _chipW + (list.length - 1) * _chipGap;

    // Column geometry.
    final colWidth = <int, double>{};
    for (final c in cols) {
      var w = _chipW;
      for (final list in (cell[c] ?? {}).values) {
        final cw = cellWidth(list);
        if (cw > w) w = cw;
      }
      colWidth[c] = w;
    }
    final colX = <int, double>{};
    var x = _gutterW;
    for (final c in cols) {
      colX[c] = x;
      x += colWidth[c]! + _colPad * 2 + _colGap;
    }
    final naturalWidth = x - _colGap + 4;
    final naturalHeight = _headerH + rows.length * _rowH + _bottomPad;

    final children = <Widget>[];

    // Highlight band behind the active column.
    if (activeColumn != null && colX.containsKey(activeColumn)) {
      final c = activeColumn!;
      children.add(Positioned(
        left: colX[c],
        top: 0,
        width: colWidth[c]! + _colPad * 2,
        height: naturalHeight,
        child: AnimatedContainer(
          duration: VizTokens.moveDuration,
          curve: VizTokens.spring,
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(VizTokens.radius),
            border: Border.all(color: scheme.primary.withValues(alpha: 0.35)),
          ),
        ),
      ));
    }

    // Row gutter labels (the depth of each row).
    for (final r in rows) {
      children.add(Positioned(
        left: 0,
        top: _headerH + rowSlot[r]! * _rowH,
        width: _gutterW - 6,
        height: _rowH,
        child: Center(
          child: Text(
            'r$r',
            style: AppTheme.mono(
              context,
              size: 11,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
        ),
      ));
    }

    // Column headers.
    for (final c in cols) {
      children.add(Positioned(
        left: colX[c]! - _colGap / 2,
        top: 0,
        width: colWidth[c]! + _colPad * 2 + _colGap,
        height: _headerH,
        child: Center(
          child: Text(
            'col $c',
            style: AppTheme.mono(
              context,
              size: 12,
              color: activeColumn == c
                  ? scheme.primary
                  : scheme.onSurfaceVariant,
            ).copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ));
    }

    // Value chips.
    for (final c in cols) {
      final byRow = cell[c] ?? {};
      for (final entry in byRow.entries) {
        final list = entry.value;
        final cw = cellWidth(list);
        final startX = colX[c]! + _colPad + (colWidth[c]! - cw) / 2;
        final y = _headerH +
            rowSlot[entry.key]! * _rowH +
            (_rowH - _chipH) / 2;
        for (var i = 0; i < list.length; i++) {
          children.add(_chip(
            context,
            scheme,
            list[i],
            startX + i * (_chipW + _chipGap),
            y,
          ));
        }
      }
    }

    return FitToWidth(
      naturalWidth: naturalWidth,
      naturalHeight: naturalHeight,
      child: SizedBox(
        width: naturalWidth,
        height: naturalHeight,
        child: Stack(clipBehavior: Clip.none, children: children),
      ),
    );
  }

  Widget _chip(
    BuildContext context,
    ColorScheme scheme,
    BoardItem item,
    double left,
    double top,
  ) {
    final c = vizStateColors(scheme, item.state);
    final emphatic =
        item.state == VizState.processing || item.state == VizState.found;
    return Positioned(
      left: left,
      top: top,
      width: _chipW,
      height: _chipH,
      child: AnimatedContainer(
        duration: VizTokens.moveDuration,
        curve: VizTokens.spring,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: c.fill,
          borderRadius: BorderRadius.circular(VizTokens.radius - 2),
          border: Border.all(color: c.border, width: emphatic ? 2 : 1),
          boxShadow: [
            if (emphatic)
              BoxShadow(
                color: c.border.withValues(alpha: 0.35),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Text(
          '${item.value}',
          style: AppTheme.mono(context, size: 14, color: c.foreground)
              .copyWith(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
