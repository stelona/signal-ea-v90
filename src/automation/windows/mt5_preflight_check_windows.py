#!/usr/bin/env python3
#═══════════════════════════════════════════════════════════════════════════
# MT5 Pre-Flight Check - Symbol Detection & Server Configuration
# WINDOWS VERSION
#═══════════════════════════════════════════════════════════════════════════
#
# Workflow:
# 1. MT5 starten und einloggen (Windows native)
# 2. Symbol-Liste via API auslesen
# 3. Suffixe für wichtige Symbole erkennen (BTCUSD, ETHUSD, etc.)
# 4. servers.dat zu S3 hochladen (für späteren Login)
# 5. Suffix-Daten an Webhook senden
# 6. MT5 sauber beenden
#
# Nach diesem Script startet Ihr System den Customer-MT5 mit korrektem Template
#
# Usage (Windows):
#   python mt5_preflight_check_windows.py ^
#       --config C:\MT5\login.ini ^
#       --webhook-url https://api.example.com/mt5/symbols ^
#       --s3-bucket my-mt5-configs ^
#       --s3-prefix customer-123/
#
# Or with PowerShell:
#   python mt5_preflight_check_windows.py `
#       --config C:\MT5\login.ini `
#       --webhook-url https://api.example.com/mt5/symbols `
#       --s3-bucket my-mt5-configs `
#       --s3-prefix customer-123/
#
# Version: 1.0 (Windows)
# Author: Stelona
#═══════════════════════════════════════════════════════════════════════════

import MetaTrader5 as mt5
import configparser
import argparse
import sys
import os
import json
import glob
from pathlib import Path
from typing import Optional, Dict, List
import logging
from datetime import datetime

# ═══════════════════════════════════════════════════════════════════════════
# Conditional Imports (fail gracefully if not installed)
# ═══════════════════════════════════════════════════════════════════════════

try:
    import boto3
    from botocore.exceptions import ClientError, NoCredentialsError
    HAS_BOTO3 = True
except ImportError:
    HAS_BOTO3 = False
    print("⚠ WARNING: boto3 not installed - S3 upload disabled")
    print("  Install: pip install boto3")

try:
    import requests
    HAS_REQUESTS = True
except ImportError:
    HAS_REQUESTS = False
    print("⚠ WARNING: requests not installed - Webhook disabled")
    print("  Install: pip install requests")

# ═══════════════════════════════════════════════════════════════════════════
# Constants
# ═══════════════════════════════════════════════════════════════════════════

VERSION = "1.0-Windows"
DEFAULT_CONFIG_PATHS = [
    "C:\\MT5\\login.ini",
    "C:\\Program Files\\MetaTrader 5\\login.ini",
    os.path.join(os.path.expanduser("~"), "Desktop", "login.ini"),
    ".\\login.ini"
]

# Symbols to detect suffixes for
CRYPTO_SYMBOLS = ["BTCUSD", "ETHUSD", "XRPUSD", "LTCUSD", "BNBUSD"]
FOREX_SYMBOLS = ["EURUSD", "GBPUSD", "USDJPY", "AUDUSD", "USDCHF"]
INDICES_SYMBOLS = ["US30", "US100", "US500", "GER40", "UK100"]

ALL_DETECT_SYMBOLS = CRYPTO_SYMBOLS + FOREX_SYMBOLS + INDICES_SYMBOLS

# ═══════════════════════════════════════════════════════════════════════════
# Logging Setup
# ═══════════════════════════════════════════════════════════════════════════

logging.basicConfig(
    level=logging.INFO,
    format='%(message)s'
)

def print_header(text: str):
    """Formatierter Header"""
    logging.info("═══════════════════════════════════════════════════════════")
    logging.info(f"  {text}")
    logging.info("═══════════════════════════════════════════════════════════")

def print_success(text: str):
    """Erfolgsmeldung"""
    logging.info(f"✓ {text}")

def print_error(text: str):
    """Fehlermeldung"""
    logging.error(f"✗ ERROR: {text}")

def print_warning(text: str):
    """Warnung"""
    logging.warning(f"⚠ WARNING: {text}")

def print_info(text: str):
    """Info-Meldung"""
    logging.info(f"  {text}")

# ═══════════════════════════════════════════════════════════════════════════
# Config & Login
# ═══════════════════════════════════════════════════════════════════════════

