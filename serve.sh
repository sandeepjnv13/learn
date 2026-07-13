#!/usr/bin/env bash
# Build the site and serve it locally.
# Usage: ./serve.sh            (serves on the default port below)
#        PORT=51234 ./serve.sh (override the port)
set -e

# Obscure high port (dynamic range) to avoid clashing with other dev servers.
PORT="${PORT:-49173}"

export PATH="$PATH:/snap/bin"
cd "$(dirname "$0")"

echo "→ Regenerating content manifest..."
dart run tool/gen_content.dart

echo "→ Building web..."
# Warn when the incremental compiler cache is cold — a cold dart2js compile is
# ~19s vs ~2.5s warm. Cache is wiped by `flutter clean`, `flutter pub get`, or
# switching branches that touch many lib/ files.
if [ ! -d .dart_tool/flutter_build ]; then
  echo "   ⚠ cold build cache — this build will be slow (~19s). Subsequent runs will be fast (~3s)."
fi
flutter build web --no-wasm-dry-run

echo ""
echo "✅ Open  http://127.0.0.1:$PORT  in your browser (Ctrl-C to stop)"
echo ""

# Free the port first: kill any previous server still holding it.
if command -v fuser >/dev/null 2>&1; then
  fuser -k "$PORT/tcp" 2>/dev/null || true
elif command -v lsof >/dev/null 2>&1; then
  lsof -ti "tcp:$PORT" | xargs -r kill 2>/dev/null || true
fi
sleep 0.5

# SPA fallback (see tool/serve.py) so direct URLs / refreshes work, not just
# navigation from the home page.
python3 tool/serve.py "$PORT" build/web
