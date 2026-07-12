---
name: algo-visualizer
description: Build a new native (Flutter) algorithm/data-structure visualizer for the `learn` app. Use when asked to "create/generate/add a visualizer" for any algorithm (sorting, searching, graph, tree, DP, linked list, stack/queue, two-pointer, etc.) — it produces a deterministic step recorder plus a view composed from the shared reusable component library, and adds a new structure primitive (tree, graph, linked list, stack…) only when a genuinely new data structure appears.
---

# Building an algorithm visualizer

You are adding a **native, full-page, step-by-step** visualizer to this Flutter-web
knowledge base. The whole point of this kit is **reuse**: every visualizer is
**composed from the shared component library** in `lib/viz/components/` — never a
bespoke per-algorithm layout. Read this whole file before writing code, then read
[`reference/components.md`](reference/components.md) for exact component APIs while
composing.

## The two non-negotiable rules

1. **Determinism via a step recorder — never a live state machine.** Run the real
   algorithm once, up front, and record **one step per pseudocode line executed**.
   Stepping the UI is then pure index movement over a precomputed list, so a click
   always advances exactly one line and can never double-fire.
2. **Compose existing components; add a primitive only for a new data structure.**
   The panels (pseudocode, variables, badge, progress, log, result, controls,
   legend) and the layout (`VizScaffold`) are shared and must be reused as-is. Only
   the **structure visual** (array / tree / graph / linked list / stack) may need
   new code — and only when the structure genuinely doesn't exist yet. Already
   built and reusable: `ArrayCells` (arrays/pointers), `LinkedListView` (singly-
   linked lists), `TreeCanvas` (binary trees / BSTs), `CoordinateBoard`
   (coordinate-grouping: items placed at `(col, row)`, e.g. vertical order
   traversal). For **recursive** algorithms
   also reuse the recursion kit — `CallStackPanel` + `RecursionPhaseChip` (see
   reference/components.md) — rather than inventing a stack view.

Focus mode (full-page lock + Exit) is **automatic** — every viz is wrapped by
`VizLauncher` and `VizScaffold` reads `VizPresentation` to fill the viewport. You
write nothing for it.

## Recipe

Work in `lib/viz/renderers/<algo>/` (snake_case, e.g. `bubble_sort/`,
`bfs/`, `reverse_linked_list/`).

### 1. Decide the structure primitive

- Array / pointers / indexed cells → **reuse `ArrayCells`** (`values`, `states`,
  `pointers`). Covers sorting, searching, two-pointer, sliding window, heaps-as-array.
- Singly-linked list → **reuse `LinkedListView`** (`values`, `states`, `pointers`,
  `removed`).
- Binary tree / BST → **reuse `TreeCanvas`** (`nodes`, `rootId`, `states`, `tags`,
  `returnTags`, `spine`; `editable` for in-canvas building).
- Recursive algorithm (any structure) → also reuse **`CallStackPanel`** +
  **`RecursionPhaseChip`** for the live call stack and descend/return cue.
- Items placed on a 2-D coordinate grid, grouped by column → **reuse
  `CoordinateBoard`** (`items` of `BoardItem(col,row,value,state)`, `activeColumn`).
- Graph, stack/queue, dense matrix/grid → **new primitive needed** (not built yet).
  Build it per "Adding a new structure primitive" below **before** writing the view.

### 2. Write the step recorder — `<algo>_algo.dart`

Mirror `renderers/binary_search/binary_search_algo.dart` exactly in shape:

- `enum <Algo>Status { running, found, done, ... }` (whatever terminal states fit).
- `const List<String> <algo>Pseudocode = [ ... ];` — the full pseudocode, one entry
  per line, indentation via leading spaces. `line` fields are **1-based** into this.
- An immutable `class <Algo>Step` with: `final int line;` the structure state for
  this step (indices, pointers, node ids, colors — whatever the primitive needs),
  `final String? badge;` (the comparison/decision just made), `final String log;`
  (plain-English trace), `final Set<String> changed;` (variable names updated this
  step, drives the pulse), `final <Algo>Status status;`.
- `List<<Algo>Step> generate<Algo>Steps(<inputs>)` — run the real algorithm and
  `steps.add(<Algo>Step(...))` **once for each pseudocode line as it executes**.
  Handle the empty/degenerate input as its own terminal step. Pure function, no
  Flutter imports.

### 3. Write the view — `<algo>_view.dart`

A `StatefulWidget` taking `final VizContext ctx`, with `static void register()`
calling `VizRegistry.register('<type>', (ctx) => <Algo>View(ctx));`. Model it on
`renderers/binary_search/binary_search_view.dart`:

- State: `late List<...> _data;`, `late List<<Algo>Step> _steps;`, `int _index = 0;`,
  `Timer? _timer;`, `TextEditingController`s for editable input.
- `initState`: parse `widget.ctx.config`, build controllers, call
  `generate<Algo>Steps(...)`.
