#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# WineBrowser's Unix-side helper. Never log OAuth URLs or codes.
set -euo pipefail
source "$(dirname -- "$0")/common.sh"
case "${1:-}" in https://*|http://*) ;; *) exit 2 ;; esac
if test -n "${INVENTOR_BROWSER:-}"; then exec "$INVENTOR_BROWSER" "$1"; fi
if command -v firefox >/dev/null; then exec firefox --new-tab "$1"; fi
exec xdg-open "$1"
