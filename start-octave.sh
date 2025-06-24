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
cd /usr/share/novnc/

# Erstelle Weiterleitungen basierend auf MWI_BASE_URL
BASE_URL=${MWI_BASE_URL:-/gnu-octave}
BASE_FILE=$(basename ${BASE_URL})

# Erstelle die Hauptanwendung unter dem konfigurierten Namen
cat > "${BASE_FILE}" <<EOF
<!DOCTYPE html>
<html>
    <head>
        <title>GNU Octave</title>
        <meta charset="utf-8">
        <script src="core/novnc.js"></script>
    </head>
    <body>
        <div id="screen"></div>
        <script>
            window.onload = function() {
                const urlParams = new URLSearchParams(window.location.search);
                let host = window.location.hostname;
                let port = window.location.port;
                let path = 'websockify';
                
                let rfb = new novnc.RFB(document.getElementById('screen'), 
                    'ws://' + host + ':' + port + '/' + path);
                rfb.scaleViewport = true;
                rfb.resizeSession = true;
            };
        </script>
    </body>
</html>
EOF

# Erstelle index.html mit Weiterleitung
cat > index.html <<EOF
<!DOCTYPE html>
<html>
<head>
    <meta http-equiv="refresh" content="0;url=${BASE_URL}" />
</head>
</html>
EOF

# Erstelle Symlinks für alle bekannten Pfade zum konfigurierten File
ln -sf "${BASE_FILE}" vnc.html
ln -sf "${BASE_FILE}" vnc_auto.html
ln -sf "${BASE_FILE}" vnc_auto.html@
ln -sf "${BASE_FILE}" vnc_lite.html
ln -sf "${BASE_FILE}" gnu-octave

# Starte websockify
websockify --web=/usr/share/novnc/ 8080 localhost:5900 &
sleep 5

echo "Starting Octave GUI..."
cd /workspace
octave --gui &

echo "=== All services started! Access via browser on port 8080 ==="
wait
