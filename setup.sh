#!/bin/sh
set -e

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

printf "==> Installing dotfiles from %s\n" "$DOTFILES_DIR"

# --- detect package manager ---
if command -v dnf >/dev/null 2>&1; then
    PKG_MGR="dnf"
    PKG_INSTALL="sudo dnf install -y"
elif command -v brew >/dev/null 2>&1; then
    PKG_MGR="brew"
    PKG_INSTALL="brew install"
else
    PKG_MGR=""
    PKG_INSTALL=""
    printf "Warning: neither dnf nor brew found.\n"
    printf "You will need to install these packages manually: tmux neovim cowsay fortune\n"
fi
printf "Using package manager: %s\n" "$PKG_MGR"

# --- install dependencies ---
if [ -n "$PKG_MGR" ]; then
    PACKAGES=""
    for pkg in tmux nvim cowsay; do
        if ! command -v "$pkg" >/dev/null 2>&1; then
            case "$pkg" in
                nvim) PACKAGES="$PACKAGES neovim" ;;
                *)    PACKAGES="$PACKAGES $pkg" ;;
            esac
        fi
    done
    if ! command -v fortune >/dev/null 2>&1; then
        if [ "$PKG_MGR" = "dnf" ]; then
            PACKAGES="$PACKAGES fortune-mod"
        else
            PACKAGES="$PACKAGES fortune"
        fi
    fi

    if [ -n "$PACKAGES" ]; then
        printf "==> Installing packages:%s\n" "$PACKAGES"
        $PKG_INSTALL $PACKAGES
    else
        printf "All dependencies already installed\n"
    fi
fi

# --- oh-my-zsh ---
if [ -d "$HOME/.config/oh-my-zsh" ]; then
    printf "oh-my-zsh already installed, skipping\n"
else
    printf "==> Installing oh-my-zsh\n"
    git clone https://github.com/ohmyzsh/ohmyzsh.git "$HOME/.config/oh-my-zsh"
fi

# --- tmux plugin manager ---
if [ -d "$HOME/.config/tmux/plugins/tpm" ]; then
    printf "TPM already installed, skipping\n"
else
    printf "==> Installing TPM\n"
    mkdir -p "$HOME/.config/tmux/plugins"
    git clone https://github.com/tmux-plugins/tpm "$HOME/.config/tmux/plugins/tpm"
fi

# --- configure zshrc ---
printf "==> Configuring zshrc\n"
if [ -f "$HOME/.zshrc" ] || [ -L "$HOME/.zshrc" ]; then
    BAK="$HOME/.zshrc.bak"
    N=1
    while [ -f "$BAK" ]; do
        BAK="$HOME/.zshrc.bak.$N"
        N=$((N + 1))
    done
    printf "  Backing up existing .zshrc to %s\n" "$(basename "$BAK")"
    cp "$HOME/.zshrc" "$BAK"
fi
touch "$HOME/.zshrc"

ZSHRC="$HOME/.zshrc"
CHANGED=0

# oh-my-zsh setup
if ! grep -q 'oh-my-zsh' "$ZSHRC" 2>/dev/null; then
    printf "  Adding oh-my-zsh config\n"
    cat >> "$ZSHRC" <<'EOF'

# oh-my-zsh
export ZSH="$HOME/.config/oh-my-zsh"
ZSH_THEME="robbyrussell"
plugins=(git)
source $ZSH/oh-my-zsh.sh
EOF
    CHANGED=1
fi

# vim/nvim alias
if ! grep -q 'alias vim="nvim"' "$ZSHRC" 2>/dev/null; then
    printf "  Adding nvim alias\n"
    cat >> "$ZSHRC" <<'EOF'

alias vim="nvim"
EOF
    CHANGED=1
fi

# PATH
if ! grep -q '$HOME/.local/bin' "$ZSHRC" 2>/dev/null; then
    printf "  Adding ~/.local/bin to PATH\n"
    cat >> "$ZSHRC" <<'EOF'

export PATH="$HOME/.local/bin:$PATH"
EOF
    CHANGED=1
fi

# tmux auto-start
if ! grep -q 'TMUX' "$ZSHRC" 2>/dev/null; then
    printf "  Adding tmux auto-start\n"
    cat >> "$ZSHRC" <<'EOF'

# Start tmux on shell launch
if [ -z "$TMUX" ]; then
    tmux
else
    fortune -s | cowsay -r
fi
EOF
    CHANGED=1
fi

if [ "$CHANGED" -eq 0 ]; then
    printf "  All zshrc components already present, no changes made\n"
fi

printf "==> Linking tmux.conf\n"
if [ -f "$HOME/.config/tmux/tmux.conf" ] || [ -L "$HOME/.config/tmux/tmux.conf" ]; then
    TBAK="$HOME/.config/tmux/tmux.conf.bak"
    N=1
    while [ -f "$TBAK" ]; do
        TBAK="$HOME/.config/tmux/tmux.conf.bak.$N"
        N=$((N + 1))
    done
    printf "  Backing up existing tmux.conf to %s\n" "$(basename "$TBAK")"
    mv "$HOME/.config/tmux/tmux.conf" "$TBAK"
fi
mkdir -p "$HOME/.config/tmux"
ln -s "$DOTFILES_DIR/tmux.conf" "$HOME/.config/tmux/tmux.conf"

# --- install tmux plugins via TPM ---
printf "==> Installing tmux plugins\n"
"$HOME/.config/tmux/plugins/tpm/bin/install_plugins"

printf "\nDone! Start a new zsh session to pick up changes.\n"
