# PreToolUse guard for shell commands, shared by Claude Code and Codex.
# Usage: guard.sh [claude|codex] < hook-json
# Codex does not support permissionDecision "ask", and its auto_review reviewer approves
# prompt rules on its own, so there every push/PR is blocked and left to the user.
{ writeShellScript, jq, gnugrep }:
writeShellScript "agent-guard" ''
  agent="''${1:-claude}"
  input=$(cat)
  tool=$(printf '%s' "$input" | ${jq}/bin/jq -r '.tool_name // empty')
  cmd=$(printf '%s' "$input" | ${jq}/bin/jq -r '.tool_input.command // empty')

  block() {
    echo "agent-guard: $1" >&2
    exit 2
  }
  ask() {
    ${jq}/bin/jq -n --arg r "$1" '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "ask", permissionDecisionReason: $r}}'
    exit 0
  }

  # Writes to external services via MCP (Jira, Confluence, Zabbix, Grafana, Sentry, XWiki, n8n, ...).
  # Local/personal servers (memory, playwright, nixos, Claude Docs) are left alone.
  case "$tool" in
    mcp__memory__* | mcp__playwright__* | mcp__nixos__* | mcp__claude_ai_Claude_Docs__* | mcp__*__executeRead | mcp__sentry__execute_sentry_tool) ;;
    mcp__*)
      if printf '%s' "''${tool#mcp__*__}" | ${gnugrep}/bin/grep -qiE \
        'create|update|edit|add|delete|remove|transition|upload|write|destructive|mass|acknowledge|push|send|import|install|clear|unblock|reset|provision|confirm|execute|publish|manage'; then
        [ "$agent" = codex ] && block "external writes ($tool) are done by the user or Claude; stop and show the user the exact payload"
        ask "external write: $tool"
      fi
      ;;
  esac

  [ -z "$cmd" ] && exit 0

  # Unsigned commits.
  if printf '%s' "$cmd" | ${gnugrep}/bin/grep -qiE -- '--no-gpg-sign|-c[[:space:]]*commit\.gpgsign|gpgsign([[:space:]]+|=)(false|0|no|off)\b'; then
    block "unsigned commits are not allowed; keep GPG signing on"
  fi

  # AI co-author trailer.
  if printf '%s' "$cmd" | ${gnugrep}/bin/grep -qE '\bgit\b.*\bcommit\b' \
    && printf '%s' "$cmd" | ${gnugrep}/bin/grep -qiE 'co-authored-by:.*(claude|codex|anthropic|openai)'; then
    block "no AI Co-Authored-By trailers in commits"
  fi

  q="(\"[^\"]*\"|'[^']*'|[^[:space:]]+)"
  start="(^|[;&|(\`[:space:]])"
  end="([[:space:];&|)]|$)"
  opts="([[:space:]]+(-[Cc][[:space:]]+$q|--[a-z-]+(=$q)?|-[a-zA-Z]+))"

  # Codex: no push or PR at all; the user does those.
  if [ "$agent" = codex ] && printf '%s' "$cmd" | ${gnugrep}/bin/grep -qE \
    "''${start}(git$opts*[[:space:]]+push|gh[[:space:]]+(pr[[:space:]]+(create|merge|ready)|release))$end"; then
    block "pushes and PRs are done by the user; stop and tell the user what to push"
  fi

  # Claude: push with git global options in front (git -C x push), which prefix rules miss.
  # Plain `git push` is left to the permission rules.
  if printf '%s' "$cmd" | ${gnugrep}/bin/grep -qE "''${start}git$opts+[[:space:]]+push$end"; then
    ask "git push needs explicit approval"
  fi

  exit 0
''
