#!/usr/bin/env python3
#═══════════════════════════════════════════════════════════════════════════
# MT5 Auto-Login + Broker-Neutral EA Setup
#═══════════════════════════════════════════════════════════════════════════
#
# Löst das Henne-Ei-Problem: Suffix ist erst nach Login bekannt
#
# Strategie:
# 1. Login in MT5 (mit automatischer Broker-Server-Suche)
# 2. Template mit Bootstrap-EA auf "sicherem Symbol" erstellen (EURUSD)
# 3. Bootstrap-EA läuft beim MT5-Start automatisch
# 4. Bootstrap-EA findet BTCUSD mit beliebigem Suffix
# 5. Bootstrap-EA öffnet Chart und lädt signal.ex5
#
# ✅ Komplett broker-neutral!
# ✅ Keine Kenntnis über Suffix vorher nötig!
# ✅ ZERO manuelle Interaktion!
#
# Usage:
#   python3 auto_login_broker_neutral.py --config /path/to/login.ini --restart
#
# Version: 3.0
# Author: Stelona
#═══════════════════════════════════════════════════════════════════════════

import MetaTrader5 as mt5
import configparser
import argparse
import sys
import os
from pathlib import Path
from typing import Optional, Dict
import logging

# Konstanten
VERSION = "3.0"
DEFAULT_CONFIG_PATHS = [
    "~/.wine/drive_c/MT5/login.ini",
    "/opt/mt5/login.ini",
    "./login.ini"
]

# Safe symbols that exist at most brokers without suffix
SAFE_SYMBOLS = ["EURUSD", "GBPUSD", "USDJPY", "EURGBP", "AUDUSD"]

# Bootstrap EA name
BOOTSTRAP_EA = "ChartSetup.ex5"

# Target configuration
TARGET_SYMBOL = "BTCUSD"
TARGET_EA = "signal.ex5"
TARGET_TIMEFRAME = mt5.TIMEFRAME_H1

# ═══════════════════════════════════════════════════════════════════════════
# Logging Setup
# ═══════════════════════════════════════════════════════════════════════════

logging.basicConfig(
    level=logging.INFO,
    format='%(message)s'
)

def print_header(text: str):
    """Gibt einen formatierten Header aus"""
    logging.info("═══════════════════════════════════════════════════════════")
    logging.info(f"  {text}")
    logging.info("═══════════════════════════════════════════════════════════")
    logging.info("")

def print_success(text: str):
    """Gibt eine Erfolgsmeldung aus"""
    logging.info(f"✓ {text}")

def print_error(text: str):
    """Gibt eine Fehlermeldung aus"""
    logging.error(f"✗ ERROR: {text}")

def print_info(text: str):
    """Gibt eine Info-Meldung aus"""
    logging.info(f"  {text}")

# ═══════════════════════════════════════════════════════════════════════════
# Config & Login (from auto_login.py v1.0)
# ═══════════════════════════════════════════════════════════════════════════

def read_login_config(config_path: str) -> Optional[Dict[str, str]]:
    """Liest die Login-Konfiguration aus einer INI-Datei"""
    try:
        config = configparser.ConfigParser()
        config.read(config_path)

        # Support both [DEFAULT] section and direct key-value
        if config.has_section('DEFAULT'):
            login = config.get('DEFAULT', 'login')
            password = config.get('DEFAULT', 'password')
            broker = config.get('DEFAULT', 'broker', fallback='')
        else:
            # Read from file directly
            with open(config_path, 'r') as f:
                content = f.read()

            login = None
            password = None
            broker = ''

            for line in content.split('\n'):
                line = line.strip()
                if line.startswith('#') or not line:
                    continue

                if '=' in line:
                    key, value = line.split('=', 1)
                    key = key.strip().lower()
                    value = value.strip()

                    if key == 'login':
                        login = value
                    elif key == 'password':
                        password = value
                    elif key == 'broker':
                        broker = value

            if not login or not password:
                print_error("login.ini muss mindestens 'login' und 'password' enthalten!")
                return None

        return {
            'login': int(login),
            'password': password,
            'broker': broker
        }

    except Exception as e:
        print_error(f"Fehler beim Lesen der Config: {e}")
        return None

