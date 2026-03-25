# flake8: noqa
from __future__ import annotations

import json
import shutil
from typing import List

import typer
from rich.panel import Panel
from rich.prompt import Confirm, Prompt

from .config import (
    ALLOWED_EDITOR_MODES,
    BUILTIN_CONVENTIONS,
    DEFAULT_CLAUDE_COMMAND,
    DEFAULT_CODEX_COMMAND,
    DEFAULT_CONFIG_FILE,
    DEFAULT_EDITOR_MODE,
    DEFAULT_MODEL,
    DEFAULT_TEMPERATURE,
    LOCAL_CONFIG_FILE,
    Config,
    load_config,
    save_config,
    validate_config,
)
from .console import abort, console, success, warn


def preview_message(message: str, provider: str, model: str) -> None:
    title = f"Generated commit message ({provider} / {model})"
    console.print(Panel(message, title=title, border_style="cyan"))


def numbered_choice(title: str, options: List[str], default_index: int = 1) -> str:
    console.print(f"[bold]{title}[/bold]")
    for idx, option in enumerate(options, start=1):
        console.print(f"  [cyan]{idx}[/cyan]) {option}")
    while True:
        raw = Prompt.ask("Select an option", default=str(default_index))
        if raw.isdigit():
            index = int(raw)
            if 1 <= index <= len(options):
                return options[index - 1]
        warn("Please enter one of the shown numbers")


def select_action(default_message: str) -> str:
    return Prompt.ask(
        "Choose action",
        choices=["commit", "edit", "regen", "print", "cancel"],
        default=default_message,
        show_choices=True,
    )


def doctor_check_binary(name: str) -> str:
    return shutil.which(name) or "not found"


def maybe_run_first_startup_init() -> Config:
    has_global = DEFAULT_CONFIG_FILE.exists()
    has_local = LOCAL_CONFIG_FILE.exists()
    if has_global or has_local:
        return load_config()

    console.print(Panel("Welcome to lazycommit. Let's set it up.", border_style="cyan"))
    provider = numbered_choice("Choose a provider", ["openrouter", "codex", "claude"], default_index=1)
    cfg = Config(provider=provider)

    if provider == "openrouter":
        cfg.model = Prompt.ask("Model", default=DEFAULT_MODEL)
        temp_raw = Prompt.ask("Temperature", default=str(DEFAULT_TEMPERATURE))
        try:
            cfg.temperature = float(temp_raw)
        except ValueError:
            abort("Temperature must be a number")
        cfg.openrouter_api_key = Prompt.ask(
            "OpenRouter API key (leave blank to use env var)",
            default="",
            password=True,
        )
    elif provider == "codex":
        cfg.codex_command = Prompt.ask("Codex command", default=DEFAULT_CODEX_COMMAND)
        args_raw = Prompt.ask(
            "Codex args as JSON array (extra CLI args, default [\"exec\"])",
            default="[]",
        )
        try:
            parsed = json.loads(args_raw)
        except json.JSONDecodeError:
            abort("Codex args must be valid JSON")
        if not isinstance(parsed, list) or not all(isinstance(item, str) for item in parsed):
            abort("Codex args must be a JSON array of strings")
        cfg.codex_args = parsed
    elif provider == "claude":
        cfg.claude_command = Prompt.ask("Claude command", default=DEFAULT_CLAUDE_COMMAND)
        args_raw = Prompt.ask(
            "Claude args as JSON array (extra CLI args)",
            default="[]",
        )
        try:
            parsed = json.loads(args_raw)
        except json.JSONDecodeError:
            abort("Claude args must be valid JSON")
        if not isinstance(parsed, list) or not all(isinstance(item, str) for item in parsed):
            abort("Claude args must be a JSON array of strings")
        cfg.claude_args = parsed

    editor_mode = numbered_choice("Choose editor mode", ["git", "editor", "print"], default_index=1)
    cfg.editor_mode = editor_mode
    validate_config(cfg)
    save_config(DEFAULT_CONFIG_FILE, cfg)
    success(f"Config written to {DEFAULT_CONFIG_FILE}")
    return cfg


