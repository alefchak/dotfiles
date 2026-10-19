# dotfiles

## Setup (macOS)

```sh
brew bundle          # tools these dotfiles use, plus this machine's extras
stow <package>...    # e.g. stow zsh common git k8s
```

Each package configures its tool only when the tool is installed, so packages for missing tools are harmless.

## Tests

```sh
bats tests     # both shells, against stub tools in a throwaway $HOME
tests/lint     # shellcheck the bash and shared files
```

Tests that need bash 4 or later skip on macOS's bash 3.2; CI runs them on Linux.
