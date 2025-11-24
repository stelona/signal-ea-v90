# 🪟 Windows 11 Testing Guide - MT5 Pre-Flight Check

## 🎯 Überblick

Diese Anleitung erklärt, wie Sie den **MT5 Pre-Flight Check** auf Ihrem **Windows 11 Desktop** testen können.

**Was das Script macht:**
1. ✅ MT5 auf Windows starten und einloggen
2. ✅ Symbol-Liste auslesen (BTCUSD, ETHUSD, etc.)
3. ✅ Broker-Suffixe erkennen (`.raw`, `.m`, etc.)
4. ✅ servers.dat zu S3 hochladen (optional)
5. ✅ Suffix-Daten an Webhook senden (optional)
6. ✅ Ergebnisse als JSON speichern

---

## 📋 Voraussetzungen

### 1. **Python 3.8+**

**Prüfen:**
```cmd
python --version
```

**Installation:**
- Download: https://www.python.org/downloads/
- ⚠️ **WICHTIG:** "Add Python to PATH" aktivieren!

### 2. **MetaTrader 5**

**Installation:**
- Download von Ihrem Broker (z.B. IC Markets, Pepperstone, XM)
- Oder: https://www.metatrader5.com/

**Standard-Pfad:**
- `C:\Program Files\MetaTrader 5\terminal64.exe`

### 3. **Python Packages**

```cmd
# Minimal (nur MT5 API)
pip install MetaTrader5

# Mit S3 und Webhook Support
pip install MetaTrader5 boto3 requests

# Oder alle aus requirements.txt
pip install -r requirements.txt
```

---

## 🚀 Quick Start (Einfachster Weg)

### Schritt 1: login.ini erstellen

Erstellen Sie eine Datei `login.ini` auf Ihrem **Desktop**:

```ini
login=12345678
password=IhrPasswort
broker=IC Markets
```

**Ersetzen Sie:**
- `12345678` → Ihre MT5 Account-Nummer
- `IhrPasswort` → Ihr MT5 Passwort
- `IC Markets` → Ihr Broker

### Schritt 2: Batch-Script ausführen

1. Öffnen Sie den Ordner: `src/automation/windows/`
2. **Doppelklick** auf `test-preflight.bat`
3. Warten Sie auf die Meldung "PRE-FLIGHT CHECK ERFOLGREICH!"
4. Ergebnis wird auf Desktop gespeichert: `mt5_symbols.json`

**Das war's!** 🎉

---

## 💻 Erweiterte Verwendung

### Option 1: Command Line (CMD)

```cmd
cd src\automation\windows

python mt5_preflight_check_windows.py ^
    --config C:\Users\IhrName\Desktop\login.ini ^
    --output-json C:\Temp\symbols.json
```

**Mit Webhook:**
```cmd
python mt5_preflight_check_windows.py ^
    --config C:\Users\IhrName\Desktop\login.ini ^
    --webhook-url https://webhook.site/your-unique-id ^
    --output-json C:\Temp\symbols.json
```

**Mit S3 Upload:**
```cmd
python mt5_preflight_check_windows.py ^
    --config C:\Users\IhrName\Desktop\login.ini ^
    --s3-bucket my-test-bucket ^
    --s3-prefix test/ ^
    --output-json C:\Temp\symbols.json
```

### Option 2: PowerShell

```powershell
cd src\automation\windows

.\Run-PreflightCheck.ps1 `
    -ConfigPath "C:\Users\IhrName\Desktop\login.ini" `
    -OutputJson "C:\Temp\symbols.json"
```

**Mit Webhook:**
```powershell
.\Run-PreflightCheck.ps1 `
    -ConfigPath "C:\Users\IhrName\Desktop\login.ini" `
    -WebhookUrl "https://webhook.site/your-unique-id" `
    -OutputJson "C:\Temp\symbols.json"
```

**Mit S3 Upload:**
```powershell
.\Run-PreflightCheck.ps1 `
    -ConfigPath "C:\Users\IhrName\Desktop\login.ini" `
    -S3Bucket "my-test-bucket" `
    -S3Prefix "test/" `
    -OutputJson "C:\Temp\symbols.json"
