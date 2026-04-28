#!/usr/bin/env bash

set -euo pipefail

# Set to 1 while debugging to keep a terminal open and show rebuild output.
DEBUG_THEME_SWITCH=0

target_variant="${1:-}"

if [ -z "$target_variant" ]; then
	echo "Usage: theme-switch <dark|light>"
	exit 1
fi

case "$target_variant" in
	dark | light) ;;
	*)
		echo "Invalid variant: $target_variant"
		exit 1
		;;
esac

if [ "$target_variant" = "$CURRENT_POLARITY" ]; then
	"$NOTIFY_SEND" "Theme switch" "$target_variant mode is already active"
	exit 0
fi

original_state="$("$CAT_BIN" "$STATE_FILE" 2>/dev/null || printf '{}')"
temp_file="$("$MKTEMP_BIN")"
backup_file="$("$MKTEMP_BIN")"
rebuild_script="$("$MKTEMP_BIN")"

printf '%s\n' "$original_state" |
	"$JQ_BIN" --arg host "$HOSTNAME_VALUE" --arg variant "$target_variant" '.[$host] = $variant' >"$temp_file"
"$CP_BIN" "$temp_file" "$STATE_FILE"
printf '%s\n' "$original_state" >"$backup_file"

cat >"$rebuild_script" <<EOF
#!/usr/bin/env bash
set -euo pipefail

cd "$CONFIG_DIRECTORY"

restore_state() {
	"$CP_BIN" "$backup_file" "$STATE_FILE"
	git add "$STATE_FILE"
	rm -f "$backup_file" "$temp_file" "$rebuild_script"
}

trap restore_state EXIT

git add "$STATE_FILE"
nvd-system-diff nh os switch -H "$HOSTNAME_VALUE" "$CONFIG_DIRECTORY"
status=\$?

if [ "\$status" -eq 0 ]; then
	"$NOTIFY_SEND" "Theme switch" "Changed theme to $target_variant"
else
	"$NOTIFY_SEND" "Theme switch" "Theme switch failed"
fi

exit "\$status"
EOF

chmod +x "$rebuild_script"

"$NOTIFY_SEND" "Theme switch" "Switching theme to $target_variant. This might take a minute..."

if [ "$DEBUG_THEME_SWITCH" -eq 1 ]; then
	export THEME_SWITCH_REBUILD_SCRIPT="$rebuild_script"
	if ! "$FOOTCLIENT_BIN" "$BASH_BIN" -lc '
		"${THEME_SWITCH_REBUILD_SCRIPT}"
		status=$?
		echo
		printf "Press return to exit..."
		read -r
		exit "$status"
	'; then
		"$CP_BIN" "$backup_file" "$STATE_FILE"
		cd "$CONFIG_DIRECTORY"
		git add "$STATE_FILE"
		rm -f "$backup_file" "$temp_file" "$rebuild_script"
		"$NOTIFY_SEND" "Theme switch" "Failed to open rebuild terminal"
		exit 1
	fi
else
	if ! "$SETSID_BIN" -f "$BASH_BIN" "$rebuild_script" >/tmp/theme-switch.log 2>&1; then
		"$CP_BIN" "$backup_file" "$STATE_FILE"
		cd "$CONFIG_DIRECTORY"
		git add "$STATE_FILE"
		rm -f "$backup_file" "$temp_file" "$rebuild_script"
		"$NOTIFY_SEND" "Theme switch" "Failed to start theme switch"
		exit 1
	fi
fi
