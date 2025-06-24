FROM gnuoctave/octave:latest

# VNC und Web-Tools installieren
RUN apt-get update && apt-get install -y \
    xvfb x11vnc novnc websockify \
    && rm -rf /var/lib/apt/lists/*

# NoVNC-Konfiguration
RUN mkdir -p /usr/share/novnc/
COPY start-octave.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/start-octave.sh

# Environment Variablen setzen
ENV DISPLAY=:1 \
    WORKSPACE=/workspace \
    HOME=/workspace \
    NVIDIA_VISIBLE_DEVICES=all \
    CUDA_VISIBLE_DEVICES=all \
    NVIDIA_DRIVER_CAPABILITIES=compute,utility \
    QT_GRAPHICSSYSTEM=native \
    XDG_RUNTIME_DIR=/tmp/runtime-octave

WORKDIR /workspace
EXPOSE 8080

# Standardbefehl setzen
ENTRYPOINT ["/usr/local/bin/start-octave.sh"]
