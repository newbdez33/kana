"""Serve only the generated impact preview artifacts."""

import argparse
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import urlsplit

parser = argparse.ArgumentParser()
parser.add_argument('--bind', default='127.0.0.1')
parser.add_argument('--port', type=int, default=8805)
args = parser.parse_args()
root = Path(__file__).resolve().parent.parent / 'build/impact-preview'
if not (root / 'preview.html').is_file():
    parser.error('Run node scripts/build-impact.mjs first.')


class Handler(SimpleHTTPRequestHandler):
    def do_GET(self):
        if urlsplit(self.path).path == '/':
            self.path = '/preview.html'
        super().do_GET()

    def end_headers(self):
        self.send_header('Cache-Control', 'no-store')
        super().end_headers()


server = ThreadingHTTPServer((args.bind, args.port), partial(Handler, directory=str(root)))
print(f'Impact preview: http://{args.bind}:{args.port}/', flush=True)
server.serve_forever()
