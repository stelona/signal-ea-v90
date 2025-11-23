#!/bin/bash
#═══════════════════════════════════════════════════════════════════════════
# MT5 Auto-Start für Linux/Wine - SaaS Platform Edition
#═══════════════════════════════════════════════════════════════════════════
#
# Vollautomatischer MT5-Start in Wine-Umgebung
# ZERO manuelle Interaktion - perfekt für SaaS-Plattformen
#
# Version: 1.0
# Author: Stelona
# Copyright 2024 Stelona. All rights reserved.
#═══════════════════════════════════════════════════════════════════════════

set -e  # Exit on error

# ============================================
# KONFIGURATION
# ============================================

CONFIG_FILE="${1:-/opt/mt5/config.json}"
LOG_FILE="${LOG_FILE:-/var/log/mt5/autostart.log}"
WINE_PREFIX="${WINEPREFIX:-$HOME/.wine}"
DISPLAY="${DISPLAY:-:99}"  # Xvfb display for headless

# ============================================
# FUNKTIONEN
# ============================================

# Logging-Funktion
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local color=""

    case "$level" in
        INFO)    color="\033[0;36m" ;;  # Cyan
        SUCCESS) color="\033[0;32m" ;;  # Green
        WARNING) color="\033[0;33m" ;;  # Yellow
        ERROR)   color="\033[0;31m" ;;  # Red
        *)       color="\033[0m" ;;     # Default
    esac

    # Konsole (mit Farbe)
    echo -e "${color}[${timestamp}] [${level}] ${message}\033[0m"

    # Log-Datei (ohne Farbe)
    echo "[${timestamp}] [${level}] ${message}" >> "$LOG_FILE"
}

# JSON-Parser (einfach mit jq)
read_config() {
    if ! command -v jq &> /dev/null; then
        log ERROR "jq ist nicht installiert. Bitte installieren: sudo apt-get install jq"
        exit 1
    fi

    if [ ! -f "$CONFIG_FILE" ]; then
        log ERROR "Konfigurationsdatei nicht gefunden: $CONFIG_FILE"
        exit 1
    fi

    log INFO "Lese Konfiguration: $CONFIG_FILE"

    # Config-Werte extrahieren
    ACCOUNT=$(jq -r '.account' "$CONFIG_FILE")
    PASSWORD=$(jq -r '.password' "$CONFIG_FILE")
    SERVER=$(jq -r '.server' "$CONFIG_FILE")
    MT5_PATH=$(jq -r '.mt5_path' "$CONFIG_FILE")
    STOP_EXISTING=$(jq -r '.stop_existing // true' "$CONFIG_FILE")
    AUTO_RESTART=$(jq -r '.auto_restart // true' "$CONFIG_FILE")
    CHECK_INTERVAL=$(jq -r '.monitoring.check_interval_seconds // 30' "$CONFIG_FILE")

    # Validierung
    if [ -z "$ACCOUNT" ] || [ "$ACCOUNT" = "null" ]; then
        log ERROR "Account fehlt in Konfiguration"
        exit 1
    fi

    if [ -z "$PASSWORD" ] || [ "$PASSWORD" = "null" ]; then
        log ERROR "Password fehlt in Konfiguration"
        exit 1
    fi

    if [ -z "$SERVER" ] || [ "$SERVER" = "null" ]; then
        log ERROR "Server fehlt in Konfiguration"
        exit 1
    fi

    log SUCCESS "Konfiguration geladen"
    log INFO "  Account: $ACCOUNT"
    log INFO "  Server:  $SERVER"
    log INFO "  MT5:     $MT5_PATH"
}

# Prüfe ob MT5 läuft
check_mt5_running() {
    if pgrep -f "terminal64.exe" > /dev/null; then
        return 0  # Läuft
    else
        return 1  # Läuft nicht
    fi
}

# Stoppe MT5
stop_mt5() {
    log INFO "Stoppe MT5-Prozess..."

    if check_mt5_running; then
        pkill -f "terminal64.exe" || true
        sleep 3

        # Force kill wenn noch läuft
        if check_mt5_running; then
            pkill -9 -f "terminal64.exe" || true
            sleep 1
        fi

        log SUCCESS "MT5-Prozess beendet"
    else
        log INFO "Kein MT5-Prozess gefunden"
    fi
}

