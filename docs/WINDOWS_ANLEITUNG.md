# 🪟 MT5 Pre-Flight Check - Windows 11 Anleitung

**Einfache Anleitung ohne PowerShell** - für die Ausführung des Python Pre-Flight Check Scripts

---

## 📋 Voraussetzungen

### 1. Python installieren

**Download:** https://www.python.org/downloads/

**WICHTIG:** Bei der Installation **"Add Python to PATH"** aktivieren!

![Python Installation - Add to PATH aktivieren]

**Prüfen ob Python installiert ist:**
1. Windows-Taste drücken
2. `cmd` eingeben und Enter
3. In der Eingabeaufforderung eingeben:
   ```cmd
   python --version
   ```
4. Du solltest etwas sehen wie: `Python 3.11.5`

---

### 2. MetaTrader5 Python Paket installieren

**In der Eingabeaufforderung (CMD):**
```cmd
pip install MetaTrader5
```

**Optional: Boto3 für S3-Upload installieren:**
```cmd
pip install boto3
```

**Optional: Requests für Webhook installieren:**
```cmd
pip install requests
```

---

### 3. MetaTrader 5 installieren

**Download:** https://www.metatrader5.com/de/download

Standardpfad: `C:\Program Files\MetaTrader 5\`

---

## 🚀 Methode 1: Doppelklick auf .bat Datei (EINFACHSTE METHODE)

### Schritt 1: login.ini erstellen

Erstelle eine Datei `login.ini` auf deinem **Desktop** oder in `C:\MT5\`:

**Inhalt:**
```ini
login=12345678
password=DeinPasswort
broker=IC Markets
```

**Broker-Namen die erkannt werden:**
- IC Markets
- Pepperstone
- Admiral Markets
- XM
- FBS
- FXTM
- Exness
- Roboforex
- Tickmill
- Alpari

---

### Schritt 2: Script-Dateien herunterladen

Lade diese Dateien in einen Ordner (z.B. `C:\MT5-Scripts\`):

1. **mt5_preflight_check_windows.py**
2. **test-preflight.bat**

---

### Schritt 3: Konfiguration anpassen (optional)

Öffne `test-preflight.bat` mit Notepad und passe die Konfiguration an:

```batch
REM Webhook URL (optional - leer lassen wenn nicht benötigt)
set WEBHOOK_URL=

REM S3 Bucket (optional - leer lassen wenn nicht benötigt)
set S3_BUCKET=
set S3_PREFIX=test/
set S3_REGION=eu-central-1

REM JSON Output (optional - leer lassen für keinen Output)
set OUTPUT_JSON=%USERPROFILE%\Desktop\mt5_symbols.json
```

**Beispiel mit Webhook:**
```batch
set WEBHOOK_URL=https://deine-domain.com/webhook
```

**Beispiel mit S3:**
```batch
set S3_BUCKET=mein-mt5-bucket
set S3_PREFIX=customer-configs/
set S3_REGION=eu-central-1
```

---

### Schritt 4: Ausführen

1. **Doppelklick** auf `test-preflight.bat`
2. Das Fenster öffnet sich und führt automatisch durch:
   - ✓ Python-Check
   - ✓ MetaTrader5-Paket-Check
   - ✓ MT5-Installation-Check
   - ✓ login.ini-Suche
   - 🚀 Pre-Flight Check Start

**Ausgabe:**
```
═══════════════════════════════════════════════════════════════════════════
  MT5 Pre-Flight Check - Quick Test
  Version: 1.0 - Windows 11
═══════════════════════════════════════════════════════════════════════════

Pruefe Python Installation...
✓ Python gefunden

Pruefe MetaTrader5 Python Paket...
✓ MetaTrader5 Paket installiert

Pruefe MT5 Installation...
✓ MT5 gefunden: C:\Program Files\MetaTrader 5\

Suche login.ini...
✓ Gefunden: C:\Users\YourName\Desktop\login.ini

═══════════════════════════════════════════════════════════════════════════
  Pre-Flight Check wird gestartet...
═══════════════════════════════════════════════════════════════════════════

[INFO] Initialisiere MT5...
[INFO] MT5 initialisiert: Version 3400
[INFO] Login erfolgreich: Account 12345678
[INFO] Broker: IC Markets Global
[INFO] Server: ICMarkets-Demo01

