---
name: algo-visualizer
description: Build a new native (Flutter) algorithm/data-structure visualizer for the `learn` app. Use when asked to "create/generate/add a visualizer" for any algorithm (sorting, searching, graph, tree, DP, linked list, stack/queue, two-pointer, etc.) - it produces a deterministic step recorder plus a view composed from the shared reusable component library, and adds a new structure primitive (tree, graph, linked list, stack…) only when a genuinely new data structure appears.
---

# Building an algorithm visualizer

You are adding a **native, full-page, step-by-step** visualizer to this Flutter-web
knowledge base. The whole point of this kit is **reuse**: every visualizer is
**composed from the shared component library** in `lib/viz/components/` - never a
bespoke per-algorithm layout. Read this whole file before writing code, then read
[`reference/components.md`](reference/components.md) for exact component APIs while
composing.

## The two non-negotiable rules

1. **Determinism via a step recorder - never a live state machine.** Run the real
   algorithm once, up front, and record **one step per pseudocode line executed**.
   Stepping the UI is then pure index movement over a precomputed list, so a click
   always advances exactly one line and can never double-fire.
2. **Compose existing components; add a primitive only for a new data structure.**
   The panels (pseudocode, variables, badge, progress, log, result, controls,
   legend, **preset picker**), the page-top **`ApproachCard` glance card**
   (`type: approach`), and the layout (`VizScaffold`) are shared and must
   be reused as-is. Only
   the **structure visual** (array / tree / graph / linked list / stack) may need
   new code - and only when the structure genuinely doesn't exist yet. Already
   built and reusable: `ArrayCells` (arrays/pointers), `BaselineBarPlot` (signed
   running-total bars around a zero baseline, e.g. gas-station runningGas),
   `LinkedListView` (singly-linked lists), `TreeCanvas` (binary trees / BSTs),
   `CoordinateBoard` (coordinate-grouping: items placed at `(col, row)`, e.g.
   vertical order traversal), `StackView` (LIFO stacks), `GridBoard` (dense 2-D
   matrix, e.g. grid DP / flood fill), `RecursionTree` (n-ary call tree, e.g.
   overlapping subproblems). For **recursive** algorithms
   also reuse the recursion kit - `CallStackPanel` + `RecursionPhaseChip` (see
   reference/components.md) - rather than inventing a stack view.

Focus mode (full-page lock + Exit) is **automatic** - every viz is wrapped by
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
- LIFO stack (parentheses, monotonic stack / next-greater-element, DFS-with-stack)
  → **reuse `StackView`** (horizontal; `values` bottom→top render as bars when
  numeric else cells; `states`, `captions`, `topLabel`, `barMax`; the top
  push/pop slot is auto-marked).
