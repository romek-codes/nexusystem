from __future__ import annotations

import os
import shlex
import subprocess
import tempfile
from pathlib import Path

import typer

from .console import abort


def commit_with_message(message: str, no_verify: bool = False, amend: bool = False) -> None:
    args = ["commit"]
    if amend:
        args.append("--amend")
    if no_verify:
        args.append("--no-verify")
    args += ["-e", "-m", message]
    result = subprocess.run(["git", *args], check=False)
    if result.returncode != 0:
        raise typer.Exit(result.returncode)


def commit_via_editor_file(message: str, no_verify: bool = False, amend: bool = False) -> None:
    with tempfile.NamedTemporaryFile("w", delete=False, encoding="utf-8", suffix=".commitmsg") as tmp:
        tmp.write(message)
        tmp.write("\n")
        tmp_path = tmp.name

    try:
        args = ["commit", "-F", tmp_path, "-e"]
        if amend:
            args.insert(1, "--amend")
        if no_verify:
            args.insert(1, "--no-verify")
        result = subprocess.run(["git", *args], check=False)
        if result.returncode != 0:
            raise typer.Exit(result.returncode)
    finally:
        try:
            os.unlink(tmp_path)
        except FileNotFoundError:
            pass


def open_external_editor(initial_text: str) -> str:
    editor = os.getenv("VISUAL") or os.getenv("EDITOR")
    if not editor:
        abort("No editor configured. Set $VISUAL or $EDITOR, or use editor_mode=git.")

    with tempfile.NamedTemporaryFile("w", delete=False, encoding="utf-8", suffix=".txt") as tmp:
        tmp.write(initial_text)
        tmp.write("\n")
        tmp_path = tmp.name

    try:
        result = subprocess.run(shlex.split(editor) + [tmp_path], check=False)
        if result.returncode != 0:
            abort(f"Editor exited with code {result.returncode}")
        edited = Path(tmp_path).read_text(encoding="utf-8").strip()
        if not edited:
            abort("Edited commit message is empty")
        return edited
    finally:
        try:
            os.unlink(tmp_path)
        except FileNotFoundError:
            pass
