# Component API reference

Exact signatures of the reusable visualizer kit. Barrel import gives you
everything:

```dart
import '../../components/components.dart';
```

Design tokens & semantic colors live in `viz_tokens.dart` (re-exported):
`VizTokens.spring` (`Cubic(0.34,1.56,0.64,1.0)`), `VizTokens.moveDuration` (420ms),
`VizTokens.pulseDuration` (260ms), `VizTokens.radius` (12), `VizTokens.panelGap`
(16); `enum VizState { inactive, inScope, processing, discarded, found, notFound }`;
`VizStateColors vizStateColors(ColorScheme, VizState)` → `.fill/.border/.foreground`;
`String vizStateLabel(VizState)`.

**Identity tints** - `VizStateColors vizIdentityColors(ColorScheme, int index)`
(cycles every `vizIdentityCount` = 6). Use when you need to say *"these are the
same thing"* (the same subproblem recurring across a recursion tree, the same key
in several buckets) rather than *"this cell means X right now"* - that's
`VizState`'s job. Key `index` off a stable identity so every visual on the page
agrees on which color means what. `GridBoard` and `RecursionTree` both accept a
`tint` that overrides the semantic fill with these.

Monospace text: `AppTheme.mono(context, size: 13, color: ...)` from
`lib/theme/app_theme.dart`.

**Motion.** These tokens are also the *only* motion vocabulary - animate with the
`Animated*` widgets on `VizTokens.spring` + `moveDuration` (boxes/nodes/pointers)
and the pulse pattern on `pulseDuration` (value/state changes). For monotonic
*scalar* interpolation, spring overshoot is wrong - use a plain `easeInOutCubic`
(add a shared `double easeInOutCubic(double t)` to `viz_tokens.dart` if absent).
See **SKILL.md → "Motion & animation craft"** for the choreography principles,
tasteful event accents, and the optional pointer-trail/ghosting technique before
adding motion to a primitive.

## Approach glance card - `ApproachCard` (`type: approach`)

A **static, non-interactive "glance card"** that heads every problem page: the
one-look answer to *"how is this solved?"*. It is **not** a stepper - no controls,
no editable input, no focus/fit chrome (it's registered as a *static* viz, so
`VizLauncher` renders it plainly inline). It shows the **technique name**, a small
**schematic** (a hand-drawn hint keyed by `pattern`), a few **mechanic bullets**, an
optional **gotcha**, and the **complexity**.

Author it as the **first** `viz` block on the page:

```yaml
type: approach
technique: Monotonic decreasing stack   # the headline
pattern: monotonic-stack                # selects the schematic (see list below)
idea: Keep indices whose answer is unknown, values decreasing bottom→top.
bullets:                                # 2–4 short "moves that make it work"
  - Pop every top smaller than the current value - it just found its answer
  - Push the current index; leftovers at the end resolve to -1
gotcha: Use a strict `<` so equal values don't resolve each other.
complexity: O(n) time · O(n) space
```

**Schematic `pattern` keys** (each draws a themed vector hint; unknown → a plain
labelled box):

| pattern | draws | use for |
|---|---|---|
| `monotonic-stack` | decreasing staircase + incoming taller bar popping it | next-greater-element, stock span, largest rectangle |
| `stack` | vertical LIFO cells with push/pop + top marker | balanced parentheses, DFS-with-stack |
| `binary-search` | sorted row with lo/mid/hi, one half discarded | binary search & variants |
| `two-pointer` | row with lo → ← hi converging | sorted two-sum, palindrome, container |
| `fast-slow` | linked list with slow(+1)/fast(+2) markers | middle/cycle of a linked list |
| `post-order` | small tree with return-up arrows, meeting node lit | LCA, tree aggregation |
| `coordinate` | sparse grid, dots at (col,row), active column band | vertical order, group-by-coordinate |
| `interval` | number line, grey intervals + one growing merged bar | insert/merge intervals |
| `adjacent-swap` | bars with two adjacent highlighted + swap arc | bubble sort, adjacent-compare passes |
| `running-sum` | zigzag sum crossing a dashed target line, hit markers where it resets | partition-by-sum, subarray-sum-equals-target |
| `gas-station` | gas / cost cell rows + a runningGas baseline plot (signed bars); the below-zero bar is flagged and the next station marked `start` | gas station, reset-start-on-deficit greedy |
| `overlapping-subproblems` | small recursion tree with the same call appearing twice (amber), the second marked `cached` | memoization, DP intros, overlapping subproblems |