def read_login_config(config_path: str) -> Optional[Dict[str, str]]:
    """Liest Login-Konfiguration"""
    try:
        config = configparser.ConfigParser()
        config.read(config_path, encoding='utf-8')

        if config.has_section('DEFAULT'):
            login = config.get('DEFAULT', 'login')
            password = config.get('DEFAULT', 'password')
            broker = config.get('DEFAULT', 'broker', fallback='')
        else:
            with open(config_path, 'r', encoding='utf-8') as f:
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
                print_error("login.ini muss 'login' und 'password' enthalten!")
                return None

        return {
            'login': int(login),
            'password': password,
            'broker': broker
        }

    except Exception as e:
        print_error(f"Fehler beim Lesen der Config: {e}")
        return None

def find_broker_server(broker_name: str) -> Optional[str]:
    """Findet Server für Broker"""
    broker_patterns = {
        'IC Markets': ['ICMarkets', 'ICMarketsSC'],
        'Pepperstone': ['Pepperstone'],
        'XM': ['XM', 'XMGlobal'],
        'FTMO': ['FTMO'],
        'Exness': ['Exness'],
        'FBS': ['FBS'],
        'HFM': ['HFMarkets'],
        'Fusion Markets': ['FusionMarkets'],
        'FP Markets': ['FPMarkets'],
        'Admiral Markets': ['AdmiralMarkets'],
    }

    patterns = broker_patterns.get(broker_name, [broker_name])

    servers = []
    for pattern in patterns:
        for suffix in ['-Live', '-Real', '-Live01', '-Live10', 'SC-Live', 'SC-Live10']:
            servers.append(f"{pattern}{suffix}")
        for suffix in ['-Demo', '-Demo01', 'SC-Demo']:
            servers.append(f"{pattern}{suffix}")
        servers.append(pattern)

    if servers:
        return servers[0]

    return None

def check_investor_mode() -> Dict:
    """Prüft ob Account im Investor-Modus (Read-Only) ist"""
    account_info = mt5.account_info()
    if not account_info:
        return {
            'is_investor': False,
            'trade_allowed': False,
            'trade_expert': False,
            'error': 'Account info nicht verfügbar'
        }

    is_investor = not account_info.trade_allowed

    return {
        'is_investor': is_investor,
        'trade_allowed': account_info.trade_allowed,
        'trade_expert': account_info.trade_expert,
        'trade_mode': 'INVESTOR (Read-Only)' if is_investor else 'TRADING (Full Access)'
    }

def login_to_mt5(login: int, password: str, server: str, allow_investor: bool = False) -> bool:
    """MT5 Login"""
    print_header("MT5 Login")
    print_info(f"Account: {login}")
    print_info(f"Server:  {server}")

    server_variations = [
        server,
        server.replace('-Live', 'SC-Live'),
        server + '01',
        server + '10',
    ]

    for srv in server_variations:
        if mt5.login(login, password, srv):
            print_success("Login erfolgreich!")

            account_info = mt5.account_info()
            if account_info:
                print_info(f"Server:  {account_info.server}")
                print_info(f"Balance: {account_info.balance:.2f} {account_info.currency}")
                print_info(f"Hebel:   1:{account_info.leverage}")

                # Check investor mode
                investor_check = check_investor_mode()

                if investor_check['is_investor']:
                    logging.info("")
                    print_warning("INVESTOR-MODUS ERKANNT!")
                    print_info(f"Account-Typ: {investor_check['trade_mode']}")
                    print_info(f"Trading erlaubt: {investor_check['trade_allowed']}")
                    print_info(f"Expert Advisors: {investor_check['trade_expert']}")
                    logging.info("")

                    if not allow_investor:
                        print_error("Investor-Accounts können keine EAs ausführen!")
                        print_info("Verwenden Sie einen Trading-Account für EA-Betrieb.")
                        print_info("Oder: --allow-investor Flag zum Ignorieren")
                        return False
                    else:
                        print_warning("Investor-Account wird ignoriert (--allow-investor Flag)")
                else:
                    print_success(f"Account-Typ: {investor_check['trade_mode']}")
                    print_info(f"Expert Advisors erlaubt: {investor_check['trade_expert']}")

            return True

    error = mt5.last_error()
    print_error(f"Login fehlgeschlagen: {error}")
    return False

# ═══════════════════════════════════════════════════════════════════════════
# Symbol Detection
# ═══════════════════════════════════════════════════════════════════════════