```

**Mit System-Checks überspringen:**
```powershell
.\Run-PreflightCheck.ps1 `
    -ConfigPath ".\login.ini" `
    -SkipChecks
```

---

## 📊 Output Beispiel

### Console Output:

```
═══════════════════════════════════════════════════════════
  MT5 Pre-Flight Check v1.0-Windows - Stelona
═══════════════════════════════════════════════════════════
  Platform: Windows 11


═══════════════════════════════════════════════════════════
  MT5 Initialisierung
═══════════════════════════════════════════════════════════
✓ MT5 initialisiert
  Version: 5382
  Path: C:\Program Files\MetaTrader 5

═══════════════════════════════════════════════════════════
  MT5 Login
═══════════════════════════════════════════════════════════
  Account: 12345678
  Server:  ICMarkets-Live10
✓ Login erfolgreich!
  Server:  ICMarkets-Live10
  Balance: 10000.00 USD
  Hebel:   1:500

═══════════════════════════════════════════════════════════
  Symbol-Erkennung
═══════════════════════════════════════════════════════════
  Scanne Crypto-Symbole...
✓ BTCUSD → BTCUSD.raw
✓ ETHUSD → ETHUSD.raw
✓ XRPUSD → XRPUSD.raw
✓ LTCUSD → LTCUSD.raw

  Scanne Forex-Symbole...
✓ EURUSD → EURUSD
✓ GBPUSD → GBPUSD
✓ USDJPY → USDJPY

  Scanne Indizes...
✓ US30 → US30
✓ US100 → US100
✓ US500 → US500

═══════════════════════════════════════════════════════════
  Suche servers.dat
═══════════════════════════════════════════════════════════
  MT5 Data Path: C:\Users\IhrName\AppData\Roaming\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075
✓ Gefunden: C:\Users\IhrName\AppData\Roaming\MetaQuotes\Terminal\...\config\servers.dat

═══════════════════════════════════════════════════════════
  JSON Output
═══════════════════════════════════════════════════════════
✓ Gespeichert: C:\Users\IhrName\Desktop\mt5_symbols.json
✓ MT5 beendet

═══════════════════════════════════════════════════════════
  ✓ PRE-FLIGHT CHECK ABGESCHLOSSEN
═══════════════════════════════════════════════════════════
  Crypto-Symbole:  5/5
  Forex-Symbole:   7/5
  Indizes:         5/5
  servers.dat S3:  ✗
  Webhook:         ✗
═══════════════════════════════════════════════════════════

✓ Ergebnisse gespeichert in: C:\Users\IhrName\Desktop\mt5_symbols.json
```

### JSON Output (mt5_symbols.json):

```json
{
  "crypto": {
    "BTCUSD": {
      "base_symbol": "BTCUSD",
      "full_symbol": "BTCUSD.raw",
      "suffix": ".raw",
      "description": "Bitcoin vs US Dollar",
      "path": "Crypto"
    },
    "ETHUSD": {
      "base_symbol": "ETHUSD",
      "full_symbol": "ETHUSD.raw",
      "suffix": ".raw",
      "description": "Ethereum vs US Dollar",
      "path": "Crypto"
    }
  },
  "forex": {
    "EURUSD": {
      "base_symbol": "EURUSD",
      "full_symbol": "EURUSD",
      "suffix": "",
      "description": "Euro vs US Dollar",
      "path": "Forex"
    }
  },
  "indices": {
    "US30": {
      "base_symbol": "US30",
      "full_symbol": "US30",
      "suffix": "",
      "description": "US Wall Street 30",
      "path": "Indices"
    }
  },
  "broker_info": {
    "server": "ICMarkets-Live10",
    "company": "IC Markets",
    "currency": "USD"
  },
  "timestamp": "2024-01-15T10:30:45.123456"
}
```

---

## 🧪 Webhook Testing

Um den Webhook zu testen ohne echten Backend-Server:

### 1. **Webhook.site** (Empfohlen)

1. Gehen Sie zu: https://webhook.site/
2. Kopieren Sie die **Unique URL**
3. Verwenden Sie diese im Script:

```cmd
python mt5_preflight_check_windows.py ^
    --config login.ini ^
    --webhook-url https://webhook.site/abc123-xyz789