[SCAN] Scanne Symbole...
✓ BTCUSD → BTCUSDm (Suffix: m)
✓ ETHUSD → ETHUSDm (Suffix: m)
✓ EURUSD → EURUSD (Suffix: keins)
✓ XAUUSD → XAUUSD (Suffix: keins)

[S3] Suche servers.dat...
[S3] servers.dat gefunden: C:\Users\YourName\AppData\Roaming\...
[S3] Upload ÜBERSPRUNGEN (kein S3 Bucket konfiguriert)

[WEBHOOK] Sende Daten...
[WEBHOOK] ÜBERSPRUNGEN (kein Webhook konfiguriert)

[JSON] Speichere Ergebnis: C:\Users\YourName\Desktop\mt5_symbols.json

═══════════════════════════════════════════════════════════════════════════
  ✓ PRE-FLIGHT CHECK ERFOLGREICH!
═══════════════════════════════════════════════════════════════════════════

Ergebnis gespeichert: C:\Users\YourName\Desktop\mt5_symbols.json

JSON-Datei oeffnen? (J/N)
```

---

## 🖥️ Methode 2: CMD (Eingabeaufforderung)

### Schritt 1: CMD öffnen

1. Windows-Taste drücken
2. `cmd` eingeben
3. Enter drücken

---

### Schritt 2: Zum Script-Ordner navigieren

```cmd
cd C:\MT5-Scripts
```

Oder wo auch immer du die Dateien gespeichert hast.

---

### Schritt 3: Script ausführen

**Minimale Ausführung:**
```cmd
python mt5_preflight_check_windows.py --config C:\Users\YourName\Desktop\login.ini
```

**Mit JSON Output:**
```cmd
python mt5_preflight_check_windows.py --config C:\Users\YourName\Desktop\login.ini --output-json C:\Users\YourName\Desktop\mt5_symbols.json
```

**Mit Webhook:**
```cmd
python mt5_preflight_check_windows.py --config C:\Users\YourName\Desktop\login.ini --webhook-url https://deine-domain.com/webhook
```

**Mit S3-Upload:**
```cmd
python mt5_preflight_check_windows.py --config C:\Users\YourName\Desktop\login.ini --s3-bucket mein-bucket --s3-prefix test/ --s3-region eu-central-1
```

**KOMPLETT (alle Optionen):**
```cmd
python mt5_preflight_check_windows.py ^
  --config C:\Users\YourName\Desktop\login.ini ^
  --output-json C:\Users\YourName\Desktop\mt5_symbols.json ^
  --webhook-url https://deine-domain.com/webhook ^
  --s3-bucket mein-bucket ^
  --s3-prefix test/ ^
  --s3-region eu-central-1
```

**Hinweis:** Das `^` am Ende jeder Zeile ist der Windows-Zeilenumbruch für CMD.

---

## 📝 Methode 3: Python direkt aus Explorer

### Schritt 1: Python-Script bearbeiten

Öffne `mt5_preflight_check_windows.py` mit Notepad und füge am Anfang (nach den Imports) ein:

```python
# Hardcoded Config für einfaches Testen
CONFIG_PATH = r"C:\Users\YourName\Desktop\login.ini"
WEBHOOK_URL = ""  # Optional
S3_BUCKET = ""    # Optional
OUTPUT_JSON = r"C:\Users\YourName\Desktop\mt5_symbols.json"
```

---

### Schritt 2: Script anpassen

Suche nach der Zeile mit `if __name__ == "__main__":` (ganz unten) und ersetze:

```python
if __name__ == "__main__":
    import sys

    # Verwende hardcoded Config wenn keine Args
    if len(sys.argv) == 1:
        sys.argv = [
            sys.argv[0],
            "--config", CONFIG_PATH,
            "--output-json", OUTPUT_JSON
        ]
        if WEBHOOK_URL:
            sys.argv.extend(["--webhook-url", WEBHOOK_URL])
        if S3_BUCKET:
            sys.argv.extend(["--s3-bucket", S3_BUCKET])

    main()
