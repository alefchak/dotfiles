load helpers

# A cluster where flux-system applies cluster, which applies media (in apps) and infra; media and
# infra each apply a helmrelease. The root lists itself, as flux-system does.
setup() {
  setup_home
  stub kubectl flux
  printf 'default\nflux-system\napps\nkube-system\n' > "$STATE/namespaces"
  mkdir -p "$STATE/flux"
  cat > "$STATE/flux/inventory" <<'EOF'
kustomization/flux-system/flux-system flux-system_flux-system_kustomize.toolkit.fluxcd.io_Kustomization flux-system_cluster_kustomize.toolkit.fluxcd.io_Kustomization apps_x_image.toolkit.fluxcd.io_ImagePolicy
kustomization/flux-system/cluster apps_media_kustomize.toolkit.fluxcd.io_Kustomization flux-system_infra_kustomize.toolkit.fluxcd.io_Kustomization
kustomization/apps/media apps_jellyfin_helm.toolkit.fluxcd.io_HelmRelease
kustomization/flux-system/infra kube-system_cilium_helm.toolkit.fluxcd.io_HelmRelease
EOF
}

exists() {
  local o
  for o; do mkdir -p "$STATE/flux/exists/${o%/*}" && touch "$STATE/flux/exists/$o"; done
}
whole_tree() {
  exists kustomization/flux-system/flux-system kustomization/flux-system/cluster kustomization/flux-system/infra \
    kustomization/apps/media helmrelease/apps/jellyfin helmrelease/kube-system/cilium
}
reconciles() { grep '^flux reconcile' "$STATE/calls.log"; }

ALL_RECONCILES="flux reconcile kustomization flux-system -n flux-system --with-source
flux reconcile kustomization cluster -n flux-system
flux reconcile kustomization media -n apps
flux reconcile helmrelease jellyfin -n apps --with-source
flux reconcile kustomization infra -n flux-system
flux reconcile helmrelease cilium -n kube-system --with-source"

# frtree

check_frtree_tree() {
  whole_tree
  sh_run "$1" 'frtree'
  [ "$status" -eq 0 ]
  assert_eq "$output" "frtree: reconciled flux-system and 5 resources under it"
  assert_eq "$(reconciles)" "$ALL_RECONCILES"
}
@test "bash: frtree reconciles the tree parents first" { check_frtree_tree bash; }
@test "zsh: frtree reconciles the tree parents first" { check_frtree_tree zsh; }

# Deleting the apps namespace removed media and jellyfin; their parents recreate them
check_frtree_deleted() {
  exists kustomization/flux-system/flux-system kustomization/flux-system/cluster
  sh_run "$1" 'frtree'
  [ "$status" -eq 0 ]
  assert_eq "$output" "frtree: reconciled flux-system and 5 resources under it"
  assert_eq "$(reconciles)" "$ALL_RECONCILES"
}
@test "bash: frtree recreates what a deleted namespace removed" { check_frtree_deleted bash; }
@test "zsh: frtree recreates what a deleted namespace removed" { check_frtree_deleted zsh; }

