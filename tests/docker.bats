load helpers

setup() {
  setup_home
  stub docker
  printf 'web\nworker\n' > "$STATE/containers"
  printf 'pgdata\nuploads\n' > "$STATE/volumes"
}

@test "bash: dbash, dvbackup and dvrestore have completion" {
  sh_run bash 'complete -p dbash dvbackup dvrestore'
  assert_eq "$(normalize_specs "$output")" "complete -F _dbash dbash
complete -F _dvbackup dvbackup
complete -o plusdirs -f -X !*.tar.gz dvrestore"
}

@test "bash: dbash completes containers and dvbackup volumes" {
  sh_run bash '
    COMP_WORDS=(dbash w); COMP_CWORD=1; _dbash; echo "[${COMPREPLY[*]}]"
    COMP_WORDS=(dvbackup u); COMP_CWORD=1; _dvbackup; echo "[${COMPREPLY[*]}]"'
  assert_eq "$output" "[web worker]
[uploads]"
}

@test "zsh: dbash completes containers and dvbackup volumes" {
  sh_run zsh "$ZSH_COMPADD"'_dbash; echo --; _dvbackup'
  assert_eq "$output" "web
worker
--
pgdata
uploads"
}

@test "zsh: Tab on dvrestore offers only .tar.gz archives" {
  touch "$HOME_DIR/pgdata.tar.gz" "$HOME_DIR/pgdata.txt"
  run tab zsh 'dvrestore pg'
  assert_eq "$output" "dvrestore pgdata.tar.gz "
}

@test "bash: Tab on dvrestore offers only .tar.gz archives" {
  skip_unless_bash4
  touch "$HOME_DIR/pgdata.tar.gz" "$HOME_DIR/pgdata.txt"
  run tab bash 'dvrestore pg'
  assert_eq "$output" "dvrestore pgdata.tar.gz "
}
