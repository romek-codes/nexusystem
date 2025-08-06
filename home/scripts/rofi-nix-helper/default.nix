{ pkgs, config, inputs, ... }:
let

  configDirectory = config.var.configDirectory;
  hostname = config.var.hostname;

  rofi-nix-helper = pkgs.writeShellScriptBin "rofi-nix-helper"
    # bash
    ''
              # Define prefix and suffix for commands
              # prefix to open command in kitty, inside a tmux session, for yanking with /, also send return on open to end previous command, doesnt work sometimes though.
              prefix="footclient zsh -c 'if tmux has-session -t nh 2>/dev/null; then tmux attach -t nh; else tmux new-session -s nh \" echo -ne \n |"
              # suffix to wait for enter input
              suffix="; echo \\\"Press return to exit...\\\"; read\"; fi'"

              function run_command_with_prefix_and_suffix() {
                local cmd="$@"
                eval "$prefix$cmd$suffix"
              }

              function run_command() {
                local cmd="$1"
                eval "$cmd"
              }


              function ui(){
      	options=(
      		"builder;Rebuild;rofi-nix-helper rebuild"
      		"internet-archive;Search;rofi-nix-helper search"
      		"edit-clear;Clean;rofi-nix-helper clean"
      		"system-upgrade;Upgrade;rofi-nix-helper upgrade"
      		"system-software-update;Update;rofi-nix-helper update"
      		"adventure_list;List generations;rofi-nix-helper list_generations"
      	)

      	# Format options for rofi menu
      	menu_items=""
      	# Format options for rofi menu with icons
      	for option in "''${options[@]}"; do
      		icon=$(echo "$option" | cut -d';' -f1)
      		name=$(echo "$option" | cut -d';' -f2)
      		command=$(echo "$option" | cut -d';' -f3)
      		printf "%s\0icon\x1f%s\0meta\x1f%s\n" "$name" "$icon" "$command"
      	done >/tmp/rofi_menu

      	# Display menu with rofi
      	selected=$(cat /tmp/rofi_menu | rofi -i -dmenu -show-icons -matching fuzzy -sort-method fzf -sort)
      	[[ -z $selected ]] && exit 0

      	# Find the selected command - now match by name only
      	for option in "''${options[@]}"; do
      		name=$(echo "$option" | cut -d';' -f2)
      		command=$(echo "$option" | cut -d';' -f3)

      		if [[ "$selected" == "$name" ]]; then
      			run_command_with_prefix_and_suffix "$command"
      			exit $?
      		fi
      	done
              }

              [[ $1 == "" ]] && ui
              if [[ $1 == "rebuild" ]];then
                cmd="cd ${configDirectory} && git add . && nh os switch -H ${hostname} ${configDirectory}"
                run_command "$cmd"
              elif [[ $1 == "search" ]];then
                cmd="echo -n 'Search input: ' && read search_term && nh search \$search_term"
                run_command "$cmd"
              elif [[ $1 == "clean" ]];then
                cmd="nh clean all"
                run_command "$cmd"
              elif [[ $1 == "upgrade" ]];then
                cmd="nh os switch --upgrade -H ${hostname} ${configDirectory}"
                run_command "$cmd"
              elif [[ $1 == "update" ]];then
                cmd="cd ${configDirectory} && nix flake update"
                run_command "$cmd"
              elif [[ $1 == "list_generations" ]];then
                cmd="sudo nix-env -p /nix/var/nix/profiles/system --list-generations"
                run_command "$cmd"
              else
                echo "Unknown argument"
              fi
    '';

in { home.packages = [ rofi-nix-helper ]; }
