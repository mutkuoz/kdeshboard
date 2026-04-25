#!/usr/bin/env bash
# Luxury Journal installer — color scheme, fonts, plasmoids.
# Idempotent: safe to re-run. Use --dry-run to preview.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FONT_DIR="$HOME/.local/share/fonts/luxury-journal"
COLOR_DIR="$HOME/.local/share/color-schemes"

DRY_RUN=0
NO_FONTS=0
FORCE=0
NO_RESTART=0

usage() {
    cat <<EOF
Usage: $0 [options]

Options:
  --dry-run     Print actions without executing them
  --no-fonts    Skip font downloads (use existing installs)
  --force       Overwrite color scheme even if it differs from the repo copy
  --no-restart  Don't restart plasmashell at the end (you'll need to refresh
                widgets manually for the new code to load)
  -h, --help    Show this help
EOF
}

for arg in "$@"; do
    case "$arg" in
        --dry-run)   DRY_RUN=1 ;;
        --no-fonts)  NO_FONTS=1 ;;
        --force)     FORCE=1 ;;
        --no-restart) NO_RESTART=1 ;;
        -h|--help)   usage; exit 0 ;;
        *) echo "unknown argument: $arg" >&2; usage >&2; exit 2 ;;
    esac
done

say()  { echo "→ $*"; }
warn() { echo "⚠ $*" >&2; }
die()  { echo "✖ $*" >&2; exit 1; }
do_or_echo() {
    if (( DRY_RUN )); then
        echo "  would: $*"
    else
        # shellcheck disable=SC2294
        eval "$@"
    fi
}

# ---- Preflight -------------------------------------------------------------
preflight() {
    say "Preflight checks"
    command -v plasmashell >/dev/null || die "plasmashell not found — is this Plasma 6?"
    local ver
    ver=$(plasmashell --version 2>/dev/null | awk '{print $2}')
    [[ "$ver" =~ ^6\. ]] || die "Plasma 6.x required, found: $ver"
    for bin in kpackagetool6 fc-cache curl awk stat rsync sha256sum; do
        command -v "$bin" >/dev/null || die "missing binary: $bin"
    done
    mkdir -p "$FONT_DIR" "$COLOR_DIR" || die "cannot create target dirs"
}

# ---- Fonts -----------------------------------------------------------------
# All URLs verified against google/fonts main branch. Cormorant Garamond
# upstream switched to a single variable font (CormorantGaramond[wght].ttf)
# so we no longer download the four static weights — Qt's font.weight axis
# applies to the variable font directly. IM Fell DW Pica's roman file was
# renamed to IMFePIrm28P.ttf in the Google Fonts repo even though the family
# name registered with Qt is still "IM Fell DW Pica".
declare -A FONT_URLS=(
    [Parisienne-Regular.ttf]="https://github.com/google/fonts/raw/main/ofl/parisienne/Parisienne-Regular.ttf"
    [Caveat.ttf]="https://github.com/google/fonts/raw/main/ofl/caveat/Caveat%5Bwght%5D.ttf"
    [CormorantGaramond.ttf]="https://github.com/google/fonts/raw/main/ofl/cormorantgaramond/CormorantGaramond%5Bwght%5D.ttf"
    [CormorantSC-Medium.ttf]="https://github.com/google/fonts/raw/main/ofl/cormorantsc/CormorantSC-Medium.ttf"
    [IMFellDWPica-Roman.ttf]="https://github.com/google/fonts/raw/main/ofl/imfelldwpica/IMFePIrm28P.ttf"
    [JetBrainsMono-Regular.ttf]="https://github.com/JetBrains/JetBrainsMono/raw/master/fonts/ttf/JetBrainsMono-Regular.ttf"
)

install_fonts() {
    (( NO_FONTS )) && { say "Fonts: skipped (--no-fonts)"; return; }
    say "Fonts → $FONT_DIR"
    local name url out
    local any_changed=0
    for name in "${!FONT_URLS[@]}"; do
        url="${FONT_URLS[$name]}"
        out="$FONT_DIR/$name"
        if [[ -f "$out" ]]; then
            echo "  · $name (present)"
            continue
        fi
        echo "  · $name ← downloading"
        do_or_echo curl -sSL --fail --max-time 60 "'$url'" -o "'$out'" \
            || { warn "download failed for $name"; any_changed=1; continue; }
        any_changed=1
    done
    if (( any_changed )); then
        do_or_echo fc-cache -f "'$FONT_DIR'" ">/dev/null"
    fi
}

