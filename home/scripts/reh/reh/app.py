from __future__ import annotations

import json
import os
import re
import shutil
import subprocess
import sys
import threading
import time
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path

from textual.app import App, ComposeResult
from textual.binding import Binding
from textual.containers import Container, Horizontal, Vertical
from textual.events import Key
from textual.reactive import reactive
from textual.widgets import DataTable, Header, Input, Static, TextArea
from textual.widgets.text_area import Selection

UUID_RE = re.compile(r"^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$")

STATE_DIR = Path.home() / ".local" / "state" / "reh"
LOG_PATH = STATE_DIR / "reh.log"


@dataclass(frozen=True)
class SessionRecord:
    tool: str
    session_id: str
    cwd: str
    project: str
    transcript_path: str
    updated_at: float

    @property
    def search_text(self) -> str:
        return " ".join(
            [
                self.tool,
                self.session_id,
                self.project,
                self.cwd,
                self.transcript_path,
            ]
        ).lower()


@dataclass(frozen=True)
class LaunchSpec:
    command: list[str]
    tool: str
    session_id: str


class RehDataTable(DataTable):
    BINDINGS = []


class RehTextArea(TextArea):
    BINDINGS = []


class RehInput(Input):
    BINDINGS = []


def log_event(message: str) -> None:
    try:
        STATE_DIR.mkdir(parents=True, exist_ok=True)
        with LOG_PATH.open("a", encoding="utf-8") as handle:
            timestamp = datetime.now().astimezone().isoformat(timespec="seconds")
            handle.write(f"[{timestamp}] {message}\n")
    except OSError:
        pass


def _home_path(path: str) -> str:
    home = str(Path.home())
    if path == home:
        return "~"
    if path.startswith(home + "/"):
        return "~/" + path[len(home) + 1 :]
    return path


def _project_name(cwd: str) -> str:
    stripped = cwd.rstrip("/")
    if not stripped:
        return cwd
    return Path(stripped).name or stripped


def _age_label(timestamp: float) -> str:
    now = datetime.now(timezone.utc).timestamp()
    delta = max(0, int(now - timestamp))
    if delta < 60:
        return f"{delta}s"
    if delta < 3600:
        return f"{delta // 60}m"
    if delta < 86400:
        return f"{delta // 3600}h"
    if delta < 86400 * 30:
        return f"{delta // 86400}d"
    return f"{delta // (86400 * 30)}mo"


def _is_uuid(value: str) -> bool:
    return bool(UUID_RE.match(value))


def load_codex_sessions() -> list[SessionRecord]:
    base = Path.home() / ".codex" / "sessions"
    sessions: dict[str, SessionRecord] = {}
    if not base.exists():
        return []

    for path in sorted(base.glob("**/*.jsonl")):
        try:
            with path.open("r", encoding="utf-8") as handle:
                first_line = handle.readline()
            if not first_line:
                continue
            entry = json.loads(first_line)
            payload = entry.get("payload", {})
            if entry.get("type") != "session_meta":
                continue
            session_id = payload.get("id")
            cwd = payload.get("cwd")
            if not isinstance(session_id, str) or not _is_uuid(session_id):
                continue
            if not isinstance(cwd, str) or not cwd:
                continue
            updated_at = path.stat().st_mtime
            record = SessionRecord(
                tool="codex",
                session_id=session_id,
                cwd=cwd,
                project=_project_name(cwd),
                transcript_path=str(path),
                updated_at=updated_at,
            )
            existing = sessions.get(session_id)
            if existing is None or record.updated_at > existing.updated_at:
                sessions[session_id] = record
        except (OSError, json.JSONDecodeError):
            continue

    return sorted(sessions.values(), key=lambda record: record.updated_at, reverse=True)


def _extract_claude_cwd(path: Path) -> str | None:
    try:
        with path.open("r", encoding="utf-8") as handle:
            for _ in range(40):
                line = handle.readline()
                if not line:
                    break
                match = re.search(r'"cwd":"([^"]+)"', line)
                if match:
                    return match.group(1)
    except OSError:
        return None
    return None


def load_claude_sessions() -> list[SessionRecord]:
    base = Path.home() / ".claude" / "projects"
    sessions: dict[str, SessionRecord] = {}
    if not base.exists():
        return []

    for path in sorted(base.glob("*/*.jsonl")):
        session_id = path.stem
        if not _is_uuid(session_id):
            continue
        cwd = _extract_claude_cwd(path)
        if not cwd:
            continue
        try:
            updated_at = path.stat().st_mtime
        except OSError:
            continue
        record = SessionRecord(
            tool="claude",
            session_id=session_id,
            cwd=cwd,
            project=_project_name(cwd),
            transcript_path=str(path),
            updated_at=updated_at,
        )
        existing = sessions.get(session_id)
        if existing is None or record.updated_at > existing.updated_at:
            sessions[session_id] = record

    return sorted(sessions.values(), key=lambda record: record.updated_at, reverse=True)


