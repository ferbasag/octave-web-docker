#!/bin/bash
set -e

echo "Starting VNC server setup..."

# Parameter verarbeiten
AUTO_CONNECT=false
FULLSCREEN=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --auto-connect)
            AUTO_CONNECT=true
            shift
            ;;
        --fullscreen)
            FULLSCREEN=true
            shift
            ;;
        *)
            shift
            ;;
    esac
done

# Umgebungsvariablen prüfen
if [ "${VNC_AUTO_REDIRECT}" = "true" ]; then
    AUTO_CONNECT=true
fi

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

# Auto-connect Parameter für NoVNC
AUTOCONNECT_PARAM=""
if [ "$AUTO_CONNECT" = true ]; then
    AUTOCONNECT_PARAM="?autoconnect=true&resize=scale&view_only=0"
fi

# Erstelle die optimierte vnc_auto.html
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
                overflow: hidden;
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
            .loading {
                position: fixed;
                top: 50%;
                left: 50%;
                transform: translate(-50%, -50%);
                color: white;
                font-family: Arial, sans-serif;
                text-align: center;
            }
        </style>
    </head>
    <body>
        <div id="screen"></div>
        <div class="loading">Connecting to Octave...</div>
        <script>
            window.onload = function() {
                const wsProtocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
                const wsUrl = wsProtocol + '//' + window.location.host + '/websockify';
                
                let rfb = new novnc.RFB(document.getElementById('screen'), wsUrl);
                
                // Optimierte Einstellungen
                rfb.scaleViewport = true;
                rfb.resizeSession = true;
                rfb.viewOnly = false;
                rfb.showDotCursor = false;
                
                // Automatisch verbinden
                rfb.connect();
                
                // Event Handler
                rfb.addEventListener('connect', () => {
                    document.querySelector('.loading').style.display = 'none';
                });
                
                rfb.addEventListener('disconnect', () => {
                    document.querySelector('.loading').style.display = 'block';
                });
                
                // Automatische Größenanpassung
                function updateDisplay() {
                    if (rfb && rfb._display) {
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

# Erstelle index.html mit direkter Weiterleitung
cat > /usr/share/novnc/index.html <<EOF
<!DOCTYPE html>
<html>
    <head>
        <meta http-equiv="refresh" content="0;url=vnc_auto.html${AUTOCONNECT_PARAM}">
        <title>Redirecting to Octave...</title>
    </head>
    <body style="font-family: Arial, sans-serif; text-align: center; margin-top: 50px;">
        <h2>Redirecting to GNU Octave...</h2>
        <p>If you are not redirected automatically, <a href="vnc_auto.html${AUTOCONNECT_PARAM}">click here</a>.</p>
    </body>
</html>
EOF

# Starte Websockify
websockify --web=/usr/share/novnc/ ${PORT} localhost:5900 &
sleep 2

echo "Starting Octave..."
cd ${WORKSPACE}
octave --force-gui &

echo "Setup complete. Access via browser at port ${PORT}"
echo "Direct VNC access: vnc_auto.html${AUTOCONNECT_PARAM}"
wait