def detect_symbol_suffix(base_symbol: str) -> Optional[Dict]:
    """Erkennt Suffix für ein Symbol"""
    symbols = mt5.symbols_get()
    if not symbols:
        return None

    found_symbols = []
    for symbol in symbols:
        symbol_name = symbol.name
        if base_symbol.upper() in symbol_name.upper():
            found_symbols.append({
                'name': symbol_name,
                'description': symbol.description,
                'visible': symbol.visible,
                'path': symbol.path
            })

    if not found_symbols:
        return None

    # Prioritize exact match
    for found in found_symbols:
        if found['name'] == base_symbol:
            return {
                'base_symbol': base_symbol,
                'full_symbol': base_symbol,
                'suffix': '',
                'description': found['description'],
                'path': found['path']
            }

    # Find with suffix
    for found in found_symbols:
        if found['name'].startswith(base_symbol):
            suffix = found['name'][len(base_symbol):]
            return {
                'base_symbol': base_symbol,
                'full_symbol': found['name'],
                'suffix': suffix,
                'description': found['description'],
                'path': found['path']
            }

    # Fallback: first found
    return {
        'base_symbol': base_symbol,
        'full_symbol': found_symbols[0]['name'],
        'suffix': 'unknown',
        'description': found_symbols[0]['description'],
        'path': found_symbols[0]['path']
    }

def scan_all_symbols() -> Dict:
    """Scannt alle wichtigen Symbole"""
    print_header("Symbol-Erkennung")

    results = {
        'crypto': {},
        'forex': {},
        'indices': {},
        'timestamp': datetime.utcnow().isoformat(),
        'broker_info': {}
    }

    # Get broker info
    account_info = mt5.account_info()
    if account_info:
        results['broker_info'] = {
            'server': account_info.server,
            'company': account_info.company,
            'currency': account_info.currency
        }

    # Scan crypto
    print_info("Scanne Crypto-Symbole...")
    for symbol in CRYPTO_SYMBOLS:
        result = detect_symbol_suffix(symbol)
        if result:
            results['crypto'][symbol] = result
            print_success(f"{symbol} → {result['full_symbol']}")
        else:
            print_warning(f"{symbol} nicht gefunden")

    # Scan forex
    print_info("\nScanne Forex-Symbole...")
    for symbol in FOREX_SYMBOLS:
        result = detect_symbol_suffix(symbol)
        if result:
            results['forex'][symbol] = result
            print_success(f"{symbol} → {result['full_symbol']}")

    # Scan indices
    print_info("\nScanne Indizes...")
    for symbol in INDICES_SYMBOLS:
        result = detect_symbol_suffix(symbol)
        if result:
            results['indices'][symbol] = result
            print_success(f"{symbol} → {result['full_symbol']}")

    return results

# ═══════════════════════════════════════════════════════════════════════════
# servers.dat Upload (Windows Paths)
# ═══════════════════════════════════════════════════════════════════════════

def find_servers_dat() -> Optional[str]:
    """Findet servers.dat Datei (Windows)"""
    print_header("Suche servers.dat")

    terminal_info = mt5.terminal_info()
    if not terminal_info:
        print_error("Konnte Terminal-Info nicht abrufen")
        return None

    data_path = terminal_info.data_path
    print_info(f"MT5 Data Path: {data_path}")

    # Try common Windows locations
    search_paths = [
        os.path.join(data_path, "config", "servers.dat"),
        os.path.join(data_path, "..", "config", "servers.dat"),
    ]

    # Windows AppData paths
    appdata = os.path.expanduser("~\\AppData\\Roaming")
    metaquotes_base = os.path.join(appdata, "MetaQuotes", "Terminal")

    if os.path.exists(metaquotes_base):
        # Find all Terminal installations
        for terminal_hash in os.listdir(metaquotes_base):
            terminal_path = os.path.join(metaquotes_base, terminal_hash)
            if os.path.isdir(terminal_path):
                servers_path = os.path.join(terminal_path, "config", "servers.dat")
                search_paths.append(servers_path)

    for path in search_paths:
        if os.path.exists(path):
            print_success(f"Gefunden: {path}")
            return path

    print_warning("servers.dat nicht gefunden - suche rekursiv...")

    # Recursive search as fallback
    if os.path.exists(data_path):
        for root, dirs, files in os.walk(os.path.dirname(data_path)):
            if 'servers.dat' in files:
                path = os.path.join(root, 'servers.dat')
                print_success(f"Gefunden: {path}")
                return path

    print_error("servers.dat nicht gefunden!")
    return None

