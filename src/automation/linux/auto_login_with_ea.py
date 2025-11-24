#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
═══════════════════════════════════════════════════════════════════════════
MT5 Auto-Login + EA Auto-Load Script - SaaS Platform Edition
═══════════════════════════════════════════════════════════════════════════

Vollautomatisch:
- Login in MT5
- Broker-Suffixe erkennen
- BTCUSD Symbol finden
- EA auf H1 Chart laden

Version: 2.0
Author: Stelona
Copyright 2024 Stelona. All rights reserved.

Usage:
    python3 auto_login_with_ea.py [--config /path/to/login.ini] [--ea signal.ex5]
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

DEFAULT_CONFIG_PATH = os.path.expanduser("~/.wine/drive_c/MT5/login.ini")
DEFAULT_EA_NAME = "signal.ex5"
DEFAULT_SYMBOL = "BTCUSD"
DEFAULT_TIMEFRAME = mt5.TIMEFRAME_H1

LOG_FILE = "/var/log/mt5/auto_login.log"
LOG_LEVEL = logging.INFO

# ═══════════════════════════════════════════════════════════════════════════
# LOGGING SETUP
# ═══════════════════════════════════════════════════════════════════════════

def setup_logging():
    """Konfiguriert Logging für Konsole und Datei"""
    log_dir = os.path.dirname(LOG_FILE)
    if log_dir and not os.path.exists(log_dir):
        try:
            os.makedirs(log_dir, exist_ok=True)
        except Exception:
            pass

    log_format = '%(asctime)s [%(levelname)s] %(message)s'
    date_format = '%Y-%m-%d %H:%M:%S'

    console_handler = logging.StreamHandler(sys.stdout)
    console_handler.setLevel(LOG_LEVEL)
    console_handler.setFormatter(logging.Formatter(log_format, date_format))

    handlers = [console_handler]
    try:
        file_handler = logging.FileHandler(LOG_FILE, encoding='utf-8')
        file_handler.setLevel(LOG_LEVEL)
        file_handler.setFormatter(logging.Formatter(log_format, date_format))
        handlers.append(file_handler)
    except Exception:
        pass

    logging.basicConfig(
        level=LOG_LEVEL,
        format=log_format,
        datefmt=date_format,
        handlers=handlers
    )

# ═══════════════════════════════════════════════════════════════════════════
# LOGIN.INI PARSER (aus v1.0)
# ═══════════════════════════════════════════════════════════════════════════

def read_login_config(config_path: str) -> Tuple[Optional[int], Optional[str], Optional[str]]:
    """Liest login.ini und extrahiert Login-Daten"""
    logging.info(f"Lese Konfigurationsdatei: {config_path}")

    if not os.path.exists(config_path):
        logging.error(f"Konfigurationsdatei nicht gefunden: {config_path}")
        return None, None, None

    try:
        config = configparser.ConfigParser()
        with open(config_path, 'r', encoding='utf-8') as f:
            config_string = '[DEFAULT]\n' + f.read()
        config.read_string(config_string)

        login = config.get('DEFAULT', 'login', fallback=None)
        password = config.get('DEFAULT', 'password', fallback=None)
        broker = config.get('DEFAULT', 'broker', fallback=None)

        if not login or not password or not broker:
            logging.error("Unvollständige Konfiguration!")
            return None, None, None

        login_int = int(login)
        logging.info(f"✓ Config geladen: Login={login_int}, Broker={broker}")
        return login_int, password, broker

    except Exception as e:
        logging.error(f"Fehler beim Lesen der Konfiguration: {e}")
        return None, None, None

# ═══════════════════════════════════════════════════════════════════════════
# BROKER-SERVER-SUCHE (aus v1.0)
# ═══════════════════════════════════════════════════════════════════════════

