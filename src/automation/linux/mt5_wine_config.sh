#!/bin/bash
#═══════════════════════════════════════════════════════════════════════════
# MT5 Wine Configuration Manager
#═══════════════════════════════════════════════════════════════════════════
#
# Verwaltet MT5-Konfigurationen in Wine-Umgebung
# Erstellt Config-Dateien basierend auf Kunden-Eingaben
#
# Usage:
#   ./mt5_wine_config.sh create --account 12345678 --server "ICMarkets-Demo" --password "***"
#   ./mt5_wine_config.sh info
#   ./mt5_wine_config.sh install-mt5
#
# Version: 1.0
# Author: Stelona
#═══════════════════════════════════════════════════════════════════════════

set -e

# ============================================
# KONFIGURATION
# ============================================

WINE_PREFIX="${WINEPREFIX:-$HOME/.wine}"
CONFIG_DIR="${CONFIG_DIR:-/opt/mt5}"
CONFIG_FILE="$CONFIG_DIR/config.json"

# ============================================
# FARBEN
# ============================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;36m'
NC='\033[0m'

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

# Zeige Hilfe
show_help() {
    cat <<EOF
MT5 Wine Configuration Manager v1.0

Usage:
  $0 create [OPTIONS]     Erstellt neue MT5-Konfiguration
  $0 info                 Zeigt aktuelle Konfiguration
  $0 install-mt5          Installiert MT5 in Wine
  $0 test                 Testet Wine-Setup
  $0 help                 Zeigt diese Hilfe

Create Options:
  --account NUMMER        MT5 Account-Nummer (erforderlich)
  --password PASSWORT     MT5 Passwort (erforderlich)
  --server SERVER         Broker-Server (erforderlich)
  --customer-id ID        Kunden-ID für Multi-Tenant (optional)
  --output FILE           Ausgabe-Datei (default: $CONFIG_FILE)

Examples:
  # Einzelner Kunde
  $0 create --account 12345678 --password "MyPass123" --server "ICMarkets-Demo"

  # Multi-Tenant
  $0 create --account 11111111 --password "Pass1" --server "XM-Demo" --customer-id customer1

  # Installation
  $0 install-mt5

EOF
}

# Erstelle Konfiguration aus Kunden-Eingaben
create_config() {
    local account=""
    local password=""
    local server=""
    local customer_id=""
    local output_file="$CONFIG_FILE"

    # Parse Parameter
    while [[ $# -gt 0 ]]; do
        case $1 in
            --account)
                account="$2"
                shift 2
                ;;
            --password)
                password="$2"
                shift 2
                ;;
            --server)
                server="$2"
                shift 2
                ;;
            --customer-id)
                customer_id="$2"
                output_file="$CONFIG_DIR/${customer_id}_config.json"
                shift 2
                ;;
            --output)
                output_file="$2"
                shift 2
                ;;
            *)
                log_error "Unbekannter Parameter: $1"
                show_help
                exit 1
                ;;
        esac
    done

    # Validierung
    if [ -z "$account" ] || [ -z "$password" ] || [ -z "$server" ]; then
        log_error "Account, Password und Server sind erforderlich!"
        show_help
        exit 1
    fi

    log_info "═══════════════════════════════════════════════════════════"
    log_info "   Erstelle MT5-Konfiguration"
    log_info "═══════════════════════════════════════════════════════════"
    log_info "Account:     $account"
    log_info "Server:      $server"
    log_info "Customer-ID: ${customer_id:-N/A}"
    log_info "Ausgabe:     $output_file"
    echo ""

    # Erstelle Config-Verzeichnis
    mkdir -p "$(dirname "$output_file")"

    # MT5-Pfad ermitteln
    local mt5_path=""
    if [ -f "$WINE_PREFIX/drive_c/Program Files/MetaTrader 5/terminal64.exe" ]; then
        mt5_path="C:\\\\Program Files\\\\MetaTrader 5\\\\terminal64.exe"
    elif [ -f "$WINE_PREFIX/drive_c/Program Files (x86)/MetaTrader 5/terminal64.exe" ]; then
        mt5_path="C:\\\\Program Files (x86)\\\\MetaTrader 5\\\\terminal64.exe"
    else
        log_warning "MT5 nicht gefunden - verwende Standard-Pfad"
        mt5_path="C:\\\\Program Files\\\\MetaTrader 5\\\\terminal64.exe"
    fi

    # JSON-Konfiguration erstellen
    cat > "$output_file" <<EOF
{
  "_comment": "MT5 SaaS Auto-Login Konfiguration - Linux/Wine",
  "_version": "1.0",
  "_created": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",

  "account": $account,
  "password": "$password",
  "server": "$server",

  "mt5_path": "$mt5_path",
  "wine_prefix": "$WINE_PREFIX",

  "stop_existing": true,
  "auto_restart": true,
  "restart_delay_seconds": 10,

  "monitoring": {
    "enabled": true,
    "check_interval_seconds": 30,
    "log_status": true
  },

  "logging": {
    "enabled": true,
    "log_file": "/var/log/mt5/mt5_autostart.log",
    "log_level": "INFO"
  },

  "customer": {
    "id": "${customer_id:-default}",
    "created_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  }
}
EOF

    log_success "Konfiguration erstellt: $output_file"
    echo ""

    # Sichere Berechtigungen setzen
    chmod 600 "$output_file"
    log_success "Berechtigungen gesetzt (600 - nur Owner kann lesen/schreiben)"
    echo ""

    log_info "Nächste Schritte:"
    log_info "1. Prüfen Sie die Konfiguration: cat $output_file"
    log_info "2. Testen Sie das Setup: $0 test"
    log_info "3. Installieren Sie den Service: sudo ./install_systemd_service.sh $output_file"
    echo ""
}

