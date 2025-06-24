FROM gnuoctave/octave:latest

# System-Pakete installieren
RUN apt-get update && apt-get install -y \
    xvfb x11vnc novnc websockify python3 \
    && rm -rf /var/lib/apt/lists/*

# NoVNC Setup
RUN mkdir -p /usr/share/novnc && \
    ln -s /usr/share/novnc/vnc_auto.html /usr/share/novnc/index.html

# Startup-Script kopieren
COPY start-octave.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/start-octave.sh

# Environment Variablen für Run.ai
ENV DISPLAY=:1 \
    VNC_RESOLUTION=1920x1080 \
    NO_VNC_PORT=8080 \
    WORKSPACE=/workspace \
    HOME=/workspace

# Arbeitsverzeichnis
WORKDIR /workspace

# Port für NoVNC
EXPOSE 8080

# Entrypoint für Run.ai
ENTRYPOINT ["/usr/local/bin/start-octave.sh"]