- Playback helpers (copy the pattern): `_togglePlay` (a `Timer.periodic` ~1100ms
  that stops at the last step), `_goto(i)`, `_reset()`, `_rebuild()` (re-parse the
  input fields, regenerate steps, reset index). Always `_timer?.cancel()` in
  `dispose`.
- Derived-state helpers off the current `_step`: a `Map<int, VizState>` (or per-node
  map) for the primitive, the pointer list, `List<VizVar> _vars()` (set
  `changed: _step.changed.contains('name')`), and `_result()` → `ResultKind?` + msg.
- `build` returns a single **`VizScaffold`**:
  - `controlBar: ControlBar(playing/atStart/atEnd/callbacks, input: <your fields>)`
  - `stage:` a `Column` with the **structure primitive**, then `ComparisonBadge`,
    `StepProgress`, `Legend`, `ResultBanner`.
  - `panels: [PseudocodePanel(lines: <algo>Pseudocode, currentLine: _step.line),
    VariablesPanel(vars: _vars())]`
  - `logPanel: EventLog(entries: [for (var i=0; i<=_index; i++) _steps[i].log],
    expand: true)`

Keep semantic `VizState` colors consistent: `inScope` = active window, `processing`
= examining now, `discarded` = ruled out/visited, `found` = result, `notFound` =
failure, `inactive` = untouched.

### 4. Register — `lib/viz/init.dart`

Add `<Algo>View.register();` to `registerVisualizers()`.

### 5. Author a page + viz block

Add/extend a markdown page under `content/` with a fenced block:

    ```viz
    type: <type>
    # …algorithm-specific config the view's initState reads…
    ```

Then **run `dart run tool/gen_content.dart`** (regenerates `assets/manifest.json`
and the `pubspec.yaml` asset list).

### 6. Verify (all must pass)

```
export PATH="$PATH:/snap/bin"
flutter analyze          # clean
flutter test             # add a recorder test (see test/widget_test.dart)
flutter build web --no-tree-shake-icons   # compiles for the real target
```

Add a unit test for the recorder (deterministic, easy): assert the final step's
status/result and that stepping is monotonic — mirror the `binarySearch` test in
`test/widget_test.dart`.

## Adding a new structure primitive

Only when the data structure doesn't exist yet. Already built: `ArrayCells`,
`LinkedListView`, `TreeCanvas`, `CoordinateBoard` (plus the `CallStackPanel`
recursion kit).
Put a new one in `lib/viz/components/<name>.dart` and `export` it from
`components.dart`. Follow the `ArrayCells` conventions so the kit stays one system:

- **Semantic colors from tokens.** Never hardcode state colors — call
  `vizStateColors(scheme, state)` (fill/border/foreground) and accept a
  `Map<NodeId, VizState> states`. Respect light/dark via `Theme.of(context)`.
- **Motion from tokens.** Animate position/appearance with `VizTokens.spring` +
  `VizTokens.moveDuration` (use `AnimatedContainer` / `AnimatedPositioned` /
  `AnimatedOpacity`); use `VizTokens.radius` for corners.
- **Labels/pointers** analogous to `ArrayPointer` (a moving `current`/`i`/`j`/`head`
  marker) where the structure has a cursor.
- **Self-fitting, never side-scrolling.** When many inputs would overflow the
  width, the **elements themselves shrink to fit the page** — no horizontal
  scrollbar. Wrap the fixed-size element visual in the shared **`FitToWidth`**
  (from `components.dart`), passing its intrinsic `naturalWidth`/`naturalHeight`
  (which the primitive knows from element geometry × count). `FitToWidth` scales
  the visual down only when it doesn't fit, centers it when it does, never
  enlarges past 1:1, and reserves the scaled height. Do **not** wrap the
  primitive (or the view's stage) in a horizontal `SingleChildScrollView`. Only
  the data elements resize — surrounding panels, controls, and the step tracker
  are untouched. (A primitive that maps a domain onto the full width instead,
  like `IntervalTrack`, is already fitting and needs no `FitToWidth`.)
- Keep it a **dumb, stateless render** of the step's data — no algorithm logic
  inside the primitive.

Primitives still to build as they come up: `GraphCanvas` (nodes + edges,
directed/weighted — can reuse the recursion kit for DFS), `StackView`/`QueueView`
(vertical / horizontal cell stack with a top/front marker), `Grid` (dense 2-D
matrix cells for DP / flood-fill — distinct from the sparse `CoordinateBoard`).
(`TreeCanvas`, `LinkedListView`, and `CoordinateBoard` already exist — reuse
them; extend `TreeCanvas` for heaps.) Build the minimum the current
algorithm needs; generalize later.

## Checklist before finishing

- [ ] Step recorder is a pure function, one step per pseudocode line, terminal cases
      handled.
- [ ] View composes `VizScaffold` + shared panels; no bespoke layout.
- [ ] New primitive (if any) exported from `components.dart`, uses tokens + semantic
      colors, animates with the spring curve.
- [ ] Registered in `init.dart`; content page has a `type:` block;
      `gen_content.dart` re-run.
- [ ] `flutter analyze` clean, `flutter test` green (incl. a new recorder test),
      `flutter build web` succeeds.
