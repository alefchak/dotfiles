# Enable bash-completion
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

[[ -e "$HOME/.aliases" ]] && for file in $HOME/.aliases/*; do
  source $file
done
unset file

[[ -e "$HOME/.bash" ]] && for file in $HOME/.bash/*; do
  source $file
done
unset file