- Dense 2-D matrix / grid DP (min path sum, edit distance, unique paths, flood
  fill) → **reuse `GridBoard`** (`rows`, `cols`, `cells` of `GridCellSpec(row,
  col, value, corner, state, tag, tint)`, `arrows` of `GridArrow` for "where
  this answer came from", `cellSize`).
- Recursion / call tree (overlapping subproblems, call expansion, memoization
  collapse) → **reuse `RecursionTree`** (`nodes` of `CallNodeSpec(id, label,
  children, tint, returns, cacheHit, badge)`, `rootId`). Note this is the *call*
  tree; `TreeCanvas` is for a binary tree of *data*.
- Graph or queue → **new primitive needed** (not built yet).
  Build it per "Adding a new structure primitive" below **before** writing the view.

### 2. Write the step recorder - `<algo>_algo.dart`

Mirror `renderers/binary_search/binary_search_algo.dart` exactly in shape:

- `enum <Algo>Status { running, found, done, ... }` (whatever terminal states fit).
- `const List<String> <algo>Pseudocode = [ ... ];` - the full pseudocode, one entry
  per line, indentation via leading spaces. `line` fields are **1-based** into this.
- An immutable `class <Algo>Step` with: `final int line;` the structure state for
  this step (indices, pointers, node ids, colors - whatever the primitive needs),
  `final String? badge;` (the comparison/decision just made), `final String log;`
  (plain-English trace), `final Set<String> changed;` (variable names updated this
  step, drives the pulse), `final <Algo>Status status;`.
- `List<<Algo>Step> generate<Algo>Steps(<inputs>)` - run the real algorithm and
  `steps.add(<Algo>Step(...))` **once for each pseudocode line as it executes**.
  Handle the empty/degenerate input as its own terminal step. Pure function, no
  Flutter imports.

### 3. Write the view - `<algo>_view.dart`

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
- **Preset examples (required).** Every visualizer with editable input MUST
  offer a `PresetPicker` in the `ControlBar.input` slot, *before* the edit
  fields - 3–4 presets that span the algorithm's behaviours **plus the
  frequently-missed edge cases** (empty/single input, boundaries, strict-vs-equal,
  ties, degenerate/skewed shapes), marked `edgeCase: true`. Store each preset's
  `VizPreset` label next to its payload in one `static const` list so they can't
  drift, and have `_loadPreset(i)` write the input controllers then call
  `_rebuild()` (or, for in-canvas tree builders, reseed + rebuild). See
  reference/components.md → "Preset examples".
- `build` returns a single **`VizScaffold`**:
  - `controlBar: ControlBar(playing/atStart/atEnd/callbacks, input: <presets + your fields>)`
  - `stage:` a `Column` with the **structure primitive**, then `ComparisonBadge`,
    `StepProgress`, `Legend`, `ResultBanner`.
  - `panels: [PseudocodePanel(lines: <algo>Pseudocode, currentLine: _step.line),
    VariablesPanel(vars: _vars())]`
  - `logPanel: EventLog(entries: [for (var i=0; i<=_index; i++) _steps[i].log],
    expand: true)`

Keep semantic `VizState` colors consistent: `inScope` = active window, `processing`
= examining now, `discarded` = ruled out/visited, `found` = result, `notFound` =
failure, `inactive` = untouched.

### 4. Register - `lib/viz/init.dart`

Add `<Algo>View.register();` to `registerVisualizers()`.

### 5. Author a page + viz block

Every problem page has the **same tight shape** - a glance card, direct prose, then
the interactive viz. Keep it lean: *the trick, then the gotchas, nothing more.*

**Title - LeetCode number first.** If the problem is a LeetCode problem, prefix its
number LeetCode-native style in **both** the frontmatter `title` and the page `#`
heading: `title: Valid Parentheses` → `title: 20. Valid Parentheses`, and
`# 20. Valid Parentheses`. Skip the number only for generic technique pages with no
single LeetCode id (e.g. "Two Pointer").

**Glance card first (required).** Before any prose, add a static `type: approach`
**glance card** - the non-interactive "how is this solved?" summary a learner can
read in one look (technique name + a schematic hint + a couple of mechanic bullets +
complexity). Pick the schematic `pattern` that matches the structure (see
reference/components.md → "Approach glance card" for the list and YAML). It renders
inline with no stepper/focus chrome.

**Prose - direct, then the interactive viz.** After the card, write only: a
one-line problem statement, *how the trick solves it*, and the **edge cases /
gotchas**. Cut narration ("Watch it run", "Try this preset") - the card and the
interactive viz already carry the walkthrough. Keep pseudocode/code (it *is* how the
problem is solved). Then the interactive `type: <algo>` block.

    ```viz
    type: approach
    technique: <the named technique>
    pattern: <schematic key>
    idea: <one-line gist>
    bullets:
      - <mechanic 1>
      - <mechanic 2>
    gotcha: <the single most-missed pitfall>
    complexity: O(n) time · O(n) space
    ```

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
status/result and that stepping is monotonic - mirror the `binarySearch` test in
`test/widget_test.dart`.

## Motion & animation craft

The recorder decides *what* each step shows; this section is about *how the change
moves*. In a step-by-step visualizer the **transition between two steps is the
teaching moment** - the learner understands the algorithm by watching state move,
not by reading two static frames. Treat that motion as a first-class, meticulously
tuned part of the work, not an afterthought. (Distilled from Anthropic's
`algorithmic-art` skill - its *process-over-product* and craftsmanship ethos - but
adapted to a **deterministic, educational, theme-consistent** tool: we keep the
motion craft and reject the generative side. **No RNG, no seeded variation, no
particle systems, no flow fields** - every frame is still a pure function of the
recorded step, and theme + layout stay exactly as they are.)

Everything below reuses the **existing** design tokens (`VizTokens.spring`,
`moveDuration`, `pulseDuration`, `radius`) and **semantic** `VizState` colors - it
adds motion quality, never new theme surface.

### Principles

- **Choreograph the change, don't snap it.** When a pointer advances, a cell
  recolors, or a value moves, animate it as a *movement*: `AnimatedPositioned` /
  `AnimatedContainer` / `AnimatedOpacity` on `VizTokens.spring` + `moveDuration`.
  A step should read as "this thing moved *here* and *this* is why," never as an
  instant redraw. This is the one rule that most raises perceived quality.
- **One idea in motion per step.** A step maps to one pseudocode line, so it should
  have one dominant movement (the thing that line did). Let secondary state settle
  quietly (shorter/subtler) so the eye is led, not scattered. Order-of-motion *is*
  composition - the art skill's "visual hierarchy even in randomness," applied to
  a single deterministic frame.
- **Semantic transitions.** Color changes carry meaning (`inScope`→`discarded`,
  `processing`→`found`); let them ease over `moveDuration` rather than flip, so the
  learner sees the reclassification happen. Never hardcode a color - go through
  `vizStateColors`.
- **Tune, don't decorate.** Craftsmanship here means calibrating durations, easing
  and stagger until the motion feels inevitable - *not* adding ornament. If an
  effect doesn't help the learner track state, cut it.

### Techniques (apply when they help; skip when they don't)

- **Event accents - tasteful, one-shot.** On a semantic milestone (found, swap,
  discarded, base case reached) a single subtle scale-pop + glow on the affected
  element, using the existing `pulseDuration`/pulse pattern (same one `PulseChip`
  uses). It punctuates the moment. **Guardrail:** one accent per milestone, no
  bursts, no confetti/particles - this is a study tool, restraint reads as quality.
- **Motion trails / ghosting - OPTIONAL, only when it genuinely aids tracking.**
  Borrowed from the art skill's fading-trail idea: when a marker *jumps a distance*
  (e.g. binary-search `mid` leaping across the array, a two-pointer skip), leave a
  brief fading ghost of its previous position(s) so the eye follows the jump.
  - Use it **only** where the jump is large enough to lose; for a pointer that
    moves one cell at a time it's noise - don't add it there.
  - Implement as an **opt-in flag** on the pointer/marker (e.g. `trail: true`),
    default off; render prior positions as decaying `AnimatedOpacity` in the same
    semantic color. Theme-aware, no new colors.
  - It must never change layout or leave permanent marks - ghosts fully fade within
    ~`moveDuration`.
- **Non-spring easing for scalars.** The spring curve overshoots - great for
  boxes/nodes, wrong for a monotonic *number* (search-space countdown, progress
  caption, a running sum). For those use a plain `easeInOutCubic`. If a shared
  helper isn't in `viz_tokens.dart` yet, add one there (a pure
  `double easeInOutCubic(double t)`) and reuse it - don't inline copies.

