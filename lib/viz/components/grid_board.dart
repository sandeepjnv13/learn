import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'fit_to_width.dart';
import 'viz_tokens.dart';

/// One cell of a [GridBoard].
///
/// [value] is the big label (a dp answer, a distance, a flood-fill mark); null
/// renders the cell as still-unfilled. [corner] is the small muted label in the
/// top-left - typically the input the dp is derived from (the grid's own cost),
/// so a learner can see `dp[i][j]` and `grid[i][j]` at once.
class GridCellSpec {
  final int row;
  final int col;
  final String? value;
  final String? corner;
  final VizState state;

  /// Small pill under the cell (e.g. `start`, `end`).
  final String? tag;

  /// Identity tint index (see [vizIdentityColors]); overrides the [state] fill
  /// so repeated/matched cells can be color-matched to another visual. Null
  /// (the default) uses the semantic state color.
  final int? tint;

  const GridCellSpec({
    required this.row,
    required this.col,
    this.value,
    this.corner,
    this.state = VizState.inactive,
    this.tag,
    this.tint,
  });
}

/// An arrow drawn between two cell centers - the "where this answer came from"
/// cue (e.g. dp[i][j] took its min from the cell above).
class GridArrow {
  final int fromRow;
  final int fromCol;
  final int toRow;
  final int toCol;
  const GridArrow(this.fromRow, this.fromCol, this.toRow, this.toCol);
}

/// Structure primitive: a **dense 2-D matrix** of cells addressed by
/// `(row, col)` - the natural picture for grid DP (min path sum, edit distance,
/// unique paths), flood fill, and matrix walks. Distinct from the sparse
/// [CoordinateBoard], which places scattered items at coordinates; here every
/// slot in a `rows × cols` rectangle is drawn.
///
/// Dumb stateless render: colors come from [vizStateColors] (or
/// [vizIdentityColors] when a cell sets `tint`), motion from [VizTokens], and
/// it self-fits via [FitToWidth] so a wide grid scales down instead of
/// side-scrolling. No algorithm logic lives here.
class GridBoard extends StatelessWidget {
  final int rows;
  final int cols;
  final List<GridCellSpec> cells;

  /// Provenance arrows between cell centers.
  final List<GridArrow> arrows;

  /// Draws `i`/`j` index rulers along the top and left edges.
  final bool showIndices;

  /// Edge length of a cell. Shrink it when the grid is a secondary visual
  /// sitting alongside another structure rather than the main event.
  final double cellSize;

  const GridBoard({
    super.key,
    required this.rows,
    required this.cols,
    required this.cells,
    this.arrows = const [],
    this.showIndices = true,
    this.cellSize = 62,
  });

  static const double _gap = 8;
  static const double _ruler = 20;
  static const double _tagLane = 16;

  double get _cell => cellSize;
  double get _stride => _cell + _gap;

  double get _originX => showIndices ? _ruler : 0;
  double get _originY => showIndices ? _ruler : 0;

  Offset _centerOf(int row, int col) => Offset(
        _originX + col * _stride + _cell / 2,
        _originY + row * _stride + _cell / 2,
      );

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final naturalWidth = _originX + cols * _stride - _gap;
    final naturalHeight = _originY + rows * _stride - _gap + _tagLane;

    final children = <Widget>[
      if (arrows.isNotEmpty)
        Positioned.fill(
          child: CustomPaint(
            painter: _ArrowPainter(
              arrows: [
                for (final a in arrows)
                  (_centerOf(a.fromRow, a.fromCol), _centerOf(a.toRow, a.toCol)),
              ],
              color: scheme.primary,
              cell: _cell,
            ),
          ),
        ),
    ];

    if (showIndices) {
      for (var c = 0; c < cols; c++) {
        children.add(_rulerLabel(
          context,
          scheme,
          '$c',
          left: _originX + c * _stride,
          top: 0,
          width: _cell,
          height: _ruler,
        ));
      }
      for (var r = 0; r < rows; r++) {
        children.add(_rulerLabel(
          context,
          scheme,
          '$r',
          left: 0,
          top: _originY + r * _stride,
          width: _ruler,
          height: _cell,
        ));
      }
    }

