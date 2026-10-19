# Shared test setup: a fake stowed $HOME and stub tools, fresh for every test.

bats_require_minimum_version 1.5.0

REPO=$(cd "$BATS_TEST_DIRNAME/.." && pwd)

# Creates $HOME_DIR (the repo's files linked in, as stow would), $BIN (stubs, first on PATH)
# and $STATE (files the stubs read and log to).
setup_home() {
  HOME_DIR=$BATS_TEST_TMPDIR/home
  BIN=$BATS_TEST_TMPDIR/bin
  STATE=$BATS_TEST_TMPDIR/state
  mkdir -p "$HOME_DIR/.aliases" "$HOME_DIR/.bash" "$HOME_DIR/.zsh" "$BIN" "$STATE"
  local d f
  for d in .aliases .bash .zsh; do
    for f in "$REPO"/*/"$d"/*; do ln -s "$f" "$HOME_DIR/$d/"; done
  done
  ln -s "$REPO/bash/.bashrc" "$HOME_DIR/.bashrc"
  ln -s "$REPO/zsh/.zshrc" "$HOME_DIR/.zshrc"
  # Only stubs and the base system are on PATH, so tests never reach real tools or config
  TEST_ENV=(HOME="$HOME_DIR" PATH="$BIN:/usr/bin:/bin" STATE="$STATE" TERM=dumb)
}

# stub kubectl flux ...: put those stub tools on PATH
stub() {
  local t
  for t; do ln -s "$BATS_TEST_DIRNAME/stubs/$t" "$BIN/$t"; done
}

# stub_as <stub> <name>...: install one stub under other names
stub_as() {
  local s=$1 t; shift
  for t; do ln -s "$BATS_TEST_DIRNAME/stubs/$s" "$BIN/$t"; done
}

# stub_noop tofu ...: a tool that exists but does nothing
stub_noop() { stub_as noop "$@"; }

# sh_run <bash|zsh> '<snippet>' [VAR=value...]: run the snippet in an interactive shell with the
# dotfiles loaded. Sets $status, $output (stdout) and $stderr, with the job control noise an
# interactive shell without a terminal prints removed from $stderr.
sh_run() {
  local sh=$1 snippet=$2; shift 2
  run --separate-stderr env -i "${TEST_ENV[@]}" "$@" "$sh" -ic "$snippet"
  stderr=$(printf '%s\n' "$stderr" | grep -vE 'job control|terminal process group|Inappropriate ioctl' || true)
}

# tab <bash|zsh> '<text>' [VAR=value...]: type the text and press Tab in a real interactive shell,
# started in $HOME_DIR. Prints the edited line.
tab() {
  local sh=$1 text=$2; shift 2
  (cd "$HOME_DIR" && env -i "${TEST_ENV[@]}" "$@" python3 "$BATS_TEST_DIRNAME/tab.py" "$sh" "$text")
}

# Bash before 4 has no BASH_ALIASES, mapfile or READLINE_LINE, so alias completion and real Tab
# presses are not available there.
skip_unless_bash4() {
  [ "$(bash -c 'echo ${BASH_VERSINFO[0]}')" -ge 4 ] || skip "needs bash >= 4"
}

# assert_eq <actual> <expected>: on mismatch, fail showing both
assert_eq() {
  [ "$1" = "$2" ] && return
  printf 'expected: %s\nactual:   %s\n' "$2" "$1" >&2
  return 1
}

# zsh's compadd only works inside a completion widget. This replacement prints the candidates
# instead, so zsh completion functions can be called directly. Prepend it to a zsh snippet.
# shellcheck disable=SC2016,SC2034 # zsh code, used by the .bats files
ZSH_COMPADD='compadd() { [[ $1 == -- ]] && shift; print -rl -- "$@"; };'
