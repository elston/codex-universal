#!/bin/bash --login

set -euo pipefail

/opt/codex/setup_universal.sh

# 3. Final Step: Hand over to the Codex CLI or the user's CMD
# This allows 'docker run ... my-image codex auth' to work
exec "$@"
