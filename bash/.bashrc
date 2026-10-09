# Enable bash-completion
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

for file in "$HOME"/.aliases/* "$HOME"/.bash/*; do
  [[ -f "$file" ]] && source "$file"
done
unset file

shopt -s checkwinsize

# Complete every simple alias as the command it expands to, as zsh does by default
function _complete_alias {
  local name=${COMP_WORDS[0]}
  local expansion=${BASH_ALIASES[$name]}
  local -a head=($expansion)
  local cmd=${head[0]} spec func
  if ! spec=$(complete -p "$cmd" 2>/dev/null); then
    # bash-completion loads most completions on first use
    if declare -F _comp_load >/dev/null; then _comp_load "$cmd"
    elif declare -F _completion_loader >/dev/null; then _completion_loader "$cmd"
    fi
    spec=$(complete -p "$cmd" 2>/dev/null)
  fi
  [[ $spec == *" -F "* ]] || return
  func=${spec#* -F }; func=${func%% *}
  [[ $spec == *"-o nospace"* ]] && compopt -o nospace
  COMP_LINE=$expansion${COMP_LINE#"$name"}
  COMP_POINT=$(( COMP_POINT + ${#expansion} - ${#name} ))
  COMP_CWORD=$(( COMP_CWORD + ${#head[@]} - 1 ))
  COMP_WORDS=("${head[@]}" "${COMP_WORDS[@]:1}")
  "$func" "$cmd" "${COMP_WORDS[COMP_CWORD]}" "${COMP_WORDS[COMP_CWORD-1]}"
}
if [[ ${BASH_VERSINFO[0]} -ge 4 ]]; then
  for name in "${!BASH_ALIASES[@]}"; do
    expansion=${BASH_ALIASES[$name]}
    [[ $expansion == *[';&|<>$`']* ]] && continue      # only plain commands
    [[ ${expansion%% *} == "$name" ]] && continue      # ls='ls ...' keeps its own completion
    complete -p "$name" >/dev/null 2>&1 && continue    # already has one
    complete -o default -o bashdefault -F _complete_alias "$name"
  done
  unset name expansion
fi