```

4. Sehen Sie die Daten auf Webhook.site in Echtzeit!

### 2. **RequestBin**

Alternative: https://requestbin.com/

---

## 🔐 AWS S3 Testing

### AWS Credentials einrichten:

**Option 1: Environment Variables (PowerShell)**
```powershell
$env:AWS_ACCESS_KEY_ID = "your-access-key"
$env:AWS_SECRET_ACCESS_KEY = "your-secret-key"
```

**Option 2: AWS CLI**
```cmd
pip install awscli
aws configure
```

Geben Sie ein:
- Access Key ID
- Secret Access Key
- Region: `eu-central-1`
- Output: `json`

**Option 3: Credentials File**

Erstellen Sie: `C:\Users\IhrName\.aws\credentials`

```ini
[default]
aws_access_key_id = your-access-key
aws_secret_access_key = your-secret-key
```

### S3 Bucket erstellen:

```cmd
aws s3 mb s3://my-mt5-test-bucket --region eu-central-1
```

### Test mit S3:

```cmd
python mt5_preflight_check_windows.py ^
    --config login.ini ^
    --s3-bucket my-mt5-test-bucket ^
    --s3-prefix test/ ^
    --output-json symbols.json
```

### Ergebnis prüfen:

```cmd
aws s3 ls s3://my-mt5-test-bucket/test/

# Sollte zeigen:
# 2024-01-15 10:30:45      12345 servers.dat
```

---

## 🔍 Troubleshooting

### Problem: "Python nicht gefunden"

**Symptom:**
```
'python' is not recognized as an internal or external command
```

**Lösung:**
1. Python neu installieren: https://www.python.org/downloads/
2. ✅ "Add Python to PATH" aktivieren!
3. Computer neu starten
4. Testen: `python --version`

### Problem: "MT5-Initialisierung fehlgeschlagen"

**Symptom:**
```
✗ ERROR: MT5-Initialisierung fehlgeschlagen!
Error: (-2, 'IPC initialization failed')
```

**Lösungen:**

**1. MT5 ist bereits geöffnet**
- Schließen Sie MT5 komplett
- Prüfen Sie Task Manager (Strg+Shift+Esc) → Beenden Sie `terminal64.exe`
- Script erneut ausführen

**2. MT5 nicht installiert**
- Installieren Sie MT5 von Ihrem Broker
- Standard-Pfad: `C:\Program Files\MetaTrader 5\`

**3. Falsche MT5 Version**
- Stellen Sie sicher, dass Sie **MT5** haben (nicht MT4!)
- MetaTrader 5 Python API funktioniert nur mit MT5

### Problem: "Login fehlgeschlagen"

**Symptom:**
```
✗ ERROR: Login fehlgeschlagen: (10004, 'No connection to server')
```

**Lösungen:**

**1. Falsche Credentials**
- Prüfen Sie Login-Nummer (keine E-Mail!)
- Prüfen Sie Passwort (keine Leerzeichen)

**2. Falscher Server**
- Prüfen Sie Broker-Namen in login.ini
- Oder manuell angeben:
  ```cmd
  python mt5_preflight_check_windows.py ^
      --config login.ini ^
      --server ICMarkets-Live10
  ```

**3. Firewall blockiert**
- Windows Firewall → MT5 erlauben
- Antivirus temporär deaktivieren (Test)

**4. Internet-Verbindung**
- Prüfen Sie Ihre Internet-Verbindung
- VPN könnte stören (deaktivieren)

### Problem: "MetaTrader5 Paket nicht gefunden"

**Symptom:**
```
ModuleNotFoundError: No module named 'MetaTrader5'
```

**Lösung:**
```cmd
pip install MetaTrader5
```

Wenn das fehlschlägt:
```cmd
python -m pip install --upgrade pip
python -m pip install MetaTrader5
```

### Problem: "boto3 not installed" (S3)

**Symptom:**
```
⚠ WARNING: boto3 not installed - S3 upload disabled
```

**Lösung:**
```cmd
pip install boto3
```

Dies ist **optional** - nur nötig für S3 Upload!

### Problem: "servers.dat nicht gefunden"

**Symptom:**
```
✗ ERROR: servers.dat nicht gefunden!
```

**Grund:**
servers.dat wird erst NACH dem ersten Login erstellt.

**Lösung:**
1. Führen Sie das Script NACH erfolgreichem Login aus
2. servers.dat sollte dann existieren

**Manuell prüfen:**
```cmd
dir /s C:\Users\%USERNAME%\AppData\Roaming\MetaQuotes\Terminal\*servers.dat
```

### Problem: PowerShell Execution Policy

**Symptom:**
```
Run-PreflightCheck.ps1 cannot be loaded because running scripts is disabled
```

**Lösung:**

**Temporär:**
```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\Run-PreflightCheck.ps1
```

**Dauerhaft (als Administrator):**
```powershell
Set-ExecutionPolicy RemoteSigned
```

---

## 📁 File Locations

### Config Files:

```
Default search paths:
├─ C:\MT5\login.ini
├─ C:\Program Files\MetaTrader 5\login.ini
├─ C:\Users\IhrName\Desktop\login.ini
└─ .\login.ini (aktuelles Verzeichnis)
```

### MT5 Installation:

```
Standard paths:
├─ C:\Program Files\MetaTrader 5\terminal64.exe
├─ C:\Program Files (x86)\MetaTrader 5\terminal64.exe
└─ C:\Users\IhrName\AppData\Local\Programs\MetaTrader 5\terminal64.exe
```

### servers.dat:

```
Windows path:
C:\Users\IhrName\AppData\Roaming\MetaQuotes\Terminal\<HASH>\config\servers.dat