Need a structure with no matching schematic? Add a new `case` to
`_SchematicPainter` in `lib/viz/components/approach_card.dart` (theme-aware, drawn
from the same `ColorScheme` + semantic hues as the rest of the kit), then list it in
the table above. Keep each schematic a **small static hint**, not a full diagram -
it points at the idea, the interactive viz below does the walking-through.

> **Schematic label placement - avoid text overlap.** A schematic caption's origin
> and `align` are its *anchor*, and the card lays out at only ~288px of drawable
> width in desktop row mode (the `SizedBox(width: 320)` minus padding). So two
> captions anchored to the **same edge or point will collide** at that width even
> if they look fine wider. Rules when adding/placing `_text` captions:
> - Give the schematic **at most one caption per band** - top-left title, top-right
>   mechanic, bottom-center summary. Never put two labels in the same band.
> - **Never anchor a second label at `r.center.dx`** if a corner label shares that
>   band - a center-anchored `TextAlign.right`/`left` string extends *toward* the
>   corner and overruns it. Pin the second label to the opposite edge (`r.right`
>   with `align: TextAlign.right`, or `r.left` with `align: TextAlign.left`).
> - Keep captions ≤ ~24 chars; the amber mechanic line and the muted title must not
>   each exceed roughly half the width or they meet in the middle.
> - After adding a schematic, eyeball it at the **narrow (≤620px, stacked) and the
>   desktop row (320px card) widths** - the row width is the tight case.

```dart
ApproachCard({
  required String technique,   // headline
  required String pattern,     // schematic key
  String? idea,                // one-line gist
  List<String> bullets = const [],  // 2–4 mechanic lines
  String? gotcha,              // one highlighted watch-out
  String? complexity,          // e.g. 'O(n) time · O(n) space'
})
```

## Layout - `VizScaffold`

The full-page shell. Desktop = info column (left) | stage (right), height-bounded so
only the log scrolls; narrow stacks. Fills the viewport automatically in focus mode.
A stage taller than its bounded height (a deep tree, a many-row grid, a short
window) scrolls internally rather than overflowing; one that fits still fills and
centers exactly as before - so a stage needs no scroll handling of its own.

```dart
VizScaffold({
  required String title,
  String? subtitle,
  required Widget controlBar,   // usually a ControlBar
  required Widget stage,        // the structure primitive + badge/progress/legend/result
  required List<Widget> panels, // fixed-height left-column panels (pseudocode, variables)
  Widget? logPanel,             // fills remaining left-column height; use EventLog(expand: true)
  double infoWidth = 380,
  double breakpoint = 820,
})
```

## Controls - `ControlBar`

Owns no state; you pass flags + callbacks. Renders Step-back / Auto(Pause/Replay) /
Step-forward / Reset, with an optional leading `input` slot.

```dart
ControlBar({
  required bool playing,
  required bool atStart,
  required bool atEnd,
  required VoidCallback onReset,
  required VoidCallback? onStepBack,     // null disables
  required VoidCallback? onStepForward,  // null disables
  required VoidCallback onTogglePlay,
  Widget? input,                         // e.g. a Row of TextFields + apply button
})
```

## Preset examples - `PresetPicker` / `VizPreset`

A dropdown of **preset example inputs**, placed in the `ControlBar.input` slot
next to the editable fields. **Every step-by-step visualizer with editable input
must offer one** - 3–4 presets that span the algorithm's shapes, *plus* the
frequently-missed edge cases (mark those `edgeCase: true`). Selecting a preset
loads it (the view writes its input controllers, then calls its `_rebuild`);
editing the loaded values is still allowed.

```dart
VizPreset(String label, {String? detail, bool edgeCase = false})
// label: short menu title; detail: one line on why it's interesting;
// edgeCase: badges it as a frequently-missed case.

PresetPicker({
  required List<VizPreset> presets,
  required void Function(int index) onSelected,  // load presets[index]
  String label = 'Examples',
})
```

