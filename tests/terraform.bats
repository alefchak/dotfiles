load helpers

setup() { setup_home; }

# alias_of <bash|zsh> <name>: print what the alias expands to
alias_of() {
  if [ "$1" = bash ]; then sh_run bash "alias $2"; else sh_run zsh "alias $2"; fi
  output=${output#alias }; output=${output#*=}; output=${output//\'/}
}

check_tf_prefers_tofu() {
  stub_as tfcompleter tofu terraform terragrunt
  alias_of "$1" tf; assert_eq "$output" tofu
  alias_of "$1" tg; assert_eq "$output" terragrunt
}
@test "bash: tf runs tofu when both are installed" { check_tf_prefers_tofu bash; }
@test "zsh: tf runs tofu when both are installed" { check_tf_prefers_tofu zsh; }

check_tf_falls_back() {
  stub_as tfcompleter terraform
  alias_of "$1" tf; assert_eq "$output" terraform
}
@test "bash: tf runs terraform without tofu" { check_tf_falls_back bash; }
@test "zsh: tf runs terraform without tofu" { check_tf_falls_back zsh; }

@test "bash: each tool and alias completes through its own binary" {
  stub_as tfcompleter tofu terraform terragrunt
  sh_run bash 'complete -p terraform tofu terragrunt tf tg'
  assert_eq "$output" "complete -o nospace -C terraform terraform
complete -o nospace -C tofu tofu
complete -o nospace -C terragrunt terragrunt
complete -o nospace -C tofu tf
complete -o nospace -C terragrunt tg"
}

@test "zsh: Tab completes tofu, tf and tg, without a trailing space" {
  stub_as tfcompleter tofu terragrunt
  run tab zsh 'tofu pl'; assert_eq "$output" "tofu plan"
  run tab zsh 'tf pl';   assert_eq "$output" "tf plan"
  run tab zsh 'tg pl';   assert_eq "$output" "tg plan"
}

@test "bash: Tab completes tf and tg" {
  skip_unless_bash4
  stub_as tfcompleter tofu terragrunt
  run tab bash 'tf pl'; assert_eq "$output" "tf plan"
  run tab bash 'tg pl'; assert_eq "$output" "tg plan"
}
