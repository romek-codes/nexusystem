{ pkgs, ... }:
let
  commandPalette = pkgs.writeShellScriptBin "command-palette"
    # bash
    ''
      # Meta keywords should be used to define synonyms (apps->programs, screenshot->screen capture)
      selected=$(rofi -i -dmenu -show-icons -matching fuzzy -sorting-method fzf -sort < <(
      # Format: "Display Text" "icon-name" "meta keywords..."
      printf "%s\0icon\x1f%s\x1fmeta\x1f%s\n" \
      "Nix helper" "nix-snowflake" "update upgrade clean rebuild system"
      printf "%s\0icon\x1f%s\x1fmeta\x1f%s\n" \
      "Open browser" "zen-browser" "zen firefox chrome web internet"
      printf "%s\0icon\x1f%s\x1fmeta\x1f%s\n" \
      "Bitwarden (SUPER + B)" "bitwarden" "rbw bw passwords login auth security"
      printf "%s\0icon\x1f%s\x1fmeta\x1f%s\n" \
      "Search apps (SUPER + P)" "applications-all" "applications programs software launcher menu"
      printf "%s\0icon\x1f%s\x1fmeta\x1f%s\n" \
      "Toggle blue light filter (SUPER + F2)" "preferences-desktop-display-nightcolor" "blf night mode eye strain redshift flux"
      printf "%s\0icon\x1f%s\x1fmeta\x1f%s\n" \
      "Todos" "todoist" "todo todoist td planify tasks organize productivity"
      printf "%s\0icon\x1f%s\x1fmeta\x1f%s\n" \
      "Color picker" "color-picker" "cp pick color hex rgb design development"
      printf "%s\0icon\x1f%s\x1fmeta\x1f%s\n" \
      "File explorer (SUPER + E)" "system-file-manager" "fe files browse folder directory thunar manager explorer"
      printf "%s\0icon\x1f%s\x1fmeta\x1f%s\n" \
      "Search open windows (SUPER/ALT + TAB)" "window_list" "sow window switcher"
      printf "%s\0icon\x1f%s\x1fmeta\x1f%s\n" \
      "Screenshot (SUPER + A / ALT + PRINTSCREEN)" "screengrab" "ss screen capture print image save"
      printf "%s\0icon\x1f%s\x1fmeta\x1f%s\n" \
      "Toggle zen mode" "face-ninja" "focus"
      printf "%s\0icon\x1f%s\x1fmeta\x1f%s\n" \
      "Search files" "gnome-search-tool" "sf find file browse directory explore"
      printf "%s\0icon\x1f%s\x1fmeta\x1f%s\n" \
      "Search files recursively" "gnome-search-tool" "sfr find recursive deep file search locate"
      printf "%s\0icon\x1f%s\x1fmeta\x1f%s\n" \
      "Optimize disk space" "disk-usage-analyzer" "cw storage cleanup disk free space qdirstat"
      printf "%s\0icon\x1f%s\x1fmeta\x1f%s\n" \
      "Toggle suspend & screenlock" "caffeine" "sleep"
      printf "%s\0icon\x1f%s\x1fmeta\x1f%s\n" \
      "Toggle VPN" "application-x-openvpn-profile" "security privacy network"
      printf "%s\0icon\x1f%s\x1fmeta\x1f%s\n" \
      "Emoji picker" "preferences-desktop-emoticons" "icon character"
      printf "%s\0icon\x1f%s\x1fmeta\x1f%s\n" \
      "Nerdfont picker" "preferences-desktop-emoticons" "icon character"
      printf "%s\0icon\x1f%s\x1fmeta\x1f%s\n" \
      "Clipboard history (SUPER + V)" "edit-paste" "ch copy paste clipboard history buffer"
      printf "%s\0icon\x1f%s\x1fmeta\x1f%s\n" \
      "Calculator (SUPER + C)" "accessories-calculator" "calc math compute formula arithmetic"
      printf "%s\0icon\x1f%s\x1fmeta\x1f%s\n" \
      "Change keyboard layout (SUPER + SPACE)" "input-keyboard" "ckl keyboard input language layout switch"
      printf "%s\0icon\x1f%s\x1fmeta\x1f%s\n" \
      "Toggle fullscreen (SUPER + F)" "view-fullscreen-symbolic" "hyprland wm fullscreen maximize"
      printf "%s\0icon\x1f%s\x1fmeta\x1f%s\n" \
      "Toggle floating (SUPER + T)" "window-duplicate" "hyprland wm tile floating window"
      printf "%s\0icon\x1f%s\x1fmeta\x1f%s\n" \
      "Toggle hyprpanel / bar (SUPER + SHIFT + T)" "panel" "hyprland wm hyprpanel bar status hide show"
      printf "%s\0icon\x1f%s\x1fmeta\x1f%s\n" \
      "Restart hyprpanel / bar" "view-refresh-symbolic" "hyprland wm hyprpanel bar restart reload"
      printf "%s\0icon\x1f%s\x1fmeta\x1f%s\n" \
      "Open terminal (SUPER + ENTER)" "utilities-terminal" "term foot wm console shell command"
      printf "%s\0icon\x1f%s\x1fmeta\x1f%s\n" \
      "Network (SUPER + ENTER)" "networkmanager" "network internet wifi ethernet connection"
      printf "%s\0icon\x1f%s\x1fmeta\x1f%s\n" \
      "Lock screen (SUPER + CTRL + L)" "system-lock-screen" "lock screen ls security hyprlock"
      printf "%s\0icon\x1f%s\x1fmeta\x1f%s\n" \
      "Logout" "log-out" "logout log out change account session exit"
      printf "%s\0icon\x1f%s\x1fmeta\x1f%s\n" \
      "Suspend" "suspend" "suspend sleep power save hibernate"
      printf "%s\0icon\x1f%s\x1fmeta\x1f%s\n" \
      "Reboot" "reboot" "restart reboot system"
      printf "%s\0icon\x1f%s\x1fmeta\x1f%s\n" \
      "Shutdown" "shutdown" "poweroff shutdown power off system"
      printf "%s\0icon\x1f%s\x1fmeta\x1f%s\n" \
      "Play/Pause" "media-playback-play-pause-symbolic" "play pause start stop media music video"
      printf "%s\0icon\x1f%s\x1fmeta\x1f%s\n" \
      "Next" "media-skip-forward-symbolic" "next skip track song media"
      printf "%s\0icon\x1f%s\x1fmeta\x1f%s\n" \
      "Previous" "media-skip-backward-symbolic" "previous back track song media"
      printf "%s\0icon\x1f%s\x1fmeta\x1f%s\n" \
      "Mute" "audio-volume-muted-symbolic" "mute audio sound volume silence"
      printf "%s\0icon\x1f%s\x1fmeta\x1f%s\n" \
      "Set volume" "audio-volume-high-symbolic" "volume sound sv audio level"
      printf "%s\0icon\x1f%s\x1fmeta\x1f%s\n" \
      "Skip back seconds" "media-seek-backward-symbolic" "rewind back skip media sound playerctl seek"
      printf "%s\0icon\x1f%s\x1fmeta\x1f%s\n" \
      "Skip forward seconds" "media-seek-forward-symbolic" "forward skip ahead media sound playerctl seek"
      printf "%s\0icon\x1f%s\x1fmeta\x1f%s\n" \
      "Jump to timestamp" "preferences-system-time-symbolic" "seek skip position timestamp jump media sound playerctl"
      printf "%s\0icon\x1f%s\x1fmeta\x1f%s\n" \
      "Set brightness" "display-brightness-symbolic" "brightness sb screen display backlight"
      printf "%s\0icon\x1f%s\x1fmeta\x1f%s\n" \
      "Clear notifications" "edit-clear-all-symbolic" "cn alerts notifications clear dismiss"
      printf "%s\0icon\x1f%s\x1fmeta\x1f%s\n" \
      "Toggle do not disturb" "face-quiet" "dnd alerts notifications"
      printf "%s\0icon\x1f%s\x1fmeta\x1f%s\n" \
      "Bluetooth" "bluetooth" "bt bluetooth wireless connect device"
      printf "%s\0icon\x1f%s\x1fmeta\x1f%s\n" \
      "Close window (SUPER + Q)" "window-close" "cw quit close kill window"
      printf "%s\0icon\x1f%s\x1fmeta\x1f%s\n" \
      "Go to BIOS" "system-component-firmware" "gtb bios firmware sb setup boot"
      ))

      	# If no selection was made (user pressed Escape), exit gracefully
      	[ -z "$selected" ] && exit 0

      	command_found=0
      	# Close on super key pressed.
      	# -click-to-exit option not working on hyprland, would be nice for beginners too when it's fixed.
      	# https://github.com/lbonn/rofi/issues/22

      	# rofi_command="rofi -kb-cancel '[133]' "
      	rofi_command="rofi "

      	if [[ "$selected" == *"Toggle suspend & screenlock"* ]]; then
      	suspend-and-screen-lock
      	command_found=1
      	elif [[ "$selected" == *"Open terminal"* ]]; then
      	footclient
      	command_found=1
      	elif [[ "$selected" == *"Open browser"* ]]; then
      	uwsm app -- $BROWSER
      	command_found=1
      	elif [[ "$selected" == *"Optimize disk space"* ]]; then
      	uwsm app -- ${pkgs.qdirstat}/bin/qdirstat
      	command_found=1
      	elif [[ "$selected" == *"Shutdown"* ]]; then
      	systemctl poweroff
      	command_found=1
      	elif [[ "$selected" == *"Reboot"* ]]; then
      	systemctl reboot
      	command_found=1
      	elif [[ "$selected" == *"Todos"* ]]; then
      	uwsm app -- ${pkgs.planify}/bin/io.github.alainm23.planify
      	command_found=1
      	elif [[ "$selected" == *"Suspend"* ]]; then
      	systemctl suspend
      	command_found=1
      	elif [[ "$selected" == *"Logout"* ]]; then
      	hyprctl dispatch exit
      	command_found=1
      	elif [[ "$selected" == *"Toggle fullscreen"* ]]; then
      	hyprctl dispatch fullscreen
      	command_found=1
      	elif [[ "$selected" == *"Toggle floating"* ]]; then
      	hyprctl dispatch togglefloating
      	command_found=1
      	elif [[ "$selected" == *"Toggle hyprpanel / bar"* ]]; then
      	hyprpanel-toggle
      	command_found=1
      	elif [[ "$selected" == *"Restart hyprpanel / bar"* ]]; then
      	hyprpanel restart
      	command_found=1
      	elif [[ "$selected" == *"Search apps"* ]]; then
      	app-menu
      	command_found=1
      	elif [[ "$selected" == *"Search files recursively"* ]]; then
      	eval "$rofi_command -modi recursivebrowser -filebrowser-command 'thunar' -show recursivebrowser"
      	command_found=1
      	elif [[ "$selected" == *"Search files"* && "$selected" != *"recursively"* ]]; then
      	eval "$rofi_command -modi filebrowser -filebrowser-command 'thunar' -show filebrowser"
      	command_found=1
      	elif [[ "$selected" == *"Search open windows"* ]]; then
      	eval "$rofi_command -modes run,window -show window"
      	command_found=1
      	elif [[ "$selected" == *"Toggle blue light filter"* ]]; then
      	blue-light-filter
      	command_found=1
      	elif [[ "$selected" == *"Emoji picker"* ]]; then
      	rofimoji -f emojis
      	command_found=1
      	elif [[ "$selected" == *"Nerdfont picker"* ]]; then
      	rofimoji -f geometric_shapes geometric_shapes_extended nerd_font
      	command_found=1
      	elif [[ "$selected" == *"Nix helper"* ]]; then
      	rofi-nix-helper
      	command_found=1
      	elif [[ "$selected" == *"Color picker"* ]]; then
      	sleep 0.2 && hyprpicker -a
      	command_found=1
      	elif [[ "$selected" == *"Toggle VPN"* ]]; then
      	openvpn-toggle
      	command_found=1
      	elif [[ "$selected" == *"Bitwarden"* ]]; then
      	rofi-rbw
      	command_found=1
      	elif [[ "$selected" == *"Screenshot"* ]]; then
      	sleep 0.2 && screenshot region swappy
      	command_found=1
      	elif [[ "$selected" == *"Clipboard history"* ]]; then
      	rofi-cliphist
      	command_found=1
      	elif [[ "$selected" == *"Calculator"* ]]; then
      	eval "$rofi_command -show calc -modi calc -no-show-match -no-sort"
      	command_found=1
      	elif [[ "$selected" == *"File explorer"* ]]; then
      	uwsm app -- ${pkgs.xfce.thunar}/bin/thunar
      	command_found=1
      	elif [[ "$selected" == *"Lock screen"* ]]; then
      	uwsm app -- ${pkgs.hyprlock}/bin/hyprlock
      	command_found=1
      	elif [[ "$selected" == *"Change keyboard layout"* ]]; then
      	change-keyboard-layout
      	command_found=1
      	elif [[ "$selected" == *"Toggle zen mode"* ]]; then
      	hyprfocus-toggle
      	command_found=1
      	elif [[ "$selected" == *"Network"* ]]; then
      	rofi-network-manager
      	command_found=1
      	elif [[ "$selected" == *"Play/Pause"* ]]; then
      	${pkgs.playerctl}/bin/playerctl play-pause
      	command_found=1
      	elif [[ "$selected" == *"Next"* ]]; then
      	${pkgs.playerctl}/bin/playerctl next
      	command_found=1
      	elif [[ "$selected" == *"Previous"* ]]; then
      	${pkgs.playerctl}/bin/playerctl previous
      	command_found=1
      	elif [[ "$selected" == *"Skip back seconds"* ]]; then
      	# Get seconds value from user using rofi
      	seconds=$(rofi -dmenu -p "Skip back how many seconds?" -l 0)
      	# Check if input is valid
      	if [[ "$seconds" =~ ^[0-9]+$ ]] && [ "$seconds" -ge 0 ]; then
      	${pkgs.playerctl}/bin/playerctl position "$seconds"-
      	else
      	notify-send "Invalid input" "Please enter a valid number of seconds"
      	fi
      	command_found=1
      	elif [[ "$selected" == *"Skip forward seconds"* ]]; then
      	# Get seconds value from user using rofi
      	seconds=$(rofi -dmenu -p "Skip forward how many seconds?" -l 0)
      	# Check if input is valid
      	if [[ "$seconds" =~ ^[0-9]+$ ]] && [ "$seconds" -ge 0 ]; then
      	${pkgs.playerctl}/bin/playerctl position "$seconds"+
      	else
      	notify-send "Invalid input" "Please enter a valid number of seconds"
      	fi
      	command_found=1
      	elif [[ "$selected" == *"Jump to timestamp"* ]]; then
      	# Get position value from user using rofi
      	position=$(rofi -dmenu -p "Jump to position (seconds)" -l 0)
      	# Check if input is valid
      	if [[ "$position" =~ ^[0-9]+$ ]] && [ "$position" -ge 0 ]; then
      	${pkgs.playerctl}/bin/playerctl position "$position"
      	else
      	notify-send "Invalid position" "Please enter a valid number of seconds"
      	fi
      	command_found=1
      	elif [[ "$selected" == *"Mute"* ]]; then
      	sound-toggle
      	command_found=1
      	elif [[ "$selected" == *"Set volume"* ]]; then
      	# Get volume value from user using rofi
      	volume=$(rofi -dmenu -p "Enter volume (0-100)" -l 0)
      	# Check if input is valid
      	if [[ "$volume" =~ ^[0-9]+$ ]] && [ "$volume" -ge 0 ] && [ "$volume" -le 100 ]; then
      	sound-set "$volume"
      	else
      	notify-send "Invalid volume" "Please enter a number between 0 and 100"
      	fi
      	command_found=1
      	elif [[ "$selected" == *"Set brightness"* ]]; then
      	# Get brightness value from user using rofi
      	brightness=$(rofi -dmenu -p "Enter brightness (0-100)" -l 0)
      	# Check if input is valid
      	if [[ "$brightness" =~ ^[0-9]+$ ]] && [ "$brightness" -ge 0 ] && [ "$brightness" -le 100 ]; then
      	brightness-set "$brightness"
      	else
      	notify-send "Invalid brightness" "Please enter a number between 0 and 100"
      	fi
      	command_found=1
      	elif [[ "$selected" == *"Clear notifications"* ]]; then
      	hyprpanel clearNotifications
      	command_found=1
      	elif [[ "$selected" == *"Toggle do not disturb"* ]]; then
        status=$(hyprpanel toggleDnd)
        if [[ $status == "Enabled" ]]; then
          title="󰳙  Do not disturb activated"
          description="Do not disturb is now activated!"
          hyprpanel toggleDnd
          notif "Zen mode" "$title" "$description"
          hyprpanel toggleDnd
        else
          title="󰕦  Do not disturb deactivated"
          description="Do not disturb is now deactivated!"
          notif "Zen mode" "$title" "$description"
        fi
      	command_found=1
      	elif [[ "$selected" == *"Close window"* ]]; then
      	hyprctl dispatch killactive
      	command_found=1
      	elif [[ "$selected" == *"Bluetooth"* ]]; then
      	uwsm app -- blueman-manager
      	command_found=1
      	elif [[ "$selected" == *"Go to BIOS"* ]]; then
      	systemctl reboot --firmware-setup
      	command_found=1
      	fi

      	# Show notification if no command was found
      	if [ $command_found -eq 0 ]; then
      	notify-send "Command Palette" "No matching command found for: $selected" -i dialog-error
      	fi
    '';

in { home.packages = [ commandPalette ]; }