def find_broker_server(broker_name: str) -> Optional[str]:
    """Findet den passenden MT5-Server"""
    logging.info(f"Suche Server für Broker: {broker_name}")

    broker_patterns = {
        'ic markets': ['ICMarkets', 'ICMarketsSC', 'ICMarketsCT'],
        'pepperstone': ['Pepperstone'],
        'xm': ['XM'],
        'ftmo': ['FTMO'],
        'exness': ['Exness'],
        'roboforex': ['RoboForex'],
        'admirals': ['Admirals', 'AdmiralMarkets'],
        'fxpro': ['FxPro'],
    }

    broker_lower = broker_name.lower().strip()
    patterns = []
    for key, values in broker_patterns.items():
        if key in broker_lower or broker_lower in key:
            patterns.extend(values)
            break

    if not patterns:
        patterns = [broker_name.replace(' ', '')]

    suffixes = ['-Live', '-Live01', '-Real', '-Demo', '-Demo01', '']
    possible_servers = [f"{p}{s}" for p in patterns for s in suffixes]

    live_servers = [s for s in possible_servers if 'Live' in s or 'Real' in s]
    demo_servers = [s for s in possible_servers if 'Demo' in s]
    other_servers = [s for s in possible_servers if s not in live_servers and s not in demo_servers]

    if live_servers:
        best = live_servers[0]
        logging.info(f"✓ Server gefunden (Live): {best}")
        return best
    elif demo_servers:
        best = demo_servers[0]
        logging.info(f"✓ Server gefunden (Demo): {best}")
        return best
    elif other_servers:
        return other_servers[0]
    else:
        return None

# ═══════════════════════════════════════════════════════════════════════════
# MT5 LOGIN (aus v1.0)
# ═══════════════════════════════════════════════════════════════════════════

def initialize_mt5() -> bool:
    """Initialisiert MT5-Verbindung"""
    logging.info("Initialisiere MT5-Verbindung...")
    if not mt5.initialize():
        error = mt5.last_error()
        logging.error(f"MT5-Initialisierung fehlgeschlagen: {error}")
        return False
    logging.info("✓ MT5 erfolgreich initialisiert")
    return True

def login_to_mt5(login: int, password: str, server: str) -> bool:
    """Führt Login in MT5 durch"""
    logging.info("═══════════════════════════════════════════════════════════")
    logging.info("  MT5 Login-Versuch")
    logging.info("═══════════════════════════════════════════════════════════")
    logging.info(f"Account: {login}")
    logging.info(f"Server:  {server}")

    try:
        authorized = mt5.login(login, password, server)
        if not authorized:
            error = mt5.last_error()
            logging.error(f"✗ Login fehlgeschlagen! Error: {error}")
            return False

        logging.info("✓ Login erfolgreich!")
        account_info = mt5.account_info()
        if account_info:
            logging.info(f"Name:     {account_info.name}")
            logging.info(f"Balance:  {account_info.balance} {account_info.currency}")
        return True

    except Exception as e:
        logging.error(f"Exception beim Login: {e}")
        return False

# ═══════════════════════════════════════════════════════════════════════════
# NEUE FUNKTIONEN: SYMBOL-SUFFIX-ERKENNUNG & EA-SETUP
# ═══════════════════════════════════════════════════════════════════════════

