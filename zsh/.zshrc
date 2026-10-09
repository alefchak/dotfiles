autoload -Uz compinit
compinit

setopt noautomenu
setopt nomenucomplete

for file in "$HOME"/.aliases/*(N-.) "$HOME"/.zsh/*(N-.); do
  source "$file"
done
unset file