# Zeige aktuelle Konfiguration
show_info() {
    log_info "═══════════════════════════════════════════════════════════"
    log_info "   MT5 Wine-Umgebung Informationen"
    log_info "═══════════════════════════════════════════════════════════"
    echo ""

    # Wine
    if command -v wine &> /dev/null; then
        local wine_version=$(wine --version 2>/dev/null || echo "unknown")
        log_success "Wine installiert: $wine_version"
    else
        log_error "Wine NICHT installiert!"
    fi

    # Wine Prefix
    if [ -d "$WINE_PREFIX" ]; then
        log_success "Wine Prefix: $WINE_PREFIX"
    else
        log_warning "Wine Prefix nicht gefunden: $WINE_PREFIX"
    fi

    # MT5
    if [ -f "$WINE_PREFIX/drive_c/Program Files/MetaTrader 5/terminal64.exe" ]; then
        log_success "MT5 installiert: C:\\Program Files\\MetaTrader 5\\terminal64.exe"
    elif [ -f "$WINE_PREFIX/drive_c/Program Files (x86)/MetaTrader 5/terminal64.exe" ]; then
        log_success "MT5 installiert: C:\\Program Files (x86)\\MetaTrader 5\\terminal64.exe"
    else
        log_warning "MT5 nicht in Wine installiert"
    fi

    # Xvfb
    if command -v Xvfb &> /dev/null; then
        log_success "Xvfb installiert"
    else
        log_warning "Xvfb nicht installiert (für headless empfohlen)"
    fi

    # jq
    if command -v jq &> /dev/null; then
        log_success "jq installiert"
    else
        log_error "jq NICHT installiert (erforderlich!)"
    fi

    echo ""

    # Konfigurationsdateien
    log_info "Konfigurationsdateien:"
    if [ -d "$CONFIG_DIR" ]; then
        find "$CONFIG_DIR" -name "*.json" 2>/dev/null | while read -r file; do
            log_info "  - $file"
        done
    else
        log_warning "Config-Verzeichnis nicht gefunden: $CONFIG_DIR"
    fi

    echo ""
}