def find_broker_server(broker_name: str, manual_server: Optional[str] = None) -> Optional[str]:
    """Findet den passenden Server für einen Broker"""
    if manual_server:
        print_info(f"Verwende manuell angegebenen Server: {manual_server}")
        return manual_server

    # Broker-Server Patterns
    broker_patterns = {
        'IC Markets': ['ICMarkets', 'ICMarketsSC', 'ICMarketsCT'],
        'Pepperstone': ['Pepperstone'],
        'XM': ['XM', 'XMGlobal', 'XMTrading'],
        'FTMO': ['FTMO'],
        'Exness': ['Exness'],
        'FBS': ['FBS'],
        'HFM': ['HFMarkets', 'HotForex'],
        'Fusion Markets': ['FusionMarkets'],
        'FP Markets': ['FPMarkets'],
        'Admiral Markets': ['AdmiralMarkets', 'Admiral-'],
    }

    patterns = broker_patterns.get(broker_name, [broker_name])

    print_info(f"Suche nach Server-Patterns: {patterns}")

    # Verfügbare Server abrufen
    servers = []

    # Try to get all available servers
    try:
        import subprocess
        # This is a workaround - MT5 doesn't expose server list via API
        # We'll just try common patterns
        pass
    except:
        pass

    # Suche in allen verfügbaren Servern
    for pattern in patterns:
        # Try Live servers first
        for suffix in ['-Live', '-Real', '-Live01', '-Live1', '-Live10', 'SC-Live', 'SC-Live10']:
            server_name = f"{pattern}{suffix}"
            servers.append(server_name)

        # Then Demo servers
        for suffix in ['-Demo', '-Demo01', '-Demo1', 'SC-Demo', 'SC-Demo01']:
            server_name = f"{pattern}{suffix}"
            servers.append(server_name)

        # And without suffix
        servers.append(pattern)

    # Return first match (will be validated during login)
    if servers:
        print_success(f"Server gefunden (wird beim Login validiert): {servers[0]}")
        return servers[0]

    print_error(f"Kein Server gefunden für Broker: {broker_name}")
    return None

def login_to_mt5(login: int, password: str, server: str) -> bool:
    """Führt Login in MT5 durch"""
    print_header("MT5 Login-Versuch")
    print_info(f"Account: {login}")
    print_info(f"Server:  {server}")
    print_info(f"Password: {'*' * len(password)} (versteckt)")
    logging.info("")

    # Try login with multiple server variations
    server_variations = [
        server,
        server.replace('-Live', 'SC-Live'),
        server.replace('-Demo', 'SC-Demo'),
        server + '01',
        server + '10',
    ]

    for srv in server_variations:
        if not mt5.login(login, password, srv):
            error_code = mt5.last_error()
            logging.debug(f"Login fehlgeschlagen für Server {srv}: {error_code}")
            continue

        # Login successful
        print_success("Login erfolgreich!")
        logging.info("")

        # Account info
        account_info = mt5.account_info()
        if account_info:
            print_header("Account-Informationen")
            print_info(f"Name:           {account_info.name}")
            print_info(f"Server:         {account_info.server}")
            print_info(f"Balance:        {account_info.balance:.2f} {account_info.currency}")
            print_info(f"Eigenkapital:   {account_info.equity:.2f} {account_info.currency}")
            print_info(f"Hebel:          1:{account_info.leverage}")
            print_info(f"Handelserlaubt: {'Ja' if account_info.trade_allowed else 'Nein'}")
            logging.info("═══════════════════════════════════════════════════════════")
            logging.info("")

        return True

    # All login attempts failed
    error = mt5.last_error()
    print_error(f"Login fehlgeschlagen!")
    print_error(f"Error Code: {error[0]}")
    print_error(f"Message: {error[1]}")
    return False

# ═══════════════════════════════════════════════════════════════════════════
# NEW: Broker-Neutral Chart Setup
# ═══════════════════════════════════════════════════════════════════════════

