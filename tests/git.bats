load helpers

# A bare origin with two clones: ours pushes "one"; theirs adds "two" on top
setup() {
  setup_home
  ln -s "$REPO/git/.gitconfig" "$HOME_DIR/.gitconfig"
  W=$BATS_TEST_TMPDIR/w
  mkdir "$W"
  CLONES="cd '$W' && git init -q --bare origin.git && git clone -q origin.git ours 2>/dev/null && git clone -q origin.git theirs 2>/dev/null
    cd ours && echo 1 > f && git add f && git commit -qm one && git push -q && cd ..
    THEIRS='cd ../theirs && git pull -q && echo 2 >> f && git commit -qam two && git push -q && cd ../ours'"
}

origin_log() { git -C "$W/origin.git" log --format=%s main | tr '\n' ' '; }

check_gpf_rewrites() {
  sh_run "$1" "$CLONES"'
    cd ours && git commit -q --amend -m "one, reworded" && gpf -q'
  [ "$status" -eq 0 ]
  assert_eq "$(origin_log)" "one, reworded "
}
@test "bash: gpf force-pushes a rewritten branch" { check_gpf_rewrites bash; }
@test "zsh: gpf force-pushes a rewritten branch" { check_gpf_rewrites zsh; }

# A background fetch moves origin/main, so the lease alone would pass
check_gpf_refuses_unseen() {
  sh_run "$1" "$CLONES"'
    cd ours && eval "$THEIRS" && git fetch -q && git commit -q --amend -m "one, reworded" && gpf'
  [ "$status" -ne 0 ]
  [[ $stderr == *"(remote ref updated since checkout)"* ]]   # the force-if-includes check
  assert_eq "$(origin_log)" "two one "
}
@test "bash: gpf refuses to overwrite commits only a background fetch has seen" { check_gpf_refuses_unseen bash; }
@test "zsh: gpf refuses to overwrite commits only a background fetch has seen" { check_gpf_refuses_unseen zsh; }

@test "without push.useForceIfIncludes the same push overwrites their commit" {
  sh_run bash "$CLONES"'
    cd ours && eval "$THEIRS" && git fetch -q && git commit -q --amend -m "one, reworded" &&
    git -c push.useForceIfIncludes=false pushf -q'
  [ "$status" -eq 0 ]
  assert_eq "$(origin_log)" "one, reworded "
}