Beispiel:
C:\Users\John\AppData\Roaming\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075\config\servers.dat
```

---

## 📋 Checkliste

Vor dem Test:

- [ ] Python 3.8+ installiert (`python --version`)
- [ ] MetaTrader5 Package installiert (`pip install MetaTrader5`)
- [ ] MT5 Terminal installiert
- [ ] login.ini erstellt (Desktop oder C:\MT5\)
- [ ] MT5 ist geschlossen (kein terminal64.exe läuft)

Optional (S3):

- [ ] boto3 installiert (`pip install boto3`)
- [ ] AWS Credentials konfiguriert (`aws configure`)
- [ ] S3 Bucket erstellt

Optional (Webhook):

- [ ] requests installiert (`pip install requests`)
- [ ] Webhook.site URL erstellt

---

## 🚀 Next Steps nach erfolgreichem Test

1. **Ergebnis analysieren:**
   - Öffnen Sie `mt5_symbols.json` auf Desktop
   - Prüfen Sie erkannte Suffixe
   - Notieren Sie Broker-Server

2. **In Produktion integrieren:**
   - Webhook URL durch Ihre Backend-API ersetzen
   - S3 Bucket für Produktion konfigurieren
   - Login.ini dynamisch generieren (aus Datenbank)

3. **Template erstellen:**
   - Verwenden Sie erkannte Suffixe
   - Erstellen Sie MT5 Chart-Template
   - Beispiel in `PREFLIGHT_WORKFLOW.md`

---

## 📞 Support

Bei Problemen:

1. Prüfen Sie diese Troubleshooting-Sektion
2. Aktivieren Sie Verbose-Logging:
   ```cmd
   python mt5_preflight_check_windows.py --config login.ini --verbose
   ```
3. GitHub Issues: https://github.com/stelona/signal-ea-v90/issues

---

## 📝 Files

**Windows-spezifische Dateien:**

```
src/automation/windows/
├─ mt5_preflight_check_windows.py    # Haupt-Script
├─ Run-PreflightCheck.ps1             # PowerShell Wrapper
└─ test-preflight.bat                 # Batch Script (Quick Start)

docs/
└─ WINDOWS_TESTING_GUIDE.md           # Diese Anleitung
```

---

## ✅ Zusammenfassung

### Einfachster Test:

1. `login.ini` auf Desktop erstellen
2. Doppelklick auf `test-preflight.bat`
3. Fertig! Ergebnis auf Desktop: `mt5_symbols.json`

### Command Line:

```cmd
python mt5_preflight_check_windows.py --config login.ini --output-json result.json
```

### PowerShell:

```powershell
.\Run-PreflightCheck.ps1 -ConfigPath "login.ini" -OutputJson "result.json"
```

---

**Happy Testing! 🎉**

**© 2024 Stelona. All rights reserved.**