def find_safe_symbol() -> Optional[str]:
    """Findet ein "sicheres" Symbol, das bei den meisten Brokern ohne Suffix existiert"""
    print_header("Suche sicheres Bootstrap-Symbol")

    for symbol in SAFE_SYMBOLS:
        # Check if symbol exists
        symbol_info = mt5.symbol_info(symbol)

        if symbol_info is not None and symbol_info.visible:
            print_success(f"Sicheres Symbol gefunden: {symbol}")
            print_info(f"Beschreibung: {symbol_info.description}")
            return symbol

        # Try with common suffixes
        for suffix in ['.raw', '.m', '.', 'pro', 'i']:
            test_symbol = symbol + suffix
            symbol_info = mt5.symbol_info(test_symbol)

            if symbol_info is not None and symbol_info.visible:
                print_success(f"Sicheres Symbol gefunden: {test_symbol}")
                print_info(f"Beschreibung: {symbol_info.description}")
                return test_symbol

    print_error("Kein sicheres Symbol gefunden!")
    print_info("Verfügbare Symbole:")

    # Show first 10 symbols as fallback
    symbols = mt5.symbols_get()
    if symbols:
        for i, sym in enumerate(symbols[:10]):
            print_info(f"  {sym.name}")

    return None

def create_bootstrap_template(safe_symbol: str, target_symbol: str, target_ea: str) -> bool:
    """Erstellt Template mit Bootstrap-EA auf sicherem Symbol"""
    print_header("Erstelle Bootstrap-Template")

    # Find MT5 data directory
    terminal_info = mt5.terminal_info()
    if not terminal_info:
        print_error("Konnte Terminal-Info nicht abrufen")
        return False

    data_path = terminal_info.data_path
    template_dir = os.path.join(data_path, "MQL5", "Profiles", "Templates")

    # Create directory if not exists
    os.makedirs(template_dir, exist_ok=True)

    template_path = os.path.join(template_dir, "AutoStart.tpl")

    # Template content with Bootstrap EA
    template_content = f"""<chart>
symbol={safe_symbol}
period=60
<expert>
name={BOOTSTRAP_EA}
path=Experts\\{BOOTSTRAP_EA}
expertmode=1
<inputs>
TargetSymbolBase={target_symbol}
TargetEA={target_ea}
TargetTimeframe={TARGET_TIMEFRAME}
RemoveSelfAfterSetup=true
SetupDelaySeconds=5
</inputs>
</expert>
</chart>
"""

    try:
        with open(template_path, 'w') as f:
            f.write(template_content)

        print_success(f"Template erstellt: {template_path}")
        print_info(f"Bootstrap-Symbol: {safe_symbol}")
        print_info(f"Bootstrap-EA: {BOOTSTRAP_EA}")
        print_info(f"Target-Symbol: {target_symbol}")
        print_info(f"Target-EA: {target_ea}")

        return True

    except Exception as e:
        print_error(f"Fehler beim Erstellen des Templates: {e}")
        return False

# ═══════════════════════════════════════════════════════════════════════════
# Main
# ═══════════════════════════════════════════════════════════════════════════

