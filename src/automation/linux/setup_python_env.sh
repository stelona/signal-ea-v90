#!/bin/bash
#═══════════════════════════════════════════════════════════════════════════
# Python Environment Setup für MT5 Auto-Login
#═══════════════════════════════════════════════════════════════════════════
#
# Installiert alle erforderlichen Python-Pakete für auto_login.py
#
# Usage:
#   sudo ./setup_python_env.sh
#
# Version: 1.0
# Author: Stelona
#═══════════════════════════════════════════════════════════════════════════

set -e

# Farben
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;36m'
NC='\033[0m'

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

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}   Python Environment Setup für MT5 Auto-Login${NC}"
echo -e "${BLUE}   Copyright 2024 Stelona${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

# Python-Version prüfen
log_info "Prüfe Python-Installation..."

if ! command -v python3 &> /dev/null; then
    log_error "Python 3 ist nicht installiert!"
    log_info "Installieren Sie Python 3:"
    log_info "  sudo apt-get install python3 python3-pip"
    exit 1
fi

PYTHON_VERSION=$(python3 --version | awk '{print $2}')
log_success "Python gefunden: $PYTHON_VERSION"

# pip prüfen
if ! command -v pip3 &> /dev/null; then
    log_warning "pip3 nicht gefunden - installiere..."
    sudo apt-get update
    sudo apt-get install -y python3-pip
fi

log_success "pip3 gefunden"
echo ""

# MetaTrader5 Python Package installieren
log_info "═══════════════════════════════════════════════════════════"
log_info "   Installiere MetaTrader5 Python Package"
log_info "═══════════════════════════════════════════════════════════"
echo ""

log_info "Installiere MetaTrader5..."
pip3 install --upgrade MetaTrader5

log_success "MetaTrader5 Package installiert"
echo ""

# Zusätzliche nützliche Pakete
log_info "Installiere zusätzliche Pakete..."
pip3 install --upgrade configparser

log_success "Alle Pakete installiert"
echo ""

# Verifizierung
log_info "═══════════════════════════════════════════════════════════"
log_info "   Verifikation"
log_info "═══════════════════════════════════════════════════════════"
echo ""

log_info "Teste MetaTrader5 Import..."
python3 -c "import MetaTrader5 as mt5; print(f'MT5 Version: {mt5.__version__}')" 2>/dev/null

if [ $? -eq 0 ]; then
    log_success "✓ MetaTrader5 Package funktioniert"
else
    log_error "✗ MetaTrader5 Package konnte nicht importiert werden"
    exit 1
fi

echo ""

# Script ausführbar machen
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AUTO_LOGIN_SCRIPT="$SCRIPT_DIR/auto_login.py"

if [ -f "$AUTO_LOGIN_SCRIPT" ]; then
    chmod +x "$AUTO_LOGIN_SCRIPT"
    log_success "auto_login.py ist ausführbar"
fi

echo ""
log_success "═══════════════════════════════════════════════════════════"
log_success "   Setup erfolgreich abgeschlossen!"
log_success "═══════════════════════════════════════════════════════════"
echo ""

log_info "Nächste Schritte:"
log_info "1. Erstellen Sie login.ini:"
log_info "   cp examples/login.ini ~/.wine/drive_c/MT5/login.ini"
log_info "   nano ~/.wine/drive_c/MT5/login.ini"
log_info ""
log_info "2. Testen Sie das Login-Script:"
log_info "   python3 $AUTO_LOGIN_SCRIPT"
log_info ""
log_info "3. Integrieren Sie in Auto-Start (optional):"
log_info "   Siehe: INTEGRATION_GUIDE.md"
echo ""
