autoload -Uz compinit
compinit

setopt noautomenu
setopt nomenucomplete

# History: large, written as you go, de-duplicated, timestamped
HISTFILE=~/.zsh_history
HISTSIZE=100000
SAVEHIST=100000
setopt inc_append_history extended_history
setopt hist_ignore_all_dups hist_save_no_dups hist_ignore_space hist_verify

# Up/Down search history for commands starting with what is already typed
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey '^[[A' up-line-or-beginning-search
bindkey '^[OA' up-line-or-beginning-search
bindkey '^[[B' down-line-or-beginning-search
bindkey '^[OB' down-line-or-beginning-search

for file in "$HOME"/.aliases/*(N-.) "$HOME"/.zsh/*(N-.); do
  source "$file"
done
unset file
