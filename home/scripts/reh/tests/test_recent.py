from __future__ import annotations

import json
import os
import subprocess
import tempfile
import unittest
from contextlib import redirect_stdout
from io import StringIO
from pathlib import Path
from unittest.mock import patch

from reh.app import recent_sessions
from reh.cli import parse_duration
from reh.recent import print_recent, reopen_recent


class RecentSessionsTest(unittest.TestCase):
    def setUp(self) -> None:
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.home = Path(self.temp.name)
        self.project = self.home / "project"
        self.project.mkdir()

    def add_codex(self, session_id: str, age: int) -> None:
        path = self.home / ".codex" / "sessions" / f"{session_id}.jsonl"
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(json.dumps({"type": "session_meta", "payload": {"id": session_id, "cwd": str(self.project)}}) + "\n")
        os.utime(path, (age, age))

    def test_recent_sorts_by_update_and_skips_current(self) -> None:
        old = "11111111-1111-1111-1111-111111111111"
        middle = "22222222-2222-2222-2222-222222222222"
        current = "33333333-3333-3333-3333-333333333333"
        self.add_codex(old, 100)
        self.add_codex(middle, 200)
        self.add_codex(current, 300)
        with patch("reh.app.Path.home", return_value=self.home), patch.dict(os.environ, {"CODEX_THREAD_ID": current}, clear=False):
            self.assertEqual([item.session_id for item in recent_sessions(2)], [middle, old])
            self.assertEqual([item.session_id for item in recent_sessions(2, include_current=True)], [current, middle])
            with patch("reh.app.time.time", return_value=300):
                self.assertEqual([item.session_id for item in recent_sessions(2, within_seconds=120)], [middle])

    def test_recent_shows_last_messages(self) -> None:
        session_id = "11111111-1111-1111-1111-111111111111"
        self.add_codex(session_id, 100)
        path = self.home / ".codex" / "sessions" / f"{session_id}.jsonl"
        with path.open("a") as handle:
            for role, message in [("user", "start"), ("assistant", "done"), ("user", "next step")]:
                handle.write(json.dumps({"type": "response_item", "payload": {"type": "message", "role": role, "content": [{"type": "input_text" if role == "user" else "output_text", "text": message}]}}) + "\n")
        output = StringIO()
        with patch("reh.app.Path.home", return_value=self.home), redirect_stdout(output):
            self.assertEqual(print_recent(1, message_count=2, as_json=True), 0)
        messages = json.loads(output.getvalue())[0]["last_messages"]
        self.assertEqual(messages, ["assistant> done", "user> next step"])

    def test_duration(self) -> None:
        self.assertEqual(parse_duration("24h"), 86400)

    def test_reopen_uses_separate_tmux_windows(self) -> None:
        first = "11111111-1111-1111-1111-111111111111"
        second = "22222222-2222-2222-2222-222222222222"
        self.add_codex(first, 100)
        self.add_codex(second, 200)
        with patch("reh.app.Path.home", return_value=self.home), patch.dict(os.environ, {"TMUX": "test", "TMUX_PANE": "%9"}, clear=False), patch("reh.recent.shutil.which", return_value="/bin/tmux"), patch("reh.recent.subprocess.run") as run:
            run.return_value = subprocess.CompletedProcess([], 0, stdout="$1\n")
            self.assertEqual(reopen_recent(2), 0)
        self.assertEqual(run.call_count, 3)
        self.assertEqual(run.call_args_list[0].args[0], ["tmux", "display-message", "-p", "-t", "%9", "#{session_id}"])
        commands = [call.args[0] for call in run.call_args_list[1:]]
        self.assertEqual([command[0:2] for command in commands], [["tmux", "new-window"], ["tmux", "new-window"]])
        self.assertEqual([command[4] for command in commands], ["$1", "$1"])
        self.assertIn(second, commands[0][-1])
        self.assertIn(first, commands[1][-1])


if __name__ == "__main__":
    unittest.main()
