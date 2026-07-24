#!/bin/bash
# WSL Setup: Chisel client to connect to Codespace
# Run this after Codespace is created
# Usage: bash setup-wsl.sh CODESPACE_URL

set -e

CODESPACE_URL="${1:-}"
if [ -z "$CODESPACE_URL" ]; then
    echo "Usage: $0 CODESPACE_URL"
    echo "Example: $0 https://cuddly-space-engine-xxxxx-8080.preview.app.github.dev"
    exit 1
fi

echo "=== Installing Chisel ==="
if ! command -v chisel &>/dev/null; then
    curl -sL -o /tmp/chisel.gz "https://github.com/jpillora/chisel/releases/download/v1.11.8/chisel_1.11.8_linux_amd64.gz"
    gunzip -f /tmp/chisel.gz
    chmod +x /tmp/chisel
    cp /tmp/chisel /usr/local/bin/chisel
fi
echo "Chisel version: $(chisel --version)"

echo "=== Testing connection to Codespace ==="
# First verify the URL is reachable
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "$CODESPACE_URL" 2>/dev/null || echo "timeout")
echo "Codespace HTTP status: $HTTP_CODE"

echo "=== Starting Chisel client ==="
# Connect to Codespace with reverse tunnels:
# R:80 -> localhost:80 (Caddy/subscription)
# R:8448 -> localhost:8448 (Xray WS)

chisel client \
  --keepalive 25s \
  "$CODESPACE_URL" \
  R:80:localhost:80 \
  R:8448:localhost:8448

echo "Chisel client disconnected"