```

---

### Schritt 3: Doppelklick auf .py Datei

Jetzt kannst du einfach doppelklicken auf `mt5_preflight_check_windows.py`.

**Hinweis:** Ein CMD-Fenster öffnet sich kurz und schließt wieder. Ergebnisse findest du in der JSON-Datei.

---

## 🔍 Alle Kommandozeilen-Optionen

```cmd
python mt5_preflight_check_windows.py --help
```

**Ausgabe:**
```
usage: mt5_preflight_check_windows.py [-h] --config CONFIG
                                       [--output-json OUTPUT_JSON]
                                       [--webhook-url WEBHOOK_URL]
                                       [--s3-bucket S3_BUCKET]
                                       [--s3-prefix S3_PREFIX]
                                       [--s3-region S3_REGION]

MT5 Pre-Flight Check für Windows

required arguments:
  --config CONFIG          Pfad zur login.ini Datei

optional arguments:
  -h, --help              Zeigt diese Hilfe an
  --output-json OUTPUT    Speichere Ergebnis als JSON
  --webhook-url URL       Sende Ergebnis an Webhook
  --s3-bucket BUCKET      S3 Bucket für servers.dat Upload
  --s3-prefix PREFIX      S3 Prefix (z.B. configs/)
  --s3-region REGION      AWS Region (default: eu-central-1)
```

---

## 📤 JSON Output Format

Die generierte JSON-Datei sieht so aus:

```json
{
  "timestamp": "2025-11-25T21:30:45.123456",
  "account_number": 12345678,
  "broker_info": {
    "name": "IC Markets Global",
    "server": "ICMarkets-Demo01"
  },
  "crypto": {
    "BTCUSD": {
      "full_symbol": "BTCUSDm",
      "suffix": "m",
      "description": "Bitcoin vs US Dollar"
    },
    "ETHUSD": {
      "full_symbol": "ETHUSDm",
      "suffix": "m",
      "description": "Ethereum vs US Dollar"
    }
  },
  "forex": {
    "EURUSD": {
      "full_symbol": "EURUSD",
      "suffix": "",
      "description": "Euro vs US Dollar"
    }
  },
  "indices": {
    "US30": {
      "full_symbol": "US30",
      "suffix": "",
      "description": "US Wall Street 30"
    }
  }
}
```

---

## 🌐 Webhook Payload Format

Wenn ein Webhook konfiguriert ist, wird dieser Payload gesendet:

```json
{
  "event": "mt5_preflight_complete",
  "timestamp": "2025-11-25T21:30:45.123456",
  "account": 12345678,
  "broker": "IC Markets Global",
  "server": "ICMarkets-Demo01",
  "symbols": {
    "crypto": { "BTCUSD": "m", "ETHUSD": "m" },
    "forex": { "EURUSD": "", "GBPUSD": "" },
    "indices": { "US30": "", "US100": "" }
  },
  "servers_dat_uploaded": false,
  "s3_key": null
}
```

---

## ⚙️ AWS S3 Konfiguration (optional)

### Schritt 1: AWS Credentials einrichten

Erstelle die Datei `C:\Users\YourName\.aws\credentials`:

```ini
[default]
aws_access_key_id = DEIN_ACCESS_KEY
aws_secret_access_key = DEIN_SECRET_KEY
```

Oder setze Umgebungsvariablen:

```cmd
set AWS_ACCESS_KEY_ID=DEIN_ACCESS_KEY
set AWS_SECRET_ACCESS_KEY=DEIN_SECRET_KEY
set AWS_DEFAULT_REGION=eu-central-1
```

---

### Schritt 2: Boto3 installieren

```cmd
pip install boto3
```

---

### Schritt 3: S3-Parameter übergeben

```cmd
python mt5_preflight_check_windows.py ^
  --config login.ini ^
  --s3-bucket mein-mt5-bucket ^
  --s3-prefix customer-configs/ ^
  --s3-region eu-central-1
```

**Ergebnis:**
- `servers.dat` wird hochgeladen nach:
- `s3://mein-mt5-bucket/customer-configs/12345678_servers.dat`

---

## 🛠️ Troubleshooting

### ❌ "Python nicht gefunden"

**Lösung:**
1. Python neu installieren: https://www.python.org/downloads/
2. **"Add Python to PATH"** aktivieren
3. CMD neu starten (wichtig!)

**Test:**
```cmd
python --version
```

---

### ❌ "MetaTrader5 Paket nicht installiert"

**Lösung:**
```cmd
pip install MetaTrader5
```

**Bei Fehlermeldung "pip not found":**
```cmd
python -m pip install MetaTrader5
```

---

### ❌ "MT5 Initialisierung fehlgeschlagen"

