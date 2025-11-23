# 🐍 MT5 Python Auto-Login - Vollständige Anleitung

## 📋 Übersicht

Das Python Auto-Login Script (`auto_login.py`) ermöglicht **vollautomatisches Einloggen** in MT5 ohne jegliche manuelle Interaktion.

### ✅ Was es kann:

- ✅ **Automatisches Einlesen** von `login.ini`
- ✅ **Intelligente Broker-Server-Suche** (IC Markets, Pepperstone, XM, etc.)
- ✅ **Vollautomatischer Login** via MetaTrader5 Python API
- ✅ **Headless Betrieb** - keine GUI-Interaktion nötig
- ✅ **Retry-Logik** bei Verbindungsfehlern
- ✅ **Umfassendes Logging**
- ✅ **Multi-Tenant-fähig**

### ❌ Was NICHT mehr nötig ist:

- ❌ Kein manuelles Klicken in MT5
- ❌ Keine GUI-Dialoge
- ❌ Keine Benutzer-Interaktion

---

## 🚀 Quick Start

### 1. Python-Umgebung einrichten

```bash
cd /opt/signal-ea-v90/src/automation/linux

# Setup-Script ausführen
chmod +x setup_python_env.sh
sudo ./setup_python_env.sh
```

**Was wird installiert:**
- Python 3.x
- pip3
- MetaTrader5 Python Package
- configparser

### 2. Login-Konfiguration erstellen

```bash
# Erstelle Verzeichnis für Config
mkdir -p ~/.wine/drive_c/MT5

# Kopiere Beispiel-Config
cp /opt/signal-ea-v90/examples/login.ini ~/.wine/drive_c/MT5/login.ini

# Bearbeite mit Kunden-Daten
nano ~/.wine/drive_c/MT5/login.ini
```

**Inhalt:**
```ini
login=12345678
password=IhrKundenPasswort
broker=IC Markets
```

### 3. Login-Script testen

```bash
# Manueller Test
python3 auto_login.py

# Oder mit spezifischer Config
python3 auto_login.py --config /path/to/custom_login.ini

# Mit manuellem Server
python3 auto_login.py --server "ICMarketsSC-Live10"
```

**Erwarteter Output:**
```
═══════════════════════════════════════════════════════════
  MT5 Auto-Login Script v1.0 - Stelona
═══════════════════════════════════════════════════════════

Lese Konfigurationsdatei: ~/.wine/drive_c/MT5/login.ini
✓ Konfiguration geladen:
  Login:  12345678
  Broker: IC Markets
  Password: ****** (versteckt)

Initialisiere MT5-Verbindung...
✓ MT5 erfolgreich initialisiert
MT5 Version: 5.0.40 (Build 4300)

Suche Server für Broker: IC Markets
Suche nach Server-Patterns: ['ICMarkets', 'ICMarketsSC', 'ICMarketsCT']
✓ Server gefunden (Live): ICMarketsSC-Live10

═══════════════════════════════════════════════════════════
  MT5 Login-Versuch
═══════════════════════════════════════════════════════════
Account: 12345678
Server:  ICMarketsSC-Live10
Password: ****** (versteckt)

✓ Login erfolgreich!

═══════════════════════════════════════════════════════════
  Account-Informationen
═══════════════════════════════════════════════════════════
Name:           John Doe
Server:         ICMarketsSC-Live10
Balance:        10000.00 USD
Eigenkapital:   10000.00 USD
Hebel:          1:500
Handelserlaubt: Ja
═══════════════════════════════════════════════════════════

✓ Verbindung zum Server aktiv

═══════════════════════════════════════════════════════════
  ✓ AUTO-LOGIN ERFOLGREICH!
═══════════════════════════════════════════════════════════

MT5 ist nun vollständig eingeloggt und betriebsbereit.
```

---

## 🔗 Integration in bestehende Auto-Start-Infrastruktur

### Option 1: Integration in `mt5_autostart.sh`

Bearbeiten Sie `mt5_autostart.sh` und fügen Sie nach dem MT5-Start hinzu:

```bash
# Nach dem MT5-Start (in der start_mt5 Funktion)

log INFO "MT5 erfolgreich gestartet!"

# NEUE ZEILE: Python Auto-Login ausführen
log INFO "Führe Auto-Login aus..."
sleep 5  # Warte bis MT5 vollständig geladen ist

python3 /opt/signal-ea-v90/src/automation/linux/auto_login.py \
    --config "$WINE_PREFIX/drive_c/MT5/login.ini" \
    >> "$LOG_FILE" 2>&1

if [ $? -eq 0 ]; then
    log SUCCESS "Auto-Login erfolgreich!"
else
    log ERROR "Auto-Login fehlgeschlagen!"
    return 1
fi
```

