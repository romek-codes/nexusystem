#!/usr/bin/env bash

set -euo pipefail

case "$CURRENT_POLARITY" in
	dark)
		exec theme-switch light
		;;
	light)
		exec theme-switch dark
		;;
	*)
		"$NOTIFY_SEND" "Theme switch" "Unknown theme polarity: $CURRENT_POLARITY"
		exit 1
		;;
esac
