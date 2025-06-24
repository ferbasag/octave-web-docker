#!/bin/bash
set -e

# Display setzen
export DISPLAY=:1

# Virtuelle Display mit höherer Auflösung starten
Xvfb :1 -screen 0 1920x1080x24 &
sleep 2

# VNC Server mit optimierten Einstellungen starten
x11vnc -display :1 -nopw -listen 0.0.0.0 -xkb -forever -scale_cursor 1 -repeat -shared &
sleep 2

# NoVNC konfigurieren
cd /usr/share/novnc/
cat > vnc_auto.html <<EOF
<!DOCTYPE html>
<html>
    <head>
        <title>GNU Octave</title>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
        <link rel="stylesheet" href="core/novnc.css">
        <script src="core/novnc.js"></script>
        <style>
            body, html {
                width: 100%;
                height: 100%;
                margin: 0;
                padding: 0;
                overflow: hidden;
                background-color: #1a1a1a;
            }
            #screen {
                position: absolute;
                left: 0;
                top: 0;
                right: 0;
                bottom: 0;
                width: 100%;
                height: 100%;
            }
        </style>
    </head>
    <body>
        <div id="screen"></div>
        <script>
            window.onload = function() {
                const rfb = new novnc.RFB(document.getElementById('screen'), 
                    'ws://' + window.location.host + '/websockify');
                
                // Vollbild und Skalierung aktivieren
                rfb.scaleViewport = true;
                rfb.resizeSession = true;
                rfb.viewOnly = false;
                
                // Automatische Anpassung an Fenstergröße
                window.addEventListener('resize', function() {
                    if (rfb) rfb.scaleViewport = true;
                });
            };
        </script>
    </body>
</html>
EOF

# Symlink für automatischen Start
ln -sf vnc_auto.html index.html

# Websockify mit optimierten Einstellungen starten
websockify --web=/usr/share/novnc/ --heartbeat=30 8080 localhost:5900 &
sleep 2

# Octave mit maximiertem Fenster starten
cd /workspace
octave --gui --force-gui &

# Warten auf alle Prozesse
wait
