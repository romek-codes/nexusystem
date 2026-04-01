{ pkgs, config, lib, ... }:
let
  helpers = import ../../../helpers { inherit lib; };
  changeKeyboardLayout = pkgs.writeShellScriptBin "change-keyboard-layout"
    # bash
    ''
      switch=$(hyprctl devices -j | jq -r '.keyboards[] | .active_keymap' | uniq -c | [ $(wc -l) -eq 1 ] && echo "next" || echo "0")
      for device in $(hyprctl devices -j | jq -r '.keyboards[] | .name'); do hyprctl switchxkblayout $device $switch; done
      activeKeymap=$(hyprctl devices -j | jq -r '.keyboards[0] | .active_keymap')
      if [ $switch == "0" ]; then resetStr="(reset)"; else resetStr=""; fi
      hyprctl notify -1 1500 0 "$activeKeymap $resetStr"
    '';

  lock = pkgs.writeShellScriptBin "lock"
    # bash
    ''
      ${if (!helpers.isEmpty config.theme.backgroundImage)
      && (!helpers.isStaticImage config.theme.backgroundImage) then ''
        # Animated background - use mpvpaper overlay
        uwsm app -- ${pkgs.mpvpaper}/bin/mpvpaper -vs -o "no-audio --loop --panscan=1.0" --layer overlay ALL ${
          toString config.theme.backgroundImage
        } & OVERLAY_PID=$!;
        sleep 0.5 # Sleep so that mpvpaper starts before hyprlock, otherwise it looks weird.
        uwsm app -- ${pkgs.hyprlock}/bin/hyprlock
        kill $OVERLAY_PID
      '' else ''
        # Static image or no background - just run hyprlock
        uwsm app -- ${pkgs.hyprlock}/bin/hyprlock
      ''}
    '';

  appMenu = pkgs.writeShellScriptBin "app-menu"
    # bash
    ''
      rofi -modes drun -show drun -show-icons -matching fuzzy -sorting-method fzf -sort
    '';

  openedWindows = pkgs.writeShellScriptBin "opened-windows"
    # bash
    ''
      rofi -modes window -show window -matching fuzzy -sorting-method fzf -sort
    '';

  tmuxSessionPicker = pkgs.writeShellScriptBin "tmux-session-picker"
    # bash
    ''
      set -euo pipefail

      LOG_DIR="$HOME/Workspace/logs"
      LOG_FILE="$LOG_DIR/$(date +%Y-%m-%d).log"
      mkdir -p "$LOG_DIR"
      log() {
        printf '%s %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "$LOG_FILE"
      }
      log "tmux-session-picker start"

      if ! command -v tmux >/dev/null 2>&1; then
        log "tmux-session-picker error=tmux-not-found"
        echo "tmux not found."
        exit 1
      fi

      sessions=$(tmux list-sessions -F '#{session_name}' 2>/dev/null || true)
      if [[ -z "$sessions" ]]; then
        log "tmux-session-picker no-sessions"
        echo "No tmux sessions found."
        exit 0
      fi

      if command -v rofi >/dev/null 2>&1; then
        sleep 0.2
        selected=$(printf "%s\n" "$sessions" | rofi -dmenu -p "Tmux session")
      else
        printf "Tmux session: "
        read -r selected
      fi

      if [[ -z "$selected" ]]; then
        log "tmux-session-picker cancelled"
        exit 0
      fi

      log "tmux-session-picker selected=$selected"
      uwsm app -- footclient -e env ZSH_TMUX_AUTOSTART_DISABLE=1 sh -lc "tmux attach -t \"$selected\" || exec \\$SHELL"
    '';

  tmuxSessionCloseAll = pkgs.writeShellScriptBin "tmux-session-close-all"
    # bash
    ''
      set -euo pipefail

      LOG_DIR="$HOME/Workspace/logs"
      LOG_FILE="$LOG_DIR/$(date +%Y-%m-%d).log"
      mkdir -p "$LOG_DIR"
      log() {
        printf '%s %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "$LOG_FILE"
      }
      log "tmux-session-close-all start"

      if ! command -v tmux >/dev/null 2>&1; then
        log "tmux-session-close-all error=tmux-not-found"
        echo "tmux not found."
        exit 1
      fi

      sessions=$(tmux list-sessions -F '#{session_name}' 2>/dev/null || true)
      if [[ -z "$sessions" ]]; then
        log "tmux-session-close-all no-sessions"
        echo "No tmux sessions found."
        exit 0
      fi

      if [[ "''${SKIP_CONFIRM:-0}" != "1" ]]; then
        if command -v rofi >/dev/null 2>&1; then
          confirm=$(printf "Cancel\nClose all\n" | rofi -dmenu -p "Close all tmux sessions?" -l 0)
          [[ "$confirm" == "Close all" ]] || { log "tmux-session-close-all cancelled"; exit 0; }
        else
          printf "Close all tmux sessions? [y/N]: "
          read -r confirm
          [[ "$confirm" == "y" || "$confirm" == "Y" ]] || { log "tmux-session-close-all cancelled"; exit 0; }
        fi
      fi

      log "tmux-session-close-all confirmed"
      tmux kill-server
    '';

  tmuxSessionClose = pkgs.writeShellScriptBin "tmux-session-close"
    # bash
    ''
      set -euo pipefail

      LOG_DIR="$HOME/Workspace/logs"
      LOG_FILE="$LOG_DIR/$(date +%Y-%m-%d).log"
      mkdir -p "$LOG_DIR"
      log() {
        printf '%s %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "$LOG_FILE"
      }
      log "tmux-session-close start"

      if ! command -v tmux >/dev/null 2>&1; then
        log "tmux-session-close error=tmux-not-found"
        echo "tmux not found."
        exit 1
      fi

      sessions=$(tmux list-sessions -F '#{session_name}' 2>/dev/null || true)
      if [[ -z "$sessions" ]]; then
        log "tmux-session-close no-sessions"
        echo "No tmux sessions found."
        exit 0
      fi

      if command -v rofi >/dev/null 2>&1; then
        selected=$(printf "%s\n" "$sessions" | rofi -dmenu -p "Close tmux session")
      else
        printf "Close tmux session: "
        read -r selected
      fi

      if [[ -z "$selected" ]]; then
        log "tmux-session-close cancelled"
        exit 0
      fi

      if command -v rofi >/dev/null 2>&1; then
        confirm=$(printf "Cancel\nClose %s\n" "$selected" | rofi -dmenu -p "Close tmux session?")
        [[ "$confirm" == "Close $selected" ]] || { log "tmux-session-close cancelled"; exit 0; }
      else
        printf "Close tmux session '%s'? [y/N]: " "$selected"
        read -r confirm
        [[ "$confirm" == "y" || "$confirm" == "Y" ]] || { log "tmux-session-close cancelled"; exit 0; }
      fi

      log "tmux-session-close session=$selected"
      tmux kill-session -t "$selected"
    '';

  tmuxNewTerminal = pkgs.writeShellScriptBin "tmux-new-terminal"
    # bash
    ''
      set -euo pipefail

      LOG_DIR="$HOME/Workspace/logs"
      LOG_FILE="$LOG_DIR/$(date +%Y-%m-%d).log"
      mkdir -p "$LOG_DIR"
      log() {
        printf '%s %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "$LOG_FILE"
      }
      log "tmux-new-terminal start"

      if ! command -v tmux >/dev/null 2>&1; then
        log "tmux-new-terminal error=tmux-not-found"
        echo "tmux not found."
        exit 1
      fi

      sessions=$(tmux list-sessions -F '#{session_name}' 2>/dev/null || true)
      if [[ -n "$sessions" ]] && command -v rofi >/dev/null 2>&1; then
        choice=$(printf "New terminal session\n%s\n" "$sessions" | rofi -dmenu -p "Tmux sessions")
        if [[ -z "$choice" ]]; then
          log "tmux-new-terminal cancelled"
          exit 0
        fi
        if [[ "$choice" != "New terminal session" ]]; then
          log "tmux-new-terminal attach=$choice"
          uwsm app -- footclient -e env ZSH_TMUX_AUTOSTART_DISABLE=1 sh -lc "tmux attach -t \"$choice\" || exec \\$SHELL"
          exit 0
        fi
      fi

      idx=1
      session="tmux-1"
      while tmux has-session -t "$session" 2>/dev/null; do
        idx=$((idx + 1))
        session="tmux-$idx"
      done

      log "tmux-new-terminal session=$session"
      uwsm app -- footclient -e tmux new-session -s "$session"
    '';

  tmuxAgentCapture = pkgs.writeShellScriptBin "tmux-agent-capture"
    # bash
    ''
      set -u

      WIN_ID=$1
      ROWS=$2
      content=$(tmux capture-pane -ep -t "$WIN_ID" 2>/dev/null || true)
      N=$(printf "%s\n" "$content" | awk 'NF{l=NR} END{print l+0}')
      [ "$N" -gt 0 ] || exit 0
      head -n "$N" <<<"$content" | tail -n "$ROWS"
    '';

  tmuxAgentMonitor = pkgs.writeShellScriptBin "tmux-agent-monitor"
    # bash
    ''
      set -u -o pipefail
      LOG_DIR="$HOME/Workspace/logs"
      LOG_FILE="$LOG_DIR/$(date +%Y-%m-%d).log"
      mkdir -p "$LOG_DIR"
      log() {
        printf '%s %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "$LOG_FILE"
      }

      SESSION_NAME=$1
      WIN_IDX=$2
      WIN_NAME=$3
      COLOR=$4
      WIN_ID=$5
      log "tmux-agent-monitor start pane=$WIN_ID session=$SESSION_NAME window=$WIN_IDX name=$WIN_NAME"

      while true; do
        scroll=$(tmux display-message -p -t "$WIN_ID" '#{scroll_position}' 2>/dev/null || echo 0)
        if [ "$scroll" != "0" ]; then
          sleep 5
          continue
        fi

        ROWS=$(tput lines 2>/dev/null || echo 40)
        printf "\033[2J\033[H"
        printf "\033[1;''${COLOR}m── ''${SESSION_NAME}:''${WIN_IDX} | ''${WIN_NAME} ──\033[0m\n"
        tmux-agent-capture "$WIN_ID" $((ROWS-2)) || log "tmux-agent-monitor capture-failed pane=$WIN_ID"
        sleep 5
      done
    '';

in { home.packages = [ appMenu openedWindows lock changeKeyboardLayout tmuxSessionPicker tmuxSessionClose tmuxSessionCloseAll tmuxNewTerminal tmuxAgentCapture tmuxAgentMonitor ]; }
