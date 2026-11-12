#!/usr/bin/env python3
# SPDX-License-Identifier: MIT
"""Fetch checksum-verified Autodesk payloads referenced by the local manifests."""
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
import argparse
import os
import shutil
import hashlib
import sys
import tarfile
import urllib.parse
import urllib.request
import xml.etree.ElementTree as ET

PROJECT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(PROJECT / "vendor/inventor-linux/scripts/lib"))
import odis

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("source", nargs="?", type=Path, help="Extracted official media/manifests (copied to the ignored build directory)")
args = parser.parse_args()
STATE = Path(os.environ.get("INVENTOR_STATE_DIR", PROJECT))
media = STATE / "build/install-media"
if args.source:
    source = args.source.resolve()
    if not source.is_dir() or source == media.resolve() or media.resolve() in source.parents or source in media.resolve().parents:
        raise SystemExit("Use a separate extracted media directory")
    shutil.copytree(source, media, dirs_exist_ok=True)
if not media.is_dir():
    parser.error("Provide the extracted official media directory on the first run")
cache = STATE / "build/payloads"
cache.mkdir(parents=True, exist_ok=True)
img = odis.Image(str(media))
steps, _, missing = odis.plan(img, ["inventor"], "ja-JP")
if missing:
    raise SystemExit(f"Missing manifests: {missing}")
jobs = {}
for step in steps:
    root = ET.parse(img.find(step["manifest"])).getroot()
    for f in root.findall("m:Payload/m:File", odis.NS):
        url = urllib.parse.urljoin("https://dds.autodesk.com/", f.text.strip())
        if urllib.parse.urlparse(url).hostname not in {"dds.autodesk.com", "efulfillment.autodesk.com"}:
            raise SystemExit("Unexpected payload host")
        digest = f.get("checkSum", "").lower()
        if len(digest) != 64:
            raise SystemExit("Expected SHA-256 payload checksum")
        jobs[url] = (digest, int(f.get("sizePacked", "0")))

def sha256(path):
    h = hashlib.sha256()
    with path.open("rb") as src:
        for block in iter(lambda: src.read(1024 * 1024), b""):
            h.update(block)
    return h.hexdigest()

data_home = Path(os.environ.get("XDG_DATA_HOME", Path.home() / ".local/share"))
prefix = Path(os.environ.get("INVENTOR_PREFIX") or os.environ.get("WINEPREFIX")
              or data_home / "inventor-on-linux/prefix")
existing_root = prefix / "drive_c/Autodesk/WI"
existing = {}
for p in existing_root.rglob("pkg.*.tar*"):
    existing.setdefault(p.name, []).append(p)

def fetch(item):
    url, (digest, size) = item
    name = Path(urllib.parse.urlparse(url).path).name
    dest = cache / digest / name
    dest.parent.mkdir(exist_ok=True)
    choices = ([dest] if dest.exists() else []) + existing.get(name, [])
    for candidate in choices:
        if candidate.stat().st_size == size and sha256(candidate) == digest:
            print(f"verified cached {name}", flush=True)
            return candidate
    partial = dest.with_name(dest.name + ".partial")
    print(f"download {name} ({size / 1e6:.1f} MB)", flush=True)
    with urllib.request.urlopen(url, timeout=60) as src, partial.open("wb") as out:
        for block in iter(lambda: src.read(1024 * 1024), b""):
            out.write(block)
    if partial.stat().st_size != size or sha256(partial) != digest:
        raise RuntimeError(f"Payload checksum/size mismatch: {name}")
    partial.replace(dest)
    return dest

with ThreadPoolExecutor(max_workers=3) as pool:
    archives = list(pool.map(fetch, jobs.items()))
for archive in archives:
    marker = cache / (hashlib.sha256(str(archive).encode()).hexdigest() + ".extracted")
    if marker.exists():
        continue
    print(f"extract {archive.name}", flush=True)
    with tarfile.open(archive) as source:
        for member in source:
            target = media / member.name
            if not target.absolute().is_relative_to(media.absolute()) or ".." in Path(member.name).parts:
                raise RuntimeError("Archive member escapes media directory")
            # The overlay initially links back to the original download cache.
            if target.is_symlink():
                target.unlink()
            source.extract(member, media, filter="data")
    marker.touch()
missing_payloads = [s["file"] for s in steps if not odis.Image(str(media)).find(s["file"])]
if missing_payloads:
    raise SystemExit(f"Still missing payloads: {missing_payloads}")
print(f"Ready: {len(steps)} package steps; {len(archives)} verified payload archives", flush=True)