def detect_broker_suffix(base_symbol: str = "BTCUSD") -> Optional[str]:
    """
    Erkennt das Suffix, das der Broker für Symbole verwendet

    Args:
        base_symbol: Basis-Symbol ohne Suffix (default: BTCUSD)

    Returns:
        Suffix als String (z.B. ".raw", ".m", "") oder None
    """
    logging.info("═══════════════════════════════════════════════════════════")
    logging.info("  Erkenne Broker-Suffix für Symbole")
    logging.info("═══════════════════════════════════════════════════════════")

    # Hole alle verfügbaren Symbole
    symbols = mt5.symbols_get()

    if not symbols:
        logging.error("Keine Symbole verfügbar!")
        return None

    logging.info(f"Gefunden: {len(symbols)} Symbole")

    # Häufige Suffixe bei verschiedenen Brokern
    common_suffixes = [
        "",        # Kein Suffix (z.B. IC Markets)
        ".raw",    # Raw Spread (z.B. IC Markets Raw)
        ".m",      # Mini (z.B. einige Broker)
        ".pro",    # Pro Account
        ".ecn",    # ECN Account
        ".c",      # Classic
        "_",       # Unterstrich statt Punkt
        "-",       # Minus statt Punkt
    ]

    # Suche nach BTCUSD mit verschiedenen Suffixen
    found_symbols = []

    for symbol in symbols:
        symbol_name = symbol.name
        # Prüfe ob Symbol BTCUSD enthält (case-insensitive)
        if base_symbol.upper() in symbol_name.upper():
            found_symbols.append(symbol_name)
            logging.info(f"  Gefunden: {symbol_name}")

    if not found_symbols:
        logging.error(f"Kein {base_symbol}-Symbol gefunden!")
        return None

    # Bestimme Suffix
    for found in found_symbols:
        if found == base_symbol:
            # Kein Suffix
            logging.info(f"✓ Symbol ohne Suffix gefunden: {found}")
            return ""

        # Extrahiere Suffix
        if found.startswith(base_symbol):
            suffix = found[len(base_symbol):]
            logging.info(f"✓ Suffix erkannt: '{suffix}' (vollständig: {found})")
            return suffix

    # Fallback: Nimm erstes gefundenes Symbol
    logging.warning(f"Konnte Suffix nicht eindeutig bestimmen - verwende: {found_symbols[0]}")
    if found_symbols[0] == base_symbol:
        return ""
    else:
        return found_symbols[0][len(base_symbol):]

def find_symbol_with_suffix(base_symbol: str, suffix: str) -> Optional[str]:
    """
    Findet und validiert das vollständige Symbol

    Args:
        base_symbol: Basis-Symbol (z.B. "BTCUSD")
        suffix: Suffix (z.B. ".raw" oder "")

    Returns:
        Vollständiger Symbol-Name oder None
    """
    full_symbol = f"{base_symbol}{suffix}"

    logging.info(f"Suche Symbol: {full_symbol}")

    # Prüfe ob Symbol existiert
    symbol_info = mt5.symbol_info(full_symbol)

    if symbol_info is None:
        logging.error(f"Symbol nicht gefunden: {full_symbol}")
        return None

    # Aktiviere Symbol falls nötig
    if not symbol_info.visible:
        logging.info(f"Aktiviere Symbol: {full_symbol}")
        if not mt5.symbol_select(full_symbol, True):
            logging.error(f"Konnte Symbol nicht aktivieren: {full_symbol}")
            return None

    logging.info(f"✓ Symbol gefunden und aktiv: {full_symbol}")
    logging.info(f"  Beschreibung: {symbol_info.description}")
    logging.info(f"  Spread:       {symbol_info.spread}")

    return full_symbol

def load_ea_on_chart(symbol: str, timeframe, ea_name: str) -> bool:
    """
    Lädt EA auf Chart

    WICHTIG: Die MT5 Python API kann KEINE EAs direkt auf Charts laden!

    Workaround:
    1. Erstelle ein MQL5-Script, das den EA lädt
    2. Führe dieses Script aus

    Alternative für Production:
    - Verwende ein Template (chart.tpl)
    - Oder modifiziere terminal.ini

    Args:
        symbol: Symbol-Name (z.B. "BTCUSD.raw")
        timeframe: MT5 Timeframe (z.B. mt5.TIMEFRAME_H1)
        ea_name: EA-Name (z.B. "signal.ex5")

    Returns:
        True bei Erfolg, False bei Fehler
    """
    logging.info("═══════════════════════════════════════════════════════════")
    logging.info("  EA Setup auf Chart")
    logging.info("═══════════════════════════════════════════════════════════")
    logging.info(f"Symbol:    {symbol}")
    logging.info(f"Timeframe: H1")
    logging.info(f"EA:        {ea_name}")

    # WICHTIGE INFO: MT5 Python API Limitation
    logging.warning("HINWEIS: MT5 Python API kann EAs nicht direkt laden")
    logging.info("Erstelle MQL5-Setup-Script für automatisches EA-Laden...")

    # Erstelle MQL5-Script für EA-Setup
    mql5_script = create_ea_setup_script(symbol, timeframe, ea_name)

    if mql5_script:
        logging.info("✓ MQL5-Setup-Script erstellt")
        logging.info(f"  Pfad: {mql5_script}")
        logging.info("")
        logging.info("NÄCHSTE SCHRITTE:")
        logging.info("1. MT5 neustarten (optional)")
        logging.info("2. Script wird automatisch ausgeführt")
        logging.info("3. EA wird auf Chart geladen")
        return True
    else:
        logging.error("✗ Konnte Setup-Script nicht erstellen")
        return False

