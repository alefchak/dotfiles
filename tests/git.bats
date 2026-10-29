load helpers

# A bare origin with two clones: ours pushes "one"; theirs adds "two" on top
setup() {
  setup_home
  ln -s "$REPO/git/.gitconfig" "$HOME_DIR/.gitconfig"
  mkdir -p "$HOME_DIR/.local/bin"
  ln -s "$REPO/git/.local/bin/git-gone" "$HOME_DIR/.local/bin/"
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

# In ours, four pushed branches: sq is squash-merged, mg merged, ex squash-merged plus a commit
# never pushed, al not merged. Then sq, mg and ex are deleted on origin, so their upstreams are gone.
GONE_BRANCHES='cd ours && git remote set-head origin -a >/dev/null
  mk() { git switch -qc "$1" main && echo "$1" > "$1" && git add "$1" && git commit -qm "$1" &&
    git push -qu origin "$1" && git switch -q main; }
  mk sq && git merge -q --squash sq && git commit -qm "squash sq"
  mk mg && git merge -q mg
  mk ex && git merge -q --squash ex && git commit -qm "squash ex"
  git switch -q ex && echo more >> ex && git commit -qam more && git switch -q main
  mk al
  git push -q && git push -q origin --delete sq mg ex && git fetch -q'

branches() { git -C "$W/ours" branch --format='%(refname:short)' | sort | tr '\n' ' '; }

check_gone() {
  sh_run "$1" "$CLONES
    $GONE_BRANCHES"'
    git gone'
  [ "$status" -eq 0 ]
  [[ $output == *"Deleted branch mg "* ]]
  [[ $output == *"Deleted branch sq "* ]]
  [[ $output == *"Kept ex: has changes not in origin/main"* ]]
  assert_eq "$(branches)" "al ex main "
}
@test "bash: git gone deletes merged and squash-merged branches, keeps unmerged work" { check_gone bash; }
@test "zsh: git gone deletes merged and squash-merged branches, keeps unmerged work" { check_gone zsh; }

check_gone_no_remote_head() {
  sh_run "$1" "$CLONES
    $GONE_BRANCHES"'
    git remote set-head origin -d && git gone'
  [ "$status" -eq 0 ]
  [[ $output == *"Kept sq: origin/HEAD is not set (git remote set-head origin -a)"* ]]
  assert_eq "$(branches)" "al ex main mg sq "
}
@test "bash: git gone keeps every branch when origin/HEAD is not set" { check_gone_no_remote_head bash; }
@test "zsh: git gone keeps every branch when origin/HEAD is not set" { check_gone_no_remote_head zsh; }
