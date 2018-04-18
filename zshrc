# Path to your oh-my-zsh configuration.
ZSH=$HOME/.oh-my-zsh

# Set name of the theme to load.
# Look in ~/.oh-my-zsh/themes/
# Optionally, if you set this to "random", it'll load a random theme each
# time that oh-my-zsh is loaded.
ZSH_THEME=jreese

# Set to this to use case-sensitive completion
# CASE_SENSITIVE="true"

# Comment this out to disable weekly auto-update checks
# DISABLE_AUTO_UPDATE="true"

# Uncomment following line if you want to disable colors in ls
# DISABLE_LS_COLORS="true"

# Uncomment following line if you want to disable autosetting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment following line if you want red dots to be displayed while waiting for completion
# COMPLETION_WAITING_DOTS="true"

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Example format: plugins=(rails git textmate ruby lighthouse)
plugins=(git)

source $ZSH/oh-my-zsh.sh

# Customize to your needs...

alias git='noglob git'
alias rake='noglob rake'
alias rspec='nocorrect rspec'
alias tmux='nocorrect tmux'
alias tree='nocorrect tree'
alias watch='watch --color --diff'

export PATH="$HOME/bin:/usr/local/bin:/usr/local/sbin:$PATH"
export EDITOR="/usr/bin/env vim"
export GEM_OPEN_EDITOR="$EDITOR"
export GOPATH="$HOME/golang"
export PATH="$GOPATH/bin:$PATH"

PATH=$PATH:/Library/Frameworks/AndroidDeveloperTools/sdk/platform-tools # Add Android SDK platform tools to PATH

# Set up asdf for tool version management.
. $HOME/.asdf/asdf.sh
. $HOME/.asdf/completions/asdf.bash

test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

# Enable IEx history.
export ERL_AFLAGS="-kernel shell_history enabled"

echo
todo --list
echo

# Add RVM to PATH for scripting. Make sure this is the last PATH variable change.
export PATH="$PATH:$HOME/.rvm/bin"