def upload_to_s3(file_path: str, bucket: str, s3_key: str, region: str = 'eu-central-1') -> bool:
    """Lädt Datei zu S3 hoch"""
    if not HAS_BOTO3:
        print_error("boto3 nicht installiert - S3 Upload nicht möglich")
        print_info("Installation: pip install boto3")
        return False

    print_header("S3 Upload")
    print_info(f"Datei:   {file_path}")
    print_info(f"Bucket:  {bucket}")
    print_info(f"Key:     {s3_key}")
    print_info(f"Region:  {region}")

    try:
        s3_client = boto3.client('s3', region_name=region)

        with open(file_path, 'rb') as f:
            s3_client.put_object(
                Bucket=bucket,
                Key=s3_key,
                Body=f,
                ContentType='application/octet-stream'
            )

        print_success("S3 Upload erfolgreich!")

        # Generate presigned URL for verification (optional)
        try:
            url = s3_client.generate_presigned_url(
                'get_object',
                Params={'Bucket': bucket, 'Key': s3_key},
                ExpiresIn=3600
            )
            print_info(f"Download URL (1h): {url[:80]}...")
        except:
            pass

        return True

    except NoCredentialsError:
        print_error("AWS Credentials nicht gefunden!")
        print_info("Setzen Sie: AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY")
        print_info("Oder: aws configure")
        return False

    except ClientError as e:
        print_error(f"S3 Upload fehlgeschlagen: {e}")
        return False

    except Exception as e:
        print_error(f"Fehler beim S3 Upload: {e}")
        return False

# ═══════════════════════════════════════════════════════════════════════════
# Webhook Notification
# ═══════════════════════════════════════════════════════════════════════════

def send_webhook(url: str, data: Dict, timeout: int = 10) -> bool:
    """Sendet Daten an Webhook"""
    if not HAS_REQUESTS:
        print_error("requests nicht installiert - Webhook nicht möglich")
        print_info("Installation: pip install requests")
        return False

    print_header("Webhook Notification")
    print_info(f"URL: {url}")
    print_info(f"Payload: {len(json.dumps(data))} bytes")

    try:
        response = requests.post(
            url,
            json=data,
            headers={'Content-Type': 'application/json'},
            timeout=timeout
        )

        if response.status_code >= 200 and response.status_code < 300:
            print_success(f"Webhook erfolgreich! Status: {response.status_code}")
            return True
        else:
            print_error(f"Webhook fehlgeschlagen! Status: {response.status_code}")
            print_info(f"Response: {response.text[:200]}")
            return False

    except requests.exceptions.Timeout:
        print_error(f"Webhook Timeout nach {timeout}s")
        return False

    except requests.exceptions.RequestException as e:
        print_error(f"Webhook Fehler: {e}")
        return False

# ═══════════════════════════════════════════════════════════════════════════
# Main
# ═══════════════════════════════════════════════════════════════════════════

