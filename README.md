# Learn

A personal, interactive knowledge base - Flutter web app where content is plain
markdown and any page can host a live visualizer. Covers DS & Algo, Databases,
System Design, Low-Level Design, Languages, and whatever else you add.

> **Docs:** [CLAUDE.md](CLAUDE.md) (working guide) · [ARCHITECTURE.md](ARCHITECTURE.md)
> (how it's built + the visualizer standard).

## Run locally

```bash
flutter pub get
dart run tool/gen_content.dart   # rebuild nav after adding/renaming content
flutter run -d chrome            # or: flutter run -d web-server
```

## Add content while studying

1. Create a markdown file under `content/…`, e.g.
   `content/ds-algo/arrays/kadane.md`. Folders become the nav tree at any depth.
2. Add frontmatter:
   ```markdown
   ---
   title: Kadane's Algorithm
   order: 3
   ---
   ```
   A folder can have a `_section.md` (frontmatter only) to set its title/order.
3. Run `dart run tool/gen_content.dart` to refresh the sidebar, then hot-restart.

## Visualizers

Two kinds, and both are meant to be **full-page-scale**, not small inline boxes:

- **Native (Flutter)** - rich, step-by-step algorithm visualizers built from a
  **shared reusable component library** (pseudocode panel, variables, comparison
  badge, progress, event log, result banner, controls, legend, structure visual).
  See the standard in [ARCHITECTURE.md](ARCHITECTURE.md#4a-native-flutter--the-standard-).
- **HTML** - a standalone author-written HTML file embedded in a sandboxed iframe,
  for hand-crafted visuals we don't otherwise control.

Drop a fenced ```` ```viz ```` block anywhere in a page.

**Live (real Dart algorithm generates the animation):**
````markdown
```viz
type: array
algo: bubble-sort
input: [5, 1, 4, 2, 8]
```
````

**Authored frames (stepper, no code):**
````markdown
```viz
type: array
frames:
  - {data: [1,3,4,5], pointers: {lo: 0, hi: 3}, note: "start"}
  - {data: [1,3,4,5], highlight: [1,2], note: "..."}
```
````

**Single static frame:**
````markdown
```viz
type: array
data: [3, 1, 4]
highlight: [1]
```
````

**Raw HTML file (hand-crafted visual, lives next to the page):**
````markdown
```viz
type: html
src: my-visual.html
height: 300
```
````

### Extending the kit
- **New algorithm:** add a recorder in `lib/algorithms/`, register it in
  `lib/algorithms/registry.dart`.
- **New structure renderer** (tree, graph, linked list…): add a widget in
  `lib/viz/renderers/`, register it in `lib/viz/init.dart`.

## Deploy

Push to `main` → GitHub Action builds and publishes to GitHub Pages
(`.github/workflows/deploy.yml`). Enable Pages → Source: **GitHub Actions** once.