def interactive_config_menu() -> None:
    while True:
        cfg = maybe_run_first_startup_init()
        console.print(Panel("lazycommit configuration", border_style="cyan"))
        console.print("[cyan]1[/cyan]) Show current config")
        console.print("[cyan]2[/cyan]) Change provider")
        console.print("[cyan]3[/cyan]) Change model")
        console.print("[cyan]4[/cyan]) Change temperature")
        console.print("[cyan]5[/cyan]) Change editor mode")
        console.print("[cyan]6[/cyan]) Change OpenRouter API key")
        console.print("[cyan]7[/cyan]) Change Codex command")
        console.print("[cyan]8[/cyan]) Change Codex args")
        console.print("[cyan]9[/cyan]) Change Claude command")
        console.print("[cyan]10[/cyan]) Change Claude args")
        console.print("[cyan]11[/cyan]) Change commit style (convention)")
        console.print("[cyan]12[/cyan]) Set custom convention prompt")
        console.print("[cyan]13[/cyan]) Run guided init")
        console.print("[cyan]14[/cyan]) Exit")

        choice = Prompt.ask("Select an option", default="1")

        if choice == "1":
            from dataclasses import asdict
            rendered = asdict(cfg)
            if rendered.get("openrouter_api_key"):
                rendered["openrouter_api_key"] = "********"
            console.print_json(data=rendered)
        elif choice == "2":
            cfg.provider = numbered_choice("Choose provider", ["openrouter", "codex", "claude"], default_index=1)
            validate_config(cfg)
            save_config(DEFAULT_CONFIG_FILE, cfg)
            success("Provider updated")
        elif choice == "3":
            cfg.model = Prompt.ask("Model", default=cfg.model)
            validate_config(cfg)
            save_config(DEFAULT_CONFIG_FILE, cfg)
            success("Model updated")
        elif choice == "4":
            raw = Prompt.ask("Temperature", default=str(cfg.temperature))
            try:
                cfg.temperature = float(raw)
            except ValueError:
                warn("Temperature must be a number")
                continue
            validate_config(cfg)
            save_config(DEFAULT_CONFIG_FILE, cfg)
            success("Temperature updated")
        elif choice == "5":
            cfg.editor_mode = numbered_choice("Choose editor mode", ["git", "editor", "print"], default_index=1)
            validate_config(cfg)
            save_config(DEFAULT_CONFIG_FILE, cfg)
            success("Editor mode updated")
        elif choice == "6":
            cfg.openrouter_api_key = Prompt.ask("OpenRouter API key", default="", password=True)
            validate_config(cfg)
            save_config(DEFAULT_CONFIG_FILE, cfg)
            success("OpenRouter API key updated")
        elif choice == "7":
            cfg.codex_command = Prompt.ask("Codex command", default=cfg.codex_command)
            validate_config(cfg)
            save_config(DEFAULT_CONFIG_FILE, cfg)
            success("Codex command updated")
        elif choice == "8":
            raw = Prompt.ask(
                "Codex args as JSON array (extra CLI args, default [\"exec\"])",
                default=json.dumps(cfg.codex_args),
            )
            try:
                parsed = json.loads(raw)
            except json.JSONDecodeError:
                warn("Codex args must be valid JSON")
                continue
            if not isinstance(parsed, list) or not all(isinstance(item, str) for item in parsed):
                warn("Codex args must be a JSON array of strings")
                continue
            cfg.codex_args = parsed
            validate_config(cfg)
            save_config(DEFAULT_CONFIG_FILE, cfg)
            success("Codex args updated")
        elif choice == "9":
            cfg.claude_command = Prompt.ask("Claude command", default=cfg.claude_command)
            validate_config(cfg)
            save_config(DEFAULT_CONFIG_FILE, cfg)
            success("Claude command updated")
        elif choice == "10":
            raw = Prompt.ask(
                "Claude args as JSON array (extra CLI args)",
                default=json.dumps(cfg.claude_args),
            )
            try:
                parsed = json.loads(raw)
            except json.JSONDecodeError:
                warn("Claude args must be valid JSON")
                continue
            if not isinstance(parsed, list) or not all(isinstance(item, str) for item in parsed):
                warn("Claude args must be a JSON array of strings")
                continue
            cfg.claude_args = parsed
            validate_config(cfg)
            save_config(DEFAULT_CONFIG_FILE, cfg)
            success("Claude args updated")
        elif choice == "11":
            cfg.convention = numbered_choice(
                "Choose commit style",
                sorted(BUILTIN_CONVENTIONS),
                default_index=sorted(BUILTIN_CONVENTIONS).index(cfg.convention) + 1
                if cfg.convention in BUILTIN_CONVENTIONS else 1,
            )
            validate_config(cfg)
            save_config(DEFAULT_CONFIG_FILE, cfg)
            success("Convention updated")
        elif choice == "12":
            console.print("[dim]Enter a custom system prompt for commit generation.[/dim]")
            console.print("[dim]Leave blank to use the built-in preset instead.[/dim]")
            current = cfg.convention_prompt or ""
            new_prompt = Prompt.ask("Custom convention prompt", default=current)
            cfg.convention_prompt = new_prompt
            validate_config(cfg)
            save_config(DEFAULT_CONFIG_FILE, cfg)
            success("Custom convention prompt updated")
        elif choice == "13":
            maybe_run_first_startup_init()
        elif choice == "14":
            return
        else:
            warn("Please enter one of the shown numbers")
