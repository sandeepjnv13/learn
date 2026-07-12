#!/usr/bin/env python3
"""Tiny static server with SPA fallback.

`flutter build web` produces a single-page app that does its own client-side
routing. A plain static server (e.g. `python -m http.server`) returns 404 for a
deep link like `/ds-algo/searching/binary-search` because no such file exists,
so direct URL access / refresh fails. This server serves the requested file when
it exists and otherwise falls back to `index.html`, letting the router take over
— exactly what the deployed GitHub Pages `404.html` copy does in production.

Usage: python3 tool/serve.py [PORT] [DIRECTORY]
"""
import os
import sys
from http.server import HTTPServer, SimpleHTTPRequestHandler

PORT = int(sys.argv[1]) if len(sys.argv) > 1 else 49173
DIRECTORY = sys.argv[2] if len(sys.argv) > 2 else "build/web"


class SPAHandler(SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=DIRECTORY, **kwargs)

    def send_head(self):
        # Rewrite unknown paths (client-side routes) to the app shell.
        path = self.translate_path(self.path)
        if not os.path.exists(path):
            self.path = "/index.html"
        return super().send_head()


if __name__ == "__main__":
    with HTTPServer(("127.0.0.1", PORT), SPAHandler) as httpd:
        print(f"Serving {DIRECTORY} on http://127.0.0.1:{PORT} (SPA fallback on)")
        httpd.serve_forever()
