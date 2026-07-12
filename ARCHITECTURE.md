# Architecture

`learn` is a Flutter **web** app that renders a tree of markdown pages and lets any
page embed interactive visualizers. This document explains how the pieces fit and,
importantly, the **standard every visualizer must follow**.

> Status legend: ✅ built · 🚧 in progress · 📐 planned/convention

## 1. High-level flow

```
content/**.md ──gen_content.dart──▶ assets/manifest.json ──▶ ContentService
                                                                   │
                                            router.dart builds routes per page
                                                                   │
                        AppShell (sidebar + content)  ──▶  ContentPage
                                                                   │
                                     MarkdownDocument (splits ```viz blocks)
                                              │                    │
                                   normal markdown         VizRegistry.build(type)
                                                                   │
                              ┌────────────────────────┬──────────┴───────────┐
                        native renderers         html embed (iframe)     (future types)
                              │
                    reusable component library + step recorders
```

## 2. Content pipeline ✅

- **`content/`** — folders are sections, `.md` files are pages, unlimited nesting.
  Frontmatter (`title`, `order`); a folder may carry `_section.md` for its own
  title/order.
- **`tool/gen_content.dart`** — walks `content/`, emits `assets/manifest.json`
  (the nav tree) and rewrites the managed asset-dir list in `pubspec.yaml` between
  the `# >>> generated content dirs` markers. Run after any content change.
- **`ContentService`** (`lib/services/`) — loads the manifest and individual pages
  (splitting frontmatter from body) from bundled assets.
- **`router.dart`** — builds one `GoRoute` per page from the manifest, all under a
  `ShellRoute` (`AppShell`). Clean URLs via `usePathUrlStrategy()`; GitHub Pages
  gets a `404.html` copy of `index.html` for deep-link fallback.

## 3. Markdown + visualizer dispatch ✅

- **`MarkdownDocument`** (`lib/ui/markdown/`) segments the page body on
  ```` ```viz ```` fences. Non-viz text → `flutter_markdown_plus` with a themed
  stylesheet; viz blocks → parsed as YAML → `VizRegistry`.
- **`VizRegistry`** (`lib/viz/registry.dart`) maps a `type:` string to a builder.
  A `VizContext` carries the parsed config and the page asset path (to resolve
  relative `src:` for HTML embeds). Unknown types render a visible error.

## 4. Visualizer families

### 4a. Native (Flutter) — the standard 📐

Native visualizers are the heart of this project. **They are full-page-scale,
reusable-component-based, step-by-step experiences** — never a bespoke one-off
layout per algorithm, never a cramped inline box.

**Determinism via recorders (not live state machines).**
Each algorithm ships a **step recorder**: it runs the real algorithm once and
records **one step per pseudocode line executed**. Stepping is then index movement
over a precomputed list, so a click always advances exactly one line and can never
double-fire. Example already written: `lib/viz/renderers/binary_search/
binary_search_algo.dart` (🚧) producing `BsStep`s + the pseudocode.

**Required anatomy of an algorithm visualizer:**
1. **Structure visual** — array boxes / graph nodes+edges / tree, with pointer &
   index labels (low/mid/high, current node, i/j) that move as state changes, and a
   **legend**. State colors are semantic and consistent: active/in-scope,
   currently-processing, discarded/visited, found/result.
2. **Pseudocode panel** — full pseudocode with the **current line highlighted**, in
   sync with each step.
3. **Variables panel** — live key variables, each with a **pulse/flash** when its
   value changes.
4. **Comparison/decision badge** — the specific comparison just made
   (e.g. `arr[mid] < target → search right`).
5. **Progress indicator** — shrinking search space / nodes visited, plus a **step
   counter**.
6. **Event log** — scrolling plain-English trace of every step.
7. **Result banner** — success/failure/completion, visually distinct from the log.
8. **Controls** — Start / Step / Auto Play / Reset, plus editable input in a top bar.

**Reusable component library** ✅ (`lib/viz/components/`) — built and
**composed** in every algorithm visualizer. Barrel export: `components.dart`.
Design tokens (semantic `VizState` colors, spring curve, geometry) live in
`viz_tokens.dart`. Panels: `Panel` (the white card shell), `ControlBar`,
`PseudocodePanel`, `VariablesPanel` (+ `PulseChip`), `ComparisonBadge`,
`StepProgress`, `EventLog`, `ResultBanner`, `Legend`, and the full-page layout
`VizScaffold` (header + control bar + stage + responsive 2-col panel grid).
Structure primitives: `ArrayCells` ✅ (colored cells + gliding pointer lane);
`GraphCanvas`, `TreeCanvas`, `LinkedListView`, `StackView` 📐 still to come.
A new algorithm adds *only* a step recorder + a thin composition widget (see
`renderers/binary_search/binary_search_view.dart` ✅); add a new primitive *only*
for a genuinely new data structure.

> Migration note: the current `ArrayView` + `VizPlayer` + `VizCard` (✅) are the
> first-generation, simpler renderers. They are being superseded by the component
> library above; refactor shared parts out of them rather than duplicating.

**Design language:** material light feel — soft elevation shadows, rounded corners
10–14px, neutral background, white cards per panel. Fluid animation: spring easing
`Cubic(0.34, 1.56, 0.64, 1.0)` on box/node transitions, subtle pulse on variable
updates, smooth width transition on progress bars. Layout: 2-column grid on desktop
(e.g. pseudocode + variables side by side) collapsing to 1 column on narrow screens.
Respect the app's light/dark theme for panels; keep state colors semantic.

### 4b. HTML — author-controlled, full-page ✅

`type: html` embeds a standalone HTML file (inline CSS/JS, no frameworks) authored
by the user, sitting next to its page. Rendered in a **sandboxed iframe**
(`lib/viz/renderers/html_platform_web.dart`, via conditional import so non-web
analysis stays clean; local files use `srcdoc`, URLs use `src`).

We **do not control its internals**, and we **assume it is a full-page visualizer**
— so it must be rendered large / full-width, not a small box. (Height is
configurable today; the direction is full-viewport / a launch-to-fullscreen
affordance.)

## 5. Deploy ✅

`.github/workflows/deploy.yml`: on push to `main`, installs Flutter, regenerates the
manifest, `flutter build web --base-href /<repo>/`, copies `index.html`→`404.html`,
and publishes to GitHub Pages (enable Pages → Source: GitHub Actions once).

## 6. Directory map

```
content/                     markdown pages + optional .html visualizers
tool/gen_content.dart        manifest + pubspec asset generator
assets/manifest.json         generated nav tree
lib/
  main.dart                  entry: load content, url strategy, run app
  app_scope.dart             InheritedWidget: ContentService + themeMode
  router.dart                routes built from manifest
  theme/app_theme.dart       light + dark, Inter/JetBrains Mono
  models/content_node.dart   nav tree node
  services/content_service.dart
  ui/
    app_shell.dart, sidebar.dart, home_page.dart, content_page.dart
    markdown/markdown_document.dart
  algorithms/                first-gen live recorders (bubble, binary) + registry
  viz/
    registry.dart, frame.dart, player.dart, viz_card.dart, init.dart
    components/              📐 reusable panels + structure primitives
    renderers/
      array_view.dart, html_embed.dart, html_platform_{web,stub}.dart
      binary_search/         ✅ rich binary-search visualizer (algo + view)
```
