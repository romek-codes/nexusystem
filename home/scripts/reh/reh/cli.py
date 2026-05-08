from __future__ import annotations

import argparse
import shutil
import sys

from .app import RehApp, launch_selection


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        prog="reh",
        description="Resume Codex and Claude sessions from one picker.",
    )
    parser.add_argument(
        "launcher",
        nargs="?",
        choices=["happy"],
        help="launch selected sessions through happy",
    )
    return parser.parse_args(argv)


def main() -> int:
    args = parse_args(sys.argv[1:])
    if args.launcher == "happy" and shutil.which("happy") is None:
        print("reh: `happy` is not on PATH", file=sys.stderr)
        return 127
    app = RehApp()
    if args.launcher == "happy":
        app.happy_mode = True
    app.run()
    return launch_selection(app.selection)


if __name__ == "__main__":
    raise SystemExit(main())
