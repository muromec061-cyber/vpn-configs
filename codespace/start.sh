#!/bin/bash
# Codespace start.sh — runs on every Codespace resume
# Installs Xray if missing, starts Xray + subscription server

log() { echo "[$(date '+%H:%M:%S')] $*"; }

# Install Xray if missing
if ! command -v xray &>/dev/null; then
  log "Installing Xray..."
  bash -c "$(curl -sL https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install
fi

# Copy config if not already there
if [ ! -f /usr/local/etc/xray/config.json ]; then
  mkdir -p /usr/local/etc/xray
  cp /workspaces/vpn-configs/codespace/config.json /usr/local/etc/xray/config.json
fi

# Kill stale processes
pkill -f "xray run" 2>/dev/null || true
pkill -f "http.server 8080" 2>/dev/null || true
sleep 1

# Start Xray
nohup xray run -c /usr/local/etc/xray/config.json > /tmp/xray.log 2>&1 &
log "Xray started, PID: $!"

# Start subscription HTTP server
cd /workspaces/vpn-configs
nohup python3 -m http.server 8080 --bind 0.0.0.0 > /tmp/sub-server.log 2>&1 &
log "Sub server started, PID: $!"

# Make ports public
for port in 8080 10443 10444 10445; do
  gh codespace ports visibility "$port:public" 2>/dev/null || true
done

log "All services started"
