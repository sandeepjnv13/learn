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

Monospace text: `AppTheme.mono(context, size: 13, color: ...)` from
`lib/theme/app_theme.dart`.

## Layout — `VizScaffold`

The full-page shell. Desktop = info column (left) | stage (right), height-bounded so
only the log scrolls; narrow stacks. Fills the viewport automatically in focus mode.

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

## Controls — `ControlBar`

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

## Pseudocode — `PseudocodePanel`

```dart
PseudocodePanel({
  required List<String> lines,   // the const <algo>Pseudocode
  required int? currentLine,     // 1-based; highlights + animates
  String title = 'Pseudocode',
})
```

## Variables — `VariablesPanel` / `VizVar`

Each var is a `PulseChip` that flashes when `changed` flips or the value changes.

```dart
VizVar(String name, String value, {bool changed = false})
VariablesPanel({ required List<VizVar> vars, String title = 'Variables' })
```

## Comparison — `ComparisonBadge`

```dart
ComparisonBadge({ required String? text })  // null → empty spacer; animates on change
```

## Progress — `StepProgress`

```dart
StepProgress({
  required int step,      // 0-based (pass _index)
  required int total,     // _steps.length
  String? caption,        // e.g. 'search space: 3'
})
```

## Event log — `EventLog`

```dart
EventLog({
  required List<String> entries,  // oldest→newest, up to & incl. current step
  String title = 'Event log',
  double height = 180,
  bool expand = false,            // true when used as VizScaffold.logPanel
})
```
Typical: `EventLog(entries: [for (var i = 0; i <= _index; i++) _steps[i].log], expand: true)`.

## Result — `ResultBanner` / `ResultKind`

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

## Panel (card shell) — for building new primitives/panels

```dart
Panel({
  String? title, IconData? icon, Widget? trailing,
  EdgeInsetsGeometry padding = const EdgeInsets.all(16),
  bool fill = false,        // content flexes to bounded parent height
  required Widget child,
})
```

## Fit-to-width — `FitToWidth`

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
`ArrayCells`, `LinkedListView`, and `TreeCanvas` already use it internally, so
callers just drop the primitive into the stage — it self-fits.

## Structure primitives — `ArrayCells` / `LinkedListView` / `TreeCanvas`

The built-in structure visuals. Reuse `ArrayCells` for anything array/pointer-shaped;
`LinkedListView` for singly-linked lists; `TreeCanvas` for binary trees / BSTs.

```dart
ArrayPointer(String label, int index, {Color? color})   // glides to its cell; off-range hides

ArrayCells({
  required List<num> values,
  Map<int, VizState> states = const {},   // per-index color; missing → inactive
  List<ArrayPointer> pointers = const [], // lane of labeled markers above the cells
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
emphasis. All three **self-fit** via `FitToWidth` — a long input shrinks to fit the
width rather than scrolling. **Build a new primitive** (see SKILL.md) for graphs,
stacks/queues, and grids, following the same tokens + `states` + pointer/tag + fit
conventions.

## Coordinate board — `CoordinateBoard` / `BoardItem`

Structure primitive for **coordinate-grouping** problems — vertical order
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

## Recursion kit — `CallStackPanel` / `RecursionPhaseChip`

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
// the big DESCEND / BASE / COMBINE / RETURN cue — the thing that makes recursion legible.
```
A recursion recorder emits one step per pseudocode line as usual, and each step
additionally carries a `List<RecursionFrame>` snapshot + a `RecursionPhase`; the view
drops them into `CallStackPanel` / `RecursionPhaseChip`. See `renderers/lca/` for the
reference instance (LeetCode 236).
