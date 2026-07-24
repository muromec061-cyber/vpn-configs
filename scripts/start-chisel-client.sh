#!/bin/bash
# Persistent Chisel client connecting to Codespace
# Installed as /etc/systemd/system/chisel-client.service
URL='https://vigilant-zebra-7vq4g4qg46gv3wp9q-8080.app.github.dev'
while true; do
    echo "Connecting to $URL..."
    chisel client --keepalive 25s "$URL" R:8081:localhost:80 R:9443:localhost:8448
    echo "Disconnected. Reconnecting in 5s..."
    sleep 5
done
