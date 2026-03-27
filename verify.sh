#!/bin/bash --login

set -euo pipefail

echo "Verifying language runtimes ..."

read -ra PYTHON <<< "${PYTHON_VERSIONS:-${PYTHON_VERSION:-}}"
read -ra NODE   <<< "${NODE_VERSIONS:-${NODE_VERSION:-}}"

max=$(printf "%s\n" \
  ${#PYTHON[@]} \
  ${#NODE[@]} \
  | sort -nr | head -1)

for ((i=max-1; i>=0; i--)); do
  CODEX_ENV_PYTHON_VERSION=${PYTHON[i]:-${PYTHON[0]}} \
  CODEX_ENV_NODE_VERSION=${NODE[i]:-${NODE[0]}} \
  bash -lc '
    printf "\n\nTesting setup_universal with versions:\n"
    env | grep "^CODEX_ENV_" | sort
    printf "\n"
    /opt/codex/setup_universal.sh
  '
done

echo "- Python:"
python3 --version
pyenv versions | sed 's/^/  /'

echo "- Node.js:"
node --version
npm --version
pnpm --version
yarn --version
npm ls -g

echo "All language runtimes detected successfully."
