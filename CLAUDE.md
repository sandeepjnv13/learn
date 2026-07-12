# CLAUDE.md

Operating guide for Claude Code working in this repo. Read this first.
For deeper detail see [ARCHITECTURE.md](ARCHITECTURE.md).

## What this is

`learn` is a personal, interactive **knowledge base**: a **Flutter web app** where
content is plain **markdown** (`content/…`) and any page can host an interactive
**visualizer**. Deploys to **GitHub Pages** on push to `main`.

Requirements are explicitly **fluid/negotiable** — confirm direction before large
or destructive changes.

## Commands

Flutter is installed via snap and may not be on PATH — prefix when needed:
`export PATH="$PATH:/snap/bin"`.

| Task | Command |
|------|---------|
| Install deps | `flutter pub get` |
| Regenerate nav after adding/renaming content | `dart run tool/gen_content.dart` |
| Run (dev, hot reload) | `flutter run -d web-server --web-hostname 127.0.0.1 --web-port 8000` |
| Build + serve (view only) | `./serve.sh` → http://127.0.0.1:8000 |
| Analyze | `flutter analyze` |
| Test | `flutter test` |
| Build for deploy | handled by `.github/workflows/deploy.yml` |

Gotchas: open the app via **`127.0.0.1`** (not `localhost`) — the dev server binds
IPv4 and Firefox may resolve `localhost` to IPv6. If a browser "can't connect,"
also check Firefox **HTTPS-Only Mode** is off.

## Authoring content

- A folder under `content/` is a **section**; a `.md` file is a **page**. Nesting is
  unlimited. Folders → sidebar tree.
- Frontmatter: `title`, `order`. A folder may hold a `_section.md` (frontmatter
  only) to set its title/order.
- **Always run `dart run tool/gen_content.dart`** after adding/renaming/moving
  content — it regenerates `assets/manifest.json` and the managed asset list in
  `pubspec.yaml`.

## Visualizers — the rules

Visualizers are fenced ```` ```viz ```` blocks (YAML) in a page, dispatched by
`type` through `VizRegistry`. **A visualizer is a full-page-scale experience, not
a small inline box** — give it generous space and prefer a focused/full-width
presentation.

Two families:

### 1. Native (Flutter) visualizers — MUST reuse components
For algorithm/data-structure pages. Build these from the **shared reusable
component library** (see ARCHITECTURE.md → "Native visualizer standard"). Do **not**
hand-roll a bespoke layout per algorithm. A new algorithm =
1. write a **step recorder** (deterministic; one pseudocode line per step — never a
   live state machine, to avoid double-firing), then
2. **compose the existing panels** (pseudocode, variables, comparison badge,
   progress, event log, result banner, controls, legend, structure visual).
Only add a new *structure primitive* (e.g. GraphCanvas) when a genuinely new data
structure appears.

Design: material light feel, soft elevation, rounded corners (10–14px), white
cards on a neutral background; spring easing `Cubic(0.34, 1.56, 0.64, 1.0)` on
box/node transitions; pulse on variable change; smooth progress-bar width; 2-column
on desktop, 1-column on narrow. Adapt to the app's light/dark theme; keep state
colors semantic and consistent (in-scope, processing, discarded/visited,
found/result).

### 2. HTML visualizers — author-controlled, full-page
`type: html` embeds an author-written single HTML file (inline CSS/JS, no
frameworks) in a sandboxed iframe. **We do not control its internals** and must
**assume it is a full-page visualizer** — render it large / full-width, not a small
box. The `.html` lives next to its page.

## Extending

- **New algorithm visualizer:** step recorder in `lib/viz/renderers/<algo>/` +
  register a `type` in `lib/viz/init.dart`; compose reusable panels. The
  **`algo-visualizer` skill** (`.claude/skills/algo-visualizer/`) automates this
  end-to-end — invoke it whenever asked to build a visualizer for an algorithm.
- **New structure primitive / panel:** add to the component library and register.
- Keep `flutter analyze` clean and tests passing before finishing.