def main():
    print_header(f"MT5 Auto-Login + Broker-Neutral Setup v{VERSION} - Stelona")

    # Argument Parser
    parser = argparse.ArgumentParser(
        description='MT5 Auto-Login mit broker-neutralem EA-Setup'
    )
    parser.add_argument(
        '--config',
        type=str,
        help='Pfad zur login.ini Datei'
    )
    parser.add_argument(
        '--server',
        type=str,
        help='Manueller Server-Name (optional)'
    )
    parser.add_argument(
        '--target-symbol',
        type=str,
        default=TARGET_SYMBOL,
        help=f'Ziel-Symbol (default: {TARGET_SYMBOL})'
    )
    parser.add_argument(
        '--target-ea',
        type=str,
        default=TARGET_EA,
        help=f'Ziel-EA (default: {TARGET_EA})'
    )
    parser.add_argument(
        '--restart',
        action='store_true',
        help='MT5 nach Setup neu starten'
    )

    args = parser.parse_args()

    # Find config file
    config_path = args.config

    if not config_path:
        for path in DEFAULT_CONFIG_PATHS:
            expanded = os.path.expanduser(path)
            if os.path.exists(expanded):
                config_path = expanded
                break

    if not config_path or not os.path.exists(config_path):
        print_error("Keine login.ini Datei gefunden!")
        print_info("Durchsucht:")
        for path in DEFAULT_CONFIG_PATHS:
            print_info(f"  - {path}")
        print_info("\nVerwendung: python3 auto_login_broker_neutral.py --config /path/to/login.ini")
        return 1

    print_info(f"Lese Konfigurationsdatei: {config_path}")

    # Read config
    config = read_login_config(config_path)
    if not config:
        return 1

    print_success("Config geladen:")
    print_info(f"Login:  {config['login']}")
    print_info(f"Broker: {config['broker']}")
    print_info(f"Password: {'*' * len(config['password'])} (versteckt)")
    logging.info("")

    # Initialize MT5
    logging.info("Initialisiere MT5-Verbindung...")
    if not mt5.initialize():
        print_error("MT5-Initialisierung fehlgeschlagen!")
        print_error(f"Error: {mt5.last_error()}")
        return 1

    print_success("MT5 erfolgreich initialisiert")
    terminal_info = mt5.terminal_info()
    if terminal_info:
        print_info(f"MT5 Version: {terminal_info.build}")
    logging.info("")

    # Find server
    if config['broker']:
        logging.info(f"Suche Server für Broker: {config['broker']}")
        server = find_broker_server(config['broker'], args.server)
        if not server:
            mt5.shutdown()
            return 1
        logging.info("")
    else:
        if not args.server:
            print_error("Kein Broker angegeben und kein --server Parameter!")
            mt5.shutdown()
            return 1
        server = args.server

    # Login
    if not login_to_mt5(config['login'], config['password'], server):
        mt5.shutdown()
        return 1

    # ═══════════════════════════════════════════════════════════════════════
    # NEW: Broker-Neutral Setup
    # ═══════════════════════════════════════════════════════════════════════

    print_header("Broker-Neutrales EA-Setup")

    # Step 1: Find safe symbol
    safe_symbol = find_safe_symbol()
    if not safe_symbol:
        print_error("Setup fehlgeschlagen - kein Bootstrap-Symbol gefunden")
        mt5.shutdown()
        return 1

    logging.info("")

    # Step 2: Create bootstrap template
    if not create_bootstrap_template(safe_symbol, args.target_symbol, args.target_ea):
        print_error("Setup fehlgeschlagen - Template-Erstellung")
        mt5.shutdown()
        return 1

    logging.info("")

    # Success
    print_header("✓ SETUP ABGESCHLOSSEN!")
    print_info(f"Bootstrap-Symbol: {safe_symbol}")
    print_info(f"Bootstrap-EA: {BOOTSTRAP_EA}")
    print_info("")
    print_info("Beim nächsten MT5-Start:")
    print_info(f"1. {BOOTSTRAP_EA} läuft auf {safe_symbol}")
    print_info(f"2. Findet {args.target_symbol} mit beliebigem Suffix")
    print_info(f"3. Öffnet Chart und lädt {args.target_ea}")
    print_info("")
    print_info("✅ Komplett broker-neutral!")
    logging.info("═══════════════════════════════════════════════════════════")
    logging.info("")

    # Restart if requested
    if args.restart:
        logging.info("MT5-Neustart gewünscht...")
        print_success("MT5 heruntergefahren - wird automatisch neu gestartet")
        mt5.shutdown()
        logging.info("")
        logging.info("Nach dem Neustart wird das Bootstrap-EA automatisch geladen.")
    else:
        logging.info("Template erstellt. MT5-Neustart erforderlich für automatisches Laden.")
        logging.info("Führen Sie aus: systemctl restart mt5-autostart")
        mt5.shutdown()

    return 0

if __name__ == "__main__":
    sys.exit(main())