def load_sessions() -> list[SessionRecord]:
    sessions = load_codex_sessions() + load_claude_sessions()
    log_event(
        f"loaded sessions total={len(sessions)} codex={sum(1 for s in sessions if s.tool == 'codex')} claude={sum(1 for s in sessions if s.tool == 'claude')}"
    )
    return sorted(sessions, key=lambda record: record.updated_at, reverse=True)


def _clean_preview_text(text: str) -> str:
    flattened = " ".join(text.split())
    return flattened[:240] + ("..." if len(flattened) > 240 else "")


def _extract_codex_user_texts(path: Path) -> list[str]:
    messages: list[str] = []
    seen: set[str] = set()
    try:
        with path.open("r", encoding="utf-8") as handle:
            for line in handle:
                line = line.strip()
                if not line:
                    continue
                try:
                    entry = json.loads(line)
                except json.JSONDecodeError:
                    continue

                entry_type = entry.get("type")
                if entry_type == "event_msg":
                    payload = entry.get("payload", {})
                    if payload.get("type") != "user_message":
                        continue
                    text = payload.get("message")
                    if isinstance(text, str):
                        cleaned = _clean_preview_text(text)
                        if cleaned and cleaned not in seen:
                            messages.append(cleaned)
                            seen.add(cleaned)
                elif entry_type == "response_item":
                    payload = entry.get("payload", {})
                    if (
                        payload.get("type") != "message"
                        or payload.get("role") != "user"
                    ):
                        continue
                    content = payload.get("content", [])
                    if not isinstance(content, list):
                        continue
                    for block in content:
                        if not isinstance(block, dict):
                            continue
                        if block.get("type") != "input_text":
                            continue
                        text = block.get("text")
                        if isinstance(text, str):
                            cleaned = _clean_preview_text(text)
                            if cleaned and cleaned not in seen:
                                messages.append(cleaned)
                                seen.add(cleaned)
    except OSError:
        return []
    return messages[-10:]


def _extract_claude_texts_from_content(content: object) -> list[str]:
    texts: list[str] = []
    if isinstance(content, str):
        texts.append(content)
    elif isinstance(content, list):
        for block in content:
            if not isinstance(block, dict):
                continue
            if block.get("type") != "text":
                continue
            text = block.get("text")
            if isinstance(text, str):
                texts.append(text)
    return texts


def _extract_claude_user_texts(path: Path) -> list[str]:
    messages: list[str] = []
    try:
        with path.open("r", encoding="utf-8") as handle:
            for line in handle:
                line = line.strip()
                if (
                    not line
                    or '"type":"user"' not in line
                    and '"type": "user"' not in line
                ):
                    continue
                try:
                    entry = json.loads(line)
                except json.JSONDecodeError:
                    continue
                if entry.get("type") != "user":
                    continue
                if entry.get("isMeta") is True:
                    continue
                message = entry.get("message")
                if not isinstance(message, dict):
                    continue
                for text in _extract_claude_texts_from_content(message.get("content")):
                    cleaned = _clean_preview_text(text)
                    if cleaned:
                        messages.append(cleaned)
    except OSError:
        return []
    return messages[-10:]


def load_recent_user_messages(record: SessionRecord) -> list[str]:
    path = Path(record.transcript_path)
    if record.tool == "codex":
        return _extract_codex_user_texts(path)
    return _extract_claude_user_texts(path)


def _dedupe_lines(lines: list[str]) -> list[str]:
    deduped: list[str] = []
    previous = None
    for line in lines:
        if line == previous:
            continue
        deduped.append(line)
        previous = line
    return deduped


