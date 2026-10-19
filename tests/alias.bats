load helpers

# Bash completes an alias as the command it expands to through _complete_alias (bash/.bashrc);
# zsh does it by default. k uses a completion function (-F), awswho an external completer (-C).

setup() {
  setup_home
  stub kubectl aws aws_completer
}

@test "bash: simple aliases complete through _complete_alias, others do not" {
  skip_unless_bash4
  sh_run bash 'complete -p k awswho; complete -p pull || echo "pull: none"'
  assert_eq "$(normalize_specs "$output")" "complete -o bashdefault -o default -F _complete_alias k
complete -o bashdefault -o default -F _complete_alias awswho
pull: none"
}

@test "bash: _complete_alias forwards to a completion function" {
  skip_unless_bash4
  sh_run bash 'COMP_WORDS=(k ge); COMP_CWORD=1; COMP_LINE="k ge"; COMP_POINT=4; _complete_alias; echo "[${COMPREPLY[*]}]"'
  assert_eq "$output" "[get]"
}

@test "bash: _complete_alias forwards the expanded line to a completer command" {
  skip_unless_bash4
  sh_run bash 'COMP_WORDS=(awswho --ou); COMP_CWORD=1; COMP_LINE="awswho --ou"; COMP_POINT=11; _complete_alias; echo "[${COMPREPLY[*]}]"'
  assert_eq "$output" "[--output]"
  assert_eq "$(cat "$STATE/aws_completer.log")" "COMP_LINE=[aws sts get-caller-identity --ou] COMP_POINT=[32]"
}

check_tab_alias() {
  run tab "$1" 'k ge';         assert_eq "$output" "k get "
  run tab "$1" 'awswho --ou';  assert_eq "$output" "awswho --output "
}
@test "bash: Tab completes aliases as their expansion" { skip_unless_bash4; check_tab_alias bash; }
@test "zsh: Tab completes aliases as their expansion" { check_tab_alias zsh; }
