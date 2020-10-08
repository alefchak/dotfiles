#!/bin/sh

mkdir -p docker/.zsh/completion
curl -L https://raw.githubusercontent.com/docker/cli/master/contrib/completion/zsh/_docker > docker/.zsh/completion/_docker
curl -L https://raw.githubusercontent.com/docker/compose/master/contrib/completion/zsh/_docker-compose > docker/.zsh/completion/_docker-compose

mkdir -p zsh/.zsh/powerlevel10k
curl -L https://github.com/romkatv/powerlevel10k/archive/master.tar.gz | tar zx --strip-components=1 -C zsh/.zsh/powerlevel10k