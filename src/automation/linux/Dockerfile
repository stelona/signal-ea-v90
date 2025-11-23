# ═══════════════════════════════════════════════════════════════════════════
# MT5 Auto-Start Docker Container - SaaS Edition
# ═══════════════════════════════════════════════════════════════════════════
#
# Vollautomatischer MT5-Container für SaaS-Plattformen
# Läuft isolated mit Wine und Xvfb
#
# Build:
#   docker build -t mt5-saas:latest .
#
# Run:
#   docker run -d \
#     --name mt5-customer1 \
#     -v /path/to/config.json:/opt/mt5/config.json:ro \
#     -e ACCOUNT=12345678 \
#     -e PASSWORD="YourPassword" \
#     -e SERVER="ICMarkets-Demo" \
#     mt5-saas:latest
#
# Version: 1.0
# Author: Stelona
# ═══════════════════════════════════════════════════════════════════════════

FROM ubuntu:22.04

LABEL maintainer="Stelona <support@stelona.com>"
LABEL description="MetaTrader 5 Auto-Start Container for SaaS Platforms"
LABEL version="1.0"

# ============================================
# UMGEBUNGSVARIABLEN
# ============================================

ENV DEBIAN_FRONTEND=noninteractive \
    DISPLAY=:99 \
    WINEPREFIX=/opt/wine \
    WINEARCH=win64 \
    WINE_MONO_VERSION=7.4.0 \
    WINE_GECKO_VERSION=2.47.3

# ============================================
# SYSTEM-PAKETE INSTALLIEREN
# ============================================

RUN apt-get update && apt-get install -y \
    # Wine und Abhängigkeiten
    wine \
    wine64 \
    winetricks \
    # Virtual Display
    xvfb \
    x11vnc \
    # Utilities
    wget \
    curl \
    jq \
    procps \
    psmisc \
    # Cleanup
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# ============================================
# WINE KONFIGURATION
# ============================================

# Wine initialisieren (erstellt .wine Prefix)
RUN wine wineboot --init && \
    wineserver -w

# Wine-Mono und Gecko installieren (für .NET Support)
RUN wget -q https://dl.winehq.org/wine/wine-mono/7.4.0/wine-mono-7.4.0-x86.msi -O /tmp/wine-mono.msi && \
    wine msiexec /i /tmp/wine-mono.msi /quiet && \
    rm /tmp/wine-mono.msi && \
    wineserver -w

# ============================================
# MT5 INSTALLATION
# ============================================

# MT5-Installer herunterladen und installieren
RUN wget -q https://download.mql5.com/cdn/web/metaquotes.software.corp/mt5/mt5setup.exe -O /tmp/mt5setup.exe && \
    wine /tmp/mt5setup.exe /auto && \
    wineserver -w && \
    rm /tmp/mt5setup.exe

# ============================================
# SCRIPT-FILES KOPIEREN
# ============================================

# Erstelle Arbeitsverzeichnisse
RUN mkdir -p /opt/mt5 /var/log/mt5

# Kopiere Automation-Scripts
COPY mt5_autostart.sh /opt/mt5/
COPY mt5_wine_config.sh /opt/mt5/

# Ausführbar machen
RUN chmod +x /opt/mt5/*.sh

# ============================================
# ENTRYPOINT SCRIPT
# ============================================

# Entrypoint erstellen
RUN cat > /opt/mt5/docker-entrypoint.sh <<'EOF'
#!/bin/bash
set -e

echo "═══════════════════════════════════════════════════════════"
echo "   MT5 Auto-Start Docker Container v1.0"
echo "   Copyright 2024 Stelona"
echo "═══════════════════════════════════════════════════════════"
echo ""

# Umgebungsvariablen prüfen
if [ -n "$ACCOUNT" ] && [ -n "$PASSWORD" ] && [ -n "$SERVER" ]; then
    echo "[INFO] Erstelle Config aus Umgebungsvariablen..."

    cat > /opt/mt5/config.json <<EOFCONFIG
{
  "account": $ACCOUNT,
  "password": "$PASSWORD",
  "server": "$SERVER",
  "mt5_path": "C:\\\\Program Files\\\\MetaTrader 5\\\\terminal64.exe",
  "wine_prefix": "$WINEPREFIX",
  "stop_existing": true,
  "auto_restart": true,
  "monitoring": {
    "enabled": true,
    "check_interval_seconds": 30
  },
  "logging": {
    "log_file": "/var/log/mt5/mt5_autostart.log"
  }
}
EOFCONFIG

    echo "[SUCCESS] Config erstellt"
fi

# Prüfe ob Config existiert
if [ ! -f /opt/mt5/config.json ]; then
    echo "[ERROR] Keine Konfigurationsdatei gefunden!"
    echo "[ERROR] Entweder: 1) Mount config.json oder 2) Setze ENV-Variablen"
    echo ""
    echo "Beispiel mit ENV:"
    echo "  docker run -e ACCOUNT=12345678 -e PASSWORD='...' -e SERVER='...' mt5-saas"
    echo ""
    echo "Beispiel mit Mount:"
    echo "  docker run -v /path/to/config.json:/opt/mt5/config.json:ro mt5-saas"
    exit 1
fi

# Starte Xvfb (Virtual Display)
echo "[INFO] Starte Xvfb..."
Xvfb :99 -screen 0 1024x768x24 &
sleep 2

# Starte MT5 Auto-Start Script
echo "[INFO] Starte MT5 Auto-Start..."
exec /opt/mt5/mt5_autostart.sh /opt/mt5/config.json
EOF

RUN chmod +x /opt/mt5/docker-entrypoint.sh

# ============================================
# VOLUMES
# ============================================

# Config und Logs als Volumes
VOLUME ["/opt/mt5/config", "/var/log/mt5"]

# ============================================
# HEALTHCHECK
# ============================================

HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD pgrep -f "terminal64.exe" > /dev/null || exit 1

# ============================================
# USER & ENTRYPOINT
# ============================================

# Als non-root user ausführen (Security Best Practice)
RUN useradd -m -s /bin/bash mt5user && \
    chown -R mt5user:mt5user /opt/mt5 /opt/wine /var/log/mt5

USER mt5user
WORKDIR /opt/mt5

# Entrypoint
ENTRYPOINT ["/opt/mt5/docker-entrypoint.sh"]
