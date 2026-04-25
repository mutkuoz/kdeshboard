#!/usr/bin/env bash
# Luxury Journal uninstaller. Removes plasmoids + color scheme.
# --purge also removes fonts.
set -euo pipefail

FONT_DIR="$HOME/.local/share/fonts/luxury-journal"
COLOR_DIR="$HOME/.local/share/color-schemes"

PURGE=0
DRY_RUN=0

usage() {
    cat <<EOF
Usage: $0 [options]

Options:
  --purge       Also remove installed fonts
  --dry-run     Print actions without executing them
  -h, --help    Show this help
EOF
}

for arg in "$@"; do
    case "$arg" in
        --purge)   PURGE=1 ;;
        --dry-run) DRY_RUN=1 ;;
        -h|--help) usage; exit 0 ;;
        *) echo "unknown argument: $arg" >&2; usage >&2; exit 2 ;;
    esac
done

say() { echo "→ $*"; }
do_or_echo() {
    if (( DRY_RUN )); then
        echo "  would: $*"
    else
        # shellcheck disable=SC2294
        eval "$@"
    fi
}

PLASMOIDS=(
    com.utku.luxurygreeting
    com.utku.tmuxtail
    com.utku.journaltasks
    com.utku.journalclock
    com.utku.journalweather
    com.utku.journalnowplaying
    com.utku.systeminfo
    com.utku.analogclock
    com.utku.almanac
    com.utku.commonplacebook
    com.utku.hourglass
    com.utku.quickaccess
)

say "Removing plasmoids"
installed=$(kpackagetool6 -t Plasma/Applet --list 2>/dev/null || true)
for id in "${PLASMOIDS[@]}"; do
    if echo "$installed" | grep -q "^$id$"; then
        echo "  · $id"
        do_or_echo kpackagetool6 -t Plasma/Applet --remove "$id"
    else
        echo "  · $id (not installed)"
    fi
done

say "Removing color scheme"
dst="$COLOR_DIR/luxury-journal.colors"
if [[ -f "$dst" ]]; then
    do_or_echo rm -f "'$dst'"
else
    echo "  · already absent"
fi

if (( PURGE )); then
    say "Removing fonts (--purge)"
    if [[ -d "$FONT_DIR" ]]; then
        do_or_echo rm -rf "'$FONT_DIR'"
        do_or_echo fc-cache -f ">/dev/null"
    else
        echo "  · font directory already absent"
    fi
else
    say "Fonts kept (re-run with --purge to remove)"
fi

say "Done. Your selected color scheme may still be 'Luxury Journal' in kdeglobals;"
say "Plasma will fall back to Breeze when it fails to find the removed scheme."
