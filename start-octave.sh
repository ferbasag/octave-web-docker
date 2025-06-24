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

# Erstelle die Hauptanwendung
cat > index.html <<EOF
<!DOCTYPE html>
<html>
    <head>
        <title>GNU Octave</title>
        <meta charset="utf-8">
        <meta http-equiv="refresh" content="0;url=/vnc_auto.html">
    </head>
</html>
EOF

# Erstelle die VNC Viewer Seite
cat > vnc_auto.html <<EOF
<!DOCTYPE html>
<html>
    <head>
        <title>GNU Octave</title>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <link rel="stylesheet" href="core/novnc.css">
        <script src="core/novnc.js"></script>
        <style>
            body, html {
                margin: 0;
                padding: 0;
                height: 100%;
                overflow: hidden;
            }
            #screen {
                width: 100vw;
                height: 100vh;
            }
        </style>
    </head>
    <body>
        <div id="screen"></div>
        <script>
            window.onload = function() {
                const rfb = new novnc.RFB(document.getElementById('screen'), 
                    'ws://' + window.location.host + '/websockify');
                rfb.scaleViewport = true;
                rfb.resizeSession = true;
            };
        </script>
    </body>
</html>
EOF

# Erstelle Symlinks für Kompatibilität
ln -sf vnc_auto.html vnc.html
ln -sf vnc_auto.html vnc_lite.html

# Starte websockify mit korrekter Konfiguration
websockify --web=/usr/share/novnc/ 8080 localhost:5900 &
sleep 5

echo "Starting Octave GUI..."
cd /workspace
octave --gui &

echo "=== All services started! Access via browser on port 8080 ==="
wait