def load_transcript_lines(record: SessionRecord) -> list[str]:
    path = Path(record.transcript_path)
    lines: list[str] = []
    try:
        with path.open("r", encoding="utf-8") as handle:
            for raw_line in handle:
                raw_line = raw_line.strip()
                if not raw_line:
                    continue
                try:
                    entry = json.loads(raw_line)
                except json.JSONDecodeError:
                    continue

                if record.tool == "codex":
                    entry_type = entry.get("type")
                    if entry_type == "event_msg":
                        payload = entry.get("payload", {})
                        message_type = payload.get("type")
                        if message_type == "user_message":
                            text = payload.get("message")
                            if isinstance(text, str) and text.strip():
                                lines.append(f"user> {_clean_preview_text(text)}")
                        elif message_type == "agent_reasoning":
                            text = payload.get("text")
                            if isinstance(text, str) and text.strip():
                                lines.append(f"assistant> {_clean_preview_text(text)}")
                    elif entry_type == "response_item":
                        payload = entry.get("payload", {})
                        if payload.get("type") != "message":
                            continue
                        role = payload.get("role")
                        if role not in {"user", "assistant"}:
                            continue
                        content = payload.get("content", [])
                        if not isinstance(content, list):
                            continue
                        texts: list[str] = []
                        for block in content:
                            if not isinstance(block, dict):
                                continue
                            text = block.get("text")
                            if block.get("type") in {
                                "input_text",
                                "output_text",
                            } and isinstance(text, str):
                                texts.append(text)
                        for text in texts:
                            if text.strip():
                                lines.append(f"{role}> {_clean_preview_text(text)}")
                else:
                    message_type = entry.get("type")
                    if message_type not in {"user", "assistant"}:
                        continue
                    if entry.get("isMeta") is True:
                        continue
                    message = entry.get("message")
                    if not isinstance(message, dict):
                        continue
                    for text in _extract_claude_texts_from_content(
                        message.get("content")
                    ):
                        if text.strip():
                            lines.append(f"{message_type}> {_clean_preview_text(text)}")
    except OSError:
        return []

    return _dedupe_lines(lines)


