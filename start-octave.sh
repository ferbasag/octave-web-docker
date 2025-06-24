#!/bin/bash
set -e

# Display setzen
export DISPLAY=:1

# Virtuelle Display starten
Xvfb :1 -screen 0 1024x768x24 &
sleep 2

# VNC Server starten
x11vnc -display :1 -nopw -listen 0.0.0.0 -xkb -forever &
sleep 2

# NoVNC konfigurieren
cd /usr/share/novnc/
cat > vnc_auto.html <<EOF
<!DOCTYPE html>
<html>
    <head>
        <title>GNU Octave</title>
        <meta charset="utf-8">
        <script src="core/novnc.js"></script>
    </head>
    <body style="margin:0;padding:0;height:100vh">
        <div id="screen" style="width:100%;height:100%"></div>
        <script>
            new novnc.RFB(document.getElementById('screen'), 
                'ws://' + window.location.host + '/websockify');
        </script>
    </body>
</html>
EOF

# Symlink für automatischen Start
ln -sf vnc_auto.html index.html

# Websockify starten
websockify --web=/usr/share/novnc/ 8080 localhost:5900 &
sleep 2

# Octave starten
cd /workspace
octave --gui &

# Warten auf alle Prozesse
wait
