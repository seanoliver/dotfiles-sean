#!/usr/bin/env python3
"""
Work Sweep companion server.

A tiny local disk-bridge so the work-sweep HTML behaves like an app:
  - serves today's (or ?date=) report at /
  - GET  /api/state?date=YYYY-MM-DD  -> per-day view state {order, completed, dismissed}
  - POST /api/state                  -> persist view state to state-<date>.json
  - POST /api/dismiss                 -> append a dismissal+reason to the canonical
                                          work-sweep-dismissed.md (the file the skill reads)
                                          AND record the id in per-day state
  - POST /api/undismiss               -> remove the matching line again (undo)

No third-party deps. Run:  python3 ~/work-sweeps/server.py
Then open http://localhost:7777/
"""
import json
import os
import re
import sys
import datetime
import urllib.parse
from http.server import HTTPServer, BaseHTTPRequestHandler

BASE = os.path.expanduser("~/work-sweeps")
DISMISSED_FILE = os.path.expanduser(
    "~/.claude/projects/-Users-seanoliver-supabase/memory/work-sweep-dismissed.md"
)
PORT = int(os.environ.get("WS_PORT", "7777"))


def today_str():
    return datetime.date.today().isoformat()


def state_path(date):
    return os.path.join(BASE, f"state-{date}.json")


def html_path(date):
    return os.path.join(BASE, f"work-sweep-{date}.html")


def load_state(date):
    p = state_path(date)
    if os.path.exists(p):
        try:
            with open(p) as f:
                return json.load(f)
        except (json.JSONDecodeError, OSError):
            pass
    return {"order": [], "completed": [], "dismissed": []}


def save_state(date, state):
    clean = {
        "order": state.get("order", []),
        "completed": state.get("completed", []),
        "dismissed": state.get("dismissed", []),
    }
    with open(state_path(date), "w") as f:
        json.dump(clean, f, indent=2)


def append_dismissal(url, label, reason):
    """Append a dismissal line under '## Active Dismissals', idempotent on URL."""
    date = today_str()
    url = (url or "-").strip()
    label = (label or "").replace('"', "'").strip()
    reason = (reason or "").strip()
    line = f'- {date} | {url} | "{label}" | {reason}'

    content = ""
    if os.path.exists(DISMISSED_FILE):
        with open(DISMISSED_FILE) as f:
            content = f.read()

    # already dismissed this exact URL? skip (idempotent)
    if url != "-" and re.search(re.escape(f"| {url} |"), content):
        return
    if not content.strip():
        content = (
            "# Work Sweep - Dismissed Items\n\n"
            "Items listed here are filtered out of future Work Sweep reports.\n"
            "Format: `date | primary URL | short label | reason`\n\n"
            "## Active Dismissals\n"
        )
    content = content.rstrip() + "\n" + line + "\n"
    with open(DISMISSED_FILE, "w") as f:
        f.write(content)


def list_dismissed_urls():
    """Return every dismissed primary URL from the canonical file (authoritative hide list)."""
    if not os.path.exists(DISMISSED_FILE):
        return []
    urls = []
    with open(DISMISSED_FILE) as f:
        for line in f:
            line = line.strip()
            if not line.startswith("- "):
                continue
            parts = [p.strip() for p in line[2:].split("|")]
            if len(parts) >= 2 and parts[1] and parts[1] != "-":
                urls.append(parts[1])
    return urls


def remove_dismissal(url):
    """Undo: strip lines matching the URL from the dismissed file."""
    if not os.path.exists(DISMISSED_FILE) or not url:
        return
    with open(DISMISSED_FILE) as f:
        lines = f.readlines()
    kept = [ln for ln in lines if f"| {url} |" not in ln]
    with open(DISMISSED_FILE, "w") as f:
        f.writelines(kept)


class Handler(BaseHTTPRequestHandler):
    def log_message(self, *args):
        pass  # quiet

    def _json(self, code, obj):
        body = json.dumps(obj).encode()
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def _read_json(self):
        length = int(self.headers.get("Content-Length", 0) or 0)
        if not length:
            return {}
        try:
            return json.loads(self.rfile.read(length) or b"{}")
        except json.JSONDecodeError:
            return {}

    def do_GET(self):
        parsed = urllib.parse.urlparse(self.path)
        qs = urllib.parse.parse_qs(parsed.query)

        if parsed.path == "/api/state":
            date = qs.get("date", [today_str()])[0]
            self._json(200, load_state(date))
            return

        if parsed.path == "/api/dismissed":
            self._json(200, list_dismissed_urls())
            return

        # serve the report html
        date = qs.get("date", [today_str()])[0]
        path = html_path(date)
        if parsed.path not in ("/", "") and parsed.path.endswith(".html"):
            path = os.path.join(BASE, os.path.basename(parsed.path))
        if not os.path.exists(path):
            # fall back to the most recent report
            reports = sorted(
                f for f in os.listdir(BASE) if re.match(r"work-sweep-.*\.html$", f)
            )
            if reports:
                path = os.path.join(BASE, reports[-1])
            else:
                self.send_response(404)
                self.end_headers()
                self.wfile.write(b"No work-sweep report found.")
                return
        with open(path, "rb") as f:
            body = f.read()
        self.send_response(200)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_POST(self):
        parsed = urllib.parse.urlparse(self.path)
        data = self._read_json()
        date = data.get("date", today_str())

        if parsed.path == "/api/state":
            save_state(date, data.get("state", {}))
            self._json(200, {"ok": True})
            return

        if parsed.path == "/api/dismiss":
            append_dismissal(data.get("url"), data.get("label"), data.get("reason"))
            st = load_state(date)
            sid = str(data["id"]) if data.get("id") is not None else None
            st["dismissed"] = [str(x) for x in st.get("dismissed", [])]
            if sid is not None and sid not in st["dismissed"]:
                st["dismissed"].append(sid)
            save_state(date, st)
            self._json(200, {"ok": True})
            return

        if parsed.path == "/api/undismiss":
            remove_dismissal(data.get("url"))
            st = load_state(date)
            sid = str(data.get("id"))
            st["dismissed"] = [str(x) for x in st.get("dismissed", []) if str(x) != sid]
            save_state(date, st)
            self._json(200, {"ok": True})
            return

        self._json(404, {"error": "unknown endpoint"})


def main():
    os.makedirs(BASE, exist_ok=True)
    try:
        httpd = HTTPServer(("127.0.0.1", PORT), Handler)
    except OSError as e:
        print(f"Could not bind port {PORT}: {e}", file=sys.stderr)
        sys.exit(1)
    print(f"Work Sweep server -> http://localhost:{PORT}/  (Ctrl-C to stop)")
    print(f"Dismissals -> {DISMISSED_FILE}")
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\nstopped.")


if __name__ == "__main__":
    main()
