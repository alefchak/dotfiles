fpath=(~/.zsh/completion $fpath)
autoload -Uz compinit
compinit

setopt noautomenu
setopt nomenucomplete

[[ -e "$HOME/.aliases" ]] && for file in $HOME/.aliases/*; do
  source $file
done
unset file

[[ -e "$HOME/.zsh" ]] && for file in $HOME/.zsh/*; do
  source $file
done
unset file