### When adding motion to a primitive

Keep the primitive a **dumb, stateless render** (unchanged rule): it animates
*toward* whatever the current step describes via the `Animated*` widgets and tokens
- it holds no algorithm logic and no step history. If a technique needs prior
positions (trails), pass them in from the view's derived state, computed from the
recorded steps - never let the primitive infer motion on its own.

## Adding a new structure primitive

Only when the data structure doesn't exist yet. Already built: `ArrayCells`,
`LinkedListView`, `TreeCanvas`, `CoordinateBoard`, `StackView`, `GridBoard`,
`RecursionTree` (plus the `CallStackPanel` recursion kit).
Put a new one in `lib/viz/components/<name>.dart` and `export` it from
`components.dart`. Follow the `ArrayCells` conventions so the kit stays one system:

- **Semantic colors from tokens.** Never hardcode state colors - call
  `vizStateColors(scheme, state)` (fill/border/foreground) and accept a
  `Map<NodeId, VizState> states`. Respect light/dark via `Theme.of(context)`.
- **Motion from tokens.** Animate position/appearance with `VizTokens.spring` +
  `VizTokens.moveDuration` (use `AnimatedContainer` / `AnimatedPositioned` /
  `AnimatedOpacity`); use `VizTokens.radius` for corners.
- **Labels/pointers** analogous to `ArrayPointer` (a moving `current`/`i`/`j`/`head`
  marker) where the structure has a cursor.
