#!/usr/bin/env bash
set -euo pipefail

# ─────────────────────────────────────────────────────────────
# lrc-tools installer
# ─────────────────────────────────────────────────────────────

BOLD='\033[1m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
RESET='\033[0m'

LRC_DATA_DIR="$HOME/.local/share/lrc-tools"
LRC_CONFIG_DIR="$HOME/.config/lrc-tools"
LYRICS_RAW="$LRC_DATA_DIR/lyrics/raw"
LYRICS_PROCESSED="$LRC_DATA_DIR/lyrics/processed"
MUSIC_DIR="$HOME/music"

info()  { echo -e "${CYAN}::${RESET} $1"; }
ok()    { echo -e "${GREEN}✓${RESET} $1"; }
warn()  { echo -e "${YELLOW}!${RESET} $1"; }
err()   { echo -e "${RED}✗${RESET} $1"; }

# ─────────────────────────────────────────────────────────────
# Detect OS and package manager
# ─────────────────────────────────────────────────────────────
detect_pkg_manager() {
    if command -v pacman &>/dev/null; then
        echo "pacman"
    elif command -v apt &>/dev/null; then
        echo "apt"
    elif command -v dnf &>/dev/null; then
        echo "dnf"
    elif command -v brew &>/dev/null; then
        echo "brew"
    else
        echo "unknown"
    fi
}

# ─────────────────────────────────────────────────────────────
# Detect shell rc file
# ─────────────────────────────────────────────────────────────
detect_shell_rc() {
    local shell_name
    shell_name="$(basename "$SHELL")"
    case "$shell_name" in
        zsh)  echo "$HOME/.zshrc" ;;
        fish) echo "$HOME/.config/fish/config.fish" ;;
        *)    echo "$HOME/.bashrc" ;;
    esac
}

# ─────────────────────────────────────────────────────────────
# Install system dependencies
# ─────────────────────────────────────────────────────────────
install_system_deps() {
    local pkg_manager="$1"
    local missing=()

    for cmd in playerctl ffprobe mpv; do
        if ! command -v "$cmd" &>/dev/null; then
            missing+=("$cmd")
        fi
    done

    if [ ${#missing[@]} -eq 0 ]; then
        ok "System dependencies already installed"
        return 0
    fi

    warn "Missing system packages: ${missing[*]}"

    case "$pkg_manager" in
        pacman)
            local pkgs=()
            for cmd in "${missing[@]}"; do
                case "$cmd" in
                    playerctl) pkgs+=("playerctl") ;;
                    ffprobe)   pkgs+=("ffmpeg") ;;
                    mpv)       pkgs+=("mpv" "mpv-mpris") ;;
                esac
            done
            info "Installing: ${pkgs[*]}"
            sudo pacman -S --needed --noconfirm "${pkgs[@]}"
            ;;
        apt)
            local pkgs=()
            for cmd in "${missing[@]}"; do
                case "$cmd" in
                    playerctl) pkgs+=("playerctl") ;;
                    ffprobe)   pkgs+=("ffmpeg") ;;
                    mpv)       pkgs+=("mpv") ;;
                esac
            done
            info "Installing: ${pkgs[*]}"
            sudo apt install -y "${pkgs[@]}"
            if [[ " ${missing[*]} " =~ " mpv " ]]; then
                warn "mpv-mpris may need to be built from source on Debian/Ubuntu"
                warn "See: https://github.com/hoyon/mpv-mpris"
            fi
            ;;
        dnf)
            local pkgs=()
            for cmd in "${missing[@]}"; do
                case "$cmd" in
                    playerctl) pkgs+=("playerctl") ;;
                    ffprobe)   pkgs+=("ffmpeg-free") ;;
                    mpv)       pkgs+=("mpv") ;;
                esac
            done
            info "Installing: ${pkgs[*]}"
            sudo dnf install -y "${pkgs[@]}"
            ;;
        brew)
            for cmd in "${missing[@]}"; do
                case "$cmd" in
                    playerctl) warn "playerctl is Linux-only — macOS is not fully supported" ;;
                    ffprobe)   brew install ffmpeg ;;
                    mpv)       brew install mpv ;;
                esac
            done
            ;;
        *)
            err "Unknown package manager. Please install manually: ${missing[*]}"
            return 1
            ;;
    esac

    ok "System dependencies installed"
}

# ─────────────────────────────────────────────────────────────
# Install lrc-tools Python package
# ─────────────────────────────────────────────────────────────
install_python_package() {
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

    info "Installing lrc-tools Python package..."
    pip install "$script_dir[full]" --break-system-packages 2>/dev/null \
        || pip install "$script_dir[full]"
    ok "Python package installed"
}

# ─────────────────────────────────────────────────────────────
# Create directory structure
# ─────────────────────────────────────────────────────────────
create_directories() {
    info "Creating directories..."
    mkdir -p "$LYRICS_RAW" "$LYRICS_PROCESSED" "$LRC_CONFIG_DIR"

    if [ ! -d "$MUSIC_DIR" ]; then
        mkdir -p "$MUSIC_DIR"
        ok "Created $MUSIC_DIR — put your music files here"
    fi

    ok "Data directories ready"
}

