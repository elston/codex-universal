# Standard Bash defaults
[ -z "$PS1" ] && return
HISTCONTROL=ignoreboth
shopt -s checkwinsize

# Visual prompt for Codex Environment
export PS1="\[\e[32m\]codex-container\[\e[m\]:\[\e[34m\]\w\[\e[m\]\$ "

# Load NVM (Node Version Manager)
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# Load Pyenv
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
eval "$(pyenv init --path)"

# Aliases for convenience
alias ll='ls -alF'
alias python='python3'
alias cx='codex'
alias cxa='codex auth'

# Ensure Codex doesn't try to use macOS sandboxing
export CODEX_UNSAFE_ALLOW_NO_SANDBOX=1
