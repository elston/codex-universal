#!/bin/bash --login

set -euo pipefail

# 1. Load NVM environment (Crucial for Docker)
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# 2. Load Pyenv environment (Crucial for Docker)
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

CODEX_ENV_PYTHON_VERSION=${CODEX_ENV_PYTHON_VERSION:-}
CODEX_ENV_NODE_VERSION=${CODEX_ENV_NODE_VERSION:-}

echo "Configuring language runtimes..."

if [ -n "${CODEX_ENV_PYTHON_VERSION}" ]; then
    echo "# Setting Python: ${CODEX_ENV_PYTHON_VERSION}"
    pyenv global "${CODEX_ENV_PYTHON_VERSION}"
    python --version
fi

if [ -n "${CODEX_ENV_NODE_VERSION}" ]; then
    # Use 'v' prefix logic for node version comparison
    current_node=$(node -v | sed 's/v//' | cut -d. -f1) 
    echo "# Node.js target: ${CODEX_ENV_NODE_VERSION} (current: ${current_node})"
    
    if [ "${current_node}" != "${CODEX_ENV_NODE_VERSION}" ]; then
        nvm alias default "${CODEX_ENV_NODE_VERSION}"
        nvm use "${CODEX_ENV_NODE_VERSION}"
        corepack enable
    fi
fi
