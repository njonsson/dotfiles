export PATH="~/bin:/usr/local/mysql/bin:/usr/local/bin:$PATH"
export EDITOR="mvim --nofork"
export GEM_OPEN_EDITOR=mvim

source /usr/local/src/git/contrib/completion/git-completion.bash
source $(dirname $(readlink $BASH_SOURCE))/lib/git-prompt.bash

[[ -s $HOME/.rvm/scripts/rvm ]] && source $HOME/.rvm/scripts/rvm