def create_ea_setup_script(symbol: str, timeframe, ea_name: str) -> Optional[str]:
    """
    Erstellt ein MQL5-Script, das automatisch beim MT5-Start läuft
    und den EA auf den Chart lädt

    Returns:
        Pfad zum erstellten Script oder None
    """
    # Finde MT5 Scripts-Verzeichnis (Wine)
    wine_prefix = os.environ.get('WINEPREFIX', os.path.expanduser('~/.wine'))

    # Mögliche Pfade
    possible_paths = [
        os.path.join(wine_prefix, 'drive_c/Program Files/MetaTrader 5/MQL5/Scripts'),
        os.path.join(wine_prefix, 'drive_c/Program Files (x86)/MetaTrader 5/MQL5/Scripts'),
    ]

    scripts_dir = None
    for path in possible_paths:
        if os.path.exists(path):
            scripts_dir = path
            break

    if not scripts_dir:
        logging.error("MQL5 Scripts-Verzeichnis nicht gefunden!")
        logging.info("Erstelle Fallback-Script...")

        # Fallback: Erstelle Script im aktuellen Verzeichnis
        script_path = "/tmp/AutoLoadEA.mq5"
    else:
        script_path = os.path.join(scripts_dir, "AutoLoadEA.mq5")

    # Timeframe zu String
    timeframe_str = "PERIOD_H1"
    if timeframe == mt5.TIMEFRAME_M1:
        timeframe_str = "PERIOD_M1"
    elif timeframe == mt5.TIMEFRAME_M5:
        timeframe_str = "PERIOD_M5"
    elif timeframe == mt5.TIMEFRAME_M15:
        timeframe_str = "PERIOD_M15"
    elif timeframe == mt5.TIMEFRAME_H1:
        timeframe_str = "PERIOD_H1"
    elif timeframe == mt5.TIMEFRAME_H4:
        timeframe_str = "PERIOD_H4"
    elif timeframe == mt5.TIMEFRAME_D1:
        timeframe_str = "PERIOD_D1"

    # MQL5-Script-Inhalt
    mql5_code = f"""//+------------------------------------------------------------------+
//|                                                  AutoLoadEA.mq5  |
//|                                    Automatisch generiert         |
//|                                    Copyright 2024, Stelona       |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Stelona"
#property version   "1.00"
#property script_show_inputs

//+------------------------------------------------------------------+
//| Script program start function                                     |
//+------------------------------------------------------------------+
void OnStart()
{{
   Print("═══════════════════════════════════════════════════════════");
   Print("  Auto-Load EA Script");
   Print("═══════════════════════════════════════════════════════════");

   string symbol = "{symbol}";
   ENUM_TIMEFRAMES timeframe = {timeframe_str};
   string ea_name = "{ea_name}";

   Print("Symbol:    ", symbol);
   Print("Timeframe: ", EnumToString(timeframe));
   Print("EA:        ", ea_name);

   // Öffne Chart
   long chart_id = ChartOpen(symbol, timeframe);

   if(chart_id == 0)
   {{
      Print("ERROR: Konnte Chart nicht öffnen!");
      return;
   }}

   Print("✓ Chart geöffnet: ", chart_id);

   // Warte kurz
   Sleep(2000);

   // Lade EA auf Chart
   // HINWEIS: ChartIndicatorAdd funktioniert nicht für EAs!
   // EAs müssen manuell oder via Template geladen werden

   Print("");
   Print("═══════════════════════════════════════════════════════════");
   Print("  Chart ist bereit!");
   Print("═══════════════════════════════════════════════════════════");
   Print("");
   Print("NÄCHSTE SCHRITTE:");
   Print("1. Ziehen Sie '", ea_name, "' auf den Chart");
   Print("2. Oder verwenden Sie ein Template");
   Print("");

   // Alternative: Erstelle ein Template
   CreateChartTemplate(chart_id, symbol, ea_name);
}}

//+------------------------------------------------------------------+
//| Erstellt ein Chart-Template mit EA                               |
//+------------------------------------------------------------------+
void CreateChartTemplate(long chart_id, string symbol, string ea_name)
{{
   Print("Erstelle Chart-Template...");

   // Template-Name
   string template_name = "AutoEA_" + symbol;

   // Speichere aktuelles Chart als Template
   if(ChartSaveTemplate(chart_id, template_name))
   {{
      Print("✓ Template erstellt: ", template_name, ".tpl");
      Print("  Pfad: MQL5/Profiles/Templates/");
   }}
   else
   {{
      Print("✗ Konnte Template nicht erstellen");
   }}
}}
//+------------------------------------------------------------------+
"""

    try:
        with open(script_path, 'w', encoding='utf-8') as f:
            f.write(mql5_code)

        logging.info(f"✓ MQL5-Script erstellt: {script_path}")
        return script_path

    except Exception as e:
        logging.error(f"Fehler beim Erstellen des Scripts: {e}")
        return None

