from __future__ import annotations

import argparse
import json
import sys

from rich.table import Table

from .console import console
from .data import PackageAuditError, cves_payload, default_host, inventory_payload, list_hosts, report_payload
from .tui import run_tui


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(prog="package-audit", add_help=True)
    subparsers = parser.add_subparsers(dest="command")

    tui = subparsers.add_parser("tui", help="Open the package audit TUI")
    tui.add_argument("--host", default=default_host())
    tui.add_argument("--refresh", action="store_true")

    inventory = subparsers.add_parser("inventory", help="Show package inventory")
    inventory.add_argument("--host", default=default_host())
    inventory.add_argument("--all-hosts", action="store_true")
    inventory.add_argument("--json", action="store_true")
    inventory.add_argument("--refresh", action="store_true")

    cves = subparsers.add_parser("cves", help="Show vulnerabilities")
    cves.add_argument("--host", default=default_host())
    cves.add_argument("--all-hosts", action="store_true")
    cves.add_argument("--json", action="store_true")
    cves.add_argument("--refresh", action="store_true")

    report = subparsers.add_parser("report", help="Show combined package and CVE report")
    report.add_argument("--host", default=default_host())
    report.add_argument("--all-hosts", action="store_true")
    report.add_argument("--json", action="store_true")
    report.add_argument("--refresh", action="store_true")

    return parser


def main() -> None:
    parser = build_parser()
    argv = sys.argv[1:]
    if not argv:
        run_tui()
        return

    args = parser.parse_args(argv)

    try:
        if args.command == "tui":
            run_tui(args.host, refresh=args.refresh)
        elif args.command == "inventory":
            render_inventory(args.host, args.all_hosts, args.json, args.refresh)
        elif args.command == "cves":
            render_cves(args.host, args.all_hosts, args.json, args.refresh)
        elif args.command == "report":
            render_report(args.host, args.all_hosts, args.json, args.refresh)
        else:
            run_tui()
    except PackageAuditError as exc:
        console.print(f"[bold red]{exc}[/bold red]")
        raise SystemExit(1) from exc


def _hosts(host: str, all_hosts: bool) -> list[str]:
    return list_hosts() if all_hosts else [host]


def render_inventory(host: str, all_hosts: bool, as_json: bool, refresh: bool) -> None:
    payloads = [inventory_payload(item, refresh=refresh) for item in _hosts(host, all_hosts)]
    if as_json:
        print(json.dumps(payloads[0] if len(payloads) == 1 else payloads, indent=2))
        return

    for payload in payloads:
        table = Table(title=f"{payload['host']} package inventory")
        table.add_column("Package")
        table.add_column("Version")
        table.add_column("Source")
        for package in payload["packages"]:
            table.add_row(package["pname"] or package["name"], package["version"] or "-", package["source"] or "-")
        console.print(table)


def render_cves(host: str, all_hosts: bool, as_json: bool, refresh: bool) -> None:
    payloads = [cves_payload(item, refresh=refresh) for item in _hosts(host, all_hosts)]
    if as_json:
        print(json.dumps(payloads[0] if len(payloads) == 1 else payloads, indent=2))
        return

    for payload in payloads:
        table = Table(title=f"{payload['host']} vulnerabilities")
        table.add_column("Package")
        table.add_column("CVE")
        table.add_column("Score")
        entries = payload["vulnerabilities"]
        if not entries:
            console.print(f"{payload['host']}: no known vulnerabilities found.")
            continue
        for vulnerability in sorted(entries, key=lambda item: ((item["severity"] or 0.0), item["cve"]), reverse=True):
            score = f"{vulnerability['severity']:.1f}" if vulnerability["severity"] is not None else "-"
            table.add_row(vulnerability["package"] or "-", vulnerability["cve"], score)
        console.print(table)


def render_report(host: str, all_hosts: bool, as_json: bool, refresh: bool) -> None:
    payloads = [report_payload(item, refresh=refresh) for item in _hosts(host, all_hosts)]
    if as_json:
        print(json.dumps(payloads[0] if len(payloads) == 1 else payloads, indent=2))
        return

    for payload in payloads:
        table = Table(title=f"{payload['host']} package audit report")
        table.add_column("Package")
        table.add_column("Version")
        table.add_column("CVEs")
        table.add_column("Max")
        for package in sorted(payload["packages"], key=lambda item: (item["maxSeverity"], item["cveCount"], item["pname"] or item["name"]), reverse=True):
            score = f"{package['maxSeverity']:.1f}" if package["cveCount"] else "-"
            table.add_row(package["pname"] or package["name"], package["version"] or "-", str(package["cveCount"]), score)
        console.print(table)