# Installiere MT5 in Wine
install_mt5() {
    log_info "═══════════════════════════════════════════════════════════"
    log_info "   MT5 Installation in Wine"
    log_info "═══════════════════════════════════════════════════════════"
    echo ""

    # Prüfe Wine
    if ! command -v wine &> /dev/null; then
        log_error "Wine ist nicht installiert!"
        log_info "Installieren Sie Wine zuerst:"
        log_info "  Ubuntu/Debian: sudo apt-get install wine wine64"
        log_info "  Fedora:        sudo dnf install wine"
        exit 1
    fi

    log_success "Wine gefunden: $(wine --version)"
    echo ""

    # MT5-Installer herunterladen
    log_info "Lädt MT5-Installer herunter..."

    local mt5_installer="/tmp/mt5setup.exe"

    if [ -f "$mt5_installer" ]; then
        log_info "Installer bereits vorhanden: $mt5_installer"
    else
        # Download von MetaQuotes
        wget -O "$mt5_installer" "https://download.mql5.com/cdn/web/metaquotes.software.corp/mt5/mt5setup.exe" || {
            log_error "Download fehlgeschlagen!"
            log_info "Laden Sie den Installer manuell herunter:"
            log_info "  https://www.metatrader5.com/en/download"
            exit 1
        }
        log_success "Download abgeschlossen"
    fi

    echo ""
    log_info "Starte Installation..."
    log_warning "WICHTIG: Wählen Sie 'Silent Installation' oder verwenden Sie Standard-Einstellungen"
    echo ""

    # Installation starten
    WINEPREFIX=$WINE_PREFIX wine "$mt5_installer" /auto

    log_success "Installation abgeschlossen"
    echo ""

    # Validierung
    if [ -f "$WINE_PREFIX/drive_c/Program Files/MetaTrader 5/terminal64.exe" ] || \
       [ -f "$WINE_PREFIX/drive_c/Program Files (x86)/MetaTrader 5/terminal64.exe" ]; then
        log_success "MT5 erfolgreich installiert!"
    else
        log_warning "MT5-Installation konnte nicht validiert werden"
        log_info "Prüfen Sie manuell: ls -la $WINE_PREFIX/drive_c/Program*/"
    fi

    echo ""
}

# Teste Wine-Setup
test_wine() {
    log_info "═══════════════════════════════════════════════════════════"
    log_info "   Wine-Setup Test"
    log_info "═══════════════════════════════════════════════════════════"
    echo ""

    local errors=0

    # Wine
    if command -v wine &> /dev/null; then
        log_success "✓ Wine installiert"
    else
        log_error "✗ Wine NICHT installiert"
        errors=$((errors + 1))
    fi

    # jq
    if command -v jq &> /dev/null; then
        log_success "✓ jq installiert"
    else
        log_error "✗ jq NICHT installiert"
        errors=$((errors + 1))
    fi

    # Xvfb
    if command -v Xvfb &> /dev/null; then
        log_success "✓ Xvfb installiert"
    else
        log_warning "⚠ Xvfb nicht installiert (optional für headless)"
    fi

    # Wine Prefix
    if [ -d "$WINE_PREFIX" ]; then
        log_success "✓ Wine Prefix existiert: $WINE_PREFIX"
    else
        log_warning "⚠ Wine Prefix nicht gefunden - wird beim ersten Start erstellt"
    fi

    # MT5
    if [ -f "$WINE_PREFIX/drive_c/Program Files/MetaTrader 5/terminal64.exe" ] || \
       [ -f "$WINE_PREFIX/drive_c/Program Files (x86)/MetaTrader 5/terminal64.exe" ]; then
        log_success "✓ MT5 installiert"
    else
        log_error "✗ MT5 NICHT installiert"
        log_info "  Installieren Sie MT5: $0 install-mt5"
        errors=$((errors + 1))
    fi

    echo ""

    if [ $errors -eq 0 ]; then
        log_success "═══════════════════════════════════════════════════════════"
        log_success "   Alle Tests bestanden! ✓"
        log_success "═══════════════════════════════════════════════════════════"
    else
        log_error "═══════════════════════════════════════════════════════════"
        log_error "   $errors Fehler gefunden!"
        log_error "═══════════════════════════════════════════════════════════"
        exit 1
    fi

    echo ""
}

# ============================================
# HAUPTPROGRAMM
# ============================================

COMMAND="${1:-help}"

case "$COMMAND" in
    create)
        shift
        create_config "$@"
        ;;
    info)
        show_info
        ;;
    install-mt5)
        install_mt5
        ;;
    test)
        test_wine
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        log_error "Unbekannter Befehl: $COMMAND"
        show_help
        exit 1
        ;;
esac
