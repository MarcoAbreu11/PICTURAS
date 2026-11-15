"""Small client for the PictuRAS public API, used by the upload benchmark and
the regression checks. Standard library only; uploads go through curl so the
client itself never loads a file into memory."""

import hashlib
import json
import ssl
import subprocess
import time
import urllib.error
import urllib.request
import uuid

BASE_URL = "https://localhost:8080/api-gateway"

# The stack uses a self-signed certificate.
_CTX = ssl.create_default_context()
_CTX.check_hostname = False
_CTX.verify_mode = ssl.CERT_NONE


class ApiError(Exception):
    def __init__(self, status, body):
        super().__init__(f"HTTP {status}: {body}")
        self.status = status
        self.body = body


def request(method, path, body=None, token=None, headers=None, base=BASE_URL, timeout=60):
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(base + path, data=data, method=method)
    if data is not None:
        req.add_header("Content-Type", "application/json")
    if token:
        req.add_header("Authorization", f"Bearer {token}")
    for k, v in (headers or {}).items():
        req.add_header(k, str(v))
    try:
        with urllib.request.urlopen(req, context=_CTX, timeout=timeout) as resp:
            raw = resp.read()
            return resp.status, dict(resp.headers), (json.loads(raw) if raw else None)
    except urllib.error.HTTPError as e:
        raw = e.read()
        try:
            parsed = json.loads(raw)
        except ValueError:
            parsed = raw.decode(errors="replace")
        raise ApiError(e.code, parsed) from None


def register(user_type="premium"):
    """Creates a new user of the given profile and returns (user_id, token)."""
    email = f"bench-{uuid.uuid4().hex[:12]}@example.test"
    password = uuid.uuid4().hex
    request("POST", "/users/", {"name": "bench", "email": email, "password": password, "type": user_type})
    _, _, data = request("POST", f"/users/{email}/login", {"password": password})
    return str(data["user"]["_id"]), data["jwt"]


def create_project(user_id, token, name=None):
    _, _, project = request("POST", f"/projects/{user_id}", {"name": name or f"bench-{uuid.uuid4().hex[:8]}"}, token)
    return project["_id"], project["version"]


def get_project(user_id, token, project_id):
    return request("GET", f"/projects/{user_id}/{project_id}", token=token)[2]


def upload(user_id, token, project_id, version, path, kind, field=None, timeout=1800):
    """Uploads one file with curl. Returns a dict with http status, body,
    total time (s), upload speed (B/s) and the new project version."""
    endpoint = "video" if kind == "video" else "img"
    field = field or ("video" if kind == "video" else "image")
    cmd = [
        "curl", "-sk", "-o", "-", "-D", "/dev/stderr",
        "-w", "\n%{http_code} %{time_total} %{speed_upload}",
        "--max-time", str(timeout),
        "-H", f"Authorization: Bearer {token}" if token else "X-No-Auth: 1",
        "-H", f"X-Project-Version: {version}",
        "-F", f"{field}=@{path}",
        f"{BASE_URL}/projects/{user_id}/{project_id}/{endpoint}",
    ]
    started = time.time()
    proc = subprocess.run(cmd, capture_output=True, text=True)
    out = proc.stdout.rsplit("\n", 1)
    body, stats = (out[0], out[1]) if len(out) == 2 else ("", out[0])
    parts = stats.split()
    status = int(parts[0]) if parts and parts[0].isdigit() else 0
    new_version = None
    for line in proc.stderr.splitlines():
        if line.lower().startswith("x-project-version:"):
            new_version = int(line.split(":", 1)[1].strip())
    try:
        body = json.loads(body) if body else None
    except ValueError:
        pass
    return {
        "status": status,
        "body": body,
        "time_s": float(parts[1]) if len(parts) > 1 else time.time() - started,
        "speed_Bps": float(parts[2]) if len(parts) > 2 else 0.0,
        "version": new_version,
        "curl_exit": proc.returncode,
    }


def sha256_file(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def sha256_url(url):
    """Downloads a URL (streaming) and returns its SHA-256."""
    h = hashlib.sha256()
    with urllib.request.urlopen(url, context=_CTX, timeout=600) as resp:
        for chunk in iter(lambda: resp.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()