# Xvfb starten (für headless Server)
start_xvfb() {
    if [ -z "$HEADLESS" ] || [ "$HEADLESS" != "false" ]; then
        log INFO "Prüfe Xvfb (Virtual Display)..."

        if ! command -v Xvfb &> /dev/null; then
            log WARNING "Xvfb nicht installiert - installiere: sudo apt-get install xvfb"
            return 1
        fi

        # Prüfe ob Xvfb bereits läuft
        if pgrep -f "Xvfb $DISPLAY" > /dev/null; then
            log INFO "Xvfb läuft bereits auf Display $DISPLAY"
        else
            log INFO "Starte Xvfb auf Display $DISPLAY..."
            Xvfb "$DISPLAY" -screen 0 1024x768x24 &
            sleep 2
            log SUCCESS "Xvfb gestartet"
        fi

        export DISPLAY
    fi
}

# Wine konfigurieren
setup_wine() {
    log INFO "Konfiguriere Wine..."

    # Wine-Prefix setzen
    export WINEPREFIX

    log INFO "Wine Prefix: $WINEPREFIX"

    # Prüfe ob Wine installiert ist
    if ! command -v wine &> /dev/null; then
        log ERROR "Wine ist nicht installiert!"
        log ERROR "Installieren Sie Wine: sudo apt-get install wine wine64"
        exit 1
    fi

    # Wine-Version anzeigen
    local wine_version=$(wine --version 2>/dev/null || echo "unknown")
    log INFO "Wine Version: $wine_version"

    # Prüfe ob MT5 installiert ist
    if [ ! -f "$WINEPREFIX/drive_c/Program Files/MetaTrader 5/terminal64.exe" ] && \
       [ ! -f "$WINEPREFIX/drive_c/Program Files (x86)/MetaTrader 5/terminal64.exe" ]; then
        log WARNING "MT5 nicht in Wine-Prefix gefunden"
        log WARNING "Installieren Sie MT5 zuerst: wine mt5setup.exe"
    fi

    log SUCCESS "Wine konfiguriert"
}

# MT5 starten
start_mt5() {
    log INFO "═══════════════════════════════════════════════════════════"
    log INFO "   Starte MetaTrader 5 in Wine..."
    log INFO "═══════════════════════════════════════════════════════════"

    # MT5-Pfad bestimmen
    local mt5_exe=""

    if [ -n "$MT5_PATH" ] && [ "$MT5_PATH" != "null" ]; then
        # Konvertiere Windows-Pfad zu Wine-Pfad
        mt5_exe="$MT5_PATH"
    else
        # Standard-Pfade durchsuchen
        if [ -f "$WINEPREFIX/drive_c/Program Files/MetaTrader 5/terminal64.exe" ]; then
            mt5_exe="C:\\Program Files\\MetaTrader 5\\terminal64.exe"
        elif [ -f "$WINEPREFIX/drive_c/Program Files (x86)/MetaTrader 5/terminal64.exe" ]; then
            mt5_exe="C:\\Program Files (x86)\\MetaTrader 5\\terminal64.exe"
        else
            log ERROR "MT5 Executable nicht gefunden!"
            return 1
        fi
    fi

    log INFO "MT5 Pfad: $mt5_exe"
    log INFO "Login: $ACCOUNT"
    log INFO "Server: $SERVER"
    log INFO "Password: ******** (versteckt)"

    # Wine-Kommando zusammenstellen
    # MT5 Login-Parameter: /login:XXX /server:"YYY" /password:"ZZZ"
    local wine_cmd="wine \"$mt5_exe\" /login:$ACCOUNT /server:\"$SERVER\" /password:\"$PASSWORD\""

    log INFO "Starte MT5 mit Wine..."

    # MT5 im Hintergrund starten
    cd "$WINEPREFIX/drive_c/Program Files/MetaTrader 5" 2>/dev/null || \
    cd "$WINEPREFIX/drive_c/Program Files (x86)/MetaTrader 5" 2>/dev/null || \
    cd "$WINEPREFIX/drive_c"

    # Starte MT5
    DISPLAY=$DISPLAY WINEPREFIX=$WINEPREFIX wine "terminal64.exe" \
        /login:"$ACCOUNT" \
        /server:"$SERVER" \
        /password:"$PASSWORD" \
        >> "$LOG_FILE" 2>&1 &

    local wine_pid=$!

    log INFO "Wine-Prozess gestartet (PID: $wine_pid)"

    # Warte kurz und prüfe ob Prozess läuft
    sleep 5

    if check_mt5_running; then
        log SUCCESS "MT5 erfolgreich gestartet!"
        log SUCCESS "MT5 sollte nun mit Account $ACCOUNT verbunden sein"
        return 0
    else
        log ERROR "MT5-Prozess wurde nicht gefunden nach Start"
        log ERROR "Prüfen Sie die Logs: $LOG_FILE"
        return 1
    fi
}

