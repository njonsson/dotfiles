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

HISTFILE="$HOME/.zsh_history"
HISTSIZE=10000000
SAVEHIST=10000000
setopt BANG_HIST                 # Treat the '!' character specially during expansion.
setopt EXTENDED_HISTORY          # Write the history file in the ":start:elapsed;command" format.
setopt INC_APPEND_HISTORY        # Write to the history file immediately, not when the shell exits.
setopt SHARE_HISTORY             # Share history between all sessions.
setopt HIST_EXPIRE_DUPS_FIRST    # Expire duplicate entries first when trimming history.
setopt HIST_IGNORE_DUPS          # Don't record an entry that was just recorded again.
setopt HIST_IGNORE_ALL_DUPS      # Delete old recorded entry if new entry is a duplicate.
setopt HIST_FIND_NO_DUPS         # Do not display a line previously found.
setopt HIST_IGNORE_SPACE         # Don't record an entry starting with a space.
setopt HIST_SAVE_NO_DUPS         # Don't write duplicate entries in the history file.
setopt HIST_REDUCE_BLANKS        # Remove superfluous blanks before recording entry.
setopt HIST_VERIFY               # Don't execute immediately upon history expansion.
setopt HIST_BEEP                 # Beep when accessing nonexistent history.

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

test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

# Enable IEx history.
export ERL_AFLAGS="-kernel shell_history enabled"

# Accommodate Homebrew-installed asdf.
. $(brew --prefix asdf)/asdf.sh

# Add RVM to PATH for scripting. Make sure this is the last PATH variable change.
export PATH="$PATH:$HOME/.rvm/bin"

# Enable asdf.
. /usr/local/opt/asdf/libexec/asdf.sh

todo_list_incomplete_if_filename_changed() {
  if [ "$(todo --filename)" != "${_TODO_FILENAME_PREVIOUS-}" ]; then
    export _TODO_FILENAME_PREVIOUS=$(
      todo --filename
    )
    todo --list-incomplete
  fi
}
export PROMPT_COMMAND=todo_list_incomplete_if_filename_changed
precmd() { eval "$PROMPT_COMMAND" } # Workaround for zsh.
