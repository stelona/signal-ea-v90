# 🚀 MT5 SaaS-Plattform Deployment Guide

## 📋 Übersicht

Dieser Guide beschreibt die **vollautomatische** MT5-Installation für SaaS-Plattformen, bei der **KEINE manuelle Interaktion** des Kunden erforderlich ist.

### ✅ Was wird erreicht:

- ✅ **Vollautomatischer MT5-Start** mit konfigurierten Login-Daten
- ✅ **Keine manuelle Interaktion** - Kunde muss nichts klicken
- ✅ **Automatischer Start bei System-Boot** via Windows Service
- ✅ **Automatischer Neustart bei Absturz** mit Process Monitoring
- ✅ **Zentrale Konfiguration** via JSON-Datei
- ✅ **Multi-Tenant-fähig** - mehrere MT5-Instanzen pro Server
- ✅ **API-Integration** für Remote-Management

### ❌ Was NICHT funktioniert:

Das ursprüngliche `MT5_Auto_Login.mq5` Script ist **NICHT geeignet** für SaaS, weil:
- ❌ Erfordert manuelles Starten des Scripts im MT5-Terminal
- ❌ Kann keinen Account-Wechsel während MT5-Laufzeit durchführen
- ❌ Keine automatische Ausführung bei System-Start

---

## 🏗️ Architektur

```
┌─────────────────────────────────────────────────────────┐
│                    Windows Server                        │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  ┌────────────────────────────────────────────────┐    │
│  │   Windows Service / Task Scheduler             │    │
│  │   (Startet automatisch bei Boot)               │    │
│  └──────────────────┬─────────────────────────────┘    │
│                     │                                    │
│  ┌──────────────────▼─────────────────────────────┐    │
│  │   MT5_AutoStart.ps1                            │    │
│  │   - Liest JSON-Config                          │    │
│  │   - Startet MT5 mit Login-Parametern          │    │
│  │   - Überwacht Prozess                          │    │
│  └──────────────────┬─────────────────────────────┘    │
│                     │                                    │
│  ┌──────────────────▼─────────────────────────────┐    │
│  │   MetaTrader 5 Terminal                        │    │
│  │   - Automatisch eingeloggt                     │    │
│  │   - Kein manueller Eingriff nötig              │    │
│  └────────────────────────────────────────────────┘    │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

---

## 📦 Komponenten

### 1. **MT5_AutoStart.ps1**
PowerShell-Script für automatischen MT5-Start
- Liest Login-Daten aus JSON-Config
- Startet MT5 mit Kommandozeilen-Parametern
- Überwacht MT5-Prozess und startet bei Absturz neu
- Logging aller Aktivitäten

### 2. **Install-MT5Service.ps1**
Service-Installer für Windows
- Installiert MT5_AutoStart als Windows Service (via NSSM)
- Alternative: Task Scheduler Integration
- Automatischer Start bei System-Boot

### 3. **MT5_ConfigManager.ps1**
Konfigurationsmanager für MT5
- Bearbeitet `terminal.ini` programmatisch
- Erstellt erforderliche Verzeichnisse
- Backup-Funktion für Konfigurationen

### 4. **mt5_saas_config.json**
Zentrale Konfigurationsdatei
- Account-Credentials
- MT5-Pfade
- Monitoring-Einstellungen
- Restart-Policies

---

## 🚀 Installation (Schritt-für-Schritt)

### ✅ Voraussetzungen

- Windows Server 2016 oder neuer (oder Windows 10/11)
- MetaTrader 5 installiert
- PowerShell 5.1 oder neuer
- Administrator-Rechte

---

### Schritt 1: MT5 Installation

```powershell
# 1. MT5 herunterladen und installieren
# Download von: https://www.metatrader5.com/en/download

# 2. Installation im Standard-Pfad (empfohlen)
$mt5Path = "C:\Program Files\MetaTrader 5\terminal64.exe"

# 3. Validieren
if (Test-Path $mt5Path) {
    Write-Host "✓ MT5 installiert: $mt5Path" -ForegroundColor Green
} else {
    Write-Host "✗ MT5 nicht gefunden!" -ForegroundColor Red
}
```

---

### Schritt 2: Scripts herunterladen

```powershell
# 1. Repository klonen oder Scripts kopieren
git clone https://github.com/stelona/signal-ea-v90.git
cd signal-ea-v90

# 2. Scripts nach C:\MT5 kopieren
$scriptDir = "C:\MT5\automation"
New-Item -ItemType Directory -Path $scriptDir -Force

