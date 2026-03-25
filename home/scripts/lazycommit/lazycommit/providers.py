from __future__ import annotations

import re
import shlex
import subprocess
from typing import List

import requests

from .config import Config, COMMIT_PRESETS
from .console import abort


def build_system_prompt(cfg: Config) -> str:
    if cfg.convention_prompt:
        base = cfg.convention_prompt.strip()
    else:
        base = COMMIT_PRESETS[cfg.convention]
    return base + "\n\nAnalyze the following git diff and generate a single commit message."


def clean_message(message: str) -> str:
    cleaned = message.strip()
    cleaned = re.sub(r"^```[a-zA-Z0-9_-]*\n?", "", cleaned)
    cleaned = re.sub(r"\n?```$", "", cleaned)
    cleaned = cleaned.strip()
    return cleaned


def _run_command_capture(command: List[str], stdin_text: str) -> str:
    try:
        result = subprocess.run(
            command,
            input=stdin_text,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            check=False,
        )
    except FileNotFoundError:
        abort(f"Command not found: {command[0]}")

    if result.returncode != 0:
        stderr = result.stderr.strip()
        if "stdin is not a terminal" in stderr.lower():
            abort(
                "Provider command failed: "
                f"{' '.join(shlex.quote(p) for p in command)}\n"
                f"{stderr}\n"
                "Hint: some CLIs require explicit stdin flags. "
                "Try setting codex_args to a JSON array like '[\"exec\"]'."
            )
        if "stdout is not a terminal" in stderr.lower():
            abort(
                "Provider command failed: "
                f"{' '.join(shlex.quote(p) for p in command)}\n"
                f"{stderr}\n"
                "Hint: Codex needs a non-interactive subcommand. "
                "Try setting codex_args to a JSON array like '[\"exec\"]'."
            )
        abort(f"Provider command failed: {' '.join(shlex.quote(p) for p in command)}\n{stderr}")

    output = result.stdout.strip()
    if not output:
        abort(f"Provider command returned empty output: {' '.join(shlex.quote(p) for p in command)}")
    return output


def _run_command_with_prompt_arg(command: List[str], prompt: str) -> str:
    try:
        result = subprocess.run(
            [*command, prompt],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            check=False,
        )
    except FileNotFoundError:
        abort(f"Command not found: {command[0]}")

    if result.returncode != 0:
        stderr = result.stderr.strip()
        abort(f"Provider command failed: {' '.join(shlex.quote(p) for p in command)}\n{stderr}")

    output = result.stdout.strip()
    if not output:
        abort(f"Provider command returned empty output: {' '.join(shlex.quote(p) for p in command)}")
    return output


class Provider:
    def generate(self, system_prompt: str, diff: str, config: Config) -> str:
        raise NotImplementedError


class OpenRouterProvider(Provider):
    def generate(self, system_prompt: str, diff: str, config: Config) -> str:
        api_key = config.openrouter_api_key.strip()
        if not api_key:
            abort("No OpenRouter API key found. Set OPENROUTER_API_KEY or save openrouter_api_key in config.")

        payload = {
            "model": config.model,
            "messages": [
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": diff},
            ],
            "temperature": config.temperature,
        }

        try:
            response = requests.post(
                config.openrouter_base_url,
                headers={
                    "Content-Type": "application/json",
                    "Authorization": f"Bearer {api_key}",
                    "X-Title": "lazycommit",
                },
                json=payload,
                timeout=120,
            )
        except requests.RequestException as exc:
            abort(f"OpenRouter request failed: {exc}")

        try:
            data = response.json()
        except ValueError:
            abort(f"OpenRouter returned non-JSON response (HTTP {response.status_code})")

        if response.status_code >= 400 or "error" in data:
            error = data.get("error", {})
            if isinstance(error, dict):
                message = error.get("message") or str(error)
            else:
                message = str(error)
            abort(f"OpenRouter API error: {message}")

        message = data.get("choices", [{}])[0].get("message", {}).get("content", "")
        message = clean_message(message)
        if not message:
            abort("OpenRouter returned an empty commit message")
        return message


class CodexProvider(Provider):
    def generate(self, system_prompt: str, diff: str, config: Config) -> str:
        prompt = f"{system_prompt}\n\nGit diff:\n{diff}"
        command = [config.codex_command, *config.codex_args]
        if "exec" in config.codex_args or "--stdin" in config.codex_args:
            return clean_message(_run_command_capture(command, prompt))
        return clean_message(_run_command_with_prompt_arg(command, prompt))


class ClaudeProvider(Provider):
    def generate(self, system_prompt: str, diff: str, config: Config) -> str:
        prompt = f"{system_prompt}\n\nGit diff:\n{diff}"
        command = [config.claude_command, *config.claude_args]
        return clean_message(_run_command_capture(command, prompt))


def get_provider(name: str) -> Provider:
    if name == "openrouter":
        return OpenRouterProvider()
    if name == "codex":
        return CodexProvider()
    if name == "claude":
        return ClaudeProvider()
    abort(f"Unsupported provider: {name}")
