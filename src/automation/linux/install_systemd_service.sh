#!/bin/bash
#═══════════════════════════════════════════════════════════════════════════
# Systemd Service Installer für MT5 Auto-Start
#═══════════════════════════════════════════════════════════════════════════
#
# Installiert MT5 Auto-Start als systemd Service für automatischen Start
# beim System-Boot
#
# Usage:
#   sudo ./install_systemd_service.sh /opt/mt5/config.json
#
# Version: 1.0
# Author: Stelona
#═══════════════════════════════════════════════════════════════════════════

set -e

# ============================================
# FARBEN
# ============================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;36m'
NC='\033[0m' # No Color

# ============================================
# FUNKTIONEN
# ============================================

log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*"
}

check_root() {
    if [ "$EUID" -ne 0 ]; then
        log_error "Dieses Script muss als root ausgeführt werden"
        log_error "Bitte verwenden Sie: sudo $0"
        exit 1
    fi
}

# ============================================
# PARAMETER
# ============================================

CONFIG_FILE="${1:-/opt/mt5/config.json}"
SERVICE_NAME="${2:-mt5-autostart}"
SERVICE_USER="${3:-$SUDO_USER}"

# ============================================
# HAUPTPROGRAMM
# ============================================

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}   MT5 Systemd Service Installer v1.0${NC}"
echo -e "${BLUE}   Copyright 2024 Stelona${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

# Root-Check
check_root

log_info "Konfiguration:"
log_info "  Config-Datei: $CONFIG_FILE"
log_info "  Service-Name: $SERVICE_NAME"
log_info "  User:         $SERVICE_USER"
echo ""

# Validierung
if [ ! -f "$CONFIG_FILE" ]; then
    log_error "Konfigurationsdatei nicht gefunden: $CONFIG_FILE"
    exit 1
fi

log_success "Konfigurationsdatei gefunden"

# Script-Pfad
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AUTOSTART_SCRIPT="$SCRIPT_DIR/mt5_autostart.sh"

if [ ! -f "$AUTOSTART_SCRIPT" ]; then
    log_error "mt5_autostart.sh nicht gefunden in: $SCRIPT_DIR"
    exit 1
fi

log_success "Auto-Start Script gefunden: $AUTOSTART_SCRIPT"

# Stelle sicher, dass Script ausführbar ist
chmod +x "$AUTOSTART_SCRIPT"

# Erstelle Log-Verzeichnis
mkdir -p /var/log/mt5
chown "$SERVICE_USER:$SERVICE_USER" /var/log/mt5
log_success "Log-Verzeichnis erstellt: /var/log/mt5"

# Wine-Prefix für User
WINE_PREFIX="/home/$SERVICE_USER/.wine"

if [ ! -d "$WINE_PREFIX" ]; then
    log_warning "Wine-Prefix nicht gefunden: $WINE_PREFIX"
    log_warning "Stellen Sie sicher, dass Wine konfiguriert ist"
fi

# ============================================
# SYSTEMD SERVICE DATEI ERSTELLEN
# ============================================

log_info "Erstelle systemd Service-Datei..."

SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"

cat > "$SERVICE_FILE" <<EOF
[Unit]
Description=MetaTrader 5 Auto-Start Service (Wine)
After=network.target

[Service]
Type=simple
User=$SERVICE_USER
Group=$SERVICE_USER

# Umgebungsvariablen
Environment="DISPLAY=:99"
Environment="WINEPREFIX=$WINE_PREFIX"
Environment="HEADLESS=true"

# Working Directory
WorkingDirectory=/home/$SERVICE_USER

# Start-Kommando
ExecStart=$AUTOSTART_SCRIPT $CONFIG_FILE

# Restart Policy
Restart=always
RestartSec=10

# Logging
StandardOutput=append:/var/log/mt5/service_stdout.log
StandardError=append:/var/log/mt5/service_stderr.log

# Security (optional - anpassen nach Bedarf)
# NoNewPrivileges=true
# PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF

log_success "Service-Datei erstellt: $SERVICE_FILE"

# ============================================
# SYSTEMD RELOAD UND ENABLE
# ============================================

log_info "Lade systemd Konfiguration neu..."
systemctl daemon-reload

log_info "Aktiviere Service für Auto-Start..."
systemctl enable "$SERVICE_NAME"

log_success "Service aktiviert"

# ============================================
# OPTIONAL: XVFB SERVICE
# ============================================

log_info ""
log_info "═══════════════════════════════════════════════════════════"
log_info "   Xvfb (Virtual Display) Setup"
log_info "═══════════════════════════════════════════════════════════"

if ! command -v Xvfb &> /dev/null; then
    log_warning "Xvfb nicht installiert!"
    log_info "Installieren Sie Xvfb für headless Betrieb:"
    log_info "  sudo apt-get update"
    log_info "  sudo apt-get install xvfb"
    echo ""
else
    log_success "Xvfb ist installiert"

    # Erstelle Xvfb Service
    log_info "Erstelle Xvfb systemd Service..."

    XVFB_SERVICE_FILE="/etc/systemd/system/xvfb.service"

    cat > "$XVFB_SERVICE_FILE" <<EOF
[Unit]
Description=X Virtual Frame Buffer Service
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/Xvfb :99 -screen 0 1024x768x24 -ac +extension GLX +render -noreset

Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable xvfb
    systemctl start xvfb

    log_success "Xvfb Service erstellt und gestartet"
fi

# ============================================
# SERVICE STARTEN
# ============================================

echo ""
log_info "═══════════════════════════════════════════════════════════"
log_info "   Service-Start"
log_info "═══════════════════════════════════════════════════════════"

read -p "Möchten Sie den Service jetzt starten? [J/n] " -n 1 -r
echo
if [[ $REPLY =~ ^[Jj]$ ]] || [[ -z $REPLY ]]; then
    log_info "Starte Service: $SERVICE_NAME"
    systemctl start "$SERVICE_NAME"

    sleep 3

    # Status prüfen
    if systemctl is-active --quiet "$SERVICE_NAME"; then
        log_success "Service läuft!"
    else
        log_error "Service läuft nicht - prüfen Sie die Logs:"
        log_error "  sudo journalctl -u $SERVICE_NAME -f"
    fi
else
    log_info "Service wurde nicht gestartet"
    log_info "Starten Sie den Service manuell mit:"
    log_info "  sudo systemctl start $SERVICE_NAME"
fi

# ============================================
# ZUSAMMENFASSUNG
# ============================================

echo ""
log_success "═══════════════════════════════════════════════════════════"
log_success "   Installation erfolgreich abgeschlossen!"
log_success "═══════════════════════════════════════════════════════════"
echo ""

log_info "Service-Name: $SERVICE_NAME"
log_info "Config-Datei: $CONFIG_FILE"
log_info "Log-Dateien:  /var/log/mt5/"
echo ""

log_info "Wichtige Befehle:"
log_info "  Status prüfen:    sudo systemctl status $SERVICE_NAME"
log_info "  Logs anzeigen:    sudo journalctl -u $SERVICE_NAME -f"
log_info "  Service stoppen:  sudo systemctl stop $SERVICE_NAME"
log_info "  Service starten:  sudo systemctl start $SERVICE_NAME"
log_info "  Service neuladen: sudo systemctl restart $SERVICE_NAME"
log_info "  Auto-Start aus:   sudo systemctl disable $SERVICE_NAME"
echo ""

log_info "MT5 startet nun automatisch bei jedem System-Boot!"
echo ""
