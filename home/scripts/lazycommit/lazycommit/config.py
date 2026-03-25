# flake8: noqa
from __future__ import annotations

import json
import os
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Any, Dict, List

from .console import abort

DEFAULT_CONFIG_DIR = Path.home() / ".config" / "lazycommit"
DEFAULT_CONFIG_FILE = DEFAULT_CONFIG_DIR / "config.json"
LOCAL_CONFIG_FILE = Path(".lazycommit.json")

DEFAULT_PROVIDER = "openrouter"
DEFAULT_MODEL = "openrouter/auto"
DEFAULT_TEMPERATURE = 0.3
DEFAULT_CONVENTION = "conventional"
DEFAULT_EDITOR_MODE = "git"
DEFAULT_CODEX_COMMAND = "codex"
DEFAULT_CLAUDE_COMMAND = "claude"
DEFAULT_CODEX_ARGS: List[str] = ["exec"]
DEFAULT_CLAUDE_ARGS: List[str] = []
DEFAULT_OPENROUTER_BASE_URL = "https://openrouter.ai/api/v1/chat/completions"

ALLOWED_PROVIDERS = {"openrouter", "codex", "claude"}
ALLOWED_EDITOR_MODES = {"git", "editor", "print"}
BUILTIN_CONVENTIONS = {"conventional", "simple", "gitmoji"}

COMMIT_PRESETS: Dict[str, str] = {
    "conventional": """\
You are an expert at writing Conventional Commit messages for human reviewers.

FORMAT:
<type>(<scope>): <subject>

<body>

<footer>

TYPES: feat, fix, docs, style, refactor, perf, test, chore

RULES:
- Subject line: imperative mood, ≤50 chars, no trailing period
- Scope: optional, only when it adds real clarity
- Body: explain the PURPOSE and USER-VISIBLE IMPACT of the change — not a file-by-file list.
  Write as if briefing a teammate on what was accomplished and why. Keep it under 72 chars/line.
- Use a short prose paragraph or a few high-level bullets ("-"), but avoid enumerating every file.
- Footer: only for breaking changes (BREAKING CHANGE:) or issue refs; omit if irrelevant.
- Return exactly one commit message, no markdown fences or commentary.\
""",
    "simple": """\
You are an expert at writing clear, reviewer-friendly git commit messages.

FORMAT:
<subject>

<body>

RULES:
- Subject: imperative mood, ≤60 chars, no type prefix, no trailing period
- Body: 1–3 short paragraphs explaining WHAT was accomplished and WHY — not which files changed.
  Write for a human reviewer who wants to understand the intent at a glance.
- Wrap lines at ~72 chars. Omit the body only if the subject is self-explanatory.
- Return exactly one commit message, no markdown fences or commentary.\
""",
    "gitmoji": """\
You are an expert at writing gitmoji commit messages for human reviewers.

FORMAT:
<emoji> <subject>

<body>

COMMON EMOJI:
✨ new feature  🐛 bug fix  📝 docs  ♻️ refactor  ⚡ perf  🎨 style/format
🔧 config/tooling  ✅ tests  🚀 deployment  💥 breaking change  🔒 security

RULES:
- Subject: pick ONE emoji, then imperative mood description, ≤60 chars total
- Body: explain the PURPOSE and USER-VISIBLE IMPACT — not a file-by-file list.
  Write for a teammate who wants to understand what changed and why.
- Wrap lines at ~72 chars. Omit the body if the subject is fully self-explanatory.
- Return exactly one commit message, no markdown fences or commentary.\
""",
}


@dataclass
class Config:
    provider: str = DEFAULT_PROVIDER
    model: str = DEFAULT_MODEL
    temperature: float = DEFAULT_TEMPERATURE
    convention: str = DEFAULT_CONVENTION
    convention_prompt: str = ""
    editor_mode: str = DEFAULT_EDITOR_MODE
    openrouter_api_key: str = ""
    openrouter_base_url: str = DEFAULT_OPENROUTER_BASE_URL
    codex_command: str = DEFAULT_CODEX_COMMAND
    codex_args: List[str] = None  # type: ignore[assignment]
    claude_command: str = DEFAULT_CLAUDE_COMMAND
    claude_args: List[str] = None  # type: ignore[assignment]

    def __post_init__(self) -> None:
        if self.codex_args is None:
            self.codex_args = list(DEFAULT_CODEX_ARGS)
        if self.claude_args is None:
            self.claude_args = list(DEFAULT_CLAUDE_ARGS)


def parse_json_file(path: Path) -> Dict[str, Any]:
    if not path.exists():
        return {}
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        abort(f"Invalid JSON in config file: {path} ({exc})")


def ensure_config_dir(path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)


def save_config(path: Path, config: Config) -> None:
    ensure_config_dir(path)
    path.write_text(json.dumps(asdict(config), indent=2) + "\n", encoding="utf-8")
    try:
        os.chmod(path, 0o600)
    except PermissionError:
        pass


def merge_dicts(base: Dict[str, Any], override: Dict[str, Any]) -> Dict[str, Any]:
    result = dict(base)
    result.update({k: v for k, v in override.items() if v is not None})
    return result


def load_config(global_path: Path = DEFAULT_CONFIG_FILE, include_local: bool = True) -> Config:
    global_data = parse_json_file(global_path)
    local_data = parse_json_file(LOCAL_CONFIG_FILE) if include_local else {}
    merged = merge_dicts(global_data, local_data)

    env_provider = os.getenv("LAZYCOMMIT_PROVIDER")
    env_model = os.getenv("LAZYCOMMIT_MODEL")
    env_temp = os.getenv("LAZYCOMMIT_TEMPERATURE")
    env_openrouter_key = os.getenv("OPENROUTER_API_KEY") or os.getenv("LAZYCOMMIT_OPENROUTER_API_KEY")

    if env_provider:
        merged["provider"] = env_provider
    if env_model:
        merged["model"] = env_model
    if env_temp:
        try:
            merged["temperature"] = float(env_temp)
        except ValueError:
            abort("LAZYCOMMIT_TEMPERATURE must be a number")
    if env_openrouter_key:
        merged["openrouter_api_key"] = env_openrouter_key

    cfg = Config(**merged)
    validate_config(cfg)
    return cfg


def validate_config(cfg: Config) -> None:
    if cfg.provider not in ALLOWED_PROVIDERS:
        abort(f"Invalid provider: {cfg.provider}. Allowed: {', '.join(sorted(ALLOWED_PROVIDERS))}")
    if cfg.editor_mode not in ALLOWED_EDITOR_MODES:
        abort(f"Invalid editor_mode: {cfg.editor_mode}. Allowed: {', '.join(sorted(ALLOWED_EDITOR_MODES))}")
    if not cfg.convention_prompt and cfg.convention not in BUILTIN_CONVENTIONS:
        abort(
            f"Invalid convention: {cfg.convention}. "
            f"Built-in options: {', '.join(sorted(BUILTIN_CONVENTIONS))}. "
            "Set convention_prompt for a fully custom style."
        )
    if not isinstance(cfg.temperature, (int, float)):
        abort("temperature must be a number")
    if not isinstance(cfg.codex_args, list):
        abort("codex_args must be a JSON array")
    if not isinstance(cfg.claude_args, list):
        abort("claude_args must be a JSON array")
