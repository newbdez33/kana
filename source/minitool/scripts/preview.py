"""Serve the local preview with the mini-tool network restrictions."""

import argparse
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument("--port", type=int, default=8797)
args = parser.parse_args()
root = Path(__file__).resolve().parent.parent / "build/web"
if not (root / "index.html").is_file():
    parser.error("Run npm run build first.")


class Handler(SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header("Cache-Control", "no-store")
        self.send_header("Content-Security-Policy", "default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline'; img-src 'self' data: blob:; font-src 'self'; media-src 'self'; connect-src 'none'; object-src 'none'; frame-src 'none'; worker-src 'none'; base-uri 'none'; form-action 'none'")
        super().end_headers()


server = ThreadingHTTPServer(("127.0.0.1", args.port), partial(Handler, directory=str(root)))
print(f"Kana preview: http://127.0.0.1:{args.port}/?lang=zh-Hans", flush=True)
server.serve_forever()
