load helpers

setup() {
  setup_home
  stub aws aws_completer
  printf 'default\nprod\nstaging\n' > "$STATE/aws-profiles"
}

check_pager_disabled() {
  sh_run "$1" 'echo "[${AWS_PAGER-unset}]"'
  assert_eq "$output" "[]"
}
@test "bash: AWS_PAGER is empty" { check_pager_disabled bash; }
@test "zsh: AWS_PAGER is empty" { check_pager_disabled zsh; }

check_awsp() {
  sh_run "$1" '
    awsp prod; echo "set: $AWS_PROFILE"
    awsp nope; echo "rc=$? kept: $AWS_PROFILE"
    awsp; echo "cleared: ${AWS_PROFILE-unset}"'
  assert_eq "$output" "set: prod
rc=1 kept: prod
cleared: unset"
  assert_eq "$stderr" "awsp: no such profile: nope"
}
@test "bash: awsp sets, rejects unknown and clears the profile" { check_awsp bash; }
@test "zsh: awsp sets, rejects unknown and clears the profile" { check_awsp zsh; }

check_awsp_stale() {
  sh_run "$1" 'awsp staging && echo "$AWS_PROFILE"' AWS_PROFILE=gone
  assert_eq "$output" staging
}
@test "bash: awsp works when AWS_PROFILE names a missing profile" { check_awsp_stale bash; }
@test "zsh: awsp works when AWS_PROFILE names a missing profile" { check_awsp_stale zsh; }

check_awswho() {
  sh_run "$1" 'awswho'
  assert_eq "$output" '{"Account": "123456789012"}'
  grep -qx 'aws sts get-caller-identity' "$STATE/calls.log"
}
@test "bash: awswho runs sts get-caller-identity" { check_awswho bash; }
@test "zsh: awswho runs sts get-caller-identity" { check_awswho zsh; }

@test "bash: awsp completes profile names, first argument only" {
  sh_run bash '
    COMP_WORDS=(awsp p); COMP_CWORD=1; _awsp; echo "[${COMPREPLY[*]}]"
    COMP_WORDS=(awsp ""); COMP_CWORD=1; _awsp; echo "[${COMPREPLY[*]}]"
    COMPREPLY=(); COMP_WORDS=(awsp prod ""); COMP_CWORD=2; _awsp; echo "[${COMPREPLY[*]}]"' AWS_PROFILE=gone
  assert_eq "$output" "[prod]
[default prod staging]
[]"
}

@test "zsh: awsp completes profile names, first argument only" {
  sh_run zsh "$ZSH_COMPADD"'
    CURRENT=2; _awsp; echo --
    CURRENT=3; _awsp; echo --' AWS_PROFILE=gone
  assert_eq "$output" "default
prod
staging
--
--"
}

@test "bash: aws completes through aws_completer" {
  sh_run bash 'complete -p aws'
  assert_eq "$(normalize_specs "$output")" "complete -C aws_completer aws"
}

@test "zsh: Tab on aws completes through aws_completer" {
  run tab zsh 'aws st'
  assert_eq "$output" "aws sts "
}

@test "bash: aws gets no completion without aws_completer" {
  rm "$BIN/aws_completer"
  sh_run bash 'complete -p aws'
  [ "$status" -ne 0 ]
}