- **Self-fitting, never side-scrolling.** When many inputs would overflow the
  width, the **elements themselves shrink to fit the page** - no horizontal
  scrollbar. Wrap the fixed-size element visual in the shared **`FitToWidth`**
  (from `components.dart`), passing its intrinsic `naturalWidth`/`naturalHeight`
  (which the primitive knows from element geometry × count). `FitToWidth` scales
  the visual down only when it doesn't fit, centers it when it does, never
  enlarges past 1:1, and reserves the scaled height. Do **not** wrap the
  primitive (or the view's stage) in a horizontal `SingleChildScrollView`. Only
  the data elements resize - surrounding panels, controls, and the step tracker
  are untouched. (A primitive that maps a domain onto the full width instead,
  like `IntervalTrack`, is already fitting and needs no `FitToWidth`.)
- Keep it a **dumb, stateless render** of the step's data - no algorithm logic
  inside the primitive.

- **Identity vs semantic color.** `VizState` says what a cell *means now* (in
  scope, discarded, found). When you instead need "these are the **same** thing"
  - the same subproblem recurring, the same key in several buckets - use
  `vizIdentityColors(scheme, index)` and key the index off a stable identity so
  the colors agree across every visual on the page. Don't invent a local palette.

Primitives still to build as they come up: `GraphCanvas` (nodes + edges,
directed/weighted - can reuse the recursion kit for DFS) and `QueueView` (FIFO
cell row with a front/back marker - `StackView` covers LIFO).
(`TreeCanvas`, `LinkedListView`, `CoordinateBoard`, `StackView`, `GridBoard`, and
`RecursionTree` already exist - reuse them; extend `TreeCanvas` for heaps.) Build
the minimum the current algorithm needs; generalize later.

## Checklist before finishing

- [ ] Step recorder is a pure function, one step per pseudocode line, terminal cases
      handled.
- [ ] View composes `VizScaffold` + shared panels; no bespoke layout.
- [ ] Page opens with a `type: approach` **glance card** (right `pattern`
      schematic, technique name, mechanic bullets, gotcha, complexity).
- [ ] Title carries the **LeetCode number** LeetCode-native (`20. Valid
      Parentheses`) in both frontmatter `title` and the `#` heading (skip only
      for generic technique pages); prose is trimmed to *trick + gotchas*.
- [ ] Editable input has a `PresetPicker` with 3–4 presets incl. the
      frequently-missed edge cases (`edgeCase: true`).
- [ ] New primitive (if any) exported from `components.dart`, uses tokens + semantic
      colors, animates with the spring curve.
- [ ] Registered in `init.dart`; content page has a `type:` block;
      `gen_content.dart` re-run.
- [ ] `flutter analyze` clean, `flutter test` green (incl. a new recorder test),
      `flutter build web` succeeds.
