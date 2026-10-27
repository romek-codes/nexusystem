from __future__ import annotations

import json
import os
import shlex
import shutil
import subprocess
import sys
from datetime import datetime
from pathlib import Path

from .app import SessionRecord, load_recent_messages, recent_sessions


def _resume_command(record: SessionRecord, happy: bool = False) -> list[str]:
    if happy:
        return ["happy", record.tool, "resume", record.session_id]
    if record.tool == "codex":
        return ["codex", "resume", record.session_id]
    return ["claude", "--resume", record.session_id]


def print_recent(
    count: int | None,
    *,
    include_current: bool = False,
    within_seconds: float | None = None,
    message_count: int = 6,
    as_json: bool = False,
) -> int:
    records = recent_sessions(
        count, include_current=include_current, within_seconds=within_seconds
    )
    if as_json:
        print(
            json.dumps(
                [
                    {
                        "tool": record.tool,
                        "session_id": record.session_id,
                        "cwd": record.cwd,
                        "updated_at": datetime.fromtimestamp(record.updated_at)
                        .astimezone()
                        .isoformat(),
                        "transcript_path": record.transcript_path,
                        "resume_command": _resume_command(record),
                        "last_messages": load_recent_messages(record, message_count),
                    }
                    for record in records
                ],
                indent=2,
            )
        )
        return 0

    if not records:
        print("No previous sessions found.")
        return 0
    for index, record in enumerate(records, 1):
        updated = (
            datetime.fromtimestamp(record.updated_at)
            .astimezone()
            .isoformat(timespec="minutes")
        )
        print(f"{index}. {record.tool}  {record.project}  {updated}")
        print(f"   cwd: {record.cwd}")
        print(f"   session: {record.session_id}")
        print(f"   transcript: {record.transcript_path}")
        print(f"   resume: {shlex.join(_resume_command(record))}")
        for message in load_recent_messages(record, message_count):
            print(f"   {message}")
        if index != len(records):
            print()
    return 0


def reopen_recent(
    count: int,
    *,
    include_current: bool = False,
    within_seconds: float | None = None,
    happy: bool = False,
    dry_run: bool = False,
) -> int:
    records = recent_sessions(
        count, include_current=include_current, within_seconds=within_seconds
    )
    if not records:
        print("reh: no previous sessions found", file=sys.stderr)
        return 1

    pane = os.environ.get("TMUX_PANE")
    if not os.environ.get("TMUX") or not pane:
        print("reh: reopen must run inside the current tmux session", file=sys.stderr)
        return 2
    if shutil.which("tmux") is None:
        print("reh: `tmux` is not on PATH", file=sys.stderr)
        return 127
    try:
        session = subprocess.run(
            ["tmux", "display-message", "-p", "-t", pane, "#{session_id}"],
            check=True,
            capture_output=True,
            text=True,
        ).stdout.strip()
    except (OSError, subprocess.CalledProcessError) as exc:
        print(f"reh: could not find current tmux session: {exc}", file=sys.stderr)
        return 1
    if not session:
        print("reh: current tmux session has no ID", file=sys.stderr)
        return 1

    launches: list[tuple[SessionRecord, list[str]]] = []
    for record in records:
        if not Path(record.cwd).is_dir():
            print(f"reh: session cwd does not exist: {record.cwd}", file=sys.stderr)
            return 1
        command = _resume_command(record, happy=happy)
        executable = shutil.which(command[0])
        if executable is None:
            print(f"reh: `{command[0]}` is not on PATH", file=sys.stderr)
            return 127
        command[0] = executable
        title = f"reh-{record.tool}-{record.project}"[:40]
        launch = [
            "tmux",
            "new-window",
            "-d",
            "-t",
            session,
            "-c",
            record.cwd,
            "-n",
            title,
            shlex.join(command),
        ]
        launches.append((record, launch))

    for record, launch in launches:
        if dry_run:
            print(shlex.join(launch))
            continue
        try:
            subprocess.run(launch, check=True)
        except (OSError, subprocess.CalledProcessError) as exc:
            print(f"reh: failed to reopen {record.session_id}: {exc}", file=sys.stderr)
            return 1
        print(f"reopened {record.tool} {record.session_id} in tmux session {session}")
    return 0
