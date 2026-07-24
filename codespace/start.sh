#!/bin/bash
# Start Chisel server in Codespace (background mode)
# Called by devcontainer postStartCommand

CHISEL_PORT=8080
LOG_FILE=/tmp/chisel-server.log

echo "=== Starting Chisel server on port $CHISEL_PORT ==="

nohup chisel server \
  --port "$CHISEL_PORT" \
  --reverse \
  --keepalive 25s \
  > "$LOG_FILE" 2>&1 &

echo "Chisel PID: $!"
echo "Log: $LOG_FILE"
sleep 1
echo "=== Chisel server status ==="
ps aux | grep chisel | grep -v grep
echo "=== Port 8080 listening? ==="
ss -tlnp | grep 8080
echo "=== Done ==="
