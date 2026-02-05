#!/usr/bin/env bash
# Install system-level files for the gpu-switch-daemon workaround.
# Run with: sudo ./install.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

install -m 755 "$SCRIPT_DIR/gpu-switch-daemon" /usr/local/bin/gpu-switch-daemon
install -m 644 "$SCRIPT_DIR/dev.noctalia.gpu-toggle.policy" /usr/share/polkit-1/actions/

echo "Installed gpu-switch-daemon and polkit policy."