**Mögliche Ursachen:**
1. MT5 ist nicht installiert
2. MT5 läuft bereits (schließe MT5 Terminal)
3. Firewall blockiert MT5-API

**Lösung:**
1. MT5 installieren: https://www.metatrader5.com/de/download
2. MT5 schließen (auch im Task-Manager prüfen!)
3. Firewall-Ausnahme für MT5 hinzufügen

---

### ❌ "Login fehlgeschlagen"

**Mögliche Ursachen:**
1. Falsche Login-Daten in `login.ini`
2. Server nicht erreichbar
3. Account gesperrt

**Lösung:**
1. Login-Daten prüfen (in MT5 manuell testen)
2. Internet-Verbindung prüfen
3. Bei Broker nachfragen ob Account aktiv

---

### ❌ "Symbol nicht gefunden"

**Ursache:** Broker bietet das Symbol nicht an

**Lösung:** Normal! Das Script scannt 15+ Symbole, nicht alle Broker bieten alle an.

**Im Output steht dann:**
```
[SCAN] BTCUSD → nicht gefunden (Broker bietet es nicht an)
```

---

### ❌ "S3 Upload fehlgeschlagen"

**Mögliche Ursachen:**
1. AWS Credentials fehlen
2. Boto3 nicht installiert
3. Keine Berechtigung für Bucket

**Lösung:**
1. AWS Credentials einrichten (siehe oben)
2. `pip install boto3`
3. IAM-Berechtigungen prüfen (s3:PutObject erforderlich)

---

### ❌ "Webhook fehlgeschlagen"

**Mögliche Ursachen:**
1. Webhook-URL nicht erreichbar
2. Netzwerk-Problem
3. Webhook lehnt Request ab

**Lösung:**
1. URL im Browser testen
2. Internet-Verbindung prüfen
3. Webhook-Logs prüfen

---

## 🎯 Häufige Use Cases

### Use Case 1: Nur Symbol-Scan, kein Upload

```cmd
python mt5_preflight_check_windows.py --config login.ini --output-json symbols.json
```

---

### Use Case 2: Symbol-Scan + Webhook

```cmd
python mt5_preflight_check_windows.py ^
  --config login.ini ^
  --webhook-url https://meine-api.com/webhook
```

---

### Use Case 3: Vollständiger Pre-Flight (Production)

```cmd
python mt5_preflight_check_windows.py ^
  --config login.ini ^
  --output-json symbols.json ^
  --webhook-url https://meine-api.com/webhook ^
  --s3-bucket mein-bucket ^
  --s3-prefix configs/ ^
  --s3-region eu-central-1
```

---

### Use Case 4: Testen ohne S3/Webhook

```cmd
test-preflight.bat
```

Lässt einfach die Optionen im Batch-Script leer.

---

## 📚 Weitere Dokumentation

- **Preflight Workflow:** [PREFLIGHT_WORKFLOW.md](PREFLIGHT_WORKFLOW.md)
- **Backend Integration:** [PREFLIGHT_WORKFLOW.md#backend-integration](PREFLIGHT_WORKFLOW.md#backend-integration)
- **Investor Account Detection:** [INVESTOR_ACCOUNT_DETECTION.md](INVESTOR_ACCOUNT_DETECTION.md)

---

## 💡 Tipps

1. **Teste zuerst ohne S3/Webhook** - nur mit `--output-json`
2. **Prüfe die JSON-Datei** - sie zeigt alle erkannten Symbole
3. **Broker-Name muss exakt sein** - siehe Liste oben
4. **MT5 muss geschlossen sein** - sonst API-Konflikt
5. **Demo-Account für Tests** - verwende keinen Live-Account zum Testen

---

## 🆘 Support

Bei Problemen:

1. **JSON-Output prüfen** - zeigt Details zu Fehlern
2. **CMD-Output speichern:**
   ```cmd
   python mt5_preflight_check_windows.py --config login.ini > output.log 2>&1
   ```
3. **GitHub Issues:** https://github.com/stelona/signal-ea-v90/issues

---

**Version:** 1.0
**Erstellt:** 2025-11-25
**Plattform:** Windows 11
**Python:** 3.8+
**MT5:** 5.0.45+

---

✅ **Fertig!** Du kannst jetzt den MT5 Pre-Flight Check auf Windows 11 ausführen - ganz ohne PowerShell!
