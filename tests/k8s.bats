load helpers

setup() {
  setup_home
  stub kubectl
  printf 'default\napps\nmedia\n' > "$STATE/namespaces"
}

check_kns() {
  sh_run "$1" '
    echo "start: $(kns)"
    kns apps; echo "set: $(kns)"
    kns nope; echo "rc=$? kept: $(kns)"
    kns default; echo "back: $(kns)"'
  assert_eq "$output" "start: default
set: apps
rc=1 kept: apps
back: default"
  assert_eq "$stderr" "kns: no such namespace: nope"
}
@test "bash: kns shows, sets and rejects a missing namespace" { check_kns bash; }
@test "zsh: kns shows, sets and rejects a missing namespace" { check_kns zsh; }

check_kns_unverifiable() {
  echo locked > "$STATE/forbidden"
  sh_run "$1" 'kns locked; echo "rc=$? now: $(kns)"; touch "$STATE/offline"; kns elsewhere; echo "rc=$? now: $(kns)"'
  assert_eq "$output" "rc=0 now: locked
rc=0 now: elsewhere"
}
@test "bash: kns sets a namespace it cannot look up" { check_kns_unverifiable bash; }
@test "zsh: kns sets a namespace it cannot look up" { check_kns_unverifiable zsh; }

check_kgetall_usage() {
  sh_run "$1" 'kgetall'
  [ "$status" -eq 1 ]
  assert_eq "$stderr" "usage: kgetall <namespace>"
}
@test "bash: kgetall needs a namespace" { check_kgetall_usage bash; }
@test "zsh: kgetall needs a namespace" { check_kgetall_usage zsh; }

check_kgetall() {
  printf 'pods\nevents\nservices\nevents.events.k8s.io\ndeployments.apps\npods\n' > "$STATE/api-resources"
  printf 'NAME      READY\npod/web   1/1\n' > "$STATE/get-output"
  sh_run "$1" 'kgetall apps'
  [ "$status" -eq 0 ]
  assert_eq "$output" "NAME      READY
pod/web   1/1"
  # one get for every type but events, each once
  assert_eq "$(grep '^kubectl get' "$STATE/calls.log")" "kubectl get deployments.apps,pods,services -n apps --ignore-not-found"
}
@test "bash: kgetall gets every type in one call" { check_kgetall bash; }
@test "zsh: kgetall gets every type in one call" { check_kgetall zsh; }

@test "bash: kns and kgetall complete namespaces, first argument only" {
  sh_run bash '
    for cmd in kns kgetall; do
      complete -p $cmd
      COMP_WORDS=($cmd m); COMP_CWORD=1; _kube_ns_arg; echo "[${COMPREPLY[*]}]"
      COMPREPLY=(); COMP_WORDS=($cmd apps ""); COMP_CWORD=2; _kube_ns_arg; echo "[${COMPREPLY[*]}]"
    done'
  assert_eq "$output" "complete -F _kube_ns_arg kns
[media]
[]
complete -F _kube_ns_arg kgetall
[media]
[]"
}

@test "zsh: Tab completes namespaces for kns and kgetall" {
  run tab zsh 'kns m'
  assert_eq "$output" "kns media "
  run tab zsh 'kgetall a'
  assert_eq "$output" "kgetall apps "
}

@test "zsh: kns completes namespaces for the first argument only" {
  sh_run zsh "$ZSH_COMPADD"'CURRENT=2; _kube_ns_arg; echo --; CURRENT=3; _kube_ns_arg; echo --'
  assert_eq "$output" "default
apps
media
--
--"
}

check_debug_aliases() {
  sh_run "$1" 'kdebug web --target=app -n apps; kdebug node/worker1; knetshoot -n apps'
  [ "$status" -eq 0 ]
  assert_eq "$(grep -E '^kubectl (debug|run)' "$STATE/calls.log")" "kubectl debug -it --image=nicolaka/netshoot --profile=netadmin web --target=app -n apps
kubectl debug -it --image=nicolaka/netshoot --profile=netadmin node/worker1
kubectl run netshoot --rm -it --restart=Never --image=nicolaka/netshoot -n apps"
}
@test "bash: kdebug and knetshoot run netshoot" { check_debug_aliases bash; }
@test "zsh: kdebug and knetshoot run netshoot" { check_debug_aliases zsh; }

@test "bash: kdebug and knetshoot complete as kubectl" {
  skip_unless_bash4
  sh_run bash 'complete -p kdebug knetshoot'
  assert_eq "$(normalize_specs "$output")" "complete -o bashdefault -o default -F _complete_alias kdebug
complete -o bashdefault -o default -F _complete_alias knetshoot"
}

@test "zsh: Tab on kdebug completes as kubectl" {
  run tab zsh 'kdebug ge'
  assert_eq "$output" "kdebug get "
}