### Option 2: Separater systemd Service

Erstellen Sie einen separaten Service für das Login:

```bash
sudo tee /etc/systemd/system/mt5-auto-login.service <<EOF
[Unit]
Description=MT5 Auto-Login Service
After=mt5-autostart.service
Requires=mt5-autostart.service

[Service]
Type=oneshot
User=mt5user
Group=mt5user

Environment="WINEPREFIX=/home/mt5user/.wine"

# Warte bis MT5 gestartet ist
ExecStartPre=/bin/sleep 10

# Führe Auto-Login aus
ExecStart=/usr/bin/python3 /opt/signal-ea-v90/src/automation/linux/auto_login.py \
          --config /home/mt5user/.wine/drive_c/MT5/login.ini

# Logs
StandardOutput=append:/var/log/mt5/auto_login.log
StandardError=append:/var/log/mt5/auto_login_error.log

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable mt5-auto-login
sudo systemctl start mt5-auto-login
```

### Option 3: Docker Integration

Fügen Sie in `docker-entrypoint.sh` hinzu:

```bash
# Nach Xvfb-Start

# Starte MT5 im Hintergrund
wine "terminal64.exe" /login:$ACCOUNT /server:"$SERVER" /password:"$PASSWORD" &

# Warte kurz
sleep 10

# Python Auto-Login
python3 /opt/mt5/auto_login.py --config /opt/mt5/config.json

# Halte Container am Leben
exec tail -f /var/log/mt5/mt5_autostart.log
```

---

## 🔍 Headless Betrieb - Keine manuelle Interaktion!

### ✅ Garantiert keine GUI-Interaktion:

Das Python-Script nutzt die **MetaTrader5 Python API**, die:

1. **Direkt mit der MT5-Engine kommuniziert** (nicht mit GUI)
2. **Keine Fenster öffnet**
3. **Keine Dialoge zeigt**
4. **Vollständig programmgesteuert** ist

### Technische Erklärung:

```python
import MetaTrader5 as mt5

# 1. Initialisiert MT5-Terminal (ohne GUI)
mt5.initialize()

# 2. Login erfolgt direkt über API (kein Dialog!)
mt5.login(login, password, server)

# 3. MT5 läuft im Hintergrund, API bleibt aktiv
```

**Wichtig:** Nach `mt5.login()` wird **NICHT** `mt5.shutdown()` aufgerufen, damit MT5 weiterlaufen kann!

### Verifizierung:

Prüfen Sie, ob MT5 wirklich headless läuft:

```bash
# Kein GUI-Prozess sollte laufen
ps aux | grep terminal64.exe

# MT5 sollte laufen, aber keine X11-Fenster
DISPLAY=:99 xdotool search --name "MetaTrader" 2>/dev/null

# Sollte leer sein (keine Fenster)
```

---

## 🏢 Multi-Tenant Setup

### Struktur:

```
/opt/mt5/
├── customer1/
│   ├── login.ini
│   └── .wine/
├── customer2/
│   ├── login.ini
│   └── .wine/
└── customer3/
    ├── login.ini
    └── .wine/
```

### Automatisierte Config-Erstellung via SaaS-API:

```python
# Beispiel: Flask API Endpoint
from flask import Flask, request
import os

app = Flask(__name__)

@app.route('/api/mt5/create-login', methods=['POST'])
def create_login_config():
    data = request.json

    customer_id = data['customer_id']
    login = data['login']
    password = data['password']
    broker = data['broker']

    # Config-Datei erstellen
    config_path = f"/opt/mt5/{customer_id}/login.ini"
    os.makedirs(os.path.dirname(config_path), exist_ok=True)

    with open(config_path, 'w') as f:
        f.write(f"login={login}\n")
        f.write(f"password={password}\n")
        f.write(f"broker={broker}\n")

    # Berechtigungen setzen
    os.chmod(config_path, 0o600)

    return {'status': 'success', 'config': config_path}
```

---

## 🛡️ Sicherheit

### File-Berechtigungen:

```bash
# login.ini nur für Owner lesbar
chmod 600 ~/.wine/drive_c/MT5/login.ini
chown mt5user:mt5user ~/.wine/drive_c/MT5/login.ini

# Script ausführbar
chmod +x auto_login.py
```

### Passwort-Verschlüsselung (Optional):

Für Production: Verwenden Sie verschlüsselte Credentials:

```python
# Beispiel mit Fernet-Verschlüsselung
from cryptography.fernet import Fernet

# Schlüssel generieren (einmalig)
key = Fernet.generate_key()
cipher = Fernet(key)

# Passwort verschlüsseln
encrypted = cipher.encrypt(b"KundenPasswort")

# In login.ini speichern:
# password_encrypted=gAAAAABf...

# Im Script entschlüsseln:
password = cipher.decrypt(encrypted_password).decode()
```

