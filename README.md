# dotfiles

## Platforms

Everything must work in both bash and zsh on:

- RHEL 8
- Windows WSL
- modern Ubuntu
- modern macOS

CI runs the tests on ubuntu-latest, macos-latest and Rocky Linux 8.10 (a RHEL 8 rebuild). WSL runs Ubuntu
by default, so the Ubuntu job covers it; behavior specific to WSL (Windows paths, the clipboard) is not
tested.

## Setup

macOS:

```sh
brew bundle          # tools these dotfiles use, plus this machine's extras
```

Linux and WSL: install `stow` and the tools you want with the system package manager (on RHEL 8, `stow`
is in EPEL).

Then, on any platform:

```sh
stow <package>...    # e.g. stow zsh common git k8s
```

Each package configures its tool only when the tool is installed, so packages for missing tools are harmless.

## Tests

```sh
bats tests     # both shells, against stub tools in a throwaway $HOME
tests/lint     # shellcheck the bash and shared files
```

Tests that need bash 4 or later skip on macOS's bash 3.2; CI runs them on Linux.