**Wiring pattern** (keep the label and its payload together so they can't drift):

```dart
static const List<(VizPreset, List<num>)> _presets = [
  (VizPreset('Mixed', detail: 'some resolve, some wait'), [2, 1, 2, 4, 3]),
  (VizPreset('Strictly decreasing',
      detail: 'nothing resolves until the end', edgeCase: true), [5, 4, 3, 2, 1]),
  (VizPreset('All equal',
      detail: 'equal is NOT greater - all −1', edgeCase: true), [3, 3, 3, 3]),
  (VizPreset('Single element', detail: 'no successor', edgeCase: true), [7]),
];

void _loadPreset(int i) {
  _arrayCtrl.text = _presets[i].$2.join(', ');
  _rebuild();               // re-parse fields + regenerate steps + reset index
}

// in _inputs(): PresetPicker(presets: [for (final p in _presets) p.$1],
//                            onSelected: _loadPreset) then the TextField(s).
```
For **in-canvas** builders (trees: `lca`, `vertical_order`) there are no text
fields - the preset carries a level-order list (+ any p/q), and `_loadPreset`
reseeds the tree, rebuilds steps, and drops back into run mode. See
`renderers/lca/` and `renderers/vertical_order/` for that variant.

## Pseudocode - `PseudocodePanel`

```dart
PseudocodePanel({
  required List<String> lines,   // the const <algo>Pseudocode
  required int? currentLine,     // 1-based; highlights + animates
  String title = 'Pseudocode',
})
```

## Variables - `VariablesPanel` / `VizVar`

Each var is a `PulseChip` that flashes when `changed` flips or the value changes.

```dart
VizVar(String name, String value, {bool changed = false})
VariablesPanel({ required List<VizVar> vars, String title = 'Variables' })
```

## Comparison - `ComparisonBadge`

```dart
ComparisonBadge({ required String? text })  // null → empty spacer; animates on change
```

## Progress - `StepProgress`

```dart
StepProgress({
  required int step,      // 0-based (pass _index)
  required int total,     // _steps.length
  String? caption,        // e.g. 'search space: 3'
})
```

## Event log - `EventLog`

```dart
EventLog({
  required List<String> entries,  // oldest→newest, up to & incl. current step
  String title = 'Event log',
  double height = 180,
  bool expand = false,            // true when used as VizScaffold.logPanel
})
```
Typical: `EventLog(entries: [for (var i = 0; i <= _index; i++) _steps[i].log], expand: true)`.

## Result - `ResultBanner` / `ResultKind`

```dart
ResultBanner({ required ResultKind? kind, required String? message })
// ResultKind { success, failure }; null kind/message collapses the banner.
```

## Legend

```dart
Legend({
  required List<VizState> states,
  Map<VizState, String> labels = const {},  // override a state's label
})
```

## Panel (card shell) - for building new primitives/panels

```dart
Panel({
  String? title, IconData? icon, Widget? trailing,
  EdgeInsetsGeometry padding = const EdgeInsets.all(16),
  bool fill = false,        // content flexes to bounded parent height
  required Widget child,
})
```

## Fit-to-width - `FitToWidth`

Wrap any **fixed-size element visual** so it shrinks to fit the available width
instead of overflowing into a horizontal scroll when there are many inputs. Scales
down only when needed (never enlarges past 1:1), centers when it fits, and reserves
the scaled height. Every structure primitive must use this for its elements; do
**not** wrap a primitive or a stage in a horizontal `SingleChildScrollView`.

```dart
FitToWidth({
  required double naturalWidth,   // intrinsic width at 1:1 (element stride × count)
  required double naturalHeight,  // intrinsic height at 1:1
  required Widget child,          // the fixed-size element visual (wrap it in a SizedBox is not needed)
  Alignment alignment = Alignment.center,
})
```
Every structure primitive (`ArrayCells`, `LinkedListView`, `TreeCanvas`,
`CoordinateBoard`, `StackView`, `GridBoard`, `RecursionTree`) already uses it
internally, so callers just drop the primitive into the stage - it self-fits.

## Structure primitives - `ArrayCells` / `BaselineBarPlot` / `LinkedListView` / `TreeCanvas`

The built-in structure visuals. Reuse `ArrayCells` for anything array/pointer-shaped;
`BaselineBarPlot` for a signed running-total plotted around a zero baseline;
`LinkedListView` for singly-linked lists; `TreeCanvas` for binary trees / BSTs.

```dart
ArrayPointer(String label, int index, {Color? color})   // glides to its cell; off-range hides

ArrayCells({
  required List<num> values,
  Map<int, VizState> states = const {},   // per-index color; missing → inactive
  List<ArrayPointer> pointers = const [], // lane of labeled markers above the cells
  bool showIndices = true,                // off → share one index axis when stacking rows
})

// Signed bars around a dashed zero line: positive rise, negative drop, colored
// by state. Same 56px column stride as ArrayCells, so stack it under gas/cost
// rows and the columns line up. Good for runningGas / prefix-balance plots.
BaselineBarPlot({
  required List<num> values,
  Map<int, VizState> states = const {},   // per-index color; missing → inactive
  double height = 168,
})

LinkedNodePointer(String label, int index, {Color? color}) // index == length parks on the null sentinel

LinkedListView({
  required List<num> values,
  Map<int, VizState> states = const {},
  List<LinkedNodePointer> pointers = const [],
  Set<int> removed = const {},            // unlinked nodes: pop out + healed bypass arc
})

// Binary tree / BST. Nodes referenced by stable `id` (survives duplicate values).
TreeNodeSpec({ required int id, required num value, int? left, int? right })

TreeCanvas({
  required List<TreeNodeSpec> nodes,
  required int? rootId,
  Map<int, VizState> states = const {},   // per-node color; missing → inactive
  Map<int, String> tags = const {},       // identity pill ABOVE a node (e.g. 'p','q')
  Map<int, String> returnTags = const {}, // label BELOW a node (e.g. '→ 6', '→ ∅')
  Set<int> spine = const {},              // node ids on the active path → edges emphasized
  // In-canvas building affordances (edit mode); mutation logic stays in the view:
  bool editable = false,
  void Function(int parentId, bool left)? onAddChild,  // '+' on empty child slots
  void Function(int id)? onDeleteNode,                 // '×' prunes a subtree
  void Function(int id)? onTapNode,                    // tap (e.g. to mark p/q)
  VoidCallback? onAddRoot,                             // 'Add root' when empty
})
```
Cells/nodes animate color/scale with the spring curve; `processing`/`found` get
emphasis. All three **self-fit** via `FitToWidth` - a long input shrinks to fit the
width rather than scrolling. Stacks, dense grids, and call trees are covered by
`StackView` / `GridBoard` / `RecursionTree` below; **build a new primitive** (see
SKILL.md) for graphs and queues, following the same tokens + `states` +
pointer/tag + fit conventions.

## Coordinate board - `CoordinateBoard` / `BoardItem`

Structure primitive for **coordinate-grouping** problems - vertical order
traversal (LeetCode 987), group-by-column/diagonal, bucket-by-key. Places each
item at its integer `(col, row)`: columns left→right by column value, rows
top→bottom by row value, items sharing a cell laid side by side sorted by value.
Self-fits via `FitToWidth`; a highlight band marks the active column.

```dart
BoardItem({ required int id, required num value, required int col, required int row,
            VizState state = VizState.inactive })

CoordinateBoard({
  required List<BoardItem> items,
  int? activeColumn,   // paints a highlight band behind this column value
})
```
Dumb stateless render (no algorithm logic); colors via `vizStateColors`, motion
via `VizTokens`. See `renderers/vertical_order/` for the reference instance.

## Stack - `StackView`

Structure primitive for **any LIFO stack** problem (balanced parentheses,
monotonic stack / next-greater-element, DFS-with-explicit-stack, stock span).
Always **horizontal**: elements are given **bottom → top** (index 0 = bottom at
the left, last = top at the right). The single **top** slot - where both a push
and a pop happen - is marked with a subtle accent band + a "top · push/pop" tag.

Presentation adapts to the data:
* **all-numeric** values render as **normalised bars** (height ∝ value, capped so
  the stack never grows tall) - the increasing/decreasing shape is visible at a
  glance;
* anything else (short strings, e.g. bracket chars) renders as labelled **cells**.

```dart
StackView({
  required List<Object> values,          // bottom → top; numbers → bars, else cells
  Map<int, VizState> states = const {},  // per-element color; missing → inScope
  String topLabel = 'top',               // text in the top (push/pop) tag
  Map<int, String> captions = const {},  // small caption per element (e.g. '#3')
  String emptyLabel = 'empty stack',     // placeholder when values is empty
  num? barMax,                           // stable bar-height reference (pass the
                                         // whole input's max so heights don't jump)
  bool compact = false,                  // bar mode: tighten spacing so a long
                                         // monotonic stack reads as one silhouette
  bool connectTops = false,              // bar mode: draw a polyline + dots through
                                         // the bar tops - the "graph on top of the
                                         // bars" that makes the monotonic shape clear
})
```
For **monotonic-stack** problems (next-greater-element, stock span, largest
rectangle) pass `compact: true, connectTops: true`: the tight bars plus the trend
line make the strictly increasing/decreasing invariant obvious at a glance. Keep
captions short (e.g. `'#3'`, not `'idx 3'`) so they fit the compact column.
Dumb stateless render (no algorithm logic); colors via `vizStateColors`, motion +
the gliding top tag/band via `VizTokens`. Self-fits via `FitToWidth`. See
`renderers/valid_parentheses/` (cells) and `renderers/next_greater_element/`
(bars) for reference instances.

## Dense grid - `GridBoard` / `GridCellSpec` / `GridArrow`

Structure primitive for a **dense 2-D matrix** addressed by `(row, col)` - grid
DP (min path sum, edit distance, unique paths), flood fill, matrix walks. Every
slot in a `rows × cols` rectangle is drawn; contrast [`CoordinateBoard`], which
scatters sparse items at coordinates.

`corner` is the small muted label in a cell's top-left - typically the *input*
the dp is derived from (`grid[i][j]`), so `dp[i][j]` and its cost read at once.
`arrows` draw the "where did this answer come from" cue between cell centers.

```dart
GridCellSpec({ required int row, required int col,
               String? value,      // big label; null → unfilled '·'
               String? corner,     // small top-left label (the input cost)
               VizState state = VizState.inactive,
               String? tag,        // small pill under the cell ('start', 'end')
               int? tint })        // identity tint; overrides the state fill

GridArrow(int fromRow, int fromCol, int toRow, int toCol)

GridBoard({
  required int rows,
  required int cols,
  required List<GridCellSpec> cells,
  List<GridArrow> arrows = const [],
  bool showIndices = true,   // i/j rulers on the top and left edges
  double cellSize = 62,      // shrink when the grid is a secondary visual
})
```
Dumb stateless render; colors via `vizStateColors`/`vizIdentityColors`, motion via
`VizTokens`. Self-fits via `FitToWidth`. See `renderers/min_path_dp/` for the
reference instance.

## Recursion / call tree - `RecursionTree` / `CallNodeSpec`

Structure primitive for an **n-ary call tree**: the picture of what a recursion
actually does - overlapping subproblems, call expansion, memoization collapse.
This is the *call* tree (nodes are calls labelled by signature, any arity);
`TreeCanvas` is for a binary tree of *data*.

Layout is a leaf sweep - leaves take successive x slots, parents center over
their children - so subtrees occupy disjoint x ranges and nodes never overlap.

A `cacheHit` node renders as a faded, dashed, childless stub that keeps its
`tint`: you still see *which* subproblem it was, while it reads as inert. That
plus `tint` is what makes "the same call, over and over" visible at a glance.

```dart
CallNodeSpec({ required int id,
               required String label,        // the signature, e.g. '(2,2)'
               List<int> children = const [], // in call order
               int? tint,                    // identity tint - color-match repeats
               String? returns,              // label under the node ('→ 7')
               bool cacheHit = false,        // faded dashed stub, no subtree
               String? badge,                // small pill above ('×6')
               VizState state = VizState.inactive })

RecursionTree({ required List<CallNodeSpec> nodes, required int? rootId })
```
Dumb stateless render; self-fits via `FitToWidth`. See
`renderers/overlapping_subproblems/` for the reference instance - note its model
(`overlap_model.dart`) is Flutter-free and *derives* every count it quotes rather
than hardcoding them.

## Recursion kit - `CallStackPanel` / `RecursionPhaseChip`

Data-structure-agnostic panels for **any recursive algorithm** (tree/graph DFS,
backtracking, divide-and-conquer, DP-on-recursion). Compose these instead of
hand-rolling a stack view. The model lives in the Flutter-free `recursion_model.dart`
so a pure recorder can build frame snapshots directly and the view just forwards them.

```dart
enum RecursionPhase { descend, base, combine, returnUp } // shared phase vocabulary

FrameLocal(String name, String value, {bool resolved = true}) // pending → faded '…'

RecursionFrame({
  required String signature,        // e.g. 'lca(5)'
  List<FrameLocal> locals = const [],
  String? returns,                  // shown once the frame returns
  bool active = false,              // top-of-stack (currently executing)
  bool returning = false,           // the pop step (card turns green)
  int? refId,                       // link to a structure node id (for spine)
})

CallStackPanel({ required List<RecursionFrame> frames, String title = 'Call stack' })
// newest frame on top; grows/shrinks with the recursion; internal-scrolls when deep.

RecursionPhaseChip({ required RecursionPhase phase })
// the big DESCEND / BASE / COMBINE / RETURN cue - the thing that makes recursion legible.
```
A recursion recorder emits one step per pseudocode line as usual, and each step
additionally carries a `List<RecursionFrame>` snapshot + a `RecursionPhase`; the view
drops them into `CallStackPanel` / `RecursionPhaseChip`. See `renderers/lca/` for the
reference instance (LeetCode 236).