check_frtree_failing_child() {
  whole_tree
  echo kustomization/apps/media > "$STATE/flux/fail"
  sh_run "$1" 'frtree'
  [ "$status" -eq 1 ]
  assert_eq "$(reconciles)" "flux reconcile kustomization flux-system -n flux-system --with-source
flux reconcile kustomization cluster -n flux-system
flux reconcile kustomization media -n apps
flux reconcile kustomization infra -n flux-system
flux reconcile helmrelease cilium -n kube-system --with-source"
  [[ $stderr == *"frtree: some of the 4 resources under flux-system failed:
  kustomization apps/media (not descended into)"* ]]
}
@test "bash: frtree reports a failing kustomization and skips its subtree" { check_frtree_failing_child bash; }
@test "zsh: frtree reports a failing kustomization and skips its subtree" { check_frtree_failing_child zsh; }

check_frtree_root() {
  whole_tree
  sh_run "$1" 'frtree media -n apps && frtree media --namespace=apps'
  [ "$status" -eq 0 ]
  assert_eq "$(reconciles)" "flux reconcile kustomization media -n apps --with-source
flux reconcile helmrelease jellyfin -n apps --with-source
flux reconcile kustomization media -n apps --with-source
flux reconcile helmrelease jellyfin -n apps --with-source"
}
@test "bash: frtree starts at the given kustomization and namespace" { check_frtree_root bash; }
@test "zsh: frtree starts at the given kustomization and namespace" { check_frtree_root zsh; }

check_frtree_errors() {
  sh_run "$1" 'frtree --bogus; echo "rc=$?"; frtree nope; echo "rc=$?"'
  assert_eq "$output" "rc=1
rc=1"
  [[ $stderr == "usage: frtree [kustomization] [-n namespace]"* ]]
}
@test "bash: frtree rejects bad options and a missing root" { check_frtree_errors bash; }
@test "zsh: frtree rejects bad options and a missing root" { check_frtree_errors zsh; }

# fra: flux-system owns itself and apps; apps owns podinfo (helmrelease) and extras, which uses
# a different source

fra_objects() {
  # fra reads ownership from labels, not inventories; without one, reconciles create nothing and
  # every object is taken to exist
  rm "$STATE/flux/inventory"
  cat > "$STATE/flux-objects.json" <<'EOF'
{"items": [
  {"kind": "Kustomization", "metadata": {"name": "flux-system", "namespace": "flux-system",
    "labels": {"kustomize.toolkit.fluxcd.io/name": "flux-system", "kustomize.toolkit.fluxcd.io/namespace": "flux-system"}},
   "spec": {"sourceRef": {"kind": "GitRepository", "name": "flux-system"}}},
  {"kind": "Kustomization", "metadata": {"name": "apps", "namespace": "flux-system",
    "labels": {"kustomize.toolkit.fluxcd.io/name": "flux-system", "kustomize.toolkit.fluxcd.io/namespace": "flux-system"}},
   "spec": {"sourceRef": {"kind": "GitRepository", "name": "flux-system"}}},
  {"kind": "Kustomization", "metadata": {"name": "extras", "namespace": "flux-system",
    "labels": {"kustomize.toolkit.fluxcd.io/name": "apps", "kustomize.toolkit.fluxcd.io/namespace": "flux-system"}},
   "spec": {"sourceRef": {"kind": "GitRepository", "name": "extras"}}},
  {"kind": "HelmRelease", "metadata": {"name": "podinfo", "namespace": "web",
    "labels": {"kustomize.toolkit.fluxcd.io/name": "apps", "kustomize.toolkit.fluxcd.io/namespace": "flux-system"}}}
]}
EOF
}

check_fra_helmrelease() {
  fra_objects
  sh_run "$1" 'fra hr podinfo -n web'
  [ "$status" -eq 0 ]
  assert_eq "$output" "fra: reconciled 3 resources, ending with helmrelease web/podinfo"
  assert_eq "$(reconciles)" "flux reconcile kustomization flux-system -n flux-system --with-source
flux reconcile kustomization apps -n flux-system
flux reconcile helmrelease podinfo -n web --with-source --force"
}
@test "bash: fra reconciles the chain and forces the helmrelease" { check_fra_helmrelease bash; }
@test "zsh: fra reconciles the chain and forces the helmrelease" { check_fra_helmrelease zsh; }

check_fra_kustomization() {
  fra_objects
  sh_run "$1" 'fra kustomization extras'
  [ "$status" -eq 0 ]
  assert_eq "$(reconciles)" "flux reconcile kustomization flux-system -n flux-system --with-source
flux reconcile kustomization apps -n flux-system
flux reconcile kustomization extras -n flux-system --with-source"
}
@test "bash: fra fetches each source once and does not force kustomizations" { check_fra_kustomization bash; }
@test "zsh: fra fetches each source once and does not force kustomizations" { check_fra_kustomization zsh; }

check_fra_stops() {
  fra_objects
  echo kustomization/flux-system/apps > "$STATE/flux/fail"
  sh_run "$1" 'fra hr podinfo -n web'
  [ "$status" -eq 1 ]
  [[ $stderr == *'kustomization "apps" reconcile failed'*"fra: stopped at kustomization flux-system/apps"* ]]
  ! reconciles | grep -q podinfo
}
@test "bash: fra stops at the first failure" { check_fra_stops bash; }
@test "zsh: fra stops at the first failure" { check_fra_stops zsh; }

check_fra_errors() {
  fra_objects
  sh_run "$1" 'fra; echo "rc=$?"; fra pod x; echo "rc=$?"; fra ks nope; echo "rc=$?"'
  assert_eq "$output" "rc=1
rc=1
rc=1"
  [[ $stderr == *"fra: Kustomization/flux-system/nope not found"* ]]
  ! reconciles
}
@test "bash: fra rejects bad arguments and a missing resource" { check_fra_errors bash; }
@test "zsh: fra rejects bad arguments and a missing resource" { check_fra_errors zsh; }

# Completion

# complete_bash '<function>' '<word>...': call a bash completion function with the cursor on the
# last word and print the candidates
complete_bash() {
  local fn=$1; shift
  local words="" w
  for w; do words+=" $(printf '%q' "$w")"; done
  sh_run bash "COMP_WORDS=($words); COMP_CWORD=\$((\${#COMP_WORDS[@]} - 1)); $fn; echo \"[\${COMPREPLY[*]}]\""
}

@test "bash: frtree completes kustomizations, namespaces and options" {
  whole_tree
  complete_bash _frtree frtree "";               assert_eq "$output" "[cluster flux-system infra]"
  complete_bash _frtree frtree -n a;             assert_eq "$output" "[apps]"
  complete_bash _frtree frtree -n apps "";       assert_eq "$output" "[media]"
  complete_bash _frtree frtree --namespace = apps ""; assert_eq "$output" "[media]"
  complete_bash _frtree frtree -;                assert_eq "$output" "[-n --namespace]"
  complete_bash _frtree frtree cluster "";       assert_eq "$output" "[]"
}

@test "bash: fra completes the kind, then names of that kind" {
  whole_tree
  complete_bash _fra fra "";                     assert_eq "$output" "[helmrelease kustomization]"
  complete_bash _fra fra kustomization "";       assert_eq "$output" "[cluster flux-system infra]"
  complete_bash _fra fra helmrelease -n apps ""; assert_eq "$output" "[jellyfin]"
  complete_bash _fra fra hr -n kube-system c;    assert_eq "$output" "[cilium]"
  complete_bash _fra fra kustomization media ""; assert_eq "$output" "[]"
}

@test "zsh: Tab completes frtree's kustomizations and namespaces" {
  whole_tree
  run tab zsh 'frtree c';           assert_eq "$output" "frtree cluster "
  run tab zsh 'frtree -n ap';       assert_eq "$output" "frtree -n apps "
  run tab zsh 'frtree -n apps m';   assert_eq "$output" "frtree -n apps media "
}

@test "zsh: Tab completes fra's kind, then names of that kind" {
  whole_tree
  run tab zsh 'fra h';                      assert_eq "$output" "fra helmrelease "
  run tab zsh 'fra helmrelease -n apps j';  assert_eq "$output" "fra helmrelease -n apps jellyfin "
  run tab zsh 'fra kustomization i';        assert_eq "$output" "fra kustomization infra "
}

# fga

check_fga() {
  sh_run "$1" 'fga; fga apps; fga --status-selector ready=false; fga apps --status-selector ready=false'
  [ "$status" -eq 0 ]
  assert_eq "$(grep '^flux get' "$STATE/calls.log")" "flux get all -A
flux get all -n apps
flux get all -A --status-selector ready=false
flux get all -n apps --status-selector ready=false"
}
@test "bash: fga gets everything, in one namespace or all" { check_fga bash; }
@test "zsh: fga gets everything, in one namespace or all" { check_fga zsh; }

@test "bash: fga completes namespaces" {
  sh_run bash 'complete -p fga; COMP_WORDS=(fga a); COMP_CWORD=1; _kube_ns_arg; echo "[${COMPREPLY[*]}]"'
  assert_eq "$output" "complete -F _kube_ns_arg fga
[apps]"
}

@test "zsh: Tab completes namespaces for fga" {
  run tab zsh 'fga kube'
  assert_eq "$output" "fga kube-system "
}
