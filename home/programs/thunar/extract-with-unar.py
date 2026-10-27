#!/usr/bin/env python3
"""Show entry progress for unar and stop extraction when the dialog is closed."""

import html
import json
import os
import selectors
import signal
import subprocess
import sys
from pathlib import Path


def stop(process):
    if process.poll() is not None:
        return
    try:
        os.killpg(process.pid, signal.SIGTERM)
    except ProcessLookupError:
        return
    try:
        process.wait(timeout=2)
    except subprocess.TimeoutExpired:
        try:
            os.killpg(process.pid, signal.SIGKILL)
        except ProcessLookupError:
            pass
        process.wait()


def update(dialog, label, percent):
    if dialog.poll() is not None:
        return
    data = f"#{html.escape(label)}\n{percent}\n".encode()
    try:
        os.write(dialog.stdin.fileno(), data)
    except (BlockingIOError, BrokenPipeError):
        pass


def list_entries(lsar, archive, dialog):
    process = subprocess.Popen(
        [lsar, "-j", "-jss", str(archive)],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        start_new_session=True,
    )
    while True:
        if dialog.poll() is not None:
            stop(process)
            return None, None
        try:
            output, error = process.communicate(timeout=0.1)
            break
        except subprocess.TimeoutExpired:
            continue
    if process.returncode != 0:
        return None, error.decode(errors="replace").strip() or "Could not read archive"
    try:
        listing = json.loads(output)
        if listing.get("lsarError"):
            return None, f"lsar error {listing['lsarError']}"
        return len(listing["lsarContents"]), None
    except (ValueError, KeyError, TypeError):
        return None, "Could not read the archive file list"


def extract(unar, archive, dialog, completed, total, number, batch_size):
    process = subprocess.Popen(
        [unar, "-r", "-o", str(archive.parent), str(archive)],
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        start_new_session=True,
    )
    output = []
    pending = b""
    selector = selectors.DefaultSelector()
    selector.register(process.stdout, selectors.EVENT_READ)

    while selector.get_map():
        if dialog.poll() is not None:
            stop(process)
            selector.close()
            return completed, None, True
        for key, _ in selector.select(timeout=0.1):
            data = os.read(key.fd, 65536)
            if not data:
                selector.unregister(key.fileobj)
                break
            pending += data
            while b"\n" in pending:
                line, pending = pending.split(b"\n", 1)
                message = line.decode(errors="replace").strip()
                output.append(message)
                if len(output) > 12:
                    output.pop(0)
                if message.endswith("OK.") or "Failed! (" in message:
                    completed += 1
                    label = f"{archive.name} ({number}/{batch_size}) — {completed}/{total} entries"
                    update(dialog, label, min(99, completed * 100 // max(total, 1)))

    selector.close()
    process.wait()
    if process.returncode != 0:
        return completed, "\n".join(output[-6:]) or "unar failed", False
    return completed, None, False


def main():
    unar, lsar, yad, notify, *names = sys.argv[1:]
    archives = [Path(name).resolve() for name in names]
    if not archives:
        return 1

    dialog = subprocess.Popen(
        [
            yad,
            "--progress",
            "--title=Extract with unar",
            "--text=Reading archive contents…",
            "--percentage=0",
            "--width=480",
            "--auto-close",
            "--button=Cancel:1",
        ],
        stdin=subprocess.PIPE,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )
    os.set_blocking(dialog.stdin.fileno(), False)

    counts = []
    for archive in archives:
        update(dialog, f"Reading {archive.name}…", 0)
        count, error = list_entries(lsar, archive, dialog)
        if dialog.poll() is not None:
            subprocess.run([notify, "Extraction canceled", "Partially extracted files may remain."])
            return 0
        if error:
            dialog.terminate()
            subprocess.run([yad, "--error", "--title=Extraction failed", "--text=" + html.escape(f"{archive.name}: {error}")])
            return 1
        counts.append(count)

    total = sum(counts)
    completed = 0
    for number, archive in enumerate(archives, 1):
        update(dialog, f"{archive.name} ({number}/{len(archives)}) — {completed}/{total} entries", completed * 99 // max(total, 1))
        completed, error, canceled = extract(unar, archive, dialog, completed, total, number, len(archives))
        if canceled:
            subprocess.run([notify, "Extraction canceled", "Partially extracted files may remain."])
            return 0
        if error:
            dialog.terminate()
            subprocess.run([yad, "--error", "--title=Extraction failed", "--text=" + html.escape(f"{archive.name}: {error}")])
            return 1

    update(dialog, "Extraction complete", 100)
    dialog.stdin.close()
    dialog.wait(timeout=5)
    subprocess.run([notify, "Archive extraction complete", f"Extracted {len(archives)} archive(s)."])
    return 0


if __name__ == "__main__":
    sys.exit(main())