# ─────────────────────────────────────────────────────────────
# Copy default config if missing
# ─────────────────────────────────────────────────────────────
install_config() {
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local config_dest="$LRC_CONFIG_DIR/config.yaml"

    if [ ! -f "$config_dest" ]; then
        if [ -f "$script_dir/config.yaml" ]; then
            cp "$script_dir/config.yaml" "$config_dest"
            ok "Default config installed to $config_dest"
        fi
    else
        ok "Config already exists at $config_dest"
    fi

    # Copy example custom fonts if provided and not already present
    local fonts_dest="$LRC_CONFIG_DIR/custom_fonts.json"
    if [ ! -f "$fonts_dest" ] && [ -f "$script_dir/custom_fonts.json" ]; then
        cp "$script_dir/custom_fonts.json" "$fonts_dest"
        ok "Custom fonts installed to $fonts_dest"
    fi
}

# ─────────────────────────────────────────────────────────────
# Add shell aliases
# ─────────────────────────────────────────────────────────────
install_aliases() {
    local rc_file="$1"
    local marker="# >>> lrc-tools >>>"
    local end_marker="# <<< lrc-tools <<<"

    # Remove old block if present
    if grep -q "$marker" "$rc_file" 2>/dev/null; then
        sed -i "/$marker/,/$end_marker/d" "$rc_file"
    fi

    local shell_name
    shell_name="$(basename "$SHELL")"

    if [ "$shell_name" = "fish" ]; then
        cat >> "$rc_file" << 'FISH_ALIASES'
# >>> lrc-tools >>>
alias lyrics "lrc-vis --lrc-dir ~/.local/share/lrc-tools/lyrics/processed --wlrc --font mini"
alias lyrics-fetch "lrc-fetch --audio-dir ~/music --output-dir ~/.local/share/lrc-tools/lyrics/raw"
alias lyrics-process "lrc-processor --lrc-dir ~/.local/share/lrc-tools/lyrics/raw --audio-dir ~/music --output-dir ~/.local/share/lrc-tools/lyrics/processed --wlrc"
# <<< lrc-tools <<<
FISH_ALIASES
    else
        cat >> "$rc_file" << 'SHELL_ALIASES'
# >>> lrc-tools >>>
alias lyrics="lrc-vis --lrc-dir ~/.local/share/lrc-tools/lyrics/processed --wlrc --font mini"
alias lyrics-fetch="lrc-fetch --audio-dir ~/music --output-dir ~/.local/share/lrc-tools/lyrics/raw"
alias lyrics-process="lrc-processor --lrc-dir ~/.local/share/lrc-tools/lyrics/raw --audio-dir ~/music --output-dir ~/.local/share/lrc-tools/lyrics/processed --wlrc"
# <<< lrc-tools <<<
SHELL_ALIASES
    fi

    ok "Aliases added to $rc_file"
}

# ─────────────────────────────────────────────────────────────
# Main
# ─────────────────────────────────────────────────────────────
main() {
    echo
    echo -e "${BOLD}╔══════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}║         lrc-tools installer          ║${RESET}"
    echo -e "${BOLD}╚══════════════════════════════════════╝${RESET}"
    echo

    local pkg_manager
    pkg_manager="$(detect_pkg_manager)"
    info "Detected package manager: $pkg_manager"

    local rc_file
    rc_file="$(detect_shell_rc)"
    info "Shell config: $rc_file"
    echo

    # Step 1: System deps
    echo -e "${BOLD}[1/5] System dependencies${RESET}"
    install_system_deps "$pkg_manager"
    echo

    # Step 2: Python package
    echo -e "${BOLD}[2/5] Python package${RESET}"
    install_python_package
    echo

    # Step 3: Directories
    echo -e "${BOLD}[3/5] Directory structure${RESET}"
    create_directories
    echo

    # Step 4: Config files
    echo -e "${BOLD}[4/5] Configuration${RESET}"
    install_config
    echo

    # Step 5: Shell aliases
    echo -e "${BOLD}[5/5] Shell aliases${RESET}"
    install_aliases "$rc_file"
    echo

    echo -e "${BOLD}══════════════════════════════════════${RESET}"
    echo -e "${GREEN}${BOLD}Installation complete!${RESET}"
    echo -e "${BOLD}══════════════════════════════════════${RESET}"
    echo
    echo "  Reload your shell:"
    echo -e "    ${CYAN}source $rc_file${RESET}"
    echo
    echo "  Quick start:"
    echo -e "    ${CYAN}lyrics-fetch${RESET}      Fetch lyrics for ~/music"
    echo -e "    ${CYAN}lyrics-process${RESET}    Process into word-level timing"
    echo -e "    ${CYAN}lyrics${RESET}            Show lyrics while music plays"
    echo
}

main "$@"
