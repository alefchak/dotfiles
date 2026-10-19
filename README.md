# dotfiles

## Setup (macOS)

```sh
brew bundle          # tools these dotfiles use, plus this machine's extras
stow <package>...    # e.g. stow zsh common git k8s
```

Each package configures its tool only when the tool is installed, so packages for missing tools are harmless.
