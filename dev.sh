#!/usr/bin/env bash
# Luxury Journal dev helper.
# Usage: dev.sh preview <id>   Live-preview a plasmoid via plasmoidviewer
#        dev.sh reload  <id>   Copy shared QML and kpackagetool6 --upgrade
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
    cat <<EOF
Usage: $0 <command> <plasmoid-id>

Commands:
  preview <id>   Run plasmoidviewer on the plasmoid (live-reloads on save)
  reload  <id>   Copy shared/qml/ into the plasmoid and kpackagetool6 --upgrade it

<id> may be the full name (com.utku.tmuxtail) or the short name (tmuxtail).
EOF
}

resolve_id() {
    local input="$1"
    if [[ -d "$REPO_DIR/plasmoids/$input" ]]; then echo "$input"; return; fi
    if [[ -d "$REPO_DIR/plasmoids/com.utku.$input" ]]; then echo "com.utku.$input"; return; fi
    echo "unknown plasmoid: $input" >&2
    echo "available:" >&2
    ls "$REPO_DIR/plasmoids/" >&2
    exit 2
}

sync_shared() {
    local dir="$1"
    rsync -a --delete "$REPO_DIR/shared/qml/" "$dir/contents/ui/shared/"
}

cmd="${1:-}"; shift || true
case "$cmd" in
    preview)
        [[ $# -eq 1 ]] || { usage; exit 2; }
        id=$(resolve_id "$1")
        dir="$REPO_DIR/plasmoids/$id"
        sync_shared "$dir"
        exec plasmoidviewer -a "$dir"
        ;;
    reload)
        [[ $# -eq 1 ]] || { usage; exit 2; }
        id=$(resolve_id "$1")
        dir="$REPO_DIR/plasmoids/$id"
        sync_shared "$dir"
        kpackagetool6 -t Plasma/Applet --upgrade "$dir"
        echo "reloaded: $id — right-click the widget → Refresh on the desktop"
        ;;
    -h|--help|"") usage ;;
    *) echo "unknown command: $cmd" >&2; usage >&2; exit 2 ;;
esac
