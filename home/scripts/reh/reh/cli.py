from __future__ import annotations

import argparse
import re
import shutil
import sys

from .app import RehApp, launch_selection
from .recent import print_recent, reopen_recent


def parse_duration(value: str) -> int:
    match = re.fullmatch(r"([1-9][0-9]*)([smhdw])", value)
    if match is None:
        raise argparse.ArgumentTypeError(
            "use a positive duration like 30m, 24h, or 7d"
        )
    number, unit = match.groups()
    return int(number) * {"s": 1, "m": 60, "h": 3600, "d": 86400, "w": 604800}[unit]


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        prog="reh",
        description="Resume Codex and Claude sessions from one picker.",
    )
    parser.add_argument(
        "command",
        nargs="?",
        choices=["happy", "recent", "reopen"],
        help="use happy in the picker, list recent sessions, or reopen them",
    )
    parser.add_argument(
        "count",
        nargs="?",
        type=int,
        help="number of recent sessions (default: 2; all when using recent --within)",
    )
    parser.add_argument(
        "--include-current",
        action="store_true",
        help="include the calling agent's current session",
    )
    parser.add_argument("--json", action="store_true", help="output recent sessions as JSON")
    parser.add_argument(
        "--within",
        type=parse_duration,
        metavar="AGE",
        help="only use sessions updated within AGE (e.g. 24h, 7d)",
    )
    parser.add_argument(
        "--messages",
        type=int,
        default=6,
        metavar="N",
        help="show the last N messages per session (default: 6)",
    )
    parser.add_argument("--happy", action="store_true", help="reopen sessions through happy")
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="print reopen commands without launching",
    )
    return parser.parse_args(argv)


def main() -> int:
    args = parse_args(sys.argv[1:])
    if args.count is not None and args.count < 1:
        print("reh: count must be at least 1", file=sys.stderr)
        return 2
    if args.messages < 0:
        print("reh: messages must be at least 0", file=sys.stderr)
        return 2
    if args.command == "recent":
        count = args.count if args.count is not None else (None if args.within is not None else 2)
        return print_recent(
            count,
            include_current=args.include_current,
            within_seconds=args.within,
            message_count=args.messages,
            as_json=args.json,
        )
    if args.command == "reopen":
        return reopen_recent(
            args.count or 2,
            include_current=args.include_current,
            within_seconds=args.within,
            happy=args.happy,
            dry_run=args.dry_run,
        )
    if args.command == "happy" and shutil.which("happy") is None:
        print("reh: `happy` is not on PATH", file=sys.stderr)
        return 127
    app = RehApp()
    if args.command == "happy":
        app.happy_mode = True
    app.run()
    return launch_selection(app.selection)


if __name__ == "__main__":
    raise SystemExit(main())
