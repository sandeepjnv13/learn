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

## Structure primitive — `ArrayCells` / `ArrayPointer`

The one built-in structure visual. Reuse for anything array/pointer-shaped.

```dart
ArrayPointer(String label, int index, {Color? color})   // glides to its cell; off-range hides

ArrayCells({
  required List<num> values,
  Map<int, VizState> states = const {},   // per-index color; missing → inactive
  List<ArrayPointer> pointers = const [], // lane of labeled markers above the cells
})
```
Cells animate color/scale with the spring curve; `processing`/`found` get emphasis.
Scrolls horizontally when the array is wide. **Build a new primitive** (see SKILL.md)
for trees, graphs, linked lists, stacks/queues, and grids, following the same
tokens + `states` + pointer conventions.
