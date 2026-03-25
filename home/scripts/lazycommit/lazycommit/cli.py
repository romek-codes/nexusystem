# flake8: noqa
from __future__ import annotations

import shlex
from dataclasses import asdict
from typing import Optional

import typer
from rich import box
from rich.table import Table

from .commit import commit_via_editor_file, commit_with_message, open_external_editor
from .config import (
    ALLOWED_EDITOR_MODES,
    BUILTIN_CONVENTIONS,
    DEFAULT_CONFIG_FILE,
    LOCAL_CONFIG_FILE,
    load_config,
    parse_json_file,
    ensure_config_dir,
    save_config,
    validate_config,
    Config,
    DEFAULT_MODEL,
    DEFAULT_TEMPERATURE,
    DEFAULT_EDITOR_MODE,
    DEFAULT_CODEX_COMMAND,
    DEFAULT_CLAUDE_COMMAND,
)
from .console import abort, console, info, success, warn
from .git import ensure_git_repo, get_staged_diff
from .providers import build_system_prompt, get_provider
from .ui import (
    doctor_check_binary,
    interactive_config_menu,
    maybe_run_first_startup_init,
    numbered_choice,
    preview_message,
    select_action,
)

from rich.prompt import Confirm, Prompt

app = typer.Typer(help="AI-powered git commit message generator")
config_app = typer.Typer(help="Manage lazycommit configuration")
app.add_typer(config_app, name="config")


def run_commit(
    provider: Optional[str] = None,
    model: Optional[str] = None,
    temperature: Optional[float] = None,
    convention: Optional[str] = None,
    no_verify: bool = False,
    amend: bool = False,
    print_only: bool = False,
    editor_mode: Optional[str] = None,
) -> None:
    ensure_git_repo()
    cfg = maybe_run_first_startup_init()

    if provider is not None:
        cfg.provider = provider
    if model is not None:
        cfg.model = model
    if temperature is not None:
        cfg.temperature = temperature
    if convention is not None:
        cfg.convention = convention
    if editor_mode is not None:
        cfg.editor_mode = editor_mode
    validate_config(cfg)

    diff = get_staged_diff()
    system_prompt = build_system_prompt(cfg)

    info("🤖 Generating commit message...")
    if cfg.provider == "openrouter":
        console.print(f"[dim]Using OpenRouter model: {cfg.model}[/dim]")
    elif cfg.provider == "codex":
        command = " ".join(shlex.quote(p) for p in [cfg.codex_command, *cfg.codex_args])
        console.print(f"[dim]Using Codex command: {command}[/dim]")
    elif cfg.provider == "claude":
        command = " ".join(shlex.quote(p) for p in [cfg.claude_command, *cfg.claude_args])
        console.print(f"[dim]Using Claude command: {command}[/dim]")

    provider_impl = get_provider(cfg.provider)
    message = provider_impl.generate(system_prompt, diff, cfg)

    while True:
        preview_message(message, cfg.provider, cfg.model)

        if print_only or cfg.editor_mode == "print":
            console.print(message)
            return

        action = select_action("commit")

        if action == "print":
            console.print(message)
            continue
        if action == "cancel":
            warn("Cancelled")
            raise typer.Exit(0)
        if action == "regen":
            message = provider_impl.generate(system_prompt, diff, cfg)
            continue
        if action == "edit":
            edited = open_external_editor(message)
            preview_message(edited, cfg.provider, cfg.model)
            if Confirm.ask("Commit edited message?", default=True):
                if cfg.editor_mode == "editor":
                    commit_with_message(edited, no_verify=no_verify, amend=amend)
                else:
                    commit_via_editor_file(edited, no_verify=no_verify, amend=amend)
                success("Commit complete")
                return
            continue
        if action == "commit":
            if cfg.editor_mode == "editor":
                commit_with_message(message, no_verify=no_verify, amend=amend)
            else:
                commit_via_editor_file(message, no_verify=no_verify, amend=amend)
            success("Commit complete")
            return


