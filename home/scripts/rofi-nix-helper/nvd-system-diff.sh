if [[ -n "$XDG_STATE_HOME" && "$XDG_STATE_HOME" = /* ]]; then
  state_home="$XDG_STATE_HOME"
else
  state_home="$HOME/.local/state"
fi
state_dir="$state_home/nvd-system-diff"
last_diff_file="$state_dir/last-diff"

is_store_path() {
  [[ "$1" == /nix/store/* ]]
}

read_current_system() {
  readlink -f /run/current-system
}

save_last_diff() {
  is_store_path "$1" || return 1
  is_store_path "$2" || return 1
  mkdir -p "$state_dir"
  printf '%s\n%s\n' "$1" "$2" > "$last_diff_file"
}

load_last_diff() {
  [[ -r "$last_diff_file" ]] || return 1

  mapfile -t saved_diff < "$last_diff_file"
  [[ ${#saved_diff[@]} -ge 2 ]] || return 1
  is_store_path "${saved_diff[0]}" || return 1
  is_store_path "${saved_diff[1]}" || return 1

  printf '%s\n%s\n' "${saved_diff[0]}" "${saved_diff[1]}"
}

if [[ $# -eq 0 ]]; then
  if ! mapfile -t saved_diff < <(load_last_diff); then
    echo "usage: nvd-system-diff <command> [args...]"
    echo "or run it without arguments after a rebuild/upgrade saved the last diff"
    exit 1
  fi

  exec nvd diff "${saved_diff[0]}" "${saved_diff[1]}"
fi

old_system=$(readlink -f /run/current-system)
"$@"
status=$?

if [[ $status -ne 0 ]]; then
  exit "$status"
fi

new_system=$(read_current_system)
is_store_path "$old_system" || {
  echo "failed to resolve previous system path from /run/current-system" >&2
  exit 1
}
is_store_path "$new_system" || {
  echo "failed to resolve current system path from /run/current-system" >&2
  exit 1
}
save_last_diff "$old_system" "$new_system"
exec nvd diff "$old_system" "$new_system"
