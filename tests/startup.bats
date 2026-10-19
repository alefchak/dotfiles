load helpers

# "started" is printed only if the dotfiles' functions loaded

setup() { setup_home; }

all_stubs() {
  stub kubectl flux aws aws_completer docker
  stub_noop tofu terraform terragrunt helm k9s starship
}

@test "bash starts cleanly with no tools installed" {
  sh_run bash 'type kns frtree awsp >/dev/null && echo started'
  [ "$status" -eq 0 ]
  [ "$output" = started ]
  [ -z "$stderr" ]
}

@test "zsh starts cleanly with no tools installed" {
  sh_run zsh 'type kns frtree awsp >/dev/null && echo started'
  [ "$status" -eq 0 ]
  [ "$output" = started ]
  [ -z "$stderr" ]
}

@test "bash starts cleanly with every tool installed" {
  all_stubs
  sh_run bash 'type kns frtree awsp >/dev/null && echo started'
  [ "$status" -eq 0 ]
  [ "$output" = started ]
  [ -z "$stderr" ]
}

@test "zsh starts cleanly with every tool installed" {
  all_stubs
  sh_run zsh 'type kns frtree awsp >/dev/null && echo started'
  [ "$status" -eq 0 ]
  [ "$output" = started ]
  [ -z "$stderr" ]
}

@test "real Tab press works in zsh" {
  stub kubectl
  run tab zsh 'kubectl ge'
  [ "$status" -eq 0 ]
  [ "$output" = "kubectl get " ]
}

@test "real Tab press works in bash" {
  skip_unless_bash4
  stub kubectl
  run tab bash 'kubectl ge'
  [ "$status" -eq 0 ]
  [ "$output" = "kubectl get " ]
}
