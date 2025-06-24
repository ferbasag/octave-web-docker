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
# Erstelle eine angepasste gnu-octave Datei mit automatischer Verbindung
cat > gnu-octave <<EOF
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

ln -sf gnu-octave index.html
websockify --web=/usr/share/novnc/ 8080 localhost:5900 &
sleep 5

echo "Starting Octave GUI..."
cd /workspace
octave --gui &

echo "=== All services started! Access via browser on port 8080 ==="
wait