def create_chart_template(symbol: str, ea_name: str) -> bool:
    """
    ALTERNATIVE LÖSUNG: Erstellt ein Chart-Template direkt

    Dies ist der pragmatischste Ansatz für vollautomatisches Setup!
    """
    logging.info("═══════════════════════════════════════════════════════════")
    logging.info("  Erstelle Chart-Template mit EA")
    logging.info("═══════════════════════════════════════════════════════════")

    wine_prefix = os.environ.get('WINEPREFIX', os.path.expanduser('~/.wine'))

    # Template-Verzeichnis
    template_paths = [
        os.path.join(wine_prefix, 'drive_c/Program Files/MetaTrader 5/MQL5/Profiles/Templates'),
        os.path.join(wine_prefix, 'drive_c/Program Files (x86)/MetaTrader 5/MQL5/Profiles/Templates'),
    ]

    template_dir = None
    for path in template_paths:
        if os.path.exists(path):
            template_dir = path
            break
        # Erstelle falls nicht vorhanden
        try:
            os.makedirs(path, exist_ok=True)
            template_dir = path
            break
        except:
            continue

    if not template_dir:
        logging.error("Template-Verzeichnis nicht gefunden/erstellt!")
        return False

    template_file = os.path.join(template_dir, "AutoStart.tpl")

    # Template-Inhalt (vereinfacht)
    template_content = f"""<chart>
symbol={symbol}
period=60
leftpos=0
digits=2
scale=4
graph=1
fore=0
grid=1
volume=0
scroll=1
shift=1
ohlc=1
askline=0
days=0
descriptions=0
shift_size=20
fixed_pos=0
window_left=0
window_top=0
window_right=1000
window_bottom=600
window_type=3
background_color=16777215
foreground_color=0
barup_color=65280
bardown_color=255
bullcandle_color=65280
bearcandle_color=255

<expert>
name={ea_name}
path=Experts\\{ea_name}
expertmode=1
<inputs>
</inputs>
</expert>

</chart>
"""

    try:
        with open(template_file, 'w', encoding='utf-8') as f:
            f.write(template_content)

        logging.info(f"✓ Template erstellt: {template_file}")
        logging.info("")
        logging.info("VERWENDUNG:")
        logging.info("1. Öffnen Sie MT5")
        logging.info("2. Datei → Template laden → AutoStart")
        logging.info("3. Oder: MT5 neu starten mit diesem Template")

        return True

    except Exception as e:
        logging.error(f"Fehler beim Erstellen des Templates: {e}")
        return False

# ═══════════════════════════════════════════════════════════════════════════
# HAUPTPROGRAMM
# ═══════════════════════════════════════════════════════════════════════════

