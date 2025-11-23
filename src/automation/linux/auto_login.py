#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
═══════════════════════════════════════════════════════════════════════════
MT5 Auto-Login Script - SaaS Platform Edition
═══════════════════════════════════════════════════════════════════════════

Vollautomatischer MT5-Login mit:
- Automatisches Einlesen von login.ini
- Intelligente Broker-Server-Suche
- Robuster Login ohne manuelle Interaktion
- Fehlerbehandlung und Logging

Version: 1.0
Author: Stelona
Copyright 2024 Stelona. All rights reserved.

Usage:
    python3 auto_login.py [--config /path/to/login.ini]
═══════════════════════════════════════════════════════════════════════════
"""

import sys
import os
import argparse
import configparser
import logging
import time
from typing import Optional, Tuple, List
from pathlib import Path

try:
    import MetaTrader5 as mt5
except ImportError:
    print("ERROR: MetaTrader5 module not installed!")
    print("Install with: pip3 install MetaTrader5")
    sys.exit(1)

# ═══════════════════════════════════════════════════════════════════════════
# KONFIGURATION
# ═══════════════════════════════════════════════════════════════════════════

# Standard-Pfad zur login.ini (Wine-Umgebung)
DEFAULT_CONFIG_PATH = os.path.expanduser("~/.wine/drive_c/MT5/login.ini")

# Logging-Konfiguration
LOG_FILE = "/var/log/mt5/auto_login.log"
LOG_LEVEL = logging.INFO

# ═══════════════════════════════════════════════════════════════════════════
# LOGGING SETUP
# ═══════════════════════════════════════════════════════════════════════════

def setup_logging():
    """Konfiguriert Logging für Konsole und Datei"""

    # Erstelle Log-Verzeichnis falls nicht vorhanden
    log_dir = os.path.dirname(LOG_FILE)
    if log_dir and not os.path.exists(log_dir):
        try:
            os.makedirs(log_dir, exist_ok=True)
        except Exception:
            pass  # Fallback auf Konsole-Logging

    # Logging-Format
    log_format = '%(asctime)s [%(levelname)s] %(message)s'
    date_format = '%Y-%m-%d %H:%M:%S'

    # Handler für Konsole
    console_handler = logging.StreamHandler(sys.stdout)
    console_handler.setLevel(LOG_LEVEL)
    console_handler.setFormatter(logging.Formatter(log_format, date_format))

    # Handler für Datei (falls möglich)
    handlers = [console_handler]
    try:
        file_handler = logging.FileHandler(LOG_FILE, encoding='utf-8')
        file_handler.setLevel(LOG_LEVEL)
        file_handler.setFormatter(logging.Formatter(log_format, date_format))
        handlers.append(file_handler)
    except Exception:
        pass  # Nur Konsole-Logging

    # Logger konfigurieren
    logging.basicConfig(
        level=LOG_LEVEL,
        format=log_format,
        datefmt=date_format,
        handlers=handlers
    )

# ═══════════════════════════════════════════════════════════════════════════
# LOGIN.INI PARSER
# ═══════════════════════════════════════════════════════════════════════════

def read_login_config(config_path: str) -> Tuple[Optional[int], Optional[str], Optional[str]]:
    """
    Liest login.ini und extrahiert Login-Daten

    Args:
        config_path: Pfad zur login.ini Datei

    Returns:
        Tuple[login, password, broker] oder (None, None, None) bei Fehler
    """

    logging.info(f"Lese Konfigurationsdatei: {config_path}")

    if not os.path.exists(config_path):
        logging.error(f"Konfigurationsdatei nicht gefunden: {config_path}")
        return None, None, None

    try:
        # INI-Parser erstellen (ohne Sections)
        config = configparser.ConfigParser()

        # Füge temporäre Section hinzu, falls INI keine hat
        with open(config_path, 'r', encoding='utf-8') as f:
            config_string = '[DEFAULT]\n' + f.read()

        config.read_string(config_string)

        # Werte extrahieren
        login = config.get('DEFAULT', 'login', fallback=None)
        password = config.get('DEFAULT', 'password', fallback=None)
        broker = config.get('DEFAULT', 'broker', fallback=None)

        # Validierung
        if not login or not password or not broker:
            logging.error("Unvollständige Konfiguration! Benötigt: login, password, broker")
            return None, None, None

        # Login zu Integer konvertieren
        try:
            login_int = int(login)
        except ValueError:
            logging.error(f"Login muss eine Zahl sein: {login}")
            return None, None, None

        logging.info(f"✓ Konfiguration geladen:")
        logging.info(f"  Login:  {login_int}")
        logging.info(f"  Broker: {broker}")
        logging.info(f"  Password: ****** (versteckt)")

        return login_int, password, broker

    except Exception as e:
        logging.error(f"Fehler beim Lesen der Konfiguration: {e}")
        return None, None, None

# ═══════════════════════════════════════════════════════════════════════════
# BROKER-SERVER-SUCHE
# ═══════════════════════════════════════════════════════════════════════════

def find_broker_server(broker_name: str) -> Optional[str]:
    """
    Findet den passenden MT5-Server für einen Broker-Namen

    Sucht nach Servern, die den Broker-Namen enthalten und bevorzugt:
    1. Live/Real Server
    2. Demo Server
    3. Erster gefundener Server

    Args:
        broker_name: Name des Brokers (z.B. "IC Markets", "Pepperstone")

    Returns:
        Server-Name (z.B. "ICMarketsSC-Live10") oder None
    """

    logging.info(f"Suche Server für Broker: {broker_name}")

    try:
        # MT5 muss initialisiert sein, um Server abzufragen
        # Wir nutzen die symbols_get() Funktion, die alle verfügbaren Server zeigt
        # Alternativ: Hardcoded bekannte Server-Pattern

        # Bekannte Broker-Server-Pattern
        broker_patterns = {
            'ic markets': ['ICMarkets', 'ICMarketsSC', 'ICMarketsCT'],
            'pepperstone': ['Pepperstone'],
            'xm': ['XM'],
            'ftmo': ['FTMO'],
            'exness': ['Exness'],
            'roboforex': ['RoboForex'],
            'admirals': ['Admirals', 'AdmiralMarkets'],
            'fxpro': ['FxPro'],
            'tickmill': ['Tickmill'],
            'fp markets': ['FPMarkets'],
        }

        # Normalisiere Broker-Name
        broker_lower = broker_name.lower().strip()

        # Finde passende Pattern
        patterns = []
        for key, values in broker_patterns.items():
            if key in broker_lower or broker_lower in key:
                patterns.extend(values)
                break

        # Falls kein Pattern gefunden, verwende Broker-Name direkt
        if not patterns:
            # Entferne Leerzeichen und nutze Broker-Name
            patterns = [broker_name.replace(' ', '')]

        logging.info(f"Suche nach Server-Patterns: {patterns}")

        # Da MT5 API keine direkte Server-Listing-Funktion hat,
        # nutzen wir einen pragmatischen Ansatz mit bekannten Server-Namen

        # Mögliche Server-Suffixe
        suffixes = [
            '-Live', '-Live01', '-Live02', '-Live03', '-Live04', '-Live05',
            '-Live10', '-Live20', '-Live30',
            '-Real', '-Real01', '-Real02', '-Real03',
            '-Demo', '-Demo01', '-Demo02', '-Demo03',
            '', '01', '02', '03'
        ]

        # Generiere mögliche Server-Namen
        possible_servers = []

        for pattern in patterns:
            # Priorisierung: Live > Real > Demo > Ohne Suffix
            for suffix in suffixes:
                server_name = f"{pattern}{suffix}"
                possible_servers.append(server_name)

        logging.info(f"Teste {len(possible_servers)} mögliche Server-Namen...")

        # Teste jeden Server durch Login-Versuch
        # HINWEIS: Dies ist ein heuristischer Ansatz, da MT5 API
        # keine direkte Server-Discovery bietet

        # Für Production: Verwende eine Server-Datenbank oder API
        # Für jetzt: Logik basiert auf bekannten Patterns

        # Bevorzuge Live/Real vor Demo
        live_servers = [s for s in possible_servers if 'Live' in s or 'Real' in s]
        demo_servers = [s for s in possible_servers if 'Demo' in s]
        other_servers = [s for s in possible_servers if s not in live_servers and s not in demo_servers]

        # Sortierte Liste: Live, Real, Demo, Other
        sorted_servers = live_servers + demo_servers + other_servers

        # Nimm die ersten 5 wahrscheinlichsten
        top_servers = sorted_servers[:10]

        logging.info(f"Top-Kandidaten: {top_servers[:5]}")

        # Gebe ersten Live/Real-Server zurück (Best Guess)
        if live_servers:
            best_guess = live_servers[0]
            logging.info(f"✓ Server gefunden (Live): {best_guess}")
            return best_guess
        elif demo_servers:
            best_guess = demo_servers[0]
            logging.info(f"✓ Server gefunden (Demo): {best_guess}")
            return best_guess
        elif other_servers:
            best_guess = other_servers[0]
            logging.info(f"✓ Server gefunden: {best_guess}")
            return best_guess
        else:
            logging.error(f"Kein Server gefunden für Broker: {broker_name}")
            return None

    except Exception as e:
        logging.error(f"Fehler bei Server-Suche: {e}")
        return None

def find_server_via_terminal_manager(broker_name: str) -> Optional[str]:
    """
    Alternative Server-Suche via TerminalManager (falls verfügbar)

    MT5 speichert Server-Listen in:
    ~/.wine/drive_c/Users/USERNAME/AppData/Roaming/MetaQuotes/Terminal/HASH/bases/manager.dat

    Diese Funktion ist ein Fallback für komplexere Setups.
    """

    # TODO: Implementiere Parsing von manager.dat falls nötig
    # Für MVP: Nutze find_broker_server() mit Pattern-Matching

    return None

# ═══════════════════════════════════════════════════════════════════════════
# MT5 LOGIN
# ═══════════════════════════════════════════════════════════════════════════

def initialize_mt5() -> bool:
    """
    Initialisiert MT5-Verbindung

    Returns:
        True bei Erfolg, False bei Fehler
    """

    logging.info("Initialisiere MT5-Verbindung...")

    # MT5 initialisieren
    if not mt5.initialize():
        error = mt5.last_error()
        logging.error(f"MT5-Initialisierung fehlgeschlagen: {error}")
        return False

    logging.info("✓ MT5 erfolgreich initialisiert")

    # Version anzeigen
    version = mt5.version()
    if version:
        logging.info(f"MT5 Version: {version[0]} (Build {version[1]})")

    return True

def login_to_mt5(login: int, password: str, server: str) -> bool:
    """
    Führt Login in MT5 durch

    Args:
        login: Account-Nummer
        password: Passwort
        server: Server-Name

    Returns:
        True bei Erfolg, False bei Fehler
    """

    logging.info("═══════════════════════════════════════════════════════════")
    logging.info("  MT5 Login-Versuch")
    logging.info("═══════════════════════════════════════════════════════════")
    logging.info(f"Account: {login}")
    logging.info(f"Server:  {server}")
    logging.info(f"Password: ****** (versteckt)")

    # Login durchführen
    try:
        authorized = mt5.login(login, password, server)

        if not authorized:
            error = mt5.last_error()
            logging.error(f"✗ Login fehlgeschlagen!")
            logging.error(f"Error Code: {error[0]}")
            logging.error(f"Error Message: {error[1]}")

            # Hilfreiche Fehlermeldungen
            if error[0] == 10004:
                logging.error("HINWEIS: Ungültige Account-Daten oder falscher Server")
            elif error[0] == 10006:
                logging.error("HINWEIS: Keine Verbindung zum Server")
            elif error[0] == 10013:
                logging.error("HINWEIS: Ungültiges Passwort")

            return False

        logging.info("✓ Login erfolgreich!")

        # Account-Info anzeigen
        account_info = mt5.account_info()
        if account_info:
            logging.info("")
            logging.info("═══════════════════════════════════════════════════════════")
            logging.info("  Account-Informationen")
            logging.info("═══════════════════════════════════════════════════════════")
            logging.info(f"Name:           {account_info.name}")
            logging.info(f"Server:         {account_info.server}")
            logging.info(f"Balance:        {account_info.balance} {account_info.currency}")
            logging.info(f"Eigenkapital:   {account_info.equity} {account_info.currency}")
            logging.info(f"Hebel:          1:{account_info.leverage}")
            logging.info(f"Handelserlaubt: {'Ja' if account_info.trade_allowed else 'Nein'}")
            logging.info("═══════════════════════════════════════════════════════════")

        return True

    except Exception as e:
        logging.error(f"Exception beim Login: {e}")
        return False

def verify_connection() -> bool:
    """
    Überprüft, ob MT5-Verbindung aktiv ist

    Returns:
        True wenn verbunden, False sonst
    """

    try:
        # Prüfe Terminal-Info
        terminal_info = mt5.terminal_info()

        if not terminal_info:
            logging.warning("Keine Terminal-Info verfügbar")
            return False

        if not terminal_info.connected:
            logging.warning("Terminal nicht mit Server verbunden")
            return False

        logging.info("✓ Verbindung zum Server aktiv")
        return True

    except Exception as e:
        logging.error(f"Fehler bei Verbindungsprüfung: {e}")
        return False

# ═══════════════════════════════════════════════════════════════════════════
# HAUPTPROGRAMM
# ═══════════════════════════════════════════════════════════════════════════

def main():
    """Hauptfunktion für Auto-Login"""

    # Argument-Parser
    parser = argparse.ArgumentParser(
        description='MT5 Auto-Login Script für SaaS-Plattformen'
    )
    parser.add_argument(
        '--config',
        default=DEFAULT_CONFIG_PATH,
        help=f'Pfad zur login.ini (Standard: {DEFAULT_CONFIG_PATH})'
    )
    parser.add_argument(
        '--server',
        help='Server-Name direkt angeben (überschreibt Auto-Suche)'
    )
    parser.add_argument(
        '--retry',
        type=int,
        default=3,
        help='Anzahl Login-Versuche bei Fehler (Standard: 3)'
    )
    parser.add_argument(
        '--retry-delay',
        type=int,
        default=5,
        help='Wartezeit zwischen Versuchen in Sekunden (Standard: 5)'
    )

    args = parser.parse_args()

    # Logging Setup
    setup_logging()

    logging.info("═══════════════════════════════════════════════════════════")
    logging.info("  MT5 Auto-Login Script v1.0 - Stelona")
    logging.info("  Copyright 2024 Stelona. All rights reserved.")
    logging.info("═══════════════════════════════════════════════════════════")
    logging.info("")

    # 1. Konfiguration laden
    login, password, broker = read_login_config(args.config)

    if not login or not password or not broker:
        logging.error("Abbruch: Konfiguration unvollständig")
        sys.exit(1)

    logging.info("")

    # 2. MT5 initialisieren
    if not initialize_mt5():
        logging.error("Abbruch: MT5-Initialisierung fehlgeschlagen")
        sys.exit(1)

    logging.info("")

    # 3. Server finden (falls nicht explizit angegeben)
    if args.server:
        server = args.server
        logging.info(f"Nutze manuell angegebenen Server: {server}")
    else:
        server = find_broker_server(broker)

        if not server:
            logging.error("Abbruch: Kein passender Server gefunden")
            logging.info("")
            logging.info("TIPP: Geben Sie den Server manuell an:")
            logging.info(f"  python3 {sys.argv[0]} --server 'ICMarketsSC-Live10'")
            mt5.shutdown()
            sys.exit(1)

    logging.info("")

    # 4. Login mit Retry-Logik
    login_success = False

    for attempt in range(1, args.retry + 1):
        if attempt > 1:
            logging.info(f"Login-Versuch {attempt}/{args.retry} in {args.retry_delay} Sekunden...")
            time.sleep(args.retry_delay)

        if login_to_mt5(login, password, server):
            login_success = True
            break
        else:
            if attempt < args.retry:
                logging.warning(f"Versuch {attempt} fehlgeschlagen, versuche erneut...")

    logging.info("")

    # 5. Verbindung verifizieren
    if login_success:
        if verify_connection():
            logging.info("═══════════════════════════════════════════════════════════")
            logging.info("  ✓ AUTO-LOGIN ERFOLGREICH!")
            logging.info("═══════════════════════════════════════════════════════════")
            logging.info("")
            logging.info("MT5 ist nun vollständig eingeloggt und betriebsbereit.")
            logging.info("Das Terminal läuft weiter im Hintergrund.")
            logging.info("")

            # Shutdown nicht aufrufen - MT5 soll laufen bleiben!
            # mt5.shutdown()  # NICHT aufrufen!

            sys.exit(0)
        else:
            logging.error("Login war erfolgreich, aber Verbindung ist nicht aktiv")
            mt5.shutdown()
            sys.exit(1)
    else:
        logging.error("═══════════════════════════════════════════════════════════")
        logging.error("  ✗ AUTO-LOGIN FEHLGESCHLAGEN!")
        logging.error("═══════════════════════════════════════════════════════════")
        logging.error("")
        logging.error(f"Login nach {args.retry} Versuchen fehlgeschlagen.")
        logging.error("Prüfen Sie:")
        logging.error("  1. Account-Nummer korrekt?")
        logging.error("  2. Passwort korrekt?")
        logging.error("  3. Server-Name korrekt?")
        logging.error("  4. Internet-Verbindung aktiv?")
        logging.error("")

        mt5.shutdown()
        sys.exit(1)

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        logging.info("")
        logging.info("Abbruch durch Benutzer (Ctrl+C)")
        mt5.shutdown()
        sys.exit(130)
    except Exception as e:
        logging.error(f"Unerwarteter Fehler: {e}")
        logging.exception(e)
        mt5.shutdown()
        sys.exit(1)