@app.callback(invoke_without_command=True)
def _default(
    ctx: typer.Context,
    provider: Optional[str] = typer.Option(None, help="Override configured provider"),
    model: Optional[str] = typer.Option(None, help="Override configured model"),
    temperature: Optional[float] = typer.Option(None, help="Override configured temperature"),
    convention: Optional[str] = typer.Option(None, help=f"Override commit style preset: {', '.join(sorted(BUILTIN_CONVENTIONS))}"),
    no_verify: bool = typer.Option(False, help="Pass --no-verify to git commit"),
    amend: bool = typer.Option(False, help="Use git commit --amend"),
    print_only: bool = typer.Option(False, "--print", help="Print message only, do not commit"),
    editor_mode: Optional[str] = typer.Option(None, help="Override editor mode: git, editor, print"),
) -> None:
    if ctx.invoked_subcommand is None:
        run_commit(
            provider=provider,
            model=model,
            temperature=temperature,
            convention=convention,
            no_verify=no_verify,
            amend=amend,
            print_only=print_only,
            editor_mode=editor_mode,
        )


@app.command()
def commit(
    provider: Optional[str] = typer.Option(None, help="Override configured provider"),
    model: Optional[str] = typer.Option(None, help="Override configured model"),
    temperature: Optional[float] = typer.Option(None, help="Override configured temperature"),
    convention: Optional[str] = typer.Option(None, help=f"Override commit style preset: {', '.join(sorted(BUILTIN_CONVENTIONS))}"),
    no_verify: bool = typer.Option(False, help="Pass --no-verify to git commit"),
    amend: bool = typer.Option(False, help="Use git commit --amend"),
    print_only: bool = typer.Option(False, "--print", help="Print message only, do not commit"),
    editor_mode: Optional[str] = typer.Option(None, help="Override editor mode: git, editor, print"),
) -> None:
    run_commit(
        provider=provider,
        model=model,
        temperature=temperature,
        convention=convention,
        no_verify=no_verify,
        amend=amend,
        print_only=print_only,
        editor_mode=editor_mode,
    )


@app.command()
def doctor() -> None:
    cfg = maybe_run_first_startup_init()
    ensure_git_repo()

    table = Table(title="lazycommit doctor", box=box.SIMPLE_HEAVY)
    table.add_column("Check")
    table.add_column("Status")
    table.add_column("Details")

    git_ok = doctor_check_binary("git") != "not found"
    codex_path = doctor_check_binary(cfg.codex_command)
    claude_path = doctor_check_binary(cfg.claude_command)

    table.add_row("git", "ok" if git_ok else "missing", doctor_check_binary("git"))
    table.add_row("provider", "ok", cfg.provider)
    table.add_row("model", "ok", cfg.model)
    table.add_row("requests", "ok", "python requests available")
    table.add_row("openrouter key", "ok" if bool(cfg.openrouter_api_key.strip()) else "missing", "env or config")
    table.add_row("codex command", "ok" if codex_path != "not found" else "missing", codex_path)
    table.add_row("claude command", "ok" if claude_path != "not found" else "missing", claude_path)
    table.add_row("editor mode", "ok", cfg.editor_mode)
    convention_detail = f"{cfg.convention} (custom prompt set)" if cfg.convention_prompt else cfg.convention
    table.add_row("convention", "ok", convention_detail)
    table.add_row("global config", "ok" if DEFAULT_CONFIG_FILE.exists() else "missing", str(DEFAULT_CONFIG_FILE))
    table.add_row("local config", "ok" if LOCAL_CONFIG_FILE.exists() else "optional", str(LOCAL_CONFIG_FILE.resolve()))

    console.print(table)


@config_app.callback(invoke_without_command=True)
def config_menu(ctx: typer.Context) -> None:
    if ctx.invoked_subcommand is None:
        interactive_config_menu()


@config_app.command("show")
def config_show() -> None:
    cfg = maybe_run_first_startup_init()
    rendered = asdict(cfg)
    if rendered.get("openrouter_api_key"):
        rendered["openrouter_api_key"] = "********"
    console.print_json(data=rendered)