    for (final cell in cells) {
      children.addAll(_cellWidgets(context, scheme, cell));
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

  Widget _rulerLabel(
    BuildContext context,
    ColorScheme scheme,
    String text, {
    required double left,
    required double top,
    required double width,
    required double height,
  }) {
    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: Center(
        child: Text(
          text,
          style: AppTheme.mono(context, size: 11, color: scheme.onSurfaceVariant),
        ),
      ),
    );
  }

  /// The cell body and its tag are positioned independently rather than stacked
  /// in a flex: the tag lane is a fixed strip, and a tag that renders slightly
  /// taller than the strip must not overflow the row.
  Iterable<Widget> _cellWidgets(
    BuildContext context,
    ColorScheme scheme,
    GridCellSpec cell,
  ) sync* {
    final c = cell.tint != null
        ? vizIdentityColors(scheme, cell.tint!)
        : vizStateColors(scheme, cell.state);
    final emphatic =
        cell.state == VizState.processing || cell.state == VizState.found;
    final filled = cell.value != null;
    final left = _originX + cell.col * _stride;
    final top = _originY + cell.row * _stride;

    yield Positioned(
      left: left,
      top: top,
      width: _cell,
      height: _cell,
      child: AnimatedContainer(
        duration: VizTokens.moveDuration,
        curve: VizTokens.spring,
        decoration: BoxDecoration(
          color: c.fill,
          borderRadius: BorderRadius.circular(VizTokens.radius - 2),
          border: Border.all(color: c.border, width: emphatic ? 2.4 : 1.3),
          boxShadow: [
            if (emphatic)
              BoxShadow(
                color: c.border.withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
          ],
        ),
        child: Stack(
          children: [
            if (cell.corner != null)
              Positioned(
                left: 5,
                top: 3,
                child: Text(
                  cell.corner!,
                  style: AppTheme.mono(
                    context,
                    size: 9,
                    color: c.foreground.withValues(alpha: 0.65),
                  ),
                ),
              ),
            Center(
              child: AnimatedSwitcher(
                duration: VizTokens.pulseDuration,
                child: Text(
                  cell.value ?? '·',
                  key: ValueKey(cell.value),
                  style: AppTheme.mono(
                    context,
                    size: filled ? 18 : 16,
                    color: filled
                        ? c.foreground
                        : c.foreground.withValues(alpha: 0.35),
                  ).copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (cell.tag != null) {
      yield Positioned(
        left: left,
        top: top + _cell,
        width: _cell,
        height: _tagLane,
        child: Center(
          child: Text(
            cell.tag!,
            maxLines: 1,
            style: AppTheme.mono(
              context,
              size: 9,
              color: scheme.onSurfaceVariant,
            ).copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      );
    }
  }
}

class _ArrowPainter extends CustomPainter {
  final List<(Offset, Offset)> arrows;
  final Color color;
  final double cell;

  _ArrowPainter({required this.arrows, required this.color, required this.cell});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    for (final (from, to) in arrows) {
      final dir = to - from;
      final len = dir.distance;
      if (len < 1) continue;
      final u = dir / len;
      // Stop short of both cell edges so the arrow sits in the gutter.
      final a = from + u * (cell * 0.42);
      final b = to - u * (cell * 0.48);
      canvas.drawLine(a, b, paint);
      final n = Offset(-u.dy, u.dx);
      const head = 7.0;
      canvas.drawPath(
        Path()
          ..moveTo(b.dx, b.dy)
          ..lineTo((b - u * head + n * head * 0.6).dx,
              (b - u * head + n * head * 0.6).dy)
          ..lineTo((b - u * head - n * head * 0.6).dx,
              (b - u * head - n * head * 0.6).dy)
          ..close(),
        Paint()..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(_ArrowPainter old) =>
      old.arrows != arrows || old.color != color || old.cell != cell;
}
