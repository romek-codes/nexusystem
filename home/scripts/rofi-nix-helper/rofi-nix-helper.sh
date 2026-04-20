prefix="footclient zsh -c 'if tmux has-session -t nh 2>/dev/null; then tmux attach -t nh; else tmux new-session -s nh \" echo -ne \n |"
suffix="; echo \\\"Press return to exit...\\\"; read\"; fi'"

run_command_with_prefix_and_suffix() {
  local cmd="$*"
  eval "$prefix$cmd$suffix"
}

run_command() {
  local cmd="$1"
  eval "$cmd"
}

print_menu() {
  local options=(
    "builder;Rebuild;rofi-nix-helper rebuild"
    "internet-archive;Search;rofi-nix-helper search"
    "edit-clear;Clean;rofi-nix-helper clean"
    "system-upgrade;Upgrade;rofi-nix-helper upgrade"
    "system-software-update;Update;rofi-nix-helper update"
    "adventure_list;List generations;rofi-nix-helper list_generations"
  )
  local option icon name

  for option in "${options[@]}"; do
    icon=$(echo "$option" | cut -d';' -f1)
    name=$(echo "$option" | cut -d';' -f2)
    printf "%s\0icon\x1f%s\n" "$name" "$icon"
  done
}

ui() {
  local options=(
    "Rebuild;rofi-nix-helper rebuild"
    "Search;rofi-nix-helper search"
    "Clean;rofi-nix-helper clean"
    "Upgrade;rofi-nix-helper upgrade"
    "Update;rofi-nix-helper update"
    "List generations;rofi-nix-helper list_generations"
  )
  local selected option name command

  selected=$(print_menu | rofi -i -dmenu -show-icons -matching fuzzy -sort-method fzf -sort)
  [[ -z $selected ]] && exit 0

  for option in "${options[@]}"; do
    name=$(echo "$option" | cut -d';' -f1)
    command=$(echo "$option" | cut -d';' -f2)
    if [[ "$selected" == "$name" ]]; then
      run_command_with_prefix_and_suffix "$command"
      exit $?
    fi
  done
}

[[ $# -eq 0 ]] && ui

case "$1" in
  rebuild)
    run_command "cd \"$CONFIG_DIRECTORY\" && git add . && nvd-system-diff nh os switch -H \"$HOSTNAME\" \"$CONFIG_DIRECTORY\""
    ;;
  search)
    run_command "echo -n 'Search input: ' && read search_term && nh search \$search_term"
    ;;
  clean)
    run_command "nh clean all"
    ;;
  upgrade)
    run_command "nvd-system-diff nh os switch --update -H \"$HOSTNAME\" \"$CONFIG_DIRECTORY\""
    ;;
  update)
    run_command "cd \"$CONFIG_DIRECTORY\" && nix flake update"
    ;;
  list_generations)
    run_command "sudo nix-env -p /nix/var/nix/profiles/system --list-generations"
    ;;
  *)
    echo "Unknown argument"
    exit 1
    ;;
esac
