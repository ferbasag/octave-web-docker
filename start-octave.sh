#!/bin/bash
set -e

echo "Starting VNC server setup..."

# Nutze die Umgebungsvariablen oder Standardwerte
RESOLUTION=${VNC_RESOLUTION:-1920x1080}
PORT=${NO_VNC_PORT:-8080}

# Starte Xvfb
Xvfb :1 -screen 0 ${RESOLUTION}x24 &
sleep 2

# Starte VNC Server
x11vnc -display :1 -nopw -listen 0.0.0.0 -xkb -forever -shared &
sleep 2

# Lösche vorhandene Symlinks und erstelle unsere NoVNC Konfiguration
rm -f /usr/share/novnc/vnc_auto.html
rm -f /usr/share/novnc/index.html

cat > /usr/share/novnc/vnc_auto.html <<EOF
<!DOCTYPE html>
<html>
    <head>
        <title>GNU Octave Web Interface</title>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <script src="core/novnc.js"></script>
        <style>
            html, body { 
                height: 100%; 
                margin: 0; 
                background-color: #2b2b2b;
            }
            #screen {
                position: fixed;
                top: 0;
                left: 0;
                width: 100vw;
                height: 100vh;
                box-sizing: border-box;
                margin: 0;
                padding: 0;
            }
        </style>
    </head>
    <body>
        <div id="screen"></div>
        <script>
            window.onload = function() {
                let rfb = new novnc.RFB(document.getElementById('screen'),
                    'ws://' + window.location.host + '/websockify');
                rfb.scaleViewport = true;
                rfb.resizeSession = true;
                rfb.viewOnly = false;
                
                // Automatische Größenanpassung
                function updateDisplay() {
                    if (rfb) {
                        rfb.scaleViewport = true;
                        rfb.resizeSession = true;
                    }
                }
                
                window.onresize = updateDisplay;
                updateDisplay();
            };
        </script>
    </body>
</html>
EOF

# Erstelle index.html mit direkter Weiterleitung zur vnc_auto.html
cat > /usr/share/novnc/index.html <<EOF
<!DOCTYPE html>
<html>
    <head>
        <meta http-equiv="refresh" content="0;url=vnc_auto.html">
    </head>
</html>
EOF

# Starte Websockify
websockify --web=/usr/share/novnc/ ${PORT} localhost:5900 &
sleep 2

echo "Starting Octave..."
cd ${WORKSPACE}
octave --force-gui &

echo "Setup complete. Access via browser at port ${PORT}"
wait