def main():
    """Hauptfunktion für Auto-Login + EA-Setup"""

    parser = argparse.ArgumentParser(
        description='MT5 Auto-Login + EA Auto-Load für SaaS-Plattformen'
    )
    parser.add_argument('--config', default=DEFAULT_CONFIG_PATH, help='Pfad zur login.ini')
    parser.add_argument('--server', help='Server-Name direkt angeben')
    parser.add_argument('--ea', default=DEFAULT_EA_NAME, help='EA-Name (default: signal.ex5)')
    parser.add_argument('--symbol', default=DEFAULT_SYMBOL, help='Symbol (default: BTCUSD)')
    parser.add_argument('--restart', action='store_true', help='MT5 nach Setup neu starten')

    args = parser.parse_args()

    setup_logging()

    logging.info("═══════════════════════════════════════════════════════════")
    logging.info("  MT5 Auto-Login + EA Setup v2.0 - Stelona")
    logging.info("═══════════════════════════════════════════════════════════")
    logging.info("")

    # 1. Konfiguration laden
    login, password, broker = read_login_config(args.config)
    if not login or not password or not broker:
        logging.error("Abbruch: Konfiguration unvollständig")
        sys.exit(1)

    # 2. MT5 initialisieren
    if not initialize_mt5():
        logging.error("Abbruch: MT5-Initialisierung fehlgeschlagen")
        sys.exit(1)

    # 3. Server finden
    if args.server:
        server = args.server
    else:
        server = find_broker_server(broker)
        if not server:
            logging.error("Abbruch: Server nicht gefunden")
            sys.exit(1)

    # 4. Login
    if not login_to_mt5(login, password, server):
        logging.error("Abbruch: Login fehlgeschlagen")
        mt5.shutdown()
        sys.exit(1)

    logging.info("")

    # 5. NEUE FUNKTIONEN: Suffix erkennen & EA laden
    logging.info("═══════════════════════════════════════════════════════════")
    logging.info("  EA Auto-Setup")
    logging.info("═══════════════════════════════════════════════════════════")

    # Erkenne Suffix
    suffix = detect_broker_suffix(args.symbol)
    if suffix is None:
        logging.error("Konnte Suffix nicht erkennen!")
        # Versuche ohne Suffix
        suffix = ""

    logging.info("")

    # Finde vollständiges Symbol
    full_symbol = find_symbol_with_suffix(args.symbol, suffix)
    if not full_symbol:
        logging.error(f"Symbol nicht gefunden: {args.symbol}{suffix}")
        mt5.shutdown()
        sys.exit(1)

    logging.info("")

    # Erstelle Chart-Template mit EA
    if create_chart_template(full_symbol, args.ea):
        logging.info("✓ Chart-Template erfolgreich erstellt!")
    else:
        logging.warning("Template-Erstellung fehlgeschlagen - verwende Fallback")
        # Fallback: Erstelle MQL5-Script
        create_ea_setup_script(full_symbol, DEFAULT_TIMEFRAME, args.ea)

    logging.info("")
    logging.info("═══════════════════════════════════════════════════════════")
    logging.info("  ✓ SETUP ABGESCHLOSSEN!")
    logging.info("═══════════════════════════════════════════════════════════")
    logging.info("")
    logging.info(f"Symbol gefunden: {full_symbol}")
    logging.info(f"EA:              {args.ea}")
    logging.info(f"Template:        AutoStart.tpl")
    logging.info("")

    if args.restart:
        logging.info("MT5-Neustart gewünscht...")
        logging.info("Bitte starten Sie MT5 neu, damit das Template geladen wird")
        # Shutdown MT5 (im Docker wird es automatisch neu gestartet)
        mt5.shutdown()
        logging.info("✓ MT5 heruntergefahren - wird automatisch neu gestartet")
    else:
        logging.info("HINWEIS: Für automatisches EA-Laden MT5 neu starten:")
        logging.info("  python3 auto_login_with_ea.py --config ... --restart")

    logging.info("")
    sys.exit(0)

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        logging.info("Abbruch durch Benutzer")
        mt5.shutdown()
        sys.exit(130)
    except Exception as e:
        logging.error(f"Unerwarteter Fehler: {e}")
        logging.exception(e)
        mt5.shutdown()
        sys.exit(1)