Copy-Item src/automation/* -Destination $scriptDir -Recurse
Copy-Item examples/mt5_saas_config.json -Destination "C:\MT5\config.json"

Write-Host "✓ Scripts kopiert nach $scriptDir" -ForegroundColor Green
```

---

### Schritt 3: Konfiguration anpassen

Bearbeiten Sie `C:\MT5\config.json`:

```json
{
  "account": 12345678,
  "password": "IhrKundenPasswort",
  "server": "ICMarkets-Demo",

  "mt5_path": "C:\\Program Files\\MetaTrader 5\\terminal64.exe",
  "mt5_data_path": "C:\\Users\\Administrator\\AppData\\Roaming\\MetaQuotes\\Terminal\\HASH",

  "stop_existing": true,
  "auto_restart": true,
  "restart_delay_seconds": 10,

  "monitoring": {
    "enabled": true,
    "check_interval_seconds": 30,
    "log_status": true
  }
}
```

**Wichtig:** `mt5_data_path` finden:
```powershell
# MT5 starten und Datenordner öffnen: Datei → Datenordner öffnen
# Pfad kopieren und in config.json eintragen
```

---

### Schritt 4: Test-Lauf

```powershell
# 1. Script manuell testen (OHNE Service)
cd C:\MT5\automation

powershell.exe -ExecutionPolicy Bypass -File .\MT5_AutoStart.ps1 -ConfigFile "C:\MT5\config.json" -NoMonitor

# 2. Prüfen ob MT5 startet und einloggt
# Sie sollten MT5 automatisch mit Ihrem Account sehen

# 3. Beenden Sie MT5
# Drücken Sie Strg+C im PowerShell-Fenster
```

---

### Schritt 5: Windows Service Installation

```powershell
# 1. PowerShell als Administrator starten
# Rechtsklick → Als Administrator ausführen

# 2. Service installieren
cd C:\MT5\automation

.\Install-MT5Service.ps1 -ConfigFile "C:\MT5\config.json"

# 3. Wählen Sie Installationsmethode:
#    [1] Windows Service (NSSM) - Empfohlen
#    [2] Task Scheduler - Alternative

# 4. Service sollte nun laufen
sc query MT5AutoStart
```

**Output (erfolgreich):**
```
SERVICE_NAME: MT5AutoStart
        TYPE               : 10  WIN32_OWN_PROCESS
        STATE              : 4  RUNNING
        WIN32_EXIT_CODE    : 0  (0x0)
```

---

### Schritt 6: Validierung

```powershell
# 1. Prüfe Service-Status
Get-Service -Name MT5AutoStart

# 2. Prüfe MT5-Prozess
Get-Process -Name terminal64

# 3. Prüfe Logs
Get-Content C:\MT5\logs\mt5_autostart.log -Tail 50

# 4. Neustart-Test
Restart-Computer
# Nach Neustart: MT5 sollte automatisch laufen
```

---

## 🔧 Erweiterte Konfiguration

### Multi-Tenant Setup (mehrere MT5-Instanzen)

Für SaaS-Plattformen mit mehreren Kunden:

```powershell
# Struktur:
# C:\MT5\
#   ├── customer1\
#   │   ├── config.json
#   │   └── data\
#   ├── customer2\
#   │   ├── config.json
#   │   └── data\
#   └── automation\
#       └── MT5_AutoStart.ps1

# Service für jeden Kunden installieren
.\Install-MT5Service.ps1 `
    -ConfigFile "C:\MT5\customer1\config.json" `
    -ServiceName "MT5_Customer1" `
    -DisplayName "MT5 Auto-Start - Customer 1"

.\Install-MT5Service.ps1 `
    -ConfigFile "C:\MT5\customer2\config.json" `
    -ServiceName "MT5_Customer2" `
    -DisplayName "MT5 Auto-Start - Customer 2"
```

**Hinweis:** Jede MT5-Instanz benötigt einen eigenen Datenordner!

---

### Separate MT5-Datenordner erstellen

```powershell
# 1. Portable MT5-Installation verwenden
# Download: https://www.metatrader5.com/en/download

# 2. Für jeden Kunden eigenen Ordner
$customer1Dir = "C:\MT5\customer1\MT5"
$customer2Dir = "C:\MT5\customer2\MT5"

# 3. MT5 in jeden Ordner installieren (portable Mode)
# Kopieren Sie die MT5-Installation:
Copy-Item "C:\Program Files\MetaTrader 5" -Destination $customer1Dir -Recurse
Copy-Item "C:\Program Files\MetaTrader 5" -Destination $customer2Dir -Recurse

# 4. Config für jeden Kunden anpassen
$config1 = @{
    account = 11111111
    password = "customer1_password"
    server = "ICMarkets-Demo"
    mt5_path = "$customer1Dir\terminal64.exe"
    mt5_data_path = "$customer1Dir\data"
} | ConvertTo-Json

$config1 | Set-Content "C:\MT5\customer1\config.json"
```

---

### API-Integration (Remote-Management)

Erstellen Sie eine REST API für Ihr SaaS:

```powershell
# Beispiel: Simple PowerShell Web-API
# api_server.ps1

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:8080/")
$listener.Start()

Write-Host "API läuft auf http://localhost:8080/"

while ($listener.IsListening) {
    $context = $listener.GetContext()
    $request = $context.Request
    $response = $context.Response

    # Endpoint: /start-mt5
    if ($request.Url.LocalPath -eq "/start-mt5") {
        $body = "Starting MT5..."

        # Starte MT5 für Kunden
        $customerId = $request.QueryString["customer"]
        Start-Process powershell.exe -ArgumentList "-File C:\MT5\automation\MT5_AutoStart.ps1 -ConfigFile C:\MT5\$customerId\config.json -NoMonitor"

        $buffer = [System.Text.Encoding]::UTF8.GetBytes($body)
        $response.ContentLength64 = $buffer.Length
        $response.OutputStream.Write($buffer, 0, $buffer.Length)
    }

    $response.Close()
}
```

**Nutzung:**
```bash
# MT5 für customer1 starten
curl http://localhost:8080/start-mt5?customer=customer1

# MT5 für customer2 starten
curl http://localhost:8080/start-mt5?customer=customer2
```

---

## 🛡️ Sicherheit

### 1. Credential-Management

**Problem:** Passwörter in JSON-Klartext

**Lösungen:**

#### Option A: Verschlüsselte Credentials
```powershell
# Passwort verschlüsseln
$password = "IhrPasswort" | ConvertTo-SecureString -AsPlainText -Force
$encryptedPassword = $password | ConvertFrom-SecureString

# In Config speichern
$config = @{
    account = 12345678
    encrypted_password = $encryptedPassword
    server = "ICMarkets-Demo"
} | ConvertTo-Json

# Beim Laden entschlüsseln
$securePassword = $config.encrypted_password | ConvertTo-SecureString
$plainPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword)
)
```

#### Option B: Windows Credential Manager
```powershell
# Credential speichern
cmdkey /generic:"MT5_Customer1" /user:"12345678" /pass:"IhrPasswort"

# Credential abrufen (im Script)
$credential = cmdkey /list:"MT5_Customer1"
```

#### Option C: Azure Key Vault / HashiCorp Vault
Für Produktion empfohlen!

---

### 2. Netzwerk-Isolation

```powershell
# Windows Firewall: Nur ausgehende Verbindungen zu MT5-Servern
New-NetFirewallRule -DisplayName "MT5 Outbound" `
    -Direction Outbound `
    -Program "C:\Program Files\MetaTrader 5\terminal64.exe" `
    -Action Allow `
    -Profile Any

# Eingehende Verbindungen blockieren
New-NetFirewallRule -DisplayName "MT5 Inbound Block" `
    -Direction Inbound `
    -Program "C:\Program Files\MetaTrader 5\terminal64.exe" `
    -Action Block `
    -Profile Any
```

---

### 3. File-System-Berechtigungen

```powershell
# Nur SYSTEM und Administrators dürfen Config-Dateien lesen
$configPath = "C:\MT5\config.json"

# Entferne alle Berechtigungen
$acl = Get-Acl $configPath
$acl.SetAccessRuleProtection($true, $false)

# Füge nur SYSTEM und Admins hinzu
$systemRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
    "SYSTEM", "FullControl", "Allow"
)
$adminRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
    "Administrators", "FullControl", "Allow"
)

$acl.AddAccessRule($systemRule)
$acl.AddAccessRule($adminRule)

Set-Acl $configPath $acl
```

---

## 📊 Monitoring & Logging

### Logs überwachen

```powershell
# Real-time Log-Monitoring
Get-Content C:\MT5\logs\mt5_autostart.log -Wait -Tail 50

# Fehler finden
Select-String -Path C:\MT5\logs\*.log -Pattern "ERROR" | Select-Object -Last 20

# Neustarts zählen
(Select-String -Path C:\MT5\logs\mt5_autostart.log -Pattern "erfolgreich neu gestartet").Count
```

---

### Health-Check Script

```powershell
# health_check.ps1
$mt5Process = Get-Process -Name terminal64 -ErrorAction SilentlyContinue

if ($mt5Process) {
    $memory = [math]::Round($mt5Process.WorkingSet64 / 1MB, 2)

    Write-Host "✓ MT5 läuft" -ForegroundColor Green
    Write-Host "  PID: $($mt5Process.Id)"
    Write-Host "  RAM: $memory MB"
    Write-Host "  CPU-Zeit: $($mt5Process.TotalProcessorTime)"

    exit 0
} else {
    Write-Host "✗ MT5 läuft NICHT!" -ForegroundColor Red
    exit 1
}
```

**Integration in Monitoring-System:**
```bash
# Beispiel: Nagios, Zabbix, Prometheus
powershell.exe -File health_check.ps1
echo $?  # Exit-Code: 0 = OK, 1 = ERROR
```

---

## 🔄 Automatische Updates

### MT5-Updates automatisieren

```powershell
# update_mt5.ps1

# 1. Service stoppen
Stop-Service MT5AutoStart

# 2. MT5 beenden
Stop-Process -Name terminal64 -Force -ErrorAction SilentlyContinue

# 3. Backup erstellen
$backupDir = "C:\MT5\backups\$(Get-Date -Format 'yyyyMMdd_HHmmss')"
Copy-Item "C:\Program Files\MetaTrader 5" -Destination $backupDir -Recurse

# 4. MT5 updaten (Download neueste Version)
# ... Update-Logik ...

# 5. Service neu starten
Start-Service MT5AutoStart

Write-Host "✓ MT5 Update abgeschlossen"
```

---

## 🚨 Troubleshooting

### Problem: MT5 startet nicht

**Diagnose:**
```powershell
# 1. Logs prüfen
Get-Content C:\MT5\logs\mt5_autostart.log -Tail 100

# 2. MT5-Pfad validieren
Test-Path "C:\Program Files\MetaTrader 5\terminal64.exe"

# 3. Manuell starten
& "C:\Program Files\MetaTrader 5\terminal64.exe" /login:12345678 /server:"ICMarkets-Demo" /password:"test"
```

---

### Problem: Service läuft, aber MT5 nicht

**Diagnose:**
```powershell
# 1. Service-Logs
Get-Content C:\MT5\logs\service_stdout.log
Get-Content C:\MT5\logs\service_stderr.log

# 2. Event-Log prüfen
Get-EventLog -LogName Application -Source MT5AutoStart -Newest 50

# 3. Service-Konto prüfen
sc qc MT5AutoStart
# Sollte als SYSTEM laufen für GUI-Zugriff
```

---

### Problem: Login-Daten werden nicht akzeptiert

**Lösungen:**
```powershell
# 1. Server-Name prüfen
# MT5 öffnen → Datei → Bei Handelskonto anmelden → Server-Liste anzeigen

# 2. Credentials manuell testen
# In MT5 manuell einloggen

# 3. Config validieren
Get-Content C:\MT5\config.json | ConvertFrom-Json | Format-List
```

---

## 📈 Performance-Optimierung

### Windows Server optimieren

```powershell
# 1. Deaktiviere unnötige Dienste
Set-Service -Name "Windows Search" -StartupType Disabled
Set-Service -Name "Superfetch" -StartupType Disabled

# 2. Prozess-Priorität erhöhen
$mt5Process = Get-Process -Name terminal64
$mt5Process.PriorityClass = 'High'

# 3. RAM-Limit erhöhen (wenn nötig)
# In mt5_saas_config.json:
{
  "advanced": {
    "process_priority": "High",
    "max_memory_mb": 2048
  }
}
```

---

## 📋 Checkliste für Produktion

- [ ] MT5 installiert und getestet
- [ ] Scripts nach C:\MT5 kopiert
- [ ] Config-Datei angepasst (account, password, server)
- [ ] MT5-Pfade validiert
- [ ] Manueller Test erfolgreich
- [ ] Windows Service installiert
- [ ] Service läuft nach Neustart
- [ ] Logs werden geschrieben
- [ ] Monitoring eingerichtet
- [ ] Firewall-Regeln konfiguriert
- [ ] Credentials verschlüsselt
- [ ] File-Berechtigungen gesetzt
- [ ] Backup-Strategy implementiert
- [ ] Health-Check läuft
- [ ] Dokumentation erstellt

---

## 🆘 Support

### Logs sammeln

```powershell
# Alle relevanten Logs in ZIP packen
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$zipPath = "C:\MT5\support_logs_$timestamp.zip"

Compress-Archive -Path @(
    "C:\MT5\logs\*",
    "C:\MT5\config.json",
    "C:\MT5\automation\*.ps1"
) -DestinationPath $zipPath

Write-Host "Logs gesammelt: $zipPath"
```

### Kontakt

- **Email:** [support@stelona.com](mailto:support@stelona.com)
- **GitHub Issues:** [https://github.com/stelona/signal-ea-v90/issues](https://github.com/stelona/signal-ea-v90/issues)

---

## 📝 Changelog

### Version 1.0 (2024)
- ✅ Initiale SaaS-Lösung
- ✅ Vollautomatischer MT5-Start
- ✅ Windows Service Integration
- ✅ Multi-Tenant-Support
- ✅ Prozess-Monitoring
- ✅ Umfassende Dokumentation

---

## 📄 Lizenz

Copyright 2024 Stelona. Alle Rechte vorbehalten.

Nur für autorisierte Nutzung. Kontaktieren Sie [support@stelona.com](mailto:support@stelona.com) für Lizenzinformationen.

---

**© 2024 Stelona. All rights reserved.**