# Prozess-Monitoring
monitor_mt5() {
    log INFO "═══════════════════════════════════════════════════════════"
    log INFO "   Starte MT5-Prozessüberwachung..."
    log INFO "   Check-Intervall: ${CHECK_INTERVAL}s"
    log INFO "   Drücken Sie Strg+C zum Beenden"
    log INFO "═══════════════════════════════════════════════════════════"

    local restart_count=0

    while true; do
        sleep "$CHECK_INTERVAL"

        if ! check_mt5_running; then
            restart_count=$((restart_count + 1))
            log WARNING "MT5-Prozess nicht gefunden! (Neustart #$restart_count)"

            if [ "$AUTO_RESTART" = "true" ]; then
                log INFO "Warte 10 Sekunden vor Neustart..."
                sleep 10

                if start_mt5; then
                    log SUCCESS "MT5 erfolgreich neu gestartet"
                else
                    log ERROR "Neustart fehlgeschlagen - versuche erneut in ${CHECK_INTERVAL}s"
                fi
            else
                log ERROR "Auto-Restart deaktiviert - beende Monitoring"
                exit 1
            fi
        else
            # Prozess läuft - zeige Status
            local pid=$(pgrep -f "terminal64.exe" | head -1)
            local mem=$(ps -p "$pid" -o rss= 2>/dev/null | awk '{print int($1/1024)}' || echo "0")
            local cpu=$(ps -p "$pid" -o %cpu= 2>/dev/null | tr -d ' ' || echo "0")

            log INFO "MT5 Status: Läuft (PID: $pid, RAM: ${mem}MB, CPU: ${cpu}%)"
        fi
    done
}

# Cleanup-Handler
cleanup() {
    log INFO "Cleanup wird ausgeführt..."

    if [ "$STOP_ON_EXIT" = "true" ]; then
        stop_mt5
    fi

    log INFO "Script beendet"
}

# ============================================
# HAUPTPROGRAMM
# ============================================

main() {
    log INFO "═══════════════════════════════════════════════════════════"
    log INFO "   MT5 Auto-Start für Linux/Wine - SaaS Edition v1.0"
    log INFO "   Copyright 2024 Stelona"
    log INFO "═══════════════════════════════════════════════════════════"
    log INFO ""

    # Erstelle Log-Verzeichnis
    mkdir -p "$(dirname "$LOG_FILE")"

    # Konfiguration laden
    read_config

    # Xvfb starten (für headless Server)
    start_xvfb

    # Wine konfigurieren
    setup_wine

    # Prüfe ob MT5 bereits läuft
    if check_mt5_running; then
        log WARNING "MT5 läuft bereits!"

        if [ "$STOP_EXISTING" = "true" ]; then
            log INFO "Beende bestehenden MT5-Prozess (stop_existing=true)..."
            stop_mt5
            sleep 3
        else
            log INFO "Verwende bestehenden MT5-Prozess (stop_existing=false)"

            # Nur Monitoring starten
            if [ "$AUTO_RESTART" = "true" ]; then
                monitor_mt5
            fi
            return 0
        fi
    fi

    # MT5 starten
    if ! start_mt5; then
        log ERROR "Fehler beim Starten von MT5"
        exit 1
    fi

    # Prozessüberwachung starten (falls aktiviert)
    if [ "$AUTO_RESTART" = "true" ]; then
        log INFO ""
        monitor_mt5
    else
        log INFO "Prozessüberwachung deaktiviert (auto_restart=false)"
        log INFO "MT5 läuft nun im Hintergrund"
    fi
}

# Cleanup bei Exit registrieren
trap cleanup EXIT INT TERM

# Hauptprogramm ausführen
main "$@"
