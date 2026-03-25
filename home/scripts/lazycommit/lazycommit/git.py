from __future__ import annotations

import subprocess
from typing import List

from .console import abort


def ensure_git_repo() -> None:
    result = subprocess.run(
        ["git", "rev-parse", "--is-inside-work-tree"],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        check=False,
    )
    if result.returncode != 0:
        abort("Not in a git repository")


def run_git(args: List[str], check: bool = True) -> subprocess.CompletedProcess[str]:
    result = subprocess.run(
        ["git", *args],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        check=False,
    )
    if check and result.returncode != 0:
        abort(result.stderr.strip() or f"git {' '.join(args)} failed")
    return result


def get_staged_diff() -> str:
    diff = run_git(["diff", "--cached"], check=True).stdout
    if not diff.strip():
        abort("No staged changes found. Please stage your changes first with: git add <files>")
    return diff


def get_changed_files() -> List[str]:
    output = run_git(["diff", "--cached", "--name-only"], check=True).stdout
    files = [line.strip() for line in output.splitlines() if line.strip()]
    if not files:
        abort("No staged changes found. Please stage your changes first with: git add <files>")
    return files
