#!/usr/bin/env bash

set -e

# Detect distro
detect_distro() {
    if command -v emerge &>/dev/null; then
        echo "gentoo"
    elif command -v dnf &>/dev/null; then
        echo "fedora"
    elif command -v pacman &>/dev/null; then
        echo "arch"
    else
        echo "unknown"
    fi
}

DISTRO=$(detect_distro)
echo "Detected distro: $DISTRO"
read -p "Continue with this distro? (y/n) " CONFIRM
if [[ "$CONFIRM" != "y" ]]; then
    echo "Select your distro:"
    select choice in gentoo fedora arch; do
        DISTRO=$choice
        break
    done
fi

# Install dependencies
case $DISTRO in
    gentoo)
        sudo emerge --ask app-shells/zsh dev-vcs/git curl ;;
    fedora)
        sudo dnf install -y zsh git curl ;;
    arch)
        sudo pacman -S --needed --noconfirm zsh git curl ;;
    *)
        echo "Unsupported distro. Exiting."
        exit 1 ;;
esac

# Make sure zsh is in /etc/shells
if ! grep -q "$(which zsh)" /etc/shells; then
    echo "Adding $(which zsh) to /etc/shells..."
    echo "$(which zsh)" | sudo tee -a /etc/shells
fi

# Offer to make zsh default shell
read -p "Do you want to set Zsh as your default shell? (y/n) " SET_DEFAULT
if [[ "$SET_DEFAULT" == "y" ]]; then
    chsh -s "$(which zsh)"
    echo "✅ Zsh set as default shell. It will take effect on next login."
fi

# Install Oh My Zsh
echo "Installing Oh My Zsh..."
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
    echo "Oh My Zsh already installed."
fi

# Install plugins
ZSH_CUSTOM=${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}
mkdir -p "$ZSH_CUSTOM/plugins"

git clone https://github.com/zsh-users/zsh-autosuggestions.git \
    $ZSH_CUSTOM/plugins/zsh-autosuggestions || echo "autosuggestions already installed"

# Let user choose syntax highlighting plugin
echo "Choose a syntax highlighting plugin:"
select plugin in "zsh-syntax-highlighting" "fast-syntax-highlighting"; do
    case $plugin in
        zsh-syntax-highlighting)
            git clone https://github.com/zsh-users/zsh-syntax-highlighting.git \
                $ZSH_CUSTOM/plugins/zsh-syntax-highlighting || echo "zsh-syntax-highlighting already installed"
            SYNTAX_PLUGIN="zsh-syntax-highlighting"
            break ;;
        fast-syntax-highlighting)
            git clone https://github.com/zdharma-continuum/fast-syntax-highlighting.git \
                $ZSH_CUSTOM/plugins/fast-syntax-highlighting || echo "fast-syntax-highlighting already installed"
            SYNTAX_PLUGIN="fast-syntax-highlighting"
            break ;;
    esac
done

# Backup existing .zshrc before modifying
if [[ -f "$HOME/.zshrc" ]]; then
    BACKUP="$HOME/.zshrc.backup-$(date +%F-%H%M%S)"
    cp "$HOME/.zshrc" "$BACKUP"
    echo "📦 Backed up existing .zshrc to $BACKUP"
fi

# Update .zshrc
echo "Configuring ~/.zshrc..."
if grep -q "plugins=(" ~/.zshrc; then
    sed -i "s/^plugins=(.*)/plugins=(git zsh-autosuggestions $SYNTAX_PLUGIN)/" ~/.zshrc
else
    echo "plugins=(git zsh-autosuggestions $SYNTAX_PLUGIN)" >> ~/.zshrc
fi

echo "✅ Installation complete!"
echo "Restart your terminal or run 'exec zsh' to start using Zsh."
