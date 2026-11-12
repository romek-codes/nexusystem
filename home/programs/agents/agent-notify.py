#!/usr/bin/env python3
"""Agent hook: ring BEL (tmux `!` flag) + desktop notification for this tmux pane,
unless the user is already looking at it. Click "Open" to jump to the window.

Usage: agent-notify.py claude|codex < hook-json
Claude: Stop, Notification[permission_prompt], PermissionRequest (only stashes tool detail;
        it can fire before auto mode decides, Notification fires when actually waiting).
Codex:  Stop, PermissionRequest (runs before auto-review decides and there is no
        Notification event, so it notifies only if an approval prompt shows in the pane).
"""
import json
import os
import re
import subprocess
import sys
import time

pane = os.environ.get("TMUX_PANE")
if not pane:
    sys.exit(0)
agent = sys.argv[1] if len(sys.argv) > 1 else "claude"
name = agent.capitalize()
data = json.load(sys.stdin)
event = data.get("hook_event_name")
stash = os.path.join(os.environ.get("XDG_RUNTIME_DIR", "/tmp"), f"{agent}-perm-{data.get('session_id')}")


def tmux(*args):
    return subprocess.run(["tmux", *args], capture_output=True, text=True).stdout.strip()


def oneline(text, limit=70):
    for line in (text or "").splitlines():
        line = re.sub(r"`|\*{1,3}|^\s*(#+|[-*>]|\d+\.)\s+", "", line)
        line = " ".join(line.split())
        if line:
            break
    else:
        return ""
    if len(line) <= limit:
        return line
    return line[:limit].rsplit(" ", 1)[0].rstrip(".,:;") + "…"


def tool_detail(name, inp):
    detail = inp.get("command") or inp.get("file_path") or inp.get("url") or inp.get("pattern") or ""
    if name == "apply_patch":
        detail = " ".join(os.path.basename(f) for f in re.findall(r"^\*\*\* \w+ File: (.+)$", detail, re.M))
    elif inp.get("file_path"):
        detail = os.path.basename(detail)
    name = name.split("__")[-1] if name.startswith("mcp__") else name
    return f"{name}: {detail}" if detail else name


if event == "PermissionRequest" and agent == "codex":
    # Fires before auto-review decides. User-routed prompts show up right away,
    # so watch the pane briefly in the background and notify only if one does.
    if os.fork():
        sys.exit(0)
    os.setsid()
    devnull = os.open(os.devnull, os.O_RDWR)
    for fd in (0, 1, 2):
        os.dup2(devnull, fd)
    for _ in range(30):
        time.sleep(0.5)
        if "esc to cancel" in tmux("capture-pane", "-p", "-t", pane):
            break
    else:
        sys.exit(0)
    icon, body = "⏸", oneline(tool_detail(data.get("tool_name", ""), data.get("tool_input") or {}))
elif event == "PermissionRequest":
    with open(stash, "w") as f:
        f.write(tool_detail(data.get("tool_name", ""), data.get("tool_input") or {}))
    sys.exit(0)
elif event == "Stop":
    icon, body = "✓", oneline(data.get("last_assistant_message")) or f"{name} finished"
else:
    icon, body = "⏸", data.get("message") or f"{name} needs permission"
    try:
        with open(stash) as f:
            body = oneline(f.read()) or body
        os.remove(stash)
    except OSError:
        pass

session, win, active = tmux("display", "-p", "-t", pane, "#{session_name}\t#{window_index}\t#{window_active}").split("\t")
focused = "focused" in tmux("list-clients", "-t", session, "-F", "#{client_flags}")
if active == "1" and focused:
    sys.exit(0)

with open(tmux("display", "-p", "-t", pane, "#{pane_tty}"), "w") as tty:
    tty.write("\a")

cwd = data.get("cwd") or os.getcwd()
top = subprocess.run(["git", "-C", cwd, "rev-parse", "--show-toplevel"], capture_output=True, text=True).stdout.strip()
project = os.path.basename(top or cwd)
where = f"win {win}" if len(tmux("list-sessions", "-F", "x").split()) == 1 else f"{session}:{win}"
title = f"{icon} {project}   ({where})"

# Detached so the hook returns immediately; notify-send --wait blocks until click/dismiss.
subprocess.Popen(
    ["sh", "-c", """
     [ "$(notify-send --app-name "$5" --wait --action open=Open -- "$1" "$2")" = open ] || exit 0
     tmux switch-client -t "$3" && tmux select-window -t "$3"
     hyprctl dispatch focuswindow "title:^$4: "
     """, "sh", title, body, pane, session, name],
    stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
    start_new_session=True,
)