def main():
    print_header(f"MT5 Pre-Flight Check v{VERSION} - Stelona")
    print_info("Platform: Windows 11")
    print_info("")

    parser = argparse.ArgumentParser(
        description='MT5 Pre-Flight Check: Symbol-Erkennung + Server-Config Upload (Windows)'
    )
    parser.add_argument('--config', type=str, help='Pfad zur login.ini')
    parser.add_argument('--server', type=str, help='Manueller Server-Name')

    # Webhook
    parser.add_argument('--webhook-url', type=str, help='Webhook URL für Symbol-Daten')
    parser.add_argument('--webhook-timeout', type=int, default=10, help='Webhook Timeout (Sekunden)')

    # S3
    parser.add_argument('--s3-bucket', type=str, help='S3 Bucket Name')
    parser.add_argument('--s3-prefix', type=str, default='', help='S3 Key Prefix (z.B. customer-123/)')
    parser.add_argument('--s3-region', type=str, default='eu-central-1', help='AWS Region')

    # Output
    parser.add_argument('--output-json', type=str, help='Speichere Ergebnis als JSON')
    parser.add_argument('--verbose', action='store_true', help='Verbose Logging')

    # Account Type
    parser.add_argument('--allow-investor', action='store_true', help='Erlaube Investor-Accounts (Read-Only)')

    args = parser.parse_args()

    if args.verbose:
        logging.getLogger().setLevel(logging.DEBUG)

    # ═══════════════════════════════════════════════════════════════════════
    # 1. Load Config
    # ═══════════════════════════════════════════════════════════════════════

    config_path = args.config
    if not config_path:
        for path in DEFAULT_CONFIG_PATHS:
            expanded = os.path.expanduser(path)
            if os.path.exists(expanded):
                config_path = expanded
                break

    if not config_path or not os.path.exists(config_path):
        print_error("Keine login.ini gefunden!")
        print_info("Durchsucht:")
        for path in DEFAULT_CONFIG_PATHS:
            print_info(f"  - {path}")
        print_info("\nVerwendung: python mt5_preflight_check_windows.py --config C:\\MT5\\login.ini")
        return 1

    print_info(f"Lese Konfigurationsdatei: {config_path}")

    config = read_login_config(config_path)
    if not config:
        return 1

    # ═══════════════════════════════════════════════════════════════════════
    # 2. Initialize MT5
    # ═══════════════════════════════════════════════════════════════════════

    print_header("MT5 Initialisierung")
    if not mt5.initialize():
        print_error("MT5-Initialisierung fehlgeschlagen!")
        print_error(f"Error: {mt5.last_error()}")
        print_info("\nMögliche Ursachen:")
        print_info("  - MT5 Terminal ist nicht installiert")
        print_info("  - MT5 läuft bereits und blockiert")
        print_info("  - MetaTrader5 Python Paket nicht installiert")
        return 1

    print_success("MT5 initialisiert")
    terminal_info = mt5.terminal_info()
    if terminal_info:
        print_info(f"Version: {terminal_info.build}")
        print_info(f"Path: {terminal_info.path}")

    # ═══════════════════════════════════════════════════════════════════════
    # 3. Login
    # ═══════════════════════════════════════════════════════════════════════

    server = args.server
    if not server and config['broker']:
        server = find_broker_server(config['broker'])
        if not server:
            print_error(f"Kein Server für Broker '{config['broker']}' gefunden")
            mt5.shutdown()
            return 1

    if not login_to_mt5(config['login'], config['password'], server, args.allow_investor):
        mt5.shutdown()
        return 1

    # ═══════════════════════════════════════════════════════════════════════
    # 4. Scan Symbols
    # ═══════════════════════════════════════════════════════════════════════

    symbol_data = scan_all_symbols()

    # Add account type info
    investor_check = check_investor_mode()
    symbol_data['account_type'] = investor_check

    # ═══════════════════════════════════════════════════════════════════════
    # 5. Find & Upload servers.dat
    # ═══════════════════════════════════════════════════════════════════════

    servers_dat_uploaded = False
    if args.s3_bucket:
        servers_dat = find_servers_dat()
        if servers_dat:
            s3_key = f"{args.s3_prefix}servers.dat"
            if upload_to_s3(servers_dat, args.s3_bucket, s3_key, args.s3_region):
                servers_dat_uploaded = True
                symbol_data['servers_dat_s3'] = {
                    'bucket': args.s3_bucket,
                    'key': s3_key,
                    'region': args.s3_region,
                    'uploaded': True
                }
        else:
            print_warning("servers.dat nicht gefunden - Upload übersprungen")
    else:
        print_info("\nKein S3 Bucket angegeben - Upload übersprungen")

    # ═══════════════════════════════════════════════════════════════════════
    # 6. Send Webhook
    # ═══════════════════════════════════════════════════════════════════════

    webhook_sent = False
    if args.webhook_url:
        if send_webhook(args.webhook_url, symbol_data, args.webhook_timeout):
            webhook_sent = True
    else:
        print_info("\nKeine Webhook-URL angegeben - Notification übersprungen")

    # ═══════════════════════════════════════════════════════════════════════
    # 7. Save JSON Output
    # ═══════════════════════════════════════════════════════════════════════

    if args.output_json:
        print_header("JSON Output")
        try:
            with open(args.output_json, 'w', encoding='utf-8') as f:
                json.dump(symbol_data, f, indent=2, ensure_ascii=False)
            print_success(f"Gespeichert: {args.output_json}")
        except Exception as e:
            print_error(f"Fehler beim Speichern: {e}")

    # ═══════════════════════════════════════════════════════════════════════
    # 8. Cleanup
    # ═══════════════════════════════════════════════════════════════════════

    mt5.shutdown()
    print_success("MT5 beendet")

    # ═══════════════════════════════════════════════════════════════════════
    # Summary
    # ═══════════════════════════════════════════════════════════════════════

    print_header("✓ PRE-FLIGHT CHECK ABGESCHLOSSEN")

    crypto_found = len(symbol_data['crypto'])
    forex_found = len(symbol_data['forex'])
    indices_found = len(symbol_data['indices'])

    print_info(f"Crypto-Symbole:  {crypto_found}/{len(CRYPTO_SYMBOLS)}")
    print_info(f"Forex-Symbole:   {forex_found}/{len(FOREX_SYMBOLS)}")
    print_info(f"Indizes:         {indices_found}/{len(INDICES_SYMBOLS)}")
    print_info(f"servers.dat S3:  {'✓' if servers_dat_uploaded else '✗'}")
    print_info(f"Webhook:         {'✓' if webhook_sent else '✗'}")

    logging.info("═══════════════════════════════════════════════════════════")
    logging.info("")

    if args.output_json:
        print_success(f"Ergebnisse gespeichert in: {args.output_json}")

    return 0

if __name__ == "__main__":
    sys.exit(main())
