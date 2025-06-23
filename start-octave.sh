#!/bin/bash
set -e

echo "=== Starting Octave Web Interface ==="

# Environment setzen
export DISPLAY=:1

echo "Starting Xvfb (virtual display)..."
Xvfb :1 -screen 0 1024x768x24 &
sleep 3

echo "Starting x11vnc (VNC server)..."
x11vnc -display :1 -nopw -listen 0.0.0.0 -xkb -forever &
sleep 3

echo "Starting websockify (web bridge)..."
websockify --web=/usr/share/novnc/ 8080 localhost:5900 &
sleep 5

echo "Starting Octave GUI..."
cd /workspace
octave --gui &

echo "=== All services started! Access via browser on port 8080 ==="
wait