@config_app.command("init")
def config_init(local: bool = typer.Option(False, help="Write .lazycommit.json in current repo")) -> None:
    path = LOCAL_CONFIG_FILE if local else DEFAULT_CONFIG_FILE
    if path.exists() and not Confirm.ask(f"Overwrite existing config at {path}?", default=False):
        warn("Cancelled")
        raise typer.Exit(0)

    provider = numbered_choice("Choose provider", ["openrouter", "codex", "claude"], default_index=1)
    model = Prompt.ask("Model", default=DEFAULT_MODEL)
    temp_raw = Prompt.ask("Temperature", default=str(DEFAULT_TEMPERATURE))
    try:
        temperature = float(temp_raw)
    except ValueError:
        abort("Temperature must be a number")
    editor_mode = Prompt.ask("Editor mode", choices=sorted(ALLOWED_EDITOR_MODES), default=DEFAULT_EDITOR_MODE)

    cfg = Config(
        provider=provider,
        model=model,
        temperature=temperature,
        editor_mode=editor_mode,
    )

    if provider == "openrouter":
        api_key = Prompt.ask("OpenRouter API key (leave blank to use env var)", default="", password=True)
        cfg.openrouter_api_key = api_key
    elif provider == "codex":
        cfg.codex_command = Prompt.ask("Codex command", default=DEFAULT_CODEX_COMMAND)
    elif provider == "claude":
        cfg.claude_command = Prompt.ask("Claude Code command", default=DEFAULT_CLAUDE_COMMAND)

    save_config(path, cfg)
    success(f"Config written to {path}")


@config_app.command("get")
def config_get(key: str) -> None:
    cfg = maybe_run_first_startup_init()
    data = asdict(cfg)
    if key not in data:
        abort(f"Unknown config key: {key}")
    value = data[key]
    if key == "openrouter_api_key" and value:
        value = "********"
    if isinstance(value, (dict, list)):
        console.print_json(data=value)
    else:
        console.print(value)


@config_app.command("set")
def config_set(
    key: str,
    value: str,
    local: bool = typer.Option(False, help="Write to .lazycommit.json in current repo"),
) -> None:
    import json
    path = LOCAL_CONFIG_FILE if local else DEFAULT_CONFIG_FILE
    cfg = load_config(include_local=local)
    data = asdict(cfg)

    if key not in data:
        abort(f"Unknown config key: {key}")

    from typing import Any
    parsed: Any = value
    if key == "temperature":
        try:
            parsed = float(value)
        except ValueError:
            abort("temperature must be a number")
    elif key in {"codex_args", "claude_args"}:
        try:
            parsed = json.loads(value)
        except json.JSONDecodeError:
            abort(f"{key} must be valid JSON, e.g. '[\"exec\"]'")
        if not isinstance(parsed, list) or not all(isinstance(item, str) for item in parsed):
            abort(f"{key} must be a JSON array of strings")
    elif key == "provider":
        if value not in {"openrouter", "codex", "claude"}:
            abort(f"Invalid provider: {value}")
    elif key == "editor_mode":
        if value not in ALLOWED_EDITOR_MODES:
            abort(f"Invalid editor_mode: {value}")
    elif key == "convention":
        if value not in {"conventional", "simple", "gitmoji"}:
            abort(f"Invalid convention: {value}. Built-in options: {', '.join(sorted({'conventional', 'simple', 'gitmoji'}))}")

    data[key] = parsed
    new_cfg = Config(**data)
    validate_config(new_cfg)
    save_config(path, new_cfg)
    success(f"Saved {key} to {path}")


@config_app.command("unset")
def config_unset(
    key: str,
    local: bool = typer.Option(False, help="Remove from .lazycommit.json in current repo"),
) -> None:
    import json
    path = LOCAL_CONFIG_FILE if local else DEFAULT_CONFIG_FILE
    data = parse_json_file(path)
    if key not in data:
        warn(f"Key not set in {path}: {key}")
        raise typer.Exit(0)
    data.pop(key, None)
    ensure_config_dir(path)
    path.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
    success(f"Removed {key} from {path}")


def main() -> None:
    app()


if __name__ == "__main__":
    main()
