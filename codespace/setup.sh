#!/bin/bash
# ==========================================
# VPN Codespace Setup — Xray + Reality + Subscription
# ==========================================
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

log() { echo "[$(date '+%H:%M:%S')] $*"; }

# --- 1. Find the Codespace domain ---
CODESPACE_NAME="$(hostname)"
log "Codespace: $CODESPACE_NAME"

# Extract the public domain from gh codespace ports
CS_DOMAIN=""
if command -v gh &>/dev/null; then
  CS_DOMAIN=$(gh codespace ports --json browseUrl,sourcePort -q '.[] | select(.sourcePort==8080) | .browseUrl' 2>/dev/null | head -1 | sed 's|https://||;s|-8080.*||')
  [ -z "$CS_DOMAIN" ] && CS_DOMAIN="${CODESPACE_NAME}-80.app.github.dev"
fi
log "Domain prefix: $CS_DOMAIN"

# --- 2. Install Xray if not present ---
if ! command -v xray &>/dev/null; then
  log "Installing Xray..."
  bash -c "$(curl -sL https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install
  log "Xray installed: $(xray version 2>&1 | head -1)"
else
  log "Xray already installed: $(xray version 2>&1 | head -1)"
fi

# --- 3. Copy Xray config ---
log "Installing Xray config..."
mkdir -p /usr/local/etc/xray
cp "$SCRIPT_DIR/config.json" /usr/local/etc/xray/config.json
log "Config installed"

# --- 4. Generate subscription files ---
log "Generating subscription files..."
PUBLIC_KEY="+E+mm/AWqoDaMbnACtuLVQr/2aV46ECA5rNilqjW43k="
UUID="bac4dab0-fd34-414d-bdb2-eadab83b2205"

# --- Reality VLESS share link ---
# vless://uuid@domain:443?encryption=none&security=reality&flow=xtls-rprx-vision&type=tcp&fp=chrome&pbk=PK&sni=www.microsoft.com&sid=ecbcf1be#MyPC-Reality
RL_LINK="vless://${UUID}@${CS_DOMAIN}-10443.app.github.dev:443?encryption=none&security=reality&flow=xtls-rprx-vision&type=tcp&fp=chrome&pbk=${PUBLIC_KEY}&sni=www.microsoft.com&sid=ecbcf1be#MyPC-Reality"

# --- WS TLS VLESS share link ---
WS_LINK="vless://${UUID}@${CS_DOMAIN}-10444.app.github.dev:443?encryption=none&security=tls&type=ws&path=%2Fws&host=${CS_DOMAIN}-10444.app.github.dev#MyPC-WS"

# --- SS share link ---
SS_B64=$(echo -n "2022-blake3-aes-128-gcm:hJmFp8vL2sXkR5wQ" | base64 -w0)
SS_LINK="ss://${SS_B64}@${CS_DOMAIN}-10445.app.github.dev:443#MyPC-SS"

# --- Base64 subscription (multi-line for v2rayNG) ---
SUB_CONTENT="${RL_LINK}\n${WS_LINK}\n${SS_LINK}"
SUB_B64=$(echo -e "$SUB_CONTENT" | base64 -w0)

# --- Write files ---
mkdir -p "$REPO_DIR/configs" "$REPO_DIR/docs"
echo "$RL_LINK" > "$REPO_DIR/configs/reality.txt"
echo "$WS_LINK" > "$REPO_DIR/configs/websocket.txt"
echo "$SS_LINK" > "$REPO_DIR/configs/shadowsocks.txt"
echo -e "$SUB_CONTENT" > "$REPO_DIR/mobile.txt"
echo "$SUB_B64" > "$REPO_DIR/configs/subscription-base64.txt"
echo "https://${CS_DOMAIN}-8080.app.github.dev/sub" > "$REPO_DIR/configs/subscription-url.txt"

log "Subscription files generated:"
log "  Reality:    $REPO_DIR/configs/reality.txt"
log "  WS TLS:    $REPO_DIR/configs/websocket.txt"
log "  SS:        $REPO_DIR/configs/shadowsocks.txt"
log "  Mobile:    $REPO_DIR/mobile.txt"
log "  Sub URL:   $REPO_DIR/configs/subscription-url.txt"

# --- 5. Start Xray ---
log "Starting Xray..."
systemctl stop xray 2>/dev/null || true
pkill -f xray 2>/dev/null || true
sleep 1

# Start with nohup so it survives SSH disconnect
nohup xray run -c /usr/local/etc/xray/config.json > /tmp/xray.log 2>&1 &
XRAY_PID=$!
log "Xray started, PID: $XRAY_PID"
sleep 2

# --- 6. Start subscription HTTP server ---
log "Starting subscription server on port 8080..."
pkill -f "http.server 8080" 2>/dev/null || true
nohup python3 -m http.server 8080 --bind 0.0.0.0 --directory "$REPO_DIR" > /tmp/sub-server.log 2>&1 &
SUB_PID=$!
log "Subscription server started, PID: $SUB_PID"

# --- 7. Make ports public ---
log "Setting port visibility..."
for port in 8080 10443 10444 10445; do
  gh codespace ports visibility "$port:public" 2>/dev/null || true
done

# --- 8. Verify ---
sleep 2
log "=== Verification ==="
log "Xray process: $(ps aux | grep xray | grep -v grep | head -2)"
log "Ports listening:"
ss -tlnp | grep -E "10443|10444|10445|8080" || echo "  (none listening yet)"

log "=== Setup Complete ==="
echo ""
echo "====== VPN CONFIGS ======"
echo ""
echo "REALITY (рекомендуется):"
echo "$RL_LINK"
echo ""
echo "WebSocket TLS:"
echo "$WS_LINK"
echo ""
echo "Shadowsocks:"
echo "$SS_LINK"
echo ""
echo "Subscription URL:"
echo "https://${CS_DOMAIN}-8080.app.github.dev/mobile.txt"
echo ""
echo "========================"