class RehApp(App[None]):
    TITLE = "reh"
    SUB_TITLE = "Resume Codex and Claude sessions"
    CSS = """
    Screen {
        layout: vertical;
    }

    #status {
        height: 1;
        padding: 0 1;
    }

    #helpbar {
        height: 1;
        padding: 0 1;
    }

    #search-row {
        display: none;
        height: 1;
        padding: 0 1;
        background: $surface;
    }

    #search-row.show {
        display: block;
    }

    #body {
        height: 1fr;
    }

    #table-pane {
        width: 3fr;
        margin: 0 1 1 1;
    }

    #details {
        width: 2fr;
        margin: 0 1 1 0;
        padding: 0 1;
        border: solid $panel;
    }

    #search {
        width: 100%;
        height: 1;
        min-height: 1;
        border: none;
        padding: 0;
        margin: 0;
        background: transparent;
    }

    #debug-overlay {
        display: none;
        layer: overlay;
        dock: bottom;
        width: 1fr;
        height: auto;
        padding: 0 1;
        background: $surface;
        border-top: solid $panel;
    }

    #debug-overlay.show {
        display: block;
    }
    """

    BINDINGS = [
        Binding("q", "quit", "Quit"),
        Binding("/", "focus_search", "Search"),
        Binding("escape", "handle_escape", "Back"),
        Binding("g", "handle_g", "Top", show=False),
        Binding("G", "goto_end", "End", show=False),
        Binding("1", "set_filter('all')", "All"),
        Binding("2", "set_filter('codex')", "Codex"),
        Binding("3", "set_filter('claude')", "Claude"),
        Binding("h", "toggle_happy", "Happy", show=False),
        Binding("f12", "toggle_debug_overlay", "Debug", show=False),
        Binding("r", "reload_sessions", "Reload"),
        Binding("enter", "resume_selected", "Resume"),
        Binding("j", "cursor_down", "Down", show=False),
        Binding("k", "cursor_up", "Up", show=False),
        Binding("l", "focus_or_move_right", "Details", show=False),
        Binding("ctrl+l", "focus_or_move_right", "Details", show=False),
        Binding("backspace", "toggle_happy", "Happy", show=False),
        Binding("w", "cursor_word_forward", "Word Forward", show=False),
        Binding("e", "cursor_word_end", "Word End", show=False),
        Binding("b", "cursor_word_back", "Word Back", show=False),
        Binding("v", "toggle_visual_mode", "Visual", show=False),
        Binding("V", "select_detail_line", "Line Visual", show=False),
        Binding("y", "handle_yank", "Yank", show=False),
        Binding("n", "detail_next_match", "Next Match", show=False),
        Binding("p", "detail_prev_match", "Prev Match", show=False),
    ]

    filter_mode = reactive("all")
    happy_mode = reactive(False)
    search_text = reactive("")

    def __init__(self) -> None:
        super().__init__()
        self.all_sessions: list[SessionRecord] = []
        self.visible_sessions: list[SessionRecord] = []
        self.selection: LaunchSpec | None = None
        self.preview_cache: dict[str, list[str]] = {}
        self.search_target = "sessions"
        self.detail_search_text = ""
        self.detail_search_matches: list[tuple[int, int]] = []
        self.detail_search_index = -1
        self.search_origin = "table"
        self.g_pending = False
        self.g_pending_at = 0.0
        self.debug_overlay_visible = False
        self.last_key_debug = "no key events yet"
        self.visual_anchor: tuple[int, int] | None = None
        self.y_pending = False
        self.y_pending_at = 0.0
        self.transcript_preview_cache: dict[str, str] = {}
        self.loaded_transcript_session_id: str | None = None
        self.loaded_transcript_text: str = ""

    def compose(self) -> ComposeResult:
        yield Header(show_clock=False)
        yield Static(id="status")
        with Horizontal(id="body"):
            with Vertical(id="table-pane"):
                yield RehDataTable(id="table", cursor_type="row")
            yield RehTextArea("", id="details", read_only=True)
        with Container(id="search-row"):
            yield RehInput(placeholder="Search", id="search")
        yield Static(id="helpbar")
        yield Static(id="debug-overlay")

    def on_mount(self) -> None:
        table = self.query_one("#table", DataTable)
        table.zebra_stripes = True
        table.add_columns("Tool", "Project", "Age", "Session")
        self.query_one("#table", DataTable).focus()
        self.update_search_placeholder()
        self.reload_data()
        self.refresh_chrome()
        self.refresh_debug_overlay()

    def on_key(self, event: Key) -> None:
        self.last_key_debug = (
            f"key={event.key!r} "
            f"character={event.character!r} "
            f"name={getattr(event, 'name', None)!r} "
            f"is_printable={getattr(event, 'is_printable', None)!r}"
        )
        log_event(f"key event {self.last_key_debug}")
        self.refresh_debug_overlay()
        if event.key == "backspace" and self.focused and self.focused.id == "details":
            log_event("intercepted backspace in details view")
            self.action_back_to_list()
            event.stop()
            return

    def action_focus_search(self) -> None:
        if self.focused and self.focused.id == "details":
            self.search_target = "details"
            self.search_origin = "details"
        else:
            self.search_target = "sessions"
            self.search_origin = "table"
        search = self.query_one("#search", Input)
        search.value = (
            self.detail_search_text
            if self.search_target == "details"
            else self.search_text
        )
        self.update_search_placeholder()
        self.show_search_modal(True)
        search.focus()

    def action_handle_escape(self) -> None:
        if self.focused and self.focused.id == "search":
            self.close_search_modal()
            return
        if self.focused and self.focused.id == "details":
            details = self.query_one("#details", TextArea)
            if self.visual_anchor is not None or details.selected_text:
                details.selection = Selection.cursor(details.selection.end)
                self.visual_anchor = None
                self.sync_visual_selection()
                return
            self.query_one("#table", DataTable).focus()
            self.refresh_chrome_later()
            return

    def action_handle_g(self) -> None:
        now = time.monotonic()
        if self.g_pending and now - self.g_pending_at <= 0.6:
            self.g_pending = False
            self.goto_start()
            return
        self.g_pending = True
        self.g_pending_at = now

    def action_goto_end(self) -> None:
        self.g_pending = False
        if self.focused and self.focused.id == "details":
            self.goto_detail_end()
            return
        self.goto_table_end()

    def action_set_filter(self, mode: str) -> None:
        self.g_pending = False
        self.filter_mode = mode
        self.refresh_table()

    def action_toggle_happy(self) -> None:
        if self.focused and self.focused.id == "details":
            self.action_back_to_list()
            return
        self.g_pending = False
        if not self.happy_mode and shutil.which("happy") is None:
            log_event("happy toggle failed: happy not on PATH")
            self.set_status("happy mode unavailable: `happy` is not on PATH")
            return
        self.happy_mode = not self.happy_mode
        log_event(f"happy mode toggled={self.happy_mode}")
        self.refresh_status()
        self.refresh_details()

    def action_back_to_list(self) -> None:
        if self.focused and self.focused.id == "details":
            self.query_one("#table", DataTable).focus()
            self.refresh_chrome_later()

    def action_reload_sessions(self) -> None:
        self.g_pending = False
        self.reload_data()

    def action_toggle_debug_overlay(self) -> None:
        self.debug_overlay_visible = not self.debug_overlay_visible
        self.refresh_debug_overlay()

    def action_resume_selected(self) -> None:
        self.g_pending = False
        record = self.current_record()
        if record is None:
            log_event("resume requested with no selection")
            self.set_status("no session selected")
            return

        command = self.build_launch_command(record)
        if command is None:
            log_event(
                f"resume build failed tool={record.tool} session={record.session_id}"
            )
            return

        log_event(
            f"resume selected tool={record.tool} session={record.session_id} command={' '.join(command)}"
        )
        self.selection = LaunchSpec(
            command=command, tool=record.tool, session_id=record.session_id
        )
        self.exit()

    def action_cursor_down(self) -> None:
        self.g_pending = False
        if self.focused and self.focused.id == "details":
            details = self.query_one("#details", TextArea)
            details.action_cursor_down(select=self.visual_anchor is not None)
            self.sync_visual_selection()
            return
        self.visual_anchor = None
        self.query_one("#table", DataTable).action_cursor_down()

    def action_cursor_up(self) -> None:
        self.g_pending = False
        if self.focused and self.focused.id == "details":
            details = self.query_one("#details", TextArea)
            details.action_cursor_up(select=self.visual_anchor is not None)
            self.sync_visual_selection()
            return
        self.visual_anchor = None
        self.query_one("#table", DataTable).action_cursor_up()

    def action_focus_or_move_right(self) -> None:
        self.g_pending = False
        if self.focused and self.focused.id == "details":
            details = self.query_one("#details", TextArea)
            details.action_cursor_right()
            self.sync_visual_selection()
            return
        self.query_one("#details", TextArea).focus()
        self.refresh_chrome_later()

    def action_cursor_word_forward(self) -> None:
        self.g_pending = False
        if self.focused and self.focused.id == "details":
            details = self.query_one("#details", TextArea)
            action = getattr(details, "action_cursor_word_right", None)
            if callable(action):
                action()
            else:
                details.action_cursor_right()
            self.sync_visual_selection()

    def action_cursor_word_back(self) -> None:
        self.g_pending = False
        if self.focused and self.focused.id == "details":
            details = self.query_one("#details", TextArea)
            action = getattr(details, "action_cursor_word_left", None)
            if callable(action):
                action()
            else:
                details.action_cursor_left()
            self.sync_visual_selection()

    def action_cursor_word_end(self) -> None:
        self.g_pending = False
        if self.focused and self.focused.id != "details":
            return
        details = self.query_one("#details", TextArea)
        offset = self.location_to_offset(details.text, details.selection.end)
        text = details.text
        length = len(text)
        if length == 0:
            return
        if (
            offset < length
            and text[offset].isalnum()
            and offset + 1 < length
            and text[offset + 1].isalnum()
        ):
            while offset + 1 < length and text[offset + 1].isalnum():
                offset += 1
        else:
            if offset < length - 1:
                offset += 1
            while offset < length and not text[offset].isalnum():
                offset += 1
            while offset + 1 < length and text[offset + 1].isalnum():
                offset += 1
        location = self.offset_to_location(text, offset)
        details.selection = Selection(
            self.visual_anchor if self.visual_anchor is not None else location,
            location,
        )
        self.sync_visual_selection()

    def action_toggle_visual_mode(self) -> None:
        if self.focused and self.focused.id != "details":
            return
        details = self.query_one("#details", TextArea)
        if self.visual_anchor is None:
            self.visual_anchor = details.selection.end
        else:
            details.selection = Selection.cursor(details.selection.end)
            self.visual_anchor = None
        self.sync_visual_selection()

    def action_select_detail_line(self) -> None:
        if self.focused and self.focused.id != "details":
            return
        details = self.query_one("#details", TextArea)
        line = details.selection.end[0]
        details.select_line(line)
        self.visual_anchor = details.selection.start
        self.sync_visual_selection()

    def action_handle_yank(self) -> None:
        if self.focused and self.focused.id != "details":
            return
        details = self.query_one("#details", TextArea)
        if self.visual_anchor is not None or details.selected_text:
            self.copy_with_status(details.selected_text or details.text, "YANKED!")
            details.selection = Selection.cursor(details.selection.end)
            self.visual_anchor = None
            self.y_pending = False
            return
        now = time.monotonic()
        if self.y_pending and now - self.y_pending_at <= 0.6:
            details.select_line(details.selection.end[0])
            self.copy_with_status(details.selected_text or details.text, "YANKED!")
            details.selection = Selection.cursor(details.selection.end)
            self.visual_anchor = None
            self.y_pending = False
            return
        self.y_pending = True
        self.y_pending_at = now

    def action_detail_next_match(self) -> None:
        self.g_pending = False
        self.step_detail_match(1)

    def action_detail_prev_match(self) -> None:
        self.g_pending = False
        self.step_detail_match(-1)

    def on_input_changed(self, event: Input.Changed) -> None:
        if event.input.id != "search":
            return
        if self.search_target == "details":
            self.detail_search_text = event.value
            self.refresh_detail_search()
        else:
            self.search_text = event.value
            self.refresh_table()

    def on_data_table_row_highlighted(self, _: DataTable.RowHighlighted) -> None:
        self.g_pending = False
        self.visual_anchor = None
        self.refresh_details()

    def on_data_table_row_selected(self, _: DataTable.RowSelected) -> None:
        log_event("datatable row selected via widget event")
        self.action_resume_selected()

    def on_input_submitted(self, event: Input.Submitted) -> None:
        if event.input.id != "search":
            return
        self.close_search_modal()

    def reload_data(self) -> None:
        self.all_sessions = load_sessions()
        self.preview_cache.clear()
        self.transcript_preview_cache.clear()
        self.visual_anchor = None
        self.loaded_transcript_session_id = None
        self.loaded_transcript_text = ""
        self.refresh_table()

    def filtered_sessions(self) -> list[SessionRecord]:
        sessions = self.all_sessions
        if self.filter_mode != "all":
            sessions = [
                record for record in sessions if record.tool == self.filter_mode
            ]
        needle = self.search_text.strip().lower()
        if needle:
            sessions = [record for record in sessions if needle in record.search_text]
        return sessions

    def refresh_table(self) -> None:
        table = self.query_one("#table", DataTable)
        current = self.current_record()
        self.visible_sessions = self.filtered_sessions()
        table.clear()
        for record in self.visible_sessions:
            table.add_row(
                record.tool,
                record.project,
                _age_label(record.updated_at),
                record.session_id,
                key=record.session_id,
            )

        if self.visible_sessions:
            target_id = (
                current.session_id if current else self.visible_sessions[0].session_id
            )
            for index, record in enumerate(self.visible_sessions):
                if record.session_id == target_id:
                    table.move_cursor(row=index)
                    break
        self.refresh_status()
        self.refresh_details()

    def refresh_status(self) -> None:
        happy_label = "on" if self.happy_mode else "off"
        happy_state = "ready" if shutil.which("happy") else "missing"
        mode = "details" if self.focused and self.focused.id == "details" else "table"
        status = (
            f"mode={mode}  filter={self.filter_mode}  happy={happy_label}({happy_state})  search={self.search_target}  "
            f"sessions={len(self.visible_sessions)}/{len(self.all_sessions)}"
        )
        self.query_one("#status", Static).update(status)

    def set_status(self, text: str) -> None:
        self.query_one("#status", Static).update(text)

    def current_record(self) -> SessionRecord | None:
        table = self.query_one("#table", DataTable)
        if not self.visible_sessions:
            return None
        coordinate = table.cursor_coordinate
        if coordinate.row < 0 or coordinate.row >= len(self.visible_sessions):
            return None
        return self.visible_sessions[coordinate.row]

    def build_launch_command(self, record: SessionRecord) -> list[str] | None:
        if self.happy_mode:
            happy_path = shutil.which("happy")
            if happy_path is None:
                self.set_status("cannot launch: `happy` is not on PATH")
                return None
            log_event(f"resolved happy path={happy_path}")
            return [happy_path, record.tool, "resume", record.session_id]

        base = "codex" if record.tool == "codex" else "claude"
        base_path = shutil.which(base)
        if base_path is None:
            self.set_status(f"cannot launch: `{base}` is not on PATH")
            return None
        log_event(f"resolved {base} path={base_path}")
        return [
            base_path,
            "resume" if base == "codex" else "--resume",
            record.session_id,
        ]

    def refresh_details(self) -> None:
        details = self.query_one("#details", TextArea)
        record = self.current_record()
        if record is None:
            details.load_text("No sessions found.")
            self.detail_search_matches = []
            self.detail_search_index = -1
            self.visual_anchor = None
            self.loaded_transcript_session_id = None
            self.loaded_transcript_text = ""
            return

        command = self.preview_command(record)
        updated = (
            datetime.fromtimestamp(record.updated_at)
            .astimezone()
            .strftime("%Y-%m-%d %H:%M:%S")
        )
        is_detail_focus = self.focused and self.focused.id == "details"
        if is_detail_focus:
            transcript_text = self.load_full_transcript(record)
        else:
            transcript_text = self.load_preview_transcript(record)
        details.load_text(
            "\n".join(
                [
                    f"tool:        {record.tool}",
                    f"project:     {record.project}",
                    f"cwd:         {_home_path(record.cwd)}",
                    f"updated:     {updated}",
                    f"session:     {record.session_id}",
                    # f"transcript:  {_home_path(record.transcript_path)}",
                    "",
                    f"launch:      {command}",
                    "",
                    self.format_transcript_text(
                        transcript_text or "(no transcript text found)"
                    ),
                ]
            )
        )
        self.refresh_detail_search()

    def preview_command(self, record: SessionRecord) -> str:
        if self.happy_mode:
            if shutil.which("happy") is None:
                return "happy missing"
            return f"happy {record.tool} resume {record.session_id}"
        base = "codex" if record.tool == "codex" else "claude"
        if shutil.which(base) is None:
            return f"{base} missing"
        command = [base, "resume" if base == "codex" else "--resume", record.session_id]
        return " ".join(command)

    def update_search_placeholder(self) -> None:
        search = self.query_one("#search", Input)
        if self.search_target == "details":
            search.placeholder = "Search details"
        else:
            search.placeholder = "Filter sessions"
        self.refresh_helpbar()

    def refresh_detail_search(self) -> None:
        details = self.query_one("#details", TextArea)
        query = self.detail_search_text.strip().lower()
        if not query:
            self.detail_search_matches = []
            self.detail_search_index = -1
            return
        text = details.text
        haystack = text.lower()
        matches: list[tuple[int, int]] = []
        start = 0
        while True:
            idx = haystack.find(query, start)
            if idx == -1:
                break
            matches.append((idx, idx + len(query)))
            start = idx + max(1, len(query))
        self.detail_search_matches = matches
        self.detail_search_index = 0 if matches else -1
        self.apply_detail_match_selection()

    def step_detail_match(self, direction: int) -> None:
        if not self.detail_search_matches:
            return
        self.detail_search_index = (self.detail_search_index + direction) % len(
            self.detail_search_matches
        )
        self.apply_detail_match_selection()

    def apply_detail_match_selection(self) -> None:
        if not self.detail_search_matches or self.detail_search_index < 0:
            return
        details = self.query_one("#details", TextArea)
        start, end = self.detail_search_matches[self.detail_search_index]
        start_pos = self.offset_to_location(details.text, start)
        end_pos = self.offset_to_location(details.text, end)
        details.selection = Selection(start_pos, end_pos)
        details.scroll_cursor_visible()

    def offset_to_location(self, text: str, offset: int) -> tuple[int, int]:
        lines = text.splitlines(keepends=True)
        consumed = 0
        for line_index, line in enumerate(lines):
            next_consumed = consumed + len(line)
            if offset < next_consumed:
                return (line_index, offset - consumed)
            consumed = next_consumed
        if lines:
            last = lines[-1].rstrip("\n")
            return (len(lines) - 1, len(last))
        return (0, 0)

    def goto_start(self) -> None:
        if self.focused and self.focused.id == "details":
            self.goto_detail_start()
            return
        self.goto_table_start()

    def goto_table_start(self) -> None:
        table = self.query_one("#table", DataTable)
        if self.visible_sessions:
            table.move_cursor(row=0)

    def goto_table_end(self) -> None:
        table = self.query_one("#table", DataTable)
        if self.visible_sessions:
            table.move_cursor(row=len(self.visible_sessions) - 1)

    def goto_detail_start(self) -> None:
        details = self.query_one("#details", TextArea)
        location = (0, 0)
        details.selection = Selection(
            self.visual_anchor if self.visual_anchor is not None else location,
            location,
        )
        self.sync_visual_selection()

    def goto_detail_end(self) -> None:
        details = self.query_one("#details", TextArea)
        lines = details.text.splitlines()
        if not lines:
            location = (0, 0)
        else:
            location = (len(lines) - 1, len(lines[-1]))
        details.selection = Selection(
            self.visual_anchor if self.visual_anchor is not None else location,
            location,
        )
        self.sync_visual_selection()

    def show_search_modal(self, visible: bool) -> None:
        row = self.query_one("#search-row", Container)
        row.set_class(visible, "show")
        self.refresh_helpbar()

    def close_search_modal(self) -> None:
        self.show_search_modal(False)
        if self.search_origin == "details":
            self.query_one("#details", TextArea).focus()
        else:
            self.query_one("#table", DataTable).focus()
        self.refresh_chrome_later()

    def refresh_helpbar(self) -> None:
        focused = self.focused.id if self.focused and self.focused.id else ""
        if focused == "search":
            if self.search_target == "details":
                text = "h/backspace list  j/k move  l right  w/e/b word  v/V select  y/yy yank  gg top  G end  / search  n/p match  ^p palette  f12 debug"
            else:
                text = "enter resume  l details  j/k move  gg top  G end  1/2/3 filter  h happy  / search  r reload  ^p palette  f12 debug"
        elif focused == "details":
            text = "h/backspace list  j/k move  l right  w/e/b word  v/V select  y/yy yank  gg top  G end  / search  n/p match  ^p palette  f12 debug"
        else:
            text = "enter resume  l details  j/k move  gg top  G end  1/2/3 filter  h happy  / search  r reload  ^p palette  f12 debug"
        self.query_one("#helpbar", Static).update(text)

    def refresh_chrome(self) -> None:
        self.refresh_status()
        self.refresh_helpbar()

    def refresh_chrome_later(self) -> None:
        self.call_after_refresh(self.refresh_chrome)

    def sync_visual_selection(self) -> None:
        details = self.query_one("#details", TextArea)
        if self.visual_anchor is not None:
            details.selection = Selection(self.visual_anchor, details.selection.end)
        details.scroll_cursor_visible()

    def location_to_offset(self, text: str, location: tuple[int, int]) -> int:
        row, column = location
        lines = text.splitlines(keepends=True)
        if not lines:
            return 0
        row = max(0, min(row, len(lines) - 1))
        offset = sum(len(line) for line in lines[:row])
        column = max(0, min(column, len(lines[row].rstrip("\n"))))
        return offset + column

    def load_preview_transcript(self, record: SessionRecord) -> str:
        cached = self.transcript_preview_cache.get(record.session_id)
        if cached is not None:
            if self.loaded_transcript_session_id != record.session_id:
                self.loaded_transcript_text = ""
                self.loaded_transcript_session_id = None
            return cached
        lines = load_transcript_lines(record)
        preview = "\n".join(lines[:40])
        self.transcript_preview_cache[record.session_id] = preview
        if self.loaded_transcript_session_id != record.session_id:
            self.loaded_transcript_text = ""
            self.loaded_transcript_session_id = None
        return preview

    def load_full_transcript(self, record: SessionRecord) -> str:
        if (
            self.loaded_transcript_session_id == record.session_id
            and self.loaded_transcript_text
        ):
            return self.loaded_transcript_text
        self.loaded_transcript_session_id = record.session_id
        self.loaded_transcript_text = "\n".join(load_transcript_lines(record))
        return self.loaded_transcript_text

    def format_transcript_text(self, raw: str) -> str:
        env_end = raw.find("</environment_context>")
        if env_end != -1:
            env_block = raw[: env_end + len("</environment_context>")].strip()
            rest = raw[env_end + len("</environment_context>") :].strip()
        else:
            env_block = ""
            rest = raw.strip()

        # Add 2 empty lines only when speaker changes user <-> assistant.
        lines = rest.splitlines()
        out: list[str] = []
        prev_speaker: str | None = None

        for line in lines:
            stripped = line.lstrip()
            speaker = None

            if stripped.startswith("user>"):
                speaker = "user"
            elif stripped.startswith("assistant>"):
                speaker = "assistant"

            if speaker and prev_speaker and speaker != prev_speaker:
                while out and out[-1] == "":
                    out.pop()
                out.extend(["", ""])

            out.append(line)

            if speaker:
                prev_speaker = speaker

        normal_transcript = "\n".join(out).strip()

        if env_block:
            return "\n".join(
                [
                    "environment context:",
                    env_block,
                    "",
                    "",
                    "transcript:",
                    normal_transcript or "(no transcript text found)",
                ]
            )

        return normal_transcript

    def copy_with_status(self, text: str, success_message: str) -> None:
        self.query_one("#status", Static).update("copying...")

        def worker() -> None:
            try:
                self.copy_text(text)
            except RuntimeError as exc:
                self.call_from_thread(
                    self.query_one("#status", Static).update,
                    f"clipboard failed: {exc}",
                )
                return
            self.call_from_thread(
                self.query_one("#status", Static).update,
                success_message,
            )

        threading.Thread(target=worker, daemon=True).start()

    def copy_text(self, text: str) -> None:
        failures: list[str] = []
        if shutil.which("wl-copy"):
            self.spawn_clipboard_owner(["wl-copy"], text)
            return
        for command in (
            ["xclip", "-selection", "clipboard"],
            ["xsel", "--clipboard", "--input"],
        ):
            if not shutil.which(command[0]):
                continue
            try:
                self.spawn_clipboard_owner(command, text)
                return
            except RuntimeError as exc:
                failures.append(str(exc))
        try:
            self.copy_to_clipboard(text)
            return
        except Exception as exc:
            failures.append(f"textual clipboard failed: {exc}")
        raise RuntimeError(
            "; ".join(failures) if failures else "no clipboard command available"
        )

    def spawn_clipboard_owner(self, command: list[str], text: str) -> None:
        try:
            process = subprocess.Popen(
                command,
                stdin=subprocess.PIPE,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                text=True,
                start_new_session=True,
            )
        except OSError as exc:
            raise RuntimeError(f"{command[0]} spawn failed: {exc}") from exc
        if process.stdin is None:
            raise RuntimeError(f"{command[0]} has no stdin")
        try:
            process.stdin.write(text)
            process.stdin.close()
        except OSError as exc:
            raise RuntimeError(f"{command[0]} write failed: {exc}") from exc

    def refresh_debug_overlay(self) -> None:
        overlay = self.query_one("#debug-overlay", Static)
        overlay.set_class(self.debug_overlay_visible, "show")
        overlay.update(
            "debug keys: press a key to inspect terminal input  |  "
            + self.last_key_debug
        )


def launch_selection(selection: LaunchSpec | None) -> int:
    if selection is None:
        log_event("launch skipped: no selection")
        return 0
    try:
        log_event(f"exec start command={' '.join(selection.command)}")
        os.execv(selection.command[0], selection.command)
    except FileNotFoundError as exc:
        log_event(f"exec failed not found: {selection.command[0]} error={exc}")
        print(f"reh: command not found: {selection.command[0]}", file=sys.stderr)
        return 127
    except OSError as exc:
        log_event(
            f"exec failed os error: command={' '.join(selection.command)} error={exc}"
        )
        print(
            f"reh: failed to launch {' '.join(selection.command)}: {exc}",
            file=sys.stderr,
        )
        return 127
    return 0
