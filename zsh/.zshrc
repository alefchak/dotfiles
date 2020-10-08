# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

source .zsh/powerlevel10k/powerlevel10k.zsh-theme

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

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
