from __future__ import annotations

import asyncio
import shutil
import subprocess
import threading
from dataclasses import dataclass

from textual.app import App, ComposeResult
from textual.binding import Binding
from textual.containers import Horizontal, Vertical
from textual.reactive import reactive
from textual.widgets import DataTable, Footer, Header, Input, Static, TextArea
from textual.widgets.text_area import Selection

from .data import PackageAuditError, PackageReportRow, default_host, load_cached_report, load_inventory, load_vulnerabilities, merge_report, sort_rows


@dataclass
class TuiState:
    host: str
    refresh: bool = False


class PackageAuditApp(App[None]):
    TITLE = "package-audit"
    CSS = """
    Screen {
        layout: vertical;
    }

    #status {
        height: 1;
        padding: 0 1;
    }

    #search {
        margin: 0 1;
    }

    #body {
        height: 1fr;
    }

    #table-pane {
        width: 2fr;
        margin: 0 1 1 1;
    }

    #details {
        width: 1fr;
        margin: 0 1 1 0;
        padding: 0 1;
        border: solid $panel;
        overflow-y: auto;
    }
    """

    BINDINGS = [
        Binding("q", "quit", "Quit"),
        Binding("/", "focus_search", "Search"),
        Binding("escape", "clear_search", "Clear"),
        Binding("s", "cycle_sort", "Sort"),
        Binding("r", "reload_data", "Reload"),
        Binding("l", "focus_right_pane", "Right Pane", show=False),
        Binding("h", "focus_left_pane", "Left Pane", show=False),
        Binding("v", "select_detail_line", "Select Line", show=False),
        Binding("V", "select_detail_line", "Select Line", show=False),
        Binding("y", "yank_details", "Yank", show=False),
        Binding("ctrl+y", "yank_details", "Yank"),
        Binding("j", "cursor_down", "Down", show=False),
        Binding("k", "cursor_up", "Up", show=False),
    ]

    filter_text = reactive("")
    sort_mode = reactive("severity")

    def __init__(self, state: TuiState) -> None:
        super().__init__()
        self.state = state
        self.rows: list[PackageReportRow] = []
        self.filtered_rows: list[PackageReportRow] = []
        self.visual_anchor: tuple[int, int] | None = None

    def compose(self) -> ComposeResult:
        yield Header(show_clock=False)
        yield Static(id="status")
        yield Input(placeholder="Press / to filter packages", id="search")
        with Horizontal(id="body"):
            with Vertical(id="table-pane"):
                yield DataTable(id="table", cursor_type="row")
            yield TextArea("Loading…", id="details", read_only=True)
        yield Footer()

    def on_mount(self) -> None:
        table = self.query_one("#table", DataTable)
        table.zebra_stripes = True
        table.add_columns("Package", "Version", "Src", "CVEs", "Max")
        cached_rows = load_cached_report(self.state.host)
        if cached_rows:
            self.rows = cached_rows
            self.refresh_table()
            self.query_one("#status", Static).update(
                f"host={self.state.host}  showing cached data  refreshing inventory..."
            )
            self.query_one("#details", TextArea).load_text("Showing cached report while refreshing data...")
        else:
            self.query_one("#status", Static).update(f"host={self.state.host}  loading inventory...")
            self.query_one("#details", TextArea).load_text("Loading package inventory...")
        self.query_one("#table", DataTable).focus()
        self.call_after_refresh(self._start_initial_load)

    def action_focus_search(self) -> None:
        self.query_one("#search", Input).focus()

    def action_focus_right_pane(self) -> None:
        self.query_one("#details", TextArea).focus()

    def action_focus_left_pane(self) -> None:
        self.query_one("#table", DataTable).focus()

    def action_select_detail_line(self) -> None:
        details = self.query_one("#details", TextArea)
        if self.focused and self.focused.id == "details":
            line = details.selection.end[0]
            details.select_line(line)
            self.visual_anchor = details.selection.start
            details.scroll_cursor_visible()
            self.query_one("#status", Static).update(
                f"host={self.state.host}  selected current detail line"
            )

    def action_yank_details(self) -> None:
        details = self.query_one("#details", TextArea)
        if not (self.focused and self.focused.id == "details"):
            self._copy_with_status(details.text, "copied selected package details")
            return

        if not details.selected_text:
            details.select_line(details.selection.end[0])
        self._copy_with_status(details.selected_text or details.text, "copied detail selection")

    def _copy_with_status(self, text: str, success_message: str) -> None:
        self.query_one("#status", Static).update(
            f"host={self.state.host}  copying..."
        )

        def worker() -> None:
            try:
                self.copy_text(text)
            except RuntimeError as exc:
                self.call_from_thread(
                    self.query_one("#status", Static).update,
                    f"host={self.state.host}  clipboard failed: {exc}",
                )
                return
            self.call_from_thread(
                self.query_one("#status", Static).update,
                f"host={self.state.host}  {success_message}",
            )

        threading.Thread(target=worker, daemon=True).start()

    def copy_text(self, text: str) -> None:
        failures: list[str] = []

        if shutil.which("wl-copy"):
            process = subprocess.Popen(
                ["wl-copy"],
                stdin=subprocess.PIPE,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.PIPE,
                text=True,
                start_new_session=True,
            )
            try:
                _, stderr = process.communicate(text, timeout=2)
            except subprocess.TimeoutExpired:
                process.kill()
                _, stderr = process.communicate()
                stderr = (stderr or "").strip()
                failures.append(f"wl-copy timeout{f' {stderr}' if stderr else ''}")
            else:
                if process.returncode == 0:
                    return
                stderr = (stderr or "").strip()
                failures.append(f"wl-copy exit={process.returncode}{f' {stderr}' if stderr else ''}")

        clipboard_commands = [
            ["xclip", "-selection", "clipboard"],
            ["xsel", "--clipboard", "--input"],
        ]

        for command in clipboard_commands:
            if not shutil.which(command[0]):
                continue
            try:
                result = subprocess.run(command, input=text, text=True, capture_output=True, timeout=2)
            except subprocess.TimeoutExpired:
                failures.append(f"{command[0]} timeout")
                continue
            if result.returncode == 0:
                return
            stderr = (result.stderr or "").strip()
            failures.append(f"{command[0]} exit={result.returncode}{f' {stderr}' if stderr else ''}")

        try:
            self.copy_to_clipboard(text)
            return
        except Exception as exc:
            failures.append(f"textual clipboard failed: {exc}")

        if failures:
            raise RuntimeError("; ".join(failures))
        raise RuntimeError("no clipboard command available")

    def action_clear_search(self) -> None:
        if self.focused and self.focused.id == "details":
            details = self.query_one("#details", TextArea)
            details.selection = Selection.cursor(details.selection.end)
            self.visual_anchor = None
            self.query_one("#status", Static).update(
                f"host={self.state.host}  cleared detail selection"
            )
            return
        search = self.query_one("#search", Input)
        search.value = ""
        self.filter_text = ""
        self.refresh_table()
        self.query_one("#table", DataTable).focus()

    def action_cycle_sort(self) -> None:
        order = ["severity", "count", "name"]
        self.sort_mode = order[(order.index(self.sort_mode) + 1) % len(order)]
        self.refresh_table()

    def action_reload_data(self) -> None:
        self.state.refresh = True
        self.query_one("#status", Static).update(f"host={self.state.host}  reloading inventory...")
        self.query_one("#details", TextArea).load_text("Refreshing package inventory...")
        asyncio.create_task(self.refresh_data_async())

    def action_cursor_down(self) -> None:
        if self.focused and self.focused.id == "details":
            details = self.query_one("#details", TextArea)
            details.action_cursor_down(select=self.visual_anchor is not None)
            if self.visual_anchor is not None:
                details.selection = Selection(self.visual_anchor, details.selection.end)
            details.scroll_cursor_visible()
            return
        self.visual_anchor = None
        self.query_one("#table", DataTable).action_cursor_down()

    def action_cursor_up(self) -> None:
        if self.focused and self.focused.id == "details":
            details = self.query_one("#details", TextArea)
            details.action_cursor_up(select=self.visual_anchor is not None)
            if self.visual_anchor is not None:
                details.selection = Selection(self.visual_anchor, details.selection.end)
            details.scroll_cursor_visible()
            return
        self.visual_anchor = None
        self.query_one("#table", DataTable).action_cursor_up()

    def on_input_changed(self, event: Input.Changed) -> None:
        if event.input.id == "search":
            self.filter_text = event.value.strip()
            self.refresh_table()

    def on_data_table_row_highlighted(self, event: DataTable.RowHighlighted) -> None:
        if event.cursor_row < len(self.filtered_rows):
            self.update_details(self.filtered_rows[event.cursor_row])

    def _start_initial_load(self) -> None:
        asyncio.create_task(self.refresh_data_async())

    async def refresh_data_async(self) -> None:
        try:
            inventory = await asyncio.to_thread(load_inventory, self.state.host, refresh=self.state.refresh)
            self.query_one("#status", Static).update(
                f"host={self.state.host}  packages={len(inventory)}  loading vulnerabilities..."
            )
            self.query_one("#details", TextArea).load_text("Loading vulnerability data...")
            vulnerabilities = await asyncio.to_thread(load_vulnerabilities, self.state.host, refresh=self.state.refresh)
            self.rows = merge_report(inventory, vulnerabilities)
            self.state.refresh = False
            self.refresh_table()
        except PackageAuditError as exc:
            self.query_one("#details", TextArea).load_text(str(exc))
            self.query_one("#status", Static).update(f"[error] {exc}")

    def refresh_table(self) -> None:
        table = self.query_one("#table", DataTable)
        table.clear(columns=False)

        rows = sort_rows(self.rows, self.sort_mode)
        if self.filter_text:
            term = self.filter_text.lower()
            rows = [
                row
                for row in rows
                if term in row.package.display_name.lower()
                or term in row.package.version.lower()
                or any(term in vulnerability.cve.lower() for vulnerability in row.vulnerabilities)
            ]
        self.filtered_rows = rows

        for row in rows:
            severity = f"{row.max_severity:.1f}" if row.cve_count else "-"
            table.add_row(
                row.package.display_name,
                row.package.version or "-",
                row.package.source or "-",
                str(row.cve_count),
                severity,
            )

        vulnerable = sum(1 for row in self.rows if row.cve_count)
        self.query_one("#status", Static).update(
            f"host={self.state.host}  packages={len(self.rows)}  vulnerable={vulnerable}  "
            f"shown={len(self.filtered_rows)}  sort={self.sort_mode}  filter={self.filter_text or '-'}"
        )

        if self.filtered_rows:
            self.update_details(self.filtered_rows[0])
        else:
            self.query_one("#details", TextArea).load_text("No packages match the current filter.")

    def update_details(self, row: PackageReportRow) -> None:
        lines = [
            f"{row.package.display_name}",
            f"version: {row.package.version or '-'}",
            f"source: {row.package.source or '-'}",
            f"drvPath: {row.package.drv_path or '-'}",
            f"outPath: {row.package.out_path or '-'}",
            "",
            f"CVEs: {row.cve_count}",
            f"Max severity: {row.max_severity:.1f}" if row.cve_count else "Max severity: -",
            "",
        ]
        if not row.vulnerabilities:
            lines.append("No known vulnerabilities found.")
        else:
            for vulnerability in row.vulnerabilities[:30]:
                score = f"{vulnerability.severity:.1f}" if vulnerability.severity is not None else "-"
                lines.append(f"{vulnerability.cve}  score={score}")
                if vulnerability.description:
                    lines.append(vulnerability.description.strip())
                lines.append("")
        details = self.query_one("#details", TextArea)
        details.load_text("\n".join(lines).rstrip())
        details.move_cursor((0, 0))
        self.visual_anchor = None


def run_tui(host: str | None = None, *, refresh: bool = False) -> None:
    app = PackageAuditApp(TuiState(host=host or default_host(), refresh=refresh))
    app.run()
