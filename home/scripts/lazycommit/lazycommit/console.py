from __future__ import annotations

import typer
from rich.console import Console

console = Console()


def abort(message: str, exit_code: int = 1) -> None:
    console.print(f"[bold red]❌ {message}[/bold red]")
    raise typer.Exit(exit_code)


def info(message: str) -> None:
    console.print(f"[cyan]{message}[/cyan]")


def success(message: str) -> None:
    console.print(f"[green]{message}[/green]")


def warn(message: str) -> None:
    console.print(f"[yellow]{message}[/yellow]")