---

## 📊 Monitoring & Logging

### Logs prüfen:

```bash
# Auto-Login Logs
tail -f /var/log/mt5/auto_login.log

# Fehler-Logs
tail -f /var/log/mt5/auto_login_error.log

# Nur Fehler anzeigen
grep ERROR /var/log/mt5/auto_login.log
```

### Health-Check:

```python
#!/usr/bin/env python3
# health_check.py

import MetaTrader5 as mt5

def check_mt5_connection():
    """Prüft ob MT5 verbunden ist"""

    if not mt5.initialize():
        print("ERROR: MT5 nicht initialisiert")
        return False

    terminal_info = mt5.terminal_info()

    if not terminal_info:
        print("ERROR: Keine Terminal-Info")
        return False

    if not terminal_info.connected:
        print("ERROR: Nicht verbunden")
        return False

    account_info = mt5.account_info()

    if not account_info:
        print("ERROR: Kein Account eingeloggt")
        return False

    print(f"OK: Account {account_info.login} auf {account_info.server}")
    return True

if __name__ == "__main__":
    import sys
    sys.exit(0 if check_mt5_connection() else 1)
```

**Verwendung:**
```bash
# Cronjob für Health-Check (alle 5 Minuten)
*/5 * * * * /usr/bin/python3 /opt/mt5/health_check.py || systemctl restart mt5-autostart
```

---

## 🔧 Troubleshooting

### Problem: "MT5-Initialisierung fehlgeschlagen"

**Lösung:**
```bash
# 1. Prüfe ob MT5 läuft
pgrep -f terminal64.exe

# 2. Prüfe Wine-Prefix
echo $WINEPREFIX

# 3. Prüfe MT5-Installation
ls -la ~/.wine/drive_c/Program*Files*/MetaTrader*/terminal64.exe
```

### Problem: "Server nicht gefunden"

**Lösung:**
```bash
# 1. Verwende manuellen Server
python3 auto_login.py --server "ExakterServerName"

# 2. Prüfe Server-Name beim Broker
# Login manuell in MT5, notiere exakten Server-Namen

# 3. Füge Pattern hinzu in auto_login.py
# Zeile ~186: broker_patterns dict erweitern
```

### Problem: "Login fehlgeschlagen - Error 10004"

**Bedeutung:** Ungültige Credentials oder falscher Server

**Lösung:**
```bash
# 1. Validiere login.ini
cat ~/.wine/drive_c/MT5/login.ini

# 2. Teste manuell in MT5
wine ~/.wine/drive_c/Program\ Files/MetaTrader\ 5/terminal64.exe

# 3. Prüfe Account beim Broker
```

### Problem: "MetaTrader5 module not found"

**Lösung:**
```bash
# Installiere MetaTrader5 Package
pip3 install MetaTrader5

# Oder via Setup-Script
./setup_python_env.sh
```

---

## 📝 Best Practices

### 1. Immer Retry-Logik verwenden:

```bash
python3 auto_login.py --retry 5 --retry-delay 10
```

### 2. Separate Configs pro Kunde:

```bash
python3 auto_login.py --config /opt/mt5/customer1/login.ini
python3 auto_login.py --config /opt/mt5/customer2/login.ini
```

### 3. Logging aktivieren:

```bash
# Logs in separate Dateien
python3 auto_login.py 2>&1 | tee -a /var/log/mt5/customer1_login.log
```

### 4. Health-Checks:

```bash
# Cronjob für automatische Re-Login bei Disconnect
*/10 * * * * /usr/bin/python3 /opt/mt5/auto_login.py --config /opt/mt5/login.ini >> /var/log/mt5/cron_login.log 2>&1
```

---

## 🎯 Zusammenfassung

| Frage | Antwort |
|-------|---------|
| **Manuelle Interaktion nötig?** | ❌ NEIN - vollständig automatisch |
| **GUI-Dialoge?** | ❌ NEIN - alles über Python API |
| **Headless funktionsfähig?** | ✅ JA - läuft ohne X11 |
| **Broker-Suche automatisch?** | ✅ JA - intelligentes Pattern-Matching |
| **Multi-Tenant-fähig?** | ✅ JA - separate Configs |
| **Production-ready?** | ✅ JA - mit Logging, Retry, Error-Handling |

---

## 📞 Support

- **GitHub Issues:** [https://github.com/stelona/signal-ea-v90/issues](https://github.com/stelona/signal-ea-v90/issues)
- **Email:** [support@stelona.com](mailto:support@stelona.com)

---

**© 2024 Stelona. All rights reserved.**