# ---- Color scheme ----------------------------------------------------------
install_color_scheme() {
    say "Color scheme → $COLOR_DIR"
    local src="$REPO_DIR/luxury-journal.colors"
    local dst="$COLOR_DIR/luxury-journal.colors"
    [[ -f "$src" ]] || die "missing $src"
    if [[ -f "$dst" ]] && ! (( FORCE )); then
        local sh_src sh_dst
        sh_src=$(sha256sum "$src" | awk '{print $1}')
        sh_dst=$(sha256sum "$dst" | awk '{print $1}')
        if [[ "$sh_src" == "$sh_dst" ]]; then
            echo "  · luxury-journal.colors (unchanged)"
            return
        else
            warn "installed color scheme differs from repo; use --force to overwrite"
            return
        fi
    fi
    do_or_echo cp "'$src'" "'$dst'"
}

# ---- Shared QML ------------------------------------------------------------
copy_shared_qml() {
    say "Copying shared QML into each plasmoid"
    local dir
    for dir in "$REPO_DIR"/plasmoids/*/; do
        do_or_echo rsync -a --delete "'$REPO_DIR/shared/qml/'" "'$dir/contents/ui/shared/'"
    done
}

# ---- Restart plasmashell so it drops cached QML and reloads our packages --
# Without this, kpackagetool6 only writes new files to disk; the running
# plasmashell keeps its already-compiled QML in memory and our edits never
# render. This is the single most common reason an "install seemed to work
# but nothing changed".
restart_plasmashell() {
    (( NO_RESTART )) && { say "plasmashell restart skipped (--no-restart)"; return; }
    say "Refreshing plasmashell"
    if (( DRY_RUN )); then
        echo "  would: clear ~/.cache/plasmashell/qmlcache/ and ~/.cache/plasma/plasmoids/"
        echo "  would: restart plasmashell"
        return
    fi
    # Clear compiled QML caches first so the process re-reads our QML.
    rm -rf "$HOME/.cache/plasmashell/qmlcache/" 2>/dev/null || true
    rm -rf "$HOME/.cache/plasma/plasmoids/" 2>/dev/null || true
    rm -rf "$HOME/.cache/QtProject.org/qmlcache/" 2>/dev/null || true

    # Try the preferred sequence first; fall back to plasmashell --replace
    # which is guaranteed to exist anywhere plasmashell does.
    if command -v kquitapp6 >/dev/null && command -v kstart6 >/dev/null; then
        kquitapp6 plasmashell >/dev/null 2>&1 || true
        kstart6 plasmashell >/dev/null 2>&1 &
    elif command -v plasmashell >/dev/null; then
        # `--replace` daemonises; redirect stdio so we don't block the script.
        nohup plasmashell --replace >/dev/null 2>&1 &
        disown 2>/dev/null || true
    else
        warn "plasmashell not in PATH — log out + back in to refresh"
        return
    fi
    echo "  · plasmashell restarted (widgets reappear in a couple of seconds)"
}

# ---- Plasmoids -------------------------------------------------------------
install_plasmoids() {
    say "Plasmoids"
    local dir id
    local installed
    installed=$(kpackagetool6 -t Plasma/Applet --list 2>/dev/null || true)
    for dir in "$REPO_DIR"/plasmoids/*/; do
        id=$(basename "$dir")
        if echo "$installed" | grep -q "^$id$"; then
            echo "  · $id (upgrade)"
            do_or_echo kpackagetool6 -t Plasma/Applet --upgrade "'$dir'"
        else
            echo "  · $id (install)"
            do_or_echo kpackagetool6 -t Plasma/Applet --install "'$dir'"
        fi
    done
}

# ---- Post-install summary --------------------------------------------------
summary() {
    cat <<EOF

Installed. Next steps:

  1. System Settings → Colors & Themes → Colors → pick "Luxury Journal".
  2. Right-click desktop → Add or Manage Widgets, add any of:
       Luxury Greeting · Tmux Tail · Journal Tasks ·
       Journal Clock · Journal Weather · Journal NowPlaying ·
       System Info · Analog Clock · Almanac ·
       Commonplace Book · Hourglass · Quick Access.
     Configure each via the wrench icon. Every widget now has a
     "Text size" slider in its config dialog as well.
  3. (optional) System Settings → Fonts → General "Caveat",
     Fixed Width "JetBrains Mono".

This script restarts plasmashell automatically (pass --no-restart to skip)
so the new QML actually loads. Existing widget instances keep their saved
config — if a config field added in this release looks blank, right-click
the widget → Remove, then Add Widgets → re-add a fresh instance.

Iterate on a single plasmoid without a Plasma restart:
    ./dev.sh preview tmuxtail
EOF
}

main() {
    preflight
    install_fonts
    install_color_scheme
    copy_shared_qml
    install_plasmoids
    restart_plasmashell
    summary
}

main "$@"
